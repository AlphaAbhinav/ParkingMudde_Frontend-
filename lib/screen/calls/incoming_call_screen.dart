import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkingmudde/screen/calls/in_app_call_screen.dart';
import 'package:parkingmudde/services/alert_sound_player.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/push_notification_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final String? initialAction;

  const IncomingCallScreen({
    super.key,
    required this.callData,
    this.initialAction,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  Timer? _statusTimer;
  Timer? _expiryTimer;
  bool _busy = false;
  bool _checking = false;
  bool _closing = false;
  String? _error;
  late final DateTime _expiresAt;

  String get _callId => widget.callData['call_id']?.toString() ?? '';
  String get _callToken => widget.callData['call_token']?.toString() ?? '';
  String get _vehicleNumber =>
      widget.callData['vehicle_number']?.toString() ?? '';
  String get _callerLabel =>
      widget.callData['caller_label']?.toString() ?? 'Parking Mudde reporter';

  @override
  void initState() {
    super.initState();
    unawaited(PushNotificationService.dismissIncomingCall(widget.callData));
    _expiresAt =
        DateTime.tryParse(widget.callData['expires_at']?.toString() ?? '') ??
        DateTime.now().add(const Duration(seconds: 90));
    if (!DateTime.now().isBefore(_expiresAt)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_close()));
      return;
    }
    if (widget.initialAction == 'answer' || widget.initialAction == 'decline') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(widget.initialAction == 'answer' ? _accept() : _decline());
      });
    } else {
      unawaited(AlertSoundPlayer.instance.play());
    }
    _expiryTimer = Timer(
      _expiresAt.difference(DateTime.now()),
      () => unawaited(_close()),
    );
    _statusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_checkStillRinging()),
    );
    if (widget.initialAction == null) unawaited(_checkStillRinging());
  }

  Future<void> _checkStillRinging() async {
    if (_closing ||
        _busy ||
        _checking ||
        _callId.isEmpty ||
        _callToken.isEmpty) {
      return;
    }
    if (!DateTime.now().isBefore(_expiresAt)) {
      await _close();
      return;
    }
    _checking = true;
    try {
      final result = await ApiService.getInAppCall(_callId, _callToken);
      if (!mounted || _closing || _busy || result['success'] != true) return;
      if (result['status']?.toString().toUpperCase() != 'RINGING') {
        await _close();
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await AlertSoundPlayer.instance.stop();
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _accept() async {
    if (_busy) return;
    _expiryTimer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    await AlertSoundPlayer.instance.stop();
    var result = await ApiService.acceptInAppCall(_callId, _callToken);
    // A repeated Answer delivery must not tear down an accepted call.
    if (result['success'] != true) {
      final current = await ApiService.getInAppCall(_callId, _callToken);
      if (current['success'] == true && current['status'] == 'ACCEPTED') {
        result = current;
      }
    }
    if (!mounted || _closing) return;
    if (result['success'] != true) {
      if (!DateTime.now().isBefore(_expiresAt)) {
        await _close();
        return;
      }
      _expiryTimer = Timer(
        _expiresAt.difference(DateTime.now()),
        () => unawaited(_close()),
      );
      setState(() {
        _busy = false;
        _error =
            result['message']?.toString() ??
            'This call is no longer available.';
      });
      return;
    }
    await Navigator.of(context).pushReplacement<bool, bool>(
      MaterialPageRoute(
        builder: (_) => InAppCallScreen(
          callId: _callId,
          callToken: _callToken,
          isCaller: false,
          otherPartyLabel: 'Reporter',
          vehicleNumber: _vehicleNumber,
        ),
      ),
      result: true,
    );
  }

  Future<void> _decline() async {
    if (_busy) return;
    _expiryTimer?.cancel();
    setState(() => _busy = true);
    await AlertSoundPlayer.instance.stop();
    await ApiService.rejectInAppCall(_callId, _callToken);
    if (mounted && !_closing) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _expiryTimer?.cancel();
    unawaited(AlertSoundPlayer.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF081A2E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF71D7A1),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'PRIVATE IN-APP CALL',
                      style: TextStyle(
                        color: Color(0xFF71D7A1),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 126,
                  height: 126,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF184B8C),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 68,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _callerLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Incoming audio call',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (_vehicleNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Regarding vehicle $_vehicleNumber',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'The call stays inside Parking Mudde. Neither user can see the other person’s phone number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFF9B9B)),
                  ),
                ],
                const Spacer(),
                if (_busy)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _callAction(
                        label: 'Decline',
                        icon: Icons.call_end_rounded,
                        color: const Color(0xFFE24444),
                        onTap: _decline,
                      ),
                      _callAction(
                        label: 'Accept',
                        icon: Icons.call_rounded,
                        color: const Color(0xFF22A866),
                        onTap: _accept,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _callAction({
    required String label,
    required IconData icon,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => unawaited(onTap()),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
