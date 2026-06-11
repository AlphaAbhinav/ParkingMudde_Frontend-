import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/screen/pageterm/termpage.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePicturePage extends StatefulWidget {
  final bool requireVehicleOnSuccess;

  const ProfilePicturePage({super.key, this.requireVehicleOnSuccess = true});

  @override
  State<ProfilePicturePage> createState() => _ProfilePicturePageState();
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
  final picker = ImagePicker();
  Uint8List? _profileImageBytes;
  XFile? _pickedProfileImage;
  bool isUploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 65, maxWidth: 900, maxHeight: 900);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 3700000) {
        Get.snackbar("File too large", "Please choose a smaller profile photo.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
        return;
      }
      setState(() { _pickedProfileImage = image; _profileImageBytes = bytes; });
    } catch (_) {
      Get.snackbar("Error", "Could not open this image.", backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  void _skipOrNext() async {
    if (_pickedProfileImage != null) {
      setState(() => isUploading = true);
      // We need user ID and Name, but ApiService.updateUserProfile requires fullName. 
      // We can grab it from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final fullName = prefs.getString("full_name") ?? "User";
      final mobileNumber = prefs.getString("mobile_number") ?? "";
      final email = prefs.getString("email") ?? "";

      if (userId.isNotEmpty) {
        final res = await ApiService.updateUserProfile(
          userId: userId,
          fullName: fullName,
          mobileNumber: mobileNumber,
          email: email,
          profileImage: _pickedProfileImage,
        );
        if (res['success'] == true) {
          Get.snackbar("Success", "Profile photo uploaded!", backgroundColor: Colors.green.shade700, colorText: Colors.white);
        } else {
          Get.snackbar("Upload Failed", res['message'] ?? "Could not upload photo.", backgroundColor: Colors.orange.shade700, colorText: Colors.white);
        }
      }
      setState(() => isUploading = false);
    }

    if (widget.requireVehicleOnSuccess) {
      Get.offAll(() => const AddVehicleScreen(fromRegistration: true), transition: Transition.fadeIn);
    } else {
      Get.offAll(() => const Dash(fromRegistration: true), transition: Transition.fadeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: isUploading ? null : _skipOrNext,
            child: const Text("Skip", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Add a Profile Photo",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF184B8C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Let your community recognize you.\nYou can always change this later.",
                style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade400, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF184B8C).withValues(alpha: 0.08),
                          border: Border.all(color: const Color(0xFF184B8C).withValues(alpha: 0.2), width: 2),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                          child: _profileImageBytes == null
                              ? const Icon(Icons.add_a_photo_rounded, color: Color(0xFF184B8C), size: 50)
                              : null,
                        ),
                      ),
                      if (_profileImageBytes != null)
                        Positioned(
                          bottom: 0, right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF184B8C), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                            child: const Icon(Icons.edit, size: 20, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              ElevatedButton(
                onPressed: isUploading ? null : _skipOrNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF184B8C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: isUploading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _pickedProfileImage != null ? "Continue" : "I'll do it later",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
