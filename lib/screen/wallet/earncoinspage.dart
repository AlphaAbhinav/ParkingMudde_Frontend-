import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:parkingmudde/screen/Referal/referalpage.dart';
import 'package:parkingmudde/screen/emergency/emergencyalertpage.dart';
import 'package:parkingmudde/screen/parkingnearby/parkingnearbypage.dart';
import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/services/api_service.dart';

class EarnCoinsPage extends StatefulWidget {
  const EarnCoinsPage({super.key});

  @override
  State<EarnCoinsPage> createState() => _EarnCoinsPageState();
}

class _EarnCoinsPageState extends State<EarnCoinsPage> {
  static const Color primaryBlue = Color(0xFF184B8C);
  static const Color accentYellow = Color(0xFFFFB703);
  static const Color textBlack = Color(0xFF1E293B);
  static const Color subTextGrey = Color(0xFF64748B);
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color borderGrey = Color(0xFFE2E8F0);

  Map<String, num> coinConfigs = {};
  Map<String, dynamic> referralSummary = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => isLoading = true);

    final configsFuture = ApiService.fetchCoinConfig();
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    final referralsFuture = userId == null || userId.isEmpty
        ? Future<Map<String, dynamic>>.value({})
        : ApiService.getReferrals(userId);

    final results = await Future.wait([configsFuture, referralsFuture]);
    if (!mounted) return;

    setState(() {
      coinConfigs = Map<String, num>.from(results[0] as Map);
      referralSummary = Map<String, dynamic>.from(results[1] as Map);
      isLoading = false;
    });
  }

  num? _coinValue(String key) => coinConfigs[key];
  int _intFrom(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  // Clean string specifically designed for our new UI pill layout
  String _coinText(num? value) {
    if (value == null || value <= 0) return 'TBA'; // To be announced/loaded
    final display = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '+$display';
  }

  String _referralRewardText() {
    final referralReward = _intFrom(referralSummary['reward_per_join']);
    if (referralReward > 0) return '+$referralReward';
    return _coinText(_coinValue('referral_reward'));
  }

  String _referralDescription() {
    final milestoneTarget = _intFrom(referralSummary['milestone_target']);
    final milestoneReward = _intFrom(referralSummary['milestone_reward']);
    if (milestoneTarget > 0 && milestoneReward > 0) {
      return 'Invite friends and unlock a bonus of $milestoneReward at $milestoneTarget successful referrals.';
    }
    return 'Invite friends with your referral code and earn instantly when they join.';
  }

  void _unlinkedActionAction() {
    Get.snackbar(
      "Coming Soon",
      "This shortcut is under development.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey.shade900,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<void> _openAddVehicle() async {
    final added = await Get.to(() => const AddVehicleScreen(fromMyVehicles: true));
    if (added == true) {
      Get.to(() => const MyVehiclesScreen());
    }
  }

  void _openParkingSpotListing() {
    Get.to(() => const NearbyParkingMapScreen());
  }

  void _openReportViolations() {
    Get.to(() => const IssueSelectionScreen(typev: 'report'));
  }

  void _openHelpDrivers() {
    Get.to(() => const IssueSelectionScreen(typev: 'help'));
  }

  void _openEmergencyAlert() {
    Get.to(() => const EmergencyAlertScreen());
  }

  // Categories created dynamically
  List<_EarnWay> _buildGrowthWays() {
    return [
      _EarnWay(
        icon: Icons.campaign_rounded,
        title: 'Refer a friend',
        description: _referralDescription(),
        coins: _referralRewardText(),
        color: const Color(0xFF0F766E), // Teal
        actionLabel: 'Invite Now',
        onTap: () => Get.to(() => const ReferralScreen()),
      ),
      _EarnWay(
        icon: Icons.directions_car_filled_rounded,
        title: 'Add your vehicle',
        description: 'Register your personal vehicle into My Garage profile.',
        coins: _coinText(_coinValue('add_vehicle_reward')),
        color: primaryBlue,
        actionLabel: 'Register',
        onTap: _openAddVehicle,
      ),
      _EarnWay(
        icon: Icons.local_parking_rounded,
        title: 'List a parking spot',
        description: 'Contribute a safe parking location for other users to discover on the map.',
        coins: _coinText(_coinValue('add_parking_spot_reward')),
        color: const Color(0xFFA855F7), // Purple
        actionLabel: 'Create List',
        onTap: _openParkingSpotListing,
      ),
    ];
  }

  List<_EarnWay> _buildShieldWays() {
    return [
      _EarnWay(
        icon: Icons.report_problem_rounded,
        title: 'Report violations',
        description: 'Submit valid wrong-parking photo evidence.',
        coins: _coinText(_coinValue('reward_report_generic')),
        color: const Color(0xFFEA580C), // Dark Orange
        actionLabel: 'Report',
        onTap: _openReportViolations,
      ),
      _EarnWay(
        icon: Icons.volunteer_activism_rounded,
        title: 'Help other drivers',
        description: 'Alert and provide helpful warnings to drivers that need support.',
        coins: _coinText(_coinValue('reward_help_generic')),
        color: const Color(0xFF16A34A), // Deep Green
        actionLabel: 'Help',
        onTap: _openHelpDrivers,
      ),
      _EarnWay(
        icon: Icons.add_moderator_rounded,
        title: 'Report Emergencies',
        description: 'Provide an authentic emergency tip for authorities.',
        coins: _coinText(_coinValue('reward_emergency_generic')),
        color: const Color(0xFFDC2626), // Solid Red
        actionLabel: 'Alert',
        onTap: _openEmergencyAlert,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _appBar(),
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: _loadConfig,
        child: isLoading
            ? _buildSkeletonLoader()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 32),

                  _buildSectionTitle(
                    'Network Growth',
                    'Build your profile and invite peers',
                    Icons.trending_up_rounded,
                    primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  ..._buildGrowthWays().map(_earnWayTile),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Community Shield',
                    'Take helpful and protective actions',
                    Icons.verified_user_rounded,
                    const Color(0xFF0F766E), // Muted dark teal for variety
                  ),
                  const SizedBox(height: 16),
                  ..._buildShieldWays().map(_earnWayTile),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Earn PM Coins',
        style: TextStyle(
          color: textBlack,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final int balance = _intFrom(referralSummary['total_earned']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, Color(0xFF2A5EE8)], // Deep depth colors
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Graphic Background Circles overlay
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              height: 120, width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: Icon(Icons.blur_on_rounded, size: 140, color: Colors.white.withOpacity(0.04)),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total PM Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        balance.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12, offset: const Offset(0, 4)
                      )
                    ]
                  ),
                  child: Icon(Icons.savings_rounded, color: accentYellow.withOpacity(0.95), size: 38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subTitle, IconData icon, Color baseColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: baseColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textBlack,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subTitle,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _earnWayTile(_EarnWay way) {
    final bool hasLink = way.actionLabel != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasLink ? (way.onTap ?? _unlinkedActionAction) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: way.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: way.color.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(way.icon, color: way.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            way.title,
                            style: const TextStyle(
                              color: textBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w800, // Reduced from w900
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            way.description,
                            style: const TextStyle(
                              color: subTextGrey,
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500, // Thinned for easier reading
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: borderGrey, height: 1),
                ),

                // Formatted distinct pill space vs generic words
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), // Very pale amber highlight
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFDE68A)), // darker border
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            way.coins,
                            style: const TextStyle(
                              color: Color(0xFFB45309), // deeply readable bronze
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    if (hasLink)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            way.actionLabel!,
                            style: TextStyle(
                              color: way.color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: way.color,
                            size: 16,
                          ),
                        ],
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Shimmer for elegant entry while API configs hit.
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: Colors.blueGrey.shade100.withOpacity(0.5),
        highlightColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(height: 130), // Banner
              const SizedBox(height: 32),

              _shimmerBox(height: 24, width: 200), // Section title
              const SizedBox(height: 8),
              _shimmerBox(height: 12, width: 140),
              const SizedBox(height: 24),

              _shimmerBox(height: 160), // Item 1
              const SizedBox(height: 16),
              _shimmerBox(height: 160), // Item 2
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              _shimmerBox(height: 24, width: 180),
              const SizedBox(height: 24),

              _shimmerBox(height: 160), // Item 3
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16)
      ),
    );
  }
}

class _EarnWay {
  final IconData icon;
  final String title;
  final String description;
  final String coins;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _EarnWay({
    required this.icon,
    required this.title,
    required this.description,
    required this.coins,
    required this.color,
    this.actionLabel,
    this.onTap,
  });
}
