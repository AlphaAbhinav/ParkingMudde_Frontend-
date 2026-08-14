import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/services/alert_sound_player.dart';
import 'package:parkingmudde/services/api_service.dart';

class FullScreenAlert extends StatefulWidget {
  final Map<String, dynamic> notificationData;
  final bool isHelping;

  const FullScreenAlert({
    super.key,
    required this.notificationData,
    required this.isHelping,
  });

  @override
  State<FullScreenAlert> createState() => _FullScreenAlertState();
}

class _FullScreenAlertState extends State<FullScreenAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  String get _alertType =>
      widget.notificationData["type"]?.toString().toUpperCase() ?? "";

  bool get _isEmergencyAlert => _alertType == "EMERGENCY_ALERT";

  bool get _isHelpAlert =>
      widget.isHelping ||
      _alertType == "HELP_ALERT" ||
      _alertType == "HELP_VEHICLE";

  bool get _isReportAlert =>
      _alertType == "VEHICLE_REPORTED_AGAINST_YOU" ||
      (!widget.isHelping && !_isEmergencyAlert);

  bool get _shouldPlayAlertSound =>
      widget.notificationData["suppress_alert_sound"]?.toString().toLowerCase() !=
      "true";

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
    if (_shouldPlayAlertSound) {
      unawaited(_playAlertSound());
    } else {
      unawaited(AlertSoundPlayer.instance.stop());
    }
  }

  @override
  void dispose() {
    unawaited(AlertSoundPlayer.instance.stop());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playAlertSound() async {
    await AlertSoundPlayer.instance.play();
  }

  Future<void> _stopAlertSound() async {
    await AlertSoundPlayer.instance.stop();
  }

  String get _nextStatus => _isReportAlert ? "IN_PROGRESS" : "ACKNOWLEDGED";

  Future<void> _handleAcknowledge() async {
    setState(() => _isLoading = true);
    await _stopAlertSound();
    final notificationId = widget.notificationData["id"];
    final reportId = widget.notificationData["report_id"];

    if (notificationId != null) {
      if (_isReportAlert && reportId != null) {
        await ApiService.triggerOnTheWay(reportId: reportId.toString());
      }
      await ApiService.updateNotificationStatus(
        notificationId.toString(),
        _nextStatus,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isHelpAlert
        ? const Color(0xFF20C475)
        : _isEmergencyAlert
        ? const Color(0xFFB91C1C)
        : const Color(0xFFE53E3E);
    final iconColor = _isHelpAlert
        ? const Color(0xFFE6F9F0)
        : const Color(0xFFFDE8E8);
    final icon = _isHelpAlert
        ? Icons.favorite_rounded
        : _isEmergencyAlert
        ? Icons.emergency_share_rounded
        : Icons.warning_amber_rounded;
    final title = _isHelpAlert
        ? "Someone is Helping!"
        : _isEmergencyAlert
        ? "Emergency Alert Raised"
        : "Your Car Is Being Reported";
    final description =
        widget.notificationData["description"] ??
        (_isEmergencyAlert
            ? "Please check the emergency alert for your vehicle."
            : "Please go and resolve the parking issue.");
    final vehicleNumber = widget.notificationData["vehicle_number"] ?? "";

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
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
                    child: Icon(icon, size: 80, color: bgColor),
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
                if (vehicleNumber.toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
                            _isReportAlert
                                ? "I'm On the Way"
                                : "Acknowledge Alert",
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
      ),
    );
  }
}
