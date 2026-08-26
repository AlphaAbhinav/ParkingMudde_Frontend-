import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/auth/onboarding.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/auth/permissionspage.dart';
import 'package:pinput/pinput.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class Otppage extends StatefulWidget {
  final String mobile;
  final String referralCode;
  final String? testOtp;
  final bool requireVehicleOnSuccess;

  const Otppage({
    super.key,
    required this.mobile,
    required this.referralCode,
    this.testOtp,
    this.requireVehicleOnSuccess = false,
  });

  @override
  State<Otppage> createState() => _OtppageState();
}

class _OtppageState extends State<Otppage> {
  String enteredOtp = "";
  bool isLoading = false;
  bool isResending = false;
  final TextEditingController otpController = TextEditingController();

  final Color brandBlue = const Color(0XFF184b8c);
  final Color brandYellow = const Color(0XFFfdd708);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOtpToast(widget.testOtp);
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _showAuthToast({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFFFF1A8),
      colorText: const Color(0xFF253047),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 14,
      borderColor: const Color(0xFFFFB300),
      borderWidth: 1.4,
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFFFB300).withOpacity(0.26),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
      icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF167C80)),
      duration: const Duration(seconds: 4),
    );
  }

  void _showOtpToast(String? otp) {
    if (otp == null || otp.trim().isEmpty) {
      _showAuthToast(
        title: "Code sent",
        message: "A 6-digit code has been sent to your mobile.",
      );
      return;
    }

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      "OTP sent",
      "Your OTP is ${otp.trim()}",
      backgroundColor: brandBlue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      borderRadius: 12,
      icon: const Icon(Icons.password_rounded, color: Colors.white),
      duration: const Duration(seconds: 12),
    );
  }

  Future<void> _handleVerification() async {
    FocusScope.of(context).unfocus();

    if (enteredOtp.length != 6) {
      _showAuthToast(
        title: "A quick check",
        message: "Please enter the complete 6-digit code we sent you.",
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.verifyOtp(
      widget.mobile,
      enteredOtp,
      widget.referralCode,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result["success"] == true) {
      final prefs = await SharedPreferences.getInstance();
      await ApiService.saveUserSession({
        ...result,
        "mobile_number": widget.mobile,
      });
      final isNewAccount =
          result["is_new_user"] == true || widget.requireVehicleOnSuccess;
      if (isNewAccount) {
        await prefs.setBool("is_new_user", true);
        await prefs.setBool("pending_feature_walkthrough", true);
      } else {
        await prefs.setBool("pending_feature_walkthrough", false);
      }

      // Sync FCM Token
      try {
        await ApiService.syncCurrentFcmToken();
      } catch (e) {
        print("Error syncing FCM token: $e");
      }

      if (isNewAccount) {
        Get.offAll(
          () => ParkingOnboarding(
            fromAccountCreation: true,
            requireVehicleOnSuccess: widget.requireVehicleOnSuccess,
          ),
          transition: Transition.fadeIn,
        );
        return;
      }

      final hasSeenPermissions = prefs.getBool("has_seen_permissions") ?? false;
      if (!hasSeenPermissions) {
        Get.offAll(() => const PermissionsPage(requireVehicleOnSuccess: false));
      } else {
        Get.offAll(() => const Dash());
      }
    } else {
      _showAuthToast(
        title: result["title"]?.toString() ?? "Invalid Code",
        message: result["message"]?.toString() ??
            "That code doesn't seem right. Please check and try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(child: Image.asset('assets/logo.png', height: 70)),

                  const SizedBox(height: 35),

                  const Text(
                    "Almost there! ✨",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        const TextSpan(
                          text: "We've just sent a secure 6-digit code to\n",
                        ),
                        TextSpan(
                          text: "+91 ${widget.mobile}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  Pinput(
                    controller: otpController,
                    length: 6,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 24,
                        color: brandBlue,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.8,
                        ),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 24,
                        color: brandBlue,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: brandBlue, width: 2.0),
                      ),
                    ),
                    onCompleted: (pin) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          enteredOtp = pin;
                        });
                        if (enteredOtp.length == 6 && !isLoading) {
                          _handleVerification();
                        }
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        enteredOtp = value;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Didn't receive the message?  ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                if (isResending) return;
                                setState(() => isResending = true);
                                final result = await ApiService.sendOtp(
                                  widget.mobile,
                                );

                                if (!mounted) return;
                                setState(() => isResending = false);

                                if (result["success"] == true) {
                                  final newOtp = result["otp"]?.toString();
                                  setState(() {
                                    enteredOtp = "";
                                  });
                                  otpController.clear();
                                  _showOtpToast(newOtp);
                                } else {
                                  _showAuthToast(
                                    title: result["title"]?.toString() ?? "Hold on",
                                    message: result["message"]?.toString() ??
                                        "We couldn't resend the code just yet. Please try again.",
                                  );
                                }
                              },
                            text: isResending ? 'Sending...' : 'Resend it',
                            style: TextStyle(
                              fontSize: 14,
                              color: brandBlue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: brandBlue.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  GestureDetector(
                    onTap: isLoading ? null : _handleVerification,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        color: enteredOtp.length == 6
                            ? brandBlue
                            : brandBlue.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: enteredOtp.length == 6 && !isLoading
                            ? [
                                BoxShadow(
                                  color: brandBlue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Verify & Continue",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ScreenSlogan(
                    "One last step. Your privacy matters.",
                    color: brandBlue,
                    icon: Icons.verified_user_rounded,
                    imagePath: 'assets/otpslogan.png',
                    normalImageWidth: 140,
                    compactImageWidth: 118,
                    textMaxLines: 2,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
