import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class AlertSoundPlayer {
  AlertSoundPlayer._();

  static final AlertSoundPlayer instance = AlertSoundPlayer._();

  static const String _assetPath =
      'assets/sounds/FullAudioPMAlertsFinalAlertTone.mpeg';

  VideoPlayerController? _player;

  Future<void> prime() async {}

  Future<void> play() async {
    try {
      await _player?.dispose();
      final player = VideoPlayerController.asset(_assetPath);
      _player = player;
      await player.initialize();
      if (_player != player) {
        await player.dispose();
        return;
      }
      await player.setLooping(true);
      await player.setVolume(1.0);
      await player.play();
    } catch (error) {
      debugPrint("Could not play alert sound: $error");
    }
  }

  Future<void> stop() async {
    try {
      await _player?.pause();
      await _player?.seekTo(Duration.zero);
    } catch (error) {
      debugPrint("Could not stop alert sound: $error");
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
