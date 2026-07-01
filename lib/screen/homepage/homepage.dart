import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';
import 'package:parkingmudde/screen/parking_prachar/parking_prachar_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:parkingmudde/services/razorpay_web_checkout.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../widgets/dynamic_ad_carousel.dart';
import 'package:parkingmudde/screen/homepage/reels_screen.dart';


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
  final bool autoStartReport;
  const Homepage({super.key, this.fromRegistration = false, this.autoStartReport = false});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Map<String, dynamic>? user;
  int walletCoins = 247; // Match Figma preview
  bool _hasCheckedVehiclePrompt = false;
  final Set<int> _shownAlertIds = {};
  final Set<int> _activeAlertIds = {};
  Timer? _globalAlertTimer;
  bool _isTutorialShowing = false;

  final GlobalKey _reportKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();
  
  late TutorialCoachMark tutorialCoachMark;

  List<dynamic> _topUsers = [];
  Map<String, dynamic>? _myProgress;
  List<dynamic> _ads = [];
  List<dynamic> _blogs = [];
  List<dynamic> _reels = [];

  // Parking alerts counts
  int _alertsRaisedByYou = 0;
  int _alertsAgainstYou = 0;

  late Razorpay _razorpay;
  String? _pendingRazorpayOrderId;
  bool _razorpayEventReceived = false;


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
                      title: "Parking Prachar",
                      subtitle: "Ads & Blogs",
                      color: Colors.blueGrey.shade700,
                      onTap: () {
                        Get.back();
                        Get.to(() => const ParkingPracharScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.emoji_events_rounded,
                      title: "Leaderboards",
                      subtitle: "Top Warriors",
                      color: Colors.amber.shade700,
                      onTap: () {
                        Get.back();
                        Get.to(() => const LeaderboardScreen());
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
                        Get.to(() => const IssueSelectionScreen(typev: "emergency"));
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


  Future<void> _showTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('hasShownTutorial') ?? false;
    
    // Only show if it hasn't been shown before
    if (!hasShown) {
      await prefs.setBool('hasShownTutorial', true);
      if (mounted) {
        _isTutorialShowing = true;
        tutorialCoachMark = TutorialCoachMark(
          targets: _createTargets(),
          colorShadow: Colors.black,
          textSkip: "SKIP",
          paddingFocus: 10,
          opacityShadow: 0.85,
          onFinish: () {
            _isTutorialShowing = false;
            if (mounted) _showAddVehiclePromptIfNeeded(user?["user_id"]?.toString(), bypassCheck: true);
          },
          onSkip: () {
            _isTutorialShowing = false;
            if (mounted) _showAddVehiclePromptIfNeeded(user?["user_id"]?.toString(), bypassCheck: true);
            return true;
          },
        )..show(context: context);
      }
    }
  }
  Widget _buildCoachMarkContent({
    required String title,
    required String body,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/onboarding_guy.png',
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5EE8),
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 13.0),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isFirst)
                      TextButton(
                        onPressed: () {
                          tutorialCoachMark.previous();
                        },
                        child: const Text("Previous", style: TextStyle(color: Colors.grey)),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A5EE8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        if (isLast) {
                          tutorialCoachMark.finish();
                        } else {
                          tutorialCoachMark.next();
                        }
                      },
                      child: Text(isLast ? "Finish" : "Next", style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
              return _buildCoachMarkContent(
                title: "Report Wrong Parking",
                body: "Use this to report wrongly parked vehicles.\n\nDo this responsibly, as the other person will get a coin deduction!",
                isFirst: true,
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
              return _buildCoachMarkContent(
                title: "Help a Vehicle",
                body: "Alert an owner that their vehicle needs attention (e.g., lights left on, window open).\n\nHelp your community and earn rewards!",
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
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildCoachMarkContent(
                title: "PM Coins",
                body: "These are your PM Coins. Use them in the Coupon Store for exciting discounts!",
                isLast: true,
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
    _loadShownAlerts().then((_) => _checkGlobalAlerts());
    _startGlobalAlertPolling();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadUser();
    
    if (widget.fromRegistration) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showTutorial();
      });
    }

    if (widget.autoStartReport) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Get.to(() => const IssueSelectionScreen(typev: "report"));
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
        if (mounted && wallet["pm_coins_balance"] != null) {
          setState(
            () => walletCoins =
                int.tryParse(wallet["pm_coins_balance"].toString()) ?? walletCoins,
          );
        }
        final lb = await ApiService.getLeaderboard();
        final me = await ApiService.getMyGamificationProgress(userId);
        final alerts = await ApiService.getParkingAlerts(userId);
        final fetchedAds = await ApiService.getAds();
        final fetchedBlogs = await ApiService.getBlogs();
        final fetchedReels = await ApiService.getReels();
        if (mounted) {
          setState(() {
            _topUsers = (lb["parking_warriors"] as List?)?.take(3).toList() ?? [];
            _myProgress = me;
            _ads = fetchedAds;
            _blogs = fetchedBlogs;
            _reels = List.from(fetchedReels)..shuffle();
            final counts = alerts["counts"];
            if (counts != null) {
              _alertsRaisedByYou = counts["raised_by_you"] ?? 0;
              _alertsAgainstYou = counts["against_you"] ?? 0;
            }
          });
        }
      }
    }
  }

  Future<void> _showAddVehiclePromptIfNeeded(String? userId, {bool bypassCheck = false}) async {
    if (_hasCheckedVehiclePrompt && !bypassCheck) return;
    if (userId == null || userId.isEmpty || !mounted) return;
    
    if (_isTutorialShowing) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hasShownTutorial = prefs.getBool('hasShownTutorial') ?? false;
    if (widget.fromRegistration && !hasShownTutorial && !bypassCheck) {
      // Delay showing the vehicle prompt until the tutorial finishes
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

  Widget _buildAdCarousel() {
    return const DynamicAdCarousel(pageName: 'Home');
  }

  Widget _buildParkingPrachaarBlogs() {
    final displayBlogs = _blogs.isNotEmpty ? _blogs : [
      {
        "title": "Smart Parking Zones Active",
        "description": "Find new automated zones in Sector 14.",
        "image_url": "https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?q=80&w=300&auto=format&fit=crop",
      },
      {
        "title": "FASTag Integration Live",
        "description": "Pay seamlessly with your vehicle FASTag.",
        "image_url": "https://images.unsplash.com/photo-1549317661-bd32c8ce0be2?q=80&w=300&auto=format&fit=crop",
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Parking Prachaar Blogs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const ParkingPracharScreen()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "See All",
                style: TextStyle(
                  color: Color(0XFF184B8C),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: displayBlogs.length,
            itemBuilder: (context, index) {
              final news = displayBlogs[index];
              final rawImageUrl = news["image_url"] ?? '';
              final imageUrl = rawImageUrl.startsWith('/') ? '${ApiService.baseUrl}$rawImageUrl' : rawImageUrl;
              
              return GestureDetector(
                onTap: () async {
                  final targetUrl = news["url"];
                  if (targetUrl != null && targetUrl.toString().isNotEmpty) {
                    var uri = Uri.parse(targetUrl.toString());
                    if (!uri.hasScheme) {
                      uri = Uri.parse('https://${targetUrl.toString()}');
                    }
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint("Could not launch $targetUrl");
                    }
                  }
                },
                child: Container(
                width: 240,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news["title"] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            news["description"] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParkingPrachaarReels() {
    final displayReels = _reels.isNotEmpty ? _reels : [
      {
        "id": "reel_1",
        "title": "How to park like a pro",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1511674900547-0e9e1bbaf259?q=80&w=300&auto=format&fit=crop",
        "author": "Parking Mudde",
        "likes": 1205,
        "comments": 45
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Parking Prachaar Reels",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => ReelsScreen(reels: displayReels, initialIndex: 0)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Watch All",
                style: TextStyle(
                  color: Color(0XFF184B8C),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: displayReels.length,
            itemBuilder: (context, index) {
              final reel = displayReels[index];
              return GestureDetector(
                onTap: () {
                  Get.to(() => ReelsScreen(reels: displayReels, initialIndex: index));
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage((reel['thumbnail_url'] ?? '').startsWith('/') ? '${ApiService.baseUrl}${reel['thumbnail_url']}' : (reel['thumbnail_url'] ?? '')),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          reel['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= RAZORPAY LOGIC =================
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _razorpayEventReceived = true;
    String orderId = _pendingRazorpayOrderId ?? '';
    _pendingRazorpayOrderId = null;

    if (!mounted) return;
    
    Get.snackbar("Success", "Proceeding to report.", 
      backgroundColor: Colors.green, colorText: Colors.white);
      
    Get.to(() => IssueSelectionScreen(
      razorpayOrderId: orderId,
      razorpayPaymentId: response.paymentId,
      razorpaySignature: response.signature,
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _razorpayEventReceived = true;
    _pendingRazorpayOrderId = null;
    Get.defaultDialog(
      title: "Payment Failed",
      middleText: response.message ?? 'Payment was not completed or was cancelled.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _razorpayEventReceived = true;
    _pendingRazorpayOrderId = null;
    Get.defaultDialog(
      title: "External Wallet",
      middleText: 'Payment via ${response.walletName} selected.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  Future<void> _startReportPayment() async {
    Get.to(() => const IssueSelectionScreen(typev: "report"));
    return;

    Get.defaultDialog(
      title: "Processing",
      content: const CircularProgressIndicator(),
      barrierDismissible: false,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString("user_id") ?? "0";
      
      final orderResult = await ApiService.createReportRazorpayOrder(userId: userIdStr);
      
      if (Get.isDialogOpen == true) Get.back();

      if (orderResult['success'] == false) {
        Get.defaultDialog(
          title: "API Error",
          middleText: orderResult['message']?.toString() ?? 'Could not initiate payment.',
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
        return;
      }

      final razorpayOrderId = orderResult['razorpay_order_id']?.toString();
      final razorpayKeyId = orderResult['razorpay_key_id']?.toString();

      if (razorpayOrderId == null || razorpayKeyId == null) {
        Get.defaultDialog(
          title: "Error",
          middleText: "Invalid response from server.",
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
        return;
      }

      _pendingRazorpayOrderId = razorpayOrderId;
      _razorpayEventReceived = false;

      final options = {
        'key': razorpayKeyId,
        'order_id': razorpayOrderId,
        'amount': 100, // 1 INR in paise
        'currency': 'INR',
        'name': 'Parking Mudde',
        'description': 'Report Wrong Parking',
        'prefill': {
          'contact': '',
          'email': ''
        }
      };

      if (kIsWeb) {
        await openRazorpayWebCheckout(
          Map<String, dynamic>.from(options),
          onSuccess: (response) {
            _handlePaymentSuccess(PaymentSuccessResponse(
              response['razorpay_payment_id'],
              response['razorpay_order_id'],
              response['razorpay_signature'],
              null,
            ));
          },
          onFailure: (message) {
            _handlePaymentError(PaymentFailureResponse(0, message, null));
          },
          onDismiss: () {
            _handlePaymentError(PaymentFailureResponse(0, 'Cancelled', null));
          },
        );
      } else {
        _razorpay.open(options);
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.defaultDialog(
        title: "Error",
        middleText: e.toString(),
        textConfirm: "OK",
        onConfirm: () => Get.back(),
      );
    }
  }

  void _handleReportClick() async {
    final storedUser = await ApiService.getStoredUser();
    final userId = storedUser?["user_id"]?.toString() ?? "";
    if (userId.isEmpty) {
      Get.snackbar("Error", "Session invalid. Please login again.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    Get.defaultDialog(
      title: "Checking Account",
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            SizedBox(height: 16),
            Text("Checking registered vehicles...", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final vehicles = await ApiService.getMyVehicles(userId);
      if (Get.isDialogOpen == true) Get.back();

      if (vehicles.isEmpty) {
        Get.defaultDialog(
          title: "Vehicle Required",
          middleText: "You must add at least one vehicle to your account to report wrong parking.",
          textConfirm: "Add Vehicle",
          textCancel: "Cancel",
          onConfirm: () {
            Get.back();
            Get.to(() => const MyVehiclesScreen());
          },
        );
        return;
      }

      Get.defaultDialog(
                title: "Report Wrong Parking",
        middleText: "Upload proof first. AI will validate the report before asking for the vehicle plate.",
        textConfirm: "Proceed to Report",
        textCancel: "Cancel",
        onConfirm: () {
          Get.back();
          Get.to(() => const IssueSelectionScreen(typev: "report"));
        },
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar("Error", "Failed to verify vehicle registration. Please try again.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
  // ================= END RAZORPAY LOGIC =================

  @override
  void dispose() {
    _globalAlertTimer?.cancel();
    super.dispose();
  }

    Future<void> _loadShownAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('actioned_alert_ids') ?? [];
    if (mounted) {
      setState(() {
        _shownAlertIds.addAll(list.map((e) => int.tryParse(e) ?? 0));
      });
    }
  }

  Future<void> _saveShownAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _shownAlertIds.map((e) => e.toString()).toList();
    await prefs.setStringList('actioned_alert_ids', list);
  }

void _startGlobalAlertPolling() {
    _globalAlertTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkGlobalAlerts();
    });
  }

Future<void> _checkGlobalAlerts() async {
      try {
        final notifications = await ApiService.getNotificationsForCurrentUser();
        for (var n in notifications) {
          final int id = n['id'] ?? 0;
          if (id == 0 || _shownAlertIds.contains(id) || _activeAlertIds.contains(id)) continue;

          final type = n['type'] ?? '';
          final status = n['status'] ?? '';
          
          if (type == 'VEHICLE_REPORTED_AGAINST_YOU' && status == 'SUBMITTED') {
            _showBigPopup(
              "YOUR CAR IS BEING REPORTED",
              "Please go and resolve the parking issue.",
              Colors.redAccent,
              n,
            );
          } else if (type == 'HELP_VEHICLE' && status == 'SUBMITTED') {
            _shownAlertIds.add(id);
      _saveShownAlerts();
            _showBigPopup("HELP REQUESTED!", "Someone needs you to move your vehicle.", Colors.orangeAccent, n);
          }
        }
      } catch (e) {
        // Ignore network errors in background poll
      }
  }

  void _showBigPopup(String title, String subtitle, Color bgColor, dynamic notificationData) {
    if (!mounted) return;
    int secondsLeft = 30;
    Timer? dialogTimer;
    final int alertId = notificationData['id'] is int
        ? notificationData['id']
        : int.tryParse(notificationData['id']?.toString() ?? '') ?? 0;
    final bool persistUntilAction =
        notificationData['type'] == 'VEHICLE_REPORTED_AGAINST_YOU';

    if (alertId != 0) {
      _activeAlertIds.add(alertId);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: bgColor.withOpacity(1.0), // Consume the whole screen
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!persistUntilAction) {
              dialogTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
                if (secondsLeft == 0) {
                  t.cancel();
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                } else {
                  setDialogState(() {
                    secondsLeft--;
                  });
                }
              });
            }

            return WillPopScope(
              onWillPop: () async => false, // Prevent dismissing by back button
              child: Scaffold(
                backgroundColor: bgColor, // Full screen background color matching bgColor
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.white, size: 100),
                          const SizedBox(height: 32),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (!persistUntilAction)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Time remaining: $secondsLeft seconds",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 60),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: bgColor,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                dialogTimer?.cancel();
                                if (notificationData['report_id'] != null) {
                                  await ApiService.triggerOnTheWay(
                                    reportId: notificationData['report_id'].toString(),
                                  );
                                }
                                if (notificationData['id'] != null) {
                                  await ApiService.updateNotificationStatus(
                                    notificationData['id'].toString(),
                                    "IN_PROGRESS",
                                  );
                                }
                                if (alertId != 0) {
                                  _shownAlertIds.add(alertId);
                                  _activeAlertIds.remove(alertId);
                                  await _saveShownAlerts();
                                }
                                if (Navigator.canPop(dialogContext)) {
                                  Navigator.pop(dialogContext);
                                }
                              },
                              child: const Text(
                                "I AM ON MY WAY",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      dialogTimer?.cancel();
      if (alertId != 0 && !_shownAlertIds.contains(alertId)) {
        _activeAlertIds.remove(alertId);
      }
    });
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
              _buildFloatingNewsTicker(),
                const SizedBox(height: 16),
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
                onTap: _handleReportClick,
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
                onTap: () => Get.to(() => const IssueSelectionScreen(typev: "help")),
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
                onTap: () => Get.to(() => const IssueSelectionScreen(typev: "emergency")),
              ),

              const SizedBox(height: 32),

              // Add Vehicle & My Vehicles Half Section
              _buildVehicleHalfSection(),
              const SizedBox(height: 24),

              // Leaderboard (ABOVE Quick Actions)
                _buildHomeLeaderboardSection(),
                const SizedBox(height: 24),

              // Suggest Society Section
              _buildSuggestSocietySection(),
              const SizedBox(height: 32),

              _buildAdCarousel(),
              const SizedBox(height: 24),

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
                    Container(key: _walletKey, child: _buildQuickActionCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: "Wallet",
                      subtitle: "Manage coins",
                      color: Colors.green.shade600,
                      onTap: () => Get.to(() => WalletScreen(totalCoins: walletCoins)),
                    ),),
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

                // FAQ & Blogs (BELOW Quick Actions)
                const Text(
                  "Help & Info",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textBlack,
                  ),
                ),
                const SizedBox(height: 16),
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
                      icon: Icons.article_rounded,
                      title: "Parking Prachar",
                      subtitle: "Ads & Blogs",
                      color: Colors.blueGrey.shade700,
                      onTap: () => Get.to(() => const ParkingPracharScreen()),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.question_answer_rounded,
                      title: "FAQs",
                      subtitle: "Get Help",
                      color: Colors.indigo.shade600,
                      onTap: () => Get.to(() => const FaqPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 32),


              _buildParkingPrachaarBlogs(),
                const SizedBox(height: 32),
              _buildParkingPrachaarReels(),
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

              // Parking Alerts Count Tag
              _buildParkingAlertsCountTag(),
              const SizedBox(height: 24),

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

              const SizedBox(height: 32),

              // Refer & Earn Section
              _buildReferAndEarnSection(),

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

  Widget _buildHomeLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "Top Contributors",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            GestureDetector(
              onTap: () => Get.to(() => const LeaderboardScreen()),
              child: const Text(
                "View All",
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_topUsers.isNotEmpty)
                ..._topUsers.asMap().entries.map((entry) {
                  int index = entry.key;
                  var u = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: index == 0
                              ? Colors.amber.shade100
                              : index == 1
                                  ? Colors.grey.shade200
                                  : index == 2
                                      ? Colors.brown.shade100
                                      : Colors.blue.shade50,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? Colors.amber.shade800
                                  : index == 1
                                      ? Colors.grey.shade700
                                      : index == 2
                                          ? Colors.brown.shade700
                                          : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryBlue.withValues(alpha: 0.1),
                          backgroundImage: u["profile_pic"] != null
                              ? NetworkImage(u["profile_pic"])
                              : null,
                          child: u["profile_pic"] == null
                              ? const Icon(Icons.person,
                                  size: 20, color: primaryBlue)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            u["full_name"] ?? "User",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.diamond_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${u["score"] ?? 0}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Be the first to get on the leaderboard!",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              const Divider(height: 24),
              // Current User position
              Row(
                children: [
                  const Text(
                    "Your Rank:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _myProgress != null && _myProgress!['current_rank'] != null ? "#${_myProgress!['current_rank']}" : "-",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingNewsTicker() {
    return Container(
    );
  }

  // ================= NEW SECTION: ADD VEHICLE & MY VEHICLES (HALF-HALF) =================
  Widget _buildVehicleHalfSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final added = await Get.to(() => const AddVehicleScreen());
              if (added == true) {
                Get.to(() => const MyVehiclesScreen());
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Add Vehicle",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Register your car",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: () => Get.to(() => const MyVehiclesScreen()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "My Vehicles",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage your fleet",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= NEW SECTION: SUGGEST SOCIETY =================
  Widget _buildSuggestSocietySection() {
    return GestureDetector(
      onTap: () => _showSuggestSocietyDialog(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Suggest a Society",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Help us expand to your community",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuggestSocietyDialog() {
    final societyNameController = TextEditingController();
    final addressPincodeController = TextEditingController();
    final contactDetailsController = TextEditingController();
    final personalNameController = TextEditingController();

    // Pre-fill contact details from user profile
    final userName = user?["full_name"]?.toString() ?? "";
    final userMobile = user?["mobile_number"]?.toString() ?? "";
    final userEmail = user?["email"]?.toString() ?? "";
    final userLocation = user?["location"]?.toString() ?? "";

    personalNameController.text = userName;
    contactDetailsController.text = userMobile.isNotEmpty ? userMobile : userEmail;
    addressPincodeController.text = userLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Suggest a Society",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Help ParkingMudde expand to your society. We'll review your suggestion and reach out.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSocietyTextField(
                    controller: societyNameController,
                    label: "Society / Community Name",
                    icon: Icons.location_city_rounded,
                    hint: "e.g. Green Valley Apartments",
                  ),
                  const SizedBox(height: 16),
                  _buildSocietyTextField(
                    controller: addressPincodeController,
                    label: "Address / Pincode",
                    icon: Icons.pin_drop_rounded,
                    hint: "e.g. Sector 14, Gurgaon - 122001",
                  ),
                  const SizedBox(height: 16),
                  _buildSocietyTextField(
                    controller: personalNameController,
                    label: "Your Name",
                    icon: Icons.person_rounded,
                    hint: "e.g. Rahul Sharma",
                  ),
                  const SizedBox(height: 16),
                  _buildSocietyTextField(
                    controller: contactDetailsController,
                    label: "Contact Details",
                    icon: Icons.phone_rounded,
                    hint: "Phone or email",
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "* Pre-filled from your profile. You can update if needed.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = societyNameController.text.trim();
                      final address = addressPincodeController.text.trim();
                      final contact = contactDetailsController.text.trim();
                      final pName = personalNameController.text.trim();

                      if (name.isEmpty || address.isEmpty || contact.isEmpty || pName.isEmpty) {
                        Get.snackbar("Missing Info", "Please fill all fields.",
                            backgroundColor: Colors.orange, colorText: Colors.white);
                        return;
                      }

                      final userId = user?["user_id"];
                      if (userId == null) {
                        Get.snackbar("Error", "Please log in first.",
                            backgroundColor: Colors.red, colorText: Colors.white);
                        return;
                      }

                      Navigator.pop(ctx);

                      final result = await ApiService.suggestSociety(
                        userId: int.tryParse(userId.toString()) ?? 0,
                        societyName: name,
                        addressPincode: address,
                        contactDetails: "$pName ($contact)",
                      );

                      if (result["success"] == true) {
                        Get.snackbar(
                          "Thank You! 🎉",
                          "Your society suggestion has been submitted. We'll review it soon!",
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      } else {
                        Get.snackbar(
                          "Error",
                          result["message"] ?? "Something went wrong.",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Submit Suggestion",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocietyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ================= NEW SECTION: PARKING ALERTS COUNT TAG =================
  Widget _buildParkingAlertsCountTag() {
    final int totalAlerts = _alertsRaisedByYou + _alertsAgainstYou;

    return GestureDetector(
      onTap: () => Get.to(() => const AlertsScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: totalAlerts > 0 ? Colors.orange.shade200 : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: totalAlerts > 0 ? Colors.orange.shade700 : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Parking Alerts",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textBlack,
                      ),
                    ),
                  ],
                ),
                if (totalAlerts > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$totalAlerts Active",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Raised by You",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$_alertsRaisedByYou",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Against You",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$_alertsAgainstYou",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Tap to view all alerts →",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NEW SECTION: REFER & EARN =================
  Widget _buildReferAndEarnSection() {
    final referralCode = user?["referral_code"]?.toString() ?? "";

    return GestureDetector(
      onTap: () => Get.to(() => const ReferralScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Refer & Earn",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Invite friends to ParkingMudde and\nearn PM Coins for every referral!",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  if (referralCode.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
