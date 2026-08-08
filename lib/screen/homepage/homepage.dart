import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';
import 'package:parkingmudde/screen/parking_prachar/parking_prachar_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'dart:async';
import 'dart:convert';
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
import 'package:parkingmudde/screen/vehicle/my_challans_screen.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/screen/wallet/walletpage.dart';
import 'package:parkingmudde/screen/common/feature_walkthrough_dialog.dart';
import 'package:parkingmudde/screen/alerts/fullscreen_alert.dart';
import 'package:parkingmudde/services/alert_state.dart';

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
  const Homepage({
    super.key,
    this.fromRegistration = false,
    this.autoStartReport = false,
  });

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
  bool _isFirstRunGuideShowing = false;

  final GlobalKey _reportKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;

  List<dynamic> _topUsers = [];
  Map<String, dynamic>? _myProgress;
  List<dynamic> _ads = [];
  List<dynamic> _blogs = [];
  List<dynamic> _reels = [];
  List<dynamic> _faqs = [];
  List<dynamic> _communityStories = [];
  Map<String, int> _communityImpactStats = const {
    "users": 0,
    "vehicles": 0,
    "vehicles_reported": 0,
    "vehicles_helped": 0,
    "emergencies_solved": 0,
  };
  bool _isLoadingCommunityImpact = true;
  Map<String, dynamic> _coinOffer = const {
    "discount_percent": 0,
    "tag": "Launch Offer",
    "is_active": false,
  };

  // Parking alerts counts
  int _alertsRaisedByYou = 0;
  int _alertsAgainstYou = 0;

  late Razorpay _razorpay;
  String? _pendingRazorpayOrderId;
  bool _razorpayEventReceived = false;

  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color secondaryYellow = Color(0xFFFFB703);
  static const Color backgroundLight = Color(
    0xFFF8FAFC,
  ); // Slightly cooler, modern light bg
  static const Color textBlack = Color(0xFF1E293B); // Modern slate black

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
      borderRadius: 12,
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
      borderRadius: 12,
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
      borderRadius: 12,
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
      borderRadius: 12,
    );
  }

  // --- SEE ALL MENU: Original features bundled beautifully in matching Figma styling ---
  void _showAllQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
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
                  letterSpacing: -0.5,
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

              Expanded(
                child: GridView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.85,
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
                      icon: Icons.gavel_rounded,
                      title: "Challans/Towed",
                      subtitle: "View history",
                      color: Colors.red.shade500,
                      onTap: () {
                        Get.back();
                        Get.to(() => const MyChallansScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.directions_car_rounded,
                      title: "My Vehicles",
                      subtitle: "Manage fleet",
                      color: Colors.purple.shade500,
                      onTap: () {
                        Get.back();
                        Get.to(() => const MyVehiclesScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.warning_rounded,
                      title: "Parking Alerts",
                      subtitle: "Stay Notified",
                      color: Colors.orange.shade500,
                      onTap: () {
                        Get.back();
                        Get.to(() => const AlertsScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.add_circle_rounded,
                      title: "Add Vehicle",
                      subtitle: "Register your car",
                      color: Colors.teal.shade500,
                      onTap: () async {
                        Get.back();
                        final added = await Get.to(
                          () => const AddVehicleScreen(),
                        );
                        if (added == true) {
                          Get.to(() => const MyVehiclesScreen());
                        }
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.share_rounded,
                      title: "Referral",
                      subtitle: "Refer & earn",
                      color: Colors.indigo.shade500,
                      onTap: () {
                        Get.back();
                        Get.to(() => const ReferralScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.car_rental_rounded,
                      title: "Buy Vehicle",
                      subtitle: "Coming soon",
                      color: Colors.cyan.shade600,
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
                      color: Colors.blueGrey.shade600,
                      onTap: () {
                        Get.back();
                        Get.to(() => const ParkingPracharScreen());
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.emoji_events_rounded,
                      title: "Leaderboards",
                      subtitle: "Top Warriors",
                      color: Colors.amber.shade600,
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
                      color: Colors.indigo.shade400,
                      onTap: () {
                        Get.back();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CouponStoreScreen(
                              coinsbackBalance: walletCoins,
                            ),
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

  Future<void> _showFirstRunGuideIfNeeded() async {
    if (!mounted || _isFirstRunGuideShowing || widget.autoStartReport) return;

    final prefs = await SharedPreferences.getInstance();
    final hasPendingSignupGuide =
        prefs.getBool('pending_feature_walkthrough') ?? false;
    if (!widget.fromRegistration && !hasPendingSignupGuide) return;

    final hasSeenGuide = prefs.getBool('has_seen_feature_walkthrough') ?? false;
    if (hasSeenGuide && !hasPendingSignupGuide) return;

    _isFirstRunGuideShowing = true;
    await prefs.setBool('has_seen_feature_walkthrough', true);
    await prefs.setBool('pending_feature_walkthrough', false);
    await prefs.setBool('hasShownTutorial', true);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FeatureWalkthroughDialog(),
    );

    _isFirstRunGuideShowing = false;
    if (mounted) {
      await _showAddVehiclePromptIfNeeded(
        user?["user_id"]?.toString(),
        bypassCheck: true,
      );
    }
  }

  // --- Tutorial Setup remains identical ---
  Future<void> _showTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('hasShownTutorial') ?? false;

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
            if (mounted)
              _showAddVehiclePromptIfNeeded(
                user?["user_id"]?.toString(),
                bypassCheck: true,
              );
          },
          onSkip: () {
            _isTutorialShowing = false;
            if (mounted)
              _showAddVehiclePromptIfNeeded(
                user?["user_id"]?.toString(),
                bypassCheck: true,
              );
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
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.4,
                    fontSize: 13.0,
                  ),
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
                        child: const Text(
                          "Previous",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A5EE8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        if (isLast) {
                          tutorialCoachMark.finish();
                        } else {
                          tutorialCoachMark.next();
                        }
                      },
                      child: Text(
                        isLast ? "Finish" : "Next",
                        style: const TextStyle(fontSize: 13),
                      ),
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
                body:
                    "Use this to report wrongly parked vehicles.\n\nDo this responsibly, as the other person will get a coin deduction!",
                isFirst: true,
              );
            },
          ),
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
                body:
                    "Alert an owner that their vehicle needs attention (e.g., lights left on, window open).\n\nHelp your community and earn rewards!",
                isLast: true,
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadShownAlerts().then((_) => _checkGlobalAlerts());
    _startGlobalAlertPolling();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }

    _loadUser();
    _loadCommunityStories();
    _loadCommunityImpactStats();
    _loadCoinOffer();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _showFirstRunGuideIfNeeded();
    });

    if (widget.autoStartReport) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Get.to(() => const IssueSelectionScreen(typev: "report"));
      });
    }
  }

  Future<void> _loadCommunityStories() async {
    final stories = await ApiService.getCommunityStories();
    if (mounted) {
      setState(() => _communityStories = stories);
    }
  }

  Future<void> _loadCommunityImpactStats() async {
    final stats = await ApiService.getCommunityImpactStats();
    if (mounted) {
      setState(() {
        _isLoadingCommunityImpact = false;
        if (stats.isNotEmpty) {
          _communityImpactStats = {
            "users": stats["users"] ?? 0,
            "vehicles": stats["vehicles"] ?? 0,
            "vehicles_reported": stats["vehicles_reported"] ?? 0,
            "vehicles_helped": stats["vehicles_helped"] ?? 0,
            "emergencies_solved": stats["emergencies_solved"] ?? 0,
          };
        }
      });
    }
  }

  Future<void> _loadCoinOffer() async {
    final offer = await ApiService.fetchCoinOffer();
    if (mounted) {
      setState(() => _coinOffer = offer);
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
        if (mounted) {
          setState(() {
            final pm =
                int.tryParse(wallet["pm_coins_balance"]?.toString() ?? "0") ??
                0;
            final cb =
                int.tryParse(wallet["coinsback_balance"]?.toString() ?? "0") ??
                0;
            walletCoins = pm + cb;
          });
        }
        final lb = await ApiService.getLeaderboard();
        final me = await ApiService.getMyGamificationProgress(userId);
        final alerts = await ApiService.getParkingAlerts(userId);
        final fetchedAds = await ApiService.getAds();
        final fetchedBlogs = await ApiService.getBlogs();
        final fetchedReels = await ApiService.getReels();
        final fetchedFaqs = await ApiService.getFaqs();
        final fetchedCommunityStories = await ApiService.getCommunityStories();
        if (mounted) {
          setState(() {
            _topUsers =
                (lb["parking_warriors"] as List?)?.take(3).toList() ?? [];
            _myProgress = me;
            _ads = fetchedAds;
            _blogs = fetchedBlogs;
            _reels = List.from(fetchedReels)..shuffle();
            _faqs = fetchedFaqs;
            _communityStories = fetchedCommunityStories;
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

  Future<void> _showAddVehiclePromptIfNeeded(
    String? userId, {
    bool bypassCheck = false,
  }) async {
    if (_hasCheckedVehiclePrompt && !bypassCheck) return;
    if (userId == null || userId.isEmpty || !mounted) return;

    if (_isTutorialShowing || _isFirstRunGuideShowing) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenGuide = prefs.getBool('has_seen_feature_walkthrough') ?? false;
    if (widget.fromRegistration && !hasSeenGuide && !bypassCheck) {
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
    if (_blogs.isEmpty) return const SizedBox.shrink();
    final displayBlogs = _blogs;

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
                fontWeight: FontWeight.w700,
                color: textBlack,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const ParkingPracharScreen()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "See All",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
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
              final imageUrl = rawImageUrl.startsWith('/')
                  ? '${ApiService.baseUrl}$rawImageUrl'
                  : rawImageUrl;

              return GestureDetector(
                onTap: () async {
                  final targetUrl = news["url"];
                  if (targetUrl != null && targetUrl.toString().isNotEmpty) {
                    var uri = Uri.parse(targetUrl.toString());
                    if (!uri.hasScheme) {
                      uri = Uri.parse('https://${targetUrl.toString()}');
                    }
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
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
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 100,
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
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
                                color: textBlack,
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
    if (_reels.isEmpty) return const SizedBox.shrink();
    final displayReels = _reels;

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
                fontWeight: FontWeight.w700,
                color: textBlack,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(
                () => ReelsScreen(reels: displayReels, initialIndex: 0),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Watch All",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
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
                  Get.to(
                    () => ReelsScreen(reels: displayReels, initialIndex: index),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(
                        (reel['thumbnail_url'] ?? '').startsWith('/')
                            ? '${ApiService.baseUrl}${reel['thumbnail_url']}'
                            : (reel['thumbnail_url'] ?? ''),
                      ),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: Text(
                          reel['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
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

  Widget _buildFaqPreview() {
    final displayFaqs = _faqs
        .whereType<Map>()
        .map(
          (item) => {
            "question": item["question"]?.toString().trim() ?? "",
            "answer": item["answer"]?.toString().trim() ?? "",
          },
        )
        .where(
          (faq) => faq["question"]!.isNotEmpty && faq["answer"]!.isNotEmpty,
        )
        .take(3)
        .toList();

    if (displayFaqs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "FAQs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textBlack,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const FaqPage()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "See All",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: displayFaqs
              .map(
                (faq) => InkWell(
                  onTap: () => Get.to(() => const FaqPage()),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: _premiumCardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.question_answer_rounded,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                faq["question"]!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: textBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                faq["answer"]!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.blueGrey.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
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

    Get.snackbar(
      "Success",
      "Proceeding to report.",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Get.to(
      () => IssueSelectionScreen(
        razorpayOrderId: orderId,
        razorpayPaymentId: response.paymentId,
        razorpaySignature: response.signature,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _razorpayEventReceived = true;
    _pendingRazorpayOrderId = null;
    Get.defaultDialog(
      title: "Payment Failed",
      middleText:
          response.message ?? 'Payment was not completed or was cancelled.',
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

  void _handleReportClick() async {
    final storedUser = await ApiService.getStoredUser();
    final userId = storedUser?["user_id"]?.toString() ?? "";
    if (userId.isEmpty) {
      Get.snackbar(
        "Error",
        "Session invalid. Please login again.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
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
            Text(
              "Checking registered vehicles...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final vehicles = await ApiService.getMyVehicles(userId);
      if (Get.isDialogOpen == true) Get.back();

      if (vehicles.isEmpty) {
        _showBeautifulDialog(
          title: "Vehicle Required",
          description:
              "You must add at least one vehicle to your account to report wrong parking.",
          icon: Icons.directions_car_rounded,
          iconColor: Colors.orange.shade600,
          confirmText: "Add Vehicle",
          onConfirm: () {
            Get.back();
            Get.to(() => const MyVehiclesScreen());
          },
        );
        return;
      }

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
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar(
        "Error",
        "Failed to verify vehicle registration. Please try again.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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
                  letterSpacing: -0.3,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ================= END RAZORPAY LOGIC =================

  @override
  void dispose() {
    _globalAlertTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadShownAlerts() async {
    final ids = await AlertState.actionedIds();
    if (mounted) {
      setState(() {
        _shownAlertIds.addAll(ids);
      });
    }
  }

  Future<void> _saveShownAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _shownAlertIds.map((e) => e.toString()).toList();
    await prefs.setStringList(AlertState.actionedAlertIdsKey, list);
  }

  void _startGlobalAlertPolling() {
    _globalAlertTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkGlobalAlerts();
    });
  }

  Future<void> _checkGlobalAlerts() async {
    try {
      _shownAlertIds.addAll(await AlertState.actionedIds());
      final notifications = await ApiService.getNotificationsForCurrentUser();
      for (var n in notifications) {
        final int id = AlertState.parseAlertId(n['id']);
        if (id == 0 ||
            _shownAlertIds.contains(id) ||
            _activeAlertIds.contains(id) ||
            AlertState.isActive(id)) {
          continue;
        }

        final type = n['type']?.toString().toUpperCase() ?? '';
        final status = n['status']?.toString().toUpperCase() ?? '';

        if (type == 'VEHICLE_REPORTED_AGAINST_YOU' && status == 'SUBMITTED') {
          unawaited(_openFullScreenAlert(n, isHelping: false));
        } else if (type == 'HELP_ALERT' && status == 'IN_PROGRESS') {
          unawaited(_openFullScreenAlert(n, isHelping: true));
        } else if (type == 'EMERGENCY_ALERT' && status == 'SUBMITTED') {
          unawaited(_openFullScreenAlert(n, isHelping: false));
        }
      }
    } catch (e) {
      // Ignore network errors in background poll
    }
  }

  Future<void> _openFullScreenAlert(
    dynamic notificationData, {
    required bool isHelping,
  }) async {
    if (!mounted) return;
    final int alertId = AlertState.parseAlertId(notificationData['id']);

    if (!await AlertState.begin(alertId)) return;
    if (alertId != 0) _activeAlertIds.add(alertId);

    bool acknowledged = false;
    try {
      acknowledged =
          await Get.to<bool>(
            () => FullScreenAlert(
              notificationData: Map<String, dynamic>.from(notificationData),
              isHelping: isHelping,
            ),
          ) ??
          false;
    } finally {
      if (alertId != 0) {
        _activeAlertIds.remove(alertId);
        if (acknowledged) {
          _shownAlertIds.add(alertId);
          await _saveShownAlerts();
        }
      }
      await AlertState.end(alertId, actioned: acknowledged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildPremiumHomeAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFloatingNewsTicker(),
            _buildCoinOfferBanner(),
            _buildVehicleAlertsCommandCenter(),
            const SizedBox(height: 26),
            _buildSectionTitle(
              "Primary Mission",
              "Fast actions for parking situations",
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildPrimaryMissionCard(
                    icon: Icons.camera_alt_rounded,
                    title: "Report Parking",
                    subtitle: "Submit evidence",
                    color: primaryBlue,
                    onTap: _handleReportClick,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryMissionCard(
                    icon: Icons.volunteer_activism_rounded,
                    title: "Help Vehicle",
                    subtitle: "Notify owner",
                    color: secondaryYellow,
                    foregroundColor: const Color(0xFF3A2A00),
                    onTap: () =>
                        Get.to(() => const IssueSelectionScreen(typev: "help")),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEmergencyStrip(),
            const SizedBox(height: 28),
            _buildSectionTitle("My Assets", "Wallet and garage at a glance"),
            const SizedBox(height: 14),
            _buildAssetsCarousel(),
            const SizedBox(height: 28),
            _buildHomeCommunityImpactCard(),
            const SizedBox(height: 28),
            _buildSectionTitle(
              "Secondary Tools",
              "All services in a compact swipeable row",
            ),
            const SizedBox(height: 14),
            _buildSecondaryToolsRow(),
            const SizedBox(height: 30),
            _buildCommunityZone(),
            const SizedBox(height: 30),
            _buildFooterReferralCard(),
            const SizedBox(height: 18),
            _buildSloganFooter(),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  ImageProvider? _homeProfileImageProvider() {
    final image = _userValue("profile_image", "").trim();
    if (image.isEmpty) return null;

    if (image.startsWith("data:image")) {
      try {
        return MemoryImage(base64Decode(image.split(",").last));
      } catch (_) {
        return null;
      }
    }

    final imageUrl = image.startsWith("/")
        ? "${ApiService.baseUrl}$image"
        : image;
    return NetworkImage(imageUrl);
  }

  PreferredSizeWidget _buildPremiumHomeAppBar() {
    final fullName = _userValue("full_name", "Parking Mudde User");
    final firstName = fullName.trim().split(RegExp(r'\s+')).first;
    final location = _userValue("location", "New Delhi, India");
    final profileImageProvider = _homeProfileImageProvider();
    final initial = firstName.isEmpty
        ? "P"
        : firstName.substring(0, 1).toUpperCase();

    return PreferredSize(
      preferredSize: const Size.fromHeight(86),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryBlue.withOpacity(0.1),
                backgroundImage: profileImageProvider,
                child: profileImageProvider == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Hi, $firstName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.blueGrey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: textBlack,
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Get.to(() => const Notificationpage()),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinOfferBanner() {
    final percent =
        int.tryParse(_coinOffer["discount_percent"]?.toString() ?? "0") ?? 0;
    final isActive = _coinOffer["is_active"] == true && percent > 0;
    if (!isActive) return const SizedBox.shrink();

    final tag = (_coinOffer["tag"]?.toString().trim().isNotEmpty ?? false)
        ? _coinOffer["tag"].toString().trim()
        : "Launch Offer";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Get.to(() => WalletScreen(totalCoins: walletCoins)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF172554), Color(0xFF2A5EE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3A2A00),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "$percent% off on coin packs",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Valid on Starter, Plus and Max top-ups",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textBlack,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.blueGrey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeCommunityImpactCard() {
    final stats = [
      _HomeImpactStat(
        label: "Users",
        value: _communityImpactStats["users"] ?? 0,
        icon: Icons.groups_rounded,
        color: Colors.teal.shade600,
      ),
      _HomeImpactStat(
        label: "Vehicles",
        value: _communityImpactStats["vehicles"] ?? 0,
        icon: Icons.directions_car_filled_rounded,
        color: primaryBlue,
      ),
      _HomeImpactStat(
        label: "Reported",
        value: _communityImpactStats["vehicles_reported"] ?? 0,
        icon: Icons.report_rounded,
        color: Colors.deepPurple.shade500,
      ),
      _HomeImpactStat(
        label: "Helped",
        value: _communityImpactStats["vehicles_helped"] ?? 0,
        icon: Icons.volunteer_activism_rounded,
        color: secondaryYellow,
      ),
      _HomeImpactStat(
        label: "Emergency",
        value: _communityImpactStats["emergencies_solved"] ?? 0,
        icon: Icons.health_and_safety_rounded,
        color: Colors.red.shade600,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: primaryBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Community Snapshot",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "ParkingMudde network activity at a glance",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final itemWidth = compact ? 94.0 : 104.0;
              return SizedBox(
                height: 94,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: stats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildHomeImpactTile(stats[index]),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeImpactTile(_HomeImpactStat stat) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stat.color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stat.icon, color: stat.color, size: 17),
              const Spacer(),
              if (_isLoadingCommunityImpact)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: stat.color,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            _isLoadingCommunityImpact ? "--" : _formatCompactCount(stat.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: stat.color == secondaryYellow
                  ? const Color(0xFF8A5A00)
                  : stat.color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textBlack,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCount(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  Widget _buildVehicleAlertsCommandCenter() {
    final hasAgainstYou = _alertsAgainstYou > 0 || _activeAlertIds.isNotEmpty;
    final hasRaised = _alertsRaisedByYou > 0;
    final accent = hasAgainstYou
        ? Colors.red.shade700
        : hasRaised
        ? Colors.orange.shade700
        : Colors.green.shade700;
    final icon = hasAgainstYou
        ? Icons.warning_rounded
        : hasRaised
        ? Icons.pending_actions_rounded
        : Icons.shield_rounded;
    final title = hasAgainstYou
        ? "Vehicle alert needs attention"
        : hasRaised
        ? "Your reports are being tracked"
        : "Shield active";
    final subtitle = hasAgainstYou
        ? "Review alerts against your vehicles and resolve them quickly."
        : hasRaised
        ? "Raised by you and against-you counts are tracked in one place."
        : "Your vehicles are parked safely.";

    return InkWell(
      onTap: () => Get.to(() => const AlertsScreen()),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _premiumCardDecoration(
          borderColor: accent.withOpacity(0.24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blueGrey.shade300,
                ),
              ],
            ),
            if (hasAgainstYou || hasRaised) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusMetric(
                      "Raised by You",
                      _alertsRaisedByYou,
                      Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusMetric(
                      "Against You",
                      _alertsAgainstYou,
                      Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Color foregroundColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: _premiumCardDecoration(
          backgroundColor: color,
          borderColor: color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: foregroundColor, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor.withOpacity(0.78),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyStrip() {
    return InkWell(
      onTap: () => Get.to(() => const EmergencyAlertScreen()),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: _premiumCardDecoration(
          backgroundColor: Colors.red.shade700,
          borderColor: Colors.red.shade700,
        ),
        child: Row(
          children: const [
            Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Emergency Alert",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsCarousel() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildWalletAssetCard(),
          const SizedBox(width: 12),
          _buildVehicleAssetCard(),
        ],
      ),
    );
  }

  Widget _buildWalletAssetCard() {
    return InkWell(
      onTap: () => Get.to(() => WalletScreen(totalCoins: walletCoins)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: _premiumCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    walletCoins.toString(),
                    style: const TextStyle(
                      color: textBlack,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "PM Coins",
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildVehicleAssetCard() {
    return InkWell(
      onTap: () => Get.to(() => const MyVehiclesScreen()),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: _premiumCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: Colors.green.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "My Vehicles",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Garage overview",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey,
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
    );
  }

  Widget _buildSecondaryToolsRow() {
    final tools = [
      _MiniTool(
        Icons.local_parking_rounded,
        "Find Parking",
        Colors.blue.shade700,
        () => Get.to(() => const NearbyParkingMapScreen()),
      ),
      _MiniTool(
        Icons.account_balance_wallet_rounded,
        "Wallet",
        Colors.green.shade700,
        () => Get.to(() => WalletScreen(totalCoins: walletCoins)),
      ),
      _MiniTool(
        Icons.gavel_rounded,
        "Challans",
        Colors.red.shade700,
        () => Get.to(() => const MyChallansScreen()),
      ),
      _MiniTool(
        Icons.directions_car_rounded,
        "My Vehicles",
        Colors.purple.shade600,
        () => Get.to(() => const MyVehiclesScreen()),
      ),
      _MiniTool(
        Icons.warning_rounded,
        "Parking Alerts",
        Colors.orange.shade700,
        () => Get.to(() => const AlertsScreen()),
      ),
      _MiniTool(
        Icons.add_circle_rounded,
        "Add Vehicle",
        Colors.teal.shade700,
        () async {
          final added = await Get.to(() => const AddVehicleScreen());
          if (added == true) Get.to(() => const MyVehiclesScreen());
        },
      ),
      _MiniTool(
        Icons.share_rounded,
        "Referral",
        Colors.indigo.shade600,
        () => Get.to(() => const ReferralScreen()),
      ),
      _MiniTool(
        Icons.car_rental_rounded,
        "Buy Vehicle",
        Colors.cyan.shade700,
        _showBuyVehicleComingSoon,
      ),
      _MiniTool(
        Icons.health_and_safety_rounded,
        "Vehicle Insurance",
        Colors.deepOrange.shade600,
        _showVehicleInsuranceComingSoon,
      ),
      _MiniTool(
        Icons.article_rounded,
        "Parking Prachar",
        Colors.blueGrey.shade700,
        () => Get.to(() => const ParkingPracharScreen()),
      ),
      _MiniTool(
        Icons.emoji_events_rounded,
        "Leaderboard",
        Colors.amber.shade700,
        () => Get.to(() => const LeaderboardScreen()),
      ),
      _MiniTool(
        Icons.question_answer_rounded,
        "FAQs",
        Colors.green.shade700,
        () => Get.to(() => const FaqPage()),
      ),
      _MiniTool(
        Icons.storefront_rounded,
        "Coupon Store",
        Colors.indigo.shade500,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CouponStoreScreen(coinsbackBalance: walletCoins),
            ),
          );
        },
      ),
      _MiniTool(
        Icons.badge_rounded,
        "Visitor Mgmt",
        Colors.brown.shade600,
        () => Get.to(() => const VisitorManagementScreen()),
      ),
      _MiniTool(
        Icons.local_hospital_rounded,
        "Emergency",
        Colors.red.shade700,
        () => Get.to(() => const EmergencyAlertScreen()),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tools
            .map(
              (tool) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _buildMiniTool(tool),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMiniTool(_MiniTool tool) {
    return InkWell(
      onTap: tool.onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200, width: 1.2),
                boxShadow: _softShadow(),
              ),
              child: Icon(tool.icon, color: tool.color, size: 23),
            ),
            const SizedBox(height: 8),
            Text(
              tool.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textBlack,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 26),
        _buildSectionTitle(
          "Community Zone",
          "Updates, rankings and local stories",
        ),
        const SizedBox(height: 14),
        _buildSuggestSocietyOutlineCard(),
        const SizedBox(height: 24),
        _buildHomeLeaderboardSection(),
        const SizedBox(height: 24),
        _buildParkingPrachaarBlogs(),
        const SizedBox(height: 24),
        _buildParkingPrachaarReels(),
        const SizedBox(height: 24),
        _buildFaqPreview(),
        const SizedBox(height: 24),
        _buildCommunityStoriesInline(),
      ],
    );
  }

  Widget _buildSuggestSocietyOutlineCard() {
    return InkWell(
      onTap: _showSuggestSocietyDialog,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _premiumCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Suggest Society",
                    style: TextStyle(
                      color: textBlack,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Help ParkingMudde expand to your community",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.blueGrey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityStoriesInline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Community Testimonials",
              style: TextStyle(
                color: textBlack,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => _showAddReviewDialog(context),
              child: const Text("Write"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_communityStories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _premiumCardDecoration(),
            child: Text(
              "No community stories yet. Be the first to share your Parking Mudde experience.",
              style: TextStyle(
                color: Colors.blueGrey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            child: Row(
              children: _communityStories.map((item) {
                final story = Map<String, dynamic>.from(item as Map);
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildTestimonialCard(
                    name:
                        story["reviewer_name"]?.toString() ??
                        "Parking Mudde User",
                    role: story["reviewer_role"]?.toString(),
                    review: story["story"]?.toString() ?? "",
                    rating:
                        int.tryParse(story["rating"]?.toString() ?? "5") ?? 5,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFooterReferralCard() {
    final referralCode = user?["referral_code"]?.toString() ?? "";
    return InkWell(
      onTap: () => Get.to(() => const ReferralScreen()),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _premiumCardDecoration(
          backgroundColor: primaryBlue,
          borderColor: primaryBlue,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Refer & Earn",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    referralCode.isEmpty
                        ? "Invite friends and earn PM Coins when they join."
                        : "Invite code: $referralCode",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildSloganFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        // Tune these two values to manually find the perfect slogan image size.
        const normalImageWidth = 150.0;
        const compactImageWidth = 128.0;
        const imageHeightRatio = 0.92;

        final imageWidth = compact
            ? compactImageWidth.clamp(0.0, constraints.maxWidth * 0.62)
            : normalImageWidth.clamp(0.0, constraints.maxWidth * 0.64);
        final imageHeight = imageWidth * imageHeightRatio;
        final imageRightInset = constraints.maxWidth >= 360
            ? 8.0
            : constraints.maxWidth >= 340
            ? 6.0
            : 0.0;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 156 : 180),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 24,
              compact ? 20 : 24,
              compact ? 16 : 20,
              compact ? 20 : 24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    "Stress less. Park more.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: compact ? 19.5 : 21,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 10 : 14),
                Padding(
                  padding: EdgeInsets.only(right: imageRightInset),
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.asset(
                      "assets/homepageslogan.png",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            Icons.self_improvement_rounded,
                            color: Colors.blueGrey.shade400,
                            size: compact ? 44 : 56,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _premiumCardDecoration({
    Color backgroundColor = Colors.white,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor ?? const Color(0xFFE2E8F0),
        width: 1.2,
      ),
      boxShadow: _softShadow(),
    );
  }

  List<BoxShadow> _softShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  void _showAddReviewDialog(BuildContext context) {
    final reviewController = TextEditingController();
    final nameController = TextEditingController(
      text: _userValue("full_name", _userValue("name", "")),
    );
    int selectedRating = 5;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Write a Review",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Share your experience with the Parking Mudde community.",
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Your name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => setDialogState(
                                  () => selectedRating = value,
                                ),
                          icon: Icon(
                            value <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: secondaryYellow,
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Your review...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final story = reviewController.text.trim();
                          if (name.isEmpty || story.isEmpty) {
                            Get.snackbar(
                              "Missing Info",
                              "Please enter your name and review.",
                              backgroundColor: Colors.orange.shade700,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final result = await ApiService.submitCommunityReview(
                            reviewerName: name,
                            reviewerRole: "Parking Mudde User",
                            rating: selectedRating,
                            story: story,
                          );
                          setDialogState(() => isSubmitting = false);

                          if (result["success"] == true) {
                            if (context.mounted) Navigator.pop(context);
                            Get.snackbar(
                              "Thank You!",
                              "Your review has been submitted for approval.",
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              result["message"]?.toString() ??
                                  "Failed to submit review.",
                              backgroundColor: Colors.red.shade600,
                              colorText: Colors.white,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTestimonialCard({
    required String name,
    String? role,
    required String review,
    required int rating,
  }) {
    final displayName = name.trim().isEmpty
        ? "Parking Mudde User"
        : name.trim();
    final initial = displayName.substring(0, 1).toUpperCase();
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryBlue.withOpacity(0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textBlack,
                      ),
                    ),
                    if (role != null && role.trim().isNotEmpty)
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        rating,
                        (index) => const Icon(
                          Icons.star_rounded,
                          color: secondaryYellow,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$review"',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
                letterSpacing: -0.2,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.amber.shade100
                                : index == 1
                                ? Colors.grey.shade200
                                : index == 2
                                ? Colors.brown.shade100
                                : Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
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
                        const SizedBox(width: 14),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryBlue.withValues(alpha: 0.1),
                          backgroundImage: u["profile_pic"] != null
                              ? NetworkImage(u["profile_pic"])
                              : null,
                          child: u["profile_pic"] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: primaryBlue,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            u["full_name"] ?? "User",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textBlack,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.diamond_rounded,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${u["score"] ?? 0}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
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
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              // Current User position
              Row(
                children: [
                  const Text(
                    "Your Rank:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _myProgress != null &&
                              _myProgress!['current_rank'] != null
                          ? "#${_myProgress!['current_rank']}"
                          : "-",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        fontSize: 14,
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
    return Container();
  }

  void _showSuggestSocietyDialog() {
    final societyNameController = TextEditingController();
    final addressPincodeController = TextEditingController();
    final contactDetailsController = TextEditingController();
    final personalNameController = TextEditingController();

    final userName = user?["full_name"]?.toString() ?? "";
    final userMobile = user?["mobile_number"]?.toString() ?? "";
    final userEmail = user?["email"]?.toString() ?? "";
    final userLocation = user?["location"]?.toString() ?? "";

    personalNameController.text = userName;
    contactDetailsController.text = userMobile.isNotEmpty
        ? userMobile
        : userEmail;
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Suggest a Society",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textBlack,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Help ParkingMudde expand to your society. We'll review your suggestion and reach out.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () async {
                      final name = societyNameController.text.trim();
                      final address = addressPincodeController.text.trim();
                      final contact = contactDetailsController.text.trim();
                      final pName = personalNameController.text.trim();

                      if (name.isEmpty ||
                          address.isEmpty ||
                          contact.isEmpty ||
                          pName.isEmpty) {
                        Get.snackbar(
                          "Missing Info",
                          "Please fill all fields.",
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      final userId = user?["user_id"];
                      if (userId == null) {
                        Get.snackbar(
                          "Error",
                          "Please log in first.",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
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
        prefixIcon: Icon(icon, color: primaryBlue, size: 22),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _MiniTool {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniTool(this.icon, this.label, this.color, this.onTap);
}

class _HomeImpactStat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _HomeImpactStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
