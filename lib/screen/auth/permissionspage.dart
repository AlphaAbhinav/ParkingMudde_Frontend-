import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';

class PermissionsPage extends StatefulWidget {
  final bool requireVehicleOnSuccess;
  
  const PermissionsPage({
    super.key,
    this.requireVehicleOnSuccess = false,
  });

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with TickerProviderStateMixin {
  static const Color themeBlue = Color(0xFF02399F);

  bool _isRequesting = false;

  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      permission: Permission.camera,
      icon: Icons.camera_alt_rounded,
      title: "Camera",
      description:
          "To scan vehicle number plates and capture parking proof photos.",
      color: const Color(0xFF2A5EE8),
    ),
    _PermissionItem(
      permission: Permission.location,
      icon: Icons.location_on_rounded,
      title: "Location",
      description:
          "To find nearby parking, report locations accurately and alert nearby hospitals.",
      color: const Color(0xFF20C475),
    ),
    _PermissionItem(
      permission: Permission.photos,
      icon: Icons.photo_library_rounded,
      title: "Photos & Media",
      description:
          "To upload parking proof images and manage your documents.",
      color: const Color(0xFFFF6B35),
    ),
    _PermissionItem(
      permission: Permission.notification,
      icon: Icons.notifications_active_rounded,
      title: "Notifications",
      description:
          "To receive alerts when someone reports your vehicle or when your documents are expiring.",
      color: const Color(0xFF9B59B6),
    ),
  ];

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _permissions.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _fadeAnims = _controllers
        .map(
          (c) => CurvedAnimation(parent: c, curve: Curves.easeOut),
        )
        .toList();

    // Stagger the card animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _requestAll() async {
    setState(() => _isRequesting = true);

    // Request all permissions one by one
    await Permission.camera.request();
    await Permission.location.request();
    await [Permission.photos, Permission.storage].request();
    await Permission.notification.request();

    if (!mounted) return;
    setState(() => _isRequesting = false);

    // Finish up and navigate to the home/vehicle screen
    await _completePermissions();
  }

  Future<void> _skipToNext() async {
    await _completePermissions();
  }

  Future<void> _completePermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("has_seen_permissions", true);

    if (widget.requireVehicleOnSuccess) {
      Get.offAll(() => const AddVehicleScreen(fromRegistration: true), transition: Transition.fadeIn);
    } else {
      Get.offAll(() => const Dash(), transition: Transition.fadeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: const BoxDecoration(
                color: themeBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "App Permissions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "ParkingMudde needs a few permissions to work properly. We only ask for what we truly need.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Permission Cards ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                itemCount: _permissions.length,
                itemBuilder: (context, i) {
                  final item = _permissions[i];
                  return FadeTransition(
                    opacity: _fadeAnims[i],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_fadeAnims[i]),
                      child: _PermissionCard(item: item),
                    ),
                  );
                },
              ),
            ),

            // ── Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Allow All & Continue",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isRequesting ? null : _skipToNext,
                    child: Text(
                      "Skip for now",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permission Card Widget ──
class _PermissionCard extends StatelessWidget {
  final _PermissionItem item;
  const _PermissionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _PermissionItem({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
