import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';

import 'package:parkingmudde/screen/auth/loginpage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import '../../services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Navigation / Onboarding step state (1 = Register, 2 = Location, 3 = Profile)
  int currentStep = 1;

  // --- Step 1 Controllers ---
  final nameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl =
      TextEditingController(); // Essential for the existing backend
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  String gender = "Male";
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String? _passwordErrorText;

  // --- Step 2 Controllers (Location) ---
  final locationSearchCtrl = TextEditingController();
  double? selectedLatitude;
  double? selectedLongitude;
  bool isFetchingLocation = false;
  final MapController mapController = MapController();

  // --- Step 3 State (Profile Photo) ---
  final ImagePicker _imagePicker = ImagePicker();
  XFile? profileImage;
  Uint8List? profileImageBytes;
  bool hasPhoto = false;

  // Figma Exact Layout UI Color Code Extracted Theme Maps
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color labelGrey = Color(0xFF555555);
  static const Color subTextGrey = Color(0xFF999999);
  static const Color borderGrey = Color(0xFFD2D2D2);
  static const Color textBlack = Color(0xFF222222);
  static const Color errorRed = Color(0xFFF03648);
  static const Color disabledGrey = Color(0xFFD8D8D8);

  @override
  void dispose() {
    nameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    dobCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    locationSearchCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Step Handler Controls
  // ──────────────────────────────────────────────────────────

  void _handleBack() {
    if (currentStep == 3) {
      if (hasPhoto) {
        setState(() => hasPhoto = false); // 04.12 back to 04.11
      } else {
        setState(() => currentStep = 2); // 04.11 back to location
      }
    } else if (currentStep == 2) {
      setState(() => currentStep = 1); // 04.7 back to auth fields
    } else {
      if (Navigator.canPop(context)) Get.back(); // Abort entire stack
    }
  }

  String get _appBarTitle {
    if (currentStep == 1) return "Create an account";
    if (currentStep == 2) return "Location";
    return "Profile";
  }

  bool _validateStep1Fields() {
    FocusScope.of(context).unfocus();
    setState(() => _passwordErrorText = null);

    final mobile = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final name = nameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim().toLowerCase();
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    if (name.isEmpty) {
      _showSnackbarError("Please enter your first name.");
      return false;
    }

    if (lastName.isEmpty) {
      _showSnackbarError("Please enter your last name.");
      return false;
    }

    if (dobCtrl.text.trim().isEmpty) {
      _showSnackbarError("Please select your date of birth.");
      return false;
    }

    if (mobile.length != 10) {
      _showSnackbarError("Enter a valid 10-digit mobile number.");
      return false;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      _showSnackbarError("Please enter a valid email address.");
      return false;
    }

    if (password.length < 6) {
      _showSnackbarError("Password must be at least 6 characters.");
      return false;
    }

    if (password != confirmPassword) {
      setState(
        () => _passwordErrorText = "The passwords you entered do not match.",
      ); // 04.6 Exact inline styling visual map natively mapped
      return false;
    }

    return true;
  }

  void _handleRegister() {
    if (_validateStep1Fields()) {
      setState(() => currentStep = 2);
    }
  }

  Future<void> _createAccountAndFinish() async {
    if (!_validateStep1Fields()) {
      setState(() => currentStep = 1);
      return;
    }

    final location = locationSearchCtrl.text.trim();
    if (location.isEmpty) {
      setState(() => currentStep = 2);
      _showSnackbarError("Please add your location.");
      return;
    }

    final mobile = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final email = emailCtrl.text.trim().toLowerCase();
    final password = passwordCtrl.text.trim();
    final fullName = "${nameCtrl.text.trim()} ${lastNameCtrl.text.trim()}";
    setState(() => isLoading = true);

    final result = await ApiService.register(
      name: fullName.trim(),
      mobile: mobile,
      email: email,
      password: password,
      gender: gender,
      dateOfBirth: dobCtrl.text.trim(),
      referralCode: null,
      location: location,
      latitude: selectedLatitude,
      longitude: selectedLongitude,
      profileImage: profileImage,
    );
    if (!mounted) return;
    setState(() => isLoading = false);

    if (result["success"] == true) {
      await ApiService.saveUserSession(result);

      Get.offAll(() => const Dash(), transition: Transition.rightToLeft);
    } else {
      _showSnackbarError(
        result["message"] ?? "Registration Failed. Please try again.",
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      profileImage = image;
      profileImageBytes = bytes;
      hasPhoto = true;
    });
  }

  Future<void> _selectDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  Future<void> _finishOnboarding() async {
    await _createAccountAndFinish();
  }

  Future<void> _updateAddressFromLatLng(double lat, double lng) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = "";
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += "${place.subLocality}, ";
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += "${place.locality}";
        }
        if (address.isEmpty && place.street != null) {
          address = place.street!;
        }
        if (address.isEmpty) {
          address = "Selected Location";
        }
        if (mounted) {
          setState(() {
            locationSearchCtrl.text = address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationSearchCtrl.text =
              "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}";
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbarError("Please turn on device location services.");
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnackbarError("Location permission is required to use GPS.");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackbarError(
          "Location permission is blocked. Enable it from app settings.",
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        selectedLatitude = position.latitude;
        selectedLongitude = position.longitude;
        locationSearchCtrl.text = "Fetching address...";
      });
      await _updateAddressFromLatLng(position.latitude, position.longitude);
      mapController.move(LatLng(position.latitude, position.longitude), 16);
    } catch (e) {
      _showSnackbarError("Could not get GPS location. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isFetchingLocation = false);
      }
    }
  }

  void _showSnackbarError(String message) {
    Get.snackbar(
      "Validation Error",
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 10,
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      "Coming soon",
      "This integration will be available shortly.",
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
    );
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryBlue,
              size: 20,
            ), // Kept strictly primary standard bounds constraint spaces map
            onPressed: _handleBack,
          ),
          centerTitle: true,
          title: Text(
            _appBarTitle,
            style: const TextStyle(
              color: textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scrollable body map areas layouts constraint boundaries mappings bound layout space limit constraint mapping constraint forms limits constraints limits space form map mappings standard map bound
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: currentStep == 1
                        ? _buildStep1AuthFields(key: const ValueKey(1))
                        : currentStep == 2
                        ? _buildStep2Location(key: const ValueKey(2))
                        : _buildStep3Profile(key: const ValueKey(3)),
                  ),
                ),
              ),

              // Bottom fixed Buttons section for Navigation standard mapping forms constraints layouts boundary space mapped bounds mapping
              if (currentStep != 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildBottomActions(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STEP 1 UI: AUTH FIELDS (Figma 04.2 - 04.6) map bound spaces standard mappings constraint limits
  // ──────────────────────────────────────────────────────────
  Widget _buildStep1AuthFields({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFigmaField(
          label: "First name",
          hint: "Input your first name",
          controller: nameCtrl,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 18),

        _buildFigmaField(
          label: "Last name",
          hint: "Input your last name",
          controller: lastNameCtrl,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 18),

        _buildFigmaField(
          label: "Mobile number",
          hint: "Input your mobile number",
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 18),

        _buildFigmaField(
          label: "Email address",
          hint: "Input email address",
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),

        const Text(
          "Gender",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderPillSelection("Male", Icons.male_rounded),
            const SizedBox(width: 12),
            _genderPillSelection("Female", Icons.female_rounded),
          ],
        ),
        const SizedBox(height: 18),

        _buildFigmaField(
          label: "Date of birth",
          hint: "Select your date of birth",
          controller: dobCtrl,
          readOnly: true,
          onTapTrigger: _selectDob,
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 18),

        _buildFigmaField(
          label: "Password",
          hint: "Input your password",
          controller: passwordCtrl,
          obscureText: obscurePassword,
          onToggleObscure: () =>
              setState(() => obscurePassword = !obscurePassword),
        ),
        const SizedBox(height: 18),

        _buildFigmaField(
          label: "Confirm Password",
          hint: "Input confirm password",
          controller: confirmPasswordCtrl,
          obscureText: obscureConfirm,
          onToggleObscure: () =>
              setState(() => obscureConfirm = !obscureConfirm),
          isError: _passwordErrorText != null,
          errorText: _passwordErrorText,
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Sign up",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(child: Divider(color: borderGrey, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Or sign up with",
                style: TextStyle(
                  color: subTextGrey.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Expanded(child: Divider(color: borderGrey, thickness: 1)),
          ],
        ),
        const SizedBox(height: 28),

        _SocialProviderButton(
          text: "Continue with Google",
          backgroundColor: Colors.white,
          textColor: textBlack,
          borderColor: borderGrey,
          iconWidget: const _FallbackGoogleIcon(),
          onTap: _showComingSoon,
        ),
        const SizedBox(height: 16),
        _SocialProviderButton(
          text: "Continue with Facebook",
          backgroundColor: facebookBlue,
          textColor: Colors.white,
          borderColor: Colors.transparent,
          iconWidget: const Icon(Icons.facebook, color: Colors.white, size: 24),
          onTap: _showComingSoon,
        ),
        const SizedBox(height: 16),
        _SocialProviderButton(
          text: "Continue with Apple",
          backgroundColor: Colors.black,
          textColor: Colors.white,
          borderColor: Colors.transparent,
          iconWidget: const Icon(
            Icons.apple_rounded,
            color: Colors.white,
            size: 26,
          ),
          onTap: _showComingSoon,
        ),

        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Already have an account? ",
              style: TextStyle(
                color: labelGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.offAll(
                  () => const Loginpage(),
                  transition: Transition.leftToRight,
                );
              },
              child: const Text(
                "Sign in",
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // STEP 2 UI: LOCATION (Figma 04.7 / 04.9) space mappings boundaries limits mapped mapping layouts layout maps bounds
  // ──────────────────────────────────────────────────────────
  Widget _buildStep2Location({required Key key}) {
    bool hasSearchText = locationSearchCtrl
        .text
        .isNotEmpty; // Determines State 04.9 logic bounds bounds map limits boundaries layout

    return Column(
      key: key,
      children: [
        const SizedBox(height: 10),
        // Beautiful minimal manually integrated icon limit
        const Center(
          child: Icon(
            Icons.location_on,
            color: Color(0xFFFF5A5F),
            size: 54,
          ), // Matches Pink Map pin styling exactly natively mapped forms limit maps boundaries constraint constraints
        ),
        const SizedBox(height: 24),

        const Text(
          "What's your location?",
          style: TextStyle(
            color: textBlack,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Use GPS or enter your city, area, or address",
          style: TextStyle(
            color: subTextGrey,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 35),

        // Advanced Custom Label Forms bound mapped
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Location",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: locationSearchCtrl,
              onChanged: (val) => setState(() {
                selectedLatitude = null;
                selectedLongitude = null;
              }), // Trigger UI change constraints bounded naturally visually
              style: const TextStyle(
                color: textBlack,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "add your location",
                hintStyle: const TextStyle(
                  color: Color(0xFFC0CAD8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: primaryBlue,
                  size: 22,
                ), // Matching the search
                suffixIcon: hasSearchText
                    ? IconButton(
                        onPressed: () {
                          locationSearchCtrl.clear();
                          selectedLatitude = null;
                          selectedLongitude = null;
                          FocusScope.of(context).unfocus();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.cancel,
                          color: Color(0xFFC0CAD8),
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: hasSearchText ? primaryBlue : borderGrey,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                ),
              ),
            ),
          ],
        ),

        // Let users confirm their own typed location without showing fake city suggestions.
        if (hasSearchText) ...[
          const SizedBox(height: 16),
          _buildTypedLocationItem(locationSearchCtrl.text.trim()),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isFetchingLocation ? null : _useCurrentLocation,
            icon: isFetchingLocation
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 20),
            label: Text(
              isFetchingLocation
                  ? "Getting location..."
                  : "Use current location",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        _buildLocationMapPreview(),
      ],
    );
  }

  Widget _buildLocationMapPreview() {
    if (selectedLatitude == null || selectedLongitude == null) {
      return const SizedBox.shrink();
    }

    final lat = selectedLatitude!;
    final lng = selectedLongitude!;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Check location on map",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelGrey,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFFF2F4F7),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 16,
                  onTap: (tapPosition, point) {
                    setState(() {
                      selectedLatitude = point.latitude;
                      selectedLongitude = point.longitude;
                      locationSearchCtrl.text = "Fetching address...";
                    });
                    _updateAddressFromLatLng(point.latitude, point.longitude);
                    mapController.move(point, 16);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.parkingmudde',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: errorRed,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "If this does not look exact, you can tap on the map or drag the pin to adjust your location perfectly.",
            style: TextStyle(
              color: subTextGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypedLocationItem(String location) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          horizontalTitleGap: 8,
          leading: const Icon(
            Icons.my_location_rounded,
            color: textBlack,
            size: 18,
          ),
          title: Text(
            'Use "$location"',
            style: const TextStyle(
              color: textBlack,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              "Save this as your entered location",
              style: const TextStyle(
                color: subTextGrey,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          onTap: () {
            // Logic mapping auto fill mappings boundaries constraints forms constraint mapped layouts space standard maps bound form mapping mapping limit mapping bounds limit mappings space constraint limits
            FocusScope.of(context).unfocus();
            locationSearchCtrl.text = location;
            setState(() {
              selectedLatitude = null;
              selectedLongitude = null;
            });
          },
        ),
        const Divider(
          color: Color(0xFFF3F3F3),
          height: 1,
        ), // Light exact spacing standard limit separator lines limit boundary
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // STEP 3 UI: PROFILE PICTURE (Figma 04.11 / 04.12) bound layouts spaces limit map boundary mapped boundaries constraint boundary mapped mapping
  // ──────────────────────────────────────────────────────────
  Widget _buildStep3Profile({required Key key}) {
    String safeName = nameCtrl.text.isEmpty
        ? "Your Name"
        : nameCtrl
              .text; // Native extraction placeholder bounds boundary constraints mapped spaces mapping

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          hasPhoto
              ? "Nice!, how your profile is looking so far"
              : "Adding photo to make your profile\nstunning",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textBlack,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.4,
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: hasPhoto ? 35 : 45),

        if (!hasPhoto)
          // FIGMA 04.11 Upload PlaceHolder constraint mapped mappings layout bound constraint boundary constraint boundary forms mapping standard limits map limits spaces constraints bounds mapped boundary constraints layout mapping mapped layout mapping forms space constraint layout bounds spaces boundary layout spaces boundaries layout maps mapping layout limit map map boundary boundaries mapping bound boundaries boundary
          Container(
            height: 180,
            width: 140,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF2F4F7,
              ), // Grey box native space constraints maps layout bound space mapping map
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGrey, width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.insert_photo,
                color: Color(0xFFB1BCCB),
                size: 48,
              ),
            ),
          )
        else
          // FIGMA 04.12 Success Complete limits bound space constraint constraints
          Column(
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.hardEdge,
                child: profileImageBytes != null
                    ? Image.memory(profileImageBytes!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.face_retouching_natural_rounded,
                        size: 100,
                        color: Color(0xFF9AA4B2),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                safeName,
                style: const TextStyle(
                  color: textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locationSearchCtrl.text.isEmpty
                    ? "Location not added"
                    : locationSearchCtrl.text,
                style: const TextStyle(
                  color: subTextGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // FIXED BOTTOM ONBOARDING BUTTON LOGIC handler spaces layout mapping map limits
  // ──────────────────────────────────────────────────────────
  Widget _buildBottomActions() {
    if (currentStep == 2) {
      bool canAdvance = locationSearchCtrl.text.isNotEmpty;
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: canAdvance ? () => setState(() => currentStep = 3) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAdvance ? primaryBlue : disabledGrey,
            disabledBackgroundColor:
                disabledGrey, // Precise logic tie maps bounds boundaries mapped bounds map standard boundary constraint layout layout limit boundary boundaries bounds map mapped mappings form spaces layout standard layout mappings mappings boundary mapped boundaries
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            canAdvance
                ? "Save"
                : "Next", // Matched strings logic tie maps exactly! mappings boundaries
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (currentStep == 3) {
      if (!hasPhoto) {
        // Double Button (Figma 04.11) layout forms mapped bounds bound form standard form space map bound spaces form
        return Column(
          children: [
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _pickProfileImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Add photo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : _finishOnboarding, // Bypasses instantly and saves safely layouts forms mappings
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Skip for now",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      } else {
        // Single Continue Button (Figma 04.12) spaces mapping
        return SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _finishOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      }
    }
    return const SizedBox.shrink(); // fallback safety boundary limit boundary limits constraints space constraints mapped
  }

  // ──────────────────────────────────────────────────────────
  // Shared Form Theme Builder
  // ──────────────────────────────────────────────────────────
  Widget _buildFigmaField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTapTrigger,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    bool isError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTapTrigger,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: textBlack,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: isError
              ? (_) => setState(() => _passwordErrorText = null)
              : null,
          decoration: InputDecoration(
            hintText: hint,
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
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9AA4B2),
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isError ? errorRed : borderGrey,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isError ? errorRed : primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),

        if (isError && errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error, color: errorRed, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _genderPillSelection(String optionTitle, IconData iconValue) {
    final isSelected = gender == optionTitle;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = optionTitle),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryBlue : borderGrey,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconValue,
                color: isSelected ? Colors.white : labelGrey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                optionTitle,
                style: TextStyle(
                  color: isSelected ? Colors.white : textBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// STANDARD SOCIAL WIDGET LOGIC bounds boundaries maps boundaries limit bounds bounds
// ─────────────────────────────────────────────────────────
class _SocialProviderButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Widget iconWidget;
  final VoidCallback onTap;
  const _SocialProviderButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackGoogleIcon extends StatelessWidget {
  const _FallbackGoogleIcon();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      width: 24,
      child: Center(
        child: Text(
          "G",
          style: TextStyle(
            color: Color(0xFFDB4437),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
