import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/alerts/fullscreen_alert.dart';
import 'package:parkingmudde/services/api_service.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  void _showOwnerReportAlert(RemoteMessage message) {
    final type = message.data['type'];
    final status = message.data['status'];

    if (type == 'VEHICLE_REPORTED_AGAINST_YOU' && status == 'SUBMITTED') {
      Get.to(
        () => FullScreenAlert(
          notificationData: {
            "id": message.data['notification_id'],
            "report_id": message.data['report_id'],
            "vehicle_number": message.data['vehicle_number'],
            "description": message.notification?.body,
            "type": type,
            "status": status,
          },
          isHelping: false,
        ),
      );
    } else if (type == 'HELP_ALERT' && status == 'IN_PROGRESS') {
      Get.to(
        () => FullScreenAlert(
          notificationData: {
            "id": message.data['notification_id'],
            "report_id": message.data['report_id'],
            "vehicle_number": message.data['vehicle_number'],
            "description": message.notification?.body,
            "type": type,
            "status": status,
          },
          isHelping: true,
        ),
      );
    }
  }

  Future<void> initNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions from user
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Fetch FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Sync token with backend
    if (fcmToken != null) {
      await ApiService.updateFcmToken(fcmToken);
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCM Token Refreshed: $newToken');
      ApiService.updateFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground FCM message: ${message.data}');
      _showOwnerReportAlert(message);
    });

    // Handle background / terminated messages (optional but good for debugging)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from FCM message: ${message.data}');
      _showOwnerReportAlert(message);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showOwnerReportAlert(initialMessage);
      });
    }
  }
}

// Top level function for handling background messages (required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
