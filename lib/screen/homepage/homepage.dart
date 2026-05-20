import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Your core pages imported directly from original snippet
import 'package:parkingmudde/screen/homepage/addvehiclepopup.dart';
import 'package:parkingmudde/screen/notification/notificationpage.dart';
import 'package:parkingmudde/screen/helpingvehicle.dart/vehiclescan.dart';
import 'package:parkingmudde/screen/parkingAlert/parkingalertpage.dart'
    show AlertsScreen;
import 'package:parkingmudde/screen/parkingnearby/parkingnearbypage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/screen/wallet/walletpage.dart';

// Original App Features Restored via Imports
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/couponstore/couponsstorepage.dart';
import 'package:parkingmudde/screen/Referal/referalpage.dart';
import 'package:parkingmudde/screen/visitormangement/vistormangepage.dart';

import '../../services/api_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Map<String, dynamic>? user;
  int walletCoins = 247; // Match Figma preview
  bool _hasCheckedVehiclePrompt = false;

  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color secondaryYellow = Color(0xFFFFB703);
  static const Color backgroundLight = Color(0xFFF6F8FA);
  static const Color textBlack = Color(0xFF222222);

  void getBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const AddVehicleBottomSheet(),
        );
      },
    );
  }

  // --- SEE ALL MENU: Original features bundled beautifully in matching Figma styling ---
  void _showAllQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allow greater height limit mapping bounds limit
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.70, // Occupies lower 70% limits
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "All Services",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Explore all tools available to enhance your experience.",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Expanded full list containing your original items perfectly styled natively
              Expanded(
                child: GridView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.local_parking_rounded,
                      title: "Find Parking",
                      subtitle: "Nearby spots",
                      color: Colors.blue.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => const NearbyParkingMapScreen());
                      },
                    ),

                    // 👉 Book & Pay safely swapped to Wallet Screen (matching constraints)
                    _buildQuickActionCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: "Wallet",
                      subtitle: "Manage coins",
                      color: Colors.green.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => WalletScreen(totalCoins: walletCoins));
                      },
                    ),

                    _buildQuickActionCard(
                      icon: Icons.directions_car_rounded,
                      title: "My Vehicles",
                      subtitle: "Manage fleet",
                      color: Colors.purple.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => const MyVehiclesScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.warning_rounded,
                      title: "Parking Alerts",
                      subtitle: "Stay Notified",
                      color: Colors.orange.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => const AlertsScreen());
                      },
                    ),

                    // Recovered Options Restored here effortlessly:
                    _buildQuickActionCard(
                      icon: Icons.add_circle_rounded,
                      title: "Add Vehicle",
                      subtitle: "Register your car",
                      color: Colors.red.shade500,
                      onTap: () async {
                        Get.back();
                        final added = await Get.to(() => const AddVehicleScreen());
                        if (added == true) {
                          Get.to(() => const MyVehiclesScreen());
                        }
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.share_rounded,
                      title: "Referral",
                      subtitle: "Refer & earn",
                      color: Colors.teal.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => const ReferralScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.storefront_rounded,
                      title: "Coupon Store",
                      subtitle: "Use PM Coins",
                      color: Colors.indigo.shade500,
                      onTap: () {
                        Get.back();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CouponStoreScreen(userCoins: walletCoins),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.badge_rounded,
                      title: "Visitor Mgmt",
                      subtitle: "Security access",
                      color: Colors.brown.shade500,
                      onTap: () {
                        Get.back();
                        Get.to(() => const VisitorManagementScreen());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final storedUser = await ApiService.getStoredUser();
    if (mounted) {
      setState(() => user = storedUser);
      await _showAddVehiclePromptIfNeeded(storedUser?["user_id"]?.toString());
    }

    final freshUser = await ApiService.refreshCurrentUser();
    if (mounted && freshUser != null) {
      setState(() => user = freshUser);
      final userId = freshUser["user_id"]?.toString();
      if (userId != null && userId.isNotEmpty) {
        await _showAddVehiclePromptIfNeeded(userId);
        final wallet = await ApiService.getWalletBalance(userId);
        if (mounted && wallet["balance"] != null) {
          setState(
            () => walletCoins =
                int.tryParse(wallet["balance"].toString()) ?? walletCoins,
          );
        }
      }
    }
  }

  Future<void> _showAddVehiclePromptIfNeeded(String? userId) async {
    if (_hasCheckedVehiclePrompt ||
        userId == null ||
        userId.isEmpty ||
        !mounted) {
      return;
    }

    _hasCheckedVehiclePrompt = true;
    final vehicles = await ApiService.getMyVehicles(userId);
    if (!mounted || vehicles.isNotEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getBottomSheet(context);
    });
  }

  String _userValue(String key, String fallback) {
    final value = user?[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 24,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current location",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: secondaryYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _userValue("location", "New Delhi, India"),
                    style: const TextStyle(
                      color: textBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () => Get.to(() => const Notificationpage()),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: textBlack,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Figma Header Primary Actions layout
              _buildFeatureButton(
                title: "Report Wrong Parking",
                subtitle: "Help clear the way in seconds",
                backgroundColor: primaryBlue,
                iconWidget: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                  ),
                ),
                onTap: () => Get.to(() => const VehicleNumberInputScreen()),
              ),
              const SizedBox(height: 14),

              _buildFeatureButton(
                title: "Help a Vehicle",
                subtitle: "Notify owner & earn rewards",
                backgroundColor: secondaryYellow,
                iconWidget: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                  ),
                ),
                onTap: () => Get.to(() => const VehicleNumberHelpScreen()),
              ),

              const SizedBox(height: 32),

              // Quick Actions Header + View All Restored Method
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textBlack,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAllQuickActions(context),
                    child: const Text(
                      "See all",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Exact Original Figma Top 4 Display with Book&Pay swapped to Wallet natively constraints bounded
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                children: [
                  _buildQuickActionCard(
                    icon: Icons.local_parking_rounded,
                    title: "Find Parking",
                    subtitle: "Nearby spots",
                    color: Colors.blue.shade600,
                    onTap: () => Get.to(() => const NearbyParkingMapScreen()),
                  ),

                  // 👉 Main Quick Actions grid update (Safe swap constraint boundaries mapped identically limit map spaces forms)
                  _buildQuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: "Wallet",
                    subtitle: "Manage coins",
                    color: Colors.green.shade600,
                    onTap: () =>
                        Get.to(() => WalletScreen(totalCoins: walletCoins)),
                  ),

                  _buildQuickActionCard(
                    icon: Icons.directions_car_rounded,
                    title: "My Vehicles",
                    subtitle: "Manage fleet",
                    color: Colors.purple.shade600,
                    onTap: () => Get.to(() => const MyVehiclesScreen()),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.warning_rounded,
                    title: "Parking Alerts",
                    subtitle: "Stay Notified",
                    color: Colors.orange.shade600,
                    onTap: () => Get.to(() => const AlertsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Outstanding Huge Promo Action Panel constraints
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEAD1D), Color(0xFFFF9000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.diamond_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                walletCoins.toString(),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            "PM Coins Balance",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Earn coins by helping others,\npark better",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          Get.to(() => WalletScreen(totalCoins: walletCoins)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.6),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "View Wallet",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Activity Banner mappings standard form boundaries spaces limit
              const Text(
                "Activity Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2FDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100, width: 1),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 16,
                      child: Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "All Clear!",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "No active parking alerts at this moment.\nYour community is parking responsibly.",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            iconWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
