import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';
import 'package:parkingmudde/widgets/ai_confidence_badge.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class IssueSelectionScreen extends StatefulWidget {
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String typev;
  final String? vehicleNumber;
  final Map<String, dynamic>? vehicleLookupData;

  const IssueSelectionScreen({
    super.key,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.typev = "report",
    this.vehicleNumber,
    this.vehicleLookupData,
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

  static const List<Map<String, String>> _helpIssues = [
    {
      "code": "PARKED_TOO_CLOSE",
      "group": "Supported",
      "title": "Parked too close (blocking)",
    },
    {
      "code": "OUTSIDE_MARKING",
      "group": "Supported",
      "title": "Parked outside marking",
    },
    {"code": "ON_RAMP_TURN", "group": "Weak", "title": "Parked on ramp / turn"},
    {
      "code": "SLOPE_NO_SUPPORT",
      "group": "Weak",
      "title": "Parked on slope without support",
    },
    {
      "code": "SUSPICIOUS",
      "group": "Weak",
      "title": "Suspicious vehicle / security concern",
    },
    {"code": "HEADLIGHTS_ON", "group": "Coming Soon", "title": "Headlights ON"},
    {"code": "INDICATOR_ON", "group": "Coming Soon", "title": "Indicator ON"},
    {"code": "DOOR_OPEN", "group": "Coming Soon", "title": "Door open"},
    {"code": "BOOT_OPEN", "group": "Coming Soon", "title": "Boot open"},
    {"code": "WINDOW_OPEN", "group": "Coming Soon", "title": "Window open"},
    {"code": "ENGINE_ON", "group": "Coming Soon", "title": "Engine ON (idle)"},
    {
      "code": "HANDBRAKE_NOT_ENGAGED",
      "group": "Coming Soon",
      "title": "Handbrake not engaged",
    },
    {
      "code": "HAZARD_LIGHT_ON",
      "group": "Coming Soon",
      "title": "Hazard light ON",
    },
    {
      "code": "ROLLING_RISK",
      "group": "Coming Soon",
      "title": "Car rolling risk",
    },
    {"code": "FLAT_TYRE", "group": "Coming Soon", "title": "Flat tyre"},
    {"code": "LOW_AIR", "group": "Coming Soon", "title": "Low air tyre"},
    {
      "code": "MIRROR_BROKEN",
      "group": "Coming Soon",
      "title": "Side mirror folded / broken",
    },
    {"code": "FUEL_CAP_OPEN", "group": "Coming Soon", "title": "Fuel cap open"},
    {"code": "OIL_LEAK", "group": "Coming Soon", "title": "Oil leak visible"},
    {
      "code": "SMOKE_FROM_ENGINE",
      "group": "Coming Soon",
      "title": "Smoke from engine",
    },
    {
      "code": "VISITOR_SLOT",
      "group": "Coming Soon",
      "title": "Parked in visitor slot",
    },
    {
      "code": "ALARM_RINGING",
      "group": "Coming Soon",
      "title": "Car alarm continuously ringing",
    },
    {
      "code": "FUEL_LEAKAGE",
      "group": "Coming Soon",
      "title": "Fuel leakage suspected",
    },
    {
      "code": "UNATTENDED",
      "group": "Coming Soon",
      "title": "Vehicle left unattended long time",
    },
  ];

  static const List<Map<String, String>> _emergencyIssues = [
    {
      "code": "VEHICLE_OVERTURNED",
      "title": "Vehicle overturned",
      "group": "Supported",
    },
    {"code": "FIRE_SMOKE", "title": "Fire risk / smoke", "group": "Supported"},
    {
      "code": "MINOR_ACCIDENT",
      "title": "Minor accident (vehicle damaged)",
      "group": "Supported",
    },
    {
      "code": "SERIOUS_ACCIDENT",
      "title": "Serious accident (injury suspected)",
      "group": "Supported",
    },

    {
      "code": "PERSON_UNCONSCIOUS",
      "title": "Person unconscious",
      "group": "Weak",
    },
    {
      "code": "MEDICAL_EMERGENCY",
      "title": "Bleeding / medical emergency",
      "group": "Weak",
    },

    {"code": "HIT_AND_RUN", "title": "Hit & run case", "group": "Coming Soon"},
    {
      "code": "NEED_AMBULANCE",
      "title": "Need ambulance immediately",
      "group": "Coming Soon",
    },
  ];

  void _handleIssueTap(Map<String, String> issue) {
    if (issue['group'] == 'Coming Soon') {
      Get.snackbar(
        "Experimental",
        "This AI option is still being trained. Please choose a High or Medium confidence issue for now.",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(
      () => ReportProofScreen(
        typev: widget.typev,
        selectedIssueTitle: issue['title'],
        selectedIssueCode: issue['code'],
        selectedIssueConfidenceGroup: issue['group'],
        razorpayOrderId: widget.razorpayOrderId,
        razorpayPaymentId: widget.razorpayPaymentId,
        razorpaySignature: widget.razorpaySignature,
        vehicleNumber: widget.vehicleNumber,
        vehicleLookupData: widget.vehicleLookupData,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final issuesToUse = widget.typev == 'help'
        ? _helpIssues
        : widget.typev == 'emergency'
        ? _emergencyIssues
        : _reportIssues;

    // Separate issues into groups
    final supportedIssues = issuesToUse
        .where((e) => e['group'] == 'Supported')
        .toList();
    final weakIssues = issuesToUse.where((e) => e['group'] == 'Weak').toList();
    final comingSoonIssues = issuesToUse
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
            Text(
              widget.typev == 'emergency'
                  ? "Emergency alerts use AI-assisted review with human-safe confirmation."
                  : widget.typev == 'help'
                  ? "Helping alerts use AI-assisted review before notifying owners."
                  : "Your report will be automatically evaluated by AI.",
              style: const TextStyle(fontSize: 14, color: textDarkGrey),
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
              "Experimental",
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
            const SizedBox(height: 18),
            const ScreenSlogan(
              "Your car's problems end here.",
              color: primaryBlue,
              icon: Icons.task_alt_rounded,
              imagePath: 'assets/reportslogan.png',
              normalImageWidth: 142,
              compactImageWidth: 122,
              textMaxLines: 2,
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
    final confidenceGroup = isComingSoon
        ? 'Coming Soon'
        : isWeak
        ? 'Weak'
        : issue['group'];

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue['title']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isComingSoon ? Colors.grey.shade500 : textBlack,
                    ),
                  ),
                  const SizedBox(height: 7),
                  AiConfidenceBadge.fromGroup(
                    confidenceGroup,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "New",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber.shade800,
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
