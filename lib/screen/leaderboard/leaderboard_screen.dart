import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import 'package:parkingmudde/screen/gamification/badges_screen.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool isLoading = true;
  List<dynamic> weeklyHeroes = [];
  List<dynamic> parkingWarriors = [];
  List<dynamic> cityChampions = [];
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => isLoading = true);
    final user = await ApiService.getStoredUser();
    final data = await ApiService.getLeaderboard();

    if (mounted) {
      setState(() {
        currentUser = user;
        weeklyHeroes = data["weekly_heroes"] ?? [];
        parkingWarriors = data["parking_warriors"] ?? [];
        cityChampions = data["city_champions"] ?? [];
        isLoading = false;
      });
    }
  }

  String _getGamificationTitle(int score) {
    if (score >= 500) return "ParkingMudde Legend 👑";
    if (score >= 300) return "Road Samaritan ❤️";
    if (score >= 150) return "Street Guardian 🚦";
    if (score >= 50) return "Society Hero 🏢";
    return "Parking Protector 🛡️";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0XFF184B8C),
              size: 22,
            ),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "Leaderboard",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0XFF184B8C),
            unselectedLabelColor: Colors.blueGrey.shade400,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            indicatorColor: const Color(0XFF184B8C),
            indicatorWeight: 3.5,
            dividerColor: Colors.grey.shade200,
            tabs: const [
              Tab(text: "Weekly Heroes"),
              Tab(text: "Parking Warriors"),
              Tab(text: "City Champions"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(weeklyHeroes, isCity: false),
                  _buildList(parkingWarriors, isCity: false),
                  _buildCityList(cityChampions),
                ],
              ),
        bottomNavigationBar: _buildStickyUserBanner(),
      ),
    );
  }

  Widget _buildList(List<dynamic> users, {required bool isCity}) {
    if (users.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          Center(
            child: Text(
              "No top users yet!",
              style: TextStyle(color: Colors.blueGrey.shade400),
            ),
          ),
          const SizedBox(height: 24),
          const ScreenSlogan(
            "Celebrating our top contributors.",
            color: Color(0XFF184B8C),
            icon: Icons.emoji_events_rounded,
            imagePath: 'assets/leaderboard.png',
            normalImageWidth: 146,
            compactImageWidth: 124,
            textMaxLines: 2,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: users.length + 1,
      itemBuilder: (context, index) {
        if (index == users.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 24),
            child: ScreenSlogan(
              "Celebrating our top contributors.",
              color: Color(0XFF184B8C),
              icon: Icons.emoji_events_rounded,
              imagePath: 'assets/leaderboard.png',
              normalImageWidth: 146,
              compactImageWidth: 124,
              textMaxLines: 2,
            ),
          );
        }
        final user = users[index];
        final isTop3 = index < 3;
        final rank = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop3
                  ? const Color(0XFFfdd708).withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                "#$rank",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isTop3 ? const Color(0XFFfdd708) : Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFF0F4F8),
                child: Icon(Icons.person, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user["username"] ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      user["score"].toString() + " Coins",
                      style: const TextStyle(
                        color: Color(0XFF184B8C),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTop3)
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0XFFfdd708),
                  size: 28,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityList(List<dynamic> users) {
    return _buildList(users, isCity: true);
  }

  Widget _buildStickyUserBanner() {
    int myScore = currentUser?["score"] ?? 0;
    String currentTitle = _getGamificationTitle(myScore);
    int myRank = currentUser?["rank"] ?? 0;

    return InkWell(
      onTap: () => Get.to(() => const BadgesScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0XFF184B8C),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  myRank > 0 ? "#$myRank" : "-",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You ($currentTitle)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Score: $myScore",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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
}
