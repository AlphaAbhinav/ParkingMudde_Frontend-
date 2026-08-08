import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/vehicle/vehicledetail.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/widgets/dynamic_ad_carousel.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class MyVehiclesScreen extends StatefulWidget {
  final bool isFromBottomNav;
  final VoidCallback? onBackPressed;
  const MyVehiclesScreen({
    super.key,
    this.isFromBottomNav = false,
    this.onBackPressed,
  });

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  // ─── STRICT GLOBAL DESIGN TOKENS ───
  static const Color brandBlue = Color(0XFF184B8C);
  static const Color brandBlueLight = Color(0xFFEFF6FF); // Soft blue background
  static const Color textDark = Color(0xFF1E293B); // Primary text
  static const Color textGrey = Color(0xFF64748B); // Secondary text
  static const Color bgSurface = Color(0xFFF8FAFC); // Page background
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenBg = Color(0xFFDCFCE7);
  static const Color indBlue = Color(0xFF1D4ED8); // For IND license plate badge

  List<dynamic> vehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final user = await ApiService.getStoredUser();
      final storedUserId = user?["user_id"]?.toString();

      if (storedUserId == null || storedUserId.isEmpty) {
        setState(() {
          vehicles = [];
          isLoading = false;
        });
        return;
      }

      final fetchedVehicles = await ApiService.getMyVehicles(storedUserId);

      setState(() {
        vehicles = fetchedVehicles;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading vehicles: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textDark,
              size: 20,
            ),
            onPressed: () {
              if (widget.isFromBottomNav && widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else {
                Get.back();
              }
            },
          ),
        ),
        title: const Text(
          "My Vehicles",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700, // Reduced from w800
            color: textDark,
            letterSpacing: 0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1.5,
          ), // Standardized border color
        ),
      ),

      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Get.to(
                  () => const AddVehicleScreen(fromMyVehicles: true),
                );
                loadVehicles();
              },
              backgroundColor: brandBlue,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Add Vehicle",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600, // Reduced from w700
                  fontSize: 14,
                ),
              ),
            ),
      body: isLoading
          ? _buildLoadingSkeleton() // Replaced CircularProgressIndicator with Premium Skeleton
          : vehicles.isEmpty
          ? _emptyStateView()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // Added bottom padding (100) to prevent FAB overlap
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Ad Banner Carousel
                  const DynamicAdCarousel(pageName: 'My Vehicles'),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Registered Vehicles",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700, // Reduced from w800
                          color: textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: brandBlueLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${vehicles.length} Total",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, // Reduced from w800
                            fontSize: 12,
                            color: brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final result = await Get.to(
                              () => VehicleDetailPage(vehicle: vehicle),
                            );
                            if (result == true) {
                              await loadVehicles();
                              Get.snackbar(
                                "Vehicle Updated",
                                "Vehicle records have been successfully saved.",
                                backgroundColor: successGreen,
                                colorText: Colors.white,
                              );
                            } else if (result == "deleted") {
                              await loadVehicles();
                            }
                          },
                          child: _vehicleCard(context, vehicle),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const ScreenSlogan(
                    "Everything about your vehicles, right here.",
                    color: brandBlue,
                    icon: Icons.auto_awesome_rounded,
                    imagePath: 'assets/myvehicleslogan.png',
                    normalImageWidth: 105,
                    compactImageWidth: 92,
                    textMaxLines: 2,
                  ),
                ],
              ),
            ),
    );
  }

  /// Premium Skeleton Loader (Replaces standard generic spinner)
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PulsingSkeleton(
            width: double.infinity,
            height: 160,
            borderRadius: 20,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _PulsingSkeleton(width: 160, height: 24, borderRadius: 6),
              const _PulsingSkeleton(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, __) => const _PulsingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty Premium State Handling
  Widget _emptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/carsvg.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "No Vehicles Registered",
              style: TextStyle(
                fontSize: 20, // Tuned for balance
                fontWeight: FontWeight.w700, // Reduced from w800
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your account is clear. Securely register your vehicles to start generating safety parameters and transfer requests.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),
            const ScreenSlogan(
              "Everything about your vehicles, right here.",
              color: brandBlue,
              icon: Icons.auto_awesome_rounded,
              imagePath: 'assets/myvehicleslogan.png',
              normalImageWidth: 105,
              compactImageWidth: 92,
              textMaxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleImagePath(String type) {
    if (type.contains('bike') || type.contains('two')) {
      return 'assets/bikesvg.png';
    } else if (type.contains('scooter')) {
      return 'assets/scootersvg.png';
    } else if (type.contains('commercial')) {
      return 'assets/commercialsvg.png';
    } else {
      return 'assets/carsvg.png';
    }
  }

  Widget _vehicleCard(BuildContext context, dynamic vehicle) {
    String fullName =
        "${vehicle['owner_first_name']} ${vehicle['owner_last_name']}";
    String vehicleType =
        vehicle['vehicle_type']?.toString().toLowerCase() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Adopted minimal flat-card elevation UI (Removed borders, kept clean soft shadow)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Dynamic Vector-Like Icon Placeholder (Replaces static car photo)
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Transform.scale(
                scaleY: 1.2,
                child: Image.asset(
                  _getVehicleImagePath(vehicleType),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// Core Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniLicensePlateView(vehicle['registration_number']),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: textGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 15, // Bumped up for legibility
                          fontWeight: FontWeight.w700, // Reduced from w800
                          color: textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.phone_iphone_rounded,
                      size: 14,
                      color: textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vehicle['registered_mobile'] ?? 'Not Specified',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 14, // Bumped up
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    _chip(vehicle['vehicle_type'] ?? 'Unknown Type'),
                    const SizedBox(width: 8),
                    _statusChip('verified'),
                  ],
                ),
              ],
            ),
          ),

          /// Action Icon trigger (Enlarged hit target padding)
          InkWell(
            onTap: () => _vehicleActions(context, vehicle),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(
                12,
              ), // Enlarged hit target from (4, 8) to 12
              child: const Icon(Icons.more_vert_rounded, color: textGrey),
            ),
          ),
        ],
      ),
    );
  }

  /// Visually Spaces Registration Number (DL8CAA1111 -> DL 8C AA 1111)
  String _formatLicensePlate(String? regNumber) {
    if (regNumber == null || regNumber.isEmpty) return 'NO-REG-NUM';
    String clean = regNumber.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    // Pattern Matcher for standard Indian Plates: XX 00 XX 0000
    RegExp exp = RegExp(r'^([A-Z]{2})(\d{1,2})([A-Z]{1,3})(\d{4})$');
    if (exp.hasMatch(clean)) {
      final match = exp.firstMatch(clean)!;
      return "${match.group(1)} ${match.group(2)} ${match.group(3)} ${match.group(4)}";
    }
    return clean; // Fallback to whatever user entered if non-standard
  }

  Widget _miniLicensePlateView(String? regNumber) {
    final formattedReg = _formatLicensePlate(regNumber);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 180,
      ), // Allowed a bit more width for spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: const BoxDecoration(
              color: indBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              "IND",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                formattedReg,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700, // Reduced from w800
                  fontSize: 14, // Bumped up for legibility
                  color: textDark,
                  letterSpacing:
                      1.0, // Tweaked letter spacing since we added physical spaces
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Same standard palette
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.commute_rounded, size: 12, color: textGrey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700, // Reduced from w800
              color: textGrey,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: successGreenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: successGreen),
          const SizedBox(width: 4),
          const Text(
            "Verified Active",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700, // Reduced from w800
              color: successGreen,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _vehicleActions(BuildContext context, dynamic vehicle) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(
          _formatLicensePlate(vehicle['registration_number']),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        message: const Text(
          "Choose an action to manage this specific vehicle entry.",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_document,
                  color: brandBlue, // Standardized to our brand
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  "Update Registration Data",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: brandBlue, // Standardized to our brand
                  ),
                ),
              ],
            ),
            onPressed: () async {
              Navigator.pop(context);
              final updated = await Get.to(
                () => AddVehicleScreen(edit: vehicle, fromMyVehicles: true),
              );
              if (updated == true) {
                await loadVehicles();
                Get.snackbar(
                  "Information Updated",
                  "Vehicle database sync completed successfully.",
                  backgroundColor: successGreen,
                  colorText: Colors.white,
                );
              }
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text(
            "Cancel",
            style: TextStyle(fontWeight: FontWeight.w600, color: textDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Original hard-coded banner method perfectly retained, with slightly gentler font weights.
  Widget _buildAdBanner() {
    final List<Map<String, dynamic>> ads = [
      {
        "title": "Register Your Parking Space",
        "desc": "List your empty space & earn passive income",
        "gradient": [const Color(0xFF0F2027), const Color(0xFF2C5364)],
        "icon": Icons.local_parking_rounded,
        "cta": "Coming Soon",
      },
      {
        "title": "Premium Shield Plan",
        "desc": "Get towing protection + priority alerts",
        "gradient": [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
        "icon": Icons.shield_rounded,
        "cta": "Explore",
      },
      {
        "title": "Refer & Earn PM Coins",
        "desc": "Invite friends to ParkingMudde",
        "gradient": [const Color(0xFFFF512F), const Color(0xFFDD2476)],
        "icon": Icons.card_giftcard_rounded,
        "cta": "Share Now",
      },
      {
        "title": "FASTag Integration",
        "desc": "Seamless toll payments from your wallet",
        "gradient": [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        "icon": Icons.nfc_rounded,
        "cta": "Coming Soon",
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          final gradientColors = ad["gradient"] as List<Color>;
          return Container(
            width: 260,
            margin: EdgeInsets.only(right: index < ads.length - 1 ? 14 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (ad["cta"] == "Coming Soon") {
                    Get.snackbar(
                      "Coming Soon",
                      "${ad['title']} will be available soon!",
                      backgroundColor: textDark,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ad["title"] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700, // Adjusted weight
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ad["desc"] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                ad["cta"] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ad["icon"] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── MINIMAL ANIMATED SKELETON HELPER ───
class _PulsingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _PulsingSkeleton({
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<_PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<_PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
