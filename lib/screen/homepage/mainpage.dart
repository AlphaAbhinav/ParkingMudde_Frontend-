import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parkingmudde/screen/account/accountpage.dart';
import 'package:parkingmudde/screen/homepage/homepage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/screen/parkingAlert/parkingalertpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';
import 'package:parkingmudde/screen/emergency/emergencyalertpage.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/widgets/notification_badge.dart';

class Dash extends StatefulWidget {
  final bool fromRegistration;
  final bool autoStartReport;
  const Dash({super.key, this.fromRegistration = false, this.autoStartReport = false});

  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  // Ordered strictly identically to match existing tabs array mapped boundaries map bounds
  List<Widget> get screens => [
    Homepage(fromRegistration: widget.fromRegistration, autoStartReport: widget.autoStartReport),
    const MyVehiclesScreen(),
    const VehicleNumberInputScreen(), // Triggered centrally by FAB Scan limit mapped map
    const AlertsScreen(),
    Accountpage(isFromBottomNav: true, onBackPressed: () => onItemTapped(0)),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
    _unreadCountTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _loadUnreadNotificationCount();
    });
  }

  int selectedIndex = 0;
  int _unreadNotificationCount = 0;
  Timer? _unreadCountTimer;

  final PageController pageController = PageController();

  @override
  void dispose() {
    _unreadCountTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotificationCount() async {
    final count = await ApiService.getUnreadNotificationCountForCurrentUser();
    if (mounted) {
      setState(() => _unreadNotificationCount = count);
    }
  }

  void onPageChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }


  String _reportFeeDescription(int? feeCoins) {
    final feeText = feeCoins == null
        ? "The current reporting fee will be shown before submission."
        : "$feeCoins PM Coins will be deducted only when you enter the vehicle number plate.";
    return "Upload proof first. AI will validate the report before asking for the vehicle plate.\n\nReporting fee: $feeText";
  }

  Future<int?> _loadReportFeeCoins() async {
    final configs = await ApiService.fetchCoinConfig();
    final fee = configs['report_fee_coins'];
    return fee?.toInt();
  }
  void _showScannerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Choose an Action",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBlack),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.security_rounded, color: primaryBlue),
                ),
                title: const Text("Report Wrong Parking", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Upload proof and alert owner", style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  final reportFeeCoins = await _loadReportFeeCoins();
                  if (!mounted) return;
                  _showBeautifulDialog(
                    title: "Report Wrong Parking",
                    description: _reportFeeDescription(reportFeeCoins),
                    icon: Icons.security_rounded,
                    iconColor: primaryBlue,
                    confirmText: "Continue",
                    onConfirm: () {
                      Get.back();
                      Get.to(() => const IssueSelectionScreen(typev: "report"));
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_rounded, color: Colors.green),
                ),
                title: const Text("Help a Vehicle", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Notify owner for help", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const IssueSelectionScreen(typev: "help"));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.red),
                ),
                title: const Text("Emergency Alert", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Notify contacts and nearby help", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const EmergencyAlertScreen());
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBeautifulDialog({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 42),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textBlack,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: textBlack, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void onItemTapped(int selectedItem) {
    if (selectedItem == 1) {
      Get.to(() => const MyVehiclesScreen());
      return;
    }
    if (selectedItem == 3) {
      Get.to(() => const AlertsScreen())?.then((_) {
        _loadUnreadNotificationCount();
      });
      return;
    }
    pageController.jumpToPage(selectedItem);
  }

  // Exact Colors matched visually straight from Figma UI Panel form limits mappings layouts boundary maps mapped limit forms bounds map constraints spaces mapping mapped layout constraints
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF888888);
  static const Color fabYellow = Color(0xFFFFB703);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!didPop) {
          onItemTapped(0);
        }
      },
      child: Scaffold(
        extendBody: true, // Prevents white boxy corners around dock
        body: PageView(
          controller: pageController,
          onPageChanged: onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: screens,
        ),
        // FIGMA PIXEL-PERFECT YELLOW FLOATING ACTION SCAN BUTTON mapping forms spaces limit layouts limits mappings boundaries boundary limits standard layout constraints mapped map boundary limit boundary limits maps boundary boundary boundaries bounds
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showScannerOptions(context),
          backgroundColor: fabYellow,
          elevation: 6,
          shape:
              const CircleBorder(), // Guarantee strict uniform round edge mapping constraints
          child: const Icon(
            Icons
                .qr_code_scanner_rounded, // Best fit for the center icon bound boundary form mappings limits mappings
            color: Colors.white,
            size: 26,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: BottomAppBar(
          shape:
              const CircularNotchedRectangle(), // Clean elegant arch mapping layouts spaces forms mappings maps limits
          notchMargin: 8,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 20,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                _buildTabItem(
                  icon: Icons.directions_car_rounded,
                  label: 'My Vehicles',
                  index: 1,
                ),

                const SizedBox(
                  width: 48,
                ), // Dedicated gap limits mappings spacing

                _buildTabItem(
                  icon: Icons.warning_rounded,
                  label: 'Alerts',
                  index: 3,
                  badgeCount: _unreadNotificationCount,
                ),
                _buildTabItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemTapped(index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NotificationBadge(
            count: badgeCount,
            child: Icon(
              icon,
              color: isSelected ? primaryBlue : subTextGrey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? primaryBlue : subTextGrey,
            ),
          ),
        ],
      ),
    );
  }
}

