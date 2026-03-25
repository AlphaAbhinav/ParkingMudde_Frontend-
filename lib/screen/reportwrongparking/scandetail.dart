import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingmudde/screen/reportwrongparking/thankspagecall.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class ReportProofScreen extends StatefulWidget {
  final typev;
  const ReportProofScreen({super.key, this.typev});

  @override
  State<ReportProofScreen> createState() => _ReportProofScreenState();
}

class _ReportProofScreenState extends State<ReportProofScreen> {
  final ImagePicker _picker = ImagePicker();

  List<XFile> images = [];
  List<Uint8List> imageBytes = [];
  XFile? videoFile;

  bool isLoading = false;

  final offenderData = {
    "vehicle": "MH12**1234",
    "owner": "R**** S****",
    "mobile": "+91 ******4321",
    "area": "Andheri East, Mumbai",
  };

  Future<void> pickImage() async {
    if (videoFile != null) {
      showSnack("Remove video to upload images");
      return;
    }

    if (images.length >= 4) {
      showSnack("Maximum 4 images allowed");
      return;
    }

    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (file == null) return;

    Uint8List bytes = await file.readAsBytes();

    setState(() {
      images.add(file);
      imageBytes.add(bytes);
    });
  }

  Future<void> pickVideo() async {
    if (images.isNotEmpty) {
      showSnack("Remove images to upload video");
      return;
    }

    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;

    setState(() => videoFile = file);
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =========================
  // Submit Report
  // =========================
  Future<void> submitReport() async {
    if (videoFile == null && images.length < 4) {
      showSnack("Please upload all 4 photos (front, back, left, right)");
      return;
    }

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> result = await ApiService.createWrongParkingReport(
      vehicleNumber: "MH12AB1234",
      images: images,
      videoFile: videoFile,
    );

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {

      // 🔹 Refresh wallet balance using Provider
      await context.read<WalletProvider>().fetchWallet();

      showSnack("Report submitted successfully");

      Get.to(() => ThankYouReportScreen(typecv: widget.typev));

    } else {

      showSnack("❌ ${result['message']}");

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.typev == "1" ? "Vehicle detail" : "Report Vehicle",
          style: const TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _offenderCard(),
            const SizedBox(height: 24),
            const Text(
              "Upload Proof",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Upload up to 4 photos OR 1 video (max 30 MB)",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _uploadActions(),
            const SizedBox(height: 20),
            if (images.isNotEmpty) _imagePreview(),
            if (videoFile != null) _videoPreview(),
            const SizedBox(height: 40),

            Center(
              child: InkWell(
                onTap: isLoading ? null : submitReport,
                child: Container(
                  height: 45,
                  width: 250,
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey : const Color(0XFF184b8c),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offenderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Offender Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _infoRow("Vehicle", offenderData["vehicle"]!),
          _infoRow("Owner", offenderData["owner"]!),
          _infoRow("Mobile", offenderData["mobile"]!),
          _infoRow("Area", offenderData["area"]!),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value),
        ],
      ),
    );
  }

  Widget _uploadActions() {
    return Row(
      children: [
        Expanded(
          child: _uploadButton(icon: Icons.camera_alt, title: "Photo", onTap: pickImage),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _uploadButton(icon: Icons.videocam, title: "Video", onTap: pickVideo),
        ),
      ],
    );
  }

  Widget _uploadButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0XFF184b8c)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0XFF184b8c)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(imageBytes.length, (index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes[index],
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() {
                  images.removeAt(index);
                  imageBytes.removeAt(index);
                }),
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _videoPreview() {
    return ListTile(
      leading: const Icon(Icons.videocam, color: Colors.green),
      title: const Text("Video Selected"),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => setState(() => videoFile = null),
      ),
    );
  }
}