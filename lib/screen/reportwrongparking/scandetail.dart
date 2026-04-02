import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingmudde/screen/reportwrongparking/thankspagecall.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class ReportProofScreen extends StatefulWidget {
  final String? typev;
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

  // Original Backend method 1
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
      imageQuality: 80, // Increased quality to prevent corruption
    );

    if (file == null) return;

    try {
      Uint8List bytes = await file.readAsBytes();

      if (mounted) {
        setState(() {
          images.add(file);
          imageBytes.add(bytes);
        });
      }
    } catch (e) {
      showSnack("Failed to load image. Please try again.");
    }
  }

  // Original Backend method 2
  Future<void> pickVideo() async {
    if (images.isNotEmpty) {
      showSnack("Remove images to upload video");
      return;
    }

    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;

    if (mounted) {
      setState(() => videoFile = file);
    }
  }

  // Modernized strictly floating graphical wrapper around existing scaffold context snackbar!
  void showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: msg.contains("successfully")
            ? Colors.green.shade800
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Original Backend Submit logic preserved explicitly
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
      capturedAt: DateTime.now().toString().split('.').first,
    );

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      // Refresh wallet balance using Provider
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
      backgroundColor: const Color(0xFFF6F8FA),
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
          widget.typev == "1" ? "Vehicle Details" : "Report Evidence",
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Top Evidence Header
                    const Text(
                      "Review & Attach",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Secure submission portal against wrong parking.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Information Readout Card
                    _offenderCard(),

                    const SizedBox(height: 28),

                    /// Upload Titles Section
                    const Row(
                      children: [
                        Icon(
                          Icons.perm_media,
                          color: Color(0XFF184B8C),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Upload Digital Proof",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: "Required: ",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "Upload 4 distinct photos (all angles) OR 1 full video showing layout limits.",
                            style: TextStyle(
                              color: Colors.blueGrey.shade500,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Premium Mode Actions & View Previews
                    _uploadActions(),

                    const SizedBox(height: 16),

                    /// Gallery output Views
                    if (images.isNotEmpty) _imagePreview(),
                    if (videoFile != null) _videoPreview(),

                    const SizedBox(height: 20),
                    const SizedBox(height: 30),

                    /// Solid Bottom Continuation Actions Block
                    _submitFooterBtn(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Very sleek summary module for offending info
  Widget _offenderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Tag heading bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.privacy_tip_rounded,
                  color: Colors.blueGrey,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Encrypted File Record",
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),

          /// Meat details area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.directions_car_rounded,
                  title: "Target Vehicle",
                  value: offenderData["vehicle"]!,
                  isHighlight: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                  child: Divider(color: Colors.grey.shade100, height: 12),
                ),

                _infoRow(
                  icon: Icons.person,
                  title: "Registered To",
                  value: offenderData["owner"]!,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                  child: Divider(color: Colors.grey.shade100, height: 12),
                ),

                _infoRow(
                  icon: Icons.phone_android_rounded,
                  title: "Contact Number",
                  value: offenderData["mobile"]!,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                  child: Divider(color: Colors.grey.shade100, height: 12),
                ),

                _infoRow(
                  icon: Icons.map_outlined,
                  title: "Location Area",
                  value: offenderData["area"]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlight
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isHighlight ? const Color(0XFF184B8C) : Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isHighlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }

  /// Big Touch Action Squares showing what state users are inside of smartly
  Widget _uploadActions() {
    bool hasMaxPhotos = images.length >= 4;
    bool photoModeBlocked = videoFile != null;
    bool videoModeBlocked = images.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: photoModeBlocked ? 0.4 : 1.0,
            child: _uploadButton(
              icon: Icons.add_a_photo_outlined,
              title: hasMaxPhotos ? "Limit Reached" : "Photos",
              subtitle: "${images.length}/4 chosen",
              colorTint: const Color(0XFF184B8C),
              onTap: pickImage,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: videoModeBlocked ? 0.4 : 1.0,
            child: _uploadButton(
              icon: Icons.video_call_outlined,
              title: videoFile != null ? "Video Applied" : "Record Video",
              subtitle: videoFile != null ? "Max lengths set" : "1 long clip",
              colorTint: Colors.green.shade600,
              onTap: pickVideo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color colorTint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: colorTint.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorTint.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorTint.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: colorTint),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Neat 2-per-row grid box arrangement for image selections
  Widget _imagePreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    imageBytes[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          images.removeAt(index);
                          imageBytes.removeAt(index);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "Angle ${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Very sleek wide media player thumb style video review tile
  Widget _videoPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage("https://picsum.photos/400/200?blur"),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      height: 140,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 16,
            child: Row(
              children: [
                const Icon(
                  Icons.movie_creation_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  videoFile!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => videoFile = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern fixed Super-App Submission Banner style
  Widget _submitFooterBtn() {
    bool hasPassedRequirements = (images.length == 4 || videoFile != null);

    return InkWell(
      onTap: isLoading
          ? null
          : submitReport, // Fires validation directly if tapped anyways exactly as originally authored!
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading
              ? Colors.grey.shade400
              : (hasPassedRequirements
                    ? const Color(0XFF184B8C)
                    : Colors.blueGrey.shade600),
          borderRadius: BorderRadius.circular(16),
          boxShadow: (isLoading || !hasPassedRequirements)
              ? []
              : [
                  BoxShadow(
                    color: const Color(0XFF184B8C).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Processing API Upload...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hasPassedRequirements
                          ? 'Transmit Proof Report'
                          : 'Incomplete Evidence Required',
                      style: TextStyle(
                        color: hasPassedRequirements
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
