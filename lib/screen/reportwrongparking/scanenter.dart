import 'package:parkingmudde/screen/reportwrongparking/thankspagecall.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/plate_scanner_service.dart';
import 'package:parkingmudde/widgets/ad_banner.dart';
import 'package:parkingmudde/widgets/ad_banner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkingmudde/widgets/dynamic_ad_carousel.dart';

class VehicleNumberInputScreen extends StatefulWidget {
  final String? reportId;
  final String? notificationId;
  final bool isAttachingPlate;
  final bool guardPlateAttach;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  const VehicleNumberInputScreen({
    super.key,
    this.reportId,
    this.notificationId,
    this.isAttachingPlate = false,
    this.guardPlateAttach = false,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  @override
  State<VehicleNumberInputScreen> createState() =>
      _VehicleNumberInputScreenState();
}

class _VehicleNumberInputScreenState extends State<VehicleNumberInputScreen> {
  final PlateScannerService _plateScanner = PlateScannerService();
  bool isScanningPlate = false;

  // Primary Theme Extraction tied perfectly native visually mappings limits mappings map boundaries constraint map forms limit boundaries
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF1E212D);
  static const Color textDarkGrey = Color(0xFF4B5563);
  static const Color lightBlueBg = Color(0xFFEFF5FE);
  static const Color borderGrey = Color(0xFFD2D2D2);

  void _openSimplePlateEntryDialog({String? initialVehicleNumber}) {
    final TextEditingController _controller = TextEditingController(
      text: initialVehicleNumber,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Vehicle Number"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "e.g. MH01AB1234"),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: () {
                Get.back();
                _attachPlate(
                  _controller.text.replaceAll(" ", "").toUpperCase(),
                );
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Strict compliance to Camera Scan action preservation limits bound boundaries mapped constraint bounds limit boundary map maps limit map ---
  Future<void> _scanNumberPlateAction() async {
    if (isScanningPlate) return;

    setState(() => isScanningPlate = true);

    try {
      final result = await _plateScanner.scanFromCamera(context: context);

      if (!mounted || result == null) return;

      if (result.vehicleNumber.isEmpty) {
        Get.snackbar(
          "Plate Not Detected",
          "Try again with the plate centered and well lit.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // Format safely bounds standard layout mappings
      final cleanPlate = result.vehicleNumber.replaceAll(" ", "").toUpperCase();

      if (widget.isAttachingPlate &&
          (widget.reportId != null || widget.notificationId != null)) {
        _attachPlate(cleanPlate);
      } else {
        _openManualEntrySheet(initialVehicleNumber: cleanPlate);
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        "Scan Failed",
        "Camera text recognition could not read the plate. Please enter it manually.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      if (mounted) setState(() => isScanningPlate = false);
    }
  }

  Future<void> _attachPlate(String vehicleNumber) async {
    if (widget.reportId == null && widget.notificationId == null) {
      Get.snackbar(
        "Error",
        "Missing activity id. Please submit the proof again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.defaultDialog(
      title: "Attaching Plate",
      content: const CircularProgressIndicator(),
      barrierDismissible: false,
    );
    try {
      final result = widget.notificationId != null
          ? await ApiService.attachNotificationPlate(
              notificationId: widget.notificationId!,
              vehicleNumber: vehicleNumber,
            )
          : widget.guardPlateAttach
              ? await ApiService.attachGuardReportPlate(
                  reportId: widget.reportId!,
                  vehicleNumber: vehicleNumber,
                )
              : await ApiService.attachWrongParkingPlate(
                  reportId: widget.reportId!,
                  vehicleNumber: vehicleNumber,
                  razorpayOrderId: widget.razorpayOrderId,
                  razorpayPaymentId: widget.razorpayPaymentId,
                  razorpaySignature: widget.razorpaySignature,
                );
      if (Get.isDialogOpen == true) Get.back();

      if (result['success'] == true) {
        if (widget.isAttachingPlate) {
          final isRegistered = result['data']?['vehicle_registered'] == true;
          Get.back(result: isRegistered); // Return to ThankYouScreen
        } else {
          Get.offAll(() => ThankYouReportScreen(reportId: widget.reportId!));
        }
      } else {
        Get.snackbar(
          "Error",
          result['message'] ?? "Failed to attach plate",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Beautiful modern native bottom-sheet call layout forms
  void _openManualEntrySheet({String? initialVehicleNumber}) {
    if (widget.isAttachingPlate) {
      // If we are attaching plate, we don't open the issue selection sheet.
      // We open a simpler dialog to just enter the plate.
      _openSimplePlateEntryDialog(initialVehicleNumber: initialVehicleNumber);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _ManualVehicleEntrySheet(
          initialVehicleNumber: initialVehicleNumber,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors
            .white, // Exact stripped-down minimal form background mapping boundaries limits map constraint
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded, // Match exactly image boundaries
              color: textBlack,
              size: 24,
            ),
            onPressed: () => Get.offAll(() => const Dash()),
          ),
          title: const Text(
            "Report Wrong Parking",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textBlack,
              letterSpacing: 0.2,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFF3F4F6), height: 1.5),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. TOP INFORMATION CARD boundaries mapping layouts boundaries standard map forms boundary mapped constraints
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderGrey,
                          width: 1,
                        ), // Exact replica constraints limits map layouts mapping spaces forms boundaries
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Clear the way peacefully.\nWe'll notify the vehicle owner privately\nso they can resolve the issue quickly.",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                              color: textBlack,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: primaryBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Your phone number is never shared.",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textDarkGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. PRIMARY SCAN TRIGGER BOX spaces mappings map constraints bounds layout limits mapping maps bound space bounds mapping forms boundaries boundaries forms maps map mapping standard boundary
                    InkWell(
                      onTap: _scanNumberPlateAction,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderGrey, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Scan Vehicle Number",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textBlack,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Fast and accurate",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFDFE8FC,
                                ), // Perfectly identical visual limits layouts boundary layouts
                                shape: BoxShape.circle,
                              ),
                              child: isScanningPlate
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: primaryBlue,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: primaryBlue,
                                      size: 24,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 3. SECONDARY TEXT BUTTON FOR MANUAL TRIGGER
                    Center(
                      child: InkWell(
                        onTap: () => _openManualEntrySheet(),
                        child: const Text(
                          "Enter Vehicle Number Manually",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AdB2 — Sponsored banner
                    const DynamicAdCarousel(pageName: 'Scan'),

                    const Spacer(),

                    // 4. BOTTOM SAFETY DISCLOSURE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Only report genuine parking issues to keep the\ncommunity responsible",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              color: Color(0xFF9AA4B2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isScanningPlate) _loadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withOpacity(0.34),
          child: Center(
            child: Container(
              width: 250,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 34,
                    width: 34,
                    child: CircularProgressIndicator(
                      color: primaryBlue,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Reading number plate",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Checking the captured photo with the AI model...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
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
}

// ──────────────────────────────────────────────────────────
// MODAL BOTTOM SHEET WRAPPER FOR NATIVE INDIAN HSRP ENTRY! layout constraints limits map maps bound map forms limits constraint bounds forms
// ──────────────────────────────────────────────────────────

class _ManualVehicleEntrySheet extends StatefulWidget {
  final String? initialVehicleNumber;

  const _ManualVehicleEntrySheet({this.initialVehicleNumber});

  @override
  State<_ManualVehicleEntrySheet> createState() =>
      _ManualVehicleEntrySheetState();
}

class _ManualVehicleEntrySheetState extends State<_ManualVehicleEntrySheet> {
  final TextEditingController vehicleController = TextEditingController();
  final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

  static const List<Map<String, String>> _reportIssues = [
    // Section 1: Normal (No Header)
    // Strong AI Detection (Top of Section 1)
    {
      "code": "NO_PARKING_ZONE",
      "title": "Parked in No Parking zone",
      "group": "Supported",
    },
    {"code": "FOOTPATH", "title": "Parked on footpath", "group": "Supported"},
    {
      "code": "PEDESTRIAN_CROSSING",
      "title": "Parked on zebra crossing",
      "group": "Supported",
    },
    {
      "code": "BLOCKING_CAR_EXIT",
      "title": "Blocking my car / double parked",
      "group": "Supported",
    },
    {
      "code": "WRONG_SIDE",
      "title": "Parked on wrong side",
      "group": "Supported",
    },
    {
      "code": "BLOCKING_GATE",
      "title": "Blocking society entry/exit gate",
      "group": "Supported",
    },
    {
      "code": "BLOCKING_DRIVEWAY",
      "title": "Blocking driveway / ramp",
      "group": "Supported",
    },
    {
      "code": "TRAFFIC_JAM",
      "title": "Parking causing traffic jam",
      "group": "Supported",
    },
    // Weak AI Detection (Bottom of Section 1)
    {
      "code": "BLOCKING_FIRE_EXIT",
      "title": "Blocking fire exit",
      "group": "Weak",
    },
    {
      "code": "BLOCKING_AMBULANCE",
      "title": "Blocking ambulance access",
      "group": "Weak",
    },
    {
      "code": "BLOCKING_SHOP",
      "title": "Blocking shop entrance / shutter",
      "group": "Weak",
    },
    {
      "code": "BLOCKING_HOME",
      "title": "Parking in front of my house",
      "group": "Weak",
    },

    // Section 2: Will take longer
    // Coming Soon (AI cannot detect yet)
    {
      "code": "RESERVED_SPOT",
      "title": "Parked in my reserved spot",
      "group": "Coming Soon",
    },
    {
      "code": "HANDICAPPED_SLOT",
      "title": "Parked in handicapped slot",
      "group": "Coming Soon",
    },
    {
      "code": "EV_CHARGING_SPOT",
      "title": "Parked in EV charging spot",
      "group": "Coming Soon",
    },
  ];

  bool isValidVehicle = false;
  bool isPristine = true;
  bool isLookingUpVehicle = false;

  @override
  void initState() {
    super.initState();

    final initialNumber = widget.initialVehicleNumber
        ?.replaceAll(" ", "")
        .toUpperCase();
    if (initialNumber != null && initialNumber.isNotEmpty) {
      vehicleController.value = TextEditingValue(
        text: initialNumber,
        selection: TextSelection.collapsed(offset: initialNumber.length),
      );
      isPristine = false;
      isValidVehicle = vehicleRegex.hasMatch(initialNumber);
    }
  }

  @override
  void dispose() {
    vehicleController.dispose();
    super.dispose();
  }

  void _validateVehicle(String value) {
    final text = value.replaceAll(" ", "").toUpperCase();

    // Smooth internal validation updates limits layout layout mapped mapping boundaries limits forms forms limit boundaries layout layout map
    if (vehicleController.text != text) {
      vehicleController.value = vehicleController.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    setState(() {
      isPristine = false;
      isValidVehicle = vehicleRegex.hasMatch(text);
    });
  }

  Future<void> _onManualSubmit() async {
    if (!isValidVehicle) return;

    final vehicleNumber = vehicleController.text.toUpperCase();
    setState(() => isLookingUpVehicle = true);

    final result = await ApiService.lookupVehicleByNumber(vehicleNumber);
    if (!mounted) return;

    setState(() => isLookingUpVehicle = false);

    if (result["success"] == true && result["registered"] == true) {
      Get.back();
      _showReportIssueSelector(
        vehicleNumber: vehicleNumber,
        vehicleLookupData: result["data"] as Map<String, dynamic>?,
      );
      return;
    }

    if (result["registered"] == false) {
      Get.back();
      _showUnregisteredReportDialog(vehicleNumber);
      return;
    }

    Get.snackbar(
      "Lookup Failed",
      result["message"]?.toString() ??
          "Could not check this vehicle right now.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showReportIssueSelector({
    required String vehicleNumber,
    required Map<String, dynamic>? vehicleLookupData,
  }) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.78),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Select parking mudde",
              style: TextStyle(
                color: Color(0xFF1E212D),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Choose the issue you are facing before uploading proof.",
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _reportIssues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final issue = _reportIssues[index];
                  final showHeader =
                      index == 0 ||
                      _reportIssues[index - 1]["group"] != issue["group"];
                  final isComingSoon = issue["group"] == "Coming Soon";
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeader && isComingSoon) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            "Coming soon",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      InkWell(
                        onTap: () {
                          Get.back();
                          Get.to(
                            () => ReportProofScreen(
                              typev: "report",
                              vehicleNumber: vehicleNumber,
                              vehicleLookupData: vehicleLookupData,
                              selectedIssueTitle: issue["title"],
                              selectedIssueCode: issue["code"],
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isComingSoon
                                    ? Icons.access_time_rounded
                                    : Icons.report_problem_rounded,
                                color: isComingSoon
                                    ? Colors.orange
                                    : const Color(0xFF2A5EE8),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  issue["title"]!,
                                  style: const TextStyle(
                                    color: Color(0xFF1E212D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showUnregisteredReportDialog(String vehicleNumber) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Stuck with an unregistered vehicle?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "$vehicleNumber is not registered with ParkingMudde yet. You can invite the owner or use SOS if the parking issue is urgent.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
          TextButton(
            onPressed: () {
              Get.back();
              _showInviteVehicleOwnerSheet(vehicleNumber);
            },
            child: const Text("Invite Now"),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri(scheme: "tel", path: "100");
              await launchUrl(uri);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A5EE8),
              foregroundColor: Colors.white,
            ),
            child: const Text("SOS"),
          ),
        ],
      ),
    );
  }

  void _showInviteVehicleOwnerSheet(String vehicleNumber) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Invite vehicle owner",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E212D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Vehicle: $vehicleNumber",
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Vehicle owner name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: "Vehicle owner number",
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar(
                      "Thanks for helping",
                      "We will alert the vehicle owner when details are available.",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text("Don't have the details?"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final mobile = mobileController.text.trim();
                    if (!RegExp(
                      r'^[6-9][0-9]{9}$',
                    ).hasMatch(mobile.replaceAll(RegExp(r'[^0-9]'), ''))) {
                      Get.snackbar(
                        "Mobile required",
                        "Enter a valid 10-digit mobile number.",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    final ownerName = nameController.text.trim();
                    final message =
                        "Hi ${ownerName.isEmpty ? "there" : ownerName}, your vehicle $vehicleNumber was reported for a parking issue. Please join ParkingMudde to get private alerts and resolve parking muddes faster.";
                    final uri = Uri(
                      scheme: "sms",
                      path: mobile,
                      queryParameters: {"body": message},
                    );
                    await launchUrl(uri);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A5EE8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Alert Them Now"),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensures modal reacts beautifully and bounds tightly above phone virtual keyboards limits layout forms mappings limits layout limits
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Compresses to only show HSRP limit boundaries map map
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              widget.initialVehicleNumber == null
                  ? "Type Registration manually"
                  : "We read this number",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E212D),
              ),
            ),
            if (widget.initialVehicleNumber != null) ...[
              const SizedBox(height: 8),
              const Text(
                "Edit it if the camera made a mistake, then continue.",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
            SizedBox(height: widget.initialVehicleNumber == null ? 24 : 20),

            // --- NATIVE PRESERVED REPLICA OF INDIAN HSRP layout boundaries limit limit spaces map limits layouts mapping boundary
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPristine
                      ? Colors.grey.shade300
                      : (isValidVehicle
                            ? Colors.green.shade500
                            : Colors.redAccent.shade400),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(6),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            "IND",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: vehicleController,
                      onChanged: _validateVehicle,
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(11),
                      ],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "MH12AB1234",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade300,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      autofocus:
                          true, // Trigger instantly form constraint mapped layouts boundaries mapping maps boundary constraint form limits mapped constraint mapping layouts constraints limits boundaries boundaries boundaries limit bound boundaries mapping
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: vehicleController.text.isEmpty
                        ? const SizedBox.shrink()
                        : Icon(
                            isValidVehicle
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 20,
                            color: isValidVehicle
                                ? Colors.green.shade600
                                : Colors.redAccent.shade400,
                          ),
                  ),
                ],
              ),
            ),

            if (!isPristine && !isValidVehicle)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Ensure format matches valid RTO rules. (Ex: DL01AA1111)",
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ),

            const SizedBox(height: 32),

            // --- SUBMIT ACTION mapped mapping forms layouts standard map map space layout mapped form
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValidVehicle && !isLookingUpVehicle
                    ? _onManualSubmit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidVehicle
                      ? const Color(0xFF2A5EE8)
                      : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLookingUpVehicle
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Checking registration...",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Validate Number",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isValidVehicle
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
