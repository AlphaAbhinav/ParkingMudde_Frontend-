import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const parkingMuddeCustomPushChannelId = 'parking_mudde_loop_alert_tone_v1';
const parkingMuddeUrgentFullScreenChannelId =
    'parking_mudde_urgent_full_screen_v12';
const parkingMuddeCallChannelId = 'parking_mudde_calls_v2';
const _customAlertSound = UriAndroidNotificationSound(
  'content://com.parkingmudde.app.notification_sound/parking_mudde_loop_alert',
);
const _iosAlertSound = 'parking_mudde_alert.caf';

const _loudPushChannel = AndroidNotificationChannel(
  parkingMuddeCustomPushChannelId,
  'Parking Mudde Loop Alert Tone',
  description:
      'All Parking Mudde push notifications with a looping alert tone.',
  importance: Importance.max,
  playSound: true,
  sound: _customAlertSound,
  audioAttributesUsage: AudioAttributesUsage.alarm,
  enableVibration: true,
);

const generalChannel = _loudPushChannel;
const _urgentAlertChannel = AndroidNotificationChannel(
  parkingMuddeUrgentFullScreenChannelId,
  'Urgent full-screen vehicle alerts',
  description:
      'Report, help, and emergency alerts that wake and cover the lock screen.',
  importance: Importance.max,
  playSound: true,
  sound: _customAlertSound,
  audioAttributesUsage: AudioAttributesUsage.alarm,
  enableVibration: true,
);
const _otpChannel = _loudPushChannel;
const _callChannel = AndroidNotificationChannel(
  parkingMuddeCallChannelId,
  'Incoming full-screen calls',
  description:
      'Urgent private in-app calls that can appear over the lock screen.',
  importance: Importance.max,
  playSound: true,
  sound: _customAlertSound,
  audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
  enableVibration: true,
);

final _notifications = FlutterLocalNotificationsPlugin();

class PushNotificationService {
  static const _overlayChannel = MethodChannel(
    'com.parkingmudde.app/urgent_overlay',
  );
  static bool _ready = false;
  static Future<void> Function(Map<String, dynamic>)? _onUrgentAlertOpened;

