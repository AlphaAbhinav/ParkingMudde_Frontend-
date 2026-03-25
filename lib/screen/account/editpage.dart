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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () {
            Get.back();
          },
        ),
        automaticallyImplyLeading: true,
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 👤 Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const NetworkImage("https://i.pravatar.cc/150")
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0XFF184b8c),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter First Name*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter Last Name*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),

              Align(
                alignment: AlignmentGeometry.topLeft,
                child: Text(
                  "Gender",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),

              // const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      activeColor: Color(0XFF184b8c),
                      title: const Text("Male"),
                      value: "Male",
                      groupValue: gender,
                      onChanged: (value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      activeColor: Color(0XFF184b8c),
                      title: const Text("Female"),
                      value: "Female",
                      groupValue: gender,
                      onChanged: (value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter Email*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),

              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter Mobile Number*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),

              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Address",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),
              TextFormField(
                onTap: _selectDob,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Date of Birth",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 30),
              InkWell(
                onTap: () {},
                child: Container(
                   height: 45,
                  decoration: BoxDecoration(
                    color: Color(0XFF184b8c),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Center(child: Text("Save Changes",style: TextStyle(color: Colors.white),)),
                ),
              ),

              SizedBox(height: 50),
              // 💾 Save Button
            ],
          ),
        ),
      ),
    );
  }
}
