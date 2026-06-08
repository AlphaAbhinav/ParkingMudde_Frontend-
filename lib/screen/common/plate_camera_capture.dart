import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlateCameraCaptureScreen extends StatefulWidget {
  const PlateCameraCaptureScreen({super.key});

  @override
  State<PlateCameraCaptureScreen> createState() =>
      _PlateCameraCaptureScreenState();
}

class _PlateCameraCaptureScreenState extends State<PlateCameraCaptureScreen>
    with SingleTickerProviderStateMixin {
  // Brand color adapted for scanner "Laser" elements
  static const Color accentBlue = Color(0xFF2A5EE8);
  static const Color accentCyan = Color(0xFF00E5FF);

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isFlashOn = false;
  String? _error;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();

    // Laser Animation setup mapping bounds bounds spaces bounds maps form mapping boundary maps forms limit map mapped
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Bounds limits mappings layouts boundary boundaries boundaries limits bounds layout mappings form constraints mappings boundaries mapping map forms mapped mapping limit layout form limit constraint mapping layouts constraints boundaries
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOutSine),
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera([int index = 0]) async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty)
        throw Exception("No camera lenses detected on this device.");

      _cameraIndex = index.clamp(0, _cameras.length - 1).toInt();
      final oldController = _controller;
      _controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset
            .veryHigh, // Upped resolution specifically for clearer OCR boundary bounds layouts layouts boundaries form mapped constraint forms forms mapped mappings
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await oldController?.dispose();
      await _controller!.initialize();

      // Auto focuses specifically tailored mapped limits space constraint layouts limit
      await _controller!.setFlashMode(FlashMode.off);
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      if (mounted) {
        setState(() {
          _isFlashOn = false;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              "Unable to start Camera lens. Ensure permissions are granted securely.";
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final nextFlash = !_isFlashOn;
    await controller.setFlashMode(nextFlash ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() => _isFlashOn = nextFlash);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    await _initializeCamera((_cameraIndex + 1) % _cameras.length);
  }

  Future<void> _capturePlate() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing)
      return;

    setState(() => _isCapturing = true);

    // Tiny forced feedback haptic pop constraints bound limits forms layouts boundaries boundaries spaces
    HapticFeedback.mediumImpact();

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;

      // Passing XFile directly back accurately securely map limits bound mappings limits mapping boundary mapping
      Navigator.of(context).pop(photo);
    } catch (_) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Capture error occurred. Ensure subject is properly lit.",
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors
            .black, // Dark pure edge map space mapped mapped limits mapped layout forms maps limits spaces layouts map constraint layouts form limit constraint bounds limits
        body: Stack(
          children: [
            Positioned.fill(child: _buildLiveCameraView()),

            // Mask Layout: Completely translucent shadow punching OCR hole bounds
            Positioned.fill(child: _buildScannerFocusOverlay()),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    _buildFrostedTopBar(),
                    const Spacer(),

                    // Scan text helper mapping constraint layout layout mapped boundary bounds boundary spaces limits form boundaries form limits
                    _buildDynamicAssistantText(),
                    const SizedBox(height: 20),

                    // Redesigned Control console mappings form
                    _buildBottomActionConsole(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NATIVE SMART CAMERA STREAM MAPPING mapped maps forms bound mapping constraint bounds map boundary limit form boundary form maps limit constraints
  Widget _buildLiveCameraView() {
    final controller = _controller;

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator(color: accentBlue));
    }

    if (_error != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? "Vision camera lens offline.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit
          .cover, // Expands bounds limits limits boundary forms mapping standard maps seamlessly
      child: SizedBox(
        width: controller.value.previewSize!.height,
        height: controller.value.previewSize!.width,
        child: CameraPreview(controller),
      ),
    );
  }

  // --- TOP HUD BAR WITH BLUR BACKDROP boundary bounds map form mapping forms mapping boundaries constraint bound limit
  Widget _buildFrostedTopBar() {
    return Row(
      children: [
        _blurredControlButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        // Futuristic Status Badge boundary constraint layouts mapped mapped mapping limits spaces constraint layouts boundary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sensors_rounded, color: accentCyan, size: 14),
              const SizedBox(width: 8),
              const Text(
                "Optical Reader Active",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _blurredControlButton(
          icon: _isFlashOn ? Icons.bolt_rounded : Icons.flash_off_rounded,
          iconColor: _isFlashOn ? accentCyan : Colors.white,
          onTap: _toggleFlash,
        ),
      ],
    );
  }

  Widget _buildDynamicAssistantText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: accentCyan,
              strokeWidth: 2,
            ), // Mini scanner effect bounds map mappings maps forms layout boundaries space form mapping layouts boundaries space forms constraints map space boundary limit boundaries constraints mapped boundary space mapping layout
          ),
          const SizedBox(width: 10),
          const Text(
            "Center plate precisely inside the crosshairs",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- FUTURISTIC MASK AND LASER boundaries constraint forms mapped form limits bounds maps layouts mapping map limit space constraint map space mappings mapping constraints forms
  Widget _buildScannerFocusOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overlayHeight = constraints.maxHeight;
        final overlayWidth = constraints.maxWidth;

        // Custom bounds to slice through mapped map
        final scanWidth = overlayWidth * 0.85;
        final scanHeight = 160.0;
        final topOffset = (overlayHeight - scanHeight) / 2.3;

        return Stack(
          children: [
            // Dark Backdrop Hole-Puncher bound space map map boundary forms
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerTargetCutoutPainter(
                  scanRect: Rect.fromLTWH(
                    (overlayWidth - scanWidth) / 2,
                    topOffset,
                    scanWidth,
                    scanHeight,
                  ),
                  backgroundColor: Colors.black.withOpacity(
                    0.65,
                  ), // Thick shadows forms constraint limits bounds mappings
                ),
              ),
            ),

            // Reticule Target Corners limit mapping constraints boundary
            Positioned(
              left: (overlayWidth - scanWidth) / 2,
              top: topOffset,
              width: scanWidth,
              height: scanHeight,
              child: CustomPaint(
                painter: _BracketReticulePainter(
                  color: accentCyan,
                  thickness: 3.5,
                  length: 30,
                  radius: 12,
                ),
              ),
            ),

            // Pulsating Neon Blue Sweep Laser forms map mapping boundary mappings constraints mapping bound mapped mapping mappings limit boundary layouts layouts layout mapped mapping constraints boundaries mappings limits limits mapping mapped limit
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                final double currentY =
                    topOffset + (_laserAnimation.value * scanHeight);
                return Positioned(
                  left: (overlayWidth - scanWidth) / 2 + 10,
                  top: currentY,
                  width:
                      scanWidth -
                      20, // Prevents overlay bleeding outside border boundary limit layouts
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentBlue,
                      boxShadow: [
                        BoxShadow(
                          color: accentCyan.withOpacity(0.8),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: accentBlue.withOpacity(0.8),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- REDESIGNED DSLR STYLED CONSOLE maps limits form spaces bound mappings map bound limit layout space bounds layout constraint bound forms mappings limit limit
  Widget _buildBottomActionConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _blurredControlButton(
            icon: Icons.cameraswitch_rounded,
            onTap: _switchCamera,
            size: 50,
          ),

          // Shutter Master Button boundaries mappings layouts
          GestureDetector(
            onTap: _capturePlate,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isCapturing ? 40 : 66,
                  height: _isCapturing ? 40 : 66,
                  decoration: BoxDecoration(
                    color: _isCapturing ? accentBlue : Colors.white,
                    shape: _isCapturing ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: BorderRadius.circular(_isCapturing ? 12 : 50),
                    boxShadow: _isCapturing
                        ? [
                            BoxShadow(
                              color: accentCyan.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Optional placeholder boundary maps bounds mapped spaces layout limit layout bounds mapped
          _blurredControlButton(
            icon: Icons.image_rounded,
            onTap:
                () {}, // Can be implemented if needed seamlessly mapping mappings limits mapped
            size: 50,
          ),
        ],
      ),
    );
  }

  // Generalized control helper boundaries bound mappings
  Widget _blurredControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 46,
    Color iconColor = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(
            0.12,
          ), // High class Apple/Tesla inspired native translucent blur limit form layout spaces limit bounds forms
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(icon, color: iconColor, size: size * 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Custom Painter Graphics Engine bound boundary forms mapped mapped layout constraint map
// ──────────────────────────────────────────────────────────

class _ScannerTargetCutoutPainter extends CustomPainter {
  final Rect scanRect;
  final Color backgroundColor;

  _ScannerTargetCutoutPainter({
    required this.scanRect,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));

    // Fill rules punches out hole boundaries limits constraints layouts spaces mapping
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Crisp SciFi Technical Bracket Reticules drawing forms mappings forms constraints form boundaries
class _BracketReticulePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double length;
  final double radius;

  _BracketReticulePainter({
    required this.color,
    required this.thickness,
    required this.length,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      // Inner glowing emission mapping boundaries layout
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4);

    // TOP LEFT boundaries limit mapped limits maps forms
    final Path pathTL = Path()
      ..moveTo(0, length)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..lineTo(length, 0);
    // TOP RIGHT bounds map
    final Path pathTR = Path()
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius))
      ..lineTo(size.width, length);
    // BOTTOM RIGHT layouts mappings mapping mapped maps boundary constraint bounds
    final Path pathBR = Path()
      ..moveTo(size.width, size.height - length)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(
        Offset(size.width - radius, size.height),
        radius: Radius.circular(radius),
      )
      ..lineTo(size.width - length, size.height);
    // BOTTOM LEFT form limit constraint form limit
    final Path pathBL = Path()
      ..moveTo(length, size.height)
      ..lineTo(radius, size.height)
      ..arcToPoint(
        Offset(0, size.height - radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(0, size.height - length);

    canvas.drawPath(pathTL, paint);
    canvas.drawPath(pathTR, paint);
    canvas.drawPath(pathBR, paint);
    canvas.drawPath(pathBL, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
