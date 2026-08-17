import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

class FrontCameraScreen extends StatefulWidget {
  const FrontCameraScreen({super.key});

  @override
  State<FrontCameraScreen> createState() => _FrontCameraScreenState();
}

class _FrontCameraScreenState extends State<FrontCameraScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCapturing = false;
  List<CameraDescription> _cameras = [];
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    await _setupCamera(useFront: true);
  }

  Future<void> _setupCamera({required bool useFront}) async {
    if (_cameras.isEmpty) return;

    final camera = _cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (useFront ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );

    // Dispose old controller before switching
    await _cameraController?.dispose();

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isFrontCamera = useFront;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitialized = false);
    await _setupCamera(useFront: !_isFrontCamera);
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || _isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final xFile = await _cameraController!.takePicture();
      // Only flip horizontally for front camera (mirror match)
      if (_isFrontCamera) {
        final bytes = await File(xFile.path).readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded != null) {
          decoded = img.flipHorizontal(decoded);
          await File(xFile.path).writeAsBytes(img.encodeJpg(decoded, quality: 95));
        }
      }
      if (mounted) {
        Navigator.pop(context, xFile.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview — match captured image exactly
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top bar with close button and instruction
            Positioned(
              top: 10.h,
              left: 16.w,
              right: 16.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  Text(
                    "Align your face to the center",
                    style: GoogleFonts.notoSans(
                      color: Colors.amber,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Face guide oval
            if (_isInitialized)
              Center(
                child: Container(
                  width: 220.w,
                  height: 280.h,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(110.w, 140.h),
                    ),
                  ),
                ),
              ),

            // Bottom controls: capture button + flip button
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Capture button (centered)
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 58.w,
                          height: 58.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing ? Colors.grey : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Flip camera button (to the right)
                  Positioned(
                    right: 40.w,
                    child: GestureDetector(
                      onTap: _flipCamera,
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flip_camera_ios_outlined,
                          color: Colors.white,
                          size: 26.sp,
                        ),
                      ),
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
