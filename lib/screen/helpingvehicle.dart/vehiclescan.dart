import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';

class VehicleNumberHelpScreen extends StatefulWidget {
  const VehicleNumberHelpScreen({super.key});

  @override
  State<VehicleNumberHelpScreen> createState() =>
      _VehicleNumberHelpScreenState();
}

class _VehicleNumberHelpScreenState extends State<VehicleNumberHelpScreen> {
  final TextEditingController vehicleController = TextEditingController();
  bool isValidVehicle = false;
  bool isPristine = true;

  /// Indian Vehicle Number Regex
  final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

  void validateVehicle(String value) {
    final text = value.replaceAll(" ", "").toUpperCase();

    // Smooth inline updates maintaining correct cursor positions
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
          onPressed: () {
            // Maintains your precise explicit back route logic
            Get.offAll(const Dash());
          },
        ),
        title: const Text(
          "Help Vehicle",
          style: TextStyle(
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
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header titles mapped for helping flow
                      const Text(
                        "Notify the Owner",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Scan or enter the vehicle number to alert the owner in case of an emergency or issue.",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// Interactive Professional Scanner Card
                      buildScannerCard(),

                      const SizedBox(height: 32),

                      /// Elegant Section Divider
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

                      /// Stunning License Plate Replica Field
                      buildIndianLicensePlateField(),

                      const SizedBox(height: 20),

                      const SizedBox(height: 20),

                      /// Solid Submit/Continue block Action Footer
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

  /// Visually satisfying layout for scan to notify
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
                    Icons
                        .qr_code_scanner_rounded, // Specific scan icon matching help scenario slightly better
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
              "Instantly scan plate and notify owner",
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

  /// Exact replica Indian HSRP Input element connecting functionality beautifully
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
            borderRadius: BorderRadius.circular(8),
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
              // 'IND' Blue Strip area
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
                    ),
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

              // Properly connected text editing logic
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
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: "MH12AB1234",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),

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

        if (vehicleController.text.isNotEmpty && !isValidVehicle)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Requires correct RTO Format (MH12AB1234)",
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
              "Format correctly identified",
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

  /// Full width elegant sticky action row
  Widget buildActionFooter() {
    // Requires controller text present before lighting up
    bool canProceed = vehicleController.text.isNotEmpty;

    return InkWell(
      onTap: canProceed
          ? () {
              if (isValidVehicle) {
                Get.to(ReportProofScreen(typev: "1"));
              } else {
                Get.snackbar(
                  "Incorrect Registration format",
                  "Enter a valid format to proceed locating the owner.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.amber.shade800,
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
                "Fetch Owner Data",
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
