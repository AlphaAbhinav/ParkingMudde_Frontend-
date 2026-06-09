import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parkingmudde/screen/account/editpage.dart';
import 'package:parkingmudde/screen/account/documentspage.dart';
import 'package:parkingmudde/screen/account/support_pages.dart';
import 'package:parkingmudde/screen/booking/mybookingspage.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/auth/loginpage.dart';
import 'package:parkingmudde/screen/notification/notificationpage.dart';
import 'package:parkingmudde/screen/parkingAlert/parkingalertpage.dart';
import 'package:parkingmudde/screen/Referal/referalpage.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/screen/wallet/walletpage.dart';
import '../../services/api_service.dart';

class Accountpage extends StatefulWidget {
  const Accountpage({super.key});

  @override
  State<Accountpage> createState() => _AccountpageState();
}

class _AccountpageState extends State<Accountpage> {
  Map<String, dynamic>? user;
  bool isLoadingUser = true;
  int walletCoins = 0;
  int vehicleCount = 0;
  int bookingCount = 0;
  int alertsRaisedByCount = 0;
  int alertsAgainstCount = 0;
  Map<String, dynamic>? communityProfile;

  // Clean unified extraction constants natively mapping layouts
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color secondaryYellow = Color(0xFFFFB703);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // --- NATIVE SECURE BACKEND INTEGRATION mapped
  Future<void> _loadUser() async {
    final storedUser = await ApiService.getStoredUser();
    if (mounted) {
      setState(() {
        user = storedUser;
        isLoadingUser = false;
      });
    }
    final storedUserId = storedUser?["user_id"]?.toString();
    if (storedUserId != null && storedUserId.isNotEmpty) {
      await _loadProfileCounts(storedUserId);
    }

    final freshUser = await ApiService.refreshCurrentUser();
    if (mounted && freshUser != null) {
      setState(() => user = freshUser);
      final userId = freshUser["user_id"]?.toString();
      if (userId != null && userId.isNotEmpty) {
        await _loadProfileCounts(userId);
      }
    }
  }

