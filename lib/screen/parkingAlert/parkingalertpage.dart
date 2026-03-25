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
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: Color(0XFFfdd708),
              size: 40,
            ),
            onPressed: () {
              Get.back();
            },
          ),
          automaticallyImplyLeading: true,
          toolbarHeight: 60,
          elevation: 0.2,
          centerTitle: true,
          backgroundColor: Colors.white,
          title: Text(
            "My Alerts",
            style: TextStyle(color: Color(0XFFfdd708),fontSize: 18,fontWeight: FontWeight.bold),
          ),
          // title: const Text("My Alerts"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Raised By You"),
              Tab(text: "Against You"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AlertsList(alerts: alertsRaisedByYou),
            AlertsList(alerts: alertsAgainstYou),
          ],
        ),
      ),
    );
  }
}

class AlertsList extends StatelessWidget {
  final List<AlertModel> alerts;

  const AlertsList({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Center(child: Text("No alerts found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _statusChip(alert.isResolved),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  "Raised on: ${alert.date}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const Divider(height: 20),

                /// 🪙 Reward / Penalty
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoTile(
                      title: "Reward",
                      value: alert.reward > 0 ? "+${alert.reward} 🪙" : "--",
                      color: Colors.green,
                    ),
                    _infoTile(
                      title: "Penalty",
                      value: alert.penalty > 0 ? "-${alert.penalty} 🪙" : "--",
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _statusChip(bool resolved) {
    return Chip(
      label: Text(resolved ? "Resolved" : "Pending"),
      backgroundColor: resolved
          ? Colors.green.shade100
          : Colors.orange.shade100,
      labelStyle: TextStyle(color: resolved ? Colors.green : Colors.orange),
    );
  }
}
