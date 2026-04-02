import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:sms_autofill/sms_autofill.dart';

class Otppage extends StatefulWidget {
  final String mobile;
  final String referralCode;

  const Otppage({super.key, required this.mobile, required this.referralCode});

  @override
  State<Otppage> createState() => _OtppageState();
}

class _OtppageState extends State<Otppage> {
  String enteredOtp = "";
  bool isLoading = false;

  final Color brandBlue = const Color(0XFF184b8c);
  final Color brandYellow = const Color(0XFFfdd708);

  Future<void> _handleVerification() async {
    FocusScope.of(context).unfocus();

    if (enteredOtp.length != 6) {
      Get.snackbar(
        "Action Required",
        "Please enter the complete 6-digit OTP code sent.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
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
      await prefs.setString("user_id", result["user_id"]);

      Get.offAll(() => Dash());
    } else {
      Get.snackbar(
        "Invalid OTP",
        result["message"] ??
            "Verification failed. Please check the code and try again.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
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
                          color: Colors.grey.shade100,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(child: Image.asset('assets/logo.png', height: 70)),

                  const SizedBox(height: 35),

                  const Text(
                    "Enter OTP Code",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
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
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(
                          text: "Please enter the 6-digit pin code sent to\n",
                        ),
                        TextSpan(
                          text: "+91 ${widget.mobile}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  PinFieldAutoFill(
                    codeLength: 6,
                    autoFocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: BoxLooseDecoration(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: brandBlue,
                      ),
                      gapSpace: 12,
                      strokeWidth: 1.8,
                      radius: const Radius.circular(12),
                      strokeColorBuilder: PinListenColorBuilder(
                        brandBlue,
                        Colors.grey.shade300,
                      ),
                      bgColorBuilder: const FixedColorBuilder(
                        Color(0xFFFAFAFA),
                      ),
                    ),
                    onCodeChanged: (value) {
                      if (value == null) return;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;

                        setState(() {
                          enteredOtp = value;
                        });

                        if (enteredOtp.length == 6 && !isLoading) {
                          _handleVerification();
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Didn't receive code?  ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final result = await ApiService.sendOtp(
                                  widget.mobile,
                                );

                                if (result["success"] == true) {
                                  Get.snackbar(
                                    "OTP Resent",
                                    "Successfully sent a new code.",
                                    backgroundColor: Colors.black87,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                    margin: const EdgeInsets.all(15),
                                  );
                                }
                              },
                            text: 'Resend',
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
                                "Verify OTP",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
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
