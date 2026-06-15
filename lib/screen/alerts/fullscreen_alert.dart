import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/services/api_service.dart';

class FullScreenAlert extends StatefulWidget {
  final Map<String, dynamic> notificationData;
  final bool isHelping;

  const FullScreenAlert({
    Key? key,
    required this.notificationData,
    required this.isHelping,
  }) : super(key: key);

  @override
  State<FullScreenAlert> createState() => _FullScreenAlertState();
}

class _FullScreenAlertState extends State<FullScreenAlert> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAcknowledge() async {
    setState(() => _isLoading = true);
    final notificationId = widget.notificationData["id"];
    
    if (notificationId != null) {
      await ApiService.updateNotificationStatus(
        notificationId.toString(),
        widget.isHelping ? "ACKNOWLEDGED" : "IN_PROGRESS",
      );
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isHelping ? const Color(0xFF20C475) : const Color(0xFFE53E3E);
    final iconColor = widget.isHelping ? const Color(0xFFE6F9F0) : const Color(0xFFFDE8E8);
    final icon = widget.isHelping ? Icons.favorite_rounded : Icons.warning_amber_rounded;
    final title = widget.isHelping ? "Someone is Helping!" : "Vehicle Reported!";
    final description = widget.notificationData["description"] ?? "Unknown issue";
    final vehicleNumber = widget.notificationData["vehicle_number"] ?? "";

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 80,
                    color: bgColor,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vehicleNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAcknowledge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: bgColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.isHelping ? "Got it, Thanks!" : "I'm On the Way",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
