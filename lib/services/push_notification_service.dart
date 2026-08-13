import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screen/notification/full_screen_alert_page.dart';
import 'api_service.dart';

const _urgentChannel = AndroidNotificationChannel(
  'parking_mudde_urgent_alerts',
  'Urgent Parking Alerts',
  description: 'Emergency and time-sensitive vehicle alerts.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final _notifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> parkingMuddeBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  await PushNotificationService.initializeLocalNotifications();
  await PushNotificationService.show(message);
}

class PushNotificationService {
  static bool _localNotificationsReady = false;

  static Future<void> initializeLocalNotifications() async {
    if (_localNotificationsReady) return;
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) => _openPayload(response.payload),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_urgentChannel);
    _localNotificationsReady = true;
  }

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      await initializeLocalNotifications();

      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestFullScreenIntentPermission();

      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(parkingMuddeBackgroundMessage);
      FirebaseMessaging.onMessage.listen(show);
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _open(message.data));

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(initialMessage.data));
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
    } catch (error, stackTrace) {
      debugPrint('Push notifications are not configured: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _registerToken(String token) async {
    final userId = (await SharedPreferences.getInstance()).getString('user_id');
    if (userId == null || userId.isEmpty) return;
    final registered = await ApiService.registerPushToken(userId: userId, token: token);
    debugPrint(registered ? 'FCM device registered.' : 'FCM device registration failed.');
  }

  static Future<void> syncCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (error) {
      debugPrint('Unable to sync FCM device: $error');
    }
  }

  static bool _isFullScreen(Map<String, dynamic> data) {
    final requested = data['full_screen']?.toString().toLowerCase() == 'true';
    final type = data['type']?.toString().toUpperCase() ?? '';
    return requested &&
        (type.contains('EMERGENCY') ||
            type.contains('REPORT') ||
            type.contains('HELP'));
  }

  static Future<void> show(RemoteMessage message) async {
    final data = <String, dynamic>{...message.data};
    data['title'] ??= message.notification?.title;
    data['body'] ??= message.notification?.body;
    final fullScreen = _isFullScreen(data);

    await _notifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: data['title']?.toString() ?? 'Parking Mudde Alert',
      body: data['body']?.toString() ?? 'Please check your vehicle alert.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _urgentChannel.id,
          _urgentChannel.name,
          channelDescription: _urgentChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          category: fullScreen ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.status,
          fullScreenIntent: fullScreen,
          ongoing: fullScreen,
          autoCancel: !fullScreen,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: jsonEncode(data),
    );

    if (fullScreen && Get.context != null) _open(data);
  }

  static void _openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (error) {
      debugPrint('Invalid notification payload: $error');
    }
  }

  static void _open(Map<String, dynamic> data) {
    if (!_isFullScreen(data) || Get.context == null) return;
    Get.to(() => FullScreenAlertPage(data: data), fullscreenDialog: true);
  }
}
