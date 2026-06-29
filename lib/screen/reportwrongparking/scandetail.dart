import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart' as parkingmudde_scanenter;
import 'package:parkingmudde/screen/homepage/homepage.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingmudde/screen/reportwrongparking/thankspagecall.dart';
import 'package:parkingmudde/services/api_service.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:parkingmudde/services/razorpay_web_checkout.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class ReportProofScreen extends StatefulWidget {
  final String? typev;
  final String? vehicleNumber;
  final Map<String, dynamic>? vehicleLookupData;
  final String? selectedIssueTitle;
  final String? selectedIssueCode;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  const ReportProofScreen({
    super.key,
    this.typev,
    this.vehicleNumber,
    this.vehicleLookupData,
    this.selectedIssueTitle,
    this.selectedIssueCode,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  @override
  State<ReportProofScreen> createState() => _ReportProofScreenState();
}

class _ReportProofScreenState extends State<ReportProofScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController situationController = TextEditingController();

  List<XFile> images = [];
  List<Uint8List> imageBytes = [];
  XFile? videoFile;

  bool isLoading = false;

  late Razorpay _razorpay;
  bool _razorpayEventReceived = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }


  bool get _isHelpFlow => widget.typev == "help";
  bool get _isEmergencyFlow => widget.typev == "emergency";
  bool get _requiresSinglePhoto => _isHelpFlow || _isEmergencyFlow;
  String get _issueTitle {
    if (widget.selectedIssueTitle?.trim().isNotEmpty == true) {
      return widget.selectedIssueTitle!.trim();
    }
    if (_isHelpFlow) return "Parking error";
    if (_isEmergencyFlow) return "Emergency situation";
    return "Wrong parking issue";
  }

  static const List<String> _reportAngleLabels = [
    "Front",
    "Back",
    "Left",
    "Right",
  ];


  @override
  void dispose() {
    _razorpay.clear();
    situationController.dispose();
    super.dispose();
  }


  // Original Backend method 1
  Future<void> pickImage() async {
    if (videoFile != null) {
      showSnack("Remove video to upload images");
      return;
    }

    final maxImages = _requiresSinglePhoto ? 1 : 4;
    if (images.length >= maxImages) {
      showSnack(_requiresSinglePhoto ? "Only 1 photo is required" : "Maximum 4 images allowed");
      return;
    }

    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60, // Compressed for AI Model
      maxWidth: 1024,
      maxHeight: 1024,
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

    final XFile? file = await _picker.pickVideo(source: ImageSource.camera);

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
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _razorpayEventReceived = true;
    _finishSubmitReport(
      rOrderId: response.orderId,
      rPaymentId: response.paymentId,
      rSignature: response.signature,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _razorpayEventReceived = true;
    setState(() => isLoading = false);
    Get.defaultDialog(
      title: "Payment Failed",
      middleText: response.message ?? 'Payment was not completed or was cancelled.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _razorpayEventReceived = true;
    setState(() => isLoading = false);
    Get.defaultDialog(
      title: "External Wallet",
      middleText: 'Payment via ${response.walletName} selected.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  Future<void> _startRazorpayPayment(String currentUserId) async {
    await _finishSubmitReport(rOrderId: null, rPaymentId: null, rSignature: null);
    return;

    final orderResult = await ApiService.createReportRazorpayOrder(userId: currentUserId);
    
    if (!mounted) return;

    final razorpayOrderId = orderResult['razorpay_order_id']?.toString();
    final razorpayKeyId = orderResult['razorpay_key_id']?.toString();

    if (razorpayOrderId == null || razorpayOrderId.isEmpty || razorpayKeyId == null || razorpayKeyId.isEmpty) {
      setState(() => isLoading = false);
      Get.defaultDialog(
        title: "API Error",
        middleText: orderResult['message']?.toString() ?? 'Could not initiate payment from backend.',
        textConfirm: "OK",
        onConfirm: () => Get.back(),
      );
      return;
    }

    _razorpayEventReceived = false;
    final options = {
      'key': razorpayKeyId,
      'order_id': razorpayOrderId,
      'amount': orderResult['amount'],
      'currency': orderResult['currency'] ?? 'INR',
      'name': 'Parking Mudde',
      'description': 'Wrong Parking Report Fee',
      'prefill': {
        'contact': '9999999999',
        'email': 'payments@parkingmudde.com',
      },
      'retry': {'enabled': true, 'max_count': 1},
      'theme': {'color': '#184B8C'},
    };

    if (kIsWeb) {
      try {
        await openRazorpayWebCheckout(
          Map<String, dynamic>.from(options),
          onSuccess: (response) {
            _razorpayEventReceived = true;
            _finishSubmitReport(
              rOrderId: response['razorpay_order_id']?.toString(),
              rPaymentId: response['razorpay_payment_id']?.toString(),
              rSignature: response['razorpay_signature']?.toString(),
            );
          },
          onFailure: (message) {
            _razorpayEventReceived = true;
            setState(() => isLoading = false);
            Get.defaultDialog(
              title: "Payment Failed",
              middleText: message,
              textConfirm: "OK",
              onConfirm: () => Get.back(),
            );
          },
          onDismiss: () {
            _razorpayEventReceived = true;
            setState(() => isLoading = false);
          },
        );
      } catch (e) {
        setState(() => isLoading = false);
        Get.defaultDialog(
          title: "Payment Error",
          middleText: "Could not open Razorpay on web. Error: $e",
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => isLoading = false);
        Get.defaultDialog(
          title: "Plugin Error",
          middleText: "Razorpay error: $e",
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
      }
    });
  }

  Future<void> submitReport() async {
    if (isLoading) return;

    if (_isEmergencyFlow && _issueTitle.isEmpty && situationController.text.trim().isEmpty) {
      showSnack("Please specify the emergency situation");
      return;
    }

    if (_requiresSinglePhoto && images.isEmpty) {
      showSnack("Please upload 1 real-time photo proof");
      return;
    }

    if (!_requiresSinglePhoto && videoFile == null && images.length < 4) {
      showSnack("Please upload all 4 photos (front, back, left, right)");
      return;
    }

    setState(() {
      isLoading = true;
    });

    final storedUser = await ApiService.getStoredUser();
    final currentUserId = storedUser?["user_id"]?.toString();
    final targetVehicle = "";

    if (currentUserId == null || currentUserId.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showSnack("Session invalid. Please login again.");
      return;
    }

    await _finishSubmitReport(
      rOrderId: null,
      rPaymentId: null,
      rSignature: null,
    );
  }

  Future<void> _finishSubmitReport({String? rOrderId, String? rPaymentId, String? rSignature}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    final storedUser = await ApiService.getStoredUser();
    final currentUserId = storedUser?["user_id"]?.toString();
    final targetVehicle = (_isHelpFlow || _isEmergencyFlow) ? widget.vehicleNumber?.trim() ?? "" : "";

    Map<String, dynamic> result;
    if (_isEmergencyFlow) {
      result = await ApiService.createEmergencyAlertActivity(
        userId: currentUserId!,
        vehicleNumber: targetVehicle,
        situation: _issueTitle.isNotEmpty ? _issueTitle : situationController.text.trim(),
        location: "Not provided",
        image: images.isNotEmpty ? images.first : null,
      );
    } else if (_isHelpFlow) {
      result = await ApiService.createHelpedVehicleActivity(
        userId: currentUserId!,
        vehicleNumber: targetVehicle,
        image: images.isNotEmpty ? images.first : null,
        parkingError: _issueTitle,
        location: "Not provided",
      );
    } else {
      int? aiScore;
      String? aiVerdict;
      String? aiReasons;

      // Read real GPS coordinates from stored prefs
      final double reportLat = storedUser?["latitude"] as double? ?? 19.0760;
      final double reportLng = storedUser?["longitude"] as double? ?? 72.8777;

      result = await ApiService.createWrongParkingReport(
        vehicleNumber: targetVehicle,
        images: images,
        videoFile: videoFile,
        capturedAt: DateTime.now().toString().split('.').first,
        selectedIssue: _issueTitle,
        selectedIssueCode: widget.selectedIssueCode,
        aiScore: aiScore,
        aiVerdict: aiVerdict,
        aiReasons: aiReasons,
        lat: reportLat,
        lng: reportLng,
        razorpayOrderId: rOrderId,
        razorpayPaymentId: rPaymentId,
        razorpaySignature: rSignature,
      );
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      // Refresh wallet balance using Provider
      await context.read<WalletProvider>().fetchWallet();

      final reportId = result["data"] is Map
          ? result["data"]["report_id"]?.toString()
          : null;
      final notificationId = result["data"] is Map
          ? result["data"]["id"]?.toString()
          : null;
      final coinsCharged = result["coins_charged"] ?? 0;
      final coinsbackOnConfirm = result["coinsback_on_confirm"] ?? 0;
      final aiScoreRes = result["data"] is Map ? result["data"]["ai_score"] ?? 0 : 0;
      final aiVerdictRes = result["data"] is Map ? result["data"]["ai_verdict"] ?? "UNDER_REVIEW" : "UNDER_REVIEW";
      final aiReasonsRes = result["data"] is Map ? result["data"]["ai_reasons"] : null;

      Get.to(
        () => ThankYouReportScreen(
          typecv: widget.typev,
          reportId: reportId,
          notificationId: notificationId,
          coinsCharged: coinsCharged,
          coinsbackOnConfirm: coinsbackOnConfirm,
          aiScore: aiScoreRes,
          aiVerdict: aiVerdictRes,
          aiReasons: aiReasonsRes,
        ),
      );
    } else if (result["insufficient_coins"] == true) {
      // 402 — show rich dialog
      _showInsufficientCoinsDialog(result["message"] ?? "Not enough PM Coins.");
    } else {
      showSnack("❌ ${result['message']}");
    }
  }

  void _showInsufficientCoinsDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.orange.shade700, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "Insufficient PM Coins",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontSize: 13,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.back(); // Go back to home where wallet is accessible
                  },
                  icon: const Icon(Icons.add_card_rounded, color: Colors.white),
                  label: const Text("Top Up Wallet",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF184B8C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel",
                    style: TextStyle(color: Colors.blueGrey.shade400)),
              ),
            ],
          ),
        ),
      ),
    );
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
          widget.typev == "help"
              ? "Helping Evidence"
              : widget.typev == "emergency"
              ? "Emergency Evidence"
              : "Report Evidence",
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
      body: Stack(
        children: [
          LayoutBuilder(
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
                    Text(
                      _isEmergencyFlow ? "Emergency Details" : "Review & Attach",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEmergencyFlow
                          ? "Add a photo and specify the victim situation."
                          : _isHelpFlow
                          ? "Add 1 photo proof of the parking error."
                          : "Upload proof from 4 sides. This keeps reporting fair.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),


                    _selectedIssueCard(),

                    const SizedBox(height: 28),

                    if (_isEmergencyFlow) ...[
                      const Text(
                        "Situation Specification",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: situationController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Describe the accident or emergency condition",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

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
                            text: _requiresSinglePhoto
                                ? "Upload 1 real-time photo proof."
                                : "Capture Front, Back, Left and Right photos OR 1 clear video.",
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
          if (isLoading) _requestLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _requestLoadingOverlay() {
    final isHelp = widget.typev == "help";

    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withOpacity(0.34),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(
                      color: Color(0XFF184B8C),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHelp ? "Submitting help request" : "Submitting report",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    isHelp
                        ? "Notifying the vehicle owner privately..."
                        : "Uploading proof and checking the request...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedIssueCard() {
    final isHelp = _isHelpFlow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHelp ? const Color(0xFFF2F0FF) : const Color(0xFFEFF5FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHelp ? const Color(0xFFCEC9FF) : const Color(0xFFC8D8F6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHelp ? Icons.handshake_rounded : Icons.report_problem_rounded,
            color: isHelp ? const Color(0xFF4C42ED) : const Color(0XFF184B8C),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHelp ? "Selected parking error" : "Selected report issue",
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _issueTitle,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Very sleek summary module for offending info
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
    bool hasMaxPhotos = images.length >= (_requiresSinglePhoto ? 1 : 4);
    bool photoModeBlocked = videoFile != null;
    bool videoModeBlocked = images.isNotEmpty || _requiresSinglePhoto;

    return Row(
      children: [
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: photoModeBlocked ? 0.4 : 1.0,
            child: _uploadButton(
              icon: Icons.add_a_photo_outlined,
              title: hasMaxPhotos
                  ? "Limit Reached"
                  : (_requiresSinglePhoto
                      ? "Capture Proof"
                      : "Capture ${_reportAngleLabels[images.length]}"),
              subtitle: "${images.length}/${_requiresSinglePhoto ? 1 : 4} captured",
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
              title: videoFile != null ? "Video Captured" : "Record Video",
              subtitle: videoFile != null ? "Ready to submit" : "1 clear clip",
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
                      _requiresSinglePhoto
                          ? "Proof"
                          : _reportAngleLabels[index],
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
    bool hasPassedRequirements = _requiresSinglePhoto
        ? images.isNotEmpty &&
            (!_isEmergencyFlow || situationController.text.trim().isNotEmpty)
        : (images.length == 4 || videoFile != null);

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
                          ? _isEmergencyFlow
                                ? 'Send Emergency Alert'
                                : _isHelpFlow
                                ? 'Send Helping Alert'
                                : 'Submit & Alert Owner'
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
