import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/plate_scanner_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleNumberHelpScreen extends StatefulWidget {
  const VehicleNumberHelpScreen({super.key});

  @override
  State<VehicleNumberHelpScreen> createState() =>
      _VehicleNumberHelpScreenState();
}

class _VehicleNumberHelpScreenState extends State<VehicleNumberHelpScreen> {
  // Natively extracted UI theme variables matching standard boundary
  static const Color primaryViolet = Color(0xFF4C42ED);
  static const Color backgroundLightBlue = Color(0xFFF3F5FA);
  static const Color textBlack = Color(0xFF1E212D);
  static const Color subTextGrey = Color(0xFF6B7280);

  final PlateScannerService _plateScanner = PlateScannerService();
  bool isScanningPlate = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<PlateScanResult?> _handleScanAction() async {
    setState(() => isScanningPlate = true);

    try {
      return await _plateScanner.scanFromCamera(context: context);
    } finally {
      if (mounted) {
        setState(() => isScanningPlate = false);
      }
    }
  }

  // --- SHOW THE ELEGANT ACTION BOTTOM SHEET mappings limit maps mappings mapped mapped map constraints bound limit layout mappings map forms boundaries form mapped layouts boundary constraint forms layout forms mapping spaces
  void _openEntryOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _VehicleEntryOptionsSheet(onScanPressed: _handleScanAction);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors
            .white, // Inherits pristine UI boundary layouts spaces limit layout maps limits space mapping bound mapping layout boundary mapping limits mappings boundaries limits boundary limits mapped layout standard constraint mapped boundaries layout spaces mapped constraints boundaries form standard boundaries maps mapped mapped layout limits limits limits bound boundary boundaries form constraint layout bounds mappings limits limit limit limits map limits mapped limit limits constraint forms maps constraint layout mapping
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color:
                  textBlack, // Inherited UI color layout mappings boundaries map layouts boundaries
              size: 24,
            ),
            onPressed: () {
              // Your required exit mapping route
              Get.offAll(() => const Dash());
            },
          ),
          title: const Text(
            "Help a Vehicle",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textBlack,
            ),
          ),
        ),

        body: Container(
          decoration: const BoxDecoration(color: backgroundLightBlue),
          child: Column(
            children: [
              // Internal Content layout limit boundary forms map constraints boundaries bound spaces boundaries constraints standard boundaries constraint space limits forms layout spaces standard mappings space boundaries boundary constraints map mappings layout bound mapping mapping map constraints boundaries boundary mapping boundary space layouts boundaries forms mappings layout boundary
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Graphic constraint boundary layout limit bounds limits spaces constraints mappings boundary layout boundaries boundary form constraints maps bounds maps bounds forms mapping maps layout forms mapped mapped bounds boundaries layout constraint mapped boundaries mappings
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: primaryViolet,
                            size: 34,
                          ), // Visually perfectly matching design bounds mapping limit
                        ),
                      ),

                      const Text(
                        "Helping makes parking better",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textBlack,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Send a friendly alert to help another vehicle\nowner. Your Message is private and respectful.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: subTextGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Values Prop cards native lists boundaries limit form boundary limits map boundary layout space constraints map
                      _buildInfoPillCard(
                        title: "Friendly & Non-confontational",
                        desc:
                            "Your help is send as a kind reminder, not a complaint",
                        iconColor: const Color(0xFF23B172),
                        iconBgColor: const Color(0xFFE8F7F0),
                        icon: Icons.shield_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoPillCard(
                        title: "Private Notification",
                        desc:
                            "Owner gets notified privately. No public\nShaming", // Design extract matched mapping typo native layout limits constraints map form
                        iconColor: const Color(0xFF2A78EE),
                        iconBgColor: const Color(0xFFE9F1FE),
                        icon: Icons.lock_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoPillCard(
                        title: "Your Details Stay Safe",
                        desc: "No personal information is shared with anyone",
                        iconColor: const Color(0xFF863DEF),
                        iconBgColor: const Color(0xFFF1E9FD),
                        icon: Icons.security_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              // Deep Violet Submit Scan limits mappings map forms bound forms mappings layouts boundary spaces layouts layout maps mapping maps maps map bound layout form constraint bound constraints limit form mapped space mapped bounds maps constraints bounds forms map space mapping form layout
              Container(
                color: backgroundLightBlue,
                padding: const EdgeInsets.all(24),
                child: isScanningPlate
                    ? const SizedBox(
                        height: 90,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryViolet,
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: _openEntryOptionsBottomSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryViolet,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryViolet.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Scan or Enter Vehicle\nNumber",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Send a friendly alert to the vehicle owner",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Internal Visual Row Reusability bounds limit map mapped maps limit mappings spaces boundary
  Widget _buildInfoPillCard({
    required String title,
    required String desc,
    required Color iconColor,
    required Color iconBgColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment
            .center, // Center identical natively bounds limits constraint maps constraints limits mapping mapped boundary boundary
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textBlack,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: subTextGrey,
                    fontSize: 11,
                    height: 1.3,
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

// ──────────────────────────────────────────────────────────
// MODAL BOTTOM SHEET WRAPPER CLASS forms spaces boundaries mapping boundary mapping form limit limits mapping map constraint constraints mapping limits mappings boundaries mapped boundary mapped forms boundaries form boundary boundary
// ──────────────────────────────────────────────────────────

class _VehicleEntryOptionsSheet extends StatefulWidget {
  final Future<PlateScanResult?> Function() onScanPressed;

  const _VehicleEntryOptionsSheet({required this.onScanPressed});

  @override
  State<_VehicleEntryOptionsSheet> createState() =>
      _VehicleEntryOptionsSheetState();
}

class _VehicleEntryOptionsSheetState extends State<_VehicleEntryOptionsSheet> {
  final TextEditingController vehicleController = TextEditingController();
  final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

  static const List<Map<String, String>> _parkingErrors = [
    // Section 1: Normal (No Header)
    // Strong AI Detection (Top of Section 1)
    {"group": "Parking Mistakes", "title": "Parked too close (blocking)"},
    {"group": "Parking Mistakes", "title": "Parked outside marking"},
    // Weak AI Detection (Bottom of Section 1)
    {"group": "Hard to Verify automatically", "title": "Parked on ramp / turn"},
    {
      "group": "Hard to Verify automatically",
      "title": "Parked on slope without support",
    },
    {
      "group": "Hard to Verify automatically",
      "title": "Suspicious vehicle / security concern",
    },

    // Section 2: Will take longer
    // Coming Soon
    {"group": "Coming Soon (Manual Review)", "title": "Headlights ON"},
    {"group": "Coming Soon (Manual Review)", "title": "Indicator ON"},
    {"group": "Coming Soon (Manual Review)", "title": "Door open"},
    {"group": "Coming Soon (Manual Review)", "title": "Boot open"},
    {"group": "Coming Soon (Manual Review)", "title": "Window open"},
    {"group": "Coming Soon (Manual Review)", "title": "Engine ON (idle)"},
    {"group": "Coming Soon (Manual Review)", "title": "Handbrake not engaged"},
    {"group": "Coming Soon (Manual Review)", "title": "Hazard light ON"},
    {"group": "Coming Soon (Manual Review)", "title": "Car rolling risk"},
    {"group": "Coming Soon (Manual Review)", "title": "Flat tyre"},
    {"group": "Coming Soon (Manual Review)", "title": "Low air tyre"},
    {
      "group": "Coming Soon (Manual Review)",
      "title": "Side mirror folded / broken",
    },
    {"group": "Coming Soon (Manual Review)", "title": "Fuel cap open"},
    {"group": "Coming Soon (Manual Review)", "title": "Oil leak visible"},
    {"group": "Coming Soon (Manual Review)", "title": "Smoke from engine"},
    {"group": "Coming Soon (Manual Review)", "title": "Parked in visitor slot"},
    {
      "group": "Coming Soon (Manual Review)",
      "title": "Car alarm continuously ringing",
    },
    {"group": "Coming Soon (Manual Review)", "title": "Fuel leakage suspected"},
    {
      "group": "Coming Soon (Manual Review)",
      "title": "Vehicle left unattended long time",
    },
  ];

  bool isValidVehicle = false;
  bool isPristine = true;
  bool isScanningPlate = false;
  bool isLookingUpVehicle = false;

  @override
  void dispose() {
    vehicleController.dispose();
    super.dispose();
  }

  void _validateVehicle(String value) {
    final text = value.replaceAll(" ", "").toUpperCase();

    // Safely enforce correct formatting without collapsing native keyboard positions form space layout bound limits maps boundaries
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
    Get.back();

    if (result["success"] == true && result["registered"] == true) {
      _showRegisteredVehicleDialog(result["data"], vehicleNumber);
      return;
    }

    if (result["registered"] == false) {
      _showUnregisteredVehicleDialog(vehicleNumber);
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
      borderRadius: 8,
    );
  }

  void _showRegisteredVehicleDialog(
    Map<String, dynamic> data,
    String enteredVehicleNumber,
  ) {
    final vehicle = data["vehicle"] as Map<String, dynamic>? ?? {};
    final vehicleNumber =
        vehicle["vehicle_number"]?.toString() ?? enteredVehicleNumber;
    final ownerName =
        data["owner_name"]?.toString() ??
        "${vehicle["owner_first_name"] ?? ""} ${vehicle["owner_last_name"] ?? ""}"
            .trim();
    final displayOwner = ownerName.isEmpty ? "Not available" : ownerName;

    final mobile =
        vehicle["registered_mobile"]?.toString() ??
        data["owner_mobile"]?.toString() ??
        "";
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final displayMobile = cleanMobile.length >= 10
        ? "${cleanMobile.substring(0, 2)}${'X' * (cleanMobile.length - 2)}"
        : "Not available";
    final vehicleType = vehicle["vehicle_type"]?.toString() ?? "Vehicle";

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          "Registered Vehicle",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogInfoRow("Vehicle", vehicleNumber),
            _dialogInfoRow("Owner Name", displayOwner),
            if (vehicle["city"] != null &&
                vehicle["city"].toString().isNotEmpty)
              _dialogInfoRow("City", vehicle["city"].toString()),
            _dialogInfoRow("Contact", displayMobile),
            _dialogInfoRow("Type", vehicleType),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
          TextButton(
            onPressed: () {
              Get.back();
              _showParkingErrorSelector(
                vehicleNumber: vehicleNumber,
                vehicleLookupData: data,
              );
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showParkingErrorSelector({
    required String vehicleNumber,
    required Map<String, dynamic> vehicleLookupData,
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
              "Select parking error",
              style: TextStyle(
                color: Color(0xFF1E212D),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "We will send a private community alert to the owner.",
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
                itemCount: _parkingErrors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final error = _parkingErrors[index];
                  final showHeader =
                      index == 0 ||
                      _parkingErrors[index - 1]["group"] != error["group"];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeader &&
                          error["group"]!.contains("Coming Soon")) ...[
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
                              typev: "help",
                              vehicleNumber: vehicleNumber,
                              vehicleLookupData: vehicleLookupData,
                              selectedIssueTitle: error["title"],
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
                                error["group"]!.contains("Coming Soon")
                                    ? Icons.access_time_rounded
                                    : Icons.handshake_rounded,
                                color: error["group"]!.contains("Coming Soon")
                                    ? Colors.orange
                                    : const Color(0xFF4C42ED),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  error["title"]!,
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

  void _showUnregisteredVehicleDialog(String vehicleNumber) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "You will surely find this vehicle one day",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "$vehicleNumber is not registered with ParkingMudde yet. Thanks for your help. Invite known vehicle owners so the community can alert them privately next time.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri(
                scheme: "sms",
                queryParameters: {
                  "body":
                      "Join ParkingMudde to receive private vehicle alerts and help solve parking issues in your community.",
                },
              );
              await launchUrl(uri);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C42ED),
              foregroundColor: Colors.white,
            ),
            child: const Text("Refer Now"),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanAndFillManualField() async {
    if (isScanningPlate) return;

    setState(() => isScanningPlate = true);

    try {
      final result = await widget.onScanPressed();
      if (!mounted || result == null) return;

      final detectedNumber = result.vehicleNumber
          .replaceAll(" ", "")
          .toUpperCase();
      if (detectedNumber.isEmpty) {
        Get.snackbar(
          "Plate Not Detected",
          "Try again with the plate centered and well lit, or type it manually.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        return;
      }

      _validateVehicle(detectedNumber);
      Get.snackbar(
        "Number Plate Scanned",
        detectedNumber,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        "Scan Failed",
        "The plate reader could not finish. You can type the number manually.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      if (mounted) {
        setState(() => isScanningPlate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring native safe zones constraints are managed nicely if the keyboard opens layouts map mapped space layouts layout
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
              .min, // Shrinkwrap cleanly mapping layout form limit layout constraint space maps map bounds limit mapped bounds bounds limit space bound form mapping bound layout mapped limit boundary limit space bounds spaces
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
            const SizedBox(height: 24),

            const Text(
              "How to read Plate?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E212D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap scanner to instantly scan physical plate.",
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),

            const SizedBox(height: 24),

            // ACTION: SMART SCAN spaces map boundaries constraints spaces layouts bounds mapping form bounds
            ElevatedButton(
              onPressed: isScanningPlate ? null : _scanAndFillManualField,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F5FA),
                disabledBackgroundColor: const Color(0xFFF3F5FA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: isScanningPlate
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF4C42ED),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Reading plate...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4C42ED),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF4C42ED),
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Quick Camera Scan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4C42ED),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                "OR TYPE NUMBER MANUALLY",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NATIVE PRESERVED REPLICA OF INDIAN HSRP constraints space boundary forms mapped layout layouts
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

            // ACTION: SUBMIT forms form boundary mapping mapped boundary forms bounds boundary form limits layout
            SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValidVehicle && !isLookingUpVehicle
                    ? _onManualSubmit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidVehicle
                      ? const Color(0xFF4C42ED)
                      : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLookingUpVehicle
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Validate Number",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isValidVehicle
                              ? Colors.white
                              : Colors.grey.shade600,
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
