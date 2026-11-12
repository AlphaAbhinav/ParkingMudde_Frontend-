import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkingmudde/services/call_session.dart';

class InAppCallScreen extends StatefulWidget {
  final String callId;
  final String callToken;
  final bool isCaller;
  final String otherPartyLabel;
  final String? vehicleNumber;

  const InAppCallScreen({
    super.key,
    required this.callId,
    required this.callToken,
    required this.isCaller,
    required this.otherPartyLabel,
    this.vehicleNumber,
  });

  @override
  State<InAppCallScreen> createState() => _InAppCallScreenState();
}

class _InAppCallScreenState extends State<InAppCallScreen> {
  late final CallSession call;
  bool closing = false;

  @override
  void initState() {
    super.initState();
    call = CallSession.obtain(
      callId: widget.callId,
      callToken: widget.callToken,
      isCaller: widget.isCaller,
      otherPartyLabel: widget.otherPartyLabel,
    );
    call.addListener(changed);
  }

  void changed() {
    if (!mounted) return;
    if (call.ending && !closing) {
      closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop(true);
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    call.removeListener(changed);
    if (!call.nativeManaged && !call.ending) unawaited(call.hangUp());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(call.hangUp());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF081A2E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
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
                  width: 118,
                  height: 118,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF184B8C),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.otherPartyLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.vehicleNumber?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Regarding vehicle ${widget.vehicleNumber}',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  call.connected ? call.durationLabel : call.status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your phone number is never shown to the other user.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roundControl(
                      icon: call.muted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: call.muted ? 'Unmute' : 'Mute',
                      active: call.muted,
                      onTap: call.toggleMute,
                    ),
                    _roundControl(
                      icon: call.speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      label: 'Speaker',
                      active: call.speakerOn,
                      onTap: call.toggleSpeaker,
                    ),
                    _roundControl(
                      icon: Icons.call_end_rounded,
                      label: 'End',
                      color: const Color(0xFFE24444),
                      onTap: call.hangUp,
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

  Widget _roundControl({
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
    bool active = false,
    Color? color,
  }) {
    final background =
        color ?? (active ? Colors.white : const Color(0xFF18314C));
    final foreground = active ? const Color(0xFF081A2E) : Colors.white;
    return Column(
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => unawaited(onTap()),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: foreground, size: 29),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
