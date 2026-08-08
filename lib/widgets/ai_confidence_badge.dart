import 'package:flutter/material.dart';

class AiConfidenceBadge extends StatelessWidget {
  final String level;
  final bool compact;
  final bool showLabel;

  const AiConfidenceBadge({
    super.key,
    required this.level,
    this.compact = false,
    this.showLabel = true,
  });

  factory AiConfidenceBadge.fromGroup(
    String? group, {
    bool compact = false,
    bool showLabel = true,
  }) {
    return AiConfidenceBadge(
      level: confidenceLevelFromGroup(group),
      compact: compact,
      showLabel: showLabel,
    );
  }

  static String confidenceLevelFromGroup(String? group) {
    final normalized = group?.toLowerCase() ?? '';
    if (normalized.contains('coming soon')) return 'Experimental';
    if (normalized.contains('weak') ||
        normalized.contains('hard to verify') ||
        normalized.contains('manual review')) {
      return 'Medium';
    }
    if (normalized.contains('supported') ||
        normalized.contains('parking mistakes')) {
      return 'High';
    }
    return 'Medium';
  }

  static String confidenceLevelForFlow({
    String? flow,
    String? group,
    int? aiScore,
  }) {
    if (group != null && group.isNotEmpty) {
      return confidenceLevelFromGroup(group);
    }
    if (flow == 'help' || flow == 'emergency') return 'Medium';
    if (aiScore != null) {
      if (aiScore >= 70) return 'High';
      if (aiScore >= 45) return 'Medium';
      return 'Experimental';
    }
    return 'Medium';
  }

  Color get _baseColor {
    switch (level) {
      case 'High':
        return const Color(0xFF0F9F6E);
      case 'Experimental':
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFF2A5EE8);
    }
  }

  IconData get _icon {
    switch (level) {
      case 'High':
        return Icons.verified_rounded;
      case 'Experimental':
        return Icons.auto_awesome_motion_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  String get _subtitle {
    switch (level) {
      case 'High':
        return 'Strong detection support';
      case 'Experimental':
        return 'New detection support';
      default:
        return 'Assisted review support';
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _baseColor;
    final label = showLabel ? 'AI Confidence: $level' : level;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baseColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 13, color: baseColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: baseColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: baseColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
