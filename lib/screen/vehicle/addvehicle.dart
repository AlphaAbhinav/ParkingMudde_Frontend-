import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/utils/vehicle_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class AddVehicleScreen extends StatefulWidget {
  final dynamic edit;
  final bool fromRegistration;
  final bool fromMyVehicles;
  const AddVehicleScreen({
    super.key,
    this.edit,
    this.fromRegistration = false,
    this.fromMyVehicles = false,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  // Toggle states
  int selectedRole = 0; // 0 for Owner, 1 for Driver
  int selectedVehicleType = 0; // Car(0), Bike(1), Scooter(2), Commercial(3)
  int selectedFuel = 0; // Petrol(0), Diesel(1), CNG(2), Electric(3)

  final List<String> vehicleTypeOptions = [
    "Car",
    "Bike",
    "Scooter",
    "Commercial",
  ];
  final List<String> fuelOptions = ["Petrol", "Diesel", "CNG", "Electric"];

  // Controllers
  final descriptionController = TextEditingController();
  final kmDrivenController = TextEditingController();
  final pollutionExpiryController = TextEditingController();
  final ownerNameController = TextEditingController();
  final customBrandController = TextEditingController();
  final customModelController = TextEditingController();

  bool isOtherBrand = false;
  bool isOtherModel = false;
  String selectedBrand = "";
  String selectedModel = "";
  int brandKey = 0;
  int modelKey = 0;

  final yearController = TextEditingController();
  final regController = TextEditingController();
  final expiryController = TextEditingController();
  final mobileController = TextEditingController();
  final relationshipController = TextEditingController();

  bool isLoading = false;
  String? suggestedMobileNumber;

  // Modern UI Colors
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);
  static const Color fieldFill = Color(0xFFF1F5F9);
  static const Color fieldBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadSuggestedMobile();
  }

  Future<void> _loadSuggestedMobile() async {
    final user = await ApiService.getStoredUser();
    final mobile = user?["mobile_number"]?.toString();
    if (!mounted || mobile == null || mobile.isEmpty) return;
    setState(
      () => suggestedMobileNumber = mobile.replaceAll(RegExp(r'[^0-9]'), ''),
    );
  }

  bool get isEditing => widget.edit is Map;

  Map<String, dynamic>? get editVehicle {
    if (widget.edit is Map) {
      return Map<String, dynamic>.from(widget.edit as Map);
    }
    return null;
  }

  String? get editVehicleId {
    final vehicle = editVehicle;
    if (vehicle == null) return null;
    return vehicle["id"]?.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefillEditVehicle();
  }

  bool _hasPrefilledEditVehicle = false;

  void _prefillEditVehicle() {
    if (_hasPrefilledEditVehicle) return;
    final vehicle = editVehicle;
    if (vehicle == null) return;

    _hasPrefilledEditVehicle = true;
    final role = vehicle["owner_role"]?.toString().toLowerCase();
    final vehicleType = vehicle["vehicle_type"]?.toString();
    final fuel = vehicle["fuel_type"]?.toString();
    final vehicleTypeIndex = vehicleTypeOptions.indexWhere(
      (option) => option.toLowerCase() == vehicleType?.toLowerCase(),
    );
    final fuelIndex = fuelOptions.indexWhere(
      (option) => option.toLowerCase() == fuel?.toLowerCase(),
    );

    selectedRole = role == "driver" ? 1 : 0;
    selectedVehicleType = vehicleTypeIndex >= 0
        ? vehicleTypeIndex
        : selectedVehicleType;
    selectedFuel = fuelIndex >= 0 ? fuelIndex : selectedFuel;
    final initialBrand =
        vehicle["brand_name"]?.toString() ??
        vehicle["owner_first_name"]?.toString() ??
        "";
    final initialModel =
        vehicle["model_name"]?.toString() ??
        vehicle["owner_last_name"]?.toString() ??
        "";

    final currentType = vehicleTypeOptions[selectedVehicleType];
    final availableBrands =
        VehicleData.indianVehicleData[currentType]?.keys.toList() ?? [];

    if (initialBrand.isNotEmpty && !availableBrands.contains(initialBrand)) {
      isOtherBrand = true;
      selectedBrand = "Others";
      customBrandController.text = initialBrand;
    } else {
      selectedBrand = initialBrand;
    }

    final availableModels =
        VehicleData.indianVehicleData[currentType]?[selectedBrand] ?? [];
    if (initialModel.isNotEmpty && !availableModels.contains(initialModel)) {
      isOtherModel = true;
      selectedModel = "Others";
      customModelController.text = initialModel;
    } else {
      selectedModel = initialModel;
    }

    yearController.text = vehicle["purchase_year"]?.toString() ?? "";
    descriptionController.text = vehicle["description"]?.toString() ?? "";
    kmDrivenController.text = vehicle["km_driven"]?.toString() ?? "";
    regController.text = vehicle["registration_number"]?.toString() ?? "";
    expiryController.text = vehicle["insurance_expiry_date"]?.toString() ?? "";
    pollutionExpiryController.text =
        vehicle["pollution_expiry_date"]?.toString() ?? "";
    mobileController.text = vehicle["registered_mobile"]?.toString() ?? "";
    relationshipController.text =
        vehicle["owner_relationship"]?.toString() ?? "";
  }

  @override
  void dispose() {
    descriptionController.dispose();
    kmDrivenController.dispose();
    pollutionExpiryController.dispose();
    ownerNameController.dispose();
    customBrandController.dispose();
    customModelController.dispose();
    yearController.dispose();
    regController.dispose();
    expiryController.dispose();
    mobileController.dispose();
    relationshipController.dispose();
    super.dispose();
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      Get.snackbar(
        "Link Error",
        "Could not open this link. Please try again.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleSubmit() async {
    final finalBrand = isOtherBrand
        ? customBrandController.text.trim()
        : selectedBrand.trim();
    final finalModel = isOtherModel
        ? customModelController.text.trim()
        : selectedModel.trim();

    if (finalBrand.isEmpty ||
        finalModel.isEmpty ||
        yearController.text.trim().isEmpty ||
        regController.text.trim().isEmpty ||
        expiryController.text.trim().isEmpty ||
        pollutionExpiryController.text.trim().isEmpty) {
      Get.snackbar(
        "Required Fields Missing",
        "Please fill in all the required fields before proceeding.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedRole == 1 &&
        (ownerNameController.text.trim().isEmpty ||
            mobileController.text.trim().isEmpty ||
            relationshipController.text.trim().isEmpty)) {
      Get.snackbar(
        "Missing Owner Information",
        "Please provide the owner's name, mobile number, and your relationship.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final vehRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    if (!vehRegex.hasMatch(
      regController.text.trim().toUpperCase().replaceAll(' ', ''),
    )) {
      Get.snackbar(
        "Invalid Registration Format",
        "Please enter a valid Indian vehicle registration number (e.g. MH01AB1234).",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final currentYear = DateTime.now().year;
    final purchaseYear = int.tryParse(yearController.text.trim());
    if (purchaseYear != null && purchaseYear > currentYear) {
      Get.snackbar(
        "Invalid Purchase Year",
        "The purchase year cannot be in the future.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final registeredMobile = selectedRole == 1
        ? mobileController.text.trim()
        : (suggestedMobileNumber?.isNotEmpty == true
              ? suggestedMobileNumber!
              : mobileController.text.trim());

    if (!RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(registeredMobile.replaceAll(RegExp(r'[^0-9]'), ''))) {
      Get.snackbar(
        "Owner Mobile Required",
        selectedRole == 1
            ? "Enter a valid 10-digit vehicle owner mobile number."
            : "Your account mobile number is missing. Please enter owner mobile number.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");

    if (userId == null) {
      Get.snackbar("Error", "Session invalid, user not logged in");
      setState(() => isLoading = false);
      return;
    }

    try {
      final String userFullName = prefs.getString("full_name") ?? "";
      final List<String> nameParts = userFullName.trim().split(" ");
      final String userFirstName = nameParts.isNotEmpty ? nameParts.first : "";
      final String userLastName = nameParts.length > 1
          ? nameParts.skip(1).join(" ")
          : "";

      final String ownerNameStr = ownerNameController.text.trim();
      final List<String> ownerNameParts = ownerNameStr.split(" ");
      final String parsedOwnerFirst = ownerNameParts.isNotEmpty
          ? ownerNameParts.first
          : "";
      final String parsedOwnerLast = ownerNameParts.length > 1
          ? ownerNameParts.skip(1).join(" ")
          : "";

      final String finalOwnerFirst = selectedRole == 1
          ? parsedOwnerFirst
          : userFirstName;
      final String finalOwnerLast = selectedRole == 1
          ? parsedOwnerLast
          : userLastName;

      final result = isEditing
          ? await ApiService.updateVehicle(
              vehicleId: editVehicleId!,
              userId: userId,
              ownerFirstName: finalOwnerFirst,
              ownerLastName: finalOwnerLast,
              brandName: finalBrand,
              modelName: finalModel,
              vehicleType: vehicleTypeOptions[selectedVehicleType],
              fuelType: fuelOptions[selectedFuel],
              registrationNumber: regController.text.trim(),
              registeredMobile: registeredMobile,
              ownerRole: selectedRole == 0 ? "Owner" : "Driver",
              purchaseYear: yearController.text.trim(),
              description: descriptionController.text.trim(),
              kmDriven: kmDrivenController.text.trim(),
              insuranceExpiryDate: expiryController.text.trim(),
              pollutionExpiryDate: pollutionExpiryController.text.trim(),
              ownerRelationship: relationshipController.text.trim(),
            )
          : await ApiService.addVehicle(
              userId: userId,
              ownerFirstName: finalOwnerFirst,
              ownerLastName: finalOwnerLast,
              brandName: finalBrand,
              modelName: finalModel,
              vehicleType: vehicleTypeOptions[selectedVehicleType],
              fuelType: fuelOptions[selectedFuel],
              registrationNumber: regController.text.trim(),
              registeredMobile: registeredMobile,
              ownerRole: selectedRole == 0 ? "Owner" : "Driver",
              purchaseYear: yearController.text.trim(),
              description: descriptionController.text.trim(),
              kmDriven: kmDrivenController.text.trim(),
              insuranceExpiryDate: expiryController.text.trim(),
              pollutionExpiryDate: pollutionExpiryController.text.trim(),
              ownerRelationship: relationshipController.text.trim(),
            );

      if (result != null && result["success"] == true) {
        if (isEditing) {
          Get.back(result: true);
        } else {
          // Perform navigation FIRST
          if (widget.fromRegistration) {
            Get.offAll(() => const Dash(fromRegistration: true));
          } else if (widget.fromMyVehicles) {
            Get.back(result: true);
          } else {
            Get.off(() => const MyVehiclesScreen());
          }

          // Delay the snackbar slightly so it doesn't get popped by Get.back()
          // or block the route transitions.
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.snackbar(
              "Success",
              "Vehicle added successfully. PM Coins added to your wallet.",
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white,
            );
          });
        }
      } else {
        Get.snackbar(
          "Transaction Failed",
          result?["message"] ??
              "Submission could not be completed at this time.",
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Network Error",
        "An unexpected issue occurred: $e",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            bgSurface, // Switched to premium subtle grey background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: widget.fromRegistration
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textDark,
                    size: 20,
                  ),
                  onPressed: () => Get.back(),
                ),
          title: Text(
            isEditing ? "Edit Vehicle" : "Add Vehicle",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          centerTitle: false,
          actions: [
            if (widget.fromRegistration)
              TextButton(
                onPressed: () =>
                    Get.offAll(() => const Dash(fromRegistration: true)),
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Color(0xFFC0CAD8),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Dual-Toggle Center
                      Center(child: _buildRoleSelector()),
                      const SizedBox(height: 32),

                      _buildPremiumFieldLabel("Vehicle Type", isRequired: true),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(vehicleTypeOptions.length, (
                          index,
                        ) {
                          final isVehicleTypeSelected =
                              selectedVehicleType == index;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = index;
                                selectedBrand = "";
                                selectedModel = "";
                                isOtherBrand = false;
                                isOtherModel = false;
                                brandKey++;
                                modelKey++;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isVehicleTypeSelected
                                    ? primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isVehicleTypeSelected
                                      ? primaryBlue
                                      : fieldBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                vehicleTypeOptions[index],
                                style: TextStyle(
                                  color: isVehicleTypeSelected
                                      ? Colors.white
                                      : textDark,
                                  fontWeight: isVehicleTypeSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel("Brand Name", isRequired: true),
                      _buildSearchableDropdown(
                        key: ValueKey("brand_$brandKey"),
                        hintText: "Select or search brand",
                        initialValue: selectedBrand,
                        options: [
                          ...(VehicleData
                                  .indianVehicleData[vehicleTypeOptions[selectedVehicleType]]
                                  ?.keys ??
                              []),
                          "Others",
                        ],
                        onSelected: (val) {
                          setState(() {
                            selectedBrand = val;
                            isOtherBrand = val == "Others";
                            selectedModel = "";
                            isOtherModel = false;
                            modelKey++;
                          });
                        },
                      ),
                      if (isOtherBrand) ...[
                        const SizedBox(height: 16),
                        _buildPremiumFieldLabel(
                          "Custom Brand Name",
                          isRequired: true,
                        ),
                        _buildFigmaTextInput(
                          customBrandController,
                          "Enter brand name",
                        ),
                      ],
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel("Model Name", isRequired: true),
                      _buildSearchableDropdown(
                        key: ValueKey("model_$modelKey"),
                        hintText: "Select or search model",
                        initialValue: selectedModel,
                        options: [
                          ...(VehicleData
                                  .indianVehicleData[vehicleTypeOptions[selectedVehicleType]]?[selectedBrand] ??
                              []),
                          "Others",
                        ],
                        onSelected: (val) {
                          setState(() {
                            selectedModel = val;
                            isOtherModel = val == "Others";
                          });
                        },
                      ),
                      if (isOtherModel) ...[
                        const SizedBox(height: 16),
                        _buildPremiumFieldLabel(
                          "Custom Model Name",
                          isRequired: true,
                        ),
                        _buildFigmaTextInput(
                          customModelController,
                          "Enter model name",
                        ),
                      ],
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel("Description", isRequired: false),
                      _buildFigmaTextInput(
                        descriptionController,
                        "Any extra identifiers (e.g. Red SUV)",
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel(
                        "Year of Purchase",
                        isRequired: true,
                      ),
                      _buildYearDropdown(),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel("KM Driven", isRequired: false),
                      _buildFigmaTextInput(
                        kmDrivenController,
                        "Approximate km reading",
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel("Fuel Type", isRequired: true),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(fuelOptions.length, (index) {
                          final isFuelSelected = selectedFuel == index;
                          return InkWell(
                            onTap: () => setState(() => selectedFuel = index),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isFuelSelected
                                    ? primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFuelSelected
                                      ? primaryBlue
                                      : fieldBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                fuelOptions[index],
                                style: TextStyle(
                                  color: isFuelSelected
                                      ? Colors.white
                                      : textDark,
                                  fontWeight: isFuelSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel(
                        "Vehicle Registration No.",
                        isRequired: true,
                      ),
                      _buildFigmaTextInput(regController, "e.g. MH01AB1234"),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => _openExternalLink(
                            "https://parivahan.gov.in/parivahan//en/content/vehicle-related-services",
                          ),
                          child: const Text(
                            "Link mobile number with RC",
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel(
                        "Insurance Expiry Date",
                        isRequired: true,
                      ),
                      _buildFigmaTextInput(
                        expiryController,
                        "Tap to select date",
                        readOnly: true,
                        onTap: () => _selectDate(expiryController),
                        suffixIcon: const Icon(
                          Icons.calendar_month_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumFieldLabel(
                        "Pollution Expiry Date",
                        isRequired: true,
                      ),
                      _buildFigmaTextInput(
                        pollutionExpiryController,
                        "Tap to select date",
                        readOnly: true,
                        onTap: () => _selectDate(pollutionExpiryController),
                        suffixIcon: const Icon(
                          Icons.calendar_month_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),

                      // RENDER ONLY IF IT IS OWNER AND NO SAVED SUGGESTION IS FOUND
                      if (selectedRole == 0 &&
                          (suggestedMobileNumber == null ||
                              suggestedMobileNumber!.isEmpty)) ...[
                        const SizedBox(height: 24),
                        _buildPremiumFieldLabel(
                          "Registered Mobile No.",
                          isRequired: true,
                        ),
                        _buildFigmaTextInput(
                          mobileController,
                          "Your mobile number",
                          inputType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      ],

                      // RENDER EXTRA FIELDS IF DRIVER
                      if (selectedRole == 1) ...[
                        const SizedBox(height: 24),
                        _buildPremiumFieldLabel(
                          "Vehicle Owner Name",
                          isRequired: true,
                        ),
                        _buildFigmaTextInput(
                          ownerNameController,
                          "Owner's full name",
                        ),

                        const SizedBox(height: 24),
                        _buildPremiumFieldLabel(
                          "Vehicle Owner Mobile No.",
                          isRequired: true,
                        ),
                        if (suggestedMobileNumber != null &&
                            suggestedMobileNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => mobileController.text =
                                    suggestedMobileNumber!,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.contact_phone_rounded,
                                        size: 16,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Use your number ($suggestedMobileNumber)",
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildFigmaTextInput(
                          mobileController,
                          "Owner's 10-digit number",
                          inputType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildPremiumFieldLabel(
                          "Owner Relationship",
                          isRequired: true,
                        ),
                        _buildFigmaTextInput(
                          relationshipController,
                          "e.g. Brother, Father, Boss",
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Base Info Footnote
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_rounded,
                              color: Colors.blueGrey.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Note: Once added, vehicles cannot be self-removed.\nOwnership transfer is subject to admin verification.",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const ScreenSlogan(
                        "Let's get your vehicle ready.",
                        color: primaryBlue,
                        icon: Icons.directions_car_rounded,
                        imagePath: 'assets/addvehicleslogan.png',
                        normalImageWidth: 158,
                        compactImageWidth: 134,
                        textMaxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky Premium Bottom Save Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 2),
                  ),
                ),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEditing ? "Update Vehicle" : "Add Vehicle",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
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

  // ---------------- UI Helpers ----------------

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFFF1F5F9,
        ), // Deep rich unified background tone for tab selection
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleTab(0, "Owner", true),
          _buildRoleTab(1, "Driver", false),
        ],
      ),
    );
  }

  Widget _buildRoleTab(int index, String title, bool leftSide) {
    bool isSelected = selectedRole == index;
    return InkWell(
      onTap: () => setState(() => selectedRole = index),
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? textDark : Colors.blueGrey.shade500,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<int> get _purchaseYears {
    final currentYear = DateTime.now().year;
    return List<int>.generate(currentYear - 1989, (index) => 1990 + index);
  }

  int get _selectedPurchaseYear {
    final typedYear = int.tryParse(yearController.text.trim());
    if (typedYear != null && _purchaseYears.contains(typedYear)) {
      return typedYear;
    }
    return _purchaseYears.contains(2020) ? 2020 : DateTime.now().year;
  }

  Future<void> _selectPurchaseYear() async {
    final years = _purchaseYears;
    var tempSelectedYear = _selectedPurchaseYear;
    final initialIndex = years.indexOf(tempSelectedYear);
    final scrollController = FixedExtentScrollController(
      initialItem: initialIndex,
    );

    final pickedYear = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: primaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Year of Purchase",
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Required vehicle detail",
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 236,
                      decoration: BoxDecoration(
                        color: fieldFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fieldBorder),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 54,
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          ListWheelScrollView.useDelegate(
                            controller: scrollController,
                            itemExtent: 54,
                            diameterRatio: 1.28,
                            squeeze: 0.92,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setSheetState(() {
                                tempSelectedYear = years[index];
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: years.length,
                              builder: (context, index) {
                                final year = years[index];
                                final isSelected = year == tempSelectedYear;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 150),
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryBlue
                                          : Colors.blueGrey.shade400,
                                      fontSize: isSelected ? 24 : 17,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                    child: Text(year.toString()),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, tempSelectedYear),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (pickedYear == null) return;
    setState(() => yearController.text = pickedYear.toString());
  }

  Widget _buildYearDropdown() {
    final hasYear = yearController.text.trim().isNotEmpty;
    return InkWell(
      onTap: _selectPurchaseYear,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasYear ? primaryBlue : fieldBorder),
          boxShadow: hasYear
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasYear ? yearController.text.trim() : "Select year",
                    style: TextStyle(
                      color: hasYear ? textDark : const Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Required vehicle detail",
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Text(
                    "Year",
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: textGrey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BRAND NEW PREMIUM FINTECH STYLE CALENDAR / DATE PICKER OVERRIDE ---
  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 20),
      helpText: 'SELECT RENEWAL DATE',
      cancelText: 'CANCEL',
      confirmText: 'CONFIRM',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryBlue,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: primaryBlue, // Highlights and headers
              onPrimary: Colors.white, // Text inside highlighted regions
              surface: Colors.white,
              onSurface: textDark,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  28,
                ), // Beautiful rounded dialogue body
              ),
              headerBackgroundColor:
                  primaryBlue, // Striking solid colored upper header box
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              headerHelpStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Colors.white70,
              ),
              weekdayStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey.shade400,
              ),
              dayStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              yearStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              // App-style squircle selectors rather than the normal native dots
              dayShape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryBlue,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    // Safely zero pads (5 to 05) exactly mapping previously mapped functional boundaries without error
    final String paddedDay = picked.day.toString().padLeft(2, '0');
    final String paddedMonth = picked.month.toString().padLeft(2, '0');

    controller.text = "$paddedDay-$paddedMonth-${picked.year}";
  }

  Widget _buildPremiumFieldLabel(String labelText, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
          children: [
            if (isRequired)
              TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaTextInput(
    TextEditingController controller,
    String placeholderHint, {
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 15,
        color: textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: placeholderHint,
        suffixIcon: suffixIcon,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: fieldBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown({
    Key? key,
    required String hintText,
    required String initialValue,
    required List<String> options,
    required void Function(String) onSelected,
  }) {
    return Autocomplete<String>(
      key: key,
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: onSelected,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            shadowColor: Colors.black.withOpacity(0.15),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: fieldBorder),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(
            fontSize: 15,
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: fieldBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryBlue, width: 2.0),
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down_circle_outlined,
              color: Colors.blueGrey,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
