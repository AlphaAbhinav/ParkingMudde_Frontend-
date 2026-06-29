import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/guard/guard_app.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isGuardSession = false;

  bool get isHelp => widget.typecv == "help";
  bool get isEmergency => widget.typecv == "emergency";
  bool get isReport => !isHelp && !isEmergency;
  bool get isRejected => isReport && widget.aiScore < 45;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadGuardSession();

    if (isReport) {
      startTimer();
    }
  }

  void _resetToHome({bool startReport = false}) {
    final Widget destination = _isGuardSession
        ? const GuardBootstrap()
        : startReport
            ? const IssueSelectionScreen(typev: "report")
            : const Dash();

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }
  Future<void> _loadGuardSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isGuardSession = prefs.getString('guard_access_token') != null);
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
            title: "Owner on the Way! 🚗",
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
    await _openOffenderIdentificationScreen();
    return;

    setState(() => _isPaymentLoading = true);
    try {
      final storedUser = await ApiService.getStoredUser();
      final currentUserId = storedUser?["user_id"]?.toString() ?? "";

      final orderResult = await ApiService.createReportRazorpayOrder(userId: currentUserId);
      if (orderResult['success'] == false) {
        setState(() => _isPaymentLoading = false);
        Get.defaultDialog(
          title: "API Error",
          middleText: orderResult['message']?.toString() ?? 'Could not initiate payment.',
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
        return;
      }

      final razorpayOrderId = orderResult['razorpay_order_id']?.toString();
      final razorpayKeyId = orderResult['razorpay_key_id']?.toString();

      if (razorpayOrderId == null || razorpayKeyId == null) {
        setState(() => _isPaymentLoading = false);
        Get.defaultDialog(
          title: "Error",
          middleText: "Invalid response from server.",
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
        return;
      }

      final options = {
        'key': razorpayKeyId,
        'order_id': razorpayOrderId,
        'amount': 100, // 1 INR in paise
        'currency': 'INR',
        'name': 'Parking Mudde',
        'description': 'Identify Vehicle Owner',
        'prefill': {
          'contact': '',
          'email': ''
        }
      };

      if (kIsWeb) {
        await openRazorpayWebCheckout(
          Map<String, dynamic>.from(options),
          onSuccess: (response) {
            _handlePaymentSuccess(PaymentSuccessResponse(
              response['razorpay_payment_id'],
              response['razorpay_order_id'],
              response['razorpay_signature'],
              null,
            ));
          },
          onFailure: (message) {
            _handlePaymentError(PaymentFailureResponse(0, message, null));
          },
          onDismiss: () {
            _handlePaymentError(PaymentFailureResponse(0, 'Cancelled', null));
          },
        );
      } else {
        _razorpay.open(options);
      }
    } catch (e) {
      setState(() => _isPaymentLoading = false);
      Get.defaultDialog(
        title: "Error",
        middleText: e.toString(),
        textConfirm: "OK",
        onConfirm: () => Get.back(),
      );
    }
  }

  Future<void> _openOffenderIdentificationScreen() async {
    final result = await Get.to(() => VehicleNumberInputScreen(
          reportId: widget.reportId,
          notificationId: widget.notificationId,
          isAttachingPlate: true,
          razorpayOrderId: _razorpayOrderId,
          razorpayPaymentId: _razorpayPaymentId,
          razorpaySignature: _razorpaySignature,
          guardPlateAttach: _isGuardSession,
        ));

    if (result != null) {
      setState(() {
        _plateAttached = true;
        _vehicleRegistered = result == true;
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
                  color: (isRejected ? Colors.red : (isReport && !_plateAttached ? Colors.orange : Colors.green)).withOpacity(0.1),
                ),
                child: Icon(
                  isRejected ? Icons.cancel_rounded : (isReport && !_plateAttached ? Icons.hourglass_top_rounded : Icons.check_circle_rounded),
                  color: isRejected ? Colors.red : (isReport && !_plateAttached ? Colors.orange : Colors.green),
                  size: 80,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isHelp
                    ? "Thanks for helping! 🤝"
                    : isEmergency
                    ? "Emergency Alert Sent! 🚨"
                    : isRejected
                    ? "Report Rejected ❌"
                    : (!_plateAttached) ? "Almost Done! ⏳" : "Report Submitted! ✅",
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
                    ? (!_plateAttached 
                        ? "The AI has verified your image with a score of ${widget.aiScore}. Please enter or scan the number plate."
                        : "Thank you for helping, car owner has been notified, and as for your efforts you have been awarded 10 PM coins.")
                    : isRejected
                    ? "Your report was evaluated by AI and rejected due to insufficient evidence. The fee is non-refundable."
                    : (!_plateAttached)
                        ? "Your report has been successfully evaluated by AI! Please identify the offending vehicle to notify the owner."
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
              if (isReport) _buildEconomyCard(),

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
                          onTap: _openOffenderIdentificationScreen,
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
                          onTap: _openOffenderIdentificationScreen,
                        ),
                const SizedBox(height: 12),
              ],
              if (!isHelp) ...[
                if (isRejected)
                  _actionButton(
                    label: "Try Again",
                    icon: Icons.refresh_rounded,
                    enabled: true,
                    onTap: () async => _resetToHome(startReport: true),
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
          if (widget.coinsCharged > 0) ...[
            _economyRow(
              icon: Icons.remove_circle_rounded,
              iconColor: Colors.red.shade400,
              label: "Reporting Fee",
              value: "-${widget.coinsCharged} PM Coins",
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
                value: "+10 PM Coins",
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
            ]
          ],

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
              "Masked call option - Enabled after timer 📞",
              _maskedCallSeconds <= 0,
            ),
            _timelineRow(
              "SOS helpline - Enabled after timer 🚨",
              _sosCallSeconds <= 0,
            ),
            _timelineRow(
              sitBackRelax
                  ? "😊 Sit back & relax - owner is on the way!"
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
        onPressed: isTimerActive
            ? null
            : () {
                Get.snackbar("Coming Soon", "$label feature is coming soon!",
                    backgroundColor: const Color(0xFF184B8C), colorText: Colors.white);
              },
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

