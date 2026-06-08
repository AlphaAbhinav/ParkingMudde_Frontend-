import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/auth/signinpage.dart';
import 'package:parkingmudde/screen/auth/forgotpasswordpage.dart';
import 'package:parkingmudde/screen/auth/otppage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/auth/permissionspage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  // 0 = Email+Password, 1 = Phone+OTP
  int _selectedTab = 0;

  // Email + Password
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Phone + OTP
  final TextEditingController phoneController = TextEditingController();

  bool isLoadingEmail = false;
  bool isLoadingPhone = false;
  bool obscurePassword = true;

  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color labelGrey = Color(0xFF555555);
  static const Color borderGrey = Color(0xFFD2D2D2);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF999999);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
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

    setState(() => isLoadingEmail = true);
    final result = await ApiService.loginWithPassword(email, password);
    if (!mounted) return;
    setState(() => isLoadingEmail = false);

    if (result["success"] == true) {
      await ApiService.saveUserSession(result);
      final prefs = await SharedPreferences.getInstance();
      final hasSeenPermissions = prefs.getBool("has_seen_permissions") ?? false;
      if (!hasSeenPermissions) {
        Get.offAll(() => const PermissionsPage(), transition: Transition.fadeIn);
      } else {
        Get.offAll(() => const Dash(), transition: Transition.fadeIn);
      }
    } else {
      _showError(
        result["message"] ?? "Invalid email or password. Please try again.",
      );
    }
  }

  Future<void> _handlePhoneLogin() async {
    FocusScope.of(context).unfocus();
    final mobile = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (mobile.length != 10) {
      _showError("Enter a valid 10-digit mobile number.");
      return;
    }

    setState(() => isLoadingPhone = true);
    final result = await ApiService.sendOtp(mobile);
    if (!mounted) return;
    setState(() => isLoadingPhone = false);

    if (result["success"] == true) {
      Get.to(
        () => Otppage(
          mobile: mobile,
          referralCode: "",
          testOtp: result["otp"]?.toString(),
          requireVehicleOnSuccess: false,
        ),
        transition: Transition.rightToLeft,
      );
    } else {
      _showError(result["message"] ?? "Could not send OTP. Please try again.");
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Tab Toggle ──
                _buildToggle(),
                const SizedBox(height: 28),

                // ── Tab Content ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _selectedTab == 0
                      ? _buildEmailPasswordTab()
                      : _buildPhoneOtpTab(),
                ),

                const SizedBox(height: 28),

                // ── Social Login ──
                _buildSocialSection(),

                const SizedBox(height: 42),

                // ── Sign Up Footer ──
                _buildSignUpFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabOption(
            index: 0,
            icon: Icons.email_outlined,
            label: "Email & Password",
          ),
          _tabOption(
            index: 1,
            icon: Icons.phone_android_rounded,
            label: "Phone & OTP",
          ),
        ],
      ),
    );
  }

  Widget _tabOption({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? primaryBlue : const Color(0xFF8A92A0),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? primaryBlue : const Color(0xFF8A92A0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPasswordTab() {
    return Column(
      key: const ValueKey("email_tab"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Email address",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
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
        const Text(
          "Password",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          style: const TextStyle(
            color: textBlack,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration("Input your password").copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9AA4B2),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoadingEmail ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoadingEmail
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
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => Get.to(
              () => const ForgotPasswordPage(),
              transition: Transition.rightToLeft,
            ),
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
      ],
    );
  }

  Widget _buildPhoneOtpTab() {
    return Column(
      key: const ValueKey("phone_tab"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Mobile number",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(
            color: textBlack,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration("Enter 10-digit mobile number"),
        ),
        const SizedBox(height: 8),
        const Text(
          "We'll send a 6-digit OTP to verify your number.",
          style: TextStyle(
            color: subTextGrey,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoadingPhone ? null : _handlePhoneLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoadingPhone
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sms_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Send OTP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: borderGrey)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Or continue with",
                style: TextStyle(
                  color: subTextGrey.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
            const Expanded(child: Divider(color: borderGrey)),
          ],
        ),
        const SizedBox(height: 20),
        _SocialProviderButton(
          text: "Continue with Google",
          backgroundColor: Colors.white,
          textColor: textBlack,
          borderColor: borderGrey,
          iconWidget: const _FallbackGoogleIcon(),
          onTap: _showComingSoon,
        ),
        const SizedBox(height: 12),
        _SocialProviderButton(
          text: "Continue with Facebook",
          backgroundColor: facebookBlue,
          textColor: Colors.white,
          borderColor: Colors.transparent,
          iconWidget:
              const Icon(Icons.facebook, color: Colors.white, size: 24),
          onTap: _showComingSoon,
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _buildSignUpFooter() {
    return Row(
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
          onTap: () => Get.to(
            () => const SignUpScreen(),
            transition: Transition.rightToLeft,
          ),
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
    );
  }

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
