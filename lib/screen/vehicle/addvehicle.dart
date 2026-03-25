import 'dart:convert';
import 'dart:typed_data'; // ✅ Required for Web Images

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/services/api_service.dart';

// ❌ DELETED: import 'dart:io'; (This causes the crash on Web)

class AddVehicleScreen extends StatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final dynamic edit;
  const AddVehicleScreen({super.key, this.edit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  int selectedVehicleType = 0;
  bool isOtpSent = false;
  final ImagePicker _picker = ImagePicker();

  // ✅ Use Uint8List instead of File
  List<Uint8List> galleryImages = []; 
  List<String> base64Images = [];
  
  // ✅ Variable to store RC Image
  Uint8List? rcImage;
  String? rcBase64;
  
  final regController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final vehicleTypes = ["2W", "4W", "Heavy"];
  var mobile = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.edit == "1" ? "Edit Vehicle" : "Add Vehicle",
          style: const TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(firstNameController, "Enter First Name*"),
            const SizedBox(height: 20),
            _buildTextField(lastNameController, "Enter Last Name*"),
            const SizedBox(height: 10),
            
            // --- Vehicle Type ---
            const Text("Vehicle Type"),
            const SizedBox(height: 10),
            Row(
              children: List.generate(vehicleTypes.length, (index) {
                final isSelected = selectedVehicleType == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedVehicleType = index),
                    child: Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0XFF184b8c) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vehicleTypes[index],
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),
            
            // --- SCAN RC SECTION (Fixed) ---
            const Text("Scan RC"),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                // Trigger RC Picker
                showImagePickerSheet(isRC: true);
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                  image: rcImage != null 
                    ? DecorationImage(image: MemoryImage(rcImage!), fit: BoxFit.cover)
                    : null
                ),
                child: rcImage == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner, size: 36),
                        SizedBox(height: 8),
                        Text("Tap to Upload RC Photo"),
                      ],
                    )
                  : Stack(
                      children: [
                         Positioned(
                           right: 5, top: 5,
                           child: CircleAvatar(
                             backgroundColor: Colors.white,
                             child: IconButton(
                               icon: const Icon(Icons.close, color: Colors.red),
                               onPressed: (){
                                 setState(() {
                                   rcImage = null;
                                   rcBase64 = null;
                                 });
                               },
                             ),
                           ),
                         )
                      ],
                  ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Registration Number"),
            const SizedBox(height: 8),
            _buildTextField(regController, "MH12AB1234", isCapital: true),

            const SizedBox(height: 20),
            const Text("Registered Mobile Number"),
            const SizedBox(height: 8),
            
            // --- Mobile Field ---
            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (val) {
                setState(() => mobile = val); // Updates UI for button
              },
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                labelText: "Registered Mobile Number",
                border: _borderStyle(),
                suffixIcon: mobile.length == 10
                    ? TextButton(
                        onPressed: () {
                          setState(() => isOtpSent = true);
                          Get.snackbar("OTP", "OTP Sent (Simulated)");
                        },
                        child: const Text("Send OTP"),
                      )
                    : null,
              ),
            ),

            // --- OTP Section ---
            if (isOtpSent) ...[
              const SizedBox(height: 15),
              const Text("Enter OTP"),
              const SizedBox(height: 10),
              PinFieldAutoFill(
                controller: otpController,
                codeLength: 6,
                decoration: BoxLooseDecoration(
                  strokeColorBuilder: const FixedColorBuilder(Color(0XFF184b8c)),
                  bgColorBuilder: const FixedColorBuilder(Colors.white),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // --- Image Upload (Web Compatible) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Upload Vehicle Image", style: TextStyle(color: Color(0XFF184b8c))),
                InkWell(
                  onTap: () => showImagePickerSheet(isRC: false),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0XFF184b8c)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.add, color: Color(0XFF184b8c)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            
            if (galleryImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: MemoryImage(galleryImages[index]), // ✅ Web Compatible
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 0,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                galleryImages.removeAt(index);
                                base64Images.removeAt(index);
                              });
                            },
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 12,
                              child: Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 40),

            // --- SUBMIT BUTTON (FIXED) ---
            Center(
              child: Material(
                color: const Color(0XFF184b8c), // Color on Material
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20), // Ripple shape
                  onTap: () async {
                    print("🔵 Submit Button Clicked");

                    // 1. Validate Form
                    if (firstNameController.text.isEmpty ||
                        lastNameController.text.isEmpty ||
                        regController.text.isEmpty ||
                        mobileController.text.isEmpty) {
                      Get.snackbar("Error", "Please fill all fields");
                      return;
                    }

                    // 2. Check User ID
                    final prefs = await SharedPreferences.getInstance();
                    String? userId = prefs.getString("user_id");
                    
                    if (userId == null) {
                      Get.snackbar("Error", "User not logged in");
                      return;
                    }

                    // 3. Call API
                    try {
                      final result = await ApiService.addVehicle(
                        userId: userId,
                        firstName: firstNameController.text.trim(),
                        lastName: lastNameController.text.trim(),
                        vehicleType: vehicleTypes[selectedVehicleType],
                        registrationNumber: regController.text.trim(),
                        registeredMobile: mobileController.text.trim(),
                        // Pass images here if your API supports it:
                        // images: base64Images
                        // rcImage: rcBase64
                      );

                      if (result != null && result["success"] == true) {
                        Get.snackbar("Success", "Vehicle Added Successfully");
                      } else {
                        Get.snackbar("Failed", result?["message"] ?? "Unknown Error");
                      }
                    } catch (e) {
                      print("🔴 API Error: $e");
                      Get.snackbar("Error", "Connection failed: $e");
                    }
                  },
                  child: Container(
                    width: 250,
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      widget.edit == "1" ? "Edit Vehicle" : "Add Vehicle",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextField(TextEditingController controller, String label, {bool isCapital = false}) {
    return TextFormField(
      controller: controller,
      textCapitalization: isCapital ? TextCapitalization.characters : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: _borderStyle(),
        enabledBorder: _borderStyle(),
        focusedBorder: _borderStyle(),
      ),
    );
  }

  OutlineInputBorder _borderStyle() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: const Color(0XFFff6f61).withOpacity(0.5)),
    );
  }

  // --- Image Picker (WEB SAFE) ---

  void showImagePickerSheet({required bool isRC}) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera, isRC: isRC);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery, isRC: isRC);
                },
              ),
            ],
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
        // ✅ CRITICAL FIX: Use readAsBytes() instead of File()
        // This works on both Web and Mobile
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
      print("Error picking image: $e");
    }
  }
}