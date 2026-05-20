import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/auth/signinpage.dart';
import 'package:parkingmudde/screen/auth/forgotpasswordpage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // Figma Exact Extracted Colors
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color labelGrey = Color(0xFF555555);
  static const Color borderGrey = Color(0xFFD2D2D2);
  static const Color textBlack = Color(0xFF222222);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC AND FUNCTIONS (API Calls Retained Completely Unaltered) ---
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      _showError("Please input a valid email address.");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters.");
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.loginWithPassword(email, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result["success"] == true) {
      await ApiService.saveUserSession(result);

      Get.offAll(() => const Dash(), transition: Transition.fadeIn);
    } else {
      _showError(
        result["message"] ?? "Invalid email or password. Please try again.",
      );
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Validation Error",
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 8,
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      "Coming soon",
      "This authentication provider will be available shortly.",
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }
  // --- END LOGIC ---

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle
          .dark, // Standard dark notification/time text logic mapped top limit
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textBlack,
              size: 20,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) Get.back();
            },
          ),
          centerTitle: true,
          title: const Text(
            "Login",
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
                      // Email label layout forms mapped
                      const Text(
                        "Email address",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: labelGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Figma Email Address Field map boundary space bounds
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: textBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _inputDecoration("Input email address"),
                      ),

                      const SizedBox(height: 18),

                      // Password Label Forms constraint layout mappings layout boundaries
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: labelGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Figma Exact Output Input mappings space limit limits map layout maps limits constraints mapping constraint limits constraints form layout
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(
                          color: textBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _inputDecoration("Input your password")
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9AA4B2),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                              ),
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Figma Classic Simple Primary Action Submit spaces forms bound layout boundaries bounds layout limit
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
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
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // Top Blue standard layout Forgot Navigation forms map
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.to(
                              () => const ForgotPasswordPage(),
                              transition: Transition.rightToLeft,
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // SOCIAL SIGN IN GROUPS mappings layout bound limit constraints bound standard limit
                      _SocialProviderButton(
                        text: "Continue with Google",
                        backgroundColor: Colors.white,
                        textColor: textBlack,
                        borderColor: borderGrey,
                        iconWidget:
                            const _FallbackGoogleIcon(), // Embedded safe multi-color placeholder logic forms map mapped space standard form limit
                        onTap: _showComingSoon,
                      ),
                      const SizedBox(height: 16),

                      _SocialProviderButton(
                        text: "Continue with Facebook",
                        backgroundColor: facebookBlue,
                        textColor: Colors.white,
                        borderColor: Colors.transparent,
                        iconWidget: const Icon(
                          Icons.facebook,
                          color: Colors.white,
                          size: 24,
                        ),
                        onTap: _showComingSoon,
                      ),
                      const SizedBox(height: 16),

                      _SocialProviderButton(
                        text: "Continue with Apple",
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        borderColor: Colors.transparent,
                        iconWidget: const Icon(
                          Icons.apple_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        onTap: _showComingSoon,
                      ),

                      // Fills visual gap remaining ensuring perfectly pushed "bottom aligned bounds limits" mapped boundaries constraints bound constraint
                      const Spacer(),

                      // Don't have an Account - Footer mapping bounds
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "You don't have an account? ",
                              style: TextStyle(
                                color: labelGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(
                                  () => const SignUpScreen(),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: const Text(
                                "Sign up",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 14,
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

  // Abstracted Style standardizing constraints boundaries border space mapped bound layouts logic standard boundary mapped maps
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFC0CAD8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderGrey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// UI COMPONENT FOR Figma Styled Identical Logic "Buttons" standard limit layouts mapped mapping map limit limit boundaries limits standard bounds bound space limit bounds maps limit constraint mapping constraint constraints
// ─────────────────────────────────────────────────────────
class _SocialProviderButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _SocialProviderButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Lightweight implementation bounds forms boundaries mapping
class _FallbackGoogleIcon extends StatelessWidget {
  const _FallbackGoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 24,
      child: ClipOval(
        child: Image.asset(
          'assets/images/google.jpg',
          fit: BoxFit.cover,
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            // Debug: print error to console
            print('Error loading Google image: $error');
            return Container(
              width: 24,
              height: 24,
              color: Colors.blue,
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
