import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EvidenceCameraCaptureScreen extends StatefulWidget {
  const EvidenceCameraCaptureScreen({
    super.key,
    this.captureVideo = false,
  });

  final bool captureVideo;

  @override
  State<EvidenceCameraCaptureScreen> createState() =>
      _EvidenceCameraCaptureScreenState();
}

class _EvidenceCameraCaptureScreenState
    extends State<EvidenceCameraCaptureScreen> {
  static const Color accentBlue = Color(0xFF2A5EE8);

  CameraController? _controller;
  Timer? _recordingTimer;
  bool _isInitializing = true;
  bool _isBusy = false;
  bool _isFlashOn = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      final rearCameras = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .toList();
      if (rearCameras.isEmpty) {
        throw Exception("No rear camera detected on this device.");
      }

      final controller = CameraController(
        rearCameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isFlashOn = false;
        _isInitializing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = "Rear camera unavailable. Evidence must use the back camera.";
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }

    try {
      final nextFlash = !_isFlashOn;
      await controller.setFlashMode(nextFlash ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _isFlashOn = nextFlash);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Flash is unavailable on this device.")),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    HapticFeedback.mediumImpact();

    try {
      final photo = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(photo);
    } catch (_) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to capture photo. Try again.")),
        );
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }

    HapticFeedback.mediumImpact();

    if (_isRecording) {
      setState(() => _isBusy = true);
      _recordingTimer?.cancel();

      try {
        final video = await controller.stopVideoRecording();
        if (mounted) Navigator.of(context).pop(video);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isBusy = false;
            _isRecording = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to save video. Try again.")),
          );
        }
      }
      return;
    }

    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to start video. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildCameraPreview()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const Spacer(),
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
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
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                _error ?? "Camera unavailable.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize!.height,
        height: controller.value.previewSize!.width,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.48),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_rear_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                "Rear Camera",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _circleButton(
          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          onTap: _toggleFlash,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isVideo = widget.captureVideo;
    final shutterColor = isVideo
        ? (_isRecording ? Colors.white : Colors.redAccent)
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatDuration(_recordingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: isVideo ? _toggleVideoRecording : _capturePhoto,
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: Colors.transparent,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: _isBusy ? 34 : (_isRecording ? 34 : 62),
                height: _isBusy ? 34 : (_isRecording ? 34 : 62),
                decoration: BoxDecoration(
                  color: _isBusy ? accentBlue : shutterColor,
                  shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: BorderRadius.circular(_isRecording ? 8 : 40),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$remainingSeconds";
  }
}
