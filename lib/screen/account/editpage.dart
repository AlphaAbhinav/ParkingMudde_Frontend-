import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  File? _profileImage;
  final picker = ImagePicker();

  final nameCtrl = TextEditingController();
  final lNameCtrl =
      TextEditingController(); // Attached logically to match the split inputs cleanly!
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final dobCtrl = TextEditingController();

  String gender = "Male";

  Future<void> _pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Premium off-white super-app base
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
          onPressed: () {
            Get.back();
          },
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
              // ====== PREMIUM PROFILE PHOTO TRIGGER ====== //
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Focus ring glow layout
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0XFF184B8C).withOpacity(0.08),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const NetworkImage("https://i.pravatar.cc/150")
                                  as ImageProvider,
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

              const Text(
                "Personal Configuration",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 16),

              // ====== BEAUTIFIED ABSTRACTION INPUTS ====== //
              Row(
                children: [
                  Expanded(
                    child: _buildModernFormField(
                      controller: nameCtrl,
                      label: "First Name*",
                      hint: "John",
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildModernFormField(
                      controller: lNameCtrl,
                      label: "Last Name*",
                      hint: "Doe",
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ====== GENDER ELEGANT TOGGLES ====== //
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
                  _genderPillSelection("Male", Icons.male_rounded),
                  const SizedBox(width: 12),
                  _genderPillSelection("Female", Icons.female_rounded),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              const Text(
                "Communication Contact",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 16),

              _buildModernFormField(
                controller: emailCtrl,
                label: "Verified Email Address*",
                hint: "user@domain.com",
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildModernFormField(
                controller: phoneCtrl,
                label: "Mobile Primary Route*",
                hint: "+91 XXXX XXXX",
                icon: Icons.smartphone_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _buildModernFormField(
                controller: addressCtrl,
                label: "Registered Base Address",
                hint: "Street Details, City",
                icon: Icons.maps_home_work_outlined,
              ),
              const SizedBox(height: 16),

              _buildModernFormField(
                controller: dobCtrl,
                label: "Recorded Date of Birth",
                hint: "Select Birth Calendar",
                icon: Icons.calendar_month_rounded,
                readOnly: true,
                onTapTrigger: _selectDob,
              ),

              const SizedBox(height: 40),

              // ====== PRESERVED SECURE BUTTON DEPLOY ====== //
              InkWell(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    // Form handling natively safe
                    Get.snackbar(
                      "Changes Requested",
                      "Information synchronized successfully.",
                      backgroundColor: Colors.green.shade800,
                      colorText: Colors.white,
                      icon: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0XFF184B8C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0XFF184B8C).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Synchronize Registry Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.save_as_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 60,
              ), // Breathing layout offset buffer safely mapping into views
            ],
          ),
        ),
      ),
    );
  }

  /// Visually graceful extraction replacing the brutal identical copy/pasting. Ensures perfect scaling consistency natively!
  Widget _buildModernFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTapTrigger,
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
          onTap: onTapTrigger,
          keyboardType: keyboardType,
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

  /// Refined logic interface completely erasing the primitive visual representation of generic radios.
  Widget _genderPillSelection(String optionTitle, IconData iconValue) {
    bool isSelected = gender == optionTitle;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(
          () => gender = optionTitle,
        ), // Mapped inherently dynamically maintaining behavior!
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
                      color: const Color(0XFF184B8C).withOpacity(0.3),
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
                iconValue,
                size: 18,
                color: isSelected ? Colors.white : Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Text(
                optionTitle,
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
