import 'package:flutter/material.dart';

class FullScreenAlertPage extends StatelessWidget {
  const FullScreenAlertPage({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString().toUpperCase();
    final isEmergency = type.contains('EMERGENCY');
    final color = isEmergency ? const Color(0xFFE53935) : const Color(0xFF20C77A);
    final title = (data['title'] ?? (isEmergency ? 'Emergency Alert!' : 'Someone is Helping!')).toString();
    final vehicle = (data['vehicle_number'] ?? data['vehicleNumber'] ?? '').toString();
    final message = (data['body'] ?? data['message'] ?? 'Please check this alert immediately.').toString();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: color,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(isEmergency ? Icons.warning_rounded : Icons.favorite_rounded, color: color, size: 54),
                ),
                const SizedBox(height: 40),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
                if (vehicle.isNotEmpty) ...[
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(9)),
                    child: Text(vehicle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ),
                ],
                const SizedBox(height: 28),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.45)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Acknowledge Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
