import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';

class TransferVehicleScreen extends StatefulWidget {
  final dynamic vehicle;

  const TransferVehicleScreen({super.key, required this.vehicle});

  @override
  State<TransferVehicleScreen> createState() => _TransferVehicleScreenState();
}

class _TransferVehicleScreenState extends State<TransferVehicleScreen> {
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF999999);
  static const Color borderGrey = Color(0xFFD2D2D2);

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    final mobile = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (mobile.length != 10) {
      Get.snackbar(
        "Invalid Mobile Number",
        "Please enter a valid 10-digit mobile number.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Confirm Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Confirm Transfer"),
        content: Text(
          "Are you sure you want to transfer ownership of vehicle ${widget.vehicle['registration_number']} to mobile number $mobile?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Cancel", style: TextStyle(color: subTextGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(
              foregroundColor: primaryBlue,
            ),
            child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    final user = await ApiService.getStoredUser();
    final userId = user?["user_id"]?.toString() ?? "";
    final vehicleId = widget.vehicle["id"]?.toString() ?? "";

    if (userId.isEmpty || vehicleId.isEmpty) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Unable to process transfer request.");
      return;
    }

    final result = await ApiService.transferVehicle(
      vehicleId: vehicleId,
      currentUserId: userId,
      recipientMobile: mobile,
    );

    setState(() => _isLoading = false);

    if (result["success"] == true) {
      Get.snackbar(
        "Transfer Successful",
        result["message"] ?? "Vehicle ownership transferred.",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      Get.back(result: true); // Return true to indicate successful transfer and trigger refresh
    } else {
      Get.snackbar(
        "Transfer Failed",
        result["message"] ?? "Could not transfer vehicle.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final regNo = widget.vehicle['registration_number']?.toString() ?? 'N/A';
    final brand = widget.vehicle['brand_name']?.toString() ?? '';
    final model = widget.vehicle['model_name']?.toString() ?? '';
    final vehicleName = "$brand $model".trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue, size: 20),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          "Transfer Ownership",
          style: TextStyle(color: textBlack, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 40, color: primaryBlue),
                    const SizedBox(height: 12),
                    Text(
                      regNo.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (vehicleName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        vehicleName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textBlack,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Transfer To",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter the registered mobile number of the ParkingMudde user you wish to transfer this vehicle to.",
                style: TextStyle(color: subTextGrey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                "Recipient's Mobile Number *",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(
                  color: textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "Enter 10-digit mobile number",
                  hintStyle: const TextStyle(
                    color: Color(0xFFC0CAD8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "+91",
                          style: TextStyle(
                            color: textBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Initiate Transfer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}
