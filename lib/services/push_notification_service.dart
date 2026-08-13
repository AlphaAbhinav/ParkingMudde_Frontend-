import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const generalChannel = AndroidNotificationChannel(
  'parking_mudde_alerts',
  'Parking Mudde Alerts',
  description: 'Parking Mudde report, help, emergency, wallet, and app alerts.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const _otpChannel = AndroidNotificationChannel(
  'parking_mudde_contact_otp',
  'Emergency Contact OTP',
  description: 'OTP notifications for emergency contact verification.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final _notifications = FlutterLocalNotificationsPlugin();

class PushNotificationService {
  static bool _ready = false;

  static Future<void> initializeLocalNotifications() async {
    if (_ready) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(generalChannel);
    await android?.createNotificationChannel(_otpChannel);
    await android?.requestNotificationsPermission();

    _ready = true;
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
