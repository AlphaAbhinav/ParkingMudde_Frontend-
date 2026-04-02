import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VisitorModel {
  final String name;
  final String mobile;
  final String purpose;
  final String vehicleNo;
  final String dateTime;
  final String status; // Pending / Approved / Exited

  VisitorModel({
    required this.name,
    required this.mobile,
    required this.purpose,
    required this.vehicleNo,
    required this.dateTime,
    required this.status,
  });
}

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  // Preloaded variables preserved completely
  final List<VisitorModel> visitors = [
    VisitorModel(
      name: "Rahul Sharma",
      mobile: "XXXXXX1234",
      purpose: "Delivery",
      vehicleNo: "DL 01 AB 1234",
      dateTime: "12 Jan, 10:30 AM",
      status: "Pending",
    ),
    VisitorModel(
      name: "Amit Verma",
      mobile: "XXXXXX9876",
      purpose: "Guest",
      vehicleNo: "UP 16 CD 5678",
      dateTime: "11 Jan, 6:15 PM",
      status: "Approved",
    ),
    VisitorModel(
      name: "Sneha Kapoor",
      mobile: "XXXXXX5521",
      purpose: "Housekeeping",
      vehicleNo: "MH 04 AB 9811",
      dateTime: "11 Jan, 08:00 AM",
      status: "Exited",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Premium off-white super-app base
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false, // More standard modern design
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
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
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),

      /// Fully Styled extended floating action trigger
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddVisitorSheet(context),
        backgroundColor: const Color(0XFF184B8C),
        elevation: 4,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          "Pre-Approve Entry",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: visitors.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 24,
                left: 16,
                right: 16,
                bottom: 80,
              ),
              itemCount: visitors.length,
              itemBuilder: (context, index) {
                return _visitorCard(context, visitors[index]);
              },
            ),
    );
  }

  /// Extensively rebuilt Pass/Visitor Display Card
  Widget _visitorCard(BuildContext context, VisitorModel visitor) {
    Color statusColor = visitor.status == "Approved"
        ? Colors.green.shade600
        : visitor.status == "Exited"
        ? Colors.blueGrey.shade400
        : Colors.amber.shade700;

    Color statusBgColor = visitor.status == "Approved"
        ? Colors.green.shade50
        : visitor.status == "Exited"
        ? Colors.blueGrey.shade50
        : Colors.amber.shade50;

    IconData statusIcon = visitor.status == "Approved"
        ? Icons.how_to_reg_rounded
        : visitor.status == "Exited"
        ? Icons.output_rounded
        : Icons.pending_actions_rounded;

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
          /// Core Pass Data
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Subtle elegant profile ring
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0XFF184B8C).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_circle,
                              color: Color(0XFF184B8C),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visitor.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_iphone_rounded,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      visitor.mobile,
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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

                    /// Dynamic Security Tag!
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            visitor.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoPair(
                            Icons.assignment_ind_outlined,
                            visitor.purpose,
                          ),
                          const SizedBox(height: 8),
                          _infoPair(
                            Icons.access_time_rounded,
                            visitor.dateTime,
                          ),
                        ],
                      ),
                    ),
                    // Only generate car plate representation if exists safely
                    if (visitor.vehicleNo.trim().isNotEmpty)
                      _miniLicensePlateView(visitor.vehicleNo)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                      ),
                  ],
                ),
              ],
            ),
          ),

          /// Unified Security Control Action Deck (Only presented if actionable logic state requires!)
          if (visitor.status == "Pending")
            Container(
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
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.do_not_disturb_alt_rounded,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Deny Entry",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Grant Access",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  /// Visually graceful empty zero-list backup!
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.gpp_good_outlined,
                size: 50,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Secure Campus Log",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "All upcoming visitors and delivery gate entries directed to you will permanently log exactly here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPair(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey.shade400),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }

  /// Highly Accurate Authentic Representation Indian vehicle plate replication
  Widget _miniLicensePlateView(String regNumber) {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "IND",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            regNumber.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Masterfully reconstructed Entry popup generator
  void showAddVisitorSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors
          .transparent, // Fixes muddy layout from your legacy color block wrapper
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Pull-notch layout styling!
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Title Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0XFF184B8C).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0XFF184B8C),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Authorize Guest Pass",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Super-cleaned unified input forms abstracted out neatly preventing bloated repeating code!
            _buildStyledFormField(
              label: "Guest First/Last Name",
              hint: "Rahul Sharma",
              icon: Icons.badge_outlined,
              isCapital: true,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStyledFormField(
                    label: "Contact #",
                    hint: "XXXXX 54321",
                    icon: Icons.dialpad_rounded,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStyledFormField(
                    label: "Reason",
                    hint: "Family Visit",
                    icon: Icons.label_important_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildStyledFormField(
              label: "Vehicle Registration Num",
              hint: "MH 14 XX 1234",
              icon: Icons.commute_rounded,
              isCapital: true,
            ),

            const SizedBox(height: 32),

            /// Big secure confirmation entry
            InkWell(
              onTap: () {
                Get.back(); // Emulating confirmation!
                Get.snackbar(
                  "Gateway Generated!",
                  "Approval pass propagated securely into campus database array successfully.",
                  backgroundColor: Colors.green.shade800,
                  colorText: Colors.white,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0XFF184B8C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0XFF184B8C).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Transmit Entry Security Pass",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern TextForm Extractor saving lines and visually guaranteeing pixel matching rules across inputs
  Widget _buildStyledFormField({
    required String label,
    required String hint,
    required IconData icon,
    bool isNum = false,
    bool isCapital = false,
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
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          textCapitalization: isCapital
              ? TextCapitalization.words
              : TextCapitalization.sentences,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.normal,
            ),
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
              borderSide: const BorderSide(
                color: Color(0XFF184B8C),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
