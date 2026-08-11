import 'package:flutter/material.dart';

class ScreenSlogan extends StatelessWidget {
  final String text;
  final Color color;
  final EdgeInsetsGeometry padding;
  final IconData? icon;
  final TextAlign textAlign;
  final String imagePath;
  final double? normalImageWidth;
  final double? compactImageWidth;
  final double imageHeightRatio;
  final int textMaxLines;
  final double? minHeight;
  final double? normalFontSize;
  final double? compactFontSize;

  const ScreenSlogan(
    this.text, {
    super.key,
    this.color = const Color(0xFF64748B),
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.icon,
    this.textAlign = TextAlign.left,
    this.imagePath = 'assets/loginslogan.png',
    this.normalImageWidth,
    this.compactImageWidth,
    this.imageHeightRatio = 0.92,
    this.textMaxLines = 3,
    this.minHeight,
    this.normalFontSize,
    this.compactFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        // Tune these two defaults to manually find the perfect slogan image size.
        final targetNormalImageWidth = normalImageWidth ?? 230.0;
        final targetCompactImageWidth = compactImageWidth ?? 190.0;

        final imageWidth = compact
            ? targetCompactImageWidth.clamp(0.0, constraints.maxWidth * 0.62)
            : targetNormalImageWidth.clamp(0.0, constraints.maxWidth * 0.64);
        final imageHeight = imageWidth * imageHeightRatio;
        final imageRightInset = constraints.maxWidth >= 360
            ? 8.0
            : constraints.maxWidth >= 340
            ? 6.0
            : 0.0;
        final sloganText = Text(
          text,
          textAlign: textAlign,
          maxLines: textMaxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize:
                compact ? (compactFontSize ?? 19.5) : (normalFontSize ?? 21),
            fontWeight: FontWeight.w500,
            height: 1.35,
            letterSpacing: 0,
          ),
        );

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight ?? (compact ? 210 : 240),
          ),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: sloganText),
                SizedBox(width: compact ? 10 : 14),
                Padding(
                  padding: EdgeInsets.only(right: imageRightInset),
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            icon ?? Icons.self_improvement_rounded,
                            color: color.withOpacity(0.65),
                            size: compact ? 44 : 56,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
