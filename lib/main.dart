import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/splash/splashpage.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parkingmudde/services/alert_sound_player.dart';
import 'package:parkingmudde/services/firebase_api.dart';
import 'package:parkingmudde/services/visitor_sound_player.dart';
import 'firebase_options.dart';
import 'services/ios_call_service.dart';
import 'screen/calls/call_launch_screen.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  PushNotificationService.bindNativeAlertHandler(
    FirebaseApi().handleOpenedAlert,
  );
  Map<String, dynamic>? launchCall;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      const channel = MethodChannel('com.parkingmudde.app/urgent_overlay');
      await channel.invokeMethod<void>('configureCallBackend', {
        'url': ApiService.baseUrl,
      });
      launchCall = await channel.invokeMapMethod<String, dynamic>(
        'getLaunchCall',
      );
    } on PlatformException catch (error) {
      debugPrint('Call launch lookup failed: ${error.code}');
    } on MissingPluginException {
      // Desktop tests and installations awaiting a native rebuild.
    }
  }
  if (launchCall != null) FirebaseApi.claimLaunchCall(launchCall);

  runApp(
    ChangeNotifierProvider(
      create: (_) => WalletProvider(),
      child: MyApp(
        launchCall: launchCall,
        onCallFinished: () => unawaited(_initializeStartupServices()),
      ),
    ),
  );

  // Install native call callbacks independently of push-token/network startup.
  unawaited(IosCallService.instance.initialize());
  if (launchCall == null) unawaited(_initializeStartupServices());
}

Future<void> _initializeStartupServices() async {
  try {
    await _initializeFirebase();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseApi().initNotifications();
    await AlertSoundPlayer.instance.prime();
    await VisitorSoundPlayer.instance.prime();
  } catch (error) {
    debugPrint('Startup services failed: $error');
  }
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.launchCall, this.onCallFinished});
  final Map<String, dynamic>? launchCall;
  final VoidCallback? onCallFinished;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parkingमुद्दे®',
      home: launchCall == null
          ? const Splashpage()
          : CallLaunchScreen(callData: launchCall!, onFinished: onCallFinished),
    );
  }
}
