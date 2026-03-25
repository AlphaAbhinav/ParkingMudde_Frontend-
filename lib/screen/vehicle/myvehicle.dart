import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/vehicle/vehicledetail.dart';
import 'package:parkingmudde/services/api_service.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  List<dynamic> vehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      String userId = "1"; // 🔥 Replace later with actual logged-in user ID

      final data = await ApiService.getMyVehicles(userId);

      setState(() {
        vehicles = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading vehicles: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Color(0XFFfdd708), size: 40),
          onPressed: () {
            Get.back();
          },
        ),
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "My Vehicles",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
              ? const Center(child: Text("No vehicles added yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return InkWell(
                      onTap: () {
                        Get.to(const VehicleDetailPage());
                      },
                      child: _vehicleCard(context, vehicle),
                    );
                  },
                ),
    );
  }

  Widget _vehicleCard(BuildContext context, dynamic vehicle) {
    String fullName =
        "${vehicle['owner_first_name']} ${vehicle['owner_last_name']}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade200,
              image: const DecorationImage(
                image: AssetImage("assets/car.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle['registration_number'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle['registered_mobile'],
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(vehicle['vehicle_type']),
                    const SizedBox(width: 8),
                    _statusChip(true), // 🔥 you can connect real status later
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _vehicleActions(context, vehicle);
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0XFF184b8c).withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0XFF184b8c),
        ),
      ),
    );
  }

  Widget _statusChip(bool verified) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified
            ? Colors.green.shade100
            : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        verified ? "Verified" : "Pending",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: verified ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  void _vehicleActions(BuildContext context, dynamic vehicle) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Text("Edit"),
            onPressed: () {
              Navigator.pop(context);
              Get.to(AddVehicleScreen(edit: vehicle['id'].toString()));
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              debugPrint("Delete vehicle id: ${vehicle['id']}");
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}