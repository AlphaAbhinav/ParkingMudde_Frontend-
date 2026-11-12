import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// An illustrative loop, not a measurement of upload or AI progress.
class EvidenceReviewLoader extends StatefulWidget {
  const EvidenceReviewLoader({
    super.key,
    required this.photos,
    this.isVideo = false,
    this.isHelp = false,
  });

  final List<Uint8List> photos;
  final bool isVideo;
  final bool isHelp;

  @override
  State<EvidenceReviewLoader> createState() => _EvidenceReviewLoaderState();
}

class _EvidenceReviewLoaderState extends State<EvidenceReviewLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6800),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0.36;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Submitting evidence. Waiting for the report review result.',
      child: ExcludeSemantics(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3081A2E), Color(0xE6081A2E)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 410),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 48,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      final phase = _reduceMotion
                          ? 'Review in progress'
                          : t < .37
                          ? 'Packing your evidence'
                          : t < .78
                          ? 'On the road to review'
                          : 'Awaiting the result';
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1FF),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Color(0xFF2A5EE8),
                                      size: 14,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'EVIDENCE REVIEW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1,
                                        color: Color(0xFF184B8C),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                widget.isVideo
                                    ? Icons.videocam_outlined
                                    : Icons.photo_library_outlined,
                                size: 15,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.isVideo
                                    ? '1 clip'
                                    : '${widget.photos.length} ${widget.photos.length == 1 ? 'photo' : 'photos'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 360 / 230,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final scale = constraints.maxWidth / 360;
                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _ReviewScenePainter(t),
                                        ),
                                      ),
                                      for (
                                        var i = 0;
                                        i <
                                            (widget.isVideo
                                                ? 1
                                                : widget.photos.length.clamp(
                                                    0,
                                                    4,
                                                  ));
                                        i++
                                      )
                                        _flyingPhoto(i, t, scale),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            widget.isHelp
                                ? 'A little help is on its way'
                                : 'Your evidence is on its way',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102B4A),
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'We’re submitting your evidence for review.\nPlease keep this screen open.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: Color(0xFF2A5EE8),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    phase,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF184B8C),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(
                                  3,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(left: 3),
                                    child: Opacity(
                                      opacity: _reduceMotion
                                          ? .6
                                          : .25 +
                                                .75 *
                                                    ((math.sin(
                                                              t * math.pi * 6 -
                                                                  index * .9,
                                                            ) +
                                                            1) /
                                                        2),
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2A5EE8),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _flyingPhoto(int index, double t, double scale) {
    final local = ((t - .045 - index * .058) / .16).clamp(0.0, 1.0);
    final progress = Curves.easeInOutCubic.transform(local);
    final start = Offset(21 + index * 22.0, 75 - (index % 2) * 16.0);
    const end = Offset(73, 163);
    final position =
        Offset.lerp(start, end, progress)! -
        Offset(0, math.sin(progress * math.pi) * 22);
    final size = (44 - 29 * progress) * scale;
    final opacity = t > .37 ? 0.0 : (1 - ((local - .75) / .25).clamp(0.0, 1.0));
    return Positioned(
      left: position.dx * scale,
      top: position.dy * scale,
      width: size,
      height: size * 1.18,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: (index.isEven ? -.14 : .12) * (1 - progress),
          child: Container(
            padding: EdgeInsets.all(3 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5 * scale),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220B2545),
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2 * scale),
                    child: widget.isVideo
                        ? const ColoredBox(
                            color: Color(0xFFDBEAFE),
                            child: Center(
                              child: Icon(
                                Icons.movie_rounded,
                                size: 20,
                                color: Color(0xFF184B8C),
                              ),
                            ),
                          )
                        : Image.memory(
                            widget.photos[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            cacheWidth: 120,
                            errorBuilder: (_, error, stack) => const Icon(
                              Icons.image_outlined,
                              color: Color(0xFF2A5EE8),
                              size: 20,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Container(
                  height: 2 * scale,
                  width: 18 * scale,
                  color: const Color(0xFFDCE5F0),
                ),
                SizedBox(height: 2 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewScenePainter extends CustomPainter {
  _ReviewScenePainter(this.t);
  final double t;
  static const navy = Color(0xFF16395D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 230);
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
      ).createShader(const Rect.fromLTWH(0, 0, 360, 230));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 360, 230), sky);
    canvas.drawCircle(
      const Offset(185, 52),
      27,
      Paint()..color = const Color(0xFFFFE9B0),
    );
    _cloud(canvas, 30, 36, 1);
    _cloud(canvas, 140 - t * 7, 87, .65);
    _cloud(canvas, 291, 29, .8);
    for (var i = 0; i < 7; i++) {
      final x = i * 49.0 - 5;
      final h = 24.0 + (i % 3) * 14;
      _box(
        canvas,
        Rect.fromLTWH(x, 165 - h, 34, h),
        const Color(0xFFE0EAF7),
        3,
      );
      for (var j = 0; j < 3; j++) {
        _box(
          canvas,
          Rect.fromLTWH(x + 7 + j * 8, 172 - h, 3, 5),
          const Color(0xFFC7D8EC),
          1,
        );
      }
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 175, 360, 55),
      Paint()..color = const Color(0xFFD6E1EF),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 182, 360, 44),
      Paint()..color = const Color(0xFF54708D),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 182, 360, 3),
      Paint()..color = const Color(0xFFF8FBFF),
    );
    for (var i = -1; i < 9; i++) {
      _box(
        canvas,
        Rect.fromLTWH(i * 52 - (t * 130) % 52, 209, 27, 3),
        const Color(0xFFADC2D7),
        1.5,
      );
    }
    _station(canvas);
    _tree(canvas, 228, 158, .8);
    _tree(canvas, 16, 162, .65);

    final drive = Curves.easeInOutCubic.transform(
      ((t - .38) / .38).clamp(0.0, 1.0),
    );
    final enter = Curves.easeInOut.transform(((t - .7) / .15).clamp(0.0, 1.0));
    final x = 43 + drive * 225;
    final y = 165 - enter * 12 + math.sin(t * math.pi * 18) * .55 * (1 - enter);
    final alpha = (1 - enter) * (t / .035).clamp(0.0, 1.0);
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 360, 230),
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(1 - enter * .28);
    _car(canvas, drive);
    canvas.restore();
    canvas.restore();

    // The bay doors close after the car arrives, then reopen for the loop.
    final door =
        Curves.easeInOut.transform(((t - .82) / .09).clamp(0.0, 1.0)) *
        (1 - Curves.easeInOut.transform(((t - .94) / .06).clamp(0.0, 1.0)));
    _box(
      canvas,
      Rect.fromLTWH(279, 137, 45 * door, 43),
      const Color(0xFF315678),
      1,
    );
    if (door > .1) {
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(281, 145 + i * 9.0),
          Offset(277 + 45 * door, 145 + i * 9.0),
          Paint()
            ..color = const Color(0xFF577997)
            ..strokeWidth = 1,
        );
      }
    }
    if (t > .85 && t < .96) {
      final fade = math.sin(((t - .85) / .11) * math.pi);
      canvas.drawCircle(
        const Offset(302, 155),
        11,
        Paint()..color = const Color(0xFFDBEAFE).withValues(alpha: fade),
      );
      canvas.drawCircle(
        const Offset(300, 153),
        4,
        Paint()
          ..color = const Color(0xFF2A5EE8).withValues(alpha: fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        const Offset(303, 156),
        const Offset(307, 160),
        Paint()
          ..color = const Color(0xFF2A5EE8).withValues(alpha: fade)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  void _station(Canvas c) {
    c.drawOval(
      const Rect.fromLTWH(248, 172, 99, 13),
      Paint()..color = const Color(0x1A16395D),
    );
    _box(c, const Rect.fromLTWH(250, 86, 95, 94), const Color(0xFFB7CDE5), 5);
    _box(c, const Rect.fromLTWH(257, 91, 81, 89), const Color(0xFFF9FCFF), 3);
    _box(c, const Rect.fromLTWH(245, 80, 105, 12), navy, 3);
    _box(c, const Rect.fromLTWH(260, 95, 75, 28), navy, 4);
    _label(
      c,
      'POLICE',
      const Offset(275, 101),
      13,
      Colors.white,
      FontWeight.w900,
    );
    _label(
      c,
      'REVIEW STATION',
      const Offset(268, 125),
      6.2,
      const Color(0xFF54708D),
      FontWeight.w800,
    );
    _box(c, const Rect.fromLTWH(277, 135, 49, 45), const Color(0xFFB7CDE5), 4);
    _box(c, const Rect.fromLTWH(280, 138, 43, 42), const Color(0xFF203C59), 2);
    _box(c, const Rect.fromLTWH(261, 140, 10, 16), const Color(0xFF9DCBF0), 2);
    c.drawLine(
      const Offset(266, 140),
      const Offset(266, 156),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5,
    );
    _box(c, const Rect.fromLTWH(247, 178, 101, 5), const Color(0xFF8CA8C6), 1);
    c.drawLine(
      const Offset(338, 80),
      const Offset(338, 51),
      Paint()
        ..color = navy
        ..strokeWidth = 2,
    );
    final flag = Path()
      ..moveTo(338, 52)
      ..lineTo(355, 56)
      ..lineTo(338, 64)
      ..close();
    c.drawPath(flag, Paint()..color = const Color(0xFF2A5EE8));
    final glow = (math.sin(t * math.pi * 12) + 1) / 2;
    c.drawCircle(
      const Offset(257, 78),
      8,
      Paint()
        ..color = const Color(0xFFE65D67).withValues(alpha: .12 + glow * .15),
    );
    _box(c, const Rect.fromLTWH(253, 74, 8, 6), const Color(0xFFE65D67), 2);
  }

  void _car(Canvas c, double drive) {
    c.drawOval(
      const Rect.fromLTWH(-5, 29, 97, 10),
      Paint()..color = const Color(0x33112D49),
    );
    // Deep-blue patrol car with a white door panel and shield.
    final body = Path()
      ..moveTo(1, 14)
      ..lineTo(13, 11)
      ..lineTo(23, 0)
      ..quadraticBezierTo(28, -4, 36, -4)
      ..lineTo(59, -4)
      ..quadraticBezierTo(65, -3, 71, 9)
      ..lineTo(85, 13)
      ..quadraticBezierTo(92, 15, 92, 22)
      ..lineTo(91, 29)
      ..lineTo(0, 29)
      ..close();
    c.drawPath(body, Paint()..color = navy);
    _box(c, const Rect.fromLTWH(29, 0, 18, 12), const Color(0xFFA9DBFA), 2);
    final windshield = Path()
      ..moveTo(51, 0)
      ..lineTo(60, 0)
      ..lineTo(68, 12)
      ..lineTo(51, 12)
      ..close();
    c.drawPath(windshield, Paint()..color = const Color(0xFFA9DBFA));
    _box(c, const Rect.fromLTWH(27, 15, 43, 13), const Color(0xFFF9FCFF), 2);
    final shield = Path()
      ..moveTo(45, 17)
      ..lineTo(51, 17)
      ..lineTo(51, 22)
      ..lineTo(48, 25)
      ..lineTo(45, 22)
      ..close();
    c.drawPath(shield, Paint()..color = const Color(0xFFF2BD4F));
    _box(c, const Rect.fromLTWH(85, 16, 7, 5), const Color(0xFFFFD470), 2);
    _box(c, const Rect.fromLTWH(0, 16, 5, 4), const Color(0xFFEC6974), 1);
    _box(c, const Rect.fromLTWH(39, -9, 20, 5), const Color(0xFFEDF5FF), 2);
    final flash = (math.sin(t * math.pi * 24) + 1) / 2;
    c.drawOval(
      const Rect.fromLTWH(30, -18, 23, 17),
      Paint()..color = const Color(0xFFE65D67).withValues(alpha: flash * .22),
    );
    c.drawOval(
      const Rect.fromLTWH(50, -18, 23, 17),
      Paint()
        ..color = const Color(0xFF2A5EE8).withValues(alpha: (1 - flash) * .22),
    );
    _box(c, const Rect.fromLTWH(39, -9, 10, 5), const Color(0xFFE65D67), 1);
    _box(c, const Rect.fromLTWH(49, -9, 10, 5), const Color(0xFF2A5EE8), 1);
    for (final x in [20.0, 73.0]) {
      c.drawCircle(Offset(x, 29), 10, Paint()..color = const Color(0xFF102840));
      c.drawCircle(
        Offset(x, 29),
        5.5,
        Paint()..color = const Color(0xFFACC2D9),
      );
      c.save();
      c.translate(x, 29);
      c.rotate(drive * math.pi * 10);
      c.drawLine(
        const Offset(-4, 0),
        const Offset(4, 0),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
      c.drawLine(
        const Offset(0, -4),
        const Offset(0, 4),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
      c.restore();
    }
  }

  void _tree(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    _box(c, const Rect.fromLTWH(-2, -6, 4, 29), const Color(0xFF83A3B6), 2);
    c.drawCircle(
      const Offset(0, -10),
      16,
      Paint()..color = const Color(0xFFB1DACB),
    );
    c.drawCircle(
      const Offset(-7, -4),
      11,
      Paint()..color = const Color(0xFF8CCAB7),
    );
    c.restore();
  }

  void _cloud(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    final paint = Paint()..color = Colors.white.withValues(alpha: .9);
    c.drawCircle(const Offset(10, 2), 10, paint);
    c.drawCircle(const Offset(23, -3), 14, paint);
    c.drawCircle(const Offset(37, 3), 10, paint);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 1, 39, 11),
        const Radius.circular(5),
      ),
      paint,
    );
    c.restore();
  }

  void _box(Canvas c, Rect rect, Color color, double radius) => c.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    Paint()..color = color,
  );

  void _label(
    Canvas c,
    String text,
    Offset at,
    double size,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontFamily: 'Roboto',
          color: color,
          fontWeight: weight,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(c, at);
  }

  @override
  bool shouldRepaint(covariant _ReviewScenePainter oldDelegate) =>
      oldDelegate.t != t;
}
