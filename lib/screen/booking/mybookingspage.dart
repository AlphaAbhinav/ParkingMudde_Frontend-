import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool isLoading = true;
  List<dynamic> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) {
      setState(() {
        bookings = [];
        isLoading = false;
      });
      return;
    }

    final result = await ApiService.getMyBookings(userId);
    if (mounted) {
      setState(() {
        bookings = result;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Bookings",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2A5EE8)),
          onPressed: Get.back,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : bookings.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.local_parking_rounded,
                          size: 46, color: Color(0xFF2A5EE8)),
                      SizedBox(height: 14),
                      Center(
                        child: Text(
                          "No bookings yet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFF3EBFC),
                              child: Icon(Icons.local_parking_rounded,
                                  color: Color(0xFFA14FFB)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking["parking_name"]?.toString() ??
                                        "Parking Booking",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Status: ${booking["status"] ?? "SENT"}",
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade500,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (booking["amount"] != null)
                              Text(
                                "Rs${booking["amount"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
