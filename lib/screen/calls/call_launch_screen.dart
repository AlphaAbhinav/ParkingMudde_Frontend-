import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/screen/splash/splashpage.dart';
import 'incoming_call_screen.dart';

/// A separate navigator keeps normal app startup out of a cold-start call.
/// Splash is created only after the ringing/active call route has closed.
class CallLaunchScreen extends StatefulWidget {
  const CallLaunchScreen({super.key, required this.callData, this.onFinished});
  final Map<String, dynamic> callData;
  final VoidCallback? onFinished;

  @override
  State<CallLaunchScreen> createState() => _CallLaunchScreenState();
}

class _CallLaunchScreenState extends State<CallLaunchScreen> {
  bool? _signedIn;
  bool _finished = false;
  bool _notified = false;

  void _notifyFinished() {
    if (_notified) return;
    _notified = true;
    widget.onFinished?.call();
  }

  late final NavigatorObserver _observer = _CallReturnObserver(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _finished = true);
        _notifyFinished();
      }
    });
  });

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final signedIn =
        prefs.getString('user_id')?.isNotEmpty == true &&
        prefs.getBool('is_logging_out') != true;
    if (mounted) {
      setState(() => _signedIn = signedIn);
      if (!signedIn) _notifyFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished || _signedIn == false) return const Splashpage();
    if (_signedIn == null) {
      return const Scaffold(backgroundColor: Color(0xFF081A2E));
    }
    return Navigator(
      observers: [_observer],
      onGenerateInitialRoutes: (_, __) => [
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/call-return'),
          builder: (_) => const Scaffold(backgroundColor: Color(0xFF081A2E)),
        ),
        MaterialPageRoute<bool>(
          builder: (_) => IncomingCallScreen(
            callData: widget.callData,
            initialAction: widget.callData['call_action']?.toString(),
          ),
        ),
      ],
      onGenerateRoute: (_) => null,
    );
  }
}

class _CallReturnObserver extends NavigatorObserver {
  _CallReturnObserver(this.onFinished);
  final VoidCallback onFinished;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.settings.name == '/call-return') onFinished();
  }
}
