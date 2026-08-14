import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Pushes a full-screen live camera capture flow (preview -> shot -> review)
/// and returns the confirmed photo file, or null if the applicant backs out.
Future<File?> captureOrganizerPhoto(
  BuildContext context, {
  required String title,
  required String prompt,
  required CameraLensDirection lens,
  required OrganizerCaptureGuide guide,
}) {
  return Navigator.of(context).push<File?>(
    MaterialPageRoute(
      builder: (_) => _CameraCaptureScreen(
        title: title,
        prompt: prompt,
        lens: lens,
        guide: guide,
      ),
    ),
  );
}

/// Pushes a full-screen live camera video-recording flow, hard-capped at
/// [maxSeconds] (the walkthrough is capped at 60s/720p/30MB per
/// FIRESTORE_SCHEMA.md, enforced here by the recorder preset + this timer).
/// Returns the confirmed clip file, or null if the applicant backs out.
Future<File?> captureOrganizerVideo(
  BuildContext context, {
  required String title,
  required String prompt,
  int maxSeconds = 60,
}) {
  return Navigator.of(context).push<File?>(
    MaterialPageRoute(
      builder: (_) => _CameraCaptureScreen(
        title: title,
        prompt: prompt,
        lens: CameraLensDirection.back,
        guide: OrganizerCaptureGuide.none,
        isVideo: true,
        maxSeconds: maxSeconds,
      ),
    ),
  );
}

enum OrganizerCaptureGuide { corners, oval, none }

class _CameraCaptureScreen extends StatefulWidget {
  const _CameraCaptureScreen({
    required this.title,
    required this.prompt,
    required this.lens,
    required this.guide,
    this.isVideo = false,
    this.maxSeconds = 60,
  });

  final String title;
  final String prompt;
  final CameraLensDirection lens;
  final OrganizerCaptureGuide guide;
  final bool isVideo;
  final int maxSeconds;

  @override
  State<_CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<_CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;

  File? _captured;
  bool _recording = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }
      final description = cameras.firstWhere(
        (c) => c.lensDirection == widget.lens,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        widget.isVideo ? ResolutionPreset.high : ResolutionPreset.max,
        enableAudio: widget.isVideo,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start the camera: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      setState(() => _captured = File(file.path));
    } catch (e) {
      _showSnack('Could not capture — try again.');
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.startVideoRecording();
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
        if (_seconds >= widget.maxSeconds) _stopRecording();
      });
    } catch (e) {
      _showSnack('Could not start recording — try again.');
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_recording) return;
    _timer?.cancel();
    try {
      final file = await controller.stopVideoRecording();
      setState(() {
        _recording = false;
        _captured = File(file.path);
      });
    } catch (e) {
      setState(() => _recording = false);
      _showSnack('Could not save the recording — try again.');
    }
  }

  void _retake() => setState(() => _captured = null);

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(int sec) =>
      '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              ),
            );
          }
          if (_controller == null || snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (_captured != null) return _buildReview();
          return _buildLive();
        },
      ),
    );
  }

  Widget _buildLive() {
    final controller = _controller!;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: CameraPreview(controller)),
              Positioned(
                top: 16,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.prompt,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ),
              ),
              if (widget.guide != OrganizerCaptureGuide.none) Center(child: _buildGuide()),
              if (_recording)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(_fmt(_seconds), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: GestureDetector(
              onTap: widget.isVideo ? (_recording ? _stopRecording : _startRecording) : _takePhoto,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: widget.isVideo
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: _recording ? 26 : 54,
                          height: _recording ? 26 : 54,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(_recording ? 6 : 27),
                          ),
                        )
                      : Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuide() {
    if (widget.guide == OrganizerCaptureGuide.oval) {
      return Container(
        width: 200,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(130),
          border: Border.all(color: AppTheme.primary, width: 2, style: BorderStyle.solid),
        ),
      );
    }
    // corners guide (NIC)
    return SizedBox(
      width: 280,
      height: 170,
      child: Stack(children: [
        _corner(top: 0, left: 0),
        _corner(top: 0, right: 0),
        _corner(bottom: 0, left: 0),
        _corner(bottom: 0, right: 0),
      ]),
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: AppTheme.primary, width: 3) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: AppTheme.primary, width: 3) : BorderSide.none,
            left: left != null ? const BorderSide(color: AppTheme.primary, width: 3) : BorderSide.none,
            right: right != null ? const BorderSide(color: AppTheme.primary, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        Expanded(
          child: widget.isVideo
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 56),
                      const SizedBox(height: 12),
                      Text('Walkthrough recorded · ${_fmt(_seconds)}',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                )
              : InteractiveViewer(
                  child: Image.file(_captured!, fit: BoxFit.contain, width: double.infinity),
                ),
        ),
        Container(
          color: const Color(0xFF1A1A1B),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isVideo ? 'Use this walkthrough?' : 'Use this photo?',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retake,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderGray),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Retake', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_captured),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Looks good', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
