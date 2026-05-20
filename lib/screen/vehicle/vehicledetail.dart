import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/services/api_service.dart';

class VehicleDetailPage extends StatefulWidget {
  final dynamic vehicle;

  const VehicleDetailPage({super.key, this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  bool _isDeleting = false;

  // ─── Delete Reason Bottom Sheet ───────────────────────────────────────────

  void showDeleteReasonSheet({
    required BuildContext context,
    required Future<void> Function(String reason) onConfirm,
  }) {
    final TextEditingController otherController = TextEditingController();
    String? selectedReason;

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const Text(
                    "Reason for Deletion",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _reasonTile(
                    "Vehicle sold",
                    selectedReason,
                    setSheetState,
                    (v) => selectedReason = v,
                  ),
                  _reasonTile(
                    "Wrong vehicle added",
                    selectedReason,
                    setSheetState,
                    (v) => selectedReason = v,
                  ),
                  _reasonTile(
                    "Duplicate entry",
                    selectedReason,
                    setSheetState,
                    (v) => selectedReason = v,
                  ),
                  _reasonTile(
                    "Other",
                    selectedReason,
                    setSheetState,
                    (v) => selectedReason = v,
                  ),

                  if (selectedReason == "Other") ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: otherController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Enter reason",
                        labelStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFFff6f61).withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFFff6f61).withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFFff6f61).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            // Validate selection
                            if (selectedReason == null) {
                              Get.snackbar(
                                "Select Reason",
                                "Please select a reason before deleting.",
                                backgroundColor: Colors.orange.shade700,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            final reason = selectedReason == "Other"
                                ? (otherController.text.trim().isEmpty
                                    ? "Other"
                                    : otherController.text.trim())
                                : selectedReason!;

                            Navigator.pop(ctx); // close sheet
                            await onConfirm(reason);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFFfdd708), size: 40),
          onPressed: () => Get.back(),
        ),
        automaticallyImplyLeading: true,
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Vehicle Details",
          style: TextStyle(fontSize: 18, color: Color(0xFFfdd708)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                "assets/car.jpeg",
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.blueGrey.shade50,
                  child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Vehicle info
            _infoCard(
              context,
              title: "Vehicle Information",
              children: [
                _infoRow(
                  "Vehicle Number",
                  vehicle["vehicle_number"]?.toString() ?? "—",
                ),
                _infoRow(
                  "Registration No",
                  vehicle["registration_number"]?.toString() ?? "—",
                ),
                _infoRow(
                  "Brand / Model",
                  "${vehicle['brand_name'] ?? vehicle['owner_first_name'] ?? '—'} ${vehicle['model_name'] ?? vehicle['owner_last_name'] ?? ''}".trim(),
                ),
                _infoRow(
                  "Fuel Type",
                  vehicle["fuel_type"]?.toString() ?? vehicle["vehicle_type"]?.toString() ?? "—",
                ),
                _infoRow(
                  "Year of Purchase",
                  vehicle["purchase_year"]?.toString() ?? "—",
                ),
                _infoRow(
                  "Insurance Expiry",
                  vehicle["insurance_expiry_date"]?.toString() ?? "—",
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Owner info
            _infoCard(
              context,
              title: "Owner Details",
              children: [
                _infoRow(
                  "Registered Mobile",
                  vehicle["registered_mobile"]?.toString() ?? "—",
                ),
                _infoRow(
                  "Owner Role",
                  vehicle["owner_role"]?.toString() ?? "—",
                ),
                _infoRow(
                  "Relationship",
                  vehicle["owner_relationship"]?.toString() ?? "—",
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Get.to(
                        () => AddVehicleScreen(edit: widget.vehicle),
                      );
                      if (updated == true) {
                        Get.back(result: true);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      "Edit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _isDeleting
                        ? null
                        : () {
                            showDeleteReasonSheet(
                              context: context,
                              onConfirm: (reason) async {
                                setState(() => _isDeleting = true);

                                final prefs =
                                    await SharedPreferences.getInstance();
                                final userId =
                                    prefs.getString("user_id") ?? "";
                                final vehicleId =
                                    vehicle["id"]?.toString() ?? "";

                                if (userId.isEmpty || vehicleId.isEmpty) {
                                  Get.snackbar(
                                    "Error",
                                    "Unable to identify vehicle or user.",
                                    backgroundColor: Colors.red.shade600,
                                    colorText: Colors.white,
                                  );
                                  setState(() => _isDeleting = false);
                                  return;
                                }

                                final result = await ApiService.deleteVehicle(
                                  vehicleId: vehicleId,
                                  userId: userId,
                                  reason: reason,
                                );

                                setState(() => _isDeleting = false);

                                if (result["success"] == true) {
                                  Get.snackbar(
                                    "Vehicle Removed",
                                    "Your vehicle has been removed from the garage.",
                                    backgroundColor: Colors.red.shade600,
                                    colorText: Colors.white,
                                  );
                                  Get.back(result: "deleted");
                                } else {
                                  Get.snackbar(
                                    "Error",
                                    result["message"] ??
                                        "Failed to delete vehicle. Try again.",
                                    backgroundColor: Colors.orange.shade700,
                                    colorText: Colors.white,
                                  );
                                }
                              },
                            );
                          },
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete, size: 20, color: Colors.white),
                    label: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isVerified ? Colors.green : Colors.black,
                ),
              ),
              if (isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reasonTile(
    String title,
    String? selected,
    StateSetter setSheetState,
    Function(String value) onSelect,
  ) {
    return RadioListTile<String>(
      value: title,
      groupValue: selected,
      onChanged: (value) {
        setSheetState(() => onSelect(value!));
      },
      title: Text(title),
      contentPadding: EdgeInsets.zero,
    );
  }
}