  Future<void> _loadProfileCounts(String userId) async {
    final wallet = await ApiService.getWalletBalance(userId);
    final vehicles = await ApiService.getMyVehicles(userId);
    final bookings = await ApiService.getMyBookings(userId);
    final community = await ApiService.getMyCommunity(userId);
    final alerts = await ApiService.getParkingAlerts(userId);
    final alertCounts = alerts["counts"] is Map ? alerts["counts"] as Map : {};

    if (!mounted) return;
    setState(() {
      walletCoins = int.tryParse(wallet["balance"]?.toString() ?? "0") ?? 0;
      vehicleCount = vehicles.length;
      bookingCount = bookings.length;
      alertsRaisedByCount =
          int.tryParse(alertCounts["raised_by_you"]?.toString() ?? "0") ?? 0;
      alertsAgainstCount =
          int.tryParse(alertCounts["against_you"]?.toString() ?? "0") ?? 0;
      communityProfile = community;
    });
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
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryBlue,
              size: 20,
            ),
            onPressed: () => Get.offAll(() => const Dash()),
          ),
          title: const Text(
            "My Profile",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textBlack,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER AVATAR CARD
              _buildFigmaTopHeaderProfile(),

              const SizedBox(height: 32),

              // 2. METRICS ROW CARD
              _buildFigmaMetricSquaresRow(),

              const SizedBox(height: 24),

              _buildAlertCountsCard(),

              const SizedBox(height: 24),

              _buildCommunityParkingCard(),

              const SizedBox(height: 40),

              // 3. MAIN NAV LIST
              _buildModernNavRowItem(
                icon: Icons.directions_car_rounded,
                title: "My Vehicles",
                subtitle: "Manage your vehicles",
                bgColor: const Color(0xFFEDF2FE),
                iconColor: const Color(0xFF6B8FFA),
                onTap: () => Get.to(() => const MyVehiclesScreen()),
              ),
              _buildModernNavRowItem(
                icon: Icons.history_rounded,
                title: "Activities",
                subtitle: "View your parking history",
                bgColor: const Color(0xFFFFF8E5),
                iconColor: const Color(0xFFFEBC5A),
                onTap: () => Get.to(() => const Notificationpage()),
              ),
              _buildModernNavRowItem(
                icon: Icons.confirmation_num_rounded,
                title: "My Bookings",
                subtitle: "Active & past bookings",
                bgColor: const Color(0xFFF3EBFC),
                iconColor: const Color(0xFFA14FFB),
                onTap: () => Get.to(() => const MyBookingsPage()),
              ),
              _buildModernNavRowItem(
                icon: Icons.library_books_rounded,
                title: "Identity & Vehicle Documents",
                subtitle: "Aadhaar, Driving Licence, RC",
                bgColor: const Color(0xFFEBEEFB),
                iconColor: const Color(0xFF6678EF),
                onTap: () => Get.to(() => const VehicleDocumentsPage()),
              ),
              _buildModernNavRowItem(
                icon: Icons.card_giftcard_rounded,
                title: "Refer & Earn",
                subtitle: "Share with Friends",
                bgColor: const Color(0xFFFEECF3),
                iconColor: const Color(0xFFEE499B),
                onTap: () => Get.to(() => const ReferralScreen()),
              ),

              const SizedBox(height: 32),

              // 4. INFO & SUPPORT WRAPPED LIST
              const Text(
                "Support & information",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF8F9FA,
                  ), // Soft grey grouping block bound mappings layout space standard
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildSubNavItem(
                      icon: Icons.support_agent_rounded,
                      title: "Help & Support",
                      onTap: () => Get.to(() => const HelpSupportPage()),
                    ),
                    _buildSubNavItem(
                      icon: Icons.question_answer_rounded,
                      title: "FAQs",
                      onTap: () => Get.to(() => const FaqPage()),
                    ),
                    _buildSubNavItem(
                      icon: Icons.privacy_tip_rounded,
                      title: "Privacy Policy",
                      onTap: () => Get.to(() => const PrivacyPolicyPage()),
                    ),
                    _buildSubNavItem(
                      icon: Icons.article_rounded,
                      title: "Terms & Conditions",
                      onTap: () => Get.to(() => const TermsConditionsPage()),
                    ),

                    const Divider(
                      color: Color(0xFFE2E8F0),
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                      height: 32,
                    ),

                    // Correct mappings connected standard limits
                    _buildSubNavItem(
                      icon: Icons.logout_rounded,
                      title: "Logout securely",
                      iconColor: Colors.amber.shade700,
                      titleColor: Colors.amber.shade700,
                      onTap: () => _showLogoutDialog(context),
                    ),
                    _buildSubNavItem(
                      icon: Icons.person_remove_rounded,
                      title: "Delete Account Permanently",
                      iconColor: Colors.red.shade700,
                      titleColor: Colors.red.shade700,
                      onTap: () => _showDeleteDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FIGMA EXTRACT 1: TOP PROFILE MASTHEAD bounds maps limits bound bounds constraint
  // ──────────────────────────────────────────────────────────
  Widget _buildCommunityParkingCard() {
    final profile = communityProfile;
    if (profile == null || profile["linked"] != true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.apartment_rounded, color: primaryBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "No community parking linked yet. Ask your community admin to add your resident record with this mobile/email.",
                style: TextStyle(
                  color: subTextGrey,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final society = Map<String, dynamic>.from(profile["society"] ?? {});
    final resident = Map<String, dynamic>.from(profile["resident"] ?? {});
    final assignedParking = (profile["assigned_parking"] as List?) ?? [];
    final firstSlot = assignedParking.isNotEmpty
        ? Map<String, dynamic>.from(assignedParking.first)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4FD8), Color(0xFF173B8F)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_parking_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  society["name"]?.toString() ?? "My Community",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: (resident["status"] == "PENDING") ? Colors.orange.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  resident["status"]?.toString().toUpperCase() ?? "PENDING",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  resident["kyc_status"]?.toString() ?? "KYC PENDING",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "${resident["tower"] ?? "-"} / ${resident["unit_number"] ?? "-"}",
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              firstSlot == null
                  ? "Parking slot not assigned yet"
                  : "Assigned slot: ${firstSlot["slot_number"]} (${firstSlot["level"] ?? "Level not set"})",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaTopHeaderProfile() {
    final fullName = _userValue("full_name", "Parking Mudde User");
    final mobile = _userValue("mobile_number", "Mobile not added");

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: _profileImageProvider(),
                child: _profileImageProvider() == null
                    ? Text(
                        _initials(fullName),
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () async {
                  await Get.to(() => const EditProfilePage());
                  _loadUser(); // Ensure profile rebuild
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: secondaryYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoadingUser ? "Loading..." : fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mobile == "Mobile not added"
                    ? mobile
                    : (!mobile.startsWith('+') ? "+91 $mobile" : mobile),
                style: const TextStyle(
                  fontSize: 13,
                  color: subTextGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  await Get.to(() => const EditProfilePage());
                  _loadUser();
                },
                child: const Text(
                  "Edit Profile >",
                  style: TextStyle(
                    color: secondaryYellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // FIGMA EXTRACT 2: STAT CARDS mappings
  // ──────────────────────────────────────────────────────────
  Widget _buildFigmaMetricSquaresRow() {
    return Row(
      children: [
        Expanded(
          child: _metricSquareBox(
            bgColor: const Color(0xFFEFF5FE),
            borderColor: const Color(0xFFD6E3F9),
            iconBg: primaryBlue,
            iconColor: Colors.white,
            icon: Icons.directions_car_rounded,
            label: "Vehicles",
            value: vehicleCount.toString(),
            onTap: () => Get.to(() => const MyVehiclesScreen()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _metricSquareBox(
            bgColor: const Color(0xFFFFFDF5),
            borderColor: const Color(0xFFFEF2CE),
            iconBg: secondaryYellow,
            iconColor: Colors.white,
            icon: Icons.account_balance_wallet_rounded,
            label: "Wallet",
            value: walletCoins.toString(),
            onTap: () => Get.to(() => WalletScreen(totalCoins: walletCoins)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _metricSquareBox(
            bgColor: const Color(0xFFF2FDF5),
            borderColor: const Color(0xFFD2F3DD),
            iconBg: const Color(0xFF20C475),
            iconColor: Colors.white,
            icon: Icons.receipt_long_rounded,
            label: "Bookings",
            value: bookingCount.toString(),
            onTap: () => Get.to(() => const MyBookingsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCountsCard() {
    return InkWell(
      onTap: () => Get.to(() => const AlertsScreen()),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.warning_rounded, color: primaryBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Parking Alert History",
                    style: TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _alertCountPill("Raised by you", alertsRaisedByCount),
                      const SizedBox(width: 8),
                      _alertCountPill("Against you", alertsAgainstCount),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFC0CAD8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertCountPill(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                color: textBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: subTextGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricSquareBox({
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // REUSABLE BUILDERS bound
  // ──────────────────────────────────────────────────────────
  Widget _buildModernNavRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subTextGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFC0CAD8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF4C5B72),
    Color titleColor = const Color(0xFF222222),
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // --- RETAINED CORE NATIVE BACKEND LOGIC UTILS mappings maps bounds spaces space spaces forms mappings constraint limits ---
  String _userValue(String key, String fallback) {
    final value = user?[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  ImageProvider? _profileImageProvider() {
    final image = user?["profile_image"]?.toString();
    if (image == null || image.isEmpty) return null;

    if (image.startsWith("data:image")) {
      final base64Part = image.split(",").last;
      return MemoryImage(base64Decode(base64Part));
    }
    return NetworkImage(image);
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r"\s+"))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return "PM";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return "${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}"
        .toUpperCase();
  }

  // --- PRISTINE RETENTION LOGIC - Restoring Snackbars exactly per your constraints
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 34,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Close your Session?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You will need to re-verify your identity to utilize reporting pipelines upon signing out safely.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // 1. Exact Wipe Match
                        Navigator.pop(context);
                        SharedPreferences.getInstance().then(
                          (prefs) => prefs.clear(),
                        );

                        // 2. SnackBar Exactly retrieved limit mapping boundary bounds space limit
                        Get.snackbar(
                          "User Removed Successfully",
                          "Session wiped.",
                          icon: const Icon(Icons.logout, color: Colors.white),
                          backgroundColor: Colors.amber.shade800,
                          colorText: Colors.white,
                        );

                        // 3. Proper exact navigational routing preserved mapped layout
                        Get.offAll(() => const Loginpage());
                      },
                      child: const Text(
                        "Log Out",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_remove_rounded,
                  size: 34,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Delete Account Permanently?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This action cannot be undone. All your data and registered plates will be permanently erased.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);

                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString("user_id");
                        final result = userId == null
                            ? {"success": true}
                            : await ApiService.deleteAccount(userId);

                        if (result["success"] != true) {
                          Get.snackbar(
                            "Delete Failed",
                            result["message"] ?? "Please try again.",
                            backgroundColor: Colors.red.shade800,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        await prefs.clear();

                        Get.snackbar(
                          "Account Deleted",
                          "Your account has been permanently deleted.",
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                          ),
                          backgroundColor: Colors.red.shade800,
                          colorText: Colors.white,
                        );

                        Get.offAll(() => const Loginpage());
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
