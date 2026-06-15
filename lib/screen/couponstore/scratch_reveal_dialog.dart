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
  double _scratchProgress = 0.0;
  bool isRevealed = false;

  // Car exit states
  bool car1Exited = false;
  bool car2Exited = false;
  bool car3Exited = false;
  bool car4Exited = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
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
    setState(() {
      _scratchProgress = progress;

      // Trigger cars to exit at different scratch intervals
      if (progress > 15) {
        car1Exited = true;
        car2Exited = true;
        car3Exited = true;
        car4Exited = true;
      }
    });
  }

  void _onScratchThreshold() {
    if (!isRevealed) {
      isRevealed = true;
      scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 500));
      
      // Delay slightly so the user sees the clear state, then flip
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _flipController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(pi * _flipAnimation.value);

          // If passed 90 degrees, we need to correct the Y rotation so it's not mirrored
          if (_flipAnimation.value >= 0.5) {
            transform.rotateY(pi);
          }

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFlipped ? _buildBackCard() : _buildFrontCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Underlying hint (What's being scratched to reveal)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: Colors.orange.shade300, size: 60),
                const SizedBox(height: 12),
                const Text(
                  "Keep Scratching!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),

          // The Scratcher overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Scratcher(
              key: scratchKey,
              brushSize: 80,
              threshold: 40,
              color: const Color(0xFF333A45),
              onChange: _onScratchUpdate,
              onThreshold: _onScratchThreshold,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
          ),

          // Instruction Text on top of the scratcher
          if (_scratchProgress < 5)
            Positioned(
              top: 40,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Scratch to unpark cars!",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // Parking Lot Grid Lines
          IgnorePointer(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Horizontal line
                Container(width: 250, height: 4, color: Colors.white),
                // Vertical line
                Container(width: 4, height: 250, color: Colors.white),
                // Center circle
                Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4))),
              ],
            ),
          ),
          
          // Animated Cars Layer (Vector art)
          // Top Car (going UP)
          AnimatedAlign(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInBack,
            alignment: car1Exited ? const Alignment(0, -3.0) : const Alignment(0, -0.6),
            child: IgnorePointer(child: _buildVectorCar(Colors.red.shade400, 0)),
          ),
          // Bottom Car (going DOWN)
          AnimatedAlign(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInBack,
            alignment: car2Exited ? const Alignment(0, 3.0) : const Alignment(0, 0.6),
            child: IgnorePointer(child: _buildVectorCar(Colors.blue.shade400, 180)),
          ),
          // Left Car (going LEFT)
          AnimatedAlign(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInBack,
            alignment: car3Exited ? const Alignment(-3.0, 0) : const Alignment(-0.6, 0),
            child: IgnorePointer(child: _buildVectorCar(Colors.green.shade400, -90)),
          ),
          // Right Car (going RIGHT)
          AnimatedAlign(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInBack,
            alignment: car4Exited ? const Alignment(3.0, 0) : const Alignment(0.6, 0),
            child: IgnorePointer(child: _buildVectorCar(Colors.orange.shade400, 90)),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorCar(Color color, double angleDegrees) {
    return Transform.rotate(
      angle: angleDegrees * pi / 180,
      child: Container(
        width: 60,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Windshield
            Positioned(
              top: 20,
              left: 10,
              right: 10,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Rear window
            Positioned(
              bottom: 15,
              left: 10,
              right: 10,
              child: Container(
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Headlights
            Positioned(top: 5, left: 8, child: Container(width: 8, height: 6, color: Colors.yellow.shade200)),
            Positioned(top: 5, right: 8, child: Container(width: 8, height: 6, color: Colors.yellow.shade200)),
            // Taillights
            Positioned(bottom: 5, left: 8, child: Container(width: 10, height: 4, color: Colors.red.shade900)),
            Positioned(bottom: 5, right: 8, child: Container(width: 10, height: 4, color: Colors.red.shade900)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, color: Colors.orange, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            widget.coupon.brand.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.coupon.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
            ),
            child: Text(
              widget.coupon.couponCode ?? "PROCESSING...",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0XFF184B8C),
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.coupon.couponCode != null) {
                Clipboard.setData(ClipboardData(text: widget.coupon.couponCode!));
                Get.snackbar(
                  "Copied!",
                  "Coupon code copied to clipboard",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.black87,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            label: const Text("COPY CODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFF184B8C),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }
}
