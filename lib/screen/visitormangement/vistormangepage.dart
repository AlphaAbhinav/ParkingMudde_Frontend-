import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  static const Color primaryBlue = Color(0XFF184B8C);

  bool isLoading = true;
  bool isLinked = true;
  String? userId;
  String? message;
  List<dynamic> visitors = [];

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    setState(() => isLoading = true);
    final user = await ApiService.getStoredUser();
    final storedUserId = user?["user_id"]?.toString();
    if (storedUserId == null || storedUserId.isEmpty) {
      if (!mounted) return;
      setState(() {
        userId = null;
        visitors = [];
        isLinked = false;
        message = "Please login to manage visitor entries.";
        isLoading = false;
      });
      return;
    }

    final result = await ApiService.getMyVisitors(storedUserId);
    if (!mounted) return;
    setState(() {
      userId = storedUserId;
      isLinked = result["linked"] == true;
      message = result["message"]?.toString();
      visitors = result["visitors"] is List ? result["visitors"] : [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryBlue,
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Gate Approvals",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      floatingActionButton: isLinked && !isLoading
          ? FloatingActionButton.extended(
              onPressed: () => _showAddVisitorSheet(context),
              backgroundColor: primaryBlue,
              elevation: 4,
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                "Pre-Approve Entry",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadVisitors,
        color: primaryBlue,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : !isLinked
                ? _buildUnlinkedState()
                : visitors.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(
                          top: 24,
                          left: 16,
                          right: 16,
                          bottom: 96,
                        ),
                        itemCount: visitors.length,
                        itemBuilder: (context, index) {
                          return _visitorCard(visitors[index]);
                        },
                      ),
      ),
    );
  }

  Widget _visitorCard(dynamic visitor) {
    final status = visitor["status"]?.toString() ?? "PENDING";
    final vehicleNumber = visitor["vehicle_number"]?.toString() ?? "";
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);
    final visitorId = visitor["id"]?.toString() ?? "";
    final isPending = status.toUpperCase() == "PENDING";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        color: primaryBlue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visitor["name"]?.toString() ?? "Visitor",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _infoLine(
                            Icons.phone_iphone_rounded,
                            visitor["mobile_number"]?.toString() ?? "",
                          ),
                        ],
                      ),
                    ),
                    _statusChip(status, statusColor, statusIcon),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoLine(
                            Icons.assignment_ind_outlined,
                            visitor["purpose"]?.toString() ?? "Visit",
                          ),
                          const SizedBox(height: 8),
                          _infoLine(
                            Icons.access_time_rounded,
                            _formatDate(visitor["expected_at"] ?? visitor["created_at"]),
                          ),
                        ],
                      ),
                    ),
                    if (vehicleNumber.trim().isNotEmpty)
                      _miniLicensePlateView(vehicleNumber)
                    else
                      _walkInChip(),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 2),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 17,
                  color: Colors.blueGrey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusHelpText(status),
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isPending && visitorId.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _confirmCancel(visitorId),
                    icon: const Icon(Icons.cancel_outlined, size: 15),
                    label: const Text(
                      "Cancel Pass",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusHelpText(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return "Waiting for society admin/security approval.";
      case "APPROVED":
        return "Approved by society admin/security.";
      case "CHECKED_IN":
        return "Visitor is checked in by gate security.";
      case "CHECKED_OUT":
        return "Visitor has checked out.";
      case "REJECTED":
        return "Visitor pass was rejected by society admin/security.";
      default:
        return "Society admin/security manages this visitor pass.";
    }
  }

  Widget _statusChip(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status.replaceAll("_", " "),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey.shade400),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value.isEmpty ? "N/A" : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniLicensePlateView(String regNumber) {
    return Container(
      height: 30,
      constraints: const BoxConstraints(maxWidth: 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            color: Colors.blue.shade800,
            alignment: Alignment.center,
            child: const Text(
              "IND",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                regNumber.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Colors.black87,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walkInChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "Walk-In",
        style: TextStyle(
          color: Colors.black45,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.gpp_good_outlined, size: 50, color: Colors.blueGrey),
        const SizedBox(height: 24),
        Text(
          "Secure Campus Log",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Upcoming visitors and delivery gate entries directed to you will appear here.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinkedState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.apartment_rounded, size: 50, color: primaryBlue),
        const SizedBox(height: 24),
        const Text(
          "Community Link Required",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          message ??
              "Ask your community admin to add your resident record using your account mobile number.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey.shade500,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showAddVisitorSheet(BuildContext context) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final purposeController = TextEditingController();
    final vehicleController = TextEditingController();
    DateTime? expectedAt;

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 30,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Authorize Guest Pass",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _field(
                    controller: nameController,
                    label: "Visitor Name",
                    hint: "Rahul Sharma",
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: mobileController,
                          label: "Mobile",
                          hint: "10-digit mobile",
                          icon: Icons.dialpad_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: purposeController,
                          label: "Purpose",
                          hint: "Delivery",
                          icon: Icons.label_important_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: vehicleController,
                    label: "Vehicle Number",
                    hint: "Optional",
                    icon: Icons.commute_rounded,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDate: DateTime.now(),
                      );
                      if (pickedDate == null) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime == null) return;
                      setModalState(() {
                        expectedAt = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded, color: Colors.blueGrey.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              expectedAt == null
                                  ? "Select expected visit time"
                                  : _formatDate(expectedAt!.toIso8601String()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        await _createVisitor(
                          nameController.text.trim(),
                          mobileController.text,
                          purposeController.text.trim(),
                          vehicleController.text.trim(),
                          expectedAt,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text(
                        "Transmit Entry Security Pass",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createVisitor(
    String name,
    String mobile,
    String purpose,
    String vehicle,
    DateTime? expectedAt,
  ) async {
    if (userId == null || userId!.isEmpty) return;
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.isEmpty || cleanMobile.length != 10 || purpose.isEmpty) {
      Get.snackbar(
        "Missing Details",
        "Enter visitor name, valid mobile number, and purpose.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final result = await ApiService.createVisitorPass(
      userId: userId!,
      name: name,
      mobileNumber: cleanMobile,
      purpose: purpose,
      vehicleNumber: vehicle,
      expectedAt: expectedAt?.toIso8601String(),
    );

    if (result["success"] == true) {
      Get.back();
      await _loadVisitors();
      Get.snackbar(
        "Gate Pass Created ✓",
        "Visitor pass pending approval. Share pass ID: ${(result['id'] ?? '').toString().split('-').first.toUpperCase()}",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        "Could Not Create Pass",
        result["message"] ?? "Please try again.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmCancel(String visitorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Visitor Pass"),
        content: const Text(
          "This will remove the pending visitor pass. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Keep"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
    if (confirmed != true || userId == null) return;
    final result = await ApiService.cancelVisitorPass(
      visitorId: visitorId,
      userId: userId!,
    );
    if (!mounted) return;
    if (result["success"] == true) {
      await _loadVisitors();
      Get.snackbar(
        "Pass Cancelled",
        "The visitor pass has been removed.",
        backgroundColor: Colors.blueGrey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "Error",
        result["message"] ?? "Could not cancel.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "APPROVED":
      case "CHECKED_IN":
        return Colors.green.shade600;
      case "CHECKED_OUT":
        return Colors.blueGrey.shade500;
      case "REJECTED":
        return Colors.red.shade600;
      default:
        return Colors.amber.shade700;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case "APPROVED":
        return Icons.how_to_reg_rounded;
      case "CHECKED_IN":
        return Icons.login_rounded;
      case "CHECKED_OUT":
        return Icons.output_rounded;
      case "REJECTED":
        return Icons.block_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? "");
    if (date == null) return "Time not set";
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, "0");
    final suffix = date.hour >= 12 ? "PM" : "AM";
    return "${date.day}/${date.month}/${date.year} - $hour:$minute $suffix";
  }
}
