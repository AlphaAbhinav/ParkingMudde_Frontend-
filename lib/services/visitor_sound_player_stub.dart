import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VisitorSoundPlayer {
  VisitorSoundPlayer._();

  static final VisitorSoundPlayer instance = VisitorSoundPlayer._();

  static const String _assetPath = 'assets/sounds/VisitorPMFinalAlertTone.mpeg';

  VideoPlayerController? _player;

  Future<void> prime() async {}

  Future<void> playOnce() async {
    try {
      await _player?.dispose();
      final player = VideoPlayerController.asset(_assetPath);
      _player = player;
      await player.initialize();
      if (_player != player) {
        await player.dispose();
        return;
      }
      await player.setLooping(false);
      await player.setVolume(1.0);
      await player.play();
    } catch (error) {
      debugPrint("Could not play visitor sound: $error");
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
