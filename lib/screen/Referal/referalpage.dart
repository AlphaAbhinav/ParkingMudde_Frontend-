import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  static const Color primaryBlue = Color(0XFF184B8C);
  static const Color accentYellow = Color(0xFFFFB703);
  static const Color bgColor = Color(0xFFF6F8FA);

  String referralCode = "";
  int totalEarnedCoins = 0;
  int totalReferrals = 0;
  int completedReferrals = 0;
  int pendingReferrals = 0;
  int rewardPerJoin = 0;
  int milestoneProgress = 0;
  int milestoneTarget = 0;
  int milestoneReward = 0;
  List<dynamic> referralHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReferralData();
  }

  Future<void> loadReferralData() async {
    setState(() => isLoading = true);
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Get.snackbar("Error", "User not logged in");
      return;
    }

    final data = await ApiService.getReferrals(userId);
    if (!mounted) return;
    setState(() {
      referralCode = data["referral_code"]?.toString() ?? "";
      totalEarnedCoins =
          int.tryParse(data["total_earned"]?.toString() ?? "0") ?? 0;
      totalReferrals =
          int.tryParse(data["total_referrals"]?.toString() ?? "0") ?? 0;
      completedReferrals =
          int.tryParse(data["completed_referrals"]?.toString() ?? "0") ?? 0;
      pendingReferrals =
          int.tryParse(data["pending_referrals"]?.toString() ?? "0") ?? 0;
      rewardPerJoin =
          int.tryParse(data["reward_per_join"]?.toString() ?? "0") ?? 0;
      milestoneProgress =
          int.tryParse(data["milestone_progress"]?.toString() ?? "0") ?? 0;
      milestoneTarget =
          int.tryParse(data["milestone_target"]?.toString() ?? "0") ?? 0;
      milestoneReward =
          int.tryParse(data["milestone_reward"]?.toString() ?? "0") ?? 0;
      referralHistory = data["referrals"] is List ? data["referrals"] : [];
      isLoading = false;
    });
  }

  void shareReferral() {
    if (referralCode.isEmpty) {
      Get.snackbar("Code Missing", "Refresh your referral code and try again.");
      return;
    }
    final rewardText = rewardPerJoin > 0
        ? "Reward: $rewardPerJoin PM Coins after signup."
        : "Rewards are decided by ParkingMudde.";
    Share.share(
      "Join ParkingMudde and earn PM Coins.\n\n"
      "Use my invite code:\n"
      "$referralCode\n\n"
      "$rewardText",
    );
  }

  void shareLinkComingSoon() {
    Get.snackbar(
      "Coming Soon",
      "Deep linking is under development. For now, please share the code directly!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey.shade900,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<void> copyReferralCode() async {
    if (referralCode.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: referralCode));
    Get.snackbar(
      "Code Copied!",
      "Share it with friends to earn PM Coins.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey.shade900,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: accentYellow),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 4,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.15),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryBlue,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Refer & Earn",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadReferralData,
        color: primaryBlue,
        child: isLoading
            ? _buildSkeletonLoader()
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        children: [
                          _hero(),
                          const SizedBox(height: 24),
                          _codeCard(),
                          const SizedBox(height: 16),
                          _milestoneTracker(),
                          const SizedBox(height: 16),
                          _statsGrid(),
                          const SizedBox(height: 16),
                          _rulesCard(),
                          const SizedBox(height: 32),
                          _historyHeader(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (referralHistory.isEmpty)
                    SliverToBoxAdapter(child: _emptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList.builder(
                        itemCount: referralHistory.length,
                        itemBuilder: (context, index) =>
                            _historyTile(referralHistory[index]),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: ScreenSlogan(
                        "Good things are better when shared.",
                        color: primaryBlue,
                        icon: Icons.card_giftcard_rounded,
                        imagePath: 'assets/referslogan.png',
                        normalImageWidth: 146,
                        compactImageWidth: 124,
                        textMaxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- PREMIUM UI WIDGETS ---

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentYellow.withOpacity(0.3),
                  accentYellow.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: accentYellow,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Invite friends",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Earn $rewardPerJoin PM Coins for every friend that signs up using your code.",
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlue.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Icon(
              Icons.group_add_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "YOUR REFERRAL CODE",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: copyReferralCode,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              referralCode.isEmpty ? "----" : referralCode,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: shareReferral,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.ios_share_rounded,
                                color: primaryBlue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Share Code",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: shareLinkComingSoon,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Share Link",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "SOON",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW GAMIFIED MILESTONE TIER SYSTEM ---
  Widget _milestoneTracker() {
    // Defines exactly 4 Tiers mapping up to 50 Referrals
    final milestones = [5, 10, 25, 50];
    const int maxProgress = 50;

    // Calculates where to place the yellow filling bar up to a cap of 50
    // Creates equal visual gaps between segments so 5 & 10 are nicely separated
    double getVisualProgress(int count) {
      if (count <= 0) return 0.0;
      if (count <= 5) return (count / 5.0) * 0.25; // 1st quarter of the bar
      if (count <= 10) return 0.25 + ((count - 5) / 5.0) * 0.25; // 2nd quarter
      if (count <= 25)
        return 0.50 + ((count - 10) / 15.0) * 0.25; // 3rd quarter
      if (count < 50) return 0.75 + ((count - 25) / 25.0) * 0.25; // 4th quarter
      return 1.0;
    }

    double lineFillPercentage = getVisualProgress(completedReferrals);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Chest Tiers Unlocked",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$completedReferrals Joined",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC08600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 76,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 6,
                      width: constraints.maxWidth * lineFillPercentage,
                      decoration: BoxDecoration(
                        color: accentYellow,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: accentYellow.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ...milestones.map((targetVal) {
                  return _buildTierDot(
                    targetVal,
                    completedReferrals,
                    maxProgress,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (milestoneReward > 0 && milestoneProgress < milestoneTarget)
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: accentYellow, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${milestoneTarget - milestoneProgress} more signups left to grab a bonus of $milestoneReward PM Coins!",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You are currently maxing out the reward milestones! Exceptional work!",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Visual Update here handles exactly how Locked/Achieved icons show up
  Widget _buildTierDot(int targetVal, int currentReferrals, int maxTarget) {
    bool isAchieved = currentReferrals >= targetVal;

    // Map icons directly to the center points of the new evenly spaced segments
    double alignmentPoint = targetVal == 5
        ? 0.25
        : targetVal == 10
        ? 0.50
        : targetVal == 25
        ? 0.75
        : 1.0;
    // Upgraded Milestone Configurations
    Color baseTierColor;
    IconData icon;
    String label;

    switch (targetVal) {
      case 5:
        baseTierColor = const Color(0xFFCD7F32); // Bronze
        icon = Icons.star_rounded;
        label = "5";
        break;
      case 10:
        baseTierColor = const Color(0xFFB0BEC5); // Silver
        icon = Icons.redeem_rounded; // Gift Box
        label = "10";
        break;
      case 25:
        baseTierColor = const Color(0xFFFFD700); // Premium Vivid Gold
        icon = Icons.emoji_events_rounded; // Trophy Award
        label = "25";
        break;
      case 50:
      default:
        baseTierColor = const Color(
          0xFF00E5FF,
        ); // Bright Neon Cyan (Diamond Level)
        icon = Icons.diamond_rounded;
        label = "50";
        break;
    }

    // Colors fall back to completely dull greys for unachieved milestones.
    Color iconColor = isAchieved ? baseTierColor : Colors.grey.shade400;
    Color borderColor = isAchieved ? baseTierColor : Colors.grey.shade300;

    return Align(
      alignment: Alignment(-1.0 + (alignmentPoint * 2), 0.05),
      child: FractionalTranslation(
        translation: Offset.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // Padded a little thicker so Achieved nodes actively expand ("pop-out") slightly
              padding: EdgeInsets.all(isAchieved ? 10 : 6),
              decoration: BoxDecoration(
                color: isAchieved ? Colors.white : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  // Makes Border pop intensely alongside achieving the tier
                  width: isAchieved ? 3 : 1.5,
                ),
                // Glowing drop shadows exclusively rendered on achievable nodes
                boxShadow: isAchieved
                    ? [
                        BoxShadow(
                          color: baseTierColor.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              // Increase the graphical volume directly via internal flutter elements scale
              child: Icon(icon, color: iconColor, size: isAchieved ? 22 : 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAchieved ? FontWeight.w800 : FontWeight.w600,
                color: isAchieved ? Colors.black87 : Colors.blueGrey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            "Earned",
            "$totalEarnedCoins",
            "Coins",
            Icons.stars_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            "Joined",
            "$completedReferrals",
            "Friends",
            Icons.people_alt_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            "Pending",
            "$pendingReferrals",
            "Invites",
            Icons.mark_email_read_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, String subLabel, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -25,
            bottom: -35,
            child: Transform.scale(
              scale: 1.4,
              child: Icon(
                icon,
                size: 70,
                color: Colors.blueGrey.shade100.withOpacity(0.4),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.blueGrey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How it works",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _ruleRow(
            "1",
            "Share your custom link or referral code with a friend.",
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: CustomPaint(
              painter: VerticalDottedLinePainter(),
              size: const Size(1, 20),
            ),
          ),
          _ruleRow(
            "2",
            "Your friend creates their profile and inputs your code.",
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: CustomPaint(
              painter: VerticalDottedLinePainter(),
              size: const Size(1, 20),
            ),
          ),
          _ruleRow(
            "3",
            "Watch your PM coins jump upon successful account creation.",
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(String stepNumber, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accentYellow.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Color(0xFFC08600),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          "Referral Activity",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        Text(
          "$totalReferrals records",
          style: TextStyle(
            fontSize: 13,
            color: Colors.blueGrey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Render bug has been Fixed Right Here: Look at mobile_number concatenation string.
  Widget _historyTile(dynamic item) {
    final status = item["status"]?.toString().toLowerCase() ?? "pending";
    final joined = status == "joined";
    final reward = int.tryParse(item["reward"]?.toString() ?? "0") ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: joined ? Colors.green.shade50 : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              joined
                  ? Icons.how_to_reg_rounded
                  : Icons.person_add_disabled_rounded,
              color: joined ? Colors.green.shade600 : Colors.orange.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"]?.toString() ??
                      item["mobile_number"]?.toString() ??
                      "Invited Friend",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // FIX APPLIED BELOW : Render correctly separated list information vs string symbols
                  "${item["mobile_number"] ?? "No details"}  •  ${_formatDate(item["date"])}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(joined),
              if (joined && reward > 0) ...[
                const SizedBox(height: 8),
                Text(
                  "+$reward PM",
                  style: const TextStyle(
                    color: Color(0xFF198754),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool joined) {
    final color = joined ? const Color(0xFF198754) : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        joined ? "COMPLETED" : "PENDING",
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.mark_chat_read_rounded,
                  size: 100,
                  color: Colors.blueGrey.shade50,
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Icon(
                    Icons.people_rounded,
                    size: 50,
                    color: Colors.blueGrey.shade100,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 10,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 30,
                    color: accentYellow.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Waiting for your friends!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "As soon as a friend joins using your referral code, their status and your rewards will show up here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonBox(height: 100),
              const SizedBox(height: 24),
              _skeletonBox(height: 220),
              const SizedBox(height: 16),
              _skeletonBox(height: 120),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _skeletonBox(height: 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonBox(height: 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonBox(height: 100)),
                ],
              ),
              const SizedBox(height: 16),
              _skeletonBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? "");
    if (date == null) return "Just Now";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}

class VerticalDottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double dashHeight = 4, dashSpace = 4, startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
