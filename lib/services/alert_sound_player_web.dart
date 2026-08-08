// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class AlertSoundPlayer {
  AlertSoundPlayer._();

  static final AlertSoundPlayer instance = AlertSoundPlayer._();

  static const List<String> _assetUrls = [
    'assets/assets/sounds/FullAudioPMAlertsFinalAlertTone.mpeg',
    'assets/sounds/FullAudioPMAlertsFinalAlertTone.mpeg',
  ];

  html.AudioElement? _audio;
  bool _isPrimed = false;
  bool _isPrimeListenerAttached = false;

  Future<void> prime() async {
    if (_isPrimed || _isPrimeListenerAttached) return;
    _isPrimeListenerAttached = true;

    void unlock(html.Event _) {
      _unlockAudio();
      html.document.removeEventListener('click', unlock);
      html.document.removeEventListener('touchstart', unlock);
      html.document.removeEventListener('keydown', unlock);
    }

    html.document.addEventListener('click', unlock);
    html.document.addEventListener('touchstart', unlock);
    html.document.addEventListener('keydown', unlock);
  }

  Future<void> _unlockAudio() async {
    try {
      final audio = _createAudio();
      audio.volume = 0;
      await audio.play();
      audio.pause();
      audio.currentTime = 0;
      audio.volume = 1;
      _audio = audio;
      _isPrimed = true;
    } catch (error) {
      debugPrint("Could not prime alert sound on web: $error");
    }
  }

  Future<void> play() async {
    try {
      final audio = _audio ?? _createAudio();
      _audio = audio;
      audio.pause();
      audio.currentTime = 0;
      audio.volume = 1;
      await audio.play();
      _isPrimed = true;
    } catch (error) {
      debugPrint("Could not play alert sound on web: $error");
    }
  }

  Future<void> stop() async {
    try {
      final audio = _audio;
      if (audio == null) return;
      audio.pause();
      audio.currentTime = 0;
    } catch (error) {
      debugPrint("Could not stop alert sound on web: $error");
    }
  }

  Future<void> dispose() async {
    await stop();
    _audio = null;
  }

  html.AudioElement _createAudio() {
    final audio = html.AudioElement()
      ..preload = 'auto'
      ..autoplay = false
      ..loop = true;

    for (final url in _assetUrls) {
      audio.append(
        html.SourceElement()
          ..src = url
          ..type = 'audio/mpeg',
      );
    }

    audio.load();
    return audio;
  }
}
