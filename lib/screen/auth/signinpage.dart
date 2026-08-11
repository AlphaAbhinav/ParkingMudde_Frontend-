import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/auth/loginpage.dart';
import 'package:parkingmudde/screen/auth/onboarding.dart';
import 'package:parkingmudde/screen/pageterm/termpage.dart';
import '../../services/api_service.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Page Navigation State
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final drivingLicenseCtrl = TextEditingController();
  final aadhaarCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final referralCtrl = TextEditingController();
  final societyCtrl = TextEditingController();
  final towerCtrl = TextEditingController();
  final flatCtrl = TextEditingController();

  bool acceptedTerms = false;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const Color primaryBlue = Color(0xFF184B8C); // Polished brand blue
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color subTextGrey = Color(0xFF64748B);
  static const Color bgFillGrey = Color(0xFFF1F5F9); // Muted input fill
  static const Color textBlack = Color(0xFF1E293B);

  List<Map<String, dynamic>> _societiesList = [];
  String? _selectedSociety;

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    final res = await ApiService.getSocieties();
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _societiesList = List<Map<String, dynamic>>.from(
            res['societies'] ?? [],
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    drivingLicenseCtrl.dispose();
    aadhaarCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    referralCtrl.dispose();
    societyCtrl.dispose();
    towerCtrl.dispose();
    flatCtrl.dispose();
    super.dispose();
  }

  // --- Step 1 Validations (Basic) ---
  bool _validateStep1() {
    FocusScope.of(context).unfocus();
    if (firstNameCtrl.text.trim().isEmpty) {
      return _err("Please enter your first name.");
    }
    if (lastNameCtrl.text.trim().isEmpty) {
      return _err("Please enter your last name.");
    }
    final mobile = mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
      return _err("Enter a valid 10-digit mobile number.");
    }

    final email = emailCtrl.text.trim().toLowerCase();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      return _err("Please enter a valid email address.");
    }
    return true;
  }

  // --- Step 2 Validations (ID/Referral) ---
  bool _validateStep2() {
    FocusScope.of(context).unfocus();
    final aadhaar = aadhaarCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (aadhaar.isNotEmpty && aadhaar.length != 12) {
      return _err("Aadhaar number must be exactly 12 digits.");
    }
    return true; // Mostly optional data
  }

  // --- Step 3 Validations (Security) & Submits Form ---
  bool _validateStep3() {
    FocusScope.of(context).unfocus();
    final password = passwordCtrl.text;
    final confirmPassword = confirmPasswordCtrl.text;

    if (password.length < 6) {
      return _err("Password must be at least 6 characters.");
    }
    if (password != confirmPassword) return _err("Passwords do not match.");
    if (!acceptedTerms) {
      return _err("Please accept the terms of use and privacy policy.");
    }

    return true;
  }

  bool _err(String msg) {
    _showSnackbarError(msg);
    return false;
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      if (_validateStep3()) {
        await _handleSignup();
      }
    }
  }

  void _handlePrevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSignup() async {
    final mobile = mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final email = emailCtrl.text.trim().toLowerCase().isEmpty
        ? "pm_$mobile@parkingmudde.local"
        : emailCtrl.text.trim().toLowerCase();
    final fullName = "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}";

    setState(() => isLoading = true);

    final result = await ApiService.register(
      name: fullName,
      mobile: mobile,
      email: email,
      password: passwordCtrl.text,
      referralCode: referralCtrl.text.trim(),
      drivingLicenseNumber: drivingLicenseCtrl.text.trim(),
      aadhaarNumber: aadhaarCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      societyName: societyCtrl.text.trim(),
      tower: towerCtrl.text.trim(),
      flatNumber: flatCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result["success"] == true) {
      await ApiService.saveUserSession(result);
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("is_new_user", true);
      await prefs.setBool("pending_feature_walkthrough", true);

      setState(() => isLoading = false);

      Get.offAll(
        () => const ParkingOnboarding(
          fromAccountCreation: true,
          requireVehicleOnSuccess: true,
        ),
        transition: Transition.fadeIn,
      );
      return;
    }

    setState(() => isLoading = false);
    _showSnackbarError(result["message"] ?? "Registration failed.");
  }

  void _showSnackbarError(String message) {
    Get.snackbar(
      "Notice",
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      "Coming soon",
      "This integration will be available shortly.",
      backgroundColor: textBlack,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 12,
    );
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _showSnackbarError("Could not open this link.");
  }

  // ==== SOCIETY BOTTOM SHEET PICKER ====
  void _openSocietyBottomSheet() {
    FocusScope.of(context).unfocus(); // Clear Keyboard
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.75, // Sleek overlay ratio
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Select Society",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _societiesList.length + 1,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade200, height: 1),
                  itemBuilder: (ctx, idx) {
                    final isOther = (idx == _societiesList.length);
                    final name = isOther
                        ? "Other (Not listed)"
                        : _societiesList[idx]['name'].toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textBlack,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedSociety = name;
                          societyCtrl.text = isOther ? "" : name;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
              if (_currentStep > 0) {
                _handlePrevStep();
              } else if (Navigator.canPop(context)) {
                Get.back();
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 24.0, top: 18),
              child:
                  Text(
                    "Login instead",
                    style: const TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ).handleClick(() {
                    Get.off(
                      () => const Loginpage(),
                      transition: Transition.leftToRight,
                    );
                  }),
            ),
          ],
        ),

        // ---- The Footer Navigation Controller ----
        bottomNavigationBar: _buildStickyFooter(),

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroStepperHeader(),

              // Animated Page views housing different card segments
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disables finger drag navigation directly so validation runs natively via footers
                  children: [_buildStep1(), _buildStep2(), _buildStep3()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Layout Generators ---

  Widget _buildStickyFooter() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          10,
          24,
          MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              blurRadius: 40,
              spreadRadius: 30,
              offset: Offset(0, -30), // Ghost fades long scrolling forms
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _handlePrevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      child: const Text(
                        "Back",
                        style: TextStyle(
                          color: textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                if (_currentStep > 0) const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStep == 2
                                    ? "Complete Setup"
                                    : "Continue",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_currentStep < 2) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const ScreenSlogan(
              "Welcome! We've saved you a spot.",
              color: primaryBlue,
              icon: Icons.favorite_rounded,
              imagePath: 'assets/loginslogan.png',
              padding: EdgeInsets.zero,
              normalImageWidth: 92,
              compactImageWidth: 78,
              minHeight: 92,
              normalFontSize: 15.5,
              compactFontSize: 14,
              textMaxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStepperHeader() {
    // Array controls Header States
    const headings = ["Personal info", "ID Verification", "Secure Account"];
    const subs = [
      "We'd love to know your basics.",
      "Secured completely by ParkingMudde.",
      "Setup your neighborhood settings.",
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (idx) {
              final active = idx <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? primaryBlue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Text(
            headings[_currentStep],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: textBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subs[_currentStep],
            style: const TextStyle(
              fontSize: 14,
              color: subTextGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==== WIZARD SLIDES ====

  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social shortcuts sit firmly atop phase 1 reducing fatigue typing entries completely
          _buildCompactSocialLoginRow(),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _buildModernField(
                  label: "First name *",
                  hint: "E.g. Rahul",
                  controller: firstNameCtrl,
                  keyboardType: TextInputType.name,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernField(
                  label: "Last name *",
                  hint: "E.g. Sharma",
                  controller: lastNameCtrl,
                  keyboardType: TextInputType.name,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernField(
            label: "Mobile number *",
            hint: "10-digit number",
            icon: Icons.phone_android_rounded,
            controller: mobileCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernField(
            label: "Email ID",
            hint: "john@email.com (Optional)",
            icon: Icons.email_outlined,
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecureField(
            label: "Aadhaar number (Optional)",
            hint: "12-digit number",
            icon: Icons.badge_outlined,
            controller: aadhaarCtrl,
            keyboardType: TextInputType.number,
            maxLength: 12,
            isSecureCopy: true,
          ),
          const SizedBox(height: 24),
          _buildSecureField(
            label: "Driving license (Optional)",
            hint: "Enter DL number",
            icon: Icons.contact_mail_outlined,
            controller: drivingLicenseCtrl,
            textCapitalization: TextCapitalization.characters,
            isSecureCopy: true,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _openExternalLink(
                "https://sarathi.parivahan.gov.in/sarathiservice/stateSelection.do",
              ),
              child: const Text(
                "Can't find your DL info?",
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            height: 1.5,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          const SizedBox(height: 16),

          _buildModernField(
            label: "Friend's Referral Code",
            hint: "E.g. MUDDE-XYZ",
            icon: Icons.group_add_outlined,
            controller: referralCtrl,
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tap Triggering modern Society UI overlay
          const Text(
            "Society / Area Name",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: textBlack,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openSocietyBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: bgFillGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city_rounded,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _selectedSociety ?? "Select community from list",
                      style: TextStyle(
                        color: _selectedSociety != null
                            ? textBlack
                            : Colors.blueGrey.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.blueGrey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (_selectedSociety == "Other (Not listed)") ...[
            const SizedBox(height: 16),
            _buildModernField(
              label: "Enter manual name",
              hint: "Name of your area",
              controller: societyCtrl,
              textCapitalization: TextCapitalization.words,
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModernField(
                  label: "Tower",
                  hint: "T-2, Block A",
                  controller: towerCtrl,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernField(
                  label: "Flat",
                  hint: "No. 402",
                  controller: flatCtrl,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildPasswordField(
            label: "Create a Password *",
            hint: "min. 6 characters",
            controller: passwordCtrl,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            label: "Confirm Password *",
            hint: "Re-enter securely",
            controller: confirmPasswordCtrl,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),

          const SizedBox(height: 32),
          _buildTermsRow(),
        ],
      ),
    );
  }

  // --- Specialized Micro UI Modules ---

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: acceptedTerms,
            activeColor: primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(color: Colors.blueGrey.shade300, width: 2),
            onChanged: (value) =>
                setState(() => acceptedTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              children: [
                const Text(
                  "I consent & accept the application's ",
                  style: TextStyle(
                    color: subTextGrey,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Get.to(() => const Pageterm(tittle: 'Terms of Use')),
                  child: const Text(
                    "Terms of Service & Privacy Agreement.",
                    style: TextStyle(
                      color: textBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Renders Beautiful Fields strictly wiping standard boundaries unless typed over directly
  Widget _buildModernField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: textBlack,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.blueGrey, size: 20)
                : null,
            hintStyle: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: bgFillGrey,
            contentPadding: EdgeInsets.symmetric(
              horizontal: icon != null ? 0 : 16,
              vertical: 18,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Custom Build For Secure Vault Context UI Data
  Widget _buildSecureField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isSecureCopy = false,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textBlack,
              ),
            ),
            if (isSecureCopy)
              Row(
                children: const [
                  Icon(Icons.shield_rounded, color: Colors.green, size: 12),
                  SizedBox(width: 4),
                  Text(
                    "256-bit Secure",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: maxLength != null
              ? [LengthLimitingTextInputFormatter(maxLength)]
              : null,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: textBlack,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
            hintStyle: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: bgFillGrey,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: textBlack,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.blueGrey,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.blueGrey.shade400,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            hintStyle: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: bgFillGrey,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconSocialButton(
          icon: const _FallbackGoogleIcon(),
          color: Colors.white,
          borderC: Colors.grey.shade300,
          onTap: _showComingSoon,
        ),
        const SizedBox(width: 16),
        _iconSocialButton(
          icon: const Icon(Icons.facebook, color: Colors.white, size: 28),
          color: facebookBlue,
          borderC: facebookBlue,
          onTap: _showComingSoon,
        ),
        const SizedBox(width: 16),
        _iconSocialButton(
          icon: const Icon(Icons.apple_rounded, color: Colors.white, size: 30),
          color: Colors.black,
          borderC: Colors.black,
          onTap: _showComingSoon,
        ),
      ],
    );
  }

  Widget _iconSocialButton({
    required Widget icon,
    required Color color,
    required Color borderC,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        width: 85,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderC, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

// Ext Helper Widget extensions strictly binding gesture capabilities simply onto objects rendering text natively elsewhere
extension ActionClick on Widget {
  Widget handleClick(VoidCallback onTap) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: this,
    );
  }
}

class _FallbackGoogleIcon extends StatelessWidget {
  const _FallbackGoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "G",
        style: TextStyle(
          color: Color(0xFFDB4437),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
