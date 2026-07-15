import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/auth/loginpage.dart';
import 'package:parkingmudde/screen/auth/otppage.dart';
import 'package:parkingmudde/screen/pageterm/termpage.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/screen/auth/permissionspage.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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

  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color labelGrey = Color(0xFF555555);
  static const Color subTextGrey = Color(0xFF999999);
  static const Color borderGrey = Color(0xFFD2D2D2);
  static const Color textBlack = Color(0xFF222222);

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
          _societiesList = List<Map<String, dynamic>>.from(res['societies'] ?? []);
        });
      }
    }
  }

  @override
  void dispose() {
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

  bool _validateForm() {
    FocusScope.of(context).unfocus();

    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final license = drivingLicenseCtrl.text.trim();
    final aadhaar = aadhaarCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final email = emailCtrl.text.trim().toLowerCase();
    final mobile = mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final password = passwordCtrl.text;
    final confirmPassword = confirmPasswordCtrl.text;

    if (firstName.isEmpty) {
      _showSnackbarError("Please enter your first name.");
      return false;
    }

    if (lastName.isEmpty) {
      _showSnackbarError("Please enter your last name.");
      return false;
    }



    if (aadhaar.isNotEmpty && aadhaar.length != 12) {
      _showSnackbarError("Aadhaar number must be 12 digits.");
      return false;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      _showSnackbarError("Please enter a valid email address.");
      return false;
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
      _showSnackbarError("Enter a valid 10-digit mobile number.");
      return false;
    }

    if (password.length < 6) {
      _showSnackbarError("Password must be at least 6 characters.");
      return false;
    }

    if (password != confirmPassword) {
      _showSnackbarError("Passwords do not match.");
      return false;
    }

    if (!acceptedTerms) {
      _showSnackbarError("Please accept the terms of use and privacy policy.");
      return false;
    }

    return true;
  }

  Future<void> _handleSignup() async {
    if (!_validateForm()) return;

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

        setState(() => isLoading = false);

        // BYPASS OTP COMPLETELY for testing
        final hasSeenPermissions = prefs.getBool("has_seen_permissions") ?? false;
        
        if (!hasSeenPermissions) {
          Get.offAll(() => const PermissionsPage(requireVehicleOnSuccess: true));
        } else {
          Get.offAll(() => const AddVehicleScreen(fromRegistration: true));
        }
        return;
      }

    setState(() => isLoading = false);
    _showSnackbarError(result["message"] ?? "Registration failed.");
  }

  void _showSnackbarError(String message) {
    Get.snackbar(
      "Validation Error",
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 10,
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      "Coming soon",
      "This integration will be available shortly.",
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 10,
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
              color: primaryBlue,
              size: 20,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) Get.back();
            },
          ),
          centerTitle: true,
          title: const Text(
            "Create an account",
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
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                _buildFigmaField(
                  label: "First name *",
                  hint: "Enter your first name",
                  controller: firstNameCtrl,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 18),
                _buildFigmaField(
                  label: "Last name *",
                  hint: "Enter your last name",
                  controller: lastNameCtrl,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 18),
                _buildFigmaField(
                  label: "Driving license",
                  hint: "Enter your driving license number",
                  controller: drivingLicenseCtrl,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 18),
                _buildFigmaField(
                  label: "Aadhaar number",
                  hint: "Enter Aadhaar number",
                  controller: aadhaarCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFigmaField(
                  label: "Email ID",
                  hint: "Enter email ID",
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Society name ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textBlack)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSociety,
                      hint: const Text("Select your society", style: TextStyle(color: subTextGrey, fontSize: 14)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderGrey, width: 1)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: primaryBlue),
                      items: [
                        ..._societiesList.map((soc) {
                          return DropdownMenuItem<String>(
                            value: soc['name'].toString(),
                            child: Text(soc['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          );
                        }),
                        const DropdownMenuItem<String>(
                          value: "Other",
                          child: Text("Other (Not listed)", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedSociety = val;
                          societyCtrl.text = val == "Other" ? "" : (val ?? "");
                        });
                      },
                    ),
                  ],
                ),
                if (_selectedSociety == "Other") ...[
                  const SizedBox(height: 16),
                  _buildFigmaField(
                    label: "Enter your society manually",
                    hint: "Type society name",
                    controller: societyCtrl,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildFigmaField(
                        label: "Tower",
                        hint: "Tower no.",
                        controller: towerCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFigmaField(
                        label: "Flat",
                        hint: "Flat no.",
                        controller: flatCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFigmaField(
                  label: "Mobile number *",
                  hint: "Enter your registered mobile number",
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Password ──
                _buildPasswordField(
                  label: "Password *",
                  hint: "Create a password (min 6 characters)",
                  controller: passwordCtrl,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 18),

                // ── Confirm Password ──
                _buildPasswordField(
                  label: "Confirm password *",
                  hint: "Re-enter your password",
                  controller: confirmPasswordCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 18),

                _buildFigmaField(
                  label: "Referral code",
                  hint: "Enter referral code if available",
                  controller: referralCtrl,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 18),
                _buildTermsRow(),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignup,
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
                            "Let's Signup",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: borderGrey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Or sign up with",
                        style: TextStyle(
                          color: subTextGrey.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: borderGrey)),
                  ],
                ),
                const SizedBox(height: 28),
                _SocialProviderButton(
                  text: "Continue with Google",
                  backgroundColor: Colors.white,
                  textColor: textBlack,
                  borderColor: borderGrey,
                  iconWidget: const _FallbackGoogleIcon(),
                  onTap: _showComingSoon,
                ),
                const SizedBox(height: 16),
                _SocialProviderButton(
                  text: "Continue with Facebook",
                  backgroundColor: facebookBlue,
                  textColor: Colors.white,
                  borderColor: Colors.transparent,
                  iconWidget:
                      const Icon(Icons.facebook, color: Colors.white, size: 24),
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
                const SizedBox(height: 42),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: labelGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.off(
                        () => const Loginpage(),
                        transition: Transition.leftToRight,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: acceptedTerms,
          activeColor: primaryBlue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (value) => setState(() => acceptedTerms = value ?? false),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Wrap(
              children: [
                const Text(
                  "I accept the ",
                  style: TextStyle(
                    color: labelGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Get.to(() => const Pageterm(tittle: 'Terms of Use')),
                  child: const Text(
                    "terms of use & privacy policy",
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
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

  Widget _buildFigmaField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
            color: labelGrey,
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
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderGrey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9AA4B2),
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
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
    return const SizedBox(
      height: 24,
      width: 24,
      child: Center(
        child: Text(
          "G",
          style: TextStyle(
            color: Color(0xFFDB4437),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

