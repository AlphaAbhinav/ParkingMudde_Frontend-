import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';

class Notificationpage extends StatefulWidget {
  const Notificationpage({super.key});

  @override
  State<Notificationpage> createState() => _NotificationpageState();
}

class _NotificationpageState extends State<Notificationpage> {
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color accentYellow = Color(0xFFFFB703);

  final List<String> filters = [
    "All",
    "Reports",
    "Vehicles",
    "Helped",
    "Bookings",
    "Coupons",
    "Visitors",
    "Packages",
    "Updates",
    "Tickets",
  ];
  String selectedFilter = "All";
  bool isLoading = true;
  List<dynamic> notifications = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);

    final user = await ApiService.getStoredUser();
    final storedUserId = user?["user_id"]?.toString();

    if (storedUserId == null || storedUserId.isEmpty) {
      if (mounted) {
        setState(() {
          userId = null;
          notifications = [];
          isLoading = false;
        });
      }
      return;
    }

    final result = await ApiService.getNotifications(storedUserId);
    if (mounted) {
      setState(() {
        userId = storedUserId;
        notifications = result;
        isLoading = false;
      });
    }
  }

  List<dynamic> get visibleNotifications {
    return notifications.where((item) {
      final type = item["type"]?.toString() ?? "";
      if (selectedFilter == "Reports") return type == "REPORTED_VEHICLE";
      if (selectedFilter == "Vehicles") {
        return type == "VEHICLE_ADDED" ||
            type == "VEHICLE_UPDATED" ||
            type == "VEHICLE_DELETED";
      }
      if (selectedFilter == "Helped") return type == "HELPED_VEHICLE";
      if (selectedFilter == "Bookings") return type == "PARKING_BOOKING";
      if (selectedFilter == "Coupons") return type == "COUPON_PURCHASED";
      if (selectedFilter == "Visitors") return type == "VISITOR_PASS";
      if (selectedFilter == "Packages") return type == "WALLET_PACKAGE";
      if (selectedFilter == "Updates") return type == "APP_UPDATE";
      if (selectedFilter == "Tickets") return type == "SUPPORT_TICKET";
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = visibleNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryBlue,
            size: 20,
          ),
          onPressed: () {
            if (Get.key.currentState?.canPop() == true) {
              Get.back();
            }
          },
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          _notificationSummary(),
          _filterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: primaryBlue,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _emptyState()
                      : _activityList(items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: _summaryTile(
              icon: Icons.notifications_active_rounded,
              title: "App Updates",
              value: notifications.length.toString(),
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryTile(
              icon: Icons.confirmation_number_rounded,
              title: "Query Tickets",
              value: _ticketCount().toString(),
              color: Colors.deepOrange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final selected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: selected,
                onSelected: (_) => setState(() => selectedFilter = filter),
                showCheckmark: false,
                selectedColor: accentYellow,
                backgroundColor: const Color(0xFFF0F2F5),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.blueGrey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: selected ? accentYellow : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 86),
      children: [
        const Icon(
          Icons.local_activity_outlined,
          color: primaryBlue,
          size: 46,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            selectedFilter == "Tickets"
                ? "No query tickets yet"
                : "No notifications yet",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedFilter == "Tickets"
              ? "Tickets raised from Help & Support will appear here once support tracking is connected."
              : "Vehicles, reports, visitors, bookings, packages, coupons, app updates, and support ticket activity will appear here.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.blueGrey.shade500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _activityList(List<dynamic> items) {
    final grouped = <String, List<dynamic>>{};
    for (final item in items) {
      grouped.putIfAbsent(_sectionTitle(item), () => []).add(item);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 92),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: Text(
              entry.key,
              style: TextStyle(
                color: Colors.blueGrey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...entry.value.map(_activityCard),
        ];
      }).toList(),
    );
  }

  Widget _activityCard(dynamic item) {
    final type = item["type"]?.toString() ?? "";
    final status = item["status"]?.toString() ?? "SUBMITTED";
    final coins = int.tryParse(item["coins_delta"]?.toString() ?? "0") ?? 0;
    final amount = item["amount"];
    final vehicleNumber = item["vehicle_number"]?.toString();
    final location = item["location"]?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _typeColor(type).withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(type), color: _typeColor(type), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _title(type, status),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    _statusPill(status),
                  ],
                ),
                const SizedBox(height: 6),
                if (type == "PARKING_BOOKING" ||
                    type == "VEHICLE_ADDED" ||
                    type == "VEHICLE_UPDATED" ||
                    type == "VEHICLE_DELETED" ||
                    type == "COUPON_PURCHASED" ||
                    type == "WALLET_PACKAGE" ||
                    type == "VISITOR_PASS" ||
                    type == "APP_UPDATE" ||
                    type == "SUPPORT_TICKET")
                  Text(
                    item["description"]?.toString() ?? "Activity update",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    [
                      if (vehicleNumber != null && vehicleNumber.isNotEmpty)
                        vehicleNumber,
                      if (location != null && location.isNotEmpty) location,
                    ].join("  •  "),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.blueGrey.shade400,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatTime(item),
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (coins != 0) _coinText(coins),
                    if (coins == 0 && amount != null) _amountText(amount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _coinText(int coins) {
    final positive = coins > 0;
    return Text(
      "${positive ? '+' : ''}$coins PM Coins",
      style: TextStyle(
        color: positive ? const Color(0xFF10B981) : Colors.red.shade600,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _amountText(dynamic amount) {
    return Text(
      "Rs$amount",
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  String _title(String type, String status) {
    if (type == "VEHICLE_ADDED") return "Vehicle Added";
    if (type == "VEHICLE_UPDATED") return "Vehicle Updated";
    if (type == "VEHICLE_DELETED") return "Vehicle Removed";
    if (type == "COUPON_PURCHASED") return "Coupon Purchased";
    if (type == "WALLET_PACKAGE") return "Wallet Package";
    if (type == "VISITOR_PASS") return "Visitor Pass";
    if (type == "APP_UPDATE") return "App Update";
    if (type == "SUPPORT_TICKET") return "Query Ticket";
    if (type == "HELPED_VEHICLE") return "Helped Vehicle Owner";
    if (type == "PARKING_BOOKING") return "Parking Booking";
    if (status == "CONFIRMED") return "Wrong parking Confirmed";
    return "Wrong parking Reported";
  }

  String _sectionTitle(dynamic item) {
    final createdAt = DateTime.tryParse(item["created_at"]?.toString() ?? "");
    if (createdAt == null) return "THIS WEEK";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return "TODAY";
    if (diff == 1) return "YESTERDAY";
    return "THIS WEEK";
  }

  String _formatTime(dynamic item) {
    final createdAt = DateTime.tryParse(item["created_at"]?.toString() ?? "");
    if (createdAt == null) return item["time"]?.toString() ?? "";

    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) return "now";
    if (difference.inHours < 1) return "${difference.inMinutes} mins ago";
    if (difference.inDays < 1) return "${difference.inHours} hours ago";

    final hour = createdAt.hour.toString().padLeft(2, "0");
    final minute = createdAt.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }

  String _statusLabel(String status) {
    switch (status) {
      case "IN_PROGRESS":
        return "In Progress";
      case "COMPLETED":
      case "CONFIRMED":
      case "APPROVED":
        return "Completed";
      case "REJECTED":
        return "Rejected";
      case "PENDING":
      case "REQUESTED":
        return "Pending";
      case "SENT":
        return "Sent";
      default:
        return "Submitted";
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "IN_PROGRESS":
      case "SUBMITTED":
      case "SENT":
      case "PENDING":
      case "REQUESTED":
        return Colors.orange.shade700;
      case "REJECTED":
        return Colors.red.shade600;
      default:
        return Colors.green.shade700;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case "HELPED_VEHICLE":
        return const Color(0xFF10B981);
      case "PARKING_BOOKING":
        return const Color(0xFFA855F7);
      case "COUPON_PURCHASED":
        return const Color(0xFFF97316);
      case "WALLET_PACKAGE":
        return const Color(0xFF2563EB);
      case "VISITOR_PASS":
        return const Color(0xFF0F766E);
      case "APP_UPDATE":
        return const Color(0xFF7C3AED);
      case "SUPPORT_TICKET":
        return const Color(0xFFEA580C);
      case "VEHICLE_ADDED":
      case "VEHICLE_UPDATED":
        return const Color(0xFF2A5EE8);
      case "VEHICLE_DELETED":
        return Colors.red.shade600;
      default:
        return primaryBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case "HELPED_VEHICLE":
        return Icons.local_police_rounded;
      case "PARKING_BOOKING":
        return Icons.local_parking_rounded;
      case "COUPON_PURCHASED":
        return Icons.card_giftcard_rounded;
      case "WALLET_PACKAGE":
        return Icons.account_balance_wallet_rounded;
      case "VISITOR_PASS":
        return Icons.badge_rounded;
      case "APP_UPDATE":
        return Icons.campaign_rounded;
      case "SUPPORT_TICKET":
        return Icons.confirmation_number_rounded;
      case "VEHICLE_ADDED":
        return Icons.directions_car_filled_rounded;
      case "VEHICLE_UPDATED":
        return Icons.edit_note_rounded;
      case "VEHICLE_DELETED":
        return Icons.no_transfer_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  int _ticketCount() {
    return notifications
        .where((item) => item["type"]?.toString() == "SUPPORT_TICKET")
        .length;
  }
}
