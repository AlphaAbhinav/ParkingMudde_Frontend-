import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

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
    setState(() => isLoading = true);
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
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
            ? _emptyState()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length + 1,
                itemBuilder: (context, index) {
                  if (index == bookings.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 24),
                      child: ScreenSlogan(
                        "Forget parking spots. Not with us around.",
                        color: Color(0xFF2A5EE8),
                        icon: Icons.local_parking_rounded,
                      ),
                    );
                  }
                  final booking = bookings[index];
                  return _bookingCard(booking);
                },
              ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.local_parking_rounded, size: 46, color: Color(0xFF2A5EE8)),
        SizedBox(height: 14),
        Center(
          child: Text(
            "No bookings yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            "Find a nearby parking spot and send a booking request.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ),
        SizedBox(height: 18),
        ScreenSlogan(
          "Forget parking spots. Not with us around.",
          color: Color(0xFF2A5EE8),
          icon: Icons.local_parking_rounded,
        ),
      ],
    );
  }

  Widget _bookingCard(dynamic booking) {
    final status = booking["status"]?.toString() ?? "PENDING";
    final paymentStatus = booking["payment_status"]?.toString() ?? "PENDING";
    final amount = booking["amount"];
    final duration = booking["duration_hours"];
    final vehicleNumber = booking["vehicle_number"]?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              const CircleAvatar(
                backgroundColor: Color(0xFFF3EBFC),
                child: Icon(
                  Icons.local_parking_rounded,
                  color: Color(0xFFA14FFB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking["parking_name"]?.toString() ?? "Parking Booking",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatCreatedAt(booking["created_at"]),
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailChip(
                Icons.schedule_rounded,
                duration == null ? "Duration N/A" : "$duration hour(s)",
              ),
              _detailChip(
                Icons.payments_rounded,
                amount == null
                    ? "On approval"
                    : amount == 0
                    ? "Free"
                    : "Rs$amount",
              ),
              _detailChip(Icons.verified_rounded, paymentStatus),
              if (vehicleNumber != null && vehicleNumber.isNotEmpty)
                _detailChip(Icons.directions_car_rounded, vehicleNumber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final upper = status.toUpperCase();
    final color = upper == "APPROVED" || upper == "COMPLETED"
        ? Colors.green.shade700
        : upper == "REJECTED" || upper == "CANCELLED"
        ? Colors.red.shade700
        : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF2A5EE8)),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(dynamic value) {
    final createdAt = DateTime.tryParse(value?.toString() ?? "");
    if (createdAt == null) return "Recently requested";
    final hour = createdAt.hour > 12
        ? createdAt.hour - 12
        : createdAt.hour == 0
        ? 12
        : createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, "0");
    final suffix = createdAt.hour >= 12 ? "PM" : "AM";
    return "${createdAt.day}/${createdAt.month}/${createdAt.year} - $hour:$minute $suffix";
  }
}
