import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';

class ThankYouReportScreen extends StatefulWidget {
  final dynamic typecv;
  final String? reportId;
  final int coinsCharged;
  final int coinsbackOnConfirm;
  final int aiScore;
  final String aiVerdict;
  final String? aiReasons;

  const ThankYouReportScreen({
    super.key,
    this.typecv,
    this.reportId,
    this.coinsCharged = 0,
    this.coinsbackOnConfirm = 0,
    this.aiScore = 0,
    this.aiVerdict = "UNDER_REVIEW",
    this.aiReasons,
  });

  @override
  State<ThankYouReportScreen> createState() => _ThankYouReportScreenState();
}

class _ThankYouReportScreenState extends State<ThankYouReportScreen> {
  static const int maxSeconds = 60;
  int secondsLeft = maxSeconds;
  int elapsedSeconds = 0;
  Timer? timer;
  Timer? pollTimer;
  bool sitBackRelax = false; // true when offender taps On the Way

  bool get isHelp => widget.typecv == "help";
  bool get isEmergency => widget.typecv == "emergency";
  bool get isReport => !isHelp && !isEmergency;

  @override
  void initState() {
    super.initState();
    if (isReport) {
      startTimer();
      _startPollingForOnTheWay();
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() {
          secondsLeft--;
          elapsedSeconds++;
        });
      }
    });
  }

  bool get isMaskedCallEnabled => false; // Disabled until SMS/Call API key is available
  bool get isSosEnabled => false; // Disabled until SMS/Call API key is available

  /// Poll notifications every 5 seconds to detect 'On the Way' from offender
  void _startPollingForOnTheWay() {
    if (widget.reportId == null) return;
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (sitBackRelax) {
        pollTimer?.cancel();
        return;
      }
      final notifications = await ApiService.getNotificationsForCurrentUser();
      if (notifications.any((n) =>
          n["status"] == "IN_PROGRESS" &&
          n["type"] == "REPORTED_VEHICLE")) {
        if (mounted) setState(() => sitBackRelax = true);
        pollTimer?.cancel();
      }
    });
  }

  Future<void> _triggerMaskedCall() async {
    if (widget.reportId != null) {
      await ApiService.triggerReportAction(
        reportId: widget.reportId!,
        action: "ivr_call",
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Masked call request sent. No personal number is shared."),
      ),
    );
  }

  Future<void> _callHelpline() async {
    if (widget.reportId != null && !isEmergency) {
      await ApiService.triggerReportAction(
        reportId: widget.reportId!,
        action: "sos",
      );
    }
    final uri = Uri(scheme: 'tel', path: isEmergency ? '108' : '100');
    await launchUrl(uri);
  }

  @override
  void dispose() {
    timer?.cancel();
    pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCallEnabled = isSosEnabled || isEmergency;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // ── Success Icon ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isHelp
                    ? "Thanks for helping! 🤝"
                    : isEmergency
                    ? "Emergency Alert Sent! 🚨"
                    : "Report Submitted! ✅",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isEmergency
                    ? "Emergency alert has been recorded. If the victim needs immediate help, call the helpline now."
                    : isHelp
                    ? "Your helping alert has been sent successfully."
                    : "Your report has been submitted. The vehicle owner has been notified privately.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade500,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // ── Report Economy Card (only for report flow) ──
              if (isReport && widget.coinsCharged > 0) _buildEconomyCard(),

              // ── Timeline (only for report flow) ──
              if (isReport) ...[
                const SizedBox(height: 16),
                _buildTimeline(),
              ],

              const SizedBox(height: 24),

              // ── Action Buttons ──
              if (!isHelp && !isEmergency) ...[
                _actionButton(
                  label: "Masked Call Option (Coming Soon)",
                  icon: Icons.phone_in_talk_rounded,
                  enabled: isMaskedCallEnabled,
                  onTap: _triggerMaskedCall,
                ),
                const SizedBox(height: 12),
              ],
              if (!isHelp) ...[
                _actionButton(
                  label: isEmergency ? "Call Emergency Helpline" : "Call Parking Helpline (Coming Soon)",
                  icon: Icons.call_rounded,
                  enabled: isCallEnabled,
                  onTap: _callHelpline,
                ),
                const SizedBox(height: 16),
              ],

              TextButton(
                onPressed: () => Get.offAll(() => const Dash()),
                child: Text(
                  "Go Back to Home",
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Economy Summary Card ──
  Widget _buildEconomyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF184B8C), size: 18),
              const SizedBox(width: 8),
              Text(
                "Report Economy",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PM Coins charged
          _economyRow(
            icon: Icons.remove_circle_rounded,
            iconColor: Colors.red.shade400,
            label: "Reporting Fee",
            value: "-${widget.coinsCharged} PM Coins",
            valueColor: Colors.red.shade600,
            sublabel: "Charged now",
          ),

          Divider(color: Colors.grey.shade100, height: 20),

          // Coinsback on confirmation
          _economyRow(
            icon: Icons.stars_rounded,
            iconColor: Colors.amber.shade600,
            label: "Coinsback Reward",
            value: "+${widget.coinsbackOnConfirm} Coinsback",
            valueColor: Colors.green.shade700,
            sublabel: "Awarded when report is confirmed",
          ),

          Divider(color: Colors.grey.shade100, height: 20),

          // Offender penalty
          _economyRow(
            icon: Icons.gavel_rounded,
            iconColor: Colors.orange.shade600,
            label: "Offender Penalty",
            value: "-10 PM Coins",
            valueColor: Colors.orange.shade700,
            sublabel: "Deducted from offender on confirmation",
          ),

          Divider(color: Colors.grey.shade100, height: 20),

          // AI verdict
          _economyRow(
            icon: Icons.smart_toy_rounded,
            iconColor: Colors.purple.shade400,
            label: "AI Verdict",
            value: widget.aiVerdict == "UNDER_REVIEW" 
                   ? "Under Review" 
                   : "${widget.aiScore} - ${widget.aiVerdict.replaceAll('_', ' ')}",
            valueColor: Colors.purple.shade600,
            sublabel: widget.aiVerdict == "UNDER_REVIEW" 
                      ? "Score & verdict generated after analysis" 
                      : "Analysis complete",
          ),
        ],
      ),
    );
  }

  Widget _economyRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required String sublabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 2),
              Text(sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade300,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Timeline ──
  Widget _buildTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF184B8C).withOpacity(0.07),
      ),
      child: Column(
        children: [
          _timelineRow("In-app alert sent to owner", true),
          _timelineRow(
            "SMS alert — Coming Soon 📲",
            false,
            isComingSoon: true,
          ),
          _timelineRow(
            "Masked call option — Coming Soon 📞",
            false,
            isComingSoon: true,
          ),
          _timelineRow(
            "SOS helpline — Coming Soon 🚨",
            false,
            isComingSoon: true,
          ),
          _timelineRow(
            sitBackRelax
                ? "😊 Sit back & relax — owner is on the way!"
                : "Waiting for owner to tap 'On the Way'…",
            sitBackRelax,
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(String text, bool done, {bool isComingSoon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            isComingSoon
                ? Icons.schedule_rounded
                : done
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_bottom_rounded,
            color: isComingSoon
                ? Colors.blueGrey.shade300
                : done
                    ? Colors.green
                    : const Color(0xFF184B8C),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isComingSoon ? Colors.blueGrey.shade400 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Button ──
  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required Future<void> Function() onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? const Color(0xFF184B8C) : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: enabled ? 3 : 0,
        ),
      ),
    );
  }
}
