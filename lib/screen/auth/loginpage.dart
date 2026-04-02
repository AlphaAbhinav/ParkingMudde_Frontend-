import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/auth/otppage.dart';
// Note: Kept strictly what was provided in your imports.
import 'package:parkingmudde/screen/auth/signinpage.dart';
import 'package:parkingmudde/screen/pageterm/termpage.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController referralController = TextEditingController();

  // Color Definitions to seamlessly match Brand Wireframes exactly
  final Color brandBlue = const Color(0XFF184b8c);
  final Color brandYellow = const Color(0XFFfdd708);

  bool isLoading = false;

  @override
  void dispose() {
    mobileController.dispose();
    referralController.dispose();
    super.dispose();
  }

  // --- Login Functional Method abstracted natively from Builder directly --
  Future<void> _handleLogin() async {
    final mobile = mobileController.text.trim();
    final referralCode = referralController.text.trim();

    // UX Touch: Hides Keyboard smoothly gracefully right before loading natively
    FocusScope.of(context).unfocus();

    if (mobile.length != 10) {
      Get.snackbar(
        "Invalid Number",
        "Please enter a valid 10-digit Indian mobile number",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.sendOtp(mobile);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result["success"] == true) {
      print("Generated OTP: ${result["otp"]}");

      Get.to(
        () => Otppage(mobile: mobile, referralCode: referralCode),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Get.snackbar(
        "Oops!",
        result["message"] ?? "Failed to send OTP securely. Try again.",
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
      body: SafeArea(child: _buildLoginBody(context)),
    );
  }

  Widget _buildLoginBody(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.vertical,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40), // Top spacing
            // -- LOGO SECITON --
            Align(
              alignment: Alignment.centerLeft,
              child: Hero(
                tag: "brandLogo",
                child: Image.asset(
                  'assets/logo.png',
                  height:
                      70, // Slightly more professional contained footprint size locally compared structurally!
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // -- HEADING TEXT GROUPING --
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color:
                    brandBlue, // Punchy Premium Titles visually mapped mapped correctly.
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sign in via mobile securely tracking slots globally securely completely natively entirely easily via.",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 35),

            // -- MOBILE NUMBER FIELD STRUCTURE (Custom styled beautifully layout limits correctly) --
            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintText: "Enter Mobile Number",
                hintStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.call_rounded,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "+91",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 24,
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: brandBlue, width: 2.0),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -- REFERRAL CODE FIELD STRUCTURE --
            TextFormField(
              controller: referralController,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                hintText: "Referral Code (Optional)",
                hintStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: brandBlue, width: 2.0),
                ),
              ),
            ),

            const SizedBox(height: 35),

            GestureDetector(
              onTap: isLoading ? null : _handleLogin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  color: brandBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: brandBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Send Secure OTP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don’t have an account?",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => SignUpScreen(),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Text(
                    "Create Now",
                    style: TextStyle(
                      color: brandBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 15),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(
                          text: "By continuing, you agree to our ",
                        ),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Pageterm(
                                  tittle: 'Terms & Conditions',
                                ),
                              ),
                            ),
                        ),
                        const TextSpan(text: '  •  '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const Pageterm(tittle: 'Privacy Policy'),
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
