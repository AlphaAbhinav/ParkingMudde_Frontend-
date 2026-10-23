import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:parkingmudde/services/api_service.dart';

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
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Timer? _pollTimer;
  Timer? _durationTimer;
  int _lastSignalId = 0;
  int _durationSeconds = 0;
  bool _polling = false;
  bool _startingPeer = false;
  bool _offerSent = false;
  bool _remoteDescriptionSet = false;
  bool _muted = false;
  bool _speakerOn = false;
  bool _ending = false;
  bool _connected = false;
  String _status = 'Calling privately…';
  final List<RTCIceCandidate> _pendingCandidates = [];
  List<Map<String, dynamic>> _iceServers = [
    {
      'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.isCaller
        ? 'Waiting for ${widget.otherPartyLabel.toLowerCase()}…'
        : 'Connecting securely…';
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => unawaited(_pollOnce()),
    );
    unawaited(_pollOnce());
  }

  void _setStatus(String value) {
    if (mounted && value != _status) setState(() => _status = value);
  }

  Future<void> _pollOnce() async {
    if (_polling || _ending) return;
    _polling = true;
    try {
      final call = await ApiService.getInAppCall(
        widget.callId,
        widget.callToken,
      );
      if (call['success'] != true) return;
      final configuredServers = call['ice_servers'];
      if (configuredServers is List && configuredServers.isNotEmpty) {
        _iceServers = configuredServers
            .whereType<Map>()
            .map((server) => Map<String, dynamic>.from(server))
            .toList();
      }
      final state = call['status']?.toString().toUpperCase();
      if (const {'REJECTED', 'ENDED', 'MISSED', 'FAILED'}.contains(state)) {
        await _remoteFinished(state ?? 'ENDED');
        return;
      }
      if (state == 'ACCEPTED') {
        await _ensurePeerConnection();
        if (widget.isCaller && !_offerSent) await _sendOffer();
        await _receiveSignals();
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _ensurePeerConnection() async {
    if (_peerConnection != null || _startingPeer) return;
    _startingPeer = true;
    try {
      _setStatus('Requesting microphone access…');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      final connection = await createPeerConnection({
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
      });
      _peerConnection = connection;

      for (final track in _localStream!.getAudioTracks()) {
        await connection.addTrack(track, _localStream!);
      }

      connection.onIceCandidate = (candidate) {
        if (candidate.candidate == null) return;
        unawaited(
          _sendSignalWithRetry('ice', {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }),
        );
      };
      connection.onTrack = (event) {
        if (event.track.kind == 'audio') {
          event.track.enabled = true;
        }
      };
      connection.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _markConnected();
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _setStatus('Reconnecting…');
        }
      };
      _setStatus('Connecting securely…');
    } catch (error) {
      _setStatus('Microphone access is required for this call');
      await ApiService.endInAppCall(
        widget.callId,
        widget.callToken,
        reason: 'microphone_unavailable',
      );
    } finally {
      _startingPeer = false;
    }
  }

  Future<void> _sendOffer() async {
    final connection = _peerConnection;
    if (connection == null || _offerSent) return;
    final offer = await connection.createOffer({'offerToReceiveAudio': true});
    await connection.setLocalDescription(offer);
    _offerSent = await _sendSignalWithRetry('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  Future<bool> _sendSignalWithRetry(
    String type,
    Map<String, dynamic> payload,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final sent = await ApiService.sendInAppCallSignal(
        callId: widget.callId,
        callToken: widget.callToken,
        type: type,
        payload: payload,
      );
      if (sent) return true;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    return false;
  }

  Future<void> _receiveSignals() async {
    final connection = _peerConnection;
    if (connection == null) return;
    final signals = await ApiService.getInAppCallSignals(
      callId: widget.callId,
      callToken: widget.callToken,
      after: _lastSignalId,
    );
    for (final signal in signals) {
      final id = int.tryParse(signal['id']?.toString() ?? '') ?? 0;
      if (id > _lastSignalId) _lastSignalId = id;
      final type = signal['type']?.toString();
      final rawPayload = signal['payload'];
      if (rawPayload is! Map) continue;
      final payload = Map<String, dynamic>.from(rawPayload);

      if (type == 'offer' && !widget.isCaller) {
        await connection.setRemoteDescription(
          RTCSessionDescription(payload['sdp']?.toString(), 'offer'),
        );
        _remoteDescriptionSet = true;
        await _flushPendingCandidates();
        final answer = await connection.createAnswer({
          'offerToReceiveAudio': true,
        });
        await connection.setLocalDescription(answer);
        await _sendSignalWithRetry('answer', {
          'sdp': answer.sdp,
          'type': answer.type,
        });
      } else if (type == 'answer' && widget.isCaller) {
        await connection.setRemoteDescription(
          RTCSessionDescription(payload['sdp']?.toString(), 'answer'),
        );
        _remoteDescriptionSet = true;
        await _flushPendingCandidates();
      } else if (type == 'ice') {
        final candidate = RTCIceCandidate(
          payload['candidate']?.toString(),
          payload['sdpMid']?.toString(),
          int.tryParse(payload['sdpMLineIndex']?.toString() ?? ''),
        );
        if (_remoteDescriptionSet) {
          await connection.addCandidate(candidate);
        } else {
          _pendingCandidates.add(candidate);
        }
      }
    }
  }

  Future<void> _flushPendingCandidates() async {
    final connection = _peerConnection;
    if (connection == null) return;
    for (final candidate in List<RTCIceCandidate>.from(_pendingCandidates)) {
      await connection.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  void _markConnected() {
    if (_connected) return;
    _connected = true;
    _setStatus('Private call connected');
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });
  }

  Future<void> _toggleMute() async {
    _muted = !_muted;
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !_muted;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    if (!kIsWeb) await Helper.setSpeakerphoneOn(_speakerOn);
    if (mounted) setState(() {});
  }

  Future<void> _hangUp() async {
    if (_ending) return;
    _ending = true;
    await ApiService.endInAppCall(widget.callId, widget.callToken);
    await _disposeMedia();
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _remoteFinished(String state) async {
    if (_ending) return;
    _ending = true;
    await _disposeMedia();
    if (!mounted) return;
    final message = switch (state) {
      'REJECTED' => 'The call was declined.',
      'MISSED' => 'The call was not answered.',
      _ => 'The call has ended.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop(true);
  }

  Future<void> _disposeMedia() async {
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _localStream = null;
    _peerConnection = null;
  }

  String get _durationLabel {
    final minutes = _durationSeconds ~/ 60;
    final seconds = _durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    unawaited(_localStream?.dispose() ?? Future<void>.value());
    unawaited(_peerConnection?.close() ?? Future<void>.value());
    unawaited(_peerConnection?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_hangUp());
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
                  _connected ? _durationLabel : _status,
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
                      icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _muted ? 'Unmute' : 'Mute',
                      active: _muted,
                      onTap: _toggleMute,
                    ),
                    _roundControl(
                      icon: _speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      label: 'Speaker',
                      active: _speakerOn,
                      onTap: _toggleSpeaker,
                    ),
                    _roundControl(
                      icon: Icons.call_end_rounded,
                      label: 'End',
                      color: const Color(0xFFE24444),
                      onTap: _hangUp,
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
