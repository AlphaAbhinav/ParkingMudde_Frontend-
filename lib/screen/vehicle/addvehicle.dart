import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/services/api_service.dart';

class AddVehicleScreen extends StatefulWidget {
  final dynamic edit;
  const AddVehicleScreen({super.key, this.edit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  int selectedVehicleType = 0;
  bool isOtpSent = false;
  final ImagePicker _picker = ImagePicker();

  List<Uint8List> galleryImages = [];
  List<String> base64Images = [];

  Uint8List? rcImage;
  String? rcBase64;

  final regController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final vehicleTypes = ["2W", "4W", "Heavy"];
  var mobile = "";

  // Purely UI decorative maps linking with your strings seamlessly!
  final List<IconData> typeIcons = [
    Icons.motorcycle_rounded,
    Icons.directions_car_rounded,
    Icons.local_shipping_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Sleek, modern super-app silver base
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.edit == "1" ? "Edit Vehicle" : "Add Vehicle",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Vehicle Type Category"),
            const SizedBox(height: 12),

            /// ✨ Enhanced toggle pills using AnimatedContainers for sleek interaction
            Row(
              children: List.generate(vehicleTypes.length, (index) {
                final isSelected = selectedVehicleType == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedVehicleType = index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0XFF184B8C)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0XFF184B8C)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0XFF184B8C,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            typeIcons[index],
                            size: 28,
                            color: isSelected
                                ? Colors.white
                                : Colors.blueGrey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vehicleTypes[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blueGrey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),
            _sectionTitle("Registration Details"),
            const SizedBox(height: 12),

            /// ✨ HSRP Indian Vehicle Plate Styling exactly preserving logic/formatting restrictions
            _buildIndianLicensePlateField(),

            const SizedBox(height: 28),

            _sectionTitle("RC Card Identity (Smart Upload)"),
            const SizedBox(height: 12),

            /// ✨ Elevated Beautiful Droop-Zone
            InkWell(
              onTap: () => showImagePickerSheet(isRC: true),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: rcImage != null
                      ? Colors.white
                      : const Color(0XFF184b8c).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: rcImage != null
                        ? Colors.transparent
                        : const Color(0XFF184b8c).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: rcImage != null
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: rcImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0XFF184b8c).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              size: 28,
                              color: Color(0XFF184B8C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tap to capture or upload RC Image",
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Must be legible and not obstructed",
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(rcImage!, fit: BoxFit.cover),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2), // Light dim
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  rcImage = null;
                                  rcBase64 = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Document Scanned",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle("Owner Profiles Information"),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _modernFilledTextField(
                    firstNameController,
                    "First Name",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _modernFilledTextField(
                    lastNameController,
                    "Last Name",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Phone text input merged with verification status
            _modernFilledTextField(
              mobileController,
              "Mobile Registered Number",
              keyboard: TextInputType.phone,
              maxLengths: 10,
              onChangeFlow: (val) {
                setState(
                  () => mobile = val,
                ); // Existing precise state preservation
              },
              postfixExtn: mobile.length == 10
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOtpSent
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          setState(() => isOtpSent = true);
                          Get.snackbar(
                            "Authentication Link",
                            "Sent OTP temporarily disabled (Simulated environment execution)",
                            backgroundColor: Colors.blueGrey.shade800,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                          );
                        },
                        child: Text(
                          isOtpSent ? "Resend" : "Send OTP",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isOtpSent
                                ? Colors.green.shade700
                                : const Color(0XFF184B8C),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),

            if (isOtpSent) ...[
              const SizedBox(height: 12),
              PinFieldAutoFill(
                controller: otpController,
                codeLength: 6,
                decoration: BoxLooseDecoration(
                  strokeColorBuilder: FixedColorBuilder(Colors.grey.shade400),
                  bgColorBuilder: const FixedColorBuilder(Colors.white),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  gapSpace: 10,
                ),
                cursor: Cursor(color: Colors.black, enabled: true, width: 2),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Enter the secure authentication key you received above.",
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
            ],

            const SizedBox(height: 28),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Supporting Identifiers",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Upload extra vehicle shots (opt.)",
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => showImagePickerSheet(isRC: false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 16,
                          color: Color(0XFF184b8c),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Add Pic",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0XFF184B8C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (galleryImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 85,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              image: DecorationImage(
                                image: MemoryImage(
                                  galleryImages[index],
                                ), // Pure WEB SAFE
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  galleryImages.removeAt(index);
                                  base64Images.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 38),

            /// Original Function Button using highly styled wrapping!
            Material(
              color: const Color(0XFF184b8c),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  // --- Code identical to supplied Request Block Begins! --- //
                  print("🔵 Submit Button Clicked");

                  if (firstNameController.text.isEmpty ||
                      lastNameController.text.isEmpty ||
                      regController.text.isEmpty ||
                      mobileController.text.isEmpty) {
                    Get.snackbar(
                      "Error",
                      "Please fill all fields",
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  String? userId = prefs.getString("user_id");

                  if (userId == null) {
                    Get.snackbar("Error", "User not logged in");
                    return;
                  }

                  try {
                    final result = await ApiService.addVehicle(
                      userId: userId,
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      vehicleType: vehicleTypes[selectedVehicleType],
                      registrationNumber: regController.text.trim(),
                      registeredMobile: mobileController.text.trim(),
                      // images: base64Images
                      // rcImage: rcBase64
                    );
                    if (result != null && result["success"] == true) {
                      Get.snackbar(
                        "Success",
                        "Vehicle record persisted gracefully.",
                        backgroundColor: Colors.green.shade800,
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        "Failed",
                        result?["message"] ?? "Unknown Error",
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                    }
                  } catch (e) {
                    print("🔴 API Error: $e");
                    Get.snackbar("Error", "Connection failure processing: $e");
                  }
                  // --- Identical Code Concludes --- //
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0XFF184B8C).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.edit == "1"
                            ? "Update Profile Data"
                            : "Save Platform Vehicle",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 50),
          ],
        ),
      ),
    );
  }

  // --- Beautiful Minimal Design Component Wrappers --- //

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.blueGrey.shade900,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _modernFilledTextField(
    TextEditingController controller,
    String placeholder, {
    bool isCapital = false,
    TextInputType? keyboard,
    int? maxLengths,
    Widget? postfixExtn,
    Function(String)? onChangeFlow,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: isCapital
          ? TextCapitalization.characters
          : TextCapitalization.sentences,
      keyboardType: keyboard,
      maxLength: maxLengths,
      onChanged: onChangeFlow,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        hintText: placeholder,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.normal,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0XFF184B8C), width: 1.5),
        ),
        suffixIcon: postfixExtn,
      ),
    );
  }

  Widget _buildIndianLicensePlateField() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Beautiful Standard "IND" Sideplate identifier. Completely custom
          Container(
            width: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "IND",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Binds accurately identically avoiding complex input changes that could break legacy form behaviors
          Expanded(
            child: TextFormField(
              controller: regController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "MH12AB1234",
                hintStyle: TextStyle(
                  color: Colors.grey.shade300,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Strict compliance intact web picking components handling! ---

  void showImagePickerSheet({required bool isRC}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "Select Media Pipeline",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.blueAccent,
                    ),
                  ),
                  title: const Text(
                    'Capture Instantly (Camera)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(ImageSource.camera, isRC: isRC);
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text(
                    'Pick from Local Memory (Gallery)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(ImageSource.gallery, isRC: isRC);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source, {required bool isRC}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 30,
        maxWidth: 1920,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);

        setState(() {
          if (isRC) {
            rcImage = bytes;
            rcBase64 = base64;
          } else {
            galleryImages.add(bytes);
            base64Images.add(base64);
          }
        });
      }
    } catch (e) {
      print("Error picking image safely managed over UI interactions: $e");
    }
  }
}
