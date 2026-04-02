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
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Modern super-app light silver base
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "My Garage",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),

      /// 🔹 Sleek Professional Floating Action Add Button
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Get.to(() => const AddVehicleScreen()),
              backgroundColor: const Color(0XFF184B8C),
              elevation: 4,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
              ),
              label: const Text(
                "New Vehicle",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      color: Color(0XFF184b8c),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Syncing Your Garage...",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : vehicles.isEmpty
          ? _emptyStateView()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Registered Fleet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${vehicles.length} Total",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0XFF184b8c),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), // Managed seamlessly inside SCV above
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Get.to(const VehicleDetailPage());
                        },
                        child: _vehicleCard(context, vehicle),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  /// 🔹 Empty Premium State Handling
  Widget _emptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_outlined,
                size: 70,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Garage is Empty",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't added any vehicles to your secure portfolio yet. Tap the + Add button to securely bind a vehicle.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade500,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 The Highly Enhanced Card Identity
  Widget _vehicleCard(BuildContext context, dynamic vehicle) {
    String fullName =
        "${vehicle['owner_first_name']} ${vehicle['owner_last_name']}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Top align properly
        children: [
          /// Safe Modern Network-Ready Image Block with subtle soft shadows
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                "assets/car.jpeg",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.blueGrey.shade50,
                  child: const Icon(
                    Icons.car_crash_rounded,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// Core Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HSRP Miniature Plate directly mimicking SuperApp theme
                _miniLicensePlateView(
                  vehicle['registration_number'] ?? 'NO-REG-NUM',
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.person, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.phone_iphone_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vehicle['registered_mobile'] ?? 'N/A',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _chip(vehicle['vehicle_type'] ?? 'Unknown'),
                    const SizedBox(width: 8),
                    _statusChip(
                      true,
                    ), // 🔥 Configurable as asked in code natively
                  ],
                ),
              ],
            ),
          ),

          /// Unified Clean Action Icon trigger
          InkWell(
            onTap: () => _vehicleActions(context, vehicle),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: const Icon(Icons.more_vert, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  /// Minified replication of IND license-plate standard for highly accurate visuals.
  Widget _miniLicensePlateView(String regNumber) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 2,
              left: 3,
              right: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "IND",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              regNumber.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.commute, size: 10, color: Colors.indigo.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.indigo.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (verified ? Colors.green : Colors.orange).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle_rounded : Icons.info,
            size: 10,
            color: verified ? Colors.green.shade600 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? "Verified" : "Pending",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: verified ? Colors.green.shade800 : Colors.orange.shade900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _vehicleActions(BuildContext context, dynamic vehicle) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(
          vehicle['registration_number'] ?? 'Vehicle Access',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        message: const Text(
          "Select operation parameters for the listed vehicle entity.",
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text("Modify / Edit Info"),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              Get.to(AddVehicleScreen(edit: vehicle['id'].toString()));
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_sweep_rounded,
                  color: CupertinoColors.destructiveRed,
                ),
                SizedBox(width: 8),
                Text("Permanently Disconnect"),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              // Handle Delete Operations Logic Next safely from here exactly as prior.
              debugPrint("Delete vehicle id: ${vehicle['id']}");
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text("Abort Operation"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
