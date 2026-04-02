import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AlertModel {
  final String vehicleNumber;
  final String date;
  final int reward;
  final int penalty;
  final bool isResolved;

  AlertModel({
    required this.vehicleNumber,
    required this.date,
    required this.reward,
    required this.penalty,
    required this.isResolved,
  });
}

List<AlertModel> alertsRaisedByYou = [
  AlertModel(
    vehicleNumber: "DL 01 AB 1234",
    date: "12 Jan 2026 • 10:45 AM",
    reward: 10,
    penalty: 0,
    isResolved: true,
  ),
];

List<AlertModel> alertsAgainstYou = [
  AlertModel(
    vehicleNumber: "UP 32 XY 4567",
    date: "11 Jan 2026 • 6:20 PM",
    reward: 0,
    penalty: 10,
    isResolved: false,
  ),
];

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA), // Premium off-white
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false, // Super apps love aligned titles
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
            "Security Alerts",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          bottom: TabBar(
            labelColor: const Color(0XFF184B8C),
            unselectedLabelColor: Colors.blueGrey.shade400,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            indicatorColor: const Color(0XFF184B8C),
            indicatorWeight: 3.5,
            dividerColor: Colors.grey.shade200,
            tabs: const [
              Tab(text: "Raised By You"),
              Tab(text: "Filed Against You"),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            AlertsList(alerts: alertsRaisedByYou),
            AlertsList(alerts: alertsAgainstYou, isViolationList: true),
          ],
        ),
      ),
    );
  }
}

class AlertsList extends StatelessWidget {
  final List<AlertModel> alerts;
  final bool isViolationList;

  const AlertsList({
    super.key,
    required this.alerts,
    this.isViolationList = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildModernAlertCard(alert);
      },
    );
  }

  /// Visually sophisticated Card Ticket!
  Widget _buildModernAlertCard(AlertModel alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ====== TICKET HEADER SECTION ====== //
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stylized Issue Icon Element
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isViolationList
                        ? Colors.red.shade50
                        : Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isViolationList
                        ? Icons.warning_rounded
                        : Icons.report_gmailerrorred_rounded,
                    color: isViolationList
                        ? Colors.red.shade700
                        : Colors.indigo.shade700,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                // Core details wrapper
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniLicensePlateView(alert.vehicleNumber),
                          _statusChip(alert.isResolved),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 12,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Logged: ${alert.date}",
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
                ),
              ],
            ),
          ),

          // ====== DASHED TICKETING SPLIT LINE ====== //
          Row(
            children: List.generate(
              40,
              (index) => Expanded(
                child: Container(
                  color: index.isEven
                      ? Colors.grey.shade200
                      : Colors.transparent,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // ====== TICKET PENALTY/REWARD RESULT INFO ====== //
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoTile(
                  title: "Community Reward",
                  value: alert.reward > 0 ? "+${alert.reward}" : "--",
                  hasActionValue: alert.reward > 0,
                  tintColor: Colors.green,
                ),
                Container(
                  height: 30,
                  width: 1.5,
                  color: Colors.grey.shade300,
                ), // Clean separating line
                _infoTile(
                  title: "Rule Penalty Deduct",
                  value: alert.penalty > 0 ? "-${alert.penalty}" : "--",
                  hasActionValue: alert.penalty > 0,
                  tintColor: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small exact mapping of authentic Indian Reg Plates natively displaying
  Widget _miniLicensePlateView(String regNumber) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 2,
              left: 3,
              right: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "IND",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              regNumber.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Visually sophisticated dynamic tracker pillars showing transaction outcomes safely.
  Widget _infoTile({
    required String title,
    required String value,
    required Color tintColor,
    required bool hasActionValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        hasActionValue
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tintColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: tintColor.withOpacity(0.9),
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text("🪙", style: TextStyle(fontSize: 10)),
                ],
              )
            : Text(
                value,
                style: TextStyle(
                  color: Colors.blueGrey.shade300,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
      ],
    );
  }

  /// Graceful state identifier indicator
  Widget _statusChip(bool resolved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resolved ? Colors.green.shade50 : Colors.amber.shade50,
        border: Border.all(
          color: resolved ? Colors.green.shade100 : Colors.amber.shade200,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            resolved ? Icons.verified_rounded : Icons.history_rounded,
            color: resolved ? Colors.green.shade600 : Colors.amber.shade800,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            resolved ? "SOLVED" : "PENDING",
            style: TextStyle(
              color: resolved ? Colors.green.shade800 : Colors.amber.shade900,
              fontWeight: FontWeight.w900,
              fontSize: 8.5,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Visually impressive absence container avoiding stark whitespaces
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isViolationList
                  ? Icons.shield_outlined
                  : Icons.event_note_rounded,
              size: 50,
              color: Colors.blueGrey.shade200,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "You are all caught up!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isViolationList
                ? "You currently maintain an outstanding driving profile with zero tickets submitted against your vehicles."
                : "No parking or reporting claims exist initiated under your device yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
