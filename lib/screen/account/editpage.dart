import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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

  // ── Community state ──
  List<dynamic> _societies = [];
  String? _selectedSocietyId;
  String? _originalSocietyId;
  String? _originalResidentId;
  bool _isLoadingSocieties = true;
  bool _isLoadingCommunityStatus = true;
  Map<String, dynamic>? _communityStatus;
  bool isSendingCommunityRequest = false;
  final towerCtrl = TextEditingController();
  final flatCtrl = TextEditingController();

  // ── Contact state ──
  String originalAltNum = "";
  String originalEc1 = "";
  String originalEc2 = "";

  bool isAltVerified = false;
  bool isEc1Verified = false;
  bool isEc2Verified = false;

  String altSentOtp = "";
  String ec1SentOtp = "";
  String ec2SentOtp = "";

  String gender = "Male";

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSocieties();
  }

  Future<void> _loadSocieties() async {
    final response = await ApiService.getSocieties();
    if (mounted && response["success"] == true) {
      setState(() {
        _societies = response["societies"] ?? [];
        _isLoadingSocieties = false;
      });
    } else {
      if (mounted) setState(() => _isLoadingSocieties = false);
    }
  }

  Future<void> _loadProfile() async {
    final storedUser = await ApiService.getStoredUser();
    String? statusUserId;
    if (storedUser != null) {
      _fillProfileForm(storedUser);
      statusUserId = storedUser["user_id"]?.toString();
    }
    final user = await ApiService.refreshCurrentUser();
    if (!mounted) return;
    if (user != null) {
      _fillProfileForm(user);
      statusUserId = user["user_id"]?.toString();
    }
    if (statusUserId != null && statusUserId.isNotEmpty) {
      await _loadCommunityStatus(statusUserId);
    } else if (mounted) {
      setState(() => _isLoadingCommunityStatus = false);
    }
  }

  void _fillProfileForm(Map<String, dynamic> user) {
    final fullName = user["full_name"]?.toString() ?? "";
    final nameParts = fullName
        .trim()
        .split(RegExp(r"\s+"))
        .where((p) => p.isNotEmpty)
        .toList();
    setState(() {
      _userId = user["user_id"]?.toString();
      nameCtrl.text = nameParts.isNotEmpty ? nameParts.first : "";
      lNameCtrl.text = nameParts.length > 1 ? nameParts.skip(1).join(" ") : "";
      emailCtrl.text = user["email"]?.toString() ?? "";
      phoneCtrl.text = user["mobile_number"]?.toString() ?? "";
      addressCtrl.text = user["location"]?.toString() ?? "";
      dobCtrl.text = user["date_of_birth"]?.toString() ?? "";
      gender = user["gender"]?.toString().isNotEmpty == true
          ? user["gender"].toString()
          : gender;
      _storedProfileImage = user["profile_image"]?.toString();

      // Load backend-stored contacts
      final altNum = user["alternate_mobile_number"]?.toString() ?? "";
      final ec1 = user["emergency_contact_one"]?.toString() ?? "";
      final ec2 = user["emergency_contact_two"]?.toString() ?? "";
      if (altNum.isNotEmpty) {
        alternateNumberCtrl.text = altNum;
        originalAltNum = altNum;
      }
      if (ec1.isNotEmpty) {
        emergencyOneCtrl.text = ec1;
        originalEc1 = ec1;
      }
      if (ec2.isNotEmpty) {
        emergencyTwoCtrl.text = ec2;
        originalEc2 = ec2;
      }

      _originalSocietyId = user["society_id"]?.toString();
      _originalResidentId = user["resident_id"]?.toString();
      _selectedSocietyId = _originalSocietyId;
    });
    _loadLocalContacts();
  }

  bool _hasValue(dynamic value) {
    final text = value?.toString().trim();
    return text != null && text.isNotEmpty && text.toLowerCase() != "null";
  }

  bool _isPendingApprovalMessage(String? value) {
    final normalized = (value ?? "").toLowerCase();
    return normalized.contains("pending") ||
        normalized.contains("approval") ||
        normalized.contains("already applied") ||
        normalized.contains("already requested") ||
        normalized.contains("already waiting") ||
        normalized.contains("society request");
  }

  bool _communityStatusIsPending(Map<String, dynamic>? status) {
    final resident = status?["resident"] is Map
        ? Map<String, dynamic>.from(status!["resident"])
        : null;
    final hasCommunityRecord =
        status?["society"] != null || status?["resident"] != null;
    final hasStoredRequest =
        _hasValue(_originalSocietyId) || _hasValue(_originalResidentId);
    final linked = status?["linked"] == true;
    return !linked &&
        (hasStoredRequest ||
            hasCommunityRecord ||
            status?["pending"] == true ||
            resident?["status"]?.toString().toUpperCase() == "PENDING" ||
            _isPendingApprovalMessage(status?["message"]?.toString()));
  }

  Future<void> _loadCommunityStatus(String userId) async {
    if (mounted) setState(() => _isLoadingCommunityStatus = true);
    final status = await ApiService.getMyCommunity(userId);
    if (!mounted) return;
    final society = status["society"] is Map
        ? Map<String, dynamic>.from(status["society"])
        : null;
    final resident = status["resident"] is Map
        ? Map<String, dynamic>.from(status["resident"])
        : null;
    setState(() {
      _communityStatus = status;
      _isLoadingCommunityStatus = false;

      final societyId = society?["id"]?.toString();
      if (societyId != null && societyId.isNotEmpty) {
        _originalSocietyId = societyId;
        _selectedSocietyId = societyId;
      }

      final tower = resident?["tower"]?.toString() ?? "";
      final unitNumber = resident?["unit_number"]?.toString() ?? "";
      if (tower.isNotEmpty && towerCtrl.text.isEmpty) towerCtrl.text = tower;
      if (unitNumber.isNotEmpty && flatCtrl.text.isEmpty) {
        flatCtrl.text = unitNumber;
      }
    });
  }

  Future<void> _loadLocalContacts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (alternateNumberCtrl.text.isEmpty) {
        alternateNumberCtrl.text = prefs.getString("alternate_number") ?? "";
        originalAltNum = alternateNumberCtrl.text;
      }
      if (emergencyOneCtrl.text.isEmpty) {
        emergencyOneCtrl.text = prefs.getString("emergency_contact_one") ?? "";
        originalEc1 = emergencyOneCtrl.text;
      }
      if (emergencyTwoCtrl.text.isEmpty) {
        emergencyTwoCtrl.text = prefs.getString("emergency_contact_two") ?? "";
        originalEc2 = emergencyTwoCtrl.text;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 900,
        maxHeight: 900,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 3_700_000) {
        Get.snackbar(
          "Image Too Large",
          "Please choose a smaller profile photo.",
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return;
      }
      setState(() {
        _pickedProfileImage = image;
        _profileImageBytes = bytes;
      });
    } catch (_) {
      Get.snackbar(
        "Photo Not Selected",
        "Could not open this image.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectDob() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  // ── Generic: Verify OTP Removed ──

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId =
        _userId ?? (await SharedPreferences.getInstance()).getString("user_id");
    if (userId == null || userId.isEmpty) {
      Get.snackbar(
        "Error",
        "User not logged in.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final alternate = alternateNumberCtrl.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final ec1 = emergencyOneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final ec2 = emergencyTwoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Validate lengths
    for (final entry in {
      alternate: "Alternate number",
      ec1: "Emergency Contact I",
      ec2: "Emergency Contact II",
    }.entries) {
      if (entry.key.isNotEmpty &&
          !RegExp(
            r'^[6-9][0-9]{9}$',
          ).hasMatch(entry.key.replaceAll(RegExp(r'[^0-9]'), ''))) {
        Get.snackbar(
          "Invalid Contact",
          "${entry.value} must be 10 digits.",
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Check if changed contacts are verified
    if (alternate != originalAltNum && alternate.isNotEmpty && !isAltVerified) {
      Get.snackbar(
        "Verification Required",
        "Please verify Alternate Number with OTP.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }
    if (ec1 != originalEc1 && ec1.isNotEmpty && !isEc1Verified) {
      Get.snackbar(
        "Verification Required",
        "Please verify Emergency Contact I with OTP.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }
    if (ec2 != originalEc2 && ec2.isNotEmpty && !isEc2Verified) {
      Get.snackbar(
        "Verification Required",
        "Please verify Emergency Contact II with OTP.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
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
        _pickedProfileImage == null
            ? "Your profile details were saved successfully."
            : "Your profile photo and details were saved successfully.",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
      Get.back();
    } else {
      Get.snackbar(
        "Update Failed",
        result["message"] ?? "Could not update profile.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Manage Identity",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0XFF184B8C).withValues(alpha: 0.08),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : _storedProfileImageProvider(),
                        child:
                            _profileImageBytes == null &&
                                _storedProfileImageProvider() == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: Color(0XFF184B8C),
                                size: 44,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 10,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0XFF184b8c),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _sectionLabel("Personal Configuration"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      controller: nameCtrl,
                      label: "First Name*",
                      hint: "First name",
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFormField(
                      controller: lNameCtrl,
                      label: "Last Name*",
                      hint: "Last name",
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                "Identified Gender",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _genderPill("Male", Icons.male_rounded),
                  const SizedBox(width: 12),
                  _genderPill("Female", Icons.female_rounded),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              _sectionLabel("Communication Contact"),
              const SizedBox(height: 16),

              _buildFormField(
                controller: emailCtrl,
                label: "Verified Email Address*",
                hint: "user@domain.com",
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: phoneCtrl,
                label: "Mobile Primary Route*",
                hint: "+91 XXXX XXXX",
                icon: Icons.smartphone_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: addressCtrl,
                label: "Registered Base Address",
                hint: "Street Details, City",
                icon: Icons.maps_home_work_outlined,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: dobCtrl,
                label: "Recorded Date of Birth",
                hint: "Select Birth Calendar",
                icon: Icons.calendar_month_rounded,
                readOnly: true,
                onTap: _selectDob,
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              _sectionLabel("Alternate & Emergency Contacts"),
              const SizedBox(height: 4),
              Text(
                "All numbers are verified via OTP and stored securely.",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
              ),
              const SizedBox(height: 16),

              // ── Alternate Number ──
              _buildContactFieldWithOtp(
                controller: alternateNumberCtrl,
                otpController: altOtpCtrl,
                label: "Alternate Number",
                hint: "10-digit alternate mobile",
                icon: Icons.phone_iphone_rounded,
                originalNumber: originalAltNum,
                isVerified: isAltVerified,
                sentOtp: altSentOtp,
                onSendOtp: () => _sendOtp(
                  alternateNumberCtrl.text,
                  (otp) => setState(() => altSentOtp = otp),
                ),
                onVerifyOtp: () {
                  if (altOtpCtrl.text.trim() == altSentOtp &&
                      altSentOtp.isNotEmpty) {
                    setState(() {
                      isAltVerified = true;
                      altSentOtp = "";
                    });
                    Get.snackbar(
                      "Success",
                      "Alternate number verified",
                      backgroundColor: Colors.green.shade700,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      "Error",
                      "Invalid OTP",
                      backgroundColor: Colors.red.shade700,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Emergency Contact 1 ──
              _buildContactFieldWithOtp(
                controller: emergencyOneCtrl,
                otpController: emergencyOneOtpCtrl,
                label: "Emergency Contact I",
                hint: "10-digit emergency contact",
                icon: Icons.phone_in_talk_rounded,
                originalNumber: originalEc1,
                isVerified: isEc1Verified,
                sentOtp: ec1SentOtp,
                onSendOtp: () => _sendOtp(
                  emergencyOneCtrl.text,
                  (otp) => setState(() => ec1SentOtp = otp),
                ),
                onVerifyOtp: () {
                  if (emergencyOneOtpCtrl.text.trim() == ec1SentOtp &&
                      ec1SentOtp.isNotEmpty) {
                    setState(() {
                      isEc1Verified = true;
                      ec1SentOtp = "";
                    });
                    Get.snackbar(
                      "Success",
                      "Emergency Contact I verified",
                      backgroundColor: Colors.green.shade700,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      "Error",
                      "Invalid OTP",
                      backgroundColor: Colors.red.shade700,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Emergency Contact 2 ──
              _buildContactFieldWithOtp(
                controller: emergencyTwoCtrl,
                otpController: emergencyTwoOtpCtrl,
                label: "Emergency Contact II",
                hint: "10-digit emergency contact",
                icon: Icons.health_and_safety_rounded,
                originalNumber: originalEc2,
                isVerified: isEc2Verified,
                sentOtp: ec2SentOtp,
                onSendOtp: () => _sendOtp(
                  emergencyTwoCtrl.text,
                  (otp) => setState(() => ec2SentOtp = otp),
                ),
                onVerifyOtp: () {
                  if (emergencyTwoOtpCtrl.text.trim() == ec2SentOtp &&
                      ec2SentOtp.isNotEmpty) {
                    setState(() {
                      isEc2Verified = true;
                      ec2SentOtp = "";
                    });
                    Get.snackbar(
                      "Success",
                      "Emergency Contact II verified",
                      backgroundColor: Colors.green.shade700,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      "Error",
                      "Invalid OTP",
                      backgroundColor: Colors.red.shade700,
                      colorText: Colors.white,
                    );
                  }
                },
              ),

              const SizedBox(height: 40),

              // ── Link to Community ──
              _sectionLabel("Link to Community"),
              const SizedBox(height: 4),
              Text(
                "Select your society and enter flat details.",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
              ),
              const SizedBox(height: 16),
              _buildCommunitySection(),

              const SizedBox(height: 40),

              // ── Save Button ──
              InkWell(
                onTap: isSaving ? null : _onSave,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0XFF184B8C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0XFF184B8C).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSaving
                            ? "Synchronizing..."
                            : "Synchronize Registry Details",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.save_as_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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

  // OTP logic
  Future<void> _sendOtp(String mobile, Function(String) onOtpReceived) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanMobile)) {
      Get.snackbar(
        "Error",
        "Please enter a valid 10-digit mobile number.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final res = await ApiService.sendOtp(cleanMobile);
    Get.back();
    if (res["success"] == true) {
      String otp = res["otp_code"]?.toString() ?? res["otp"]?.toString() ?? "";
      if (otp.isNotEmpty) {
        Get.snackbar(
          "OTP Sent",
          "Your OTP is: $otp",
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.blue.shade800,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "OTP Sent",
          "OTP sent successfully to $cleanMobile",
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
        );
      }
      onOtpReceived(otp);
    } else {
      Get.snackbar(
        "Error",
        res["message"] ?? "Failed to send OTP",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildContactFieldWithOtp({
    required TextEditingController controller,
    required TextEditingController otpController,
    required String label,
    required String hint,
    required IconData icon,
    required String originalNumber,
    required bool isVerified,
    required String sentOtp,
    required VoidCallback onSendOtp,
    required VoidCallback onVerifyOtp,
  }) {
    final cleanText = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final bool isChanged = cleanText != originalNumber && cleanText.isNotEmpty;
    final bool needsVerification = isChanged && !isVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          controller: controller,
          label: label,
          hint: hint,
          icon: icon,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (val) {
            setState(() {
              // Reset verification if number changes again
              if (sentOtp.isNotEmpty || isVerified) {
                // If we want to strictly reset we can, but since the parent handles `isVerified` it will naturally become unverified because `cleanText != originalNumber`.
              }
            });
          },
        ),
        if (needsVerification) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  controller: otpController,
                  label: "Enter OTP",
                  hint: "OTP",
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: sentOtp.isEmpty ? onSendOtp : onVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sentOtp.isEmpty
                        ? const Color(0XFF184B8C)
                        : Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    sentOtp.isEmpty ? "Send OTP" : "Verify",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (isChanged && isVerified) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  "Verified",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommunitySection() {
    if (_isLoadingSocieties) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isLinked = _communityStatus?["linked"] == true;
    final isPending = _communityStatusIsPending(_communityStatus);
    final hasRequest =
        isLinked ||
        isPending ||
        (_originalSocietyId != null && _originalSocietyId!.isNotEmpty);
    final buttonLabel = isLinked
        ? "Update Community Details"
        : isPending
        ? "Request Pending"
        : hasRequest
        ? "Edit Request"
        : "Send Request";
    final selectedSocietyValue =
        _selectedSocietyId != null &&
            _societies.any((s) => s["id"]?.toString() == _selectedSocietyId)
        ? _selectedSocietyId
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingCommunityStatus) ...[
            _buildCommunityStatusCard(
              icon: Icons.sync_rounded,
              title: "Checking Society Status",
              message:
                  "We are checking whether your society request already exists.",
              color: const Color(0XFF184B8C),
            ),
            const SizedBox(height: 16),
          ] else if (isLinked) ...[
            _buildCommunityStatusCard(
              icon: Icons.verified_rounded,
              title: "Already Part of Society",
              message:
                  "Your community access is approved. You can manage visitors using this society profile.",
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 16),
          ] else if (isPending) ...[
            _buildCommunityStatusCard(
              icon: Icons.hourglass_top_rounded,
              title: "Society Request Pending",
              message:
                  "Society admin approval is pending. You can create visitor passes after approval.",
              color: Colors.orange.shade800,
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            "Select Society",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: selectedSocietyValue,
            items: _societies.map((s) {
              return DropdownMenuItem<String>(
                value: s["id"].toString(),
                child: Text(
                  s["name"].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: isPending
                ? null
                : (val) {
                    setState(() {
                      _selectedSocietyId = val;
                    });
                  },
            decoration: InputDecoration(
              hintText: "Select community",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.location_city_rounded,
                color: Colors.blueGrey.shade400,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0XFF184B8C),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  controller: towerCtrl,
                  label: "Tower / Block",
                  hint: "e.g. Tower A",
                  icon: Icons.business_rounded,
                  readOnly: isPending,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFormField(
                  controller: flatCtrl,
                  label: "Flat / Unit Number",
                  hint: "e.g. 101",
                  icon: Icons.door_front_door_rounded,
                  readOnly: isPending,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSendingCommunityRequest || isPending
                  ? null
                  : _submitCommunityRequest,
              icon: isSendingCommunityRequest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFF184B8C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStatusCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCommunityRequest() async {
    final userId =
        _userId ?? (await SharedPreferences.getInstance()).getString("user_id");
    if (userId == null || userId.isEmpty) return;

    final latestCommunityStatus = await ApiService.getMyCommunity(userId);
    if (!mounted) return;
    _communityStatus = latestCommunityStatus;
    if (_communityStatusIsPending(latestCommunityStatus)) {
      setState(() {});
      Get.snackbar(
        "Request Pending",
        "Your society request is already waiting for society admin approval.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedSocietyId == null) {
      Get.snackbar(
        "Missing Info",
        "Please select a community first.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }
    final tower = towerCtrl.text.trim();
    final unit = flatCtrl.text.trim();
    if (unit.isEmpty) {
      Get.snackbar(
        "Missing Info",
        "Flat / Unit Number is required.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSendingCommunityRequest = true);

    // Call update profile with just the community details
    final result = await ApiService.updateUserProfile(
      userId: userId,
      fullName: "${nameCtrl.text.trim()} ${lNameCtrl.text.trim()}".trim(),
      mobileNumber: phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      email: emailCtrl.text.trim().toLowerCase(),
      societyId: _selectedSocietyId,
      tower: tower,
      unitNumber: unit,
    );

    if (!mounted) return;
    setState(() => isSendingCommunityRequest = false);

    if (result["success"] == true) {
      setState(() {
        _originalSocietyId = _selectedSocietyId;
      });
      await _loadCommunityStatus(userId);
      Get.snackbar(
        "Success",
        "Community request sent to panel for approval.",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
      );
    } else {
      final errorMessage = (result["message"] ?? "Failed to send request.")
          .toString();
      final normalizedError = errorMessage.toLowerCase();
      final isPendingRequest =
          normalizedError.contains("pending") ||
          normalizedError.contains("approval") ||
          normalizedError.contains("already");
      if (isPendingRequest) {
        await _loadCommunityStatus(userId);
        Get.snackbar(
          "Request Pending",
          "Your society request is already waiting for society admin approval.",
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
        return;
      }
      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  ImageProvider? _storedProfileImageProvider() {
    final image = _storedProfileImage;
    if (image == null || image.isEmpty) return null;
    if (image.startsWith("data:image")) {
      return MemoryImage(base64Decode(image.split(",").last));
    }
    return NetworkImage(image);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    lNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    dobCtrl.dispose();
    alternateNumberCtrl.dispose();
    altOtpCtrl.dispose();
    emergencyOneCtrl.dispose();
    emergencyOneOtpCtrl.dispose();
    emergencyTwoCtrl.dispose();
    emergencyTwoOtpCtrl.dispose();
    towerCtrl.dispose();
    flatCtrl.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      color: Colors.blueGrey,
    ),
  );

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0XFF184B8C),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.redAccent.shade400,
                width: 1.5,
              ),
            ),
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
            border: Border.all(
              color: isSelected
                  ? const Color(0XFF184B8C)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0XFF184B8C).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
