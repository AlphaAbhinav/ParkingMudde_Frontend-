import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
