import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scratcher/scratcher.dart';
import 'package:get/get.dart';
import 'couponsstorepage.dart';

class ScratchRevealDialog extends StatefulWidget {
  final CouponModel coupon;

  const ScratchRevealDialog({super.key, required this.coupon});

  @override
  State<ScratchRevealDialog> createState() => _ScratchRevealDialogState();
}

class _ScratchRevealDialogState extends State<ScratchRevealDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScratcherState> scratchKey = GlobalKey<ScratcherState>();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool isFlipped = false;
  bool isRevealed = false;
  bool _sequenceTriggered = false;

  bool carIgnitionOn = false;
  Alignment pos1 = const Alignment(-0.62, -0.3);
  Alignment pos2 = const Alignment(0.0, -0.3);
  Alignment pos3 = const Alignment(0.62, -0.3);

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack),
    );

    _flipController.addListener(() {
      if (_flipController.value >= 0.5 && !isFlipped) {
        setState(() => isFlipped = true);
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onScratchUpdate(double progress) {
    if (progress > 1.0 && !_sequenceTriggered) {
      _sequenceTriggered = true;
      _triggerPerfectSequence();
    }
  }

  Future<void> _triggerPerfectSequence() async {
    if (!mounted) return;

    // Magically melt away the scratch layer
    scratchKey.currentState?.reveal(
      duration: const Duration(milliseconds: 250),
    );

    // Instantly illuminate reverse headlights
    setState(() {
      isRevealed = true;
      carIgnitionOn = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Right car backs out
    if (mounted) setState(() => pos3 = const Alignment(0.62, 3.5));
    await Future.delayed(const Duration(milliseconds: 300));

    // Center car backs out
    if (mounted) setState(() => pos2 = const Alignment(0.0, 3.5));
    await Future.delayed(const Duration(milliseconds: 300));

    // Left car backs out
    if (mounted) setState(() => pos1 = const Alignment(-0.62, 3.5));

    await Future.delayed(const Duration(milliseconds: 600));

    // Flip the card precisely after cars clear
    if (mounted) _flipController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final flipValue = _flipAnimation.value;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(flipValue * pi);

          if (flipValue >= 0.5) transform.rotateY(pi);

          final scale = 1.0 - 0.12 * sin(flipValue * pi);
          transform.scale(scale, scale, scale);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFlipped
                ? _buildProfessionalRewardCard()
                : _buildParkingFrontLayer(),
          );
        },
      ),
    );
  }

  // --- Front Parking Layout (Kept Exactly The Same!) ---
  Widget _buildParkingFrontLayer() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        children: [
          // Underlying Revealed Undercoat
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, size: 55, color: Color(0xFFFACC15)),
                  SizedBox(height: 16),
                  Text(
                    "REWARD PROCESSING",
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scratcher
          Positioned.fill(
            child: Scratcher(
              key: scratchKey,
              brushSize: 85,
              threshold: 95,
              color: const Color(0xFF334155),
              onChange: _onScratchUpdate,
              child: Container(color: Colors.transparent),
            ),
          ),

          if (_flipAnimation.value < 0.2)
            IgnorePointer(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Container(height: 80, color: Colors.transparent),
                        Container(
                          width: 310,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          width: 310,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 4,
                                height: double.infinity,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              Container(
                                width: 4,
                                height: double.infinity,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              Container(
                                width: 4,
                                height: double.infinity,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              Container(
                                width: 4,
                                height: double.infinity,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  AnimatedAlign(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeIn,
                    alignment: pos1,
                    child: _buildPhysicalCar(
                      Colors.grey.shade200,
                      isReversing: carIgnitionOn,
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeIn,
                    alignment: pos2,
                    child: _buildPhysicalCar(
                      const Color(0xFF38BDF8),
                      isReversing: carIgnitionOn,
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeIn,
                    alignment: pos3,
                    child: _buildPhysicalCar(
                      Colors.blueGrey.shade600,
                      isReversing: carIgnitionOn,
                    ),
                  ),

                  if (!_sequenceTriggered)
                    Positioned(
                      bottom: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Swipe lightly to clear the lot",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhysicalCar(Color bodyColor, {required bool isReversing}) {
    return Container(
      width: 58,
      height: 110,
      decoration: BoxDecoration(
        color: bodyColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 25,
            bottom: 25,
            left: 6,
            right: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            top: 40,
            bottom: 40,
            left: 2,
            right: 2,
            child: Container(color: bodyColor),
          ),

          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: 0,
                  left: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                      boxShadow: [
                        if (isReversing)
                          const BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                      boxShadow: [
                        if (isReversing)
                          const BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),

                if (isReversing)
                  Positioned(
                    bottom: -2,
                    left: 18,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isReversing)
                  Positioned(
                    bottom: -2,
                    right: 18,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Professional, Sleek, Aesthetic App Backing ---
  Widget _buildProfessionalRewardCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant Success Checkmark Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDCFCE7), width: 2),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF16A34A),
              size: 40,
            ),
          ),

          const Spacer(),

          // Professional subtle branding
          Text(
            widget.coupon.brand.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8), // Sleek metallic gray
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 8),

          // Reward Title
          Text(
            widget.coupon.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A), // Deep Slate
              height: 1.25,
            ),
          ),

          const Spacer(),

          // Modern Fintech-Style Discount Code Output Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Text(
              widget.coupon.couponCode ?? "PROCESSING",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB), // Sleek Finance Blue
                letterSpacing: 4.0,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sleek Midnight Button
          ElevatedButton.icon(
            onPressed: () {
              if (widget.coupon.couponCode != null) {
                Clipboard.setData(
                  ClipboardData(text: widget.coupon.couponCode!),
                );

                // Extremely clean confirmation notification
                Get.snackbar(
                  "Saved Securely",
                  "Offer code has been copied to your clipboard.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF0F172A),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  animationDuration: const Duration(milliseconds: 300),
                );
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A), // Midnight Dark
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            label: const Text(
              "COPY REWARD CODE",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
