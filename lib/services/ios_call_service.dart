import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/screen/calls/in_app_call_screen.dart';
import 'api_service.dart';
import 'call_session.dart';

class IosCallService with WidgetsBindingObserver {
  IosCallService._();
  static final instance = IosCallService._();
  static const _channel = MethodChannel('com.parkingmudde.app/calls');
  bool _initialized = false;
  bool _navigationReady = false;
  bool _screenOpen = false;
  bool _syncing = false;
  bool _syncRequested = false;
  CallSession? _session;
  Map<String, dynamic>? _data;
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      final data = Map<String, dynamic>.from(call.arguments as Map? ?? {});
      switch (call.method) {
        case 'token':
          unawaited(syncToken());
        case 'answer':
          _data = data;
          _session = CallSession.obtain(
            callId: data['call_id'].toString(),
            callToken: data['call_token'].toString(),
            isCaller: false,
            otherPartyLabel: 'Reporter',
            nativeManaged: true,
          );
          unawaited(_showCall());
        case 'ended':
          final session = _session;
          _data = null;
          _session = null;
          if (session != null && !session.ending) await session.hangUp();
        case 'mute':
          final session = _session;
          if (session != null && session.muted != data['muted']) {
            await session.toggleMute();
          }
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await _channel.invokeMethod('configure', {
        'backend_url': ApiService.baseUrl,
        'enabled':
            prefs.getString('user_id') != null &&
            prefs.getBool('is_logging_out') != true,
      });
    } on Exception catch (error) {
      debugPrint('iOS call bridge will retry: ${error.runtimeType}');
      WidgetsBinding.instance.removeObserver(this);
      _initialized = false;
    }
  }

  Future<void> syncToken() async {
    if (!supported) return;
    if (_syncing) {
      _syncRequested = true;
      return;
    }
    _syncing = true;
    try {
      await initialize();
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('user_id') ?? '');
      final sessionToken = prefs.getString('session_token');
      if (userId == null ||
          sessionToken == null ||
          sessionToken.isEmpty ||
          prefs.getBool('is_logging_out') == true) {
        return;
      }
      final info = await _channel.invokeMapMethod<String, dynamic>(
        'configure',
        {'backend_url': ApiService.baseUrl, 'enabled': true},
      );
      final token = info?['token']?.toString();
      final fcm = await FirebaseMessaging.instance.getToken();
      if (fcm == null) return;
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/v1/calls/devices/ios'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $sessionToken',
            },
            body: jsonEncode({
              'user_id': userId,
              'fcm_token': fcm,
              'voip_token': token == null || token.isEmpty ? null : token,
              'sandbox': info?['sandbox'] == true,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('iOS call registration will retry on resume.');
      }
    } on Exception catch (error) {
      debugPrint('iOS call setup will retry: ${error.runtimeType}');
    } finally {
      _syncing = false;
      if (_syncRequested) {
        _syncRequested = false;
        unawaited(syncToken());
      }
    }
  }

  Future<void> signOut() async {
    if (supported && _initialized) await _channel.invokeMethod('signOut');
  }

  void navigationReady() {
    _navigationReady = true;
    unawaited(_showCall());
  }

  Future<void> _showCall() async {
    final data = _data;
    final session = _session;
    if (!_navigationReady ||
        _screenOpen ||
        data == null ||
        session == null ||
        session.ending ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        Get.key.currentState == null) {
      return;
    }
    _screenOpen = true;
    try {
      await Get.to<bool>(
        () => InAppCallScreen(
          callId: session.callId,
          callToken: session.callToken,
          isCaller: false,
          otherPartyLabel: 'Reporter',
          vehicleNumber: data['vehicle_number']?.toString(),
        ),
      );
    } finally {
      _screenOpen = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncToken());
      unawaited(_showCall());
    }
  }
}
