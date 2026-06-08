import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:parkingmudde/services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  static const Color primaryBlue = Color(0XFF184B8C);
  static const Color accentYellow = Color(0xFFFFB703);

  String referralCode = "";
  int totalEarnedCoins = 0;
  int totalReferrals = 0;
  int completedReferrals = 0;
  int pendingReferrals = 0;
  int rewardPerJoin = 10;
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
          int.tryParse(data["reward_per_join"]?.toString() ?? "10") ?? 10;
      referralHistory = data["referrals"] is List ? data["referrals"] : [];
      isLoading = false;
    });
  }

  void shareReferral() {
    if (referralCode.isEmpty) {
      Get.snackbar("Code Missing", "Refresh your referral code and try again.");
      return;
    }
    Share.share(
      "Join ParkingMudde and earn PM Coins.\n\n"
      "Use my referral code: $referralCode\n"
      "Reward: $rewardPerJoin PM Coins after signup.\n"
      "Download: https://parkingmudde.app",
    );
  }

  Future<void> copyReferralCode() async {
    if (referralCode.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: referralCode));
    Get.snackbar(
      "Code Copied",
      "Share it with friends to earn PM Coins.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey.shade900,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryBlue,
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
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadReferralData,
        color: primaryBlue,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryBlue))
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        children: [
                          _hero(),
                          const SizedBox(height: 18),
                          _codeCard(),
                          const SizedBox(height: 16),
                          _statsGrid(),
                          const SizedBox(height: 18),
                          _rulesCard(),
                          const SizedBox(height: 24),
                          _historyHeader(),
                        ],
                      ),
                    ),
                  ),
                  if (referralHistory.isEmpty)
                    SliverToBoxAdapter(child: _emptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      sliver: SliverList.builder(
                        itemCount: referralHistory.length,
                        itemBuilder: (context, index) =>
                            _historyTile(referralHistory[index]),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: accentYellow,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Invite friends",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Earn $rewardPerJoin PM Coins when a friend signs up using your code.",
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.35,
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
        color: primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Text(
                  "YOUR REFERRAL CODE",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: copyReferralCode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.45)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            referralCode.isEmpty ? "----" : referralCode,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.6,
                            ),
                          ),
                        ),
                        const Icon(Icons.copy_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: shareReferral,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_rounded, color: primaryBlue, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Share Invite Code",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(child: _statTile("Earned", "$totalEarnedCoins", "PM Coins")),
        const SizedBox(width: 10),
        Expanded(child: _statTile("Joined", "$completedReferrals", "friends")),
        const SizedBox(width: 10),
        Expanded(child: _statTile("Pending", "$pendingReferrals", "invites")),
      ],
    );
  }

  Widget _statTile(String label, String value, String subLabel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subLabel,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How rewards work",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _ruleRow("1", "Share your referral code with a friend."),
          _ruleRow("2", "They enter your code during signup."),
          _ruleRow("3", "You earn PM Coins after their account is created."),
        ],
      ),
    );
  }

  Widget _ruleRow(String index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: primaryBlue.withOpacity(0.1),
            child: Text(
              index,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Referral Tracker",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        Text(
          "$totalReferrals total",
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey.shade500,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _historyTile(dynamic item) {
    final status = item["status"]?.toString().toLowerCase() ?? "pending";
    final joined = status == "joined";
    final reward = int.tryParse(item["reward"]?.toString() ?? "0") ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: joined ? Colors.green.shade50 : Colors.orange.shade50,
            child: Icon(
              joined ? Icons.how_to_reg_rounded : Icons.pending_actions_rounded,
              color: joined ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"]?.toString() ??
                      item["mobile_number"]?.toString() ??
                      "Invited user",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${item["mobile_number"] ?? "Invitee"} - ${_formatDate(item["date"])}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(joined),
              if (joined) ...[
                const SizedBox(height: 6),
                Text(
                  "+$reward PM",
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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
    final color = joined ? Colors.green.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        joined ? "COMPLETED" : "PENDING",
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "No referrals yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your invite activity will appear here after friends join with your code.",
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

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? "");
    if (date == null) return "Recently";
    return "${date.day}/${date.month}/${date.year}";
  }
}
