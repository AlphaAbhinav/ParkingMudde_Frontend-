import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:parkingmudde/screen/auth/onboarding.dart';

class Splashpage extends StatefulWidget {
  const Splashpage({super.key});

  @override
  State<Splashpage> createState() => _SplashpageState();
}

class _SplashpageState extends State<Splashpage> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _loopController;

  @override
  void initState() {
    super.initState();

    // The Master sequence timeline for driving the car and dropping the logo.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Continuous idle loops (The hovering logic, blinking button, glowing scanning radar).
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Chain the logic!
    // We launch into perpetual animations instantly while intro sequence governs coordinates.
    _introController.forward();
    _loopController.repeat();
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  void _navigateToNextPage() {
    Get.offAll(
      () => const ParkingOnboarding(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically retrieve user dimensions cleanly to keep layouts identical between different mobiles / tablets
    final screenW = MediaQuery.of(context).size.width;

    // Establishing proportional rigid scales
    double logoW = screenW * 0.7;
    if (logoW > 350) logoW = 350; // Set ceiling size for desktop / tablets.
    const double carW = 100; // Small adorable size for dragging car!
    const double maxRopeW = 60; // Max stretched distance.

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1D3557), // Dim dark industrial Navy
              Color(0xFF0b0f19),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToNextPage,
            splashColor: const Color(
              0xFFF1CA10,
            ).withOpacity(0.3), // Interaction
            highlightColor: Colors.transparent,
            child: SizedBox.expand(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _introController,
                  _loopController,
                ]),
                builder: (context, child) {
                  // ---- TIMING BLOCKS BREAKDOWN ----
                  double val = _introController.value;

                  // tPull: The Car driving onto center (0s to 1.75s)
                  double tPull = (val / 0.5).clamp(0.0, 1.0);

                  // tUnlink: Detach recoil logic snap duration (1.75s to 2.10s)
                  double tUnlink = ((val - 0.5) / 0.1).clamp(0.0, 1.0);

                  // tDriveOff: Post drop driving completely past screen edges. (2.1s - 3.5s)
                  double tDriveOff = ((val - 0.6) / 0.4).clamp(0.0, 1.0);

                  // Fluid non-robotic curve acceleration values.
                  double easePull = Curves.easeOutCubic.transform(tPull);
                  double easeDriveOff = Curves.easeInQuart.transform(tDriveOff);
                  // ------------------------------------

                  // Math for positions using exact distances guarantees zero overlaps and scale safety

                  // LOGO Coordinates
                  double logoStartX =
                      -(screenW); // Start way completely beyond user view on Left Edge
                  double logoX =
                      logoStartX +
                      (easePull *
                          (0.0 -
                              logoStartX)); // Travel all way specifically to 0.

                  // CAR / TOW TRUCK coordinates relative strictly linked structurally right next to the pulled Logo.
                  double ropeW =
                      maxRopeW *
                      (1.0 - tUnlink); // Tow Line recoil formula towards Bumper
                  double offsetDistanceLogoCenterToCarCenter =
                      (logoW / 2) + ropeW + (carW / 2);

                  double carDriveDistance =
                      (screenW) *
                      1.5; // Final total journey needed pushing him far Out right edges.
                  double carX =
                      logoX +
                      offsetDistanceLogoCenterToCarCenter +
                      (easeDriveOff * carDriveDistance);

                  // Vibrate bouncing Y engine motion simulator (Active Only when accelerating weight).
                  double carJitterY = 0;
                  if (tPull > 0 && tPull < 1.0) {
                    // Strong struggling heavy engine vibrations.
                    carJitterY = math.sin(val * 140) * 2.0;
                  } else if (tDriveOff > 0 && tDriveOff < 1.0) {
                    // Rapid exhaust leaving sprint bounce
                    carJitterY = math.sin(val * 90) * 1.5;
                  }

                  // IDLE FLOAT AND HOVER SYSTEM LOGIC!
                  // It gradually fades into floating hover sine wave right after Unlinking.
                  double hoverInfluencePower = tUnlink;
                  double smoothFloatingYOffset =
                      math.sin(_loopController.value * math.pi * 2) *
                      8.0 *
                      hoverInfluencePower;

                  // Tilt degree calculations backward. Returns solidly locked onto plane when dragging 0% and completed.
                  double pullTiltLeaningDegAngle = -0.12 * (1.0 - easePull);

                  // --------------------------------

                  return Stack(
                    alignment: Alignment.center,
                    // Clipping is imperative otherwise the OffScreen widgets overlap the UI scaffolding limits
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // --- BACKGROUND: Dynamic Glowing Ring Scanning System that surfaces gracefully post dropping --
                      Opacity(
                        opacity: hoverInfluencePower,
                        child: Transform.scale(
                          // Sine scaling from (1 -> ~1.4 scale factor)
                          scale:
                              1.0 +
                              (math.sin(_loopController.value * math.pi * 2) *
                                      0.4)
                                  .clamp(0, 2),
                          child: Opacity(
                            opacity:
                                (0.4 -
                                ((math.sin(
                                      _loopController.value * math.pi * 2,
                                    )).clamp(0.0, 1.0)) *
                                    0.3),
                            child: Container(
                              width: logoW * 1.1,
                              height: logoW * 1.1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blueAccent.shade700,
                                  width: 3,
                                ),
                                color: Colors.lightBlue.withOpacity(0.02),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // --- OBJECT 1: The Yellow Structural High Tension TOW LINE ! ---
                      Transform.translate(
                        offset: Offset(
                          carX - (carW / 2) - (ropeW / 2),
                          0 + carJitterY,
                        ),
                        child: Visibility(
                          visible: tDriveOff < 1.0,
                          child: Container(
                            width: ropeW,
                            height: 3.5, // Thick tension strap aesthetics!
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB703),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      // --- OBJECT 2: YOUR PREMIUM LOGO WITH ITS DRAG, DROP TILT! ---
                      Transform.translate(
                        offset: Offset(logoX, smoothFloatingYOffset),
                        child: Transform.rotate(
                          angle:
                              pullTiltLeaningDegAngle, // Drags backward, snaps upright!
                          alignment: Alignment
                              .bottomRight, // Physics point where the drag rotates realistically.
                          child: Container(
                            // Bold drop shadows cast visually upon reaching hover stages
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    0.3 * hoverInfluencePower,
                                  ),
                                  spreadRadius: 5,
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              "assets/logo.png",
                              width: logoW,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      // --- OBJECT 3: YOUR FUN THEMATIC INBOUND TOWING TRUCK / CAR SPRITE ! ---
                      Transform.translate(
                        offset: Offset(carX, carJitterY),
                        child: Image.asset(
                          "assets/car.png",
                          width: carW,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // --- OBJECT 4: Tap Interaction glowing instruction. Smooth visibility logic bound below the Logo bounds ---
                      Positioned(
                        bottom: 80,
                        child: Opacity(
                          opacity:
                              tDriveOff, // Doesn't actually physically light up for usage interactively until completely detached sequence completes
                          child: Opacity(
                            // Soft breathy Neon glow pulsation natively leveraging math wave 0 - 1 !
                            opacity:
                                0.5 +
                                ((math.sin(
                                          _loopController.value * math.pi * 2,
                                        ) +
                                        1.0) /
                                    4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.touch_app_rounded,
                                  color: Colors.yellowAccent,
                                  size: 28,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "TAP SCREEN TO CONTINUE",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.yellowAccent.withOpacity(0.9),
                                    letterSpacing:
                                        4.5, // Extreme spacing hints high app-design traits.
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
