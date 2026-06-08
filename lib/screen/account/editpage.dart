import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  Uint8List? _profileImageBytes;
  XFile? _pickedProfileImage;
  String? _storedProfileImage;
  String? _userId;
  bool isSaving = false;
  final picker = ImagePicker();

  // ── Controllers ──
  final nameCtrl = TextEditingController();
  final lNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final alternateNumberCtrl = TextEditingController();
  final altOtpCtrl = TextEditingController();
  final emergencyOneCtrl = TextEditingController();
  final emergencyOneOtpCtrl = TextEditingController();
  final emergencyTwoCtrl = TextEditingController();
  final emergencyTwoOtpCtrl = TextEditingController();

  // ── OTP state: Alternate Number ──
  bool _altOtpSent = false;
  bool _altVerified = false;
  bool _altOtpSending = false;
  bool _altOtpVerifying = false;
  String? _altSentTo;

  // ── OTP state: Emergency Contact 1 ──
  bool _ec1OtpSent = false;
  bool _ec1Verified = false;
  bool _ec1OtpSending = false;
  bool _ec1OtpVerifying = false;
  String? _ec1SentTo;

  // ── OTP state: Emergency Contact 2 ──
  bool _ec2OtpSent = false;
  bool _ec2Verified = false;
  bool _ec2OtpSending = false;
  bool _ec2OtpVerifying = false;
  String? _ec2SentTo;

  String gender = "Male";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final storedUser = await ApiService.getStoredUser();
    if (storedUser != null) _fillProfileForm(storedUser);
    final user = await ApiService.refreshCurrentUser();
    if (!mounted || user == null) return;
    _fillProfileForm(user);
  }

  void _fillProfileForm(Map<String, dynamic> user) {
    final fullName = user["full_name"]?.toString() ?? "";
    final nameParts = fullName.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    setState(() {
      _userId = user["user_id"]?.toString();
      nameCtrl.text = nameParts.isNotEmpty ? nameParts.first : "";
      lNameCtrl.text = nameParts.length > 1 ? nameParts.skip(1).join(" ") : "";
      emailCtrl.text = user["email"]?.toString() ?? "";
      phoneCtrl.text = user["mobile_number"]?.toString() ?? "";
      addressCtrl.text = user["location"]?.toString() ?? "";
      dobCtrl.text = user["date_of_birth"]?.toString() ?? "";
      gender = user["gender"]?.toString().isNotEmpty == true ? user["gender"].toString() : gender;
      _storedProfileImage = user["profile_image"]?.toString();

      // Load backend-stored contacts
      final altNum = user["alternate_mobile_number"]?.toString() ?? "";
      final ec1 = user["emergency_contact_one"]?.toString() ?? "";
      final ec2 = user["emergency_contact_two"]?.toString() ?? "";
      if (altNum.isNotEmpty) {
        alternateNumberCtrl.text = altNum;
        _altVerified = true; // already stored means previously verified
      }
      if (ec1.isNotEmpty) {
        emergencyOneCtrl.text = ec1;
        _ec1Verified = true;
      }
      if (ec2.isNotEmpty) {
        emergencyTwoCtrl.text = ec2;
        _ec2Verified = true;
      }
    });
    _loadLocalContacts();
  }

  Future<void> _loadLocalContacts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (alternateNumberCtrl.text.isEmpty) {
        alternateNumberCtrl.text = prefs.getString("alternate_number") ?? "";
      }
      if (emergencyOneCtrl.text.isEmpty) {
        emergencyOneCtrl.text = prefs.getString("emergency_contact_one") ?? "";
      }
      if (emergencyTwoCtrl.text.isEmpty) {
        emergencyTwoCtrl.text = prefs.getString("emergency_contact_two") ?? "";
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 65, maxWidth: 900, maxHeight: 900);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 3_700_000) {
        Get.snackbar("Image Too Large", "Please choose a smaller profile photo.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
        return;
      }
      setState(() { _pickedProfileImage = image; _profileImageBytes = bytes; });
    } catch (_) {
      Get.snackbar("Photo Not Selected", "Could not open this image.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  Future<void> _selectDob() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
    if (picked != null) dobCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
  }

  // ── Generic: Send OTP ──
  Future<void> _sendOtp({
    required TextEditingController numberCtrl,
    required Function(bool) setSending,
    required Function(String) onSuccess,
  }) async {
    final number = numberCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.length != 10) {
      Get.snackbar("Invalid Number", "Please enter a valid 10-digit number first.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }
    setSending(true);
    final res = await ApiService.sendOtp(number);
    setSending(false);
    if (res['success'] == true) {
      onSuccess(number);
      final displayOtp = res['otp']?.toString() ?? res['otp_code']?.toString();
      Get.snackbar(
        "OTP Sent ✅",
        displayOtp != null ? "OTP sent to $number. [Dev] OTP: $displayOtp" : "OTP sent to $number. Enter it below.",
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar("Failed to Send OTP", res['message'] ?? "Please try again.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  // ── Generic: Verify OTP ──
  Future<void> _verifyOtp({
    required TextEditingController otpCtrl,
    required String? sentTo,
    required Function(bool) setVerifying,
    required VoidCallback onSuccess,
  }) async {
    final otp = otpCtrl.text.trim();
    if (otp.length < 4 || sentTo == null) {
      Get.snackbar("Invalid OTP", "Please enter the OTP you received.", backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    setVerifying(true);
    final res = await ApiService.verifyOtp(sentTo, otp, '');
    setVerifying(false);
    if (res['success'] == true) {
      onSuccess();
      Get.snackbar("Number Verified ✅", "Your number $sentTo has been verified.", backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } else {
      Get.snackbar("Incorrect OTP", res['message'] ?? "Wrong OTP. Try again.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _userId ?? (await SharedPreferences.getInstance()).getString("user_id");
    if (userId == null || userId.isEmpty) {
      Get.snackbar("Error", "User not logged in.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    final alternate = alternateNumberCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final ec1 = emergencyOneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final ec2 = emergencyTwoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Validate lengths
    for (final entry in {alternate: "Alternate number", ec1: "Emergency Contact I", ec2: "Emergency Contact II"}.entries) {
      if (entry.key.isNotEmpty && entry.key.length != 10) {
        Get.snackbar("Invalid Contact", "${entry.value} must be 10 digits.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
        return;
      }
    }

    // Block save if unverified
    if (alternate.isNotEmpty && !_altVerified) {
      Get.snackbar("Verify Alternate Number", "Please verify your alternate number via OTP.", backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    if (ec1.isNotEmpty && !_ec1Verified) {
      Get.snackbar("Verify Emergency Contact I", "Please verify Emergency Contact I via OTP.", backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }
    if (ec2.isNotEmpty && !_ec2Verified) {
      Get.snackbar("Verify Emergency Contact II", "Please verify Emergency Contact II via OTP.", backgroundColor: Colors.orange.shade700, colorText: Colors.white);
      return;
    }

    final fullName = "${nameCtrl.text.trim()} ${lNameCtrl.text.trim()}".trim();
    setState(() => isSaving = true);

    final result = await ApiService.updateUserProfile(
      userId: userId,
      fullName: fullName,
      mobileNumber: phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      email: emailCtrl.text.trim().toLowerCase(),
      gender: gender,
      dateOfBirth: dobCtrl.text.trim(),
      location: addressCtrl.text.trim(),
      alternateMobileNumber: alternate,
      emergencyContactOne: ec1,
      emergencyContactTwo: ec2,
      profileImage: _pickedProfileImage,
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (result["success"] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("alternate_number", alternate);
      await prefs.setString("emergency_contact_one", ec1);
      await prefs.setString("emergency_contact_two", ec2);
      Get.snackbar(
        "Profile Updated",
        _pickedProfileImage == null ? "Your profile details were saved successfully." : "Your profile photo and details were saved successfully.",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
      Get.back();
    } else {
      Get.snackbar("Update Failed", result["message"] ?? "Could not update profile.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0XFF184B8C), size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text("Manage Identity",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.shade200, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Photo ──
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0XFF184B8C).withValues(alpha: 0.08)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : _storedProfileImageProvider(),
                        child: _profileImageBytes == null && _storedProfileImageProvider() == null
                            ? const Icon(Icons.person_rounded, color: Color(0XFF184B8C), size: 44)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 10,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0XFF184b8c), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _sectionLabel("Personal Configuration"),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _buildFormField(controller: nameCtrl, label: "First Name*", hint: "First name", icon: Icons.person_outline_rounded)),
                const SizedBox(width: 14),
                Expanded(child: _buildFormField(controller: lNameCtrl, label: "Last Name*", hint: "Last name", icon: Icons.badge_outlined)),
              ]),
              const SizedBox(height: 16),

              const Text("Identified Gender", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 8),
              Row(children: [_genderPill("Male", Icons.male_rounded), const SizedBox(width: 12), _genderPill("Female", Icons.female_rounded)]),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              _sectionLabel("Communication Contact"),
              const SizedBox(height: 16),

              _buildFormField(controller: emailCtrl, label: "Verified Email Address*", hint: "user@domain.com", icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildFormField(controller: phoneCtrl, label: "Mobile Primary Route*", hint: "+91 XXXX XXXX", icon: Icons.smartphone_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildFormField(controller: addressCtrl, label: "Registered Base Address", hint: "Street Details, City", icon: Icons.maps_home_work_outlined),
              const SizedBox(height: 16),
              _buildFormField(controller: dobCtrl, label: "Recorded Date of Birth", hint: "Select Birth Calendar", icon: Icons.calendar_month_rounded, readOnly: true, onTap: _selectDob),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              _sectionLabel("Alternate & Emergency Contacts"),
              const SizedBox(height: 4),
              Text("All numbers are verified via OTP and stored securely.", style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
              const SizedBox(height: 16),

              // ── Alternate Number ──
              _buildOtpVerifiedField(
                label: "Alternate Number",
                hint: "10-digit alternate mobile",
                icon: Icons.phone_iphone_rounded,
                numberCtrl: alternateNumberCtrl,
                otpCtrl: altOtpCtrl,
                isVerified: _altVerified,
                isOtpSent: _altOtpSent,
                isSending: _altOtpSending,
                isVerifying: _altOtpVerifying,
                onSendOtp: () => _sendOtp(
                  numberCtrl: alternateNumberCtrl,
                  setSending: (v) => setState(() => _altOtpSending = v),
                  onSuccess: (number) => setState(() { _altOtpSent = true; _altVerified = false; _altSentTo = number; altOtpCtrl.clear(); }),
                ),
                onVerify: () => _verifyOtp(
                  otpCtrl: altOtpCtrl,
                  sentTo: _altSentTo,
                  setVerifying: (v) => setState(() => _altOtpVerifying = v),
                  onSuccess: () => setState(() { _altVerified = true; _altOtpSent = false; }),
                ),
                onNumberChanged: () => setState(() { _altVerified = false; _altOtpSent = false; }),
              ),
              const SizedBox(height: 16),

              // ── Emergency Contact 1 ──
              _buildOtpVerifiedField(
                label: "Emergency Contact I",
                hint: "10-digit emergency contact",
                icon: Icons.phone_in_talk_rounded,
                numberCtrl: emergencyOneCtrl,
                otpCtrl: emergencyOneOtpCtrl,
                isVerified: _ec1Verified,
                isOtpSent: _ec1OtpSent,
                isSending: _ec1OtpSending,
                isVerifying: _ec1OtpVerifying,
                onSendOtp: () => _sendOtp(
                  numberCtrl: emergencyOneCtrl,
                  setSending: (v) => setState(() => _ec1OtpSending = v),
                  onSuccess: (number) => setState(() { _ec1OtpSent = true; _ec1Verified = false; _ec1SentTo = number; emergencyOneOtpCtrl.clear(); }),
                ),
                onVerify: () => _verifyOtp(
                  otpCtrl: emergencyOneOtpCtrl,
                  sentTo: _ec1SentTo,
                  setVerifying: (v) => setState(() => _ec1OtpVerifying = v),
                  onSuccess: () => setState(() { _ec1Verified = true; _ec1OtpSent = false; }),
                ),
                onNumberChanged: () => setState(() { _ec1Verified = false; _ec1OtpSent = false; }),
              ),
              const SizedBox(height: 16),

              // ── Emergency Contact 2 ──
              _buildOtpVerifiedField(
                label: "Emergency Contact II",
                hint: "10-digit emergency contact",
                icon: Icons.health_and_safety_rounded,
                numberCtrl: emergencyTwoCtrl,
                otpCtrl: emergencyTwoOtpCtrl,
                isVerified: _ec2Verified,
                isOtpSent: _ec2OtpSent,
                isSending: _ec2OtpSending,
                isVerifying: _ec2OtpVerifying,
                onSendOtp: () => _sendOtp(
                  numberCtrl: emergencyTwoCtrl,
                  setSending: (v) => setState(() => _ec2OtpSending = v),
                  onSuccess: (number) => setState(() { _ec2OtpSent = true; _ec2Verified = false; _ec2SentTo = number; emergencyTwoOtpCtrl.clear(); }),
                ),
                onVerify: () => _verifyOtp(
                  otpCtrl: emergencyTwoOtpCtrl,
                  sentTo: _ec2SentTo,
                  setVerifying: (v) => setState(() => _ec2OtpVerifying = v),
                  onSuccess: () => setState(() { _ec2Verified = true; _ec2OtpSent = false; }),
                ),
                onNumberChanged: () => setState(() { _ec2Verified = false; _ec2OtpSent = false; }),
              ),

              const SizedBox(height: 40),

              // ── Save Button ──
              InkWell(
                onTap: isSaving ? null : _onSave,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0XFF184B8C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0XFF184B8C).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSaving ? "Synchronizing..." : "Synchronize Registry Details",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.save_as_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable OTP-verified number field ──
  Widget _buildOtpVerifiedField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController numberCtrl,
    required TextEditingController otpCtrl,
    required bool isVerified,
    required bool isOtpSent,
    required bool isSending,
    required bool isVerifying,
    required VoidCallback onSendOtp,
    required VoidCallback onVerify,
    required VoidCallback onNumberChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
            if (isVerified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade300)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 12),
                    const SizedBox(width: 4),
                    Text("Verified", style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                readOnly: isVerified,
                onChanged: (_) { if (isVerified) onNumberChanged(); },
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  counterText: '',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: isVerified ? Colors.green.shade50 : Colors.white,
                  prefixIcon: Icon(icon, color: isVerified ? Colors.green.shade600 : Colors.blueGrey.shade400, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isVerified ? Colors.green.shade300 : Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0XFF184B8C), width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.redAccent.shade400, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (!isVerified)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isSending ? null : onSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF184B8C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isOtpSent ? "Resend" : "Send OTP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
          ],
        ),

        // OTP input row
        if (isOtpSent && !isVerified) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 6),
                  decoration: InputDecoration(
                    hintText: "Enter OTP",
                    counterText: '',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, letterSpacing: 0, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.blueGrey.shade400, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.orange.shade200, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.orange.shade600, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isVerifying
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Verify", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ImageProvider? _storedProfileImageProvider() {
    final image = _storedProfileImage;
    if (image == null || image.isEmpty) return null;
    if (image.startsWith("data:image")) return MemoryImage(base64Decode(image.split(",").last));
    return NetworkImage(image);
  }

  @override
  void dispose() {
    nameCtrl.dispose(); lNameCtrl.dispose(); emailCtrl.dispose();
    phoneCtrl.dispose(); addressCtrl.dispose(); dobCtrl.dispose();
    alternateNumberCtrl.dispose(); altOtpCtrl.dispose();
    emergencyOneCtrl.dispose(); emergencyOneOtpCtrl.dispose();
    emergencyTwoCtrl.dispose(); emergencyTwoOtpCtrl.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey));

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0XFF184B8C), width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.redAccent.shade400, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _genderPill(String title, IconData icon) {
    final bool isSelected = gender == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0XFF184B8C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? const Color(0XFF184B8C) : Colors.grey.shade300, width: 1.5),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0XFF184B8C).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.blueGrey),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
