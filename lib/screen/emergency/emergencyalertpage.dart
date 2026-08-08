import 'package:flutter/cupertino.dart';
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
  static const Color textBlack = Color(0xFF161922);
  static const Color subTextGrey = Color(0xFF6B7280);
  static const Color backgroundColor = Color(0xFFF9FAFC);

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
      ec1 = ec1.isNotEmpty
          ? ec1
          : (prefs.getString('emergency_contact_one') ?? '');
      ec2 = ec2.isNotEmpty
          ? ec2
          : (prefs.getString('emergency_contact_two') ?? '');
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
    if (isLookingUpVehicle) return;

    // Gate: contacts must be set
    if (!_hasEmergencyContacts) {
      _showMissingContactsDialog();
      return;
    }

    Get.to(
      () => const IssueSelectionScreen(typev: 'emergency'),
      transition: Transition.cupertino,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Flexible(
              child: Text(
                'No Emergency Contacts',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: textBlack,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: const Text(
          'You need to add at least 2 emergency contacts before sending an emergency alert. '
          'These contacts will be notified immediately with your location and situation.',
          style: TextStyle(
            height: 1.6,
            fontSize: 14.5,
            color: subTextGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: subTextGrey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.to(
                () => const EditProfilePage(),
              )?.then((_) => _checkEmergencyContacts());
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text(
              'Update Contacts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyRed,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: emergencyRed.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnregisteredEmergencyDialog(String vehicleNumber) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: emergencyRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_crash_rounded,
                color: emergencyRed,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Flexible(
              child: Text(
                'Unregistered Vehicle',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: textBlack,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: Text(
          '$vehicleNumber is not registered with ParkingMudde. This user is not a part of the Parking Mudde family. Please contact the nearest hospital to help.',
          style: const TextStyle(
            height: 1.6,
            fontSize: 14.5,
            color: subTextGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Close',
              style: TextStyle(color: subTextGrey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _callEmergencyHelpline,
            icon: const Icon(Icons.call, size: 18),
            label: const Text(
              'Call Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyRed,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: emergencyRed.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.85),
      colorText: Colors.white,
      margin: const EdgeInsets.all(20),
      borderRadius: 14,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          scrolledUnderElevation: 0,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: textBlack,
                  size: 20,
                ),
                onPressed: () => Get.offAll(() => const Dash()),
                splashColor: Colors.transparent,
                highlightColor: Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          title: const Text(
            'Emergency Alert',
            style: TextStyle(
              color: textBlack,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
        ),

        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SizedBox(
              height: 58,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _contactsLoaded
                    ? ElevatedButton(
                        onPressed: _hasEmergencyContacts && !isLookingUpVehicle
                            ? _continueEmergency
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasEmergencyContacts
                              ? emergencyRed
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: _hasEmergencyContacts ? 6 : 0,
                          shadowColor: emergencyRed.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasEmergencyContacts
                                  ? Icons.photo_camera_rounded
                                  : Icons.lock_outline_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _hasEmergencyContacts
                                    ? 'Select Emergency & Upload Photo'
                                    : 'Set Emergency Contacts First',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 26,
                ),
                margin: const EdgeInsets.only(bottom: 26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [emergencyRed, Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: emergencyRed.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // <--- FIX IS HERE: Removed const from this Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Emergency Support Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Alert emergency contacts and nearby help with situation, photo and location. Add vehicle plate after proof.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: -30,
                      top: -10,
                      child: Icon(
                        Icons.local_hospital_rounded,
                        size: 140,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: !_contactsLoaded
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 20.0),
                          child: CupertinoActivityIndicator(radius: 12),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        key: const ValueKey('loaded'),
                        children: [
                          if (!_hasEmergencyContacts)
                            GestureDetector(
                              onTap: () => Get.to(
                                () => const EditProfilePage(),
                              )?.then((_) => _checkEmergencyContacts()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.4),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Emergency contacts not set',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.orange.shade800,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to add them in your profile before proceeding.',
                                            style: TextStyle(
                                              color: Colors.orange.shade700
                                                  .withOpacity(0.85),
                                              fontSize: 12.5,
                                              height: 1.3,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.orange.shade700,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (_hasEmergencyContacts)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green.shade600,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Emergency contacts ready',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green.shade800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.shield_rounded,
                                              size: 12,
                                              color: Colors.green.shade700
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_maskNumber(_ec1)} • ${_maskNumber(_ec2)}',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
    return '${number.substring(0, 2)}••${number.substring(number.length - 2)}';
  }
}
