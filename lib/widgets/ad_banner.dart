import 'package:flutter/material.dart';

/// Reusable sponsored ad banner.
/// In the future, swap [brandName], [tagline], [onTap], and [logoIcon]
/// with real brand data from your backend/CMS.
class AdBanner extends StatelessWidget {
  final String brandName;
  final String tagline;
  final String ctaLabel;
  final IconData logoIcon;
  final Color accentColor;
  final VoidCallback? onTap;

  const AdBanner({
    super.key,
    this.brandName = "Your Brand Here",
    this.tagline = "Partner with ParkingMudde and reach thousands of vehicle owners.",
    this.ctaLabel = "Learn More →",
    this.logoIcon = Icons.business_rounded,
    this.accentColor = const Color(0xFF184B8C),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Color.lerp(accentColor, Colors.black, 0.35)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [accentColor, dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -28,
              top: -28,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: -36,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SPONSORED badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.4),
                            ),
                          ),
                          child: const Text(
                            "SPONSORED",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          brandName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tagline,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              ctaLabel,
                              style: TextStyle(
                                color: dark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Brand logo placeholder
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Icon(
                      logoIcon,
                      color: Colors.white.withOpacity(0.35),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
