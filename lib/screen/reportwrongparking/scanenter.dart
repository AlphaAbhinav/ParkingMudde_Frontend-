import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';

class VehicleNumberInputScreen extends StatefulWidget {
  const VehicleNumberInputScreen({super.key});

  @override
  State<VehicleNumberInputScreen> createState() =>
      _VehicleNumberInputScreenState();
}

class _VehicleNumberInputScreenState extends State<VehicleNumberInputScreen> {
  final TextEditingController vehicleController = TextEditingController();
  bool isValidVehicle = false;
  bool isPristine =
      true; // Tracks if user has started typing to hide errors early

  /// Indian Vehicle Number Regex
  final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

  void validateVehicle(String value) {
    // Kept your precise logic untouched
    final text = value.replaceAll(" ", "").toUpperCase();

    // Updates UI cursor dynamically based on exact format requested
    vehicleController.value = vehicleController.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    setState(() {
      isPristine = false;
      isValidVehicle = vehicleRegex.hasMatch(text);
    });
  }

  @override
  void dispose() {
    vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Match super-app soft background theme
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
        title: const Text(
          "Report Wrong Parking", // Fixed Typo beautifully
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B), // Sleek slate color for headings
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ), // Thin hairline division
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Interactive Professional Scanner Card
                      buildScannerCard(),

                      const SizedBox(height: 32),

                      /// 🔹 Elegant Section Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR ENTER MANUALLY",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      /// 🔹 Stunning License Plate Replica Field
                      buildIndianLicensePlateField(),

                      const SizedBox(height: 20),

                      const SizedBox(
                        height: 20,
                      ), // Buffer before the floating action layout
                      /// 🔹 Floating Action Continue Button
                      buildActionFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Interactive Scanner layout with focus guides styling
  Widget buildScannerCard() {
    return InkWell(
      onTap: () {
        // TODO: Open OCR Camera
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0XFF184b8c).withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft background radial bubble for emphasis
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0XFF184b8c).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0XFF184b8c),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Scan Number Plate",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Place vehicle plate inside the camera frame\nfor fast & accurate reporting",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visually identical input element built as a High Security Number Plate (IND plate)
  Widget buildIndianLicensePlateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vehicle Registration Number",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // Standard crisp borders
            border: Border.all(
              color: isPristine
                  ? Colors.black45
                  : (isValidVehicle ? Colors.green.shade600 : Colors.redAccent),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 'IND' Blue Strip area found on real Indian plates
              Container(
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ), // Sun hologram imitation
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        "IND",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Connected existing controller effectively without affecting logic constraints!
              Expanded(
                child: TextFormField(
                  controller: vehicleController,
                  onChanged: validateVehicle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.black87,
                  ),
                  textCapitalization:
                      TextCapitalization.characters, // Proper keyboard forcing
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9]'),
                    ), // Forcing out special chars proactively
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: "MH12AB1234",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),

              // Responsive live feedback icons
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: vehicleController.text.isEmpty
                      ? const SizedBox.shrink()
                      : isValidVehicle
                      ? Container(
                          key: const ValueKey('valid'),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                        )
                      : Container(
                          key: const ValueKey('invalid'),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        // Beautiful textual warning response
        if (vehicleController.text.isNotEmpty && !isValidVehicle)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Format e.g. MH12AB1234",
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (vehicleController.text.isNotEmpty && isValidVehicle)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Vehicle identity recognized",
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Complete full-width professional super-app docked action container
  Widget buildActionFooter() {
    // Determine states logically allowing UI flow blocking until validated properly, improving safety (can be removed if user wants raw bypassing)
    bool canProceed = vehicleController
        .text
        .isNotEmpty; // Just verifying emptiness; enforce validation directly below or optionally lock this logic!

    return InkWell(
      onTap: canProceed
          ? () {
              if (isValidVehicle) {
                Get.to(ReportProofScreen(typev: "1"));
              } else {
                Get.snackbar(
                  "Invalid Vehicle Number",
                  "Please check the details against valid RTO formatting",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 8,
                );
              }
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: canProceed ? const Color(0XFF184B8C) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canProceed
              ? [
                  BoxShadow(
                    color: const Color(0XFF184B8C).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Verify & Continue",
                style: TextStyle(
                  color: canProceed ? Colors.white : Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (canProceed)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
