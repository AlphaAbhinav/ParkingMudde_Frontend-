import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// (Class kept exactly as authored)
class ParkingSpot {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int slots;
  final bool hasLiveSlots;
  final bool isVerified;
  final double? pricePerHour;   // null = unknown
  final String feeType;         // "free" / "paid" / "unknown"
  final String? chargeLabel;    // raw charge string from OSM e.g. "₹50/hour"
  double distance;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.slots,
    this.hasLiveSlots = true,
    this.isVerified = true,
    this.distance = 0,
    this.pricePerHour,
    this.feeType = "unknown",
    this.chargeLabel,
  });

  /// Human-readable price string for display
  String get priceDisplay {
    if (feeType == "free" || pricePerHour == 0) return "FREE";
    if (chargeLabel != null && chargeLabel!.isNotEmpty) return chargeLabel!;
    if (pricePerHour != null && pricePerHour! > 0) {
      return "₹${pricePerHour!.toStringAsFixed(0)}/hr";
    }
    return "Price N/A";
  }

  /// Whether this is a free parking spot
  bool get isFree => feeType == "free" || pricePerHour == 0;

  /// Whether the price is known
  bool get hasPriceInfo => feeType != "unknown" || pricePerHour != null || (chargeLabel != null && chargeLabel!.isNotEmpty);

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: "backend-${json["id"]}",
      name: (json["name"] ?? "Verified parking").toString(),
      lat: _toDouble(json["latitude"]),
      lng: _toDouble(json["longitude"]),
      slots: _toInt(json["available_slots"]),
      hasLiveSlots: true,
      isVerified: true,
      pricePerHour: _toNullableDouble(json["price_per_hour"]),
      feeType: (json["fee_type"] ?? "unknown").toString(),
    );
  }

  factory ParkingSpot.fromOverpassElement(Map<String, dynamic> json) {
    final tags = Map<String, dynamic>.from(json["tags"] ?? {});
    final center = json["center"] is Map ? Map<String, dynamic>.from(json["center"]) : null;
    final lat = _toNullableDouble(json["lat"]) ?? _toNullableDouble(center?["lat"]) ?? 0;
    final lng = _toNullableDouble(json["lon"]) ?? _toNullableDouble(center?["lon"]) ?? 0;
    final rawCapacity = tags["capacity"] ?? tags["capacity:disabled"];

    // --- Extract pricing info from OSM tags ---
    final String? feeRaw = (tags["fee"] ?? tags["parking:fee"])?.toString().toLowerCase();
    final String? chargeRaw = tags["charge"]?.toString();

    String feeType = "unknown";
    double? pricePerHour;

    if (feeRaw == "no" || feeRaw == "none") {
      feeType = "free";
      pricePerHour = 0;
    } else if (feeRaw == "yes") {
      feeType = "paid";
      // Try to parse a numeric value from the charge tag
      if (chargeRaw != null) {
        final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(chargeRaw);
        if (numMatch != null) {
          pricePerHour = double.tryParse(numMatch.group(1)!);
        }
      }
    } else if (chargeRaw != null && chargeRaw.isNotEmpty) {
      feeType = "paid";
      final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(chargeRaw);
      if (numMatch != null) {
        pricePerHour = double.tryParse(numMatch.group(1)!);
      }
    }

    return ParkingSpot(
      id: "osm-${json["type"]}-${json["id"]}",
      name: (tags["name"] ?? _fallbackOverpassName(tags)).toString(),
      lat: lat,
      lng: lng,
      slots: _toInt(rawCapacity),
      hasLiveSlots: rawCapacity != null,
      isVerified: false,
      pricePerHour: pricePerHour,
      feeType: feeType,
      chargeLabel: chargeRaw,
    );
  }

  static String _fallbackOverpassName(Map<String, dynamic> tags) {
    final parkingType = tags["parking"];
    if (parkingType != null && parkingType.toString().trim().isNotEmpty) {
      return "${_titleCase(parkingType.toString())} parking";
    }
    return "Public parking";
  }

  static String _titleCase(String value) {
    return value
        .replaceAll("_", " ")
        .split(" ")
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(" ");
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static double _toDouble(dynamic value) {
    return _toNullableDouble(value) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "");
  }
}

class NearbyParkingMapScreen extends StatefulWidget {
  const NearbyParkingMapScreen({super.key});

  @override
  State<NearbyParkingMapScreen> createState() => _NearbyParkingMapScreenState();
}

class _NearbyParkingMapScreenState extends State<NearbyParkingMapScreen> {
  GoogleMapController? mapController;

  LatLng userLocation = const LatLng(28.6139, 77.2090);
  List<ParkingSpot> parkingSpots = [];
  bool isLoading = true; // Added purely for smooth UX presentation during init

