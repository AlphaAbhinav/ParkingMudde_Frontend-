import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for the cool scroll wheel (Cupertino Picker)
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/visitor_sound_player.dart';

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
  bool isLoadingCommunityForm = false;
  bool hasExistingSocietyRequest = false;
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

    final hasStoredSocietyRequest =
        _hasValue(user?["society_id"]) || _hasValue(user?["resident_id"]);
    final community = await ApiService.getMyCommunity(storedUserId);
    if (!mounted) return;
    final communityMessage = community["message"]?.toString() ?? "";
    final resident = community["resident"] is Map
        ? Map<String, dynamic>.from(community["resident"])
        : null;
    final hasCommunityRecord =
        community["society"] != null || community["resident"] != null;
    final isCommunityPending =
        (community["linked"] != true && hasStoredSocietyRequest) ||
        (community["linked"] != true && hasCommunityRecord) ||
        community["pending"] == true ||
        resident?["status"]?.toString().toUpperCase() == "PENDING" ||
        _isPendingApprovalMessage(communityMessage);
    if (isCommunityPending) {
      setState(() {
        userId = storedUserId;
        visitors = [];
        isLinked = false;
        hasExistingSocietyRequest = true;
        message = "Society admin approval is pending";
        isLoading = false;
      });
      return;
    }

    final result = await ApiService.getMyVisitors(storedUserId);
    if (!mounted) return;
    final resultMessage = result["message"]?.toString();
    final resultIsPending = _isPendingApprovalMessage(resultMessage);
    final fetchedVisitors = result["visitors"] is List
        ? List<dynamic>.from(result["visitors"])
        : <dynamic>[];
    await _playVisitorApprovalSounds(fetchedVisitors);
    if (!mounted) return;
    setState(() {
      userId = storedUserId;
      isLinked = result["linked"] == true;
      hasExistingSocietyRequest = hasStoredSocietyRequest || resultIsPending;
      message = resultIsPending
          ? "Society admin approval is pending"
          : resultMessage;
      visitors = fetchedVisitors;
      isLoading = false;
    });
  }

  Future<void> _playVisitorApprovalSounds(List<dynamic> fetchedVisitors) async {
    final prefs = await SharedPreferences.getInstance();
    final played =
        prefs.getStringList("visitor_approval_sound_played_ids")?.toSet() ??
        <String>{};
    final newlyApproved = <String>[];

    for (final visitor in fetchedVisitors) {
      if (visitor is! Map) continue;
      final id = visitor["id"]?.toString();
      final status = visitor["status"]?.toString().toUpperCase();
      if (id == null || id.isEmpty || status != "APPROVED") continue;
      if (!played.contains(id)) newlyApproved.add(id);
    }

    if (newlyApproved.isEmpty) return;
    played.addAll(newlyApproved);
    await prefs.setStringList(
      "visitor_approval_sound_played_ids",
      played.toList(),
    );
    await VisitorSoundPlayer.instance.playOnce();
  }

  bool _hasValue(dynamic value) {
    final text = value?.toString().trim();
    return text != null && text.isNotEmpty && text.toLowerCase() != "null";
  }

  bool _isPendingApprovalMessage(String? value) {
    final normalized = (value ?? "").toLowerCase();
    return normalized.contains("pending") ||
        normalized.contains("approval") ||
        normalized.contains("already applied") ||
        normalized.contains("already requested") ||
        normalized.contains("already waiting") ||
        normalized.contains("society request");
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
                            _formatDate(
                              visitor["expected_at"] ?? visitor["created_at"],
                            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _confirmCancel(visitorId),
                    icon: const Icon(Icons.cancel_outlined, size: 15),
                    label: const Text(
                      "Cancel Pass",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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
    final isPendingApproval =
        hasExistingSocietyRequest || _isPendingApprovalMessage(message);
    final title = isPendingApproval
        ? "Society Request Pending"
        : "Community Link Required";
    final body = isPendingApproval
        ? (message ??
              "Your society request has been sent and is waiting for society admin approval.")
        : (message ??
              "Ask your community admin to add your resident record using your account mobile number.");
    final icon = isPendingApproval
        ? Icons.hourglass_top_rounded
        : Icons.apartment_rounded;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 50, color: primaryBlue),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey.shade500,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (isPendingApproval) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFEA580C),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You can create visitor passes after society admin approval.",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!isPendingApproval && userId != null && userId!.isNotEmpty) ...[
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoadingCommunityForm
                  ? null
                  : _openCommunityRequestSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: isLoadingCommunityForm
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add_home_work_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              label: const Text(
                "Add Society",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openCommunityRequestSheet() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoadingCommunityForm = true);
    final profile =
        await ApiService.refreshCurrentUser() ??
        await ApiService.getStoredUser();
    final community = await ApiService.getMyCommunity(userId!);
    final societiesResponse = await ApiService.getSocieties();
    if (!mounted) return;
    setState(() => isLoadingCommunityForm = false);

    if (profile == null) {
      Get.snackbar(
        "Login Required",
        "Please login again to request society access.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final communityMessage = community["message"]?.toString();
    final communityResident = community["resident"] is Map
        ? Map<String, dynamic>.from(community["resident"])
        : null;
    final alreadyRequested =
        _hasValue(profile["society_id"]) ||
        _hasValue(profile["resident_id"]) ||
        community["pending"] == true ||
        (community["linked"] != true &&
            (community["society"] != null || community["resident"] != null)) ||
        communityResident?["status"]?.toString().toUpperCase() == "PENDING" ||
        _isPendingApprovalMessage(communityMessage);
    if (alreadyRequested) {
      setState(() {
        hasExistingSocietyRequest = true;
        isLinked = false;
        message = "Society admin approval is pending";
        visitors = [];
      });
      Get.snackbar(
        "Request Pending",
        "Your society request is already waiting for society admin approval.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (societiesResponse["success"] != true) {
      Get.snackbar(
        "Could Not Load Societies",
        societiesResponse["message"] ?? "Please try again.",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final societies = societiesResponse["societies"] is List
        ? societiesResponse["societies"] as List<dynamic>
        : <dynamic>[];
    if (societies.isEmpty) {
      Get.snackbar(
        "No Societies Found",
        "No communities are available right now.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _showCommunityRequestSheet(profile, societies);
  }

  void _showCommunityRequestSheet(
    Map<String, dynamic> profile,
    List<dynamic> societies,
  ) {
    String? selectedSocietyId = profile["society_id"]?.toString();
    if (selectedSocietyId != null &&
        !societies.any(
          (society) => society["id"]?.toString() == selectedSocietyId,
        )) {
      selectedSocietyId = null;
    }
    final towerController = TextEditingController();
    final flatController = TextEditingController();
    bool isSubmitting = false;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                          Icons.apartment_rounded,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Request Society Access",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting ? null : () => Get.back(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Select Society",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedSocietyId,
                    items: societies.map((society) {
                      return DropdownMenuItem<String>(
                        value: society["id"].toString(),
                        child: Text(
                          society["name"].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            setModalState(() => selectedSocietyId = value);
                          },
                    decoration: InputDecoration(
                      hintText: "Select community",
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      prefixIcon: Icon(
                        Icons.location_city_rounded,
                        color: Colors.blueGrey.shade400,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: towerController,
                          label: "Tower / Block",
                          hint: "e.g. Tower A",
                          icon: Icons.business_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: flatController,
                          label: "Flat / Unit",
                          hint: "e.g. 101",
                          icon: Icons.door_front_door_rounded,
                        ),
                      ),
                    ],
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
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              await _submitCommunityRequest(
                                profile: profile,
                                societyId: selectedSocietyId,
                                tower: towerController.text.trim(),
                                unitNumber: flatController.text.trim(),
                              );
                              if (ctx.mounted) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text(
                        "Send Request",
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

  Future<void> _submitCommunityRequest({
    required Map<String, dynamic> profile,
    required String? societyId,
    required String tower,
    required String unitNumber,
  }) async {
    if (userId == null || userId!.isEmpty) return;
    if (societyId == null || societyId.isEmpty) {
      Get.snackbar(
        "Missing Info",
        "Please select a community first.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (unitNumber.isEmpty) {
      Get.snackbar(
        "Missing Info",
        "Flat / Unit Number is required.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final fullName = (profile["full_name"]?.toString() ?? "").trim();
    final mobileNumber = (profile["mobile_number"]?.toString() ?? "")
        .replaceAll(RegExp(r'[^0-9]'), '');
    final email = (profile["email"]?.toString() ?? "").trim().toLowerCase();
    if (fullName.isEmpty ||
        !RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobileNumber) ||
        email.isEmpty) {
      Get.snackbar(
        "Profile Missing",
        "Please complete your name, mobile number, and email in profile first.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final result = await ApiService.updateUserProfile(
      userId: userId!,
      fullName: fullName,
      mobileNumber: mobileNumber,
      email: email,
      societyId: societyId,
      tower: tower,
      unitNumber: unitNumber,
    );

    if (!mounted) return;
    if (result["success"] == true) {
      Get.back();
      setState(() {
        isLinked = false;
        message = "Society admin approval is pending";
        visitors = [];
      });
      await _loadVisitors();
      Get.snackbar(
        "Request Sent",
        "Your society access request has been sent for approval.",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      final errorMessage = (result["message"] ?? "Please try again.")
          .toString();
      final normalizedError = errorMessage.toLowerCase();
      final isPendingRequest =
          normalizedError.contains("already") &&
          normalizedError.contains("pending") &&
          normalizedError.contains("society admin");
      if (isPendingRequest) {
        Get.back();
        setState(() {
          isLinked = false;
          message = "Society admin approval is pending";
          visitors = [];
        });
        Get.snackbar(
          "Request Pending",
          "Your society request is already waiting for society admin approval.",
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      Get.snackbar(
        "Could Not Send Request",
        errorMessage,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

                  // Enhanced Expected Date & "Cool Spinner" Time Setup Starts Here:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Expected Date & Time",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          // Standard Material Date Picker Calendar
                          final pickedDate = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            initialDate: DateTime.now(),
                            builder: (BuildContext ctx2, Widget? child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryBlue,
                                    onPrimary: Colors.white,
                                    onSurface: Color(0xFF1E293B),
                                  ),
                                  dialogTheme: DialogThemeData(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryBlue,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate == null) return;

                          if (!context.mounted) return;

                          // Completely Replaced: iOS-style "Cool" Spinning Wheel Modal
                          final pickedTime =
                              await showModalBottomSheet<TimeOfDay>(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (BuildContext sheetCtx) {
                                  TimeOfDay tempTime = TimeOfDay.now();
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(28),
                                      ),
                                    ),
                                    padding: EdgeInsets.only(
                                      top: 16,
                                      bottom:
                                          MediaQuery.of(
                                                sheetCtx,
                                              ).padding.bottom >
                                              0
                                          ? MediaQuery.of(
                                              sheetCtx,
                                            ).padding.bottom
                                          : 20,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(sheetCtx),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                ),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: Colors
                                                        .blueGrey
                                                        .shade400,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              const Text(
                                                "Expected Time",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  sheetCtx,
                                                  tempTime,
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                ),
                                                child: const Text(
                                                  "Done",
                                                  style: TextStyle(
                                                    color: primaryBlue,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(),
                                        SizedBox(
                                          height: 216,
                                          child: CupertinoDatePicker(
                                            mode: CupertinoDatePickerMode.time,
                                            initialDateTime: DateTime(
                                              pickedDate.year,
                                              pickedDate.month,
                                              pickedDate.day,
                                              TimeOfDay.now().hour,
                                              TimeOfDay.now().minute,
                                            ),
                                            onDateTimeChanged:
                                                (DateTime newDateTime) {
                                                  tempTime = TimeOfDay(
                                                    hour: newDateTime.hour,
                                                    minute: newDateTime.minute,
                                                  );
                                                },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.blueGrey.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  expectedAt == null
                                      ? "Select date and time"
                                      : _formatDate(
                                          expectedAt!.toIso8601String(),
                                        ),
                                  style: TextStyle(
                                    color: expectedAt == null
                                        ? Colors.blueGrey.shade600
                                        : Colors.black87,
                                    fontWeight: expectedAt == null
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                    fontSize: expectedAt == null ? 15 : 15,
                                  ),
                                ),
                              ),
                              if (expectedAt != null)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
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
    if (name.isEmpty || purpose.isEmpty) {
      Get.snackbar(
        "Missing Details",
        "Enter visitor name and purpose.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanMobile)) {
      Get.snackbar(
        "Invalid Mobile",
        "Enter a 10-digit mobile number starting with 6, 7, 8, or 9.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (vehicle.trim().isNotEmpty &&
        !RegExp(
          r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$',
        ).hasMatch(vehicle.replaceAll(' ', '').toUpperCase())) {
      Get.snackbar(
        "Invalid Vehicle",
        "Enter a valid Indian vehicle number.",
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
          "This will remove the pending visitor pass. Are you sure?",
        ),
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
