import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/account/editpage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/plate_scanner_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkingmudde/screen/reportwrongparking/issue_selection.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final PlateScannerService _plateScanner = PlateScannerService();
  final TextEditingController vehicleController = TextEditingController();
  final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

  bool isScanningPlate = false;
  bool isLookingUpVehicle = false;
  bool isValidVehicle = false;

  // Emergency contacts check
  bool _contactsLoaded = false;
  bool _hasEmergencyContacts = false;
  String _ec1 = '';
  String _ec2 = '';

  static const Color emergencyRed = Color(0xFFE53935);
  static const Color textBlack = Color(0xFF1E212D);
  static const Color subTextGrey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _checkEmergencyContacts();
  }

  Future<void> _checkEmergencyContacts() async {
    // First try to load from backend (refreshed user data)
    final user = await ApiService.refreshCurrentUser();
    if (!mounted) return;

    String ec1 = '';
    String ec2 = '';

    if (user != null) {
      ec1 = user['emergency_contact_one']?.toString() ?? '';
      ec2 = user['emergency_contact_two']?.toString() ?? '';
    }

    // Fall back to local prefs if backend didn't return them
    if (ec1.isEmpty || ec2.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      ec1 = ec1.isNotEmpty ? ec1 : (prefs.getString('emergency_contact_one') ?? '');
      ec2 = ec2.isNotEmpty ? ec2 : (prefs.getString('emergency_contact_two') ?? '');
    }

    setState(() {
      _ec1 = ec1;
      _ec2 = ec2;
      _hasEmergencyContacts = ec1.isNotEmpty && ec2.isNotEmpty;
      _contactsLoaded = true;
    });
  }

  @override
  void dispose() {
    vehicleController.dispose();
    super.dispose();
  }

  void _validateVehicle(String value) {
    final text = value.replaceAll(' ', '').toUpperCase();
    if (vehicleController.text != text) {
      vehicleController.value = vehicleController.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    setState(() => isValidVehicle = vehicleRegex.hasMatch(text));
  }

  Future<void> _scanPlate() async {
    if (isScanningPlate) return;
    setState(() => isScanningPlate = true);
    try {
      final result = await _plateScanner.scanFromCamera(context: context);
      if (!mounted || result == null) return;
      final detected = result.vehicleNumber.replaceAll(' ', '').toUpperCase();
      if (detected.isEmpty) {
        _showMessage('Plate Not Detected', 'Please enter the number manually.');
        return;
      }
      _validateVehicle(detected);
    } finally {
      if (mounted) setState(() => isScanningPlate = false);
    }
  }

  Future<void> _continueEmergency() async {
    if (!isValidVehicle || isLookingUpVehicle) return;

    // Gate: contacts must be set
    if (!_hasEmergencyContacts) {
      _showMissingContactsDialog();
      return;
    }

    final vehicleNumber = vehicleController.text.toUpperCase();
    setState(() => isLookingUpVehicle = true);
    final result = await ApiService.lookupVehicleByNumber(vehicleNumber);
    if (!mounted) return;
    setState(() => isLookingUpVehicle = false);

    if (result['success'] == true && result['registered'] == true) {
      Get.to(() => IssueSelectionScreen(
            typev: 'emergency',
            vehicleNumber: vehicleNumber,
            vehicleLookupData: result['data'] as Map<String, dynamic>?,
          ));
      return;
    }

    if (result['registered'] == false) {
      _showUnregisteredEmergencyDialog(vehicleNumber);
      return;
    }

    _showMessage(
      'Lookup Failed',
      result['message']?.toString() ?? 'Could not check this vehicle right now.',
    );
  }

  Future<void> _callEmergencyHelpline() async {
    final uri = Uri(scheme: 'tel', path: '108');
    if (!await launchUrl(uri)) {
      _showMessage('Call Failed', 'Could not open the phone dialer.');
    }
  }

  void _showMissingContactsDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
            const SizedBox(width: 8),
            const Text('No Emergency Contacts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: const Text(
          'You need to add at least 2 emergency contacts before sending an emergency alert. '
          'These contacts will be notified immediately with your location and situation.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.to(() => const EditProfilePage())?.then((_) => _checkEmergencyContacts());
            },
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Update Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnregisteredEmergencyDialog(String vehicleNumber) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Unregistered Vehicle', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          '$vehicleNumber is not registered with ParkingMudde. Call nearby emergency help directly and share the live situation.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: _callEmergencyHelpline,
            icon: const Icon(Icons.call),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String title, String message) {
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: textBlack),
            onPressed: () => Get.offAll(() => const Dash()),
          ),
          title: const Text(
            'Emergency Alert',
            style: TextStyle(color: textBlack, fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [

              // ── Missing Contacts Banner ──
              if (_contactsLoaded && !_hasEmergencyContacts)
                GestureDetector(
                  onTap: () => Get.to(() => const EditProfilePage())?.then((_) => _checkEmergencyContacts()),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Emergency contacts not set',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Tap to add them in your profile before proceeding.',
                                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.orange.shade700),
                      ],
                    ),
                  ),
                ),

              // ── Contacts confirmed banner ──
              if (_contactsLoaded && _hasEmergencyContacts)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emergency contacts ready',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13)),
                            Text('${_maskNumber(_ec1)}  •  ${_maskNumber(_ec2)}',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Info Banner ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: emergencyRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: emergencyRed.withValues(alpha: 0.18)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_hospital_rounded, color: emergencyRed, size: 34),
                    SizedBox(height: 12),
                    Text(
                      'Alert emergency contacts and nearby help with vehicle number, situation, photo and location.',
                      style: TextStyle(color: textBlack, height: 1.45, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Scan Button ──
              ElevatedButton.icon(
                onPressed: isScanningPlate ? null : _scanPlate,
                icon: isScanningPlate
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.qr_code_scanner_rounded),
                label: Text(isScanningPlate ? 'Reading plate...' : 'Scan Vehicle Number'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: emergencyRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text('OR ENTER MANUALLY',
                    style: TextStyle(color: subTextGrey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              const SizedBox(height: 18),

              // ── Vehicle number input ──
              TextField(
                controller: vehicleController,
                onChanged: _validateVehicle,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: 'DL01AA1111',
                  prefixIcon: const Icon(Icons.directions_car_rounded),
                  suffixIcon: vehicleController.text.isEmpty
                      ? null
                      : Icon(
                          isValidVehicle ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isValidVehicle ? Colors.green : Colors.red,
                        ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Continue Button ──
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isValidVehicle && !isLookingUpVehicle ? _continueEmergency : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasEmergencyContacts ? emergencyRed : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLookingUpVehicle
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(
                          _hasEmergencyContacts ? 'Continue Emergency Alert' : 'Set Emergency Contacts First',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskNumber(String number) {
    if (number.length < 4) return number;
    return '${number.substring(0, 2)}****${number.substring(number.length - 2)}';
  }
}
