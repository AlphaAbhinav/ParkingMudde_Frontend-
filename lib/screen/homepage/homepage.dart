import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:get/get.dart';

// Your core pages imported directly from original snippet
import 'package:parkingmudde/screen/homepage/addvehiclepopup.dart';
import 'package:parkingmudde/screen/notification/notificationpage.dart';
import 'package:parkingmudde/screen/helpingvehicle.dart/vehiclescan.dart';
import 'package:parkingmudde/screen/emergency/emergencyalertpage.dart';
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
import 'package:parkingmudde/screen/account/support_pages.dart';

import '../../services/api_service.dart';

class Homepage extends StatefulWidget {
  final bool fromRegistration;
  const Homepage({super.key, this.fromRegistration = false});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Map<String, dynamic>? user;
  int walletCoins = 247; // Match Figma preview
  bool _hasCheckedVehiclePrompt = false;

  final GlobalKey _reportKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();
  
  late TutorialCoachMark tutorialCoachMark;

  List<dynamic> _topUsers = [];
  Map<String, dynamic>? _myProgress;


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

  void _showBuyVehicleComingSoon() {
    Get.snackbar(
      "Coming Soon",
      "Buy Vehicle marketplace will be available in an upcoming update.",
      backgroundColor: primaryBlue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _showVehicleInsuranceComingSoon() {
    Get.snackbar(
      "Coming Soon",
      "Vehicle insurance renewal and plan comparison will be available soon.",
      backgroundColor: primaryBlue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _showNewsBlogsComingSoon() {
    Get.snackbar(
      "Coming Soon",
      "News, blogs, rules, and parking updates will be available soon.",
      backgroundColor: primaryBlue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _showLeaderboardsComingSoon() {
    Get.snackbar(
      "Coming Soon",
      "Weekly heroes, city champions, and parking warrior rankings are coming soon.",
      backgroundColor: primaryBlue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
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
                      icon: Icons.car_rental_rounded,
                      title: "Buy Vehicle",
                      subtitle: "Coming soon",
                      color: Colors.cyan.shade700,
                      onTap: () {
                        Get.back();
                        _showBuyVehicleComingSoon();
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.health_and_safety_rounded,
                      title: "Vehicle Insurance",
                      subtitle: "Coming soon",
                      color: Colors.deepOrange.shade500,
                      onTap: () {
                        Get.back();
                        _showVehicleInsuranceComingSoon();
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.article_rounded,
                      title: "News & Blogs",
                      subtitle: "Coming soon",
                      color: Colors.blueGrey.shade700,
                      onTap: () {
                        Get.back();
                        _showNewsBlogsComingSoon();
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.emoji_events_rounded,
                      title: "Leaderboards",
                      subtitle: "Coming soon",
                      color: Colors.amber.shade700,
                      onTap: () {
                        Get.back();
                        _showLeaderboardsComingSoon();
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.question_answer_rounded,
                      title: "FAQs",
                      subtitle: "Common answers",
                      color: Colors.green.shade700,
                      onTap: () {
                        Get.back();
                        Get.to(() => const FaqPage());
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
                                CouponStoreScreen(coinsbackBalance: walletCoins),
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
                    _buildQuickActionCard(
                      icon: Icons.local_hospital_rounded,
                      title: "Emergency",
                      subtitle: "Alert contacts",
                      color: Colors.red.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => const EmergencyAlertScreen());
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


  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    return [
      TargetFocus(
        identify: "reportTarget",
        keyTarget: _reportKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Report Wrong Parking",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Use this to report wrongly parked vehicles. Do this responsibly, as the other person will get a coin deduction!",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "helpTarget",
        keyTarget: _helpKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Help a Vehicle",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Alert an owner that their vehicle needs attention (e.g., lights left on, window open) and earn rewards!",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "walletTarget",
        keyTarget: _walletKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "PM Coins",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "These are your PM Coins. Use them in the Coupon Store for exciting discounts!",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (widget.fromRegistration) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showTutorial();
      });
    }
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
        final lb = await ApiService.getLeaderboard();
        final me = await ApiService.getMyGamificationProgress(userId);
        if (mounted) {
          setState(() {
            _topUsers = (lb["parking_warriors"] as List?)?.take(3).toList() ?? [];
            _myProgress = me;
          });
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
                    Icons.notifications_none_rounded,
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
              Container(key: _reportKey, child: _buildFeatureButton(
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
              )),
              const SizedBox(height: 14),

              Container(key: _helpKey, child: _buildFeatureButton(
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
              )),

              const SizedBox(height: 14),

              _buildFeatureButton(
                title: "Emergency Alert",
                subtitle: "Notify contacts and nearby help",
                backgroundColor: Colors.red.shade600,
                iconWidget: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                  ),
                ),
                onTap: () => Get.to(() => const EmergencyAlertScreen()),
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
                  _buildQuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: "Wallet",
                    subtitle: "Manage coins",
                    color: Colors.green.shade600,
                    onTap: () => Get.to(() => WalletScreen(totalCoins: walletCoins)),
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
                key: _walletKey,
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

              // Testimonials Section
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Community Stories",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textBlack,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddReviewDialog(context),
                    child: const Text(
                      "Write a Review",
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTestimonialCard(
                      name: "Rahul Sharma",
                      review: "I was blocked in by another car, but thanks to ParkingMudde, I alerted the owner and they moved it within 5 minutes!",
                      rating: 5,
                    ),
                    const SizedBox(width: 16),
                    _buildTestimonialCard(
                      name: "Priya Singh",
                      review: "Reported a wrongly parked vehicle in my society and earned 50 PM Coins instantly. Great initiative!",
                      rating: 5,
                    ),
                    const SizedBox(width: 16),
                    _buildTestimonialCard(
                      name: "Amit Verma",
                      review: "This app is a lifesaver. Found a nearby parking spot without any hassle.",
                      rating: 5,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Write a Review", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Share your experience with the Parking Mudde community.", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Your review...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Get.snackbar("Thank You!", "Your review has been submitted for approval.",
                    backgroundColor: Colors.green.shade600, colorText: Colors.white);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestimonialCard({required String name, required String review, required int rating}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryBlue.withOpacity(0.1),
                child: Text(name[0], style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: List.generate(
                        rating,
                        (index) => const Icon(Icons.star_rounded, color: secondaryYellow, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$review"',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4, fontStyle: FontStyle.italic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
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
