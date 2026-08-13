import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/alerts/fullscreen_alert.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/alert_state.dart';
import 'package:parkingmudde/services/push_notification_service.dart';
import 'package:parkingmudde/services/visitor_sound_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  static const String _playedVisitorApprovalIdsKey =
      'visitor_approval_sound_played_ids';

  Future<bool> _hasLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    return userId != null && userId.isNotEmpty;
  }

  Future<void> _markVisitorApprovalSoundPlayed(RemoteMessage message) async {
    final visitorId = message.data['visitor_id']?.toString().trim();
    if (visitorId == null || visitorId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final played =
        prefs.getStringList(_playedVisitorApprovalIdsKey)?.toSet() ??
        <String>{};
    if (played.add(visitorId)) {
      await prefs.setStringList(_playedVisitorApprovalIdsKey, played.toList());
    }
  }

  Future<void> _showOwnerReportAlert(RemoteMessage message) async {
    if (!await _hasLoggedInUser()) return;

    final type = message.data['type']?.toString().toUpperCase();
    final status = message.data['status']?.toString().toUpperCase();
    final description =
        message.notification?.body ?? message.data['body']?.toString();

    if (type == 'VEHICLE_REPORTED_AGAINST_YOU' && status == 'SUBMITTED') {
      await _openTrackedAlert({
        "id": message.data['notification_id'],
        "report_id": message.data['report_id'],
        "vehicle_number": message.data['vehicle_number'],
        "description": description,
        "type": type,
        "status": status,
      }, isHelping: false);
    } else if (type == 'HELP_ALERT' && status == 'IN_PROGRESS') {
      await _openTrackedAlert({
        "id": message.data['notification_id'],
        "report_id": message.data['report_id'],
        "vehicle_number": message.data['vehicle_number'],
        "description": description,
        "type": type,
        "status": status,
      }, isHelping: true);
    } else if (type == 'EMERGENCY_ALERT' && status == 'SUBMITTED') {
      await _openTrackedAlert({
        "id": message.data['notification_id'] ?? message.data['id'],
        "report_id": message.data['report_id'],
        "vehicle_number": message.data['vehicle_number'],
        "description": description,
        "type": type,
        "status": status,
      }, isHelping: false);
    } else if (type == 'VISITOR_PASS' && status == 'APPROVED') {
      await VisitorSoundPlayer.instance.playOnce();
      await _markVisitorApprovalSoundPlayed(message);
    }
  }

  Future<bool> _isContactOtpNotification(RemoteMessage message) async {
    if (!await _hasLoggedInUser()) return false;

    final type = message.data['type']?.toString().toUpperCase();
    return type == 'CONTACT_OTP';
  }

  Future<bool> _showContactOtpNotification(RemoteMessage message) async {
    if (!await _isContactOtpNotification(message)) return false;
    await PushNotificationService.showContactOtp(message);
    return true;
  }

  Future<void> _openTrackedAlert(
    Map<String, dynamic> notificationData, {
    required bool isHelping,
  }) async {
    final alertId = notificationData["id"];
    if (!await AlertState.begin(alertId)) return;

    bool acknowledged = false;
    try {
      acknowledged =
          await Get.to<bool>(
            () => FullScreenAlert(
              notificationData: notificationData,
              isHelping: isHelping,
            ),
          ) ??
          false;
    } finally {
      await AlertState.end(alertId, actioned: acknowledged);
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
    await PushNotificationService.initializeLocalNotifications();
    await ApiService.clearRestoredSessionIfNeeded();

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Received foreground FCM message: ${message.data}');
      if (await _showContactOtpNotification(message)) return;
      await _showOwnerReportAlert(message);
    });

    // Handle background / terminated messages (optional but good for debugging)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('App opened from FCM message: ${message.data}');
      if (message.data['type']?.toString().toUpperCase() == 'CONTACT_OTP') {
        return;
      }
      await _showOwnerReportAlert(message);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (initialMessage.data['type']?.toString().toUpperCase() ==
            'CONTACT_OTP') {
          return;
        }
        await _showOwnerReportAlert(initialMessage);
      });
    }
  }
}

// Top level function for handling background messages (required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
