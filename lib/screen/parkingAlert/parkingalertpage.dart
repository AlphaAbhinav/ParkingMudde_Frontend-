import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/widgets/ad_banner.dart';
import 'package:parkingmudde/widgets/dynamic_ad_carousel.dart';
import '../../services/api_service.dart';

class AlertModel {
  final String vehicleNumber;
  final String date;
  final int reward;
  final int penalty;
  final bool isResolved;
  final String description;

  AlertModel({
    required this.vehicleNumber,
    required this.date,
    required this.reward,
    required this.penalty,
    required this.isResolved,
    required this.description,
  });
}

class AlertsScreen extends StatefulWidget {
  final bool isFromBottomNav;
  final VoidCallback? onBackPressed;
  const AlertsScreen({super.key, this.isFromBottomNav = false, this.onBackPressed});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool isLoading = true;
  List<AlertModel> raisedByYou = [];
  List<AlertModel> againstYou = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => isLoading = true);
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        raisedByYou = [];
        againstYou = [];
        isLoading = false;
      });
      return;
    }

    final result = await ApiService.getParkingAlerts(userId);
    if (!mounted) return;
    setState(() {
      raisedByYou = _mapAlerts(result["raised_by_you"]);
      againstYou = _mapAlerts(result["against_you"]);
      isLoading = false;
    });
  }

  List<AlertModel> _mapAlerts(dynamic rawItems) {
    if (rawItems is! List) return [];
    return rawItems.map((item) {
      final coins = int.tryParse(item["coins_delta"]?.toString() ?? "0") ?? 0;
      final status = item["status"]?.toString().toUpperCase() ?? "SUBMITTED";
      return AlertModel(
        vehicleNumber: item["vehicle_number"]?.toString() ?? "N/A",
        date: _formatDate(item),
        reward: coins > 0 ? coins : 0,
        penalty: coins < 0 ? coins.abs() : 0,
        isResolved: true, // Always resolved per user request
        description: item["description"]?.toString() ?? "Alert activity",
      );
    }).toList();
  }

  String _formatDate(dynamic item) {
    final createdAt = DateTime.tryParse(item["created_at"]?.toString() ?? "")?.toLocal();
    if (createdAt == null) {
      final date = item["date"]?.toString() ?? "";
      final time = item["time"]?.toString() ?? "";
      return [date, time].where((part) => part.isNotEmpty).join(" ");
    }
    final hour = createdAt.hour > 12
        ? createdAt.hour - 12
        : createdAt.hour == 0
            ? 12
            : createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, "0");
    final suffix = createdAt.hour >= 12 ? "PM" : "AM";
    return "${createdAt.day}/${createdAt.month}/${createdAt.year} - $hour:$minute $suffix";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
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
            onPressed: () {
              if (widget.isFromBottomNav && widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else {
                Get.back();
              }
            },
          ),
          title: const Text(
            "Security Alerts",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          bottom: TabBar(
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
              Tab(text: "Raised By You"),
              Tab(text: "Filed Against You"),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            AlertsList(
              alerts: raisedByYou,
              isLoading: isLoading,
              onRefresh: _loadAlerts,
            ),
            AlertsList(
              alerts: againstYou,
              isViolationList: true,
              isLoading: isLoading,
              onRefresh: _loadAlerts,
            ),
          ],
        ),
      ),
    );
  }
}

class AlertsList extends StatelessWidget {
  final List<AlertModel> alerts;
  final bool isViolationList;
  final bool isLoading;
  final Future<void> Function()? onRefresh;

  const AlertsList({
    super.key,
    required this.alerts,
    this.isViolationList = false,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (alerts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [_buildEmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: alerts.length + 1,
        itemBuilder: (context, index) {
          if (index < alerts.length) return _buildAlertCard(alerts[index]);
          // AdB4 — bottom banner
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: DynamicAdCarousel(pageName: 'Parking Alerts'),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    final color = isViolationList ? Colors.red.shade700 : Colors.indigo.shade700;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isViolationList
                        ? Icons.warning_rounded
                        : Icons.report_gmailerrorred_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _miniLicensePlateView(alert.vehicleNumber)),
                          const SizedBox(width: 8),
                          _statusChip(alert.isResolved),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        alert.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
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
                Container(height: 30, width: 1.5, color: Colors.grey.shade300),
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

  Widget _miniLicensePlateView(String regNumber) {
    return Container(
      height: 26,
      constraints: const BoxConstraints(maxWidth: 170),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.blue.shade800,
            alignment: Alignment.center,
            child: const Text(
              "IND",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                regNumber.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasActionValue ? "$value PM Coins" : value,
          style: TextStyle(
            color: hasActionValue ? tintColor : Colors.blueGrey.shade300,
            fontSize: hasActionValue ? 12 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

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
      child: Text(
        resolved ? "SOLVED" : "PENDING",
        style: TextStyle(
          color: resolved ? Colors.green.shade800 : Colors.amber.shade900,
          fontWeight: FontWeight.w900,
          fontSize: 8.5,
        ),
      ),
    );
  }

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
                ? "No alerts are currently filed against your registered vehicles."
                : "Your reporting, helping, and emergency alerts will appear here.",
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
