import 'package:flutter/material.dart';
import 'package:parkingmudde_authority/services/api_service.dart';

class EarnCoinsPage extends StatefulWidget {
  const EarnCoinsPage({super.key});

  @override
  State<EarnCoinsPage> createState() => _EarnCoinsPageState();
}

class _EarnCoinsPageState extends State<EarnCoinsPage> {
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF888888);

  Map<String, int> coinConfigs = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final configs = await ApiService.fetchCoinConfig();
    setState(() {
      coinConfigs = configs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    final ways = [
      _EarnWay(
        icon: Icons.directions_car_filled_rounded,
        title: "Add a vehicle",
        description: "Register your vehicle in My Garage and earn PM Coins.",
        coins: "+${coinConfigs['add_vehicle_reward'] ?? 10}",
        color: primaryBlue,
      ),
      _EarnWay(
        icon: Icons.volunteer_activism_rounded,
        title: "Help a vehicle owner",
        description: "Submit a help activity when another driver needs support.",
        coins: "+${coinConfigs['help_proof_reward'] ?? 5}",
        color: const Color(0xFF20C475),
      ),
      _EarnWay(
        icon: Icons.report_problem_rounded,
        title: "Report wrong parking",
        description: "Send a valid wrong-parking report with proper evidence.",
        coins: "+${coinConfigs['report_parking_reward'] ?? 50}",
        color: const Color(0xFFFF8A00),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Earn PM Coins",
          style: TextStyle(
            color: textBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const Text(
            "Ways to earn",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Complete tasks and engage with the community to build up your PM Coins balance.",
            style: TextStyle(
              fontSize: 14,
              color: subTextGrey,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ...ways.map(_earnWayTile),
        ],
      ),
    );
  }

  Widget _earnWayTile(_EarnWay way) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: way.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  way.description,
                  style: const TextStyle(
                    color: subTextGrey,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            way.coins,
            style: TextStyle(
              color: way.color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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

  const _EarnWay({
    required this.icon,
    required this.title,
    required this.description,
    required this.coins,
    required this.color,
  });
}
