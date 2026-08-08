import 'dart:async';
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

// (Data class entirely unmodified as authored)
class ParkingSpot {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int slots;
  final bool hasLiveSlots;
  final bool isVerified;
  final double? pricePerHour;
  final String feeType;
  final String? chargeLabel;
  final List<Map<String, dynamic>> pricingTiers;
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

  String get priceDisplay {
    if (feeType == "free" || pricePerHour == 0) return "FREE";
    if (pricingTiers.isNotEmpty) {
      final first = pricingTiers[0];
      return "Rs${(first['price'] as num).toStringAsFixed(0)}/1hr";
    }
    if (chargeLabel != null && chargeLabel!.isNotEmpty) return chargeLabel!;
    if (pricePerHour != null && pricePerHour! > 0) {
      return "Rs${pricePerHour!.toStringAsFixed(0)}/hr";
    }
    return "Price N/A";
  }

  bool get isFree => feeType == "free" || pricePerHour == 0;
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

    final String? feeRaw = (tags["fee"] ?? tags["parking:fee"])?.toString().toLowerCase();
    final String? chargeRaw = tags["charge"]?.toString();
    String feeType = "unknown";
    double? pricePerHour;

    if (feeRaw == "no" || feeRaw == "none") {
      feeType = "free";
      pricePerHour = 0;
    } else if (feeRaw == "yes") {
      feeType = "paid";
      if (chargeRaw != null) {
        final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(chargeRaw);
        if (numMatch != null) pricePerHour = double.tryParse(numMatch.group(1)!);
      }
    } else if (chargeRaw != null && chargeRaw.isNotEmpty) {
      feeType = "paid";
      final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(chargeRaw);
      if (numMatch != null) pricePerHour = double.tryParse(numMatch.group(1)!);
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
  static String _titleCase(String value) => value.replaceAll("_", " ").split(" ").where((part) => part.isNotEmpty).map((part) => part[0].toUpperCase() + part.substring(1)).join(" ");
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
  static double _toDouble(dynamic value) => _toNullableDouble(value) ?? 0;
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
  // --- Global UI Design Tokens ---
  static const Color brandBlue = Color(0XFF184B8C);
  static const Color brandBlueLight = Color(0xFFEFF6FF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color surfaceGrey = Color(0xFFF1F5F9);

  final MapController mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  LatLng userLocation = const LatLng(19.0760, 72.8777);
  List<ParkingSpot> parkingSpots = [];
  bool isLoading = true;
  bool usingFallbackLocation = false;
  String? locationMessage;
  String? selectedSpotId;

  /// ROUTE VARIABLES
  List<Polyline> polylines = [];
  List<LatLng> routePoints = [];

  static const double _minMapZoom = 11.0;
  static const double _maxMapZoom = 15.5;

  double _clampZoom(double zoom) => zoom.clamp(_minMapZoom, _maxMapZoom).toDouble();

  void _moveMap(LatLng center, double zoom) {
    mapController.move(center, _clampZoom(zoom));
  }

  ParkingSpot? get selectedSpot {
    for (final spot in parkingSpots) {
      if (spot.id == selectedSpotId) return spot;
    }
    return parkingSpots.isNotEmpty ? parkingSpots.first : null;
  }

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> loadNearbyParking() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final results = await Future.wait([
      fetchBackendParkingSpots(),
      fetchOverpassParkingSpots(),
    ]);
    final mergedSpots = _mergeParkingSpots([...results[0], ...results[1]]);

    for (var spot in mergedSpots) {
      spot.distance = calculateDistance(userLocation.latitude, userLocation.longitude, spot.lat, spot.lng);
    }

    mergedSpots.sort((a, b) {
      if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
      final aBookable = a.backendId != null && a.slots > 0;
      final bBookable = b.backendId != null && b.slots > 0;
      if (aBookable != bBookable) return aBookable ? -1 : 1;
      return a.distance.compareTo(b.distance);
    });

    if (!mounted) return;
    setState(() {
      parkingSpots = mergedSpots;
      selectedSpotId = mergedSpots.isNotEmpty ? mergedSpots.first.id : null;
      isLoading = false;
    });

    // Setup map constraints correctly for route if list isn't empty.
    if (selectedSpot != null && parkingSpots.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if(_pageController.hasClients) _pageController.jumpToPage(0);
         drawRoute(selectedSpot!.lat, selectedSpot!.lng);
      });
    }
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

