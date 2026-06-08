import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class VehicleDocumentsPage extends StatefulWidget {
  const VehicleDocumentsPage({super.key});

  @override
  State<VehicleDocumentsPage> createState() => _VehicleDocumentsPageState();
}

class _VehicleDocumentsPageState extends State<VehicleDocumentsPage> {
  final ImagePicker picker = ImagePicker();
  final Map<String, Map<String, dynamic>> documentsByType = {};

  String? userId;
  bool loading = true;
  String? savingType;

  final List<Map<String, dynamic>> documentTypes = [
    {
      "type": "aadhaar_card",
      "title": "Aadhaar Card",
      "icon": Icons.credit_card_rounded,
    },
    {
      "type": "driving_licence",
      "title": "Driving Licence",
      "icon": Icons.badge_rounded,
    },
    {
      "type": "registration_certificate",
      "title": "Registration Certificate",
      "icon": Icons.description_rounded,
    },
    {
      "type": "insurance_document",
      "title": "Insurance Document",
      "icon": Icons.verified_user_rounded,
    },
    {
      "type": "pollution_certificate",
      "title": "Pollution Certificate",
      "icon": Icons.eco_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final storedUser = await ApiService.getStoredUser();
    final currentUserId = storedUser?["user_id"]?.toString();

    if (currentUserId == null || currentUserId.isEmpty) {
      if (mounted) {
        setState(() {
          userId = null;
          loading = false;
        });
      }
      return;
    }

    final docs = await ApiService.getUserDocuments(currentUserId);
    if (!mounted) return;

    setState(() {
      userId = currentUserId;
      documentsByType
        ..clear()
        ..addEntries(
          docs.map(
            (doc) => MapEntry(
              doc["document_type"].toString(),
              Map<String, dynamic>.from(doc as Map),
            ),
          ),
        );
      loading = false;
    });
  }

  Future<void> _pickDocument(Map<String, dynamic> docType) async {
    final currentUserId = userId;
    if (currentUserId == null || currentUserId.isEmpty) {
      Get.snackbar(
        "Login required",
        "Please login again to upload your documents.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final type = docType["type"].toString();
    final title = docType["title"].toString();

    setState(() => savingType = type);
    final result = await ApiService.uploadUserDocument(
      userId: currentUserId,
      documentType: type,
      documentLabel: title,
      file: file,
    );

    if (!mounted) return;
    setState(() => savingType = null);

    if (result["success"] == true) {
      await _loadDocuments();
      Get.snackbar(
        "Document saved",
        "$title has been added to your account.",
        backgroundColor: const Color(0xFF20C475),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Upload failed",
        result["message"] ?? "Please try again.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeDocument(Map<String, dynamic> document) async {
    final currentUserId = userId;
    final documentId = document["id"]?.toString();
    if (currentUserId == null || documentId == null) return;

    final result = await ApiService.deleteUserDocument(
      userId: currentUserId,
      documentId: documentId,
    );

    if (result["success"] == true) {
      await _loadDocuments();
      Get.snackbar(
        "Document removed",
        "You can add it again anytime.",
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Could not remove",
        result["message"] ?? "Please try again.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  void _openDocument(Map<String, dynamic> document) {
    final dataUrl = document["data_url"]?.toString() ?? "";
    final commaIndex = dataUrl.indexOf(",");
    if (commaIndex == -1) {
      _showOpenError();
      return;
    }

    try {
      final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
      Get.to(
        () => _DocumentPreviewPage(
          title: document["document_label"]?.toString() ?? "Document",
          documentBytes: bytes,
        ),
      );
    } catch (_) {
      _showOpenError();
    }
  }

  void _showOpenError() {
    Get.snackbar(
      "Could not open document",
      "Please replace this document and try again.",
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Documents",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2A5EE8)),
          onPressed: Get.back,
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Add and keep your documents here for quick access. You can view, replace or remove them anytime.",
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (userId == null)
                    _messageCard(
                      icon: Icons.lock_outline_rounded,
                      title: "Login required",
                      subtitle: "Please login again to manage your documents.",
                    )
                  else
                    ...documentTypes.map(_documentTile),
                ],
              ),
            ),
    );
  }

  Widget _documentTile(Map<String, dynamic> docType) {
    final type = docType["type"].toString();
    final title = docType["title"].toString();
    final icon = docType["icon"] as IconData;
    final document = documentsByType[type];
    final saved = document != null;
    final saving = savingType == type;

    return Container(
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
            backgroundColor:
                saved ? const Color(0xFFF2FDF5) : const Color(0xFFEBEEFB),
            child: Icon(
              saved ? Icons.folder_rounded : icon,
              color:
                  saved ? const Color(0xFF20C475) : const Color(0xFF6678EF),
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
                  saved ? "Added - tap view to check" : "Not added yet",
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (saving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (saved)
              IconButton(
                tooltip: "View",
                onPressed: () => _openDocument(document),
                icon: const Icon(
                  Icons.visibility_rounded,
                  color: Color(0xFF2A5EE8),
                ),
              ),
            TextButton(
              onPressed: () => _pickDocument(docType),
              child: Text(saved ? "Replace" : "Add"),
            ),
            if (saved)
              IconButton(
                tooltip: "Remove",
                onPressed: () => _removeDocument(document),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2A5EE8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
