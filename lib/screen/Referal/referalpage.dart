import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String referralCode = "";
  int totalEarnedCoins = 0;
  List referralHistory = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReferralData();
  }

  Future<void> loadReferralData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar("Error", "User not logged in");
      return;
    }

    final data = await ApiService.getReferrals(userId);

    setState(() {
      referralCode = data["referral_code"] ?? "";
      totalEarnedCoins = data["total_earned"] ?? 0;
      referralHistory = data["referrals"] ?? [];
      isLoading = false;
    });
  }

  void shareReferral() {
    Share.share(
      "Join ParkingMudde & earn coins 🪙\n\n"
      "Use my referral code: $referralCode\n"
      "Download now 👉 https://parkingmudde.app",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Premium off-white super-app base
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
          "Refer & Earn",
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
                    "Fetching Your Invite Data...",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// Playful yet professional hero icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.celebration_rounded,
                            size: 54,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Invite Friends, Get Rewarded!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Help build a responsible parking community. Both you and your friend earn 🪙 Coins instantly.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueGrey.shade500,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// Gorgeous FinTech Promo Card Box
                        _buildPromoVoucherCard(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                /// Tracker Headline + Summary Pillar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Referral Tracker",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.blueGrey.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "All history tracked dynamically.",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 12,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$totalEarnedCoins 🪙",
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Feed Results
                if (referralHistory.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = referralHistory[index];
                        return _buildModernHistoryTile(item);
                      }, childCount: referralHistory.length),
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
    );
  }

  /// Visually exciting promotional coupon/voucher
  Widget _buildPromoVoucherCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0XFF184B8C), // Preserving brand accent completely!
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF184B8C).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const Text(
                  "YOUR EXCLUSIVE CODE",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                /// Interactive dashed box highlighting copy intent!
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    Get.snackbar(
                      "Code Securely Copied!",
                      "Share it securely across platforms.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.blueGrey.shade900,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(20),
                      duration: const Duration(seconds: 2),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.greenAccent,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Pure solid replacement over complex dashed
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            referralCode.isEmpty ? "----" : referralCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tap Code string to Quick Copy",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          /// The large action button chunk at the base
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              4,
            ), // Gives border inset feeling around action
            child: InkWell(
              onTap: shareReferral, // Kept logical route intact
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ), // Conforms inside properly!
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      color: Color(0XFF184B8C),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Share Unique Code",
                      style: TextStyle(
                        color: Color(0XFF184B8C),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Identical layout format mirroring premium super apps' "history" states.
  Widget _buildModernHistoryTile(dynamic item) {
    final bool isJoined =
        item['status'] == "joined"; // Maintained strict boolean state

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Row(
        children: [
          /// Status Visualized Bubble
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isJoined ? Colors.green.shade50 : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isJoined
                  ? Icons.how_to_reg_rounded
                  : Icons.pending_actions_rounded,
              color: isJoined ? Colors.green.shade600 : Colors.orange.shade700,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          /// Context Details (User string and dates preserved!)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['mobile_number'] ?? "Unknown Invitee",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['date'] ?? "--/--/--",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ],
            ),
          ),

          /// Status text aligned on trailing securely
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isJoined
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isJoined ? "COMPLETED" : "PENDING",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isJoined
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isJoined)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "+${item['reward']} 🪙",
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sleek empty condition container purely missing inside previous default lists
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "Nothing logged yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Invites generating referral activity will be chronologically traced in this list.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
