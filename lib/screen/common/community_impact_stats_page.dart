import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/auth/permissionspage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityImpactStatsPage extends StatefulWidget {
  final bool requireVehicleOnSuccess;
  final bool hasSeenPermissions;

  const CommunityImpactStatsPage({
    super.key,
    required this.requireVehicleOnSuccess,
    required this.hasSeenPermissions,
  });

  @override
  State<CommunityImpactStatsPage> createState() =>
      _CommunityImpactStatsPageState();
}

class _CommunityImpactStatsPageState extends State<CommunityImpactStatsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isLoading = true;
  bool _statsUnavailable = false;
  bool _canContinue = false;

  Map<String, int> _stats = const {
    "users": 0,
    "vehicles": 0,
    "vehicles_reported": 0,
    "vehicles_helped": 0,
    "emergencies_solved": 0,
  };

  static const Color _background = Color(0xFFF7FAFF);
  static const Color _ink = Color(0xFF172033);
  static const Color _brandBlue = Color(0xFF2A5EE8);
  static const Color _mint = Color(0xFF0F9F7A);
  static const Color _sun = Color(0xFFF4A000);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _coral = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _canContinue = true);
          HapticFeedback.lightImpact();
        }
      });
    _loadStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await ApiService.getCommunityImpactStats();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _statsUnavailable = stats.isEmpty;
      if (stats.isNotEmpty) {
        _stats = {
          "users": stats["users"] ?? 0,
          "vehicles": stats["vehicles"] ?? 0,
          "vehicles_reported": stats["vehicles_reported"] ?? 0,
          "vehicles_helped": stats["vehicles_helped"] ?? 0,
          "emergencies_solved": stats["emergencies_solved"] ?? 0,
        };
      }
    });

    await _controller.forward(from: 0);
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_community_impact_page', true);

    if (!mounted) return;
    if (!widget.hasSeenPermissions) {
      Get.offAll(
        () => PermissionsPage(
          requireVehicleOnSuccess: widget.requireVehicleOnSuccess,
        ),
        transition: Transition.rightToLeftWithFade,
      );
      return;
    }

    Get.offAll(
      () => widget.requireVehicleOnSuccess
          ? const AddVehicleScreen(fromRegistration: true)
          : const Dash(),
      transition: Transition.rightToLeftWithFade,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final width = constraints.maxWidth;
              final scale = (height / 760).clamp(0.74, 1.0).toDouble();
              final horizontal = width < 360 ? 16.0 : 22.0;
              final vertical = height < 650 ? 10.0 : 18.0;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: vertical,
                ),
                child: _isLoading
                    ? _buildLoading(scale)
                    : _buildContent(scale),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(double scale) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 42 * scale,
            width: 42 * scale,
            child: const CircularProgressIndicator(
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              color: _brandBlue,
            ),
          ),
          SizedBox(height: 18 * scale),
          Text(
            "Waking up the network",
            style: TextStyle(
              color: _ink,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double scale) {
    final metrics = [
      _ImpactMetric(
        keyName: "users",
        label: "Total Users",
        icon: Icons.groups_rounded,
        accent: _mint,
      ),
      _ImpactMetric(
        keyName: "vehicles",
        label: "Total Vehicles",
        icon: Icons.directions_car_filled_rounded,
        accent: _brandBlue,
      ),
      _ImpactMetric(
        keyName: "vehicles_reported",
        label: "Vehicles Reported",
        icon: Icons.report_rounded,
        accent: _violet,
      ),
      _ImpactMetric(
        keyName: "vehicles_helped",
        label: "Vehicles Helped",
        icon: Icons.volunteer_activism_rounded,
        accent: _sun,
      ),
      _ImpactMetric(
        keyName: "emergencies_solved",
        label: "Emergencies Solved",
        icon: Icons.health_and_safety_rounded,
        accent: _coral,
      ),
    ];

    final footerHeight = 58 * scale;
    final gap = 8 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(scale),
        SizedBox(height: 14 * scale),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: _buildMetricRow(metrics[i], i, scale)),
                if (i != metrics.length - 1) SizedBox(height: gap),
              ],
            ],
          ),
        ),
        if (_statsUnavailable) ...[
          SizedBox(height: 8 * scale),
          _buildOfflineNote(scale),
        ],
        SizedBox(height: 12 * scale),
        SizedBox(height: footerHeight, child: _buildActionButton(scale)),
      ],
    );
  }

  Widget _buildHeader(double scale) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(
          (_controller.value / 0.24).clamp(0.0, 1.0).toDouble(),
        );
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 7 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              "COMMUNITY SNAPSHOT",
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w900,
                fontSize: 11 * scale,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            "Impact So Far",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 30 * scale,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            "A quick look at the ParkingMudde network.",
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(_ImpactMetric metric, int index, double scale) {
    final start = 0.10 + (index * 0.11);
    final end = math.min(1.0, start + 0.28);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOutBack.transform(
          ((_controller.value - start) / (end - start))
              .clamp(0.0, 1.0)
              .toDouble(),
        );
        final reveal = value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: reveal,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Transform.scale(
              scale: 0.97 + (0.03 * reveal),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 10 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: metric.accent.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44 * scale,
              height: 44 * scale,
              decoration: BoxDecoration(
                color: metric.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                metric.icon,
                color: metric.accent,
                size: 23 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(width: 10 * scale),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (_stats[metric.keyName] ?? 0).toDouble(),
              ),
              duration: Duration(milliseconds: 850 + (index * 120)),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  _formatCount(value.floor()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: metric.accent,
                    fontSize: 25 * scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineNote(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Text(
        "Live numbers are loading slowly. You can continue normally.",
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(
          color: const Color(0xFFC2410C),
          fontSize: 12 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildActionButton(double scale) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(
          ((_controller.value - 0.78) / 0.22).clamp(0.0, 1.0).toDouble(),
        );
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _canContinue ? _brandBlue : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _canContinue
              ? [
                  BoxShadow(
                    color: _brandBlue.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _canContinue ? _finish : null,
            child: Center(
              child: Text(
                "Start Engine",
                style: TextStyle(
                  color: _canContinue ? Colors.white : const Color(0xFF64748B),
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }
}

class _ImpactMetric {
  final String keyName;
  final String label;
  final IconData icon;
  final Color accent;

  const _ImpactMetric({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.accent,
  });
}
