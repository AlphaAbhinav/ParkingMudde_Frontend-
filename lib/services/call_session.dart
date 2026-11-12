import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'api_service.dart';

/// Media and signaling outlive the visible route, including a locked iPhone.
class CallSession extends ChangeNotifier {
  static final Map<String, CallSession> sessions = {};
  static const nativeChannel = MethodChannel('com.parkingmudde.app/calls');
  final String callId;
  final String callToken;
  final bool isCaller;
  final String otherPartyLabel;
  final bool nativeManaged;
  int failedPolls = 0;

  static CallSession obtain({
    required String callId,
    required String callToken,
    required bool isCaller,
    required String otherPartyLabel,
    bool nativeManaged = false,
  }) => sessions.putIfAbsent(callId, () {
    final session = CallSession._(
      callId,
      callToken,
      isCaller,
      otherPartyLabel,
      nativeManaged,
    );
    session.start();
    return session;
  });

  CallSession._(
    this.callId,
    this.callToken,
    this.isCaller,
    this.otherPartyLabel,
    this.nativeManaged,
  );

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Timer? pollTimer;
  Timer? durationTimer;
  int lastSignalId = 0;
  int durationSeconds = 0;
  bool polling = false;
  bool startingPeer = false;
  bool offerSent = false;
  bool remoteDescriptionSet = false;
  bool muted = false;
  bool speakerOn = false;
  bool ending = false;
  bool connected = false;
  String status = 'Calling privately…';
  final List<RTCIceCandidate> pendingCandidates = [];
  List<Map<String, dynamic>> iceServers = [
    {
      'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'],
    },
  ];

  void start() {
    status = isCaller
        ? 'Waiting for ${otherPartyLabel.toLowerCase()}…'
        : 'Connecting securely…';
    pollTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => unawaited(pollOnce()),
    );
    unawaited(pollOnce());
  }

  void setStatus(String value) {
    if (value != status) {
      status = value;
      notifyListeners();
    }
  }

  Future<void> pollOnce() async {
    if (polling || ending) return;
    polling = true;
    try {
      final call = await ApiService.getInAppCall(callId, callToken);
      if (ending) return;
      if (call['success'] != true) {
        if (++failedPolls >= 12) await hangUp();
        return;
      }
      failedPolls = 0;
      final configuredServers = call['ice_servers'];
      if (configuredServers is List && configuredServers.isNotEmpty) {
        iceServers = configuredServers
            .whereType<Map>()
            .map((server) => Map<String, dynamic>.from(server))
            .toList();
      }
      final state = call['status']?.toString().toUpperCase();
      if (const {'REJECTED', 'ENDED', 'MISSED', 'FAILED'}.contains(state)) {
        await remoteFinished(state ?? 'ENDED');
        return;
      }
      if (state == 'ACCEPTED') {
        await ensurePeerConnection();
        if (isCaller && !offerSent) await sendOffer();
        await receiveSignals();
      }
    } catch (_) {
      if (++failedPolls >= 12) await hangUp();
    } finally {
      polling = false;
    }
  }

  Future<void> ensurePeerConnection() async {
    if (ending || peerConnection != null || startingPeer) return;
    startingPeer = true;
    try {
      setStatus('Requesting microphone access…');
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      if (ending) {
        await localStream?.dispose();
        localStream = null;
        return;
      }

      final connection = await createPeerConnection({
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      });
      if (ending) {
        await connection.dispose();
        await localStream?.dispose();
        localStream = null;
        return;
      }
      peerConnection = connection;

      for (final track in localStream!.getAudioTracks()) {
        await connection.addTrack(track, localStream!);
      }

      connection.onIceCandidate = (candidate) {
        if (candidate.candidate == null) return;
        unawaited(
          sendSignalWithRetry('ice', {
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
          markConnected();
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          setStatus('Reconnecting…');
        }
      };
      setStatus('Connecting securely…');
      if (nativeManaged) {
        await nativeChannel.invokeMethod('answerReady', {'call_id': callId});
      }
    } catch (error) {
      setStatus('Microphone access is required for this call');
      await ApiService.endInAppCall(
        callId,
        callToken,
        reason: 'microphone_unavailable',
      );
      await remoteFinished('FAILED');
    } finally {
      startingPeer = false;
    }
  }

  Future<void> sendOffer() async {
    final connection = peerConnection;
    if (connection == null || offerSent) return;
    final offer = await connection.createOffer({'offerToReceiveAudio': true});
    await connection.setLocalDescription(offer);
    offerSent = await sendSignalWithRetry('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  Future<bool> sendSignalWithRetry(
    String type,
    Map<String, dynamic> payload,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final sent = await ApiService.sendInAppCallSignal(
        callId: callId,
        callToken: callToken,
        type: type,
        payload: payload,
      );
      if (sent) return true;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    return false;
  }

  Future<void> receiveSignals() async {
    final connection = peerConnection;
    if (connection == null) return;
    final signals = await ApiService.getInAppCallSignals(
      callId: callId,
      callToken: callToken,
      after: lastSignalId,
    );
    for (final signal in signals) {
      final id = int.tryParse(signal['id']?.toString() ?? '') ?? 0;
      if (id > lastSignalId) lastSignalId = id;
      final type = signal['type']?.toString();
      final rawPayload = signal['payload'];
      if (rawPayload is! Map) continue;
      final payload = Map<String, dynamic>.from(rawPayload);

      if (type == 'offer' && !isCaller) {
        await connection.setRemoteDescription(
          RTCSessionDescription(payload['sdp']?.toString(), 'offer'),
        );
        remoteDescriptionSet = true;
        await flushPendingCandidates();
        final answer = await connection.createAnswer({
          'offerToReceiveAudio': true,
        });
        await connection.setLocalDescription(answer);
        await sendSignalWithRetry('answer', {
          'sdp': answer.sdp,
          'type': answer.type,
        });
      } else if (type == 'answer' && isCaller) {
        await connection.setRemoteDescription(
          RTCSessionDescription(payload['sdp']?.toString(), 'answer'),
        );
        remoteDescriptionSet = true;
        await flushPendingCandidates();
      } else if (type == 'ice') {
        final candidate = RTCIceCandidate(
          payload['candidate']?.toString(),
          payload['sdpMid']?.toString(),
          int.tryParse(payload['sdpMLineIndex']?.toString() ?? ''),
        );
        if (remoteDescriptionSet) {
          await connection.addCandidate(candidate);
        } else {
          pendingCandidates.add(candidate);
        }
      }
    }
  }

  Future<void> flushPendingCandidates() async {
    final connection = peerConnection;
    if (connection == null) return;
    for (final candidate in List<RTCIceCandidate>.from(pendingCandidates)) {
      await connection.addCandidate(candidate);
    }
    pendingCandidates.clear();
  }

  void markConnected() {
    if (connected) return;
    connected = true;
    setStatus('Private call connected');
    durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      durationSeconds++;
      notifyListeners();
    });
  }

  Future<void> toggleMute() async {
    muted = !muted;
    for (final track in localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    if (!kIsWeb) await Helper.setSpeakerphoneOn(speakerOn);
    notifyListeners();
  }

  Future<void> hangUp() async {
    if (ending) return;
    ending = true;
    await disposeMedia();
    notifyListeners();
    await ApiService.endInAppCall(callId, callToken);
  }

  Future<void> remoteFinished(String state) async {
    if (ending) return;
    ending = true;
    await disposeMedia();
    setStatus(
      state == 'MISSED' ? 'The call was not answered.' : 'The call has ended.',
    );
    notifyListeners();
  }

  Future<void> disposeMedia() async {
    pollTimer?.cancel();
    durationTimer?.cancel();
    for (final track in localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await localStream?.dispose();
    await peerConnection?.close();
    await peerConnection?.dispose();
    localStream = null;
    peerConnection = null;
    try {
      if (nativeManaged) {
        await nativeChannel.invokeMethod('end', {'call_id': callId});
      }
    } finally {
      sessions.remove(callId);
    }
  }

  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
