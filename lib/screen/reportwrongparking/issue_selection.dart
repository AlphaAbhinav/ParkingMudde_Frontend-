import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';

class IssueSelectionScreen extends StatefulWidget {
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  const IssueSelectionScreen({
    super.key,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  @override
  State<IssueSelectionScreen> createState() => _IssueSelectionScreenState();
}

class _IssueSelectionScreenState extends State<IssueSelectionScreen> {
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF1E212D);
  static const Color textDarkGrey = Color(0xFF4B5563);

  static const List<Map<String, String>> _reportIssues = [
    // Strong AI Detection
    {
      "code": "NO_PARKING_ZONE",
      "title": "Parked in No Parking zone",
      "group": "Supported",
    },
    {"code": "FOOTPATH", "title": "Parked on footpath", "group": "Supported"},
    {
      "code": "PEDESTRIAN_CROSSING",
      "title": "Parked on zebra crossing",
      "group": "Supported",
    },
    {
      "code": "BLOCKING_CAR_EXIT",
      "title": "Blocking my car / double parked",
      "group": "Supported",
    },
    {
      "code": "WRONG_SIDE",
      "title": "Parked on wrong side",
      "group": "Supported",
    },
    {
      "code": "BLOCKING_GATE",
      "title": "Blocking society entry/exit gate",
      "group": "Supported",
    },
    {
      "code": "BLOCKING_DRIVEWAY",
      "title": "Blocking driveway / ramp",
      "group": "Supported",
    },
    {
      "code": "TRAFFIC_JAM",
      "title": "Parking causing traffic jam",
      "group": "Supported",
    },
    // Weak AI Detection
    {
      "code": "BLOCKING_FIRE_EXIT",
      "title": "Blocking fire exit",
      "group": "Weak",
    },
    {
      "code": "BLOCKING_AMBULANCE",
      "title": "Blocking ambulance access",
      "group": "Weak",
    },
    {
      "code": "BLOCKING_SHOP",
      "title": "Blocking shop entrance / shutter",
      "group": "Weak",
    },
    {
      "code": "BLOCKING_HOME",
      "title": "Parking in front of my house",
      "group": "Weak",
    },
    // Coming Soon
    {
      "code": "RESERVED_SPOT",
      "title": "Parked in my reserved spot",
      "group": "Coming Soon",
    },
    {
      "code": "HANDICAPPED_SLOT",
      "title": "Parked in handicapped slot",
      "group": "Coming Soon",
    },
    {
      "code": "EV_CHARGING_SPOT",
      "title": "Parked in EV charging spot",
      "group": "Coming Soon",
    },
  ];

  void _handleIssueTap(Map<String, String> issue) {
    if (issue['group'] == 'Coming Soon') {
      Get.snackbar(
        "Coming Soon",
        "AI detection for this issue is not yet supported. Please choose another issue.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(
      () => ReportProofScreen(
        typev: "report",
        selectedIssueTitle: issue['title'],
        selectedIssueCode: issue['code'],
        razorpayOrderId: widget.razorpayOrderId,
        razorpayPaymentId: widget.razorpayPaymentId,
        razorpaySignature: widget.razorpaySignature,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate issues into groups
    final supportedIssues = _reportIssues
        .where((e) => e['group'] == 'Supported')
        .toList();
    final weakIssues = _reportIssues
        .where((e) => e['group'] == 'Weak')
        .toList();
    final comingSoonIssues = _reportIssues
        .where((e) => e['group'] == 'Coming Soon')
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: textBlack,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "Select Issue",
            style: TextStyle(
              color: textBlack,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "What did the driver do wrong?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your report will be automatically evaluated by AI.",
              style: TextStyle(fontSize: 14, color: textDarkGrey),
            ),
            const SizedBox(height: 24),

            // Top section: Supported + Weak
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...supportedIssues.map((issue) => _buildIssueTile(issue)),
                  Divider(height: 1, color: Colors.grey.shade200),
                  ...weakIssues.map(
                    (issue) => _buildIssueTile(issue, isWeak: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Coming soon section
            const Text(
              "Coming soon",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDarkGrey,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: comingSoonIssues
                    .map((issue) => _buildIssueTile(issue, isComingSoon: true))
                    .toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTile(
    Map<String, String> issue, {
    bool isWeak = false,
    bool isComingSoon = false,
  }) {
    return InkWell(
      onTap: () => _handleIssueTap(issue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                issue['title']!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isComingSoon ? Colors.grey.shade400 : textBlack,
                ),
              ),
            ),
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Coming Soon",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