  static Future<void> dismissIncomingCall(Map<String, dynamic> data) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _overlayChannel.invokeMethod<void>('dismissCallOverlay', {
        'call_id': data['call_id']?.toString(),
      });
      final id = int.tryParse(data['notification_id']?.toString() ?? '');
      if (id != null) await _notifications.cancel(id);
    } on PlatformException catch (error) {
      debugPrint('Call alert cleanup failed: ${error.code}');
    } on MissingPluginException {
      // No native notification host in widget tests.
    }
  }

  static void bindNativeAlertHandler(
    Future<void> Function(Map<String, dynamic>) onOpened,
  ) {
    _onUrgentAlertOpened = onOpened;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'openAlert' && call.arguments is Map) {
        unawaited(onOpened(Map<String, dynamic>.from(call.arguments as Map)));
      }
    });
  }

  static int _notificationId(RemoteMessage message) =>
      int.tryParse(message.data['notification_id']?.toString() ?? '') ??
      (message.messageId ?? message.data['call_id']?.toString() ?? 'alert')
          .codeUnits
          .fold<int>(0, (value, unit) => (value * 31 + unit) & 0x7fffffff);

  static Future<void> initializeLocalNotifications({
    Future<void> Function(Map<String, dynamic>)? onUrgentAlertOpened,
    bool requestPermissions = true,
  }) async {
    _onUrgentAlertOpened = onUrgentAlertOpened ?? _onUrgentAlertOpened;
    if (_ready) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      ),
    );
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(generalChannel);
    await android?.createNotificationChannel(_urgentAlertChannel);
    await android?.createNotificationChannel(_otpChannel);
    await android?.createNotificationChannel(_callChannel);
    if (requestPermissions) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _ready = true;

    if (requestPermissions) {
      if (Platform.isAndroid) {
        final pending = await _overlayChannel.invokeMapMethod<String, dynamic>(
          'getPendingAlert',
        );
        if (pending != null) {
          unawaited(
            _onUrgentAlertOpened?.call(pending) ?? Future<void>.value(),
          );
        }
      }
      final launchDetails = await _notifications
          .getNotificationAppLaunchDetails();
      final response = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true && response != null) {
        Future<void>.delayed(
          const Duration(milliseconds: 800),
          () => _handleNotificationResponse(response),
        );
      }
    }
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    final notificationId = response.id;
    if (notificationId != null) {
      unawaited(_notifications.cancel(notificationId));
    }

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      final data = Map<String, dynamic>.from(decoded);
      if (response.actionId == 'answer' || response.actionId == 'decline') {
        data['call_action'] = response.actionId;
      }
      _onUrgentAlertOpened?.call(data);
    }
  }

  static bool _isUrgentAlert(RemoteMessage message) {
    final type = message.data['type']?.toString().toUpperCase();
    final status = message.data['status']?.toString().toUpperCase();
    return (type == 'VEHICLE_REPORTED_AGAINST_YOU' && status == 'SUBMITTED') ||
        ((type == 'HELP_ALERT' || type == 'HELP_VEHICLE') &&
            (status == null || status.isEmpty || status == 'IN_PROGRESS')) ||
        (type == 'EMERGENCY_ALERT' && status == 'SUBMITTED');
  }

  static Future<void> showIncomingCall(RemoteMessage message) async {
    if (!Platform.isAndroid) return;
    final type = message.data['type']?.toString().toUpperCase();
    final status = message.data['status']?.toString().toUpperCase();
    if (type != 'IN_APP_CALL' || status != 'RINGING') return;
    final expires = DateTime.tryParse(
      message.data['expires_at']?.toString() ?? '',
    );
    if (expires != null && !expires.isAfter(DateTime.now())) return;

    await initializeLocalNotifications(requestPermissions: false);
    final data = <String, dynamic>{...message.data};
    data['id'] ??= data['notification_id'];
    data['description'] ??= message.notification?.body ?? data['body'];

    await _notifications.show(
      _notificationId(message),
      message.notification?.title ??
          data['title']?.toString() ??
          'Incoming private call',
      data['description']?.toString() ??
          'Someone is calling you inside Parking Mudde.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          parkingMuddeCallChannelId,
          'Incoming full-screen calls',
          channelDescription:
              'Urgent private in-app calls that can appear over the lock screen.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          playSound: true,
          sound: _customAlertSound,
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          ongoing: true,
          autoCancel: false,
          fullScreenIntent: true,
          timeoutAfter: 90000,
          actions: [
            AndroidNotificationAction(
              'answer',
              'Answer',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'decline',
              'Decline',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  static Future<void> showUrgentAlert(RemoteMessage message) async {
    if (!_isUrgentAlert(message) || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    // APNs already presents the visible iOS alert while Flutter is suspended.
    // Posting a local copy here creates duplicate sounds and notifications.
    if (Platform.isIOS) return;
    await initializeLocalNotifications(requestPermissions: false);

    final data = <String, dynamic>{...message.data};
    data['id'] ??= data['notification_id'];
    data['description'] ??= message.notification?.body ?? data['body'];
    final type = data['type']?.toString().toUpperCase();
    final title =
        message.notification?.title ??
        data['title']?.toString() ??
        (type == 'EMERGENCY_ALERT'
            ? 'Emergency Alert'
            : type == 'HELP_ALERT' || type == 'HELP_VEHICLE'
            ? 'Someone is helping'
            : 'Your vehicle was reported');
    final body =
        data['description']?.toString() ?? 'Open Parking Mudde for details.';

    final details = Platform.isAndroid
        ? NotificationDetails(
            android: AndroidNotificationDetails(
              _urgentAlertChannel.id,
              _urgentAlertChannel.name,
              channelDescription: _urgentAlertChannel.description,
              importance: Importance.max,
              priority: Priority.max,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              fullScreenIntent: true,
              playSound: true,
              sound: _customAlertSound,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              ongoing: true,
              autoCancel: false,
              timeoutAfter: 120000,
            ),
          )
        : const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              presentBanner: true,
              presentList: true,
              sound: _iosAlertSound,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          );

    await _notifications.show(
      _notificationId(message),
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  static Future<void> showContactOtp(RemoteMessage message) async {
    await initializeLocalNotifications();

    final data = <String, dynamic>{...message.data};
    final otp = data['otp']?.toString().trim();
    final body =
        data['body']?.toString() ??
        message.notification?.body ??
        (otp == null || otp.isEmpty
            ? 'Someone is trying to add you as an emergency contact.'
            : 'Your Parking Mudde emergency contact OTP is $otp');

    await _notifications.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      data['title']?.toString() ??
          message.notification?.title ??
          'Emergency Contact OTP',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _otpChannel.id,
          _otpChannel.name,
          channelDescription: _otpChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }
}
