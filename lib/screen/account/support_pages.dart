import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/widgets/ad_banner.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoShell(
      title: "Help & Support",
      children: [
        const _InfoTile(title: "Phone", body: "+91 98765 43210"),
        const _InfoTile(title: "Email", body: "support@parkingmudde.com"),
        const _InfoTile(title: "Hours", body: "Monday to Saturday, 9 AM to 7 PM"),
        const _InfoTile(
          title: "Address",
          body: "Parking Mudde Support Desk, New Delhi, India",
        ),
        const SizedBox(height: 16),
        const Text(
          "Quick Support",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _SupportActionTile(
          icon: Icons.chat_bubble_outline,
          title: "In-App Chat",
          onTap: () {
            Get.snackbar("Coming Soon", "In-App Chat support is coming soon!");
          },
        ),
        _SupportActionTile(
          icon: Icons.quickreply_outlined,
          title: "WhatsApp Support",
          onTap: () {
            Get.snackbar("Coming Soon", "WhatsApp support is coming soon!");
          },
        ),
      ],
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SupportActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2A5EE8), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "How do I report wrong parking?",
        "answer":
            "Open Report Wrong Parking, scan or enter the vehicle number, and submit proof.",
      },
      {
        "question": "When do I earn coins?",
        "answer":
            "Coins are added after the backend confirms a report or completed help activity.",
      },
      {
        "question": "Can I manage multiple vehicles?",
        "answer": "Yes. Add and manage them from My Vehicles.",
      },
      {
        "question": "Where do booking updates appear?",
        "answer":
            "Parking booking status updates appear in Activities and My Bookings.",
      },
    ];

    return _InfoShell(
      title: "FAQs",
      children: [
        ...faqs
            .map(
              (faq) => _InfoTile(
                title: faq["question"]!,
                body: faq["answer"]!,
              ),
            )
            .toList(),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _openSupportForm(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5EE8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A5EE8).withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent_rounded, color: Color(0xFF2A5EE8)),
                SizedBox(width: 8),
                Text(
                  "Can't find your answer? Connect with us",
                  style: TextStyle(
                    color: Color(0xFF2A5EE8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const AdBanner(
          accentColor: Color(0xFF0F6B3D),
          brandName: "Your Brand Here",
          tagline: "Advertise to an engaged community of vehicle owners & drivers.",
          logoIcon: Icons.local_offer_rounded,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _openSupportForm(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    final name = prefs.getString("name") ?? "User";
    final mobile = prefs.getString("mobile_number") ?? "";

    if (userId == null) {
      Get.snackbar("Login Required", "Please login to submit a support request.");
      return;
    }

    final TextEditingController questionController = TextEditingController();
    bool isSubmitting = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Connect with us",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text("We'll contact you at $mobile"),
                const SizedBox(height: 16),
                TextField(
                  controller: questionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Type your question here...",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A5EE8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (questionController.text.trim().isEmpty) return;
                            setState(() => isSubmitting = true);
                            final success = await ApiService.submitSupportTicket(
                              userId,
                              name,
                              mobile,
                              questionController.text.trim(),
                            );
                            setState(() => isSubmitting = false);
                            if (success) {
                              Get.back();
                              Get.snackbar(
                                "Success",
                                "Your question was submitted. We will contact you soon!",
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } else {
                              Get.snackbar("Error", "Failed to submit request.");
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Submit Request",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoShell(
      title: "Privacy Policy",
      children: [
        _InfoTile(
          title: "Data We Collect",
          body:
              "We collect account details, vehicle details, booking records, report evidence, wallet activity, and support interactions required to operate Parking Mudde.",
        ),
        _InfoTile(
          title: "How We Use Data",
          body:
              "We use this information to verify users, process vehicle reports, manage bookings, maintain rewards, prevent misuse, and improve app reliability.",
        ),
        _InfoTile(
          title: "Data Safety",
          body:
              "We apply reasonable safeguards and limit access to operational needs. Do not upload documents that are not related to your vehicle or account.",
        ),
      ],
    );
  }
}

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoShell(
      title: "Terms & Conditions",
      children: [
        _InfoTile(
          title: "Responsible Use",
          body:
              "Use Parking Mudde only for genuine parking, vehicle assistance, booking, and community safety purposes.",
        ),
        _InfoTile(
          title: "Reports & Rewards",
          body:
              "Report and help rewards are issued only after backend validation. False or abusive reports may lead to coin deductions or account restrictions.",
        ),
        _InfoTile(
          title: "Bookings",
          body:
              "Parking requests can be sent, pending, approved, or rejected depending on availability and operator response.",
        ),
      ],
    );
  }
}

class _InfoShell extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2A5EE8)),
          onPressed: Get.back,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String body;

  const _InfoTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
