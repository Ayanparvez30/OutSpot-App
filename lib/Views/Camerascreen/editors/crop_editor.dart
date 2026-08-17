import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

class CropEditorScreen extends StatefulWidget {
  final String imagePath;
  final Function(String croppedPath) onDone;

  const CropEditorScreen({
    super.key,
    required this.imagePath,
    required this.onDone,
  });

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  double _rotation = 0; // in quarter turns (0, 1, 2, 3)
  bool _flipH = false;
  bool _flipV = false;
  bool _isProcessing = false;
  bool _isDragging = false;
  Timer? _toolbarTimer;

  // Actual Image Aspect Ratio fetch korar jonno variable
  double? _imageAspectRatio;

  // Crop rect as fraction of image (0.0 to 1.0)
  static const double _initialPad = 0.0;
  double _cropLeft = _initialPad;
  double _cropTop = _initialPad;
  double _cropRight = 1.0 - _initialPad;
  double _cropBottom = 1.0 - _initialPad;

  int?
  _dragHandle; // 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight, 4=move

  // Image Zoom/Pan er control er jonno controller
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImageAspectRatio(); // Screen open holei image er actual size ber korbe
  }

  // Eita image er perfectly actual aspect ratio ber korbe
  void _loadImageAspectRatio() {
    final ImageProvider imageProvider = FileImage(File(widget.imagePath));
    imageProvider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _imageAspectRatio = info.image.width / info.image.height;
              });
            }
          }),
        );
  }

  @override
  void dispose() {
    _toolbarTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  void _rotateRight() {
    setState(() {
      _rotation = (_rotation + 1) % 4;
      _transformationController.value =
          Matrix4.identity(); // Rotate korle zoom reset hbe
    });
  }

  Future<void> _applyCropAndRotation() async {
    setState(() => _isProcessing = true);

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      // Apply rotation
      final quarterTurns = _rotation.round() % 4;
      if (quarterTurns == 1) {
        decoded = img.copyRotate(decoded, angle: 90);
      } else if (quarterTurns == 2) {
        decoded = img.copyRotate(decoded, angle: 180);
      } else if (quarterTurns == 3) {
        decoded = img.copyRotate(decoded, angle: 270);
      }

      // Apply flips
      if (_flipH) decoded = img.flipHorizontal(decoded);
      if (_flipV) decoded = img.flipVertical(decoded);

      final imgW = decoded.width.toDouble();
      final imgH = decoded.height.toDouble();

      // Matrix transformation data calculations for zoomed state matrix
      final Matrix4 matrix = _transformationController.value;
      final double scale = matrix.getMaxScaleOnAxis();
      final double translationX = matrix.getTranslation().x;
      final double translationY = matrix.getTranslation().y;

      // Adjusted calculations considering the user zoom/pan coordinates
      double cropLeftPixel =
          (_cropLeft * imgW - translationX * (imgW / _displayWidth)) / scale;
      double cropTopPixel =
          (_cropTop * imgH - translationY * (imgH / _displayHeight)) / scale;
      double cropRightPixel =
          (_cropRight * imgW - translationX * (imgW / _displayWidth)) / scale;
      double cropBottomPixel =
          (_cropBottom * imgH - translationY * (imgH / _displayHeight)) / scale;

      final x = cropLeftPixel.round().clamp(0, decoded.width - 1);
      final y = cropTopPixel.round().clamp(0, decoded.height - 1);
      final w = (cropRightPixel - cropLeftPixel).round().clamp(
        1,
        decoded.width - x,
      );
      final h = (cropBottomPixel - cropTopPixel).round().clamp(
        1,
        decoded.height - y,
      );

      if (w > 0 && h > 0) {
        decoded = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      }

      final tempDir = await Directory.systemTemp.createTemp();
      final outPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(decoded, quality: 100));

      widget.onDone(outPath);
    } catch (e) {
      debugPrint('Crop error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  double _displayWidth = 1.0;
  double _displayHeight = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _isDragging ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: _isDragging,
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.4),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Crop & Rotate',
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                _isProcessing
                    ? Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                    : IconButton(
                      icon: Icon(
                        Icons.check,
                        color: const Color(0xFFAB50F6),
                        size: 28.sp,
                      ),
                      onPressed: _applyCropAndRotation,
                    ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: kToolbarHeight + 60.h,
                bottom: 160.h,
                left: 20.w,
                right: 20.w,
              ),
              child: Center(child: _buildCropPreview()),
            ),
          ),

          // Bottom toolbar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _isDragging ? -150 : 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isDragging ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: EdgeInsets.only(
                  top: 16.h,
                  bottom:
                      MediaQuery.of(context).padding.bottom > 0
                          ? MediaQuery.of(context).padding.bottom
                          : 16.h,
                ),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomButton(
                      Icons.rotate_right,
                      'Rotate',
                      _rotateRight,
                    ),
                    _buildBottomButton(Icons.flip, 'Flip H', () {
                      setState(() => _flipH = !_flipH);
                    }),
                    GestureDetector(
                      onTap: () => setState(() => _flipV = !_flipV),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotatedBox(
                            quarterTurns: 1,
                            child: Icon(
                              Icons.flip,
                              color: Colors.white,
                              size: 28.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Flip V',
                            style: GoogleFonts.notoSans(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBottomButton(Icons.crop_free, 'Reset', () {
                      setState(() {
                        _cropLeft = 0.0;
                        _cropTop = 0.0;
                        _cropRight = 1.0;
                        _cropBottom = 1.0;
                        _rotation = 0;
                        _flipH = false;
                        _flipV = false;
                        _transformationController.value =
                            Matrix4.identity(); // Reset zoom
                      });
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPreview() {
    // Image er actual size ber na howa porjonto choto loader dekhabe (ekdom fast hoye jabe)
    if (_imageAspectRatio == null) {
      return const CircularProgressIndicator(color: Color(0xFFAB50F6));
    }

    return Transform(
      alignment: Alignment.center,
      transform:
          Matrix4.identity()..scale(_flipH ? -1.0 : 1.0, _flipV ? -1.0 : 1.0),
      child: RotatedBox(
        quarterTurns: _rotation.round() % 4,
        // MAGIC FIX: AspectRatio widget perfectly bounds the Stack to the image's real shape!
        child: AspectRatio(
          aspectRatio: _imageAspectRatio!,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image now perfectly fills the aspect-ratio-corrected box
              InteractiveViewer(
                transformationController: _transformationController,
                clipBehavior: Clip.none,
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.file(
                  File(widget.imagePath),
                  fit:
                      BoxFit
                          .fill, // AspectRatio thik ache bole ekhon fill dileo kono jhamela nai
                ),
              ),

              // Gestures and Crop overlay boundary configuration (will never cross the image)
              LayoutBuilder(
                builder: (context, imgConstraints) {
                  _displayWidth = imgConstraints.maxWidth;
                  _displayHeight = imgConstraints.maxHeight;
                  final w = _displayWidth;
                  final h = _displayHeight;

                  return GestureDetector(
                    onPanStart: (details) {
                      final double pxX = details.localPosition.dx;
                      final double pxY = details.localPosition.dy;
                      _dragHandle = _getHandle(pxX, pxY, w, h);
                      if (_dragHandle != null) {
                        _toolbarTimer?.cancel();
                        setState(() => _isDragging = true);
                      }
                    },
                    onPanUpdate: (details) {
                      if (_dragHandle == null) return;
                      final dx = details.delta.dx / w;
                      final dy = details.delta.dy / h;
                      setState(() {
                        _updateCrop(dx, dy);
                      });
                    },
                    onPanEnd: (_) {
                      _dragHandle = null;
                      _toolbarTimer?.cancel();
                      _toolbarTimer = Timer(
                        const Duration(milliseconds: 500),
                        () {
                          if (mounted) setState(() => _isDragging = false);
                        },
                      );
                    },
                    onPanCancel: () {
                      _dragHandle = null;
                      _toolbarTimer?.cancel();
                      _toolbarTimer = Timer(
                        const Duration(milliseconds: 500),
                        () {
                          if (mounted) setState(() => _isDragging = false);
                        },
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _CropOverlayPainter(
                            cropLeft: _cropLeft,
                            cropTop: _cropTop,
                            cropRight: _cropRight,
                            cropBottom: _cropBottom,
                          ),
                          size: Size(w, h),
                        ),
                        // Center crop_free indicator
                        Positioned(
                          left:
                              (_cropLeft * w) +
                              ((_cropRight - _cropLeft) * w) / 2 -
                              20,
                          top:
                              (_cropTop * h) +
                              ((_cropBottom - _cropTop) * h) / 2 -
                              20,
                          child: IgnorePointer(
                            child: Icon(
                              Icons.crop_free,
                              color: Colors.white.withOpacity(0.7),
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logical pixels check for much easier touch target detection
  int _getHandle(double pxX, double pxY, double w, double h) {
    const double targetRadius = 32.0;

    final double l = _cropLeft * w;
    final double t = _cropTop * h;
    final double r = _cropRight * w;
    final double b = _cropBottom * h;

    if ((pxX - l).abs() < targetRadius && (pxY - t).abs() < targetRadius)
      return 0; // top-left
    if ((pxX - r).abs() < targetRadius && (pxY - t).abs() < targetRadius)
      return 1; // top-right
    if ((pxX - l).abs() < targetRadius && (pxY - b).abs() < targetRadius)
      return 2; // bottom-left
    if ((pxX - r).abs() < targetRadius && (pxY - b).abs() < targetRadius)
      return 3; // bottom-right

    if (pxX > l && pxX < r && pxY > t && pxY < b) return 4; // move inner region
    return 4;
  }

  void _updateCrop(double dx, double dy) {
    switch (_dragHandle) {
      case 0: // top-left
        _cropLeft = (_cropLeft + dx).clamp(0.0, _cropRight - 0.1);
        _cropTop = (_cropTop + dy).clamp(0.0, _cropBottom - 0.1);
        break;
      case 1: // top-right
        _cropRight = (_cropRight + dx).clamp(_cropLeft + 0.1, 1.0);
        _cropTop = (_cropTop + dy).clamp(0.0, _cropBottom - 0.1);
        break;
      case 2: // bottom-left
        _cropLeft = (_cropLeft + dx).clamp(0.0, _cropRight - 0.1);
        _cropBottom = (_cropBottom + dy).clamp(_cropTop + 0.1, 1.0);
        break;
      case 3: // bottom-right
        _cropRight = (_cropRight + dx).clamp(_cropLeft + 0.1, 1.0);
        _cropBottom = (_cropBottom + dy).clamp(_cropTop + 0.1, 1.0);
        break;
      case 4: // move
        final w = _cropRight - _cropLeft;
        final h = _cropBottom - _cropTop;
        var newLeft = _cropLeft + dx;
        var newTop = _cropTop + dy;
        newLeft = newLeft.clamp(0.0, 1.0 - w);
        newTop = newTop.clamp(0.0, 1.0 - h);
        _cropLeft = newLeft;
        _cropTop = newTop;
        _cropRight = newLeft + w;
        _cropBottom = newTop + h;
        break;
    }
  }

  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28.sp),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final double cropLeft, cropTop, cropRight, cropBottom;

  _CropOverlayPainter({
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final l = cropLeft * w;
    final t = cropTop * h;
    final r = cropRight * w;
    final b = cropBottom * h;

    // Dark overlay outside crop
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawRect(Rect.fromLTRB(0, 0, w, t), overlayPaint); // top
    canvas.drawRect(Rect.fromLTRB(0, t, l, b), overlayPaint); // left
    canvas.drawRect(Rect.fromLTRB(r, t, w, b), overlayPaint); // right
    canvas.drawRect(Rect.fromLTRB(0, b, w, h), overlayPaint); // bottom

    // Crop border
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTRB(l, t, r, b), borderPaint);

    // Grid lines (rule of thirds)
    final gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 0.5;
    final thirdW = (r - l) / 3;
    final thirdH = (b - t) / 3;
    canvas.drawLine(Offset(l + thirdW, t), Offset(l + thirdW, b), gridPaint);
    canvas.drawLine(
      Offset(l + thirdW * 2, t),
      Offset(l + thirdW * 2, b),
      gridPaint,
    );
    canvas.drawLine(Offset(l, t + thirdH), Offset(r, t + thirdH), gridPaint);
    canvas.drawLine(
      Offset(l, t + thirdH * 2),
      Offset(r, t + thirdH * 2),
      gridPaint,
    );

    // Corner handles (Made slightly thicker for visual reassurance)
    final handlePaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    const hl = 24.0;

    // Top-left
    canvas.drawLine(Offset(l, t), Offset(l + hl, t), handlePaint);
    canvas.drawLine(Offset(l, t), Offset(l, t + hl), handlePaint);
    // Top-right
    canvas.drawLine(Offset(r, t), Offset(r - hl, t), handlePaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + hl), handlePaint);
    // Bottom-left
    canvas.drawLine(Offset(l, b), Offset(l + hl, b), handlePaint);
    canvas.drawLine(Offset(l, b), Offset(l, b - hl), handlePaint);
    // Bottom-right
    canvas.drawLine(Offset(r, b), Offset(r - hl, b), handlePaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - hl), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) =>
      old.cropLeft != cropLeft ||
      old.cropTop != cropTop ||
      old.cropRight != cropRight ||
      old.cropBottom != cropBottom;
}
