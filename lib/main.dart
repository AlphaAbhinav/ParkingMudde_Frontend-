import 'dart:async';

import 'package:flutter/material.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _initializeFirebase();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => WalletProvider(),
      child: const MyApp(),
    ),
  );

  unawaited(_initializeStartupServices());
}

Future<void> _initializeStartupServices() async {
  try {
    await _initializeFirebase();
    await FirebaseApi().initNotifications();
    await AlertSoundPlayer.instance.prime();
    await VisitorSoundPlayer.instance.prime();
  } catch (error) {
    debugPrint('Startup services failed: $error');
  }
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parkingमुद्दे®',
      home: const Splashpage(),
    );
  }
}
