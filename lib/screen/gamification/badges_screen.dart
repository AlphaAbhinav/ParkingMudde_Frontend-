import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  bool isLoading = true;
  Map<String, dynamic>? progressData;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() => isLoading = true);
    final user = await ApiService.getStoredUser();
    if (user != null && user["user_id"] != null) {
      final data = await ApiService.getMyGamificationProgress(user["user_id"].toString());
      if (mounted) {
        setState(() {
          progressData = data;
          isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0XFF184B8C), size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "My Badges & Titles",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : progressData == null
              ? const Center(child: Text("Could not load gamification data."))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final double percentage = (progressData!["progress_percentage"] ?? 0.0) / 100.0;
    final int pointsNeeded = progressData!["points_needed"] ?? 0;
    final String nextTitle = progressData!["next_title"] ?? "Max Tier";
    final int currentScore = progressData!["total_score"] ?? 0;
    final String currentTitle = progressData!["current_title"] ?? "";
    final List<dynamic> badges = progressData!["badges"] ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0XFF184B8C), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0XFF184B8C).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "CURRENT TITLE",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  currentTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$currentScore Points",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                if (nextTitle != "Max Tier") ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Progress to $nextTitle",
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${(percentage * 100).toInt()}%",
                        style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Earn $pointsNeeded more points to unlock!",
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  const Text(
                    "You have reached the maximum tier! 🏆",
                    style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text(
            "All Titles & Badges",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          
          ...badges.map((badge) {
            final bool isUnlocked = currentScore >= badge["score"];
            return _buildBadgeCard(
              title: badge["title"],
              scoreNeeded: badge["score"],
              isUnlocked: isUnlocked,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({required String title, required int scoreNeeded, required bool isUnlocked}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? Colors.amber.shade200 : Colors.grey.shade300,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? Icons.stars_rounded : Icons.lock_rounded,
              color: isUnlocked ? Colors.amber.shade600 : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isUnlocked ? const Color(0xFF1E293B) : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlocked ? "Unlocked!" : "Requires $scoreNeeded points",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
        ],
      ),
    );
  }
}
