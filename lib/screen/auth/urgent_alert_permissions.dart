import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

const _alertChannel = MethodChannel('com.parkingmudde.app/urgent_overlay');
const _blue = Color(0xFF02399F);

enum _UrgentAlertPermission {
  fullScreen(
    'Allow full-screen alerts?',
    'Turn on full-screen notifications so incoming calls and urgent vehicle alerts can appear on your lock screen.',
    'canUseFullScreenIntent',
  ),
  overlay(
    'Allow alerts over other apps?',
    'Turn on “Display over other apps” so urgent vehicle alerts and incoming calls are visible while you use another app.',
    'canDrawOverlays',
  );

  const _UrgentAlertPermission(this.title, this.description, this.statusMethod);

  final String title;
  final String description;
  final String statusMethod;

  Future<bool> get needsPermission async {
    try {
      return await _alertChannel.invokeMethod<bool>(statusMethod) == false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      debugPrint('Could not check urgent alert permission: ${error.code}');
      return false;
    }
  }

  Future<bool?> request() async {
    try {
      switch (this) {
        case _UrgentAlertPermission.fullScreen:
          final notifications = FlutterLocalNotificationsPlugin()
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          return await notifications?.requestFullScreenIntentPermission();
        case _UrgentAlertPermission.overlay:
          return (await Permission.systemAlertWindow.request()).isGranted;
      }
    } on PlatformException catch (error) {
      debugPrint('Could not open urgent alert settings: $error');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

Future<void> requestAndroidStartupPermissions(BuildContext context) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  for (final permission in _UrgentAlertPermission.values) {
    final needsPermission = await permission.needsPermission;
    if (!context.mounted) return;
    if (!needsPermission) continue;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined, color: _blue),
        title: Text(permission.title),
        content: Text(permission.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Deny'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _blue),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    final granted = allow == true ? await permission.request() : false;
    if (!context.mounted) return;
    if (granted == true) continue;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _UrgentAlertPermissionPage(
          permission: permission,
          settingsError: granted == null,
        ),
      ),
    );
    if (!context.mounted) return;
  }

  try {
    await Permission.notification.request();
  } on MissingPluginException {
    // The test host has no Android permission handler.
  } on PlatformException catch (error) {
    debugPrint('Could not request notification permission: $error');
  }
}

class _UrgentAlertPermissionPage extends StatefulWidget {
  const _UrgentAlertPermissionPage({
    required this.permission,
    required this.settingsError,
  });

  final _UrgentAlertPermission permission;
  final bool settingsError;

  @override
  State<_UrgentAlertPermissionPage> createState() =>
      _UrgentAlertPermissionPageState();
}

class _UrgentAlertPermissionPageState
    extends State<_UrgentAlertPermissionPage> {
  bool _openingSettings = false;
  late bool _settingsError = widget.settingsError;

  Future<void> _allow() async {
    if (_openingSettings) return;
    setState(() {
      _openingSettings = true;
      _settingsError = false;
    });

    final granted = await widget.permission.request();
    if (!mounted) return;
    if (granted == true) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _openingSettings = false;
      _settingsError = granted == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFEAF0FF),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: _blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Urgent alerts need this permission',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.permission.description,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_settingsError) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Could not open Settings. Tap Allow to try again.',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _openingSettings ? null : _allow,
                        child: Text(
                          _openingSettings ? 'Opening Settings…' : 'Allow',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
