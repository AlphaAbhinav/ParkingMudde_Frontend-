import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const parkingMuddeCustomPushChannelId = 'parking_mudde_loop_alert_tone_v1';
const _customAlertSound = UriAndroidNotificationSound(
  'content://com.parkingmudde.app.notification_sound/parking_mudde_loop_alert',
);

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
const _urgentAlertChannel = _loudPushChannel;
const _otpChannel = _loudPushChannel;

final _notifications = FlutterLocalNotificationsPlugin();

class PushNotificationService {
  static bool _ready = false;
  static Future<void> Function(Map<String, dynamic>)? _onUrgentAlertOpened;

  static Future<void> initializeLocalNotifications({
    Future<void> Function(Map<String, dynamic>)? onUrgentAlertOpened,
    bool requestPermissions = true,
  }) async {
    _onUrgentAlertOpened = onUrgentAlertOpened ?? _onUrgentAlertOpened;
    if (_ready) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
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
    if (requestPermissions) {
      await android?.requestNotificationsPermission();
      await android?.requestFullScreenIntentPermission();
    }

    _ready = true;

    if (requestPermissions) {
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
      data['suppress_alert_sound'] = 'true';
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

  static Future<void> showUrgentAlert(RemoteMessage message) async {
    if (!Platform.isAndroid || !_isUrgentAlert(message)) return;
    await initializeLocalNotifications(requestPermissions: false);

    final data = <String, dynamic>{...message.data};
    data['id'] ??= data['notification_id'];
    data['description'] ??= message.notification?.body ?? data['body'];
    final type = data['type']?.toString().toUpperCase();

    await _notifications.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      message.notification?.title ??
          (type == 'EMERGENCY_ALERT'
              ? 'Emergency Alert'
              : type == 'HELP_ALERT' || type == 'HELP_VEHICLE'
              ? 'Someone is helping'
              : 'Your vehicle was reported'),
      data['description']?.toString() ?? 'Open Parking Mudde for details.',
      NotificationDetails(
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
        ),
      ),
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
