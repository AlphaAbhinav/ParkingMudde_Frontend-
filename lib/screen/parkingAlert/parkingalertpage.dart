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
  const AlertsScreen({
    super.key,
    this.isFromBottomNav = false,
    this.onBackPressed,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const Color brandBlue = Color(0XFF184B8C);
  static const Color textBlack = Color(0xFF1E293B);

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
    final createdAt = DateTime.tryParse(
      item["created_at"]?.toString() ?? "",
    )?.toLocal();
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
        backgroundColor: const Color(0xFFF8FAFC), // Fresh sleek background tone
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor:
              Colors.transparent, // Prevents Android 12 scroll tinting
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textBlack,
                size: 20,
              ),
              onPressed: () {
                if (widget.isFromBottomNav && widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else {
                  Get.back();
                }
              },
            ),
          ),
          title: const Text(
            "Security Alerts",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textBlack,
            ),
          ),
          bottom: TabBar(
            labelColor: brandBlue,
            unselectedLabelColor: Colors.blueGrey.shade400,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            indicatorColor: brandBlue,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3.0,
            dividerColor: const Color(0xFFF1F5F9), // Subdued border outline
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
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0XFF184B8C),
        ),
      );
    }

    if (alerts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        color: const Color(0XFF184B8C),
        backgroundColor: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [_buildEmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      color: const Color(0XFF184B8C),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: alerts.length + 1,
        itemBuilder: (context, index) {
          if (index < alerts.length) return _buildAlertCard(alerts[index]);

          // Original layout intact: bottom banner placement
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: DynamicAdCarousel(pageName: 'Parking Alerts'),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    // Richer, slightly darker variants of colors for maximum legibility
    final primaryCardColor = isViolationList
        ? const Color(0xFFDC2626)
        : const Color(0xFF184B8C);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ), // Slightly more generous radius
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                // Clean circular indicator container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryCardColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isViolationList
                        ? Icons
                              .gavel_rounded // Replaced basic warning with professional gavel
                        : Icons.flag_circle_rounded,
                    color: primaryCardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _miniLicensePlateView(alert.vehicleNumber),
                          ),
                          const SizedBox(width: 10),
                          _statusChip(alert.isResolved),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        alert.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(
                            0xFF334155,
                          ), // Refined blue-grey tone
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded, // Smooth icon edges
                            size: 14,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            alert.date, // Avoids "Logged: " clutter
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
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

          // Seamlessly integrated bottom tray panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.04)),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _infoTile(
                    title: "Community Reward",
                    value: alert.reward > 0 ? "+${alert.reward}" : "--",
                    hasActionValue: alert.reward > 0,
                    tintColor: const Color(0xFF10B981), // Emerald
                    alignLeft: true,
                  ),
                ),
                Container(
                  height: 32,
                  width: 1.5,
                  color: Colors.blueGrey.shade100, // Smooth middle break line
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: _infoTile(
                    title: "Penalty Imposed",
                    value: alert.penalty > 0 ? "-${alert.penalty}" : "--",
                    hasActionValue: alert.penalty > 0,
                    tintColor: const Color(0xFFEF4444), // Smooth alert red
                    alignLeft: false,
                  ),
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
      constraints: const BoxConstraints(maxWidth: 170),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // Standardized license radius
        border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant India plate marker block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              "IND",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                regNumber.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Color(0xFF1E293B),
                  letterSpacing: 1.5,
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
    required bool alignLeft,
  }) {
    return Column(
      crossAxisAlignment: alignLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF94A3B8), // Professional silver-slate
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasActionValue ? "$value Coins" : value,
          style: TextStyle(
            color: hasActionValue ? tintColor : const Color(0xFFCBD5E1),
            fontSize: hasActionValue ? 13 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(bool resolved) {
    // Upgraded standard badges to the fluid soft badges we utilized on notifications page
    final pillColor = resolved
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: pillColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pillColor.withOpacity(0.3)),
      ),
      child: Text(
        resolved ? "CLOSED" : "IN REVIEW",
        style: TextStyle(
          color: pillColor,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 100,
      ), // More central mass spacing
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isViolationList ? Icons.gavel_rounded : Icons.task_alt_rounded,
              size: 46,
              color: isViolationList
                  ? const Color(0xFF184B8C).withOpacity(
                      0.7,
                    ) // Tie back to primary brand color instead of red
                  : const Color(0xFF10B981).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Nothing here right now",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isViolationList
                  ? "Your record is completely clean! Keep up the excellent work parking responsibly."
                  : "Records of times you have stepped in or triggered alerts to secure zones will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade500,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
