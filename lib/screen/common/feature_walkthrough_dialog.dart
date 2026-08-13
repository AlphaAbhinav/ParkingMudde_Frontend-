import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// A polished, deeply spatial decelerating curve used across all animations
/// for perfectly smooth non-spring motions typical of premium editorial UI.
const Curve _kSpatialCurve = Cubic(0.2, 0.85, 0.15, 1);

class FeatureWalkthroughDialog extends StatefulWidget {
  const FeatureWalkthroughDialog({super.key});

  @override
  State<FeatureWalkthroughDialog> createState() =>
      _FeatureWalkthroughDialogState();
}

class _FeatureWalkthroughDialogState extends State<FeatureWalkthroughDialog>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _breatheController;

  int _currentIndex = 0;

  // We meticulously adjusted these to reflect variations of Brand Blue
  // and vibrant Brand Yellow/Amber so it doesn't wash out on a white background.
  final List<_GuideFeature> _features = const [
    _GuideFeature(
      icon: Icons.garage_rounded,
      title: "My Vehicles",
      desc: "Keep your vehicle details and documents in one place.",
      points: [
        "Add your vehicle number, RC, licence, and other documents.",
        "The app reminds you before a saved document expires.",
        "Other users cannot see your phone number.",
      ],
      color: Color(0xFF1E3A8A), // Very Deep Trust Blue
    ),
    _GuideFeature(
      icon: Icons.camera_alt_rounded,
      title: "Report Issues",
      desc: "Report a wrongly parked vehicle using a clear photo.",
      points: [
        "Choose the problem and take a clear photo.",
        "The app checks the photo before sending the report.",
        "Only send a report when you have correct proof.",
      ],
      color: Color(0xFFF59E0B), // Vibrant Warning Gold/Yellow
    ),
    _GuideFeature(
      icon: Icons.volunteer_activism_rounded,
      title: "Help a Vehicle",
      desc: "Tell an owner about a problem without sharing your identity.",
      points: [
        "You can report lights left on or another vehicle problem.",
        "The owner gets an alert, but your identity stays private.",
        "You can earn coins for a valid helping report.",
      ],
      color: Color(0xFF0284C7), // Bright Ocean Blue
    ),
    _GuideFeature(
      icon: Icons.sos_rounded,
      title: "Emergency Alert",
      desc: "Send an urgent alert when someone needs immediate help.",
      points: [
        "Take a clear photo and explain the emergency.",
        "The vehicle owner and saved emergency contacts may be alerted.",
        "Call emergency services directly if there is immediate danger.",
      ],
      color: Color(0xFFD97706), // Emergency Rich Amber
    ),
    _GuideFeature(
      icon: Icons.local_parking_rounded,
      title: "Nearby Parking",
      desc: "Find parking places near your current location.",
      points: [
        "Tap a parking place to see its details.",
        "Check the price and available spaces before going there.",
        "You can also see your previous bookings.",
      ],
      color: Color(0xFF2563EB), // Signature Core Brand Blue
    ),
    _GuideFeature(
      icon: Icons.account_balance_wallet_rounded,
      title: "Wallet and Coins",
      desc: "Earn coins for useful actions and use them inside the app.",
      points: [
        "Valid reports and helpful actions can give you coins.",
        "Use your coins for coupons and available app services.",
        "Your wallet shows every coin earned and spent.",
      ],
      color: Color(0xFFEAB308), // Signature Core Yellow
    ),
    _GuideFeature(
      icon: Icons.description_rounded,
      title: "Document Reminders",
      desc: "Save important dates for each of your vehicles.",
      points: [
        "Add insurance and pollution-certificate expiry dates.",
        "Check all saved vehicle details from My Vehicles.",
        "Update the information whenever it changes.",
      ],
      color: Color(0xFF0F172A), // Almost Black/Navy Contrast Accent
    ),
    _GuideFeature(
      icon: Icons.security_rounded,
      title: "Your Privacy",
      desc: "The app protects your personal contact details.",
      points: [
        "Other users do not receive your personal phone number.",
        "Use in-app alerts instead of arguing with a vehicle owner.",
        "Never share OTPs, passwords, or private details with anyone.",
      ],
      color: Color(0xFF3B82F6), // Software Azure Blue
    ),
    _GuideFeature(
      icon: Icons.storefront_rounded,
      title: "Coupon Store",
      desc: "Use your coins to unlock available discount coupons.",
      points: [
        "Read the coupon details before buying it.",
        "After purchase, scratch the card to reveal the coupon code.",
        "Check the description and expiry details before using it.",
      ],
      color: Color(0xFF4F46E5), // Indigo Accent Blue
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  bool get _isLastSlide => _currentIndex == _features.length - 1;

  void _next() {
    if (_currentIndex < _features.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: _kSpatialCurve,
      );
    } else {
      HapticFeedback.heavyImpact();
      Get.back();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: _kSpatialCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = math.min(520.0, screenSize.width - 24);
    final heightBounds = screenSize.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: heightBounds.clamp(600.0, 780.0),
        ),
        decoration: BoxDecoration(
          color: Colors.white, // Crisp, ultra-clean white
          borderRadius: BorderRadius.circular(42),
          border: Border.all(
            color: Colors.black.withOpacity(0.04), // Thin spatial separator
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), // High end subtle drop
              blurRadius: 50,
              spreadRadius: -4,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            _buildLightAuroraBgd(), // New subtle color injection backdrop
            Column(
              children: [
                _buildHeaderTopRail(),
                Expanded(child: _buildSeamlessPageCanvas()),
                _buildNavigationDock(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightAuroraBgd() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _breatheController]),
        builder: (context, _) {
          final double rawPage = _controller.hasClients
              ? (_controller.page ?? _currentIndex.toDouble())
              : _currentIndex.toDouble();

          final int indexLeft = rawPage.floor().clamp(0, _features.length - 1);
          final int indexRight = (indexLeft + 1).clamp(0, _features.length - 1);
          final double t = rawPage - indexLeft;

          final Color ambientColor = Color.lerp(
            _features[indexLeft].color,
            _features[indexRight].color,
            t,
          )!;

          final breath = Curves.easeInOutSine.transform(
            _breatheController.value,
          );

          return Stack(
            children: [
              // White foundational surface
              Container(color: const Color(0xFFFAFBFC)),

              // Top ambient pastel wash (Light, high diffusion to just cast a 'hint' of brand tint)
              Positioned(
                top: -80 - (20 * breath),
                right: -120 + (40 * breath),
                child: IgnorePointer(
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ambientColor.withOpacity(
                            0.09,
                          ), // Highly diffuse light theme aesthetic
                          ambientColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom subtle supporting accent wash
              Positioned(
                bottom: -150 + (30 * breath),
                left: -150 - (20 * breath),
                child: IgnorePointer(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ambientColor.withOpacity(0.06),
                          ambientColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderTopRail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 26, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clean light-mode specific overview badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ), // slate-200 line
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_rounded,
                  size: 14,
                  color: Color(0xFF64748B), // Slate 500
                ),
                const SizedBox(width: 8),
                Text(
                  "OVERVIEW",
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // slate-100 pill
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withOpacity(0.03)),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeamlessPageCanvas() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 250) {
          _prev();
        } else if (details.primaryVelocity! < -250) {
          _next();
        }
      },
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (ix) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = ix);
        },
        itemCount: _features.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (ctx, child) {
              final rawOffset = (_controller.page ?? _currentIndex) - index;
              final isDraggingActive = rawOffset != 0.0;

              final double pageOpacity = (1.0 - (0.75 * rawOffset.abs())).clamp(
                0.0,
                1.0,
              );
              final double pageScale = (1.0 - (0.045 * rawOffset.abs())).clamp(
                0.92,
                1.0,
              );
              final double panY = rawOffset.abs() * 25;

              if (isDraggingActive && pageOpacity == 0) return const SizedBox();

              return Opacity(
                opacity: pageOpacity,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, panY)
                    ..scale(pageScale),
                  child: _buildRefinedSlideLayer(_features[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRefinedSlideLayer(_GuideFeature feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 24, bottom: 20),
        children: [
          // Core iconography wrapper styled for a clean canvas backdrop
          Container(
            height: 72,
            width: 72,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    feature.color,
                    feature.color.withBlue(
                      (feature.color.blue + 30).clamp(0, 255),
                    ), // Auto gentle gradient shift
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(feature.icon, size: 30, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // The clean space typographic layer with Deep Indigo/Slate color grades.
          Text(
            feature.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A), // Midnight Ink / Slate 900
              letterSpacing: -1,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            feature.desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569), // Readable Lead Gray
              height: 1.5,
            ),
          ),

          const SizedBox(height: 42),

          // Professional tracking architecture
          ...List.generate(feature.points.length, (idx) {
            final point = feature.points[idx];
            final isEnd = idx == feature.points.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 4),
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: feature.color, width: 3.5),
                          color: Colors.white,
                        ),
                      ),
                      if (!isEnd)
                        Expanded(
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE2E8F0,
                              ), // Clean muted divider gray
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Text(
                        point,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(
                            0xFF1E293B,
                          ), // Core readability gray
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationDock() {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(28, 16, 28, 26 + bottomSafe),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final activeColor = _features[_currentIndex].color;

          // To ensure White text stands out on Yellow elements safely,
          // or simply just applying universal high contrast bounds rules:
          final bool isButtonLightTint =
              activeColor == const Color(0xFFEAB308) || // Yellow
              activeColor == const Color(0xFFF59E0B); // Amber
          final Color iconTextClr = isButtonLightTint
              ? const Color(0xFF060500)
              : Colors.white;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Minimal Back Toggle
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _currentIndex > 0 ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: _currentIndex > 0 ? _prev : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_backspace_rounded,
                      color: Color(0xFF475569), // Neutral Icon Dark
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Fluid Light-mode Indicator Tracking Strip Layer
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_features.length, (idx) {
                    bool isActive = idx == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.fastLinearToSlowEaseIn,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isActive ? 24 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor
                            : const Color(
                                0xFFCBD5E1,
                              ), // Cool soft inactive tracking blue/gray
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(
                                    0.25,
                                  ), // soft bloom on the bar itself
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
              ),

              // Deep Rich Action Terminal Layer
              GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: _kSpatialCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(
                          0.3,
                        ), // Vivid cast matching button action scheme
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _isLastSlide ? "Get Started" : "Continue",
                      key: ValueKey(_isLastSlide),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: 0.3,
                        color:
                            iconTextClr, // auto adjusts if yellow creates readability fail logic layer mapping above
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideFeature {
  final IconData icon;
  final String title;
  final String desc;
  final List<String> points;
  final Color color;

  const _GuideFeature({
    required this.icon,
    required this.title,
    required this.desc,
    required this.points,
    required this.color,
  });
}
