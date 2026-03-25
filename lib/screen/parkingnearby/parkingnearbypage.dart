import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ParkingSpot {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final int slots;
  double distance;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.slots,
    this.distance = 0,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json["id"],
      name: json["name"],
      lat: json["latitude"],
      lng: json["longitude"],
      slots: json["available_slots"],
    );
  }
}

class NearbyParkingMapScreen extends StatefulWidget {
  const NearbyParkingMapScreen({super.key});

  @override
  State<NearbyParkingMapScreen> createState() =>
      _NearbyParkingMapScreenState();
}

class _NearbyParkingMapScreenState extends State<NearbyParkingMapScreen> {

  GoogleMapController? mapController;

  LatLng userLocation = const LatLng(28.6139, 77.2090);

  List<ParkingSpot> parkingSpots = [];

  /// ROUTE VARIABLES
  Set<Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> routePoints = [];

  /// Replace with your Google API key
  final String googleApiKey ="AIzaSyCDpidG86xLSG6qGmneOoXcAKl_j-ar2PE";

  /// Distance calculation
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {

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

  /// Fetch parking spots
  Future<void> fetchParkingSpots() async {

    final response =
        await http.get(Uri.parse("http://localhost:8000/v1/parking/"));

    if (response.statusCode == 200) {

      List data = jsonDecode(response.body);

      List<ParkingSpot> spots =
          data.map((e) => ParkingSpot.fromJson(e)).toList();

      for (var spot in spots) {

        spot.distance = calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          spot.lat,
          spot.lng,
        );

      }

      spots.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        parkingSpots = spots;
      });

    } else {
      print("Failed to load parking spots");
    }
  }

  /// Get user location
  Future<void> getUserLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("Location disabled");
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(userLocation, 15),
    );

    fetchParkingSpots();
  }

  /// Draw route between user and parking
  Future<void> drawRoute(double destLat, double destLng) async {

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(
          userLocation.latitude,
          userLocation.longitude,
        ),
        destination: PointLatLng(destLat, destLng),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {

      routePoints.clear();

      for (var point in result.points) {
        routePoints.add(
          LatLng(point.latitude, point.longitude),
        );
      }

      setState(() {

        polylines.clear();

        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 6,
            points: routePoints,
          ),
        );

      });
    }
  }

  /// Map markers
  Set<Marker> get markers => parkingSpots.map((spot) {

        return Marker(
          markerId: MarkerId(spot.id.toString()),
          position: LatLng(spot.lat, spot.lng),
          infoWindow: InfoWindow(
            title: spot.name,
            snippet:
                "${spot.distance.toStringAsFixed(2)} km • ${spot.slots} slots available",
          ),
          onTap: () {
            drawRoute(spot.lat, spot.lng);
          },
        );

      }).toSet();

  /// Open Google Maps navigation
  void openGoogleMaps(double lat, double lng) async {

    final uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserLocation();
    fetchParkingSpots();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0XFFfdd708),
            size: 40,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Nearby Parking",
          style: TextStyle(
            fontSize: 18,
            color: Color(0XFFfdd708),
          ),
        ),
      ),

      body: Stack(
        children: [

          /// GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              mapController = controller;
            },
          ),

          /// BOTTOM LIST
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: parkingSpots.length,
                itemBuilder: (context, index) {

                  final spot = parkingSpots[index];

                  return Card(
                    child: ListTile(
                      title: Text(spot.name),
                      subtitle: Text(
                        "${spot.distance.toStringAsFixed(2)} km • ${spot.slots} slots available",
                      ),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            openGoogleMaps(spot.lat, spot.lng),
                        child: const Text("Navigate"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}