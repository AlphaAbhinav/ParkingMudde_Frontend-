import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/widgets/ai_confidence_badge.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:parkingmudde/services/razorpay_web_checkout.dart';

class ThankYouReportScreen extends StatefulWidget {
  final dynamic typecv;
  final String? reportId;
  final String? notificationId;
  final int coinsCharged;
  final int coinsbackOnConfirm;
  final int aiScore;
  final String aiVerdict;
  final String? aiReasons;
  final String? issueTitle;
  final String? aiConfidenceLevel;

  const ThankYouReportScreen({
    super.key,
    this.typecv,
    this.reportId,
    this.notificationId,
    this.coinsCharged = 0,
    this.coinsbackOnConfirm = 0,
    this.aiScore = 0,
    this.aiVerdict = "UNDER_REVIEW",
    this.aiReasons,
    this.issueTitle,
    this.aiConfidenceLevel,
  });

  @override
  State<ThankYouReportScreen> createState() => _ThankYouReportScreenState();
}

class _ThankYouReportScreenState extends State<ThankYouReportScreen> {
  static const int maxSeconds = 30;
  int secondsLeft = maxSeconds;
  int elapsedSeconds = 0;
  Timer? timer;
  Timer? pollTimer;
  bool sitBackRelax = false;
  bool _plateAttached = false;
  bool _vehicleRegistered = false; 
  int _offenderPenaltyCoins = 0;
  int _coinsCharged = 0;
  bool _smsAlertChecked = false;

  late Razorpay _razorpay;
  bool _isPaymentLoading = false;
  String? _razorpayOrderId;
  String? _razorpayPaymentId;
  String? _razorpaySignature;

  // Masked Call & SOS Countdown Timers
  int _maskedCallSeconds = 60;
  int _sosCallSeconds = 120;
  Timer? _maskedTimer;
  Timer? _sosTimer;
  bool _hasAddedOnTheWayBonus = false;

  bool get isHelp => widget.typecv == "help";
  bool get isEmergency => widget.typecv == "emergency";
  bool get isReport => !isHelp && !isEmergency;
  bool get isRejected => widget.aiScore < 45;
  String get _displayConfidenceLevel => widget.aiConfidenceLevel ??
      AiConfidenceBadge.confidenceLevelForFlow(
        flow: widget.typecv?.toString(),
        aiScore: widget.aiScore,
      );
  bool get _isUnregisteredAfterPlate =>
      _plateAttached && !_vehicleRegistered && (isHelp || isEmergency);

  Color get _statusColor {
    if (isRejected) return Colors.red;
    if (isEmergency && _isUnregisteredAfterPlate) return Colors.red;
    if (isHelp && _isUnregisteredAfterPlate) return Colors.pink;
    if (isReport && !_plateAttached) return Colors.orange;
    return Colors.green;
  }

  IconData get _statusIcon {
    if (isRejected) return Icons.cancel_rounded;
    if (isEmergency && _isUnregisteredAfterPlate) {
      return Icons.local_hospital_rounded;
    }
    if (isHelp && _isUnregisteredAfterPlate) {
      return Icons.favorite_rounded;
    }
    if (isReport && !_plateAttached) return Icons.hourglass_top_rounded;
    return Icons.check_circle_rounded;
  }

  String get _statusTitle {
    if (isRejected) return "Report Rejected";
    if (isHelp) return "Thanks for helping!";
    if (isEmergency && _isUnregisteredAfterPlate) return "Emergency Help Needed";
    if (isEmergency) return "Emergency Alert Sent!";
    return !_plateAttached ? "Almost Done!" : "Report Submitted!";
  }