  Future<List<ParkingSpot>> fetchBackendParkingSpots() async {
    try {
      final String baseUrl = dotenv.env['BACKEND_URL'] ?? "http://localhost:8000";
      final uri = Uri.parse("$baseUrl/v1/parking/nearby").replace(queryParameters: {
          "lat": userLocation.latitude.toString(),
          "lng": userLocation.longitude.toString(),
          "radius_km": "8",
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().map(ParkingSpot.fromJson).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<ParkingSpot>> fetchOverpassParkingSpots() async {
    const double radiusMeters = 5000;
    final query = """[out:json][timeout:25];(node["amenity"="parking"](around:$radiusMeters,${userLocation.latitude},${userLocation.longitude});way["amenity"="parking"](around:$radiusMeters,${userLocation.latitude},${userLocation.longitude});relation["amenity"="parking"](around:$radiusMeters,${userLocation.latitude},${userLocation.longitude}););out center tags;""";
    try {
      final response = await http.post(Uri.parse("https://overpass-api.de/api/interpreter"),
        headers: {"Content-Type": "application/x-www-form-urlencoded", "User-Agent": "ParkingMuddeApp/1.0"}, body: {"data": query}
      ).timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded["elements"];
      if (elements is! List) return [];
      return elements.whereType<Map<String, dynamic>>().map(ParkingSpot.fromOverpassElement).toList();
    } catch (_) {}
    return [];
  }

  Future<void> getUserLocation() async {
    try {
      final stored = await ApiService.getStoredUser();
      if (stored?["latitude"] is double && stored?["longitude"] is double) {
        userLocation = LatLng(stored!["latitude"], stored["longitude"]);
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _useFallbackLocation("Turn on location services to see accurate nearby parking.");
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        await _useFallbackLocation("Location permission is off. Showing saved or default city results.");
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        usingFallbackLocation = false;
        locationMessage = null;
      });
      _moveMap(userLocation, 15);
      await loadNearbyParking();
    } catch (e) {
      await _useFallbackLocation("Could not read GPS. Showing saved or default city results.");
    }
  }

  Future<void> _useFallbackLocation(String message) async {
    if (!mounted) return;
    setState(() {
      usingFallbackLocation = true;
      locationMessage = message;
    });
    _moveMap(userLocation, 13);
    await loadNearbyParking();
  }

  Future<void> drawRoute(double destLat, double destLng) async {
    final selectedId = parkingSpots
        .where((spot) => spot.lat == destLat && spot.lng == destLng)
        .map((spot) => spot.id).cast<String?>()
        .firstWhere((id) => id != null, orElse: () => null);
    if (mounted) setState(() => selectedSpotId = selectedId);
    
    final String url = "https://router.project-osrm.org/route/v1/driving/${userLocation.longitude},${userLocation.latitude};$destLng,$destLat?overview=full&geometries=geojson";
      
    try {
      final response = await http.get(Uri.parse(url), headers: const {"User-Agent": "ParkingMuddeApp/1.0"}).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final routes = decoded['routes'] as List;
        if (routes.isNotEmpty) {
          final coordinates = routes[0]['geometry']['coordinates'] as List;
          routePoints.clear();
          for (var coord in coordinates) {
            routePoints.add(LatLng(coord[1], coord[0]));
          }
          if (!mounted) return;
          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                color: brandBlue.withOpacity(0.9), 
                strokeWidth: 4.5,
                points: routePoints,
                strokeJoin: StrokeJoin.round,
                strokeCap: StrokeCap.round,
              ),
            );
          });
          mapController.fitCamera(CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([userLocation, LatLng(destLat, destLng)]),
              padding: const EdgeInsets.all(70),
              maxZoom: _maxMapZoom,
          ));
        }
      }
    } catch (_) {}
  }

  /// Refined Map Interaction System (Tapping Card triggers Focus + Tap map shifts sliding page index automatically)
  void _focusSelectedSpot(ParkingSpot spot, {bool animatePageList = false}) {
    if (!mounted) return;
    setState(() => selectedSpotId = spot.id);
    _moveMap(LatLng(spot.lat, spot.lng), _maxMapZoom); 
    drawRoute(spot.lat, spot.lng);

    if (animatePageList && _pageController.hasClients) {
      final idx = parkingSpots.indexOf(spot);
      if (idx != -1) {
        _pageController.animateToPage(idx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  /// Ã¢â€â‚¬Ã¢â€â‚¬ Modern Map Pills
  List<Marker> get markers {
    final List<Marker> spotMarkers = parkingSpots.map((spot) {
      final isSelected = spot.id == selectedSpotId;
      return Marker(
        point: LatLng(spot.lat, spot.lng),
        width: isSelected ? 80 : 70, 
        height: isSelected ? 40 : 35,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _focusSelectedSpot(spot, animatePageList: true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? brandBlue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.25 : 0.1),
                  blurRadius: isSelected ? 10 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (spot.isVerified && !isSelected)
                  const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.stars_rounded, size: 10, color: Colors.amber)),
                Flexible(
                  child: Text(
                    spot.priceDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: isSelected ? 12 : 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : (spot.isFree ? Colors.green.shade700 : textDark),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    // Map Center Target indicator 
    spotMarkers.add(Marker(
      point: userLocation, width: 22, height: 22,
      child: Container(decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)])),
    ));

    return spotMarkers;
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    final directionsUri = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=${userLocation.latitude},${userLocation.longitude}&destination=$lat,$lng&travelmode=driving");
    final fallbackUri = Uri.parse("https://maps.google.com/?q=$lat,$lng");
    try {
      final launched = await launchUrl(directionsUri, mode: LaunchMode.externalApplication, webOnlyWindowName: "_blank");
      if (!launched) await launchUrl(fallbackUri, mode: LaunchMode.platformDefault, webOnlyWindowName: "_blank");
    } catch (e) {
      Get.snackbar("Navigation Error", "Could not open Google Maps.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 18),
            onPressed: () => Get.back(),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
          ),
          child: const Text(
            "Find Nearby Spaces",
            style: TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w700, letterSpacing: 0.1),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 15.5,
              minZoom: _minMapZoom,
              maxZoom: _maxMapZoom,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.parkingmudde.app',
                maxZoom: _maxMapZoom,
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          if (usingFallbackLocation && locationMessage != null)
            Positioned(
              top: 100, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off_rounded, size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    Expanded(child: Text(locationMessage!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade900, height: 1.3))),
                  ],
                ),
              ),
            ),

          Positioned(
            right: 16,
            bottom: parkingSpots.isNotEmpty ? 230 : 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'addLocationMapUI',
                  backgroundColor: Colors.white,
                  onPressed: _showAddSpotBottomSheet,
                  tooltip: "Add Parking Spot",
                  elevation: 2,
                  child: const Icon(Icons.add_location_alt_rounded, color: textDark, size: 22),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      IconButton(icon: const Icon(Icons.my_location_rounded, color: textDark, size: 20), onPressed: () => _moveMap(userLocation, _maxMapZoom)),
                      const Divider(height: 1, color: surfaceGrey),
                      IconButton(icon: const Icon(Icons.add, color: textDark, size: 20), onPressed: () => _moveMap(mapController.camera.center, mapController.camera.zoom + 1)),
                      IconButton(icon: const Icon(Icons.remove, color: textDark, size: 20), onPressed: () => _moveMap(mapController.camera.center, mapController.camera.zoom - 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Positioned(bottom: 40, left: 0, right: 0, child: _buildSearchingBadge())
          else if (parkingSpots.isEmpty)
            Positioned(bottom: 40, left: 20, right: 20, child: _buildNoSpotsCard())
          else
            Positioned(
              bottom: 34, left: 0, right: 0,
              child: SizedBox(
                height: 185,
                // Magnetic Snapping View linked directly to selected Map markers
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: parkingSpots.length,
                  onPageChanged: (idx) => _focusSelectedSpot(parkingSpots[idx], animatePageList: false),
                  itemBuilder: (context, index) {
                    final spot = parkingSpots[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: _buildModernMapSpotCard(spot),
                    );
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
    final String availabilityLabel = spot.hasLiveSlots ? "${spot.slots} SLOTS" : "OSM LISTING";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
        border: Border.all(color: surfaceGrey, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: brandBlue.withOpacity(0.08), shape: BoxShape.circle),
                child: Icon(spot.isVerified ? Icons.verified_rounded : Icons.local_parking_rounded, color: brandBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textDark, letterSpacing: -0.2),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${spot.distance.toStringAsFixed(2)} km away ${spot.isVerified ? '' : '(Public)'}",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (spot.pricingTiers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: spot.pricingTiers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final tier = spot.pricingTiers[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceGrey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: textDark.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text("${tier['hours']}h - Ã¢â€šÂ¹${(tier['price'] as num).toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textDark)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
             const SizedBox(height: 8), 
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: spot.hasLiveSlots && isHighlyAvailable ? Colors.green.shade50 : surfaceGrey, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(spot.hasLiveSlots ? Icons.directions_car_rounded : Icons.map_rounded, size: 13, color: spot.hasLiveSlots && isHighlyAvailable ? Colors.green.shade700 : textGrey),
                          const SizedBox(width: 4),
                          Text(availabilityLabel, style: TextStyle(color: spot.hasLiveSlots && isHighlyAvailable ? Colors.green.shade800 : textDark, fontWeight: FontWeight.w700, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: spot.isFree ? Colors.green.shade50 : brandBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(spot.isFree ? Icons.money_off_rounded : spot.hasPriceInfo ? Icons.currency_rupee_rounded : Icons.help_outline_rounded, size: 13, color: spot.isFree ? Colors.green.shade700 : brandBlue),
                          const SizedBox(width: 2),
                          Text(spot.priceDisplay, style: TextStyle(color: spot.isFree ? Colors.green.shade800 : brandBlue, fontWeight: FontWeight.w700, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              InkWell(
                onTap: () => _showReportDialog(spot),
                borderRadius: BorderRadius.circular(10),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.report_gmailerrorred_rounded, size: 20, color: Colors.red.shade400)),
              ),
              const SizedBox(width: 8),

              InkWell(
                onTap: () => openGoogleMaps(spot.lat, spot.lng),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.assistant_direction_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text("Navigate", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 5))]),
          child: const Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: brandBlue, strokeWidth: 2)),
              SizedBox(width: 16),
              Text("Pinpointing locations nearby...", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: brandBlue)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoSpotsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.wrong_location_rounded, color: Colors.redAccent, size: 28)),
          const SizedBox(height: 14),
          const Text("No Parking Spots Found", style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2)),
          const SizedBox(height: 8),
          const Text("Try adjusting the map location slightly. We couldn't match active entries around this specific radius.", textAlign: TextAlign.center, style: TextStyle(color: textGrey, fontWeight: FontWeight.w500, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildModalHandle() => Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))));

  void _showAddSpotBottomSheet() {
    final nameController = TextEditingController();
    final slotsController = TextEditingController(text: "1");
    final tierPriceController = TextEditingController();
    bool isPaid = false;
    List<Map<String, dynamic>> pricingTiers = [];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModalHandle(),
                  Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: brandBlueLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add_location_alt_rounded, color: brandBlue, size: 20)),
                    const SizedBox(width: 14),
                    const Text("Add Community Parking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.5)),
                  ]),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Parking Name", hintText: "e.g. Near City Mall Gate 2",
                      filled: true, fillColor: surfaceGrey, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.edit_location_alt_rounded, color: textGrey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: slotsController, keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Available Slots", hintText: "e.g. 50",
                      filled: true, fillColor: surfaceGrey, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.car_rental_rounded, color: textGrey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: isPaid ? brandBlue.withOpacity(0.04) : Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isPaid ? brandBlue.withOpacity(0.15) : Colors.green.shade200)),
                    child: Row(children: [
                      Icon(isPaid ? Icons.account_balance_wallet_rounded : Icons.money_off_rounded, color: isPaid ? brandBlue : Colors.green.shade700, size: 20),
                      const SizedBox(width: 12),
                      Text(isPaid ? "Paid Parking" : "Free Parking", style: TextStyle(fontWeight: FontWeight.w600, color: isPaid ? brandBlue : Colors.green.shade800)),
                      const Spacer(),
                      Switch(value: isPaid, activeColor: brandBlue, onChanged: (val) => setModalState(() { isPaid = val; if (!val) pricingTiers.clear(); })),
                    ]),
                  ),
                  
                  if (isPaid) ...[
                    const SizedBox(height: 20),
                    const Text("Pricing Tiers", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textDark)),
                    const SizedBox(height: 4),
                    const Text("Set hour-wise fares so users know the exact cost.", style: TextStyle(fontSize: 11, color: textGrey)),
                    const SizedBox(height: 12),
                    ...pricingTiers.asMap().entries.map((entry) {
                      final i = entry.key; final tier = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: surfaceGrey, borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: textGrey), const SizedBox(width: 8),
                          Text("Hour ${tier['hours']}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark)), const Spacer(),
                          Text("Ã¢â€šÂ¹ ${tier['price']}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: brandBlue)), const SizedBox(width: 14),
                          GestureDetector(onTap: () => setModalState(() => pricingTiers.removeAt(i)), child: Icon(Icons.cancel_rounded, size: 20, color: Colors.red.shade300)),
                        ]),
                      );
                    }),
                    
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: tierPriceController, keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Price for Hour ${pricingTiers.length + 1}", filled: true, fillColor: surfaceGrey,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixText: "Ã¢â€šÂ¹ ",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18), elevation: 0),
                        onPressed: () {
                          final price = double.tryParse(tierPriceController.text.trim());
                          if (price == null || price <= 0) return;
                          setModalState(() { pricingTiers.add({"hours": pricingTiers.length + 1, "price": price}); tierPriceController.clear(); });
                        },
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 28),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: textDark, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      onPressed: () async {
                        final slots = int.tryParse(slotsController.text.trim()) ?? 0;
                        if (nameController.text.trim().isEmpty || slots < 1) { 
                           Get.snackbar("Missing Info", "Add a name and at least one available slot.", snackPosition: SnackPosition.BOTTOM);
                           return; 
                        }
                        if (isPaid && pricingTiers.isEmpty) { 
                           Get.snackbar("Add Pricing", "Please add at least one price tier for paid parking.", snackPosition: SnackPosition.BOTTOM);
                           return; 
                        }
                        Get.back();
                        await _submitNewParking(nameController.text.trim(), slots, isPaid, pricingTiers);
                      },
                      child: const Text("Submit Spot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
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

  void _showBookingSheet(ParkingSpot spot) {
    if (!spot.isVerified || spot.backendId == null) {
      Get.snackbar("Public Listing", "Public map listings are navigation-only until verified.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (spot.slots <= 0) {
      Get.snackbar("No Slots", "This parking has no available slots right now.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    int durationHours = 1; 
    final vehicleController = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final amount = spot.hasPriceInfo ? spot.amountForHours(durationHours) : null;
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModalHandle(),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: Icon(Icons.event_available_rounded, color: Colors.green.shade700, size: 24)),
                      const SizedBox(width: 16),
                      Expanded(child: Text(spot.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: brandBlue))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _bookingInfoTile("Slots", spot.hasLiveSlots ? "${spot.slots}" : "Map")), 
                      const SizedBox(width: 10),
                      Expanded(child: _bookingInfoTile("Distance", "${spot.distance.toStringAsFixed(2)} km")), 
                      const SizedBox(width: 10),
                      Expanded(child: _bookingInfoTile("Amount", amount == null ? "On approval" : amount == 0 ? "Free" : "Ã¢â€šÂ¹$amount")),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text("Duration", style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [1, 2, 3, 4].map((hours) {
                      final selected = durationHours == hours;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => setModalState(() => durationHours = hours),
                            child: AnimatedContainer(
                               duration: const Duration(milliseconds: 200),
                               padding: const EdgeInsets.symmetric(vertical: 12),
                               alignment: Alignment.center,
                               decoration: BoxDecoration(color: selected ? brandBlue : surfaceGrey, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? brandBlue : Colors.transparent)),
                               child: Text("${hours}h", style: TextStyle(color: selected ? Colors.white : textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                            )
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: vehicleController, textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Vehicle Number", 
                      hintText: "Optional",
                      filled: true, fillColor: surfaceGrey, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                      prefixIcon: const Icon(Icons.directions_car_rounded, color: textGrey),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      onPressed: () async { 
                        Get.back(); 
                        await _submitBooking(spot, durationHours, vehicleController.text.trim()); 
                      },
                      child: Text(
                        amount == 0 ? "Send Booking Request" : amount == null ? "Request Booking" : "Request Booking - Ã¢â€šÂ¹$amount",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: surfaceGrey, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: brandBlue, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // --- Core Form/Network Logics Restored Identical to the very first request ---
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
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        Get.snackbar("Reported", "Thanks! We will verify this.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", _messageFromResponse(response, "Failed to send report"), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Report error: $e");
    }
  }

  Future<void> _submitNewParking(String name, int slots, bool isPaid, List<Map<String, dynamic>> tiers) async {
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) {
      Get.snackbar("Login Required", "Please login before adding a parking spot.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final String baseUrl = dotenv.env['BACKEND_URL'] ?? "http://localhost:8000";
      final center = mapController.camera.center;
      final body = {
        "user_id": int.parse(userId),
        "name": name,
        "latitude": center.latitude,
        "longitude": center.longitude,
        "total_slots": slots,
        "available_slots": slots,
        "fee_type": isPaid ? "paid" : "free",
        "price_per_hour": isPaid && tiers.isNotEmpty ? (tiers.first["price"] as num).toDouble() : 0,
        if (isPaid && tiers.isNotEmpty) "pricing_tiers": tiers,
      };
      final response = await http.post(
        Uri.parse("$baseUrl/v1/parking/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "Parking spot added!", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        await loadNearbyParking();
      } else {
        Get.snackbar("Error", _messageFromResponse(response, "Failed to add spot"), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Add spot error: $e");
      Get.snackbar("Network Error", "Could not add this spot. Please try again.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _submitBooking(ParkingSpot spot, int durationHours, String vehicleNumber) async {
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) {
      Get.snackbar("Login Required", "Please login before booking a parking spot.", snackPosition: SnackPosition.BOTTOM);
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

  String _messageFromResponse(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded["detail"];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) return detail.toString();
        final message = decoded["message"];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return "$fallback (${response.statusCode})";
  }
}
