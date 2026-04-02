import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Notificationpage extends StatefulWidget {
  const Notificationpage({super.key});

  @override
  State<Notificationpage> createState() => _NotificationpageState();
}

class _NotificationpageState extends State<Notificationpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Premium off-white super-app base
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
            size: 22,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Functional Mock Action Target
            },
            child: const Text(
              "Clear all",
              style: TextStyle(
                color: Color(0XFF184B8C),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 12),

              /// Beautiful Unified List Boundary replacing awkward single flat rows!
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero, // Erases weird inner bleed mappings
                  itemCount: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(
                      left: 60,
                    ), // Keeps divider exclusively bound on text columns smoothly
                    child: Divider(
                      color: Colors.grey.shade100,
                      height: 1,
                      thickness: 1.5,
                    ),
                  ),
                  itemBuilder: (context, i) {
                    return _buildModernNotificationItem(index: i);
                  },
                ),
              ),
              const SizedBox(height: 40), // Safe screen overflow exit spacing
            ],
          ),
        ),
      ),
    );
  }

  /// Refined Premium Custom Logic mapped Notification Builder!
  Widget _buildModernNotificationItem({required int index}) {
    // Abstracted minor variations mathematically to display beautifully alternating representations so your page instantly 'pops'!
    bool isUnread = index < 3; // First 3 marked unread natively
    int logicVariation = index % 3;

    String title;
    IconData visualIcon;
    Color iconColorTint;

    // Simple presentation mocking matching the domain
    if (logicVariation == 0) {
      title = "System Alert";
      visualIcon = Icons.notifications_active_rounded;
      iconColorTint = const Color(0XFF184B8C);
    } else if (logicVariation == 1) {
      title = "New Parking Voucher!";
      visualIcon = Icons.local_activity_rounded;
      iconColorTint = Colors.green.shade600;
    } else {
      title = "Vehicle Verification Processed";
      visualIcon = Icons.directions_car_rounded;
      iconColorTint = Colors.orange.shade700;
    }

    return Material(
      color: Colors.transparent, // Fixes white ink ripple hiding!
      child: InkWell(
        onTap: () {
          // Native interaction handling space
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Interactive Display Component Avatar
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isUnread
                      ? iconColorTint.withOpacity(0.12)
                      : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnread ? Colors.transparent : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  visualIcon,
                  size: 20,
                  color: isUnread ? iconColorTint : Colors.grey.shade400,
                ),
              ),

              const SizedBox(width: 14),

              /// Detailed Segment Readouts!
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isUnread
                                ? Colors.black87
                                : Colors.blueGrey.shade600,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "2h ago",
                          style: TextStyle(
                            color: isUnread
                                ? const Color(0XFF184B8C)
                                : Colors.blueGrey.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Lorem Ipsum is simply dummy text of the printing and typesetting industry mapped beautifully.", // Fleshed to feel robust dynamically.
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.blueGrey.shade500,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // Simple new-unread ping pip component natively integrated!
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0XFF184B8C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