  String get _statusMessage {
    if (isRejected) {
      return isHelp
          ? "The helping report was checked by AI, but the photo did not show enough proof. No coins were added or removed."
          : "Your report was evaluated by AI and rejected due to insufficient evidence. No coins were charged.";
    }
    if (isEmergency && _isUnregisteredAfterPlate) {
      return "This user is not a part of the Parking Mudde family. Please contact the nearest hospital to help.";
    }
    if (isEmergency) {
      return "Emergency alert has been recorded. If the victim needs immediate help, call the helpline now.";
    }
    if (isHelp) {
      if (!_plateAttached) {
        return "AI-assisted review is ready. Please enter or scan the number plate.";
      }
      if (!_vehicleRegistered) {
        return "Thanks for helping. Though this vehicle is not a part of the Parking Mudde family, we appreciate your efforts. Keep helping.";
      }
      return "Thank you for helping, car owner has been notified, and as for your efforts you have been awarded PM coins.";
    }
    return !_plateAttached
        ? "Your report has been successfully evaluated by AI! Please identify the offending vehicle to notify the owner."
        : "Your report has been submitted. The vehicle owner has been notified privately.";
  }

  @override
  void initState() {
    super.initState();
    _coinsCharged = widget.coinsCharged;
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }

    if (isReport) {
      startTimer();
    }
  }

  void _resetToHome({bool startReport = false, bool startHelp = false}) {
    final Widget destination =
        startHelp
            ? const IssueSelectionScreen(typev: "help")
            : startReport
            ? const IssueSelectionScreen(typev: "report")
            : const Dash();

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
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

  void _startCallTimers() {
    _maskedTimer?.cancel();
    _sosTimer?.cancel();

    _maskedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_maskedCallSeconds <= 0) {
        t.cancel();
      } else {
        if (mounted) {
          setState(() {
            _maskedCallSeconds--;
          });
        }
      }
    });

    _sosTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sosCallSeconds <= 0) {
        t.cancel();
      } else {
        if (mounted) {
          setState(() {
            _sosCallSeconds--;
          });
        }
      }
    });
  }

  void _extendCallTimers() {
    setState(() {
      _maskedCallSeconds += 300; // Add 5 minutes
      _sosCallSeconds += 300; // Add 5 minutes
    });
    _startCallTimers();
  }

  /// Poll notifications every 5 seconds to detect 'On the Way' from offender
  void _startPollingForOnTheWay() {
    if (widget.reportId == null) return;
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final notifications = await ApiService.getNotificationsForCurrentUser();
      final onMyWayNotif = notifications.firstWhereOrNull((n) =>
          n["status"] == "IN_PROGRESS" &&
          n["type"] == "REPORTED_VEHICLE" &&
          n["report_id"]?.toString() == widget.reportId);

      if (onMyWayNotif != null && !_hasAddedOnTheWayBonus) {
        _hasAddedOnTheWayBonus = true;
        if (mounted) {
          setState(() {
            sitBackRelax = true;
          });
          _extendCallTimers();
          
          Get.defaultDialog(
            title: "Owner on the Way!",
            middleText: "The vehicle owner has confirmed that they are on their way. We have extended the helpline call timer by 5 minutes.",
            textConfirm: "OK",
            confirmTextColor: Colors.white,
            buttonColor: const Color(0xFF184B8C),
            onConfirm: () => Get.back(),
          );
        }
        pollTimer?.cancel();
      }
    });
  }

  // ================= RAZORPAY EVENT HANDLERS =================
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => _isPaymentLoading = false);
    _razorpayOrderId = response.orderId;
    _razorpayPaymentId = response.paymentId;
    _razorpaySignature = response.signature;

    Get.snackbar("Success", "Proceed to enter vehicle plate details.",
      backgroundColor: Colors.green, colorText: Colors.white);

    _openOffenderIdentificationScreen();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPaymentLoading = false);
    Get.defaultDialog(
      title: "Payment Failed",
      middleText: response.message ?? 'Payment was not completed.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isPaymentLoading = false);
  }

  Future<void> _startIdentificationPayment() async {
    if (_isPaymentLoading) return;
    await _openOffenderIdentificationScreen();
  }

  Future<void> _openOffenderIdentificationScreen() async {
    final result = await Get.to(() => VehicleNumberInputScreen(
          reportId: widget.reportId,
          notificationId: widget.notificationId,
          isAttachingPlate: true,
          razorpayOrderId: _razorpayOrderId,
          razorpayPaymentId: _razorpayPaymentId,
          razorpaySignature: _razorpaySignature,
          guardPlateAttach: false,
        ));

    if (result != null) {
      final data = result is Map
          ? Map<String, dynamic>.from(result)
          : <String, dynamic>{'vehicle_registered': result == true};
      final penaltyCoins = int.tryParse(data['offender_penalty_coins']?.toString() ?? '0') ?? 0;
      final coinsCharged = int.tryParse(data['coins_charged']?.toString() ?? '0') ?? 0;

      setState(() {
        _plateAttached = true;
        _vehicleRegistered = data['vehicle_registered'] == true;
        _offenderPenaltyCoins = penaltyCoins;
        _coinsCharged = coinsCharged;
      });

      if (isReport) {
        _triggerSmsAlertAfterOwnerAlert();
        _startCallTimers();
        _startPollingForOnTheWay();
      } else if (isEmergency) {
        _startCallTimers();
      }
    }
  }

  Future<void> _triggerSmsAlertAfterOwnerAlert() async {
    if (widget.reportId == null || !_vehicleRegistered) return;
    await Future.delayed(const Duration(seconds: 1));
    await ApiService.triggerReportAction(
      reportId: widget.reportId!,
      action: "alert",
    );
    if (mounted) {
      setState(() => _smsAlertChecked = true);
    }
  }

  Future<void> _triggerMaskedCall() async {
    if (widget.reportId != null) {
      await ApiService.triggerReportAction(
        reportId: widget.reportId!,
        action: "ivr_call",
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Masked call request sent. No personal number is shared."),
      ),
    );
  }

  Future<void> _callHelpline() async {
    if (widget.reportId != null && !isEmergency) {
      final result = await ApiService.triggerReportAction(
        reportId: widget.reportId!,
        action: "sos",
      );
      
      // Show confirmation dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 8),
                const Expanded(child: Text("SOS Sent!", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            content: const Text(
              "Your request has been sent to the nearest Thana. An officer is on their way to handle the situation.",
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: isEmergency ? '108' : '100');
    await launchUrl(uri);
  }

  @override
  void dispose() {
    timer?.cancel();
    pollTimer?.cancel();
    _maskedTimer?.cancel();
    _sosTimer?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: _statusColor.withOpacity(0.1),
                ),
                child: Icon(
                  _statusIcon,
                  color: _statusColor,
                  size: 80,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _statusTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade500,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),
              AiConfidenceBadge(level: _displayConfidenceLevel),

              const SizedBox(height: 24),

              // ── Report Economy Card (only for report flow) ──
              if (isReport || isRejected) _buildEconomyCard(),

              // ── Timeline (only for report flow) ──
              if (isReport && !isRejected && _plateAttached) ...[
                const SizedBox(height: 16),
                _buildTimeline(),
              ],

              const SizedBox(height: 24),

              // ── Action Buttons ──
              if (!isHelp && !isEmergency && !isRejected) ...[
                if (!_plateAttached)
                  _isPaymentLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(color: Color(0xFF184B8C)),
                          ),
                        )
                      : _actionButton(
                          label: "Enter Vehicle Plate",
                          icon: Icons.camera_alt_rounded,
                          enabled: true,
                          onTap: _startIdentificationPayment,
                        )
                else ...[
                  _actionButton(
                    label: "Vehicle Identified Successfully!",
                    icon: Icons.check_circle_rounded,
                    enabled: false,
                    onTap: () async {},
                  ),
                  const SizedBox(height: 16),
                  _buildCallTimerButton(
                    label: "Masked Call",
                    icon: Icons.phone_callback_rounded,
                    secondsLeft: _maskedCallSeconds,
                    onTap: _triggerMaskedCall,
                  ),
                  const SizedBox(height: 12),
                  _buildCallTimerButton(
                    label: "SOS Helpline Call",
                    icon: Icons.contact_emergency_rounded,
                    secondsLeft: _sosCallSeconds,
                    onTap: _callHelpline,
                  ),
                ],
              ],
              if ((isHelp || isEmergency) && !isRejected && !_plateAttached) ...[
                _isPaymentLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(color: Color(0xFF184B8C)),
                          ),
                        )
                      : _actionButton(
                          label: isEmergency
                              ? "Enter Emergency Vehicle Plate"
                              : "Enter or Scan Number Plate",
                          icon: Icons.camera_alt,
                          enabled: true,
                          onTap: _startIdentificationPayment,
                        ),
                const SizedBox(height: 12),
              ],
              if (isRejected) ...[
                _actionButton(
                  label: "Try Again",
                  icon: Icons.refresh_rounded,
                  enabled: true,
                  onTap: () async => _resetToHome(
                    startHelp: isHelp,
                    startReport: isReport,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextButton(
                onPressed: () => _resetToHome(),
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
                isHelp ? "Helping Report Review" : "Report Economy",
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
          if (_coinsCharged > 0) ...[
            _economyRow(
              icon: Icons.remove_circle_rounded,
              iconColor: Colors.red.shade400,
              label: "Reporting Fee",
              value: "-$_coinsCharged PM Coins",
              valueColor: Colors.red.shade600,
              sublabel: "Charged now",
            ),
            Divider(color: Colors.grey.shade100, height: 20),
          ],

          // Rewards and penalties
          if (!isRejected) ...[
            if (isHelp) ...[
              _economyRow(
                icon: Icons.favorite_rounded,
                iconColor: Colors.pink.shade500,
                label: "Helping Reward",
                value: "PM Coins",
                valueColor: Colors.green.shade700,
                sublabel: "Awarded for helping the community",
              ),
              Divider(color: Colors.grey.shade100, height: 20),
            ] else ...[
              _economyRow(
                icon: Icons.stars_rounded,
                iconColor: Colors.amber.shade600,
                label: "Coinsback Reward",
                value: "+${widget.coinsbackOnConfirm} Coinsback",
                valueColor: Colors.green.shade700,
                sublabel: "Awarded when report is confirmed",
              ),
              if (_plateAttached) ...[
                Divider(color: Colors.grey.shade100, height: 20),
                _economyRow(
                  icon: Icons.gavel_rounded,
                  iconColor: Colors.orange.shade600,
                  label: "Offender Penalty",
                  value: _vehicleRegistered
                      ? "-$_offenderPenaltyCoins PM Coins"
                      : "No deduction",
                  valueColor: _vehicleRegistered
                      ? Colors.orange.shade700
                      : Colors.blueGrey.shade500,
                  sublabel: _vehicleRegistered
                      ? "Deducted after vehicle number was identified"
                      : "Vehicle is not registered with ParkingMudde",
                ),
                Divider(color: Colors.grey.shade100, height: 20),
              ],
            ]
          ],

          _economyRow(
            icon: Icons.smart_toy_rounded,
            iconColor: Colors.purple.shade400,
            label: "AI Confidence",
            value: _displayConfidenceLevel,
            valueColor: Colors.purple.shade600,
            sublabel: widget.aiVerdict == "UNDER_REVIEW"
                ? "AI-assisted review is in progress"
                : "Verdict: ${widget.aiVerdict.replaceAll('_', ' ')}",
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
          if (_vehicleRegistered) ...[
            _timelineRow("User has been alerted", true),
            _timelineRow(
              _smsAlertChecked
                  ? "SMS alert checked after owner notification"
                  : "Checking SMS alert...",
              _smsAlertChecked,
            ),
            _timelineRow(
              "Masked call option - Enabled after timer",
              _maskedCallSeconds <= 0,
            ),
            _timelineRow(
              "SOS helpline - Enabled after timer",
              _sosCallSeconds <= 0,
            ),
            _timelineRow(
              sitBackRelax
                  ? "Sit back & relax - owner is on the way!"
                  : "Waiting for owner to tap 'On the Way'...",
              sitBackRelax,
            ),
          ] else ...[
            _timelineRow(
              "User is not a member of Parking Mudde. If you know them, invite them to join the app!",
              false,
              isComingSoon: true,
            ),
          ]
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

  Widget _buildCallTimerButton({
    required String label,
    required IconData icon,
    required int secondsLeft,
    required VoidCallback onTap,
  }) {
    final bool isTimerActive = secondsLeft > 0;

    String buttonText = label;
    if (isTimerActive) {
      final int minutes = secondsLeft ~/ 60;
      final int seconds = secondsLeft % 60;
      final String timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      buttonText = "$label in $timeStr";
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isTimerActive ? null : onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          buttonText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isTimerActive ? Colors.grey.shade400 : const Color(0xFF184B8C),
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: isTimerActive ? 0 : 3,
        ),
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