  /// ROUTE VARIABLES
  Set<Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> routePoints = [];

  /// Keep Google API Key exact
  final String googleApiKey = "AIzaSyCDpidG86xLSG6qGmneOoXcAKl_j-ar2PE";

  /// Distance calculation exactly preserved
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;

    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> loadNearbyParking() async {
    setState(() => isLoading = true);

    final backendSpots = await fetchBackendParkingSpots();
    final overpassSpots = await fetchOverpassParkingSpots();
    final mergedSpots = _mergeParkingSpots([...backendSpots, ...overpassSpots]);

    for (var spot in mergedSpots) {
      spot.distance = calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        spot.lat,
        spot.lng,
      );
    }

    mergedSpots.sort((a, b) {
      final verifiedCompare = (b.isVerified ? 1 : 0).compareTo(a.isVerified ? 1 : 0);
      if (verifiedCompare != 0) return verifiedCompare;
      return a.distance.compareTo(b.distance);
    });

    setState(() {
      parkingSpots = mergedSpots;
      isLoading = false;
    });
  }

  List<ParkingSpot> _mergeParkingSpots(List<ParkingSpot> spots) {
    final uniqueSpots = <String, ParkingSpot>{};

    for (final spot in spots) {
      if (spot.lat == 0 || spot.lng == 0) continue;
      final key = "${spot.lat.toStringAsFixed(5)},${spot.lng.toStringAsFixed(5)}";
      final existing = uniqueSpots[key];
      if (existing == null || (!existing.isVerified && spot.isVerified)) {
        uniqueSpots[key] = spot;
      }
    }

    return uniqueSpots.values.toList();
  }

  /// Fetch verified app parking first, then OSM fills the nearby map.
  Future<void> fetchParkingSpots() async {
    await loadNearbyParking();
  }

  Future<List<ParkingSpot>> fetchBackendParkingSpots() async {
    try {
      final String baseUrl = dotenv.env['BACKEND_URL'] ?? "http://localhost:8000";
      final response = await http.get(
        Uri.parse("$baseUrl/v1/parking/"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        List<ParkingSpot> spots = data
            .map((e) => ParkingSpot.fromJson(e))
            .toList();

        return spots;
      } else {
        print("Failed to load parking spots");
      }
    } catch (e) {
      print("Network error connecting local testing host. $e");
    }

    return [];
  }

  Future<List<ParkingSpot>> fetchOverpassParkingSpots() async {
    const double radiusMeters = 5000;
    final query = """
[out:json][timeout:25];
(
  node["amenity"="parking"](around:$radiusMeters,${userLocation.latitude},${userLocation.longitude});
  way["amenity"="parking"](around:$radiusMeters,${userLocation.latitude},${userLocation.longitude});
  relation["amenity"="parking"](around:$radiusMeters,${userLocation.latitude},${userLocation.longitude});
);
out center tags;
""";

    try {
      final response = await http.post(
        Uri.parse("https://overpass-api.de/api/interpreter"),
        headers: const {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"data": query},
      );

      if (response.statusCode != 200) {
        print("Overpass parking lookup failed: ${response.statusCode}");
        return [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded["elements"];
      if (elements is! List) return [];

      return elements
          .whereType<Map<String, dynamic>>()
          .map(ParkingSpot.fromOverpassElement)
          .toList();
    } catch (e) {
      print("Overpass parking lookup error. $e");
      return [];
    }
  }

  /// Get user location untouched
  Future<void> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("Location disabled");
      loadNearbyParking();
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      loadNearbyParking();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      loadNearbyParking();
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 15));

    loadNearbyParking();
  }

  /// Draw route completely unchanged logic
  Future<void> drawRoute(double destLat, double destLng) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(userLocation.latitude, userLocation.longitude),
        destination: PointLatLng(destLat, destLng),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      routePoints.clear();
      for (var point in result.points) {
        routePoints.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(
              0XFF184B8C,
            ), // Adjusted polyline for deep premium superapp blue
            width: 5, // slightly thinned for professional Maps UX Look
            points: routePoints,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
          ),
        );
      });

      // Auto adjusts view perfectly
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList([userLocation, LatLng(destLat, destLng)]),
          80,
        ),
      );
    }
  }

  /// Safe camera binding function for polished routes view focus
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  /// Map markers unmodified backend usage
  Set<Marker> get markers => parkingSpots.map((spot) {
    return Marker(
      markerId: MarkerId(spot.id),
      position: LatLng(spot.lat, spot.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        spot.isVerified ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
      ), // Match the blue aesthetic
      infoWindow: InfoWindow(
        title: spot.name,
        snippet: spot.hasLiveSlots
            ? "${spot.distance.toStringAsFixed(2)} km • ${spot.slots} slots • ${spot.priceDisplay}"
            : "${spot.distance.toStringAsFixed(2)} km • ${spot.priceDisplay}",
      ),
      onTap: () {
        drawRoute(spot.lat, spot.lng);
      },
    );
  }).toSet();

  /// Open Google Maps navigation exactly intact
  void openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserLocation(); // fetch is fired off inside here via exact origin setup
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Seamless immersive mapping background layout
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0XFF184B8C),
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent, // Floating glassy feel
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: const Text(
            "Find Nearby Spaces",
            style: TextStyle(
              fontSize: 14,
              color: Color(0XFF184B8C),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          /// FULL IMMERSIVE GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled:
                false, // Turned off default float so we can manage sleek layout safely, optional.
            markers: markers,
            polylines: polylines,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(
              bottom: 220,
            ), // Gives map tools space to jump over our cards
            onMapCreated: (controller) {
              mapController = controller;
            },
          ),

          /// FAB Style Live Custom User Locator
          Positioned(
            right: 16,
            bottom: parkingSpots.isNotEmpty
                ? 190
                : 30, // Hugs dynamically based on horizontal slider card presences
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(userLocation, 16),
                );
              },
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0XFF184B8C),
              ),
            ),
          ),

          /// PRETTY LOADING OR FLOATING HORIZONTAL CARDS!
          if (isLoading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildSearchingBadge(),
            )
          else if (parkingSpots.isEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildNoSpotsCard(),
            )
          else
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 140, // Polished specific slider clearance area
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: parkingSpots.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final spot = parkingSpots[index];
                    return _buildModernMapSpotCard(spot);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Very polished hovering Card to Replace ugly bottom sheet List!
  Widget _buildModernMapSpotCard(ParkingSpot spot) {
    final bool isHighlyAvailable = spot.slots > 5;
    final String availabilityLabel = spot.hasLiveSlots
        ? "${spot.slots} SLOTS"
        : "OSM LISTING";

    return InkWell(
      onTap: () {
        // Focuses the map AND maps the polyline securely simultaneously
        mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(spot.lat, spot.lng)),
        );
        drawRoute(spot.lat, spot.lng);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width:
            MediaQuery.of(context).size.width *
            0.78, // Floating size constraints
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Details Chunk
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0XFF184B8C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_parking_rounded,
                    color: Color(0XFF184B8C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spot.isVerified
                            ? "${spot.distance.toStringAsFixed(2)} Kilometers away"
                            : "${spot.distance.toStringAsFixed(2)} Kilometers away - public map data",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            // Sub Details and Quick Actions block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Slot + Price badges row
                Expanded(
                  child: Row(
                    children: [
                      /// Smart Slot visual tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: !spot.hasLiveSlots
                              ? Colors.blue.shade50
                              : isHighlyAvailable
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spot.hasLiveSlots
                                  ? Icons.directions_car_rounded
                                  : Icons.map_rounded,
                              size: 12,
                              color: !spot.hasLiveSlots
                                  ? Colors.blue.shade700
                                  : isHighlyAvailable
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              availabilityLabel,
                              style: TextStyle(
                                color: !spot.hasLiveSlots
                                    ? Colors.blue.shade800
                                    : isHighlyAvailable
                                    ? Colors.green.shade800
                                    : Colors.orange.shade900,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      /// Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: spot.isFree
                              ? Colors.green.shade50
                              : spot.hasPriceInfo
                              ? const Color(0XFF184B8C).withOpacity(0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spot.isFree
                                  ? Icons.money_off_rounded
                                  : spot.hasPriceInfo
                                  ? Icons.currency_rupee_rounded
                                  : Icons.help_outline_rounded,
                              size: 12,
                              color: spot.isFree
                                  ? Colors.green.shade700
                                  : spot.hasPriceInfo
                                  ? const Color(0XFF184B8C)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              spot.priceDisplay,
                              style: TextStyle(
                                color: spot.isFree
                                    ? Colors.green.shade800
                                    : spot.hasPriceInfo
                                    ? const Color(0XFF184B8C)
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Direct trigger launching out the navigation
                InkWell(
                  onTap: () => openGoogleMaps(spot.lat, spot.lng),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0XFF184B8C),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0XFF184B8C).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.assistant_direction_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Route",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Searching Pulse Badge avoiding annoying circular screen blanks!
  Widget _buildSearchingBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Color(0XFF184B8C),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 14),
              Text(
                "Pinpointing locations nearby...",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0XFF184B8C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Seamless absence handler cleanly mapped bottom area safely
  Widget _buildNoSpotsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.redAccent.shade100),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wrong_location_outlined,
            color: Colors.redAccent,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            "No Verified Slots Detected",
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Adjust location or try a bit further away. Your proximity has no active API mapped entries today.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
