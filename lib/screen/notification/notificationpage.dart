import 'dart:async';
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
  static const Color textBlack = Color(0xFF1E293B);

  final List<String> filters = [
    "All",
    "Reports",
    "Vehicles",
    "Helped",
    "Bookings",
    "Coupons",
    "Visitors",
    "Packages",
    "OTP",
    "Updates",
    "Tickets",
  ];

  String selectedFilter = "All";
  bool isLoading = true;
  List<dynamic> notifications = [];
  String? userId;
  final Set<String> _onTheWayDone = {};
  Timer? _onTheWayExpiryTicker;

  // Controls the 'flashing red' touch effect for the app bar delete icon
  bool _isTrashTapped = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _onTheWayExpiryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _onTheWayExpiryTicker?.cancel();
    super.dispose();
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

    await ApiService.markNotificationsRead(storedUserId);
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
    final filtered = notifications.where((item) {
      final type = item["type"]?.toString() ?? "";
      if (selectedFilter == "Reports") {
        return type == "REPORTED_VEHICLE" ||
            type == "VEHICLE_REPORTED_AGAINST_YOU";
      }
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
      if (selectedFilter == "OTP") return type == "CONTACT_OTP";
      if (selectedFilter == "Updates") return type == "APP_UPDATE";
      if (selectedFilter == "Tickets") return type == "SUPPORT_TICKET";
      return true;
    }).toList();

    return _compactReportNotifications(filtered);
  }

  List<dynamic> _compactReportNotifications(List<dynamic> items) {
    final compacted = <dynamic>[];
    final reportGroups = <String, List<dynamic>>{};

    for (final item in items) {
      if (!_isReportNotification(item) || item["report_id"] == null) {
        compacted.add(item);
        continue;
      }

      final key = "${item["type"]}:${item["report_id"]}";
      reportGroups.putIfAbsent(key, () => []).add(item);
    }

    for (final group in reportGroups.values) {
      group.sort((a, b) => _createdAtMillis(a).compareTo(_createdAtMillis(b)));
      final initial = _initialReportNotification(group);
      final finalStatus = _finalReportNotification(group);

      if (finalStatus != null) compacted.add(finalStatus);
      if (initial != null && initial["id"]?.toString() != finalStatus?["id"]?.toString()) {
        compacted.add(initial);
      }
      if (initial == null && finalStatus == null && group.isNotEmpty) {
        compacted.add(group.last);
      }
    }

    compacted.sort((a, b) => _createdAtMillis(b).compareTo(_createdAtMillis(a)));
    return compacted;
  }

  bool _isReportNotification(dynamic item) {
    final type = item["type"]?.toString() ?? "";
    return type == "REPORTED_VEHICLE" || type == "VEHICLE_REPORTED_AGAINST_YOU";
  }

  dynamic _initialReportNotification(List<dynamic> group) {
    for (final item in group) {
      final status = item["status"]?.toString() ?? "";
      final coins = int.tryParse(item["coins_delta"]?.toString() ?? "0") ?? 0;
      if (status == "SUBMITTED" || item["vehicle_number"]?.toString() == "PENDING" || coins < 0) {
        return item;
      }
    }
    return group.isEmpty ? null : group.first;
  }

  dynamic _finalReportNotification(List<dynamic> group) {
    for (final item in group.reversed) {
      if (_isFinalReportStatus(item["status"]?.toString() ?? "")) {
        return item;
      }
    }
    return null;
  }

  bool _isFinalReportStatus(String status) {
    return status == "COMPLETED" ||
        status == "CONFIRMED" ||
        status == "APPROVED" ||
        status == "REJECTED";
  }

  int _createdAtMillis(dynamic item) {
    return _parseCreatedAt(item)?.millisecondsSinceEpoch ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = visibleNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textBlack,
              size: 20,
            ),
            onPressed: () {
              if (Get.key.currentState?.canPop() == true) {
                Get.back();
              }
            },
          ),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textBlack,
          ),
        ),
        actions: [
          GestureDetector(
            onTapDown: (_) => setState(() => _isTrashTapped = true),
            onTapCancel: () => setState(() => _isTrashTapped = false),
            onTapUp: (_) {
              setState(() => _isTrashTapped = false);
              _showCleanupMenu(); // Show stunning bottom sheet menu instead of dropdown
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isTrashTapped
                    ? Colors.red.withOpacity(0.08)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isTrashTapped
                    ? Icons.delete_rounded
                    : Icons.delete_outline_rounded,
                color: _isTrashTapped
                    ? Colors.red.shade600
                    : Colors.blueGrey.shade500,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _notificationSummary(),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                _filterBar(),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              backgroundColor: Colors.white,
              color: primaryBlue,
              strokeWidth: 2.5,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: primaryBlue,
                      ),
                    )
                  : items.isEmpty
                  ? _emptyState()
                  : _activityList(items),
            ),
          ),
        ],
      ),
    );
  }

  // ---- NEW: Professional Modern Modal Menu for Cleanup ----
  void _showCleanupMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Manage History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 12),
            _menuItem(
              title: "Clear today's activity",
              subtitle: "Remove notifications from the last 24 hours.",
              icon: Icons.event_busy_rounded,
              colorTheme: primaryBlue,
              onTap: () {
                Get.back(); // close modal first
                _deleteNotificationsByRange("today", "today's");
              },
            ),
            _menuItem(
              title: "Clear this month's records",
              subtitle: "Clean up all older records logged this month.",
              icon: Icons.calendar_today_rounded,
              colorTheme: primaryBlue,
              onTap: () {
                Get.back();
                _deleteNotificationsByRange("month", "this month's");
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),
            _menuItem(
              title: "Permanently Delete Everything",
              subtitle: "Completely wipe out your entire history log.",
              icon: Icons.delete_forever_rounded,
              colorTheme: Colors.red.shade600,
              isDestructive: true,
              onTap: () {
                Get.back();
                _deleteNotificationsByRange("all", "all");
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent, // Fixes clipping round corners
    );
  }

  Widget _menuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color colorTheme,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: colorTheme.withOpacity(0.05),
      highlightColor: colorTheme.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorTheme.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorTheme, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isDestructive
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: isDestructive ? colorTheme : textBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // -------------------------------------------------------------

  Widget _notificationSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _summaryTile(
              icon: Icons.campaign_rounded,
              title: "App Updates",
              value: notifications.length.toString(),
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryTile(
              icon: Icons.confirmation_number_rounded,
              title: "Query Tickets",
              value: _ticketCount().toString(),
              color: const Color(0xFFF97316),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textBlack,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final selected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: FilterChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedFilter = filter),
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                  selectedColor: textBlack,
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.blueGrey.shade600,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              selectedFilter == "Tickets"
                  ? Icons.all_inbox_rounded
                  : Icons.notifications_none_rounded,
              color: primaryBlue.withOpacity(0.7),
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          selectedFilter == "Tickets" ? "No queries found" : "All caught up",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textBlack,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            selectedFilter == "Tickets"
                ? "Your query tickets will be securely stored here once raised via Help & Support."
                : "Check back later! Parking logs, rewards, coupons, and safety updates will populate here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade500,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _typeColor(type).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title(item),
                            style: const TextStyle(
                              color: textBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Here we use the custom reactive delete button for items
                        AnimatedResponsiveDeleteButton(
                          onDelete: () => _deleteSingleNotification(item),
                        ),
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
                        type == "CONTACT_OTP" ||
                        type == "APP_UPDATE" ||
                        type == "SUPPORT_TICKET")
                      Text(
                        item["description"]?.toString() ??
                            "System update received",
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      )
                    else
                      Text(
                        [
                          if (vehicleNumber != null && vehicleNumber.isNotEmpty)
                            vehicleNumber,
                          if (location != null && location.isNotEmpty) location,
                        ].join("  •  "),
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_shouldShowOnTheWayButton(item))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildOnTheWayButton(item),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              _statusPill(status),
              const Spacer(),
              if (coins != 0) _coinText(coins),
              if (coins == 0 && amount != null) _amountText(amount),
              const SizedBox(width: 10),
              const Text("•", style: TextStyle(color: Color(0xFFCBD5E1))),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: Colors.blueGrey.shade400,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(item),
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    String title,
    String message,
    String confirmText,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.blueGrey.shade700,
            height: 1.5,
            fontSize: 14.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              "Keep it",
              style: TextStyle(color: textBlack, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return confirmed == true;
  }

  Future<void> _deleteSingleNotification(dynamic item) async {
    final currentUserId = userId;
    final notificationId = item["id"]?.toString();
    if (currentUserId == null ||
        notificationId == null ||
        notificationId.isEmpty) {
      _showActionMessage("We couldn't process this request.", isError: true);
      return;
    }

    final confirmed = await _confirmDelete(
      "Delete this alert?",
      "Are you sure you want to permanently remove this specific alert from your records? This cannot be undone.",
      "Yes, Delete",
    );

    if (!confirmed) return;

    final result = await ApiService.deleteNotification(
      userId: currentUserId,
      notificationId: notificationId,
    );

    if (!mounted) return;
    if (result["success"] == true) {
      setState(() {
        notifications.removeWhere(
          (notification) => notification["id"]?.toString() == notificationId,
        );
      });
      _showActionMessage("Notification removed successfully.");
    } else {
      _showActionMessage(
        result["message"] ?? "An issue prevented us from removing this alert.",
        isError: true,
      );
    }
  }

  Future<void> _deleteNotificationsByRange(String range, String label) async {
    final currentUserId = userId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _showActionMessage(
        "Please check your connection to clear logs.",
        isError: true,
      );
      return;
    }

    final count = _deleteRangeCount(range);
    if (count == 0) {
      _showActionMessage("There are no matching notifications to clean up.");
      return;
    }

    final String timeFrameLabel = label == "all"
        ? "entire history"
        : "$label records";
    final confirmed = await _confirmDelete(
      "Erase $label?",
      "Are you certain you wish to wipe these alerts? Doing this will permanently erase your $timeFrameLabel.",
      "Clear Now",
    );

    if (!confirmed) return;

    final result = await ApiService.deleteNotificationsByRange(
      userId: currentUserId,
      range: range,
    );

    if (!mounted) return;
    if (result["success"] == true) {
      final deletedCount = result["deleted"] ?? count;
      await _loadNotifications();
      _showActionMessage("Success: Wiped $deletedCount historical alerts.");
    } else {
      _showActionMessage(
        result["message"] ?? "An error occurred while cleaning the logs.",
        isError: true,
      );
    }
  }

  int _deleteRangeCount(String range) {
    if (range == "all") return notifications.length;

    final now = DateTime.now();
    return notifications.where((item) {
      final createdAt = _parseCreatedAt(item);
      if (createdAt == null) return false;
      if (range == "today") {
        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      }
      if (range == "month") {
        return createdAt.year == now.year && createdAt.month == now.month;
      }
      return false;
    }).length;
  }

  void _showActionMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? "Update Failed" : "Complete",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade600 : textBlack,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError ? Icons.warning_rounded : Icons.check_circle_rounded,
        color: Colors.white,
      ),
    );
  }

  bool _shouldShowOnTheWayButton(dynamic item) {
    final type = item["type"]?.toString() ?? "";
    final status = item["status"]?.toString() ?? "";
    final reportId = item["report_id"]?.toString() ?? "";
    final createdAt = _parseCreatedAt(item);
    if (type != "VEHICLE_REPORTED_AGAINST_YOU" ||
        status != "SUBMITTED" ||
        reportId.isEmpty ||
        _onTheWayDone.contains(reportId) ||
        createdAt == null) {
      return false;
    }

    return DateTime.now().difference(createdAt) < const Duration(minutes: 2);
  }

  Widget _buildOnTheWayButton(dynamic item) {
    final reportId = item["report_id"]?.toString() ?? "";
    if (reportId.isEmpty || _onTheWayDone.contains(reportId)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          setState(() => _onTheWayDone.add(reportId));
          final result = await ApiService.triggerOnTheWay(
            reportId: reportId,
          );

          if (!mounted) return;
          if (result["success"] == true) {
            setState(() {
              for (final notification in notifications) {
                if (notification["report_id"]?.toString() == reportId &&
                    notification["type"]?.toString() == "VEHICLE_REPORTED_AGAINST_YOU") {
                  notification["status"] = "IN_PROGRESS";
                }
              }
            });
            _showActionMessage(
              "Success! The reporting user was safely alerted.",
            );
          } else {
            setState(() => _onTheWayDone.remove(reportId));
            _showActionMessage(
              result["message"] ?? "The on-the-way window has expired.",
              isError: true,
            );
          }
        },
        icon: const Icon(
          Icons.car_crash_rounded,
          size: 18,
          color: primaryBlue,
        ),
        label: const Text(
          "Confirm: I'm On The Way",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: primaryBlue.withOpacity(0.5),
            width: 1.2,
          ),
          backgroundColor: primaryBlue.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }
  Widget _statusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _coinText(int coins) {
    final positive = coins > 0;
    return Text(
      "${positive ? '+' : ''}$coins Coins",
      style: TextStyle(
        color: positive ? const Color(0xFF10B981) : Colors.red.shade500,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _amountText(dynamic amount) {
    return Text(
      "₹$amount",
      style: const TextStyle(
        color: textBlack,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _title(dynamic item) {
    final type = item["type"]?.toString() ?? "";
    final status = item["status"]?.toString() ?? "";
    if (type == "VEHICLE_ADDED") return "Vehicle Activated";
    if (type == "VEHICLE_UPDATED") return "Registration Edited";
    if (type == "VEHICLE_DELETED") return "Vehicle Archieved";
    if (type == "COUPON_PURCHASED") return "New Coupon Secured";
    if (type == "WALLET_PACKAGE") return "Balance Credited";
    if (type == "VISITOR_PASS") return "Entry Registered";
    if (type == "CONTACT_OTP") return "Emergency Contact OTP";
    if (type == "APP_UPDATE") return "Service Patch Noted";
    if (type == "SUPPORT_TICKET") return "Support Response";
    if (type == "HELPED_VEHICLE") return "User Commended";
    if (type == "PARKING_BOOKING") return "Reservation Tracked";
    if (type == "REPORTED_VEHICLE") {
      if (status == "REJECTED") return "Report Failed";
      if (_isFinalReportStatus(status)) return "Report Successful";
      return "Report Initiated - Fee Charged";
    }
    if (type == "VEHICLE_REPORTED_AGAINST_YOU") {
      if (status == "REJECTED") return "Report Dismissed";
      if (_isFinalReportStatus(status)) return "Report Confirmed";
      return "Vehicle Reported";
    }
    return "Protocol Alert Initiated";
  }
  String _sectionTitle(dynamic item) {
    final createdAt = _parseCreatedAt(item);
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
    final createdAt = _parseCreatedAt(item);
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

  DateTime? _parseCreatedAt(dynamic item) {
    final raw = item["created_at"]?.toString() ?? "";
    final parsed = DateTime.tryParse(raw);
    return parsed?.toLocal();
  }

  String _statusLabel(String status) {
    switch (status) {
      case "IN_PROGRESS":
        return "PROCESSING";
      case "COMPLETED":
      case "CONFIRMED":
      case "APPROVED":
        return "SUCCESSFUL";
      case "REJECTED":
        return "DECLINED";
      case "PENDING":
      case "REQUESTED":
        return "STANDBY";
      case "SENT":
        return "DISPATCHED";
      default:
        return "RECORDED";
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "IN_PROGRESS":
      case "SUBMITTED":
      case "SENT":
      case "PENDING":
      case "REQUESTED":
        return const Color(0xFFF59E0B);
      case "REJECTED":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
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
      case "CONTACT_OTP":
        return const Color(0xFF7C3AED);
      case "APP_UPDATE":
        return const Color(0xFF64748B);
      case "SUPPORT_TICKET":
        return const Color(0xFFEA580C);
      case "VEHICLE_ADDED":
      case "VEHICLE_UPDATED":
        return const Color(0xFF3B82F6);
      case "VEHICLE_DELETED":
        return Colors.red.shade600;
      default:
        return primaryBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case "HELPED_VEHICLE":
        return Icons.verified_user_rounded;
      case "PARKING_BOOKING":
        return Icons.event_seat_rounded;
      case "COUPON_PURCHASED":
        return Icons.redeem_rounded;
      case "WALLET_PACKAGE":
        return Icons.account_balance_wallet_rounded;
      case "VISITOR_PASS":
        return Icons.assignment_ind_rounded;
      case "CONTACT_OTP":
        return Icons.password_rounded;
      case "APP_UPDATE":
        return Icons.system_security_update_rounded;
      case "SUPPORT_TICKET":
        return Icons.support_agent_rounded;
      case "VEHICLE_ADDED":
        return Icons.commute_rounded;
      case "VEHICLE_UPDATED":
        return Icons.edit_note_rounded;
      case "VEHICLE_DELETED":
        return Icons.delete_sweep_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  int _ticketCount() {
    return notifications
        .where((item) => item["type"]?.toString() == "SUPPORT_TICKET")
        .length;
  }
}

class AnimatedResponsiveDeleteButton extends StatefulWidget {
  final VoidCallback onDelete;

  const AnimatedResponsiveDeleteButton({super.key, required this.onDelete});

  @override
  State<AnimatedResponsiveDeleteButton> createState() =>
      _AnimatedResponsiveDeleteButtonState();
}

class _AnimatedResponsiveDeleteButtonState
    extends State<AnimatedResponsiveDeleteButton> {
  bool _isTappedDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTappedDown = true),
      onTapUp: (_) {
        setState(() => _isTappedDown = false);
        widget.onDelete(); // Triggers the removal
      },
      onTapCancel: () => setState(() => _isTappedDown = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _isTappedDown
              ? Colors.red.withOpacity(0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        transform: Matrix4.identity()..scale(_isTappedDown ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        child: Icon(
          Icons.delete_outline_rounded,
          color: _isTappedDown ? Colors.red.shade600 : Colors.blueGrey.shade300,
          size: 19,
        ),
      ),
    );
  }
}
