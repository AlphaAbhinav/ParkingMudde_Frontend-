import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'guard_api_service.dart';

class GuardApp extends StatelessWidget {
  const GuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking Officer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const GuardBootstrap(),
    );
  }
}

class GuardBootstrap extends StatefulWidget {
  const GuardBootstrap({super.key});

  @override
  State<GuardBootstrap> createState() => _GuardBootstrapState();
}

class _GuardBootstrapState extends State<GuardBootstrap> {
  bool _loading = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _signedIn = prefs.getString('guard_access_token') != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _signedIn
        ? const GuardHomePage()
        : GuardLoginPage(onSignedIn: () => setState(() => _signedIn = true));
  }
}

class GuardLoginPage extends StatefulWidget {
  const GuardLoginPage({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<GuardLoginPage> createState() => _GuardLoginPageState();
}

class _GuardLoginPageState extends State<GuardLoginPage> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await GuardApiService.login(
      mobileNumber: _mobile.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] == true) {
      widget.onSignedIn();
    } else {
      setState(() => _error = result['message'] ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.local_police_rounded, size: 72, color: Color(0xFF2563EB)),
            const SizedBox(height: 20),
            const Text('Parking Officer', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Verify vehicles and log gate activity', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 32),
            TextField(controller: _mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 14),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _loading ? null : _login,
              icon: _loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class GuardHomePage extends StatefulWidget {
  const GuardHomePage({super.key});

  @override
  State<GuardHomePage> createState() => _GuardHomePageState();
}

class _GuardHomePageState extends State<GuardHomePage> {
  final _vehicleNumber = TextEditingController();
  Map<String, dynamic>? _verification;
  Map<String, dynamic>? _performance;
  bool _loading = false;
  bool _shiftLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    final result = await GuardApiService.performance();
    if (mounted && result['success'] == true) {
      setState(() => _performance = result['data']);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await GuardApiService.verifyVehicle(_vehicleNumber.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _verification = result['data'];
      } else {
        _message = result['message'];
      }
    });
    _loadPerformance();
  }

  Future<void> _log(String direction) async {
    final visitorId = _verification?['visitor']?['id'];
    final result = await GuardApiService.logEntryExit(
      vehicleNumber: _vehicleNumber.text.trim(),
      direction: direction,
      visitorId: visitorId,
      notes: _verification?['message'],
    );
    if (!mounted) return;
    setState(() => _message = result['success'] == true ? '$direction logged' : result['message']);
    _loadPerformance();
  }

  Future<void> _shift(String direction) async {
    setState(() => _shiftLoading = true);
    final result = direction == 'IN'
        ? await GuardApiService.shiftCheckIn()
        : await GuardApiService.shiftCheckOut();
    if (!mounted) return;
    setState(() {
      _shiftLoading = false;
      _message = result['success'] == true ? 'Shift check-$direction logged' : result['message'];
    });
    _loadPerformance();
  }

  Future<void> _raiseAlert() async {
    final plate = _vehicleNumber.text.trim();
    final result = await GuardApiService.createAlert(
      title: plate.isEmpty ? 'Guard assistance requested' : 'Vehicle exception reported',
      body: plate.isEmpty ? 'Guard requested supervisor assistance from the gate.' : 'Guard reported an exception for $plate.',
      eventType: plate.isEmpty ? 'GUARD_ASSISTANCE' : 'VEHICLE_EXCEPTION',
      severity: 'HIGH',
      vehicleNumber: plate.isEmpty ? null : plate,
    );
    if (!mounted) return;
    setState(() => _message = result['success'] == true ? 'Alert sent to panel' : result['message']);
    _loadPerformance();
  }

  Color get _statusColor {
    final status = _verification?['status'];
    if (status == 'AUTHORIZED' || status == 'APPROVED') return Colors.green;
    if (status == 'PENDING') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final status = _verification?['status']?.toString() ?? 'READY';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Console'),
        actions: [
          IconButton(
            onPressed: () async {
              await GuardApiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GuardLoginPage(onSignedIn: () {})));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PerformanceStrip(data: _performance),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _shiftLoading ? null : () => _shift('IN'), icon: const Icon(Icons.play_circle), label: const Text('Shift In'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: _shiftLoading ? null : () => _shift('OUT'), icon: const Icon(Icons.stop_circle), label: const Text('Shift Out'))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vehicleNumber,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Vehicle number', prefixIcon: Icon(Icons.directions_car), hintText: 'MH01AB1234'),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _loading ? null : _verify, icon: const Icon(Icons.verified), label: const Text('Verify vehicle')),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _statusColor.withValues(alpha: 0.10), border: Border.all(color: _statusColor.withValues(alpha: 0.35))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _statusColor)),
                const SizedBox(height: 8),
                Text(_verification?['message']?.toString() ?? _message ?? 'Enter a number plate to verify against resident and visitor records.'),
                if (_verification?['resident'] != null) Text('Resident: ${_verification!['resident']['full_name']}'),
                if (_verification?['visitor'] != null) Text('Visitor: ${_verification!['visitor']['name']}'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: FilledButton.tonalIcon(onPressed: _vehicleNumber.text.trim().isEmpty ? null : () => _log('ENTRY'), icon: const Icon(Icons.login), label: const Text('Entry'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.tonalIcon(onPressed: _vehicleNumber.text.trim().isEmpty ? null : () => _log('EXIT'), icon: const Icon(Icons.logout), label: const Text('Exit'))),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: _raiseAlert,
            icon: const Icon(Icons.warning_rounded),
            label: const Text('Raise Alert'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceStrip extends StatelessWidget {
  const _PerformanceStrip({required this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(label: 'Scans', value: '${data?['verifications'] ?? 0}'),
        _Metric(label: 'Entries', value: '${data?['entries'] ?? 0}'),
        _Metric(label: 'Score', value: '${data?['accuracy_score'] ?? 0}%'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
