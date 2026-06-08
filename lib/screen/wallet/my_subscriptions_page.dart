import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF888888);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color earnGreen = Color(0xFF20C475);

  List<dynamic> _vehicles = [];
  bool _loadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    if (userId != null) {
      final vehicles = await ApiService.getMyVehicles(userId);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _loadingVehicles = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Subscriptions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textBlack),
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          final subs = wallet.subscriptions;

          if (subs.isEmpty) {
            return _buildNoSubscriptions();
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Subscriptions Header
                const Text(
                  "Active Plans",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textBlack),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Your renewal alert subscriptions and their validity.",
                  style: TextStyle(color: subTextGrey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Subscription Cards
                ...subs.map((sub) => _buildSubscriptionCard(sub)),

                const SizedBox(height: 32),

                // Vehicle Insurance Section
                const Text(
                  "Vehicle Documents",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textBlack),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Insurance & PUC details for all your registered vehicles.",
                  style: TextStyle(color: subTextGrey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                if (_loadingVehicles)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: primaryBlue),
                  ))
                else if (_vehicles.isEmpty)
                  _buildNoVehicles()
                else
                  ..._vehicles.map((v) => _buildVehicleDocCard(v)),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Subscription Card ───────────────────────────────────
  Widget _buildSubscriptionCard(dynamic sub) {
    final packageId = sub['package_id']?.toString() ?? '';
    final status = sub['status']?.toString() ?? 'ACTIVE';
    final startDate = DateTime.tryParse(sub['start_date']?.toString() ?? '');
    final endDate = DateTime.tryParse(sub['end_date']?.toString() ?? '');
    final isActive = status == 'ACTIVE' && endDate != null && endDate.isAfter(DateTime.now());

    String packageName = packageId;
    IconData packageIcon = Icons.event_repeat_rounded;
    Color accentColor = primaryBlue;

    if (packageId.contains('1_year')) {
      packageName = '1 Year Renewal Alerts';
      packageIcon = Icons.event_repeat_rounded;
      accentColor = const Color(0xFF6366F1);
    } else if (packageId.contains('3_year')) {
      packageName = '3 Years Renewal Alerts';
      packageIcon = Icons.notifications_active_rounded;
      accentColor = const Color(0xFF0EA5E9);
    } else if (packageId.contains('5_year')) {
      packageName = '5 Years Renewal Alerts';
      packageIcon = Icons.verified_rounded;
      accentColor = const Color(0xFF8B5CF6);
    }

    final daysLeft = endDate != null ? endDate.difference(DateTime.now()).inDays : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? accentColor.withOpacity(0.3) : borderGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.08), accentColor.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(packageIcon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900, color: textBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Covers all registered vehicles",
                        style: TextStyle(color: subTextGrey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? earnGreen.withOpacity(0.12) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isActive ? earnGreen : Colors.red.shade600,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? "Active" : "Expired",
                        style: TextStyle(
                          color: isActive ? earnGreen : Colors.red.shade600,
                          fontWeight: FontWeight.bold, fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _infoRow(Icons.calendar_today_rounded, "Purchased On",
                    startDate != null ? _formatDate(startDate) : "N/A"),
                const SizedBox(height: 14),
                _infoRow(Icons.event_available_rounded, "Expires On",
                    endDate != null ? _formatDate(endDate) : "N/A"),
                const SizedBox(height: 14),
                _infoRow(
                  Icons.timelapse_rounded,
                  "Days Remaining",
                  isActive ? "$daysLeft days" : "Expired",
                  valueColor: isActive
                      ? (daysLeft < 30 ? Colors.orange.shade700 : earnGreen)
                      : Colors.red.shade600,
                ),

                if (isActive && daysLeft < 30) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Expiring soon! Consider extending your plan.",
                            style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vehicle Document Card ────────────────────────────────
  Widget _buildVehicleDocCard(dynamic vehicle) {
    final regNumber = vehicle['registration_number']?.toString() ?? vehicle['vehicle_number']?.toString() ?? 'N/A';
    final brandName = vehicle['brand_name']?.toString() ?? '';
    final modelName = vehicle['model_name']?.toString() ?? '';
    final vehicleType = vehicle['vehicle_type']?.toString() ?? 'Car';
    final insuranceExpiry = vehicle['insurance_expiry_date']?.toString();
    final pollutionExpiry = vehicle['pollution_expiry_date']?.toString();

    final vehicleLabel = [brandName, modelName].where((s) => s.isNotEmpty).join(' ');

    final insuranceDate = _parseFlexDate(insuranceExpiry);
    final pollutionDate = _parseFlexDate(pollutionExpiry);

    final insuranceExpired = insuranceDate != null && insuranceDate.isBefore(DateTime.now());
    final pollutionExpired = pollutionDate != null && pollutionDate.isBefore(DateTime.now());

    final insuranceDaysLeft = insuranceDate != null ? insuranceDate.difference(DateTime.now()).inDays : null;
    final pollutionDaysLeft = pollutionDate != null ? pollutionDate.difference(DateTime.now()).inDays : null;

    IconData typeIcon = Icons.directions_car_rounded;
    if (vehicleType.toLowerCase().contains('bike') || vehicleType.toLowerCase().contains('two')) {
      typeIcon = Icons.two_wheeler_rounded;
    } else if (vehicleType.toLowerCase().contains('truck') || vehicleType.toLowerCase().contains('commercial')) {
      typeIcon = Icons.local_shipping_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGrey, width: 1.2),
      ),
      child: Column(
        children: [
          // Vehicle Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: backgroundLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        regNumber,
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900, color: textBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (vehicleLabel.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          vehicleLabel,
                          style: const TextStyle(color: subTextGrey, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Insurance Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: _documentRow(
              icon: Icons.shield_rounded,
              label: "Insurance",
              expiryDate: insuranceExpiry,
              isExpired: insuranceExpired,
              daysLeft: insuranceDaysLeft,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(color: borderGrey, height: 24),
          ),

          // PUC Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _documentRow(
              icon: Icons.eco_rounded,
              label: "PUC / Pollution",
              expiryDate: pollutionExpiry,
              isExpired: pollutionExpired,
              daysLeft: pollutionDaysLeft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentRow({
    required IconData icon,
    required String label,
    String? expiryDate,
    required bool isExpired,
    int? daysLeft,
  }) {
    final hasDate = expiryDate != null && expiryDate.isNotEmpty;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!hasDate) {
      statusColor = subTextGrey;
      statusText = "Not set";
      statusIcon = Icons.help_outline_rounded;
    } else if (isExpired) {
      statusColor = Colors.red.shade600;
      statusText = "Expired";
      statusIcon = Icons.cancel_rounded;
    } else if (daysLeft != null && daysLeft < 30) {
      statusColor = Colors.orange.shade700;
      statusText = "$daysLeft days left";
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = earnGreen;
      statusText = "Valid";
      statusIcon = Icons.check_circle_rounded;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textBlack),
              ),
              const SizedBox(height: 2),
              Text(
                hasDate ? "Expires: $expiryDate" : "Expiry date not added",
                style: TextStyle(color: subTextGrey, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Empty States ─────────────────────────────────────────
  Widget _buildNoSubscriptions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded, size: 48, color: primaryBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Active Subscriptions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textBlack),
            ),
            const SizedBox(height: 8),
            const Text(
              "Purchase a renewal alert package from the\nWallet to get notified about your vehicle\ndocument expiries.",
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoVehicles() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined, size: 40, color: subTextGrey.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            "No vehicles registered yet",
            style: TextStyle(color: subTextGrey, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            "Add a vehicle to see its document details here.",
            style: TextStyle(color: subTextGrey, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: subTextGrey, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: subTextGrey, fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? textBlack,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  DateTime? _parseFlexDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    // Try ISO format first
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso;
    // Try dd/mm/yyyy
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }
}
