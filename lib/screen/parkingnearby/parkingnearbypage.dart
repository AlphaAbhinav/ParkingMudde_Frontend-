import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parkingmudde/services/api_service.dart';

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
  final List<Map<String, dynamic>> pricingTiers; // [{"hours": 1, "price": 20}, ...]
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
    this.pricingTiers = const [],
  });

  /// Human-readable price string for display
  String get priceDisplay {
    if (feeType == "free" || pricePerHour == 0) return "FREE";
    if (pricingTiers.isNotEmpty) {
      final first = pricingTiers[0];
      return "₹${(first['price'] as num).toStringAsFixed(0)}/1hr";
    }
    if (chargeLabel != null && chargeLabel!.isNotEmpty) return chargeLabel!;
    if (pricePerHour != null && pricePerHour! > 0) {
      return "₹${pricePerHour!.toStringAsFixed(0)}/hr";
    }
    return "Price N/A";
  }

  /// Whether this is a free parking spot
  bool get isFree => feeType == "free" || pricePerHour == 0;

  /// Whether the price is known
  bool get hasPriceInfo => feeType != "unknown" || pricePerHour != null || (chargeLabel != null && chargeLabel!.isNotEmpty) || pricingTiers.isNotEmpty;

  int? get backendId {
    if (!id.startsWith("backend-")) return null;
    return int.tryParse(id.replaceFirst("backend-", ""));
  }

  int amountForHours(int hours) {
    final duration = max(hours, 1);
    if (isFree) return 0;
    if (pricingTiers.isNotEmpty) {
      final matching = pricingTiers.firstWhere(
        (tier) => _toInt(tier["hours"]) == duration,
        orElse: () => pricingTiers.last,
      );
      return _toInt(matching["price"]);
    }
    if (pricePerHour != null) {
      return (pricePerHour! * duration).round();
    }
    return 0;
  }

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    final rawTiers = json["pricing_tiers"];
    final tiers = (rawTiers is List)
        ? rawTiers.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
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
      pricingTiers: tiers,
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
  final MapController mapController = MapController();

  LatLng userLocation = const LatLng(28.6139, 77.2090);
  List<ParkingSpot> parkingSpots = [];
  bool isLoading = true; // Added purely for smooth UX presentation during init

  /// ROUTE VARIABLES
  List<Polyline> polylines = [];
  List<LatLng> routePoints = [];

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

    // Enabled backend verified spots alongside public spots
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
        headers: const {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "ParkingMuddeApp/1.0",
        },
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

    mapController.move(userLocation, 15);

    loadNearbyParking();
  }

  /// Draw route using free OSRM API
  Future<void> drawRoute(double destLat, double destLng) async {
    final String url = 
      "https://router.project-osrm.org/route/v1/driving/"
      "${userLocation.longitude},${userLocation.latitude};"
      "$destLng,$destLat?overview=full&geometries=geojson";
      
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {"User-Agent": "ParkingMuddeApp/1.0"},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final routes = decoded['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          routePoints.clear();
          for (var coord in coordinates) {
            routePoints.add(LatLng(coord[1], coord[0]));
          }

          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                color: const Color(0XFF184B8C), // deep premium superapp blue
                strokeWidth: 5, // slightly thinned for professional Maps UX Look
                points: routePoints,
                strokeJoin: StrokeJoin.round,
                strokeCap: StrokeCap.round,
              ),
            );
          });

          // Auto adjusts view perfectly
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([userLocation, LatLng(destLat, destLng)]),
              padding: const EdgeInsets.all(80),
            ),
          );
        }
      }
    } catch (e) {
      print("Route fetching error: $e");
    }
  }

  /// Map markers using flutter_map
  List<Marker> get markers {
    final List<Marker> spotMarkers = parkingSpots.map((spot) {
      return Marker(
        point: LatLng(spot.lat, spot.lng),
        width: 80,
        height: 60,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            drawRoute(spot.lat, spot.lng);
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  spot.priceDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: spot.isFree ? Colors.green.shade800 : const Color(0XFF184B8C),
                  ),
                ),
              ),
              Icon(
                Icons.location_on,
                size: 32,
                color: spot.isVerified ? Colors.blue.shade600 : Colors.green.shade600,
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Add user location marker
    spotMarkers.add(
      Marker(
        point: userLocation,
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );

    return spotMarkers;
  }

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
    getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
        backgroundColor: Colors.transparent,
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
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkingmudde.app',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          Positioned(
            right: 16,
            bottom: parkingSpots.isNotEmpty ? 250 : 90,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0XFF184B8C),
              onPressed: _showAddSpotBottomSheet,
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
              label: const Text("Add Spot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            right: 16,
            bottom: parkingSpots.isNotEmpty ? 190 : 30,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                mapController.move(userLocation, 16);
              },
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0XFF184B8C),
              ),
            ),
          ),

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
                height: 185,
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

  Widget _buildModernMapSpotCard(ParkingSpot spot) {
    final bool isHighlyAvailable = spot.slots > 5;
    final String availabilityLabel = spot.hasLiveSlots
        ? "${spot.slots} SLOTS"
        : "OSM LISTING";

    return InkWell(
      onTap: () {
        mapController.move(LatLng(spot.lat, spot.lng), 16);
        drawRoute(spot.lat, spot.lng);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.78, // Floating size constraints
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

            // Pricing tiers row — only shown when tier data exists
            if (spot.pricingTiers.isNotEmpty) ...[
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: spot.pricingTiers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final tier = spot.pricingTiers[i];
                    final hrs = tier['hours'];
                    final price = (tier['price'] as num).toStringAsFixed(0);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A5296), Color(0xFF184B8C)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            "${hrs}hr · ₹$price",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],

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

                IconButton(
                  onPressed: () => _showReportDialog(spot),
                  icon: Icon(
                    Icons.report_problem_rounded,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: "Report parking",
                ),

                const SizedBox(width: 6),

                InkWell(
                  onTap: () => _showBookingSheet(spot),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Book",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

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
                          "Navigate",
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

  void _showAddSpotBottomSheet() {
    final nameController = TextEditingController();
    final tierPriceController = TextEditingController();
    bool isPaid = false;
    List<Map<String, dynamic>> pricingTiers = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0XFF184B8C).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_location_alt_rounded, color: Color(0XFF184B8C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text("Add Community Parking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0XFF184B8C))),
                  ]),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Parking Name",
                      hintText: "e.g. Near City Mall Gate 2",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.local_parking_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Paid toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaid ? const Color(0XFF184B8C).withOpacity(0.06) : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isPaid ? const Color(0XFF184B8C).withOpacity(0.2) : Colors.green.shade200),
                    ),
                    child: Row(children: [
                      Icon(isPaid ? Icons.currency_rupee_rounded : Icons.money_off_rounded,
                          color: isPaid ? const Color(0XFF184B8C) : Colors.green.shade700),
                      const SizedBox(width: 10),
                      Text(isPaid ? "Paid Parking" : "Free Parking",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? const Color(0XFF184B8C) : Colors.green.shade800)),
                      const Spacer(),
                      Switch(
                        value: isPaid,
                        activeColor: const Color(0XFF184B8C),
                        onChanged: (val) => setModalState(() {
                          isPaid = val;
                          if (!val) pricingTiers.clear();
                        }),
                      ),
                    ]),
                  ),

                  // Pricing tiers section — only visible when Paid
                  if (isPaid) ...[
                    const SizedBox(height: 16),
                    const Text("Pricing Tiers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0XFF184B8C))),
                    const SizedBox(height: 4),
                    const Text("Set hour-wise fares so users know the exact cost.",
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 10),

                    // Existing tiers
                    ...pricingTiers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final tier = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0XFF184B8C).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(Icons.access_time_rounded, size: 16, color: const Color(0XFF184B8C).withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text("Hour ${tier['hours']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text("₹${tier['price']}",
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0XFF184B8C))),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setModalState(() => pricingTiers.removeAt(i)),
                            child: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                          ),
                        ]),
                      );
                    }),

                    // Add tier row
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: tierPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Price for Hour ${pricingTiers.length + 1} (₹)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixText: "₹ ",
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF184B8C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () {
                          final price = double.tryParse(tierPriceController.text.trim());
                          if (price == null || price <= 0) return;
                          setModalState(() {
                            pricingTiers.add({"hours": pricingTiers.length + 1, "price": price});
                            tierPriceController.clear();
                          });
                        },
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFF184B8C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        if (isPaid && pricingTiers.isEmpty) {
                          Get.snackbar("Add Pricing", "Please add at least one price tier for paid parking.",
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Get.back();
                        await _submitNewParking(nameController.text.trim(), isPaid, pricingTiers);
                      },
                      child: const Text("Submit Spot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitNewParking(String name, bool isPaid, List<Map<String, dynamic>> tiers) async {
    try {
      final String baseUrl = dotenv.env['BACKEND_URL'] ?? "http://localhost:8000";
      final center = mapController.camera.center;
      final body = {
        "name": name,
        "latitude": center.latitude,
        "longitude": center.longitude,
        "fee_type": isPaid ? "paid" : "free",
        if (isPaid && tiers.isNotEmpty) "pricing_tiers": tiers,
      };
      final response = await http.post(
        Uri.parse("$baseUrl/v1/parking/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Parking spot added!", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        loadNearbyParking();
      } else {
        Get.snackbar("Error", "Failed to add spot", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Add spot error: $e");
    }
  }

  void _showBookingSheet(ParkingSpot spot) {
    int durationHours = 1;
    final vehicleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final amount = spot.hasPriceInfo
                ? spot.amountForHours(durationHours)
                : null;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 22,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_available_rounded,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          spot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0XFF184B8C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _bookingInfoTile(
                          "Slots",
                          spot.hasLiveSlots ? "${spot.slots}" : "Map",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _bookingInfoTile(
                          "Distance",
                          "${spot.distance.toStringAsFixed(2)} km",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _bookingInfoTile(
                          "Amount",
                          amount == null
                              ? "On approval"
                              : amount == 0
                                  ? "Free"
                                  : "Rs$amount",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Duration",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3, 4].map((hours) {
                      final selected = durationHours == hours;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text("${hours}h"),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: const Color(0XFF184B8C),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w900,
                            ),
                            onSelected: (_) => setModalState(
                              () => durationHours = hours,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vehicleController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Vehicle Number",
                      hintText: "Optional",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.directions_car_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFF184B8C),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        await _submitBooking(
                          spot,
                          durationHours,
                          vehicleController.text.trim(),
                        );
                      },
                      child: Text(
                        amount == 0
                            ? "Send Booking Request"
                            : amount == null
                                ? "Request Booking"
                            : "Request Booking - Rs$amount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bookingInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0XFF184B8C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking(
    ParkingSpot spot,
    int durationHours,
    String vehicleNumber,
  ) async {
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) {
      Get.snackbar(
        "Login Required",
        "Please login before booking a parking spot.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final result = await ApiService.createParkingBookingRequest(
      userId: userId,
      parkingSpotId: spot.backendId,
      parkingName: spot.name,
      vehicleNumber: vehicleNumber,
      latitude: spot.lat,
      longitude: spot.lng,
      durationHours: durationHours,
      amount: spot.hasPriceInfo ? spot.amountForHours(durationHours) : null,
    );

    if (result["success"] == true) {
      Get.snackbar(
        "Booking Requested",
        "Your parking request was sent successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      loadNearbyParking();
    } else {
      Get.snackbar(
        "Booking Failed",
        result["message"] ?? "Could not send booking request.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  void _showReportDialog(ParkingSpot spot) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Report Parking"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Is '${spot.name}' not here or closed? Let us know."),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: "Reason (e.g. Doesn't exist)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                Get.back();
                await _submitReport(spot, reasonController.text.trim());
              },
              child: const Text("Report", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _submitReport(ParkingSpot spot, String reason) async {
    try {
      final String baseUrl = dotenv.env['BACKEND_URL'] ?? "http://localhost:8000";
      final response = await http.post(
        Uri.parse("$baseUrl/v1/parking/report"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "parking_id": spot.id,
          "parking_name": spot.name,
          "latitude": spot.lat,
          "longitude": spot.lng,
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Reported", "Thanks! We will verify this.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Failed to send report", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print("Report error: $e");
    }
  }
}
