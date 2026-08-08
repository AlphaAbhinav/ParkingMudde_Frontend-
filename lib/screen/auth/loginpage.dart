import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/auth/signinpage.dart';
import 'package:parkingmudde/screen/auth/forgotpasswordpage.dart';
import 'package:parkingmudde/screen/auth/otppage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/auth/permissionspage.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';
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
      _showError("Please enter a valid email address.");
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
      await prefs.setBool("pending_feature_walkthrough", false);
      final hasSeenPermissions = prefs.getBool("has_seen_permissions") ?? false;
      if (!hasSeenPermissions) {
        Get.offAll(
          () => const PermissionsPage(),
          transition: Transition.fadeIn,
        );
      } else {
        Get.offAll(() => const Dash(), transition: Transition.fadeIn);
      }
    } else {
      _showAuthToast(
        title: result["title"]?.toString() ?? "Couldn't log you in",
        message: result["message"]?.toString() ??
            "Invalid email or password. Please try again.",
      );
    }
  }

  Future<void> _handlePhoneLogin() async {
    FocusScope.of(context).unfocus();
    final mobile = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
      _showError("Please enter a valid 10-digit mobile number.");
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
      _showAuthToast(
        title: result["title"]?.toString() ?? "Couldn't send OTP",
        message: result["message"]?.toString() ??
            "Could not send OTP. Please try again.",
      );
    }
  }

  void _showError(String message) {
    _showAuthToast(title: "A quick check", message: message);
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

  void _showComingSoon() {
    Get.snackbar(
      "Coming soon",
      "We're setting this up for you. It'll be ready shortly!",
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
          // Cleaned up App Bar - moved the text below to make it warmer
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Warm Greeting Section ──
                const Text(
                  "Welcome back! 👋",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We're so glad to see you again.",
                  style: TextStyle(
                    fontSize: 15,
                    color: subTextGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

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

                // ── Join Footer ──
                _buildSignUpFooter(),

                const SizedBox(height: 16),
                const ScreenSlogan(
                  "Nice to see you again.",
                  color: primaryBlue,
                  icon: Icons.bolt_rounded,
                  imagePath: 'assets/loginslogan.png',
                  normalImageWidth: 160,
                  compactImageWidth: 145,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.0),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _selectedTab == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tabOption(index: 0, icon: Icons.email_outlined, label: "Email"),
              _tabOption(
                index: 1,
                icon: Icons.phone_android_rounded,
                label: "Phone",
              ),
            ],
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
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? primaryBlue : const Color(0xFF8A92A0),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.1,
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
          decoration: _inputDecoration("e.g. name@example.com"),
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
          decoration: _inputDecoration("Enter your password").copyWith(
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
                    "Sign in",
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
          decoration: _inputDecoration("Enter your 10-digit number"),
        ),
        const SizedBox(height: 8),
        const Text(
          "We'll send a 6-digit OTP to securely verify you.",
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
                "Or easily connect with",
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
          iconWidget: const Icon(Icons.facebook, color: Colors.white, size: 24),
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
          "New here? ",
          style: TextStyle(
            color: labelGrey,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(
            () => const SignUpScreen(),
            transition: Transition.rightToLeft,
          ),
          child: const Text(
            "Join",
            style: TextStyle(
              color: primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w800, // Makes "Join" pop perfectly!
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
