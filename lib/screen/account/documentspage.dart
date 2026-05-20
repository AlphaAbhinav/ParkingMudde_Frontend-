import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleDocumentsPage extends StatefulWidget {
  const VehicleDocumentsPage({super.key});

  @override
  State<VehicleDocumentsPage> createState() => _VehicleDocumentsPageState();
}

class _VehicleDocumentsPageState extends State<VehicleDocumentsPage> {
  final ImagePicker picker = ImagePicker();
  final Map<String, String> documents = {};

  final List<Map<String, dynamic>> documentTypes = [
    {"title": "Registration Certificate", "icon": Icons.description_rounded},
    {"title": "Driving Licence", "icon": Icons.badge_rounded},
    {"title": "Insurance", "icon": Icons.verified_user_rounded},
    {"title": "Pollution Certificate", "icon": Icons.eco_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("vehicle_documents");
    if (saved == null || saved.isEmpty) return;

    final decoded = jsonDecode(saved) as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        documents
          ..clear()
          ..addAll(decoded.map((key, value) => MapEntry(key, value.toString())));
      });
    }
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("vehicle_documents", jsonEncode(documents));
  }

  Future<void> _pickDocument(String title) async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => documents[title] = base64Encode(bytes));
    await _saveDocuments();
  }

  Future<void> _removeDocument(String title) async {
    setState(() => documents.remove(title));
    await _saveDocuments();
  }

  void _openDocument(String title) {
    final encodedDocument = documents[title];
    if (encodedDocument == null || encodedDocument.isEmpty) return;

    try {
      final bytes = base64Decode(encodedDocument);
      Get.to(
        () => _DocumentPreviewPage(title: title, documentBytes: bytes),
      );
    } catch (_) {
      Get.snackbar(
        "Could not open document",
        "Please replace this document and try again.",
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
        title: const Text(
          "Vehicle Documents",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2A5EE8)),
          onPressed: Get.back,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Store vehicle-related documents here for quick access.",
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ...documentTypes.map(
            (doc) {
              final title = doc["title"].toString();
              final icon = doc["icon"] as IconData;
              final saved = documents.containsKey(title);
              return InkWell(
                onTap: saved ? () => _openDocument(title) : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: saved
                            ? const Color(0xFFF2FDF5)
                            : const Color(0xFFEBEEFB),
                        child: Icon(
                          saved ? Icons.check_rounded : icon,
                          color: saved
                              ? const Color(0xFF20C475)
                              : const Color(0xFF6678EF),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              saved
                                  ? "Stored on this device - tap to open"
                                  : "Not added yet",
                              style: TextStyle(
                                color: Colors.blueGrey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (saved)
                        IconButton(
                          onPressed: () => _openDocument(title),
                          icon: const Icon(
                            Icons.visibility_rounded,
                            color: Color(0xFF2A5EE8),
                          ),
                        ),
                      TextButton(
                        onPressed: () => _pickDocument(title),
                        child: Text(saved ? "Replace" : "Add"),
                      ),
                      if (saved)
                        IconButton(
                          onPressed: () => _removeDocument(title),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DocumentPreviewPage extends StatelessWidget {
  final String title;
  final List<int> documentBytes;

  const _DocumentPreviewPage({
    required this.title,
    required this.documentBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(
              Uint8List.fromList(documentBytes),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "This document could not be displayed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
