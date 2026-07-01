import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/vehicle/transfer_vehicle.dart';
import 'package:parkingmudde/screen/vehicle/vehicledetail.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/widgets/dynamic_ad_carousel.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  List<dynamic> vehicles = [];
  List<dynamic> pendingTransfers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      String userId = "";

      final user = await ApiService.getStoredUser();
      final storedUserId = user?["user_id"]?.toString();

      if (storedUserId == null || storedUserId.isEmpty) {
        setState(() {
          vehicles = [];
          pendingTransfers = [];
          isLoading = false;
        });
        return;
      }

      final fetchedVehicles = await ApiService.getMyVehicles(storedUserId);
      final fetchedPending = await ApiService.getPendingTransfers(storedUserId);

      setState(() {
        vehicles = fetchedVehicles;
        pendingTransfers = fetchedPending;
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
              onPressed: () async {
                await Get.to(() => const AddVehicleScreen(fromMyVehicles: true));
                loadVehicles();
              },
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
                  if (pendingTransfers.isNotEmpty) ...[
                    ...pendingTransfers.map((p) => _pendingTransferCard(context, p)),
                    const SizedBox(height: 16),
                  ],

                  /// 🔹 Ad Banner Carousel
                  const DynamicAdCarousel(pageName: 'My Vehicles'),
                  const SizedBox(height: 20),

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
                        onTap: () async {
                          final result = await Get.to(
                            () => VehicleDetailPage(vehicle: vehicle),
                          );
                          if (result == true) {
                            await loadVehicles();
                            Get.snackbar(
                              "Vehicle Updated",
                              "Vehicle updated successfully",
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                            );
                          } else if (result == "deleted") {
                            await loadVehicles();
                          }
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

  /// 🔹 Ad Banner Carousel
  Widget _buildAdBanner() {
    final List<Map<String, dynamic>> ads = [
      {
        "title": "Register Your Parking Space",
        "desc": "List your empty space & earn passive income",
        "gradient": [const Color(0xFF0F2027), const Color(0xFF2C5364)],
        "icon": Icons.local_parking_rounded,
        "cta": "Coming Soon",
      },
      {
        "title": "Premium Shield Plan",
        "desc": "Get towing protection + priority alerts",
        "gradient": [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
        "icon": Icons.shield_rounded,
        "cta": "Explore",
      },
      {
        "title": "Refer & Earn 50 PM Coins",
        "desc": "Invite friends to ParkingMudde",
        "gradient": [const Color(0xFFFF512F), const Color(0xFFDD2476)],
        "icon": Icons.card_giftcard_rounded,
        "cta": "Share Now",
      },
      {
        "title": "FASTag Integration",
        "desc": "Seamless toll payments from your wallet",
        "gradient": [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        "icon": Icons.nfc_rounded,
        "cta": "Coming Soon",
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          final gradientColors = ad["gradient"] as List<Color>;
          return Container(
            width: 260,
            margin: EdgeInsets.only(right: index < ads.length - 1 ? 14 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (ad["cta"] == "Coming Soon") {
                    Get.snackbar(
                      "Coming Soon",
                      "${ad['title']} will be available soon!",
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ad["title"] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ad["desc"] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                ad["cta"] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ad["icon"] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
  Widget _pendingTransferCard(BuildContext context, dynamic transfer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "Incoming Transfer Request",
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${transfer['brand_name']} ${transfer['model_name']}",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          _miniLicensePlateView(transfer['registration_number'] ?? ''),
          const SizedBox(height: 8),
          Text(
            "From: ${transfer['sender_name']} (${transfer['sender_mobile']})",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToTransfer(transfer['id'], 'decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Decline"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToTransfer(transfer['id'], 'accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Accept", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _respondToTransfer(String transferId, String action) async {
    setState(() => isLoading = true);
    final res = await ApiService.respondToTransfer(transferId: transferId, action: action);
    if (res['success'] == true) {
      Get.snackbar(
        action == 'accept' ? "Transfer Accepted" : "Transfer Declined",
        res['message'] ?? "",
        backgroundColor: action == 'accept' ? Colors.green.shade600 : Colors.orange.shade600,
        colorText: Colors.white,
      );
      await loadVehicles();
    } else {
      Get.snackbar("Error", res['message'] ?? "Action failed");
      setState(() => isLoading = false);
    }
  }

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
                      vehicle['transfer_status'] == 'pending' ? 'transfer_pending' : 'verified',
                    ),
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

  Widget _statusChip(String status) {
    bool isTransferPending = status == 'transfer_pending';
    bool verified = status == 'verified';

    Color bgColor = isTransferPending
        ? Colors.orange.shade50
        : (verified ? Colors.green.shade50 : Colors.red.shade50);
    Color borderColor = isTransferPending
        ? Colors.orange.withValues(alpha: 0.2)
        : (verified ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2));
    Color iconColor = isTransferPending
        ? Colors.orange.shade700
        : (verified ? Colors.green.shade600 : Colors.red.shade600);
    IconData iconData = isTransferPending
        ? Icons.sync_rounded
        : (verified ? Icons.check_circle_rounded : Icons.info);
    String label = isTransferPending
        ? "Transfer Pending"
        : (verified ? "Verified" : "Pending");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(iconData, size: 10, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: iconColor,
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
        actions: vehicle['transfer_status'] == 'pending'
            ? [
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: CupertinoColors.destructiveRed),
                      SizedBox(width: 8),
                      Text("Cancel Transfer"),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    // Mock cancel API logic
                    Get.snackbar(
                      "Transfer Cancelled",
                      "The transfer request has been revoked.",
                      backgroundColor: Colors.orange.shade700,
                      colorText: Colors.white,
                    );
                    await loadVehicles();
                  },
                ),
              ]
            : [
                CupertinoActionSheetAction(
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, color: CupertinoColors.activeBlue),
                      SizedBox(width: 8),
                      Text("Modify / Edit Info"),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final updated = await Get.to(() => AddVehicleScreen(edit: vehicle, fromMyVehicles: true));
                    if (updated == true) {
                      await loadVehicles();
                      Get.snackbar(
                        "Vehicle Updated",
                        "Vehicle updated successfully",
                        backgroundColor: Colors.green.shade600,
                        colorText: Colors.white,
                      );
                    }
                  },
                ),
                CupertinoActionSheetAction(
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: CupertinoColors.activeBlue,
                      ),
                      SizedBox(width: 8),
                      Text("Transfer Ownership"),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final updated = await Get.to(() => TransferVehicleScreen(vehicle: vehicle));
                    if (updated == true) {
                      await loadVehicles();
                    }
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
