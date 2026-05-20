import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import 'loginpage.dart';

/// Forgot Password — two-step logic exactly combined with Figma aesthetics
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Step 1
  final emailCtrl = TextEditingController();
  String? _emailErrorText;

  // Step 2
  final otpCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool isLoading = false;
  bool obscureNew = true;
  bool obscureConfirm = true;

  int step = 1;
  String _email = "";
  String? _devOtp;

  // Figma Exact Extracted Colors mapping identical to Login
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color labelGrey = Color(0xFF555555);
  static const Color subTextGrey = Color(0xFF999999);
  static const Color borderGrey = Color(0xFFD2D2D2);
  static const Color textBlack = Color(0xFF222222);
  static const Color errorRed = Color(
    0xFFF03648,
  ); // Figma vibrant red for errors

  @override
  void dispose() {
    emailCtrl.dispose();
    otpCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // STEP 1 — Request OTP via email (API & State Logic Unaltered)
  // ──────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();
    final email = emailCtrl.text.trim().toLowerCase();

    // Mapping specific Figma inline error display state (Panel 03.4)
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      setState(() {
        _emailErrorText = "Please provide a valid email address.";
      });
      return;
    }

    setState(() {
      _emailErrorText = null;
      isLoading = true;
    });

    final result = await ApiService.sendResetCode(email);
    if (!mounted) return;

    setState(() => isLoading = false);

    if (result["success"] == true) {
      _email = email;
      _devOtp = result["otp"]?.toString();

      if (_devOtp != null) {
        Get.snackbar(
          "Dev Mode — OTP",
          "Email not configured. Test Code: $_devOtp",
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(20),
          borderRadius: 10,
          duration: const Duration(seconds: 8),
        );
      }

      setState(() => step = 2);
    } else {
      Get.snackbar(
        "Request Failed",
        result["message"] ?? "Failed to send the password reset instruction.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 10,
      );
    }
  }

  // ──────────────────────────────────────────────
  // STEP 2 — Verify OTP + set new password (API & State Logic Unaltered)
  // ──────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final otp = otpCtrl.text.trim();
    final newPw = newPasswordCtrl.text.trim();
    final confirmPw = confirmPasswordCtrl.text.trim();

    if (otp.length != 6) {
      _showSnackbarError("Invalid code length. Ensure it's exactly 6 digits.");
      return;
    }

    if (newPw.length < 6) {
      _showSnackbarError("New password must be at least 6 characters.");
      return;
    }

    if (newPw != confirmPw) {
      _showSnackbarError("Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.resetPassword(
      email: _email,
      otpCode: otp,
      newPassword: newPw,
    );
    if (!mounted) return;

    setState(() => isLoading = false);

    if (result["success"] == true) {
      Get.snackbar(
        "Success",
        "Your password has been successfully updated. Please login.",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Get.offAll(() => const Loginpage(), transition: Transition.fadeIn);
    } else {
      _showSnackbarError(
        result["message"] ?? "Password reset verification failed.",
      );
    }
  }

  void _showSnackbarError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryBlue,
              size: 20,
            ),
            onPressed: () {
              if (step == 2) {
                setState(() => step = 1);
              } else if (Navigator.canPop(context)) {
                Get.back();
              }
            },
          ),
          centerTitle: true,
          title: const Text(
            "Forgot Password",
            style: TextStyle(
              color: textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      if (step == 1) ..._buildStep1() else ..._buildStep2(),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "You remember your password? ",
                              style: TextStyle(
                                color: labelGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.offAll(
                                  () => const Loginpage(),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Step 1 UI — Matching panels 03.1 to 03.4
  // ──────────────────────────────────────────────
  List<Widget> _buildStep1() {
    return [
      // Padlock Graphics manually created purely visually like Figma!
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.lock, size: 55, color: primaryBlue),
              Positioned(
                bottom: 6,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F58),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      "?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),

      const Text(
        "Forgot your password?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textBlack,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        "Enter your registered email below to receive\npassword reset instruction",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: subTextGrey,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 36),

      const Text(
        "Email address",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: labelGrey,
        ),
      ),
      const SizedBox(height: 8),

      // Matched directly to inline inline visual styles 03.4 layout behavior limits layout
      TextField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: textBlack,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (val) {
          if (_emailErrorText != null) {
            setState(
              () => _emailErrorText = null,
            ); // dismiss manual inline error boundary mapping layouts
          }
        },
        decoration: InputDecoration(
          hintText: "Input email address",
          hintStyle: const TextStyle(
            color: Color(0xFFC0CAD8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _emailErrorText != null ? errorRed : borderGrey,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _emailErrorText != null ? errorRed : primaryBlue,
              width: 1.5,
            ),
          ),
        ),
      ),

      // Accurate inline validation feedback visual layout error bound map (Figms Screen 03.4 exactly replicated mappings space limit constraints)
      if (_emailErrorText != null) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.error, color: errorRed, size: 16),
            const SizedBox(width: 4),
            Text(
              _emailErrorText!,
              style: const TextStyle(
                color: errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 28),

      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Send",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ];
  }

  // ──────────────────────────────────────────────
  // Step 2 UI — Verification step matches exact Figma Panel 03.5 aesthetics natively
  // ──────────────────────────────────────────────
  List<Widget> _buildStep2() {
    return [
      // Envelop & Verification Graphic built manually through flutter logic bound form limit limit map map map logic mapped forms mappings maps forms limit standard mapping spaces bounds constraint bounds constraint map bounds layout mapping mapping limit
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 80,
          height: 75,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Positioned(
                bottom: 8,
                child: Icon(
                  Icons.mail,
                  size: 70,
                  color: Color(0xFFFEBC68),
                ), // Beautiful Peach envelope
              ),
              Positioned(
                top:
                    30, // Nested icon depth spacing constraints mappings mapping bounds mapped
                child: Container(
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF67CF98),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,

                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      const Text(
        "We have sent an OTP to your email",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textBlack,
        ),
      ),
      const SizedBox(height: 12),

      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: subTextGrey,
            height: 1.6,
          ),
          children: [
            const TextSpan(
              text: "Did not receive the OTP? check your spam filter or\n",
            ), // Adjusted minimal typo bounds form spaces mappings boundaries limit maps
            WidgetSpan(
              child: GestureDetector(
                onTap: isLoading ? null : _sendOtp,
                child: const Text(
                  "resend",
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 48),

      // Retained API Verification Components mapping styles map logic layout map
      _buildFigmaTiedTextField(
        label: "Verification Code",
        hint: "Input 6-digit OTP",
        controller: otpCtrl,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),

      _buildFigmaTiedTextField(
        label: "New Password",
        hint: "Input your password",
        controller: newPasswordCtrl,
        obscureText: obscureNew,
        onToggleObscure: () => setState(() => obscureNew = !obscureNew),
      ),
      const SizedBox(height: 16),

      _buildFigmaTiedTextField(
        label: "Confirm Password",
        hint: "Input confirm password",
        controller: confirmPasswordCtrl,
        obscureText: obscureConfirm,
        onToggleObscure: () => setState(() => obscureConfirm = !obscureConfirm),
      ),
      const SizedBox(height: 28),

      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Save Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ];
  }

  Widget _buildFigmaTiedTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: textBlack,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFC0CAD8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9AA4B2),
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderGrey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
