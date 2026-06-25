import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class SuggestSocietyScreen extends StatefulWidget {
  const SuggestSocietyScreen({super.key});

  @override
  State<SuggestSocietyScreen> createState() => _SuggestSocietyScreenState();
}

class _SuggestSocietyScreenState extends State<SuggestSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _societyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _societyNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "";

    if (userId.isEmpty) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "User not found. Please log in again.");
      return;
    }

    bool success = await ApiService.suggestSociety(
      userId,
      _societyNameCtrl.text.trim(),
      _addressCtrl.text.trim(),
      _contactCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Get.snackbar(
        "Thank You!",
        "Your society has been suggested successfully. Our team will review it.",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Get.back();
      });
    } else {
      Get.snackbar(
        "Submission Failed",
        "There was an error submitting your suggestion. Please try again.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Suggest Society",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Is your society not listed?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Provide the details below and our team will get in touch to onboard your society.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Society Name Field
                _buildLabel("Society Name *"),
                TextFormField(
                  controller: _societyNameCtrl,
                  validator: (value) => value == null || value.isEmpty ? "Please enter society name" : null,
                  decoration: _inputDecoration("E.g. Green Valley Apartments"),
                ),
                const SizedBox(height: 20),

                // Address Field
                _buildLabel("Address & Pincode *"),
                TextFormField(
                  controller: _addressCtrl,
                  validator: (value) => value == null || value.isEmpty ? "Please enter address and pincode" : null,
                  maxLines: 3,
                  decoration: _inputDecoration("Enter full address and pincode"),
                ),
                const SizedBox(height: 20),

                // Contact Details Field
                _buildLabel("Contact Details *"),
                TextFormField(
                  controller: _contactCtrl,
                  validator: (value) => value == null || value.isEmpty ? "Please enter contact details" : null,
                  decoration: _inputDecoration("President/Admin contact number or email"),
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A5EE8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Submit Suggestion",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2A5EE8), width: 1.5),
      ),
    );
  }
}
