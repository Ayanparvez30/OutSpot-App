import 'dart:async';
import 'dart:math' show pi;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Message/camera_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // permanent: true so Get.offAllNamed (e.g. navigating to the camera tab from
    // another screen) doesn't delete the controller out from under the freshly
    // built screen — that race disposed the camera right after it opened
    // ("open | onClosed"), so it never stayed open. The same instance is reused
    // across navigations; setPageVisibility re-opens the hardware on re-entry.
    final controller = Get.put(CameraControllers(), permanent: true);

    // Re-read the place/category context every time the camera screen is built.
    // The controller is permanent (onInit runs only once), so without this a
    // later Get.offAllNamed(tab:2, place:...) from a place screen would be
    // ignored and "Submit for Points" wouldn't pre-select on the next capture.
    controller.refreshArgs();

    // Default interval is 500ms, which delays camera init on every tab return.
    // Lower it so visibility (and init) is detected promptly.
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 100,
    );

    return VisibilityDetector(
      key: const Key('camera-screen'),
      onVisibilityChanged: (info) {
        controller.setPageVisibility(info.visibleFraction >= 0.10);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          leading: Obx(() {
            // Pushed from a chat (snap) or the Explore place check-in → show a
            // back button to return there instead of the profile avatar.
            if (controller.isSnapToFriend || controller.fromCheckIn.value) {
              return Padding(
                padding: EdgeInsets.only(left: 18.w),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: SvgPicture.asset(
                    "assets/svg/icons/cross_withOverlay.svg",
                    height: 36,
                    width: 36,
                  ),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.only(left: 18.w),
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.myProfile),
                child: Obx(() {
                  final imageUrl = controller.avatarurl.value;
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        alignment: Alignment.topCenter,
                        width: 40.w,
                        height: 30.h,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const ShimmerPlaceholder(),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          title: GestureDetector(
            onTap: () => Get.toNamed(Routes.viewAchievements),
            child: Obx(() {
              final accontroller = Get.find<MainscreeenController>();
              final ttl = accontroller.myAchievements.value?.title;
              String imagePath = "assets/svg/level/new_explorer.svg";
              if (ttl == "Urban Explorer")
                imagePath = "assets/svg/level/urbar_explorer.svg";
              else if (ttl == "Legendary Explorer")
                imagePath = "assets/svg/level/legendary_explorer.svg";
              else if (ttl == "City Sniper")
                imagePath = "assets/svg/level/city_snipper.svg";
              else if (ttl == "New Explorer")
                imagePath = "assets/svg/level/new_explorer.svg";

              return SvgPicture.asset(
                imagePath,
                height: 30.h,
                fit: BoxFit.contain,
              );
            }),
          ),
          actions: [
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () {
                controller.clearNotificationDot();
                Get.toNamed(Routes.notification1);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 10.w),
                    width: 34.w,
                    height: 34.w,
                    padding: EdgeInsets.all(5.sp),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black26,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/svg/icons/notification_icon.svg",
                        height: 18.sp,
                        width: 18.sp,
                      ),
                    ),
                  ),
                  Obx(
                    () =>
                        controller.notificationRedDot.value
                            ? Positioned(
                              right: 10,
                              top: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (!controller.isCameraReady.value ||
              controller.cameraController == null ||
              !(controller.cameraController?.value.isInitialized ?? false)) {
            return _buildProLoader();
          }

          final ctrl = controller.cameraController!;

          return Stack(
            children: [
              // Camera preview with pinch-to-zoom and double-tap to flip
              Positioned.fill(
                child: GestureDetector(
                  onScaleStart: controller.onScaleStart,
                  onScaleUpdate: controller.onScaleUpdate,
                  onDoubleTap: controller.switchCamera,
                  onTapDown: (details) {
                    controller.onTapToFocus(
                      details,
                      BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: MediaQuery.of(context).size.height,
                      ),
                    );
                  },
                  child: ClipRect(
                    // NOTE: no GlobalKey here. previewCaptureKey lived on the
                    // PERMANENT camera controller, so when navigating back to
                    // the camera tab via offAllNamed the outgoing + incoming
                    // CameraScreen briefly shared one key → "Duplicate GlobalKey"
                    // + a RenderClipRect/LayoutBuilder mutation crash. The key
                    // was never actually read, so it's removed.
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Use a fixed 9:16 aspect ratio for consistent preview
                          // (doesn't change when recording starts)
                          const previewAspect = 9 / 16;
                          final screenAspect =
                              constraints.maxWidth / constraints.maxHeight;
                          double w, h;
                          if (screenAspect > previewAspect) {
                            w = constraints.maxWidth;
                            h = w / previewAspect;
                          } else {
                            h = constraints.maxHeight;
                            w = h * previewAspect;
                          }
                          return OverflowBox(
                            alignment: Alignment.center,
                            maxWidth: w,
                            maxHeight: h,
                            child: SizedBox(
                              width: w,
                              height: h,
                              child: CameraPreview(ctrl),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Focus circle overlay
              if (controller.showFocusCircle.value)
                Positioned(
                  left: controller.focusPoint.value.dx - 30,
                  top: controller.focusPoint.value.dy - 30,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellow, width: 2),
                    ),
                  ),
                ),
              // Camera flip icon removed
              // Left-side collapsible tools menu
              Positioned(
                top: 100.h,
                left: 15.w,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flash button (always visible)
                      Obx(
                        () => _buildToolButton(
                          icon: controller.getFlashIcon(),
                          isActive:
                              controller.currentFlashMode.value !=
                              FlashMode.off,
                          onTap: controller.toggleFlashMode,
                          iconColor:
                              controller.currentFlashMode.value != FlashMode.off
                                  ? Colors.yellowAccent
                                  : Colors.white,
                        ),
                      ),

                      // Expandable section
                      Obx(() {
                        if (!controller.isToolsExpanded.value) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            SizedBox(height: 20.h),
                            // Timer
                            Obx(
                              () => _buildToolButton(
                                icon:
                                    controller.selectedTimer.value == 0
                                        ? Icons.timer_off
                                        : (controller.selectedTimer.value == 3
                                            ? Icons.timer_3
                                            : Icons.timer_10),
                                isActive: controller.selectedTimer.value > 0,
                                onTap: controller.toggleTimer,
                                text:
                                    controller.selectedTimer.value > 0
                                        ? "${controller.selectedTimer.value}s"
                                        : null,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            // Exposure
                            Obx(
                              () => _buildToolButton(
                                icon: Icons.exposure,
                                isActive: controller.showExposureSlider.value,
                                onTap: controller.toggleExposureSlider,
                              ),
                            ),
                          ],
                        );
                      }),

                      SizedBox(height: 10.h),

                      // Dropdown arrow toggle
                      GestureDetector(
                        onTap: controller.toggleToolsMenu,
                        child: Obx(
                          () => Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              controller.isToolsExpanded.value
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exposure slider (vertical)
              Obx(() {
                if (!controller.showExposureSlider.value) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  right: 50.w,
                  top: 250.h,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Container(
                      width: 200.w,
                      height: 40.h,
                      alignment: Alignment.center,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: controller.currentExposureOffset.value,
                          min: controller.minExposure.value,
                          max: controller.maxExposure.value,
                          activeColor: Colors.yellowAccent,
                          inactiveColor: Colors.white30,
                          onChanged: (value) {
                            controller.setExposure(value);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Countdown timer display
              if (controller.isCountingDown.value)
                Center(
                  child: Text(
                    "${controller.countdownValue.value}",
                    style: TextStyle(
                      fontSize: 100.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black),
                      ],
                    ),
                  ),
                ),

              // Zoom text indicator
              Positioned(
                bottom: 200.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() {
                    if (controller.currentZoom.value <= 1.0) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${controller.currentZoom.value.toStringAsFixed(1)}x",
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Capture button
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 135),
                  // Only the recording state (start/stop) drives this rebuild.
                  // The progress arc animates via the AnimatedBuilder below, so
                  // the button + static border are NOT rebuilt every frame
                  // during the 15s recording (that per-frame churn compounded
                  // the "glitchy while recording" feel).
                  child: Obx(() {
                    final capturing = controller.isCapturing.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter: StaticBlueBorderPainter(
                            isCapturing: capturing,
                          ),
                          child: const SizedBox(width: 90, height: 90),
                        ),

                        // Per-frame progress arc, isolated so ONLY this
                        // CustomPaint repaints as the record timer advances.
                        if (capturing)
                          AnimatedBuilder(
                            animation: controller.rotationController,
                            builder:
                                (_, __) => CustomPaint(
                                  painter: GrowingRedArcPainter(
                                    controller.rotationController.value,
                                  ),
                                  child: const SizedBox(width: 90, height: 90),
                                ),
                          ),

                        BounceCaptureButton(
                          isCapturing: capturing,
                          onTap: controller.captureImage,
                          onLongPressStart: controller.startVideoRecording,
                          onLongPressEnd: controller.stopVideoRecording,
                          onZoomDrag: controller.onZoomDrag,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    String? text,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 26.sp),
            if (text != null)
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProLoader() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff323434).withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff704EF9).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50.w,
                    height: 50.w,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xff704EF9),
                      ),
                      strokeWidth: 2.5,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  UnconstrainedBox(
                    child: SvgPicture.asset(
                      "assets/svg/icons/camera_icon.svg",

                      // fit: BoxFit.scaleDown,
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

class GrowingRedArcPainter extends CustomPainter {
  final double progress;
  GrowingRedArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xff704EF9)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = progress * 2 * pi;
    const startAngle = -pi / 2;
    if (sweepAngle > 0.01) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GrowingRedArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class BounceCaptureButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final ValueChanged<double>? onZoomDrag;
  final bool isCapturing;

  const BounceCaptureButton({
    super.key,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    this.onZoomDrag,
    required this.isCapturing,
  });

  @override
  State<BounceCaptureButton> createState() => _BounceCaptureButtonState();
}

class _BounceCaptureButtonState extends State<BounceCaptureButton> {
  double _scale = 1.0;
  Timer? _holdTimer;
  bool _isRecording = false;
  double _startY = 0;

  void _handlePointerDown(PointerEvent event) {
    setState(() => _scale = 0.85);
    _isRecording = false;
    _startY = event.position.dy;

    // 250ms delay to cleanly separate a tap from a video hold
    _holdTimer = Timer(const Duration(milliseconds: 250), () {
      _isRecording = true;
      setState(() => _scale = 1.0);
      widget.onLongPressStart();
    });
  }

  void _handlePointerMove(PointerEvent event) {
    if (_isRecording && widget.onZoomDrag != null) {
      // Calculate upward drag distance
      final dy = _startY - event.position.dy;
      // Dead-zone: ignore the small finger movement/jitter that happens right
      // as you press-and-hold, so zoom doesn't jump from 1x the instant you
      // start recording. Only an intentional drag past the threshold zooms,
      // and it starts smoothly from the base zoom. Symmetric so drag-down
      // (zoom out) keeps working too.
      const double dragDeadZone = 28.0;
      double effective;
      if (dy > dragDeadZone) {
        effective = dy - dragDeadZone;
      } else if (dy < -dragDeadZone) {
        effective = dy + dragDeadZone;
      } else {
        effective = 0.0;
      }
      widget.onZoomDrag!(effective);
    }
  }

  void _handlePointerUp(PointerEvent event) {
    setState(() => _scale = 1.0);

    if (_holdTimer != null && _holdTimer!.isActive) {
      _holdTimer!.cancel();
      widget.onTap();
    } else if (_isRecording) {
      widget.onLongPressEnd();
      _isRecording = false;
    }
  }

  void _handlePointerCancel(PointerEvent event) {
    setState(() => _scale = 1.0);
    if (_holdTimer != null && _holdTimer!.isActive) {
      _holdTimer!.cancel();
    } else if (_isRecording) {
      widget.onLongPressEnd();
      _isRecording = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          width: 75,
          height: 75,
          decoration: const BoxDecoration(
            color: Color(0xff323434),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.circle,
              color:
                  widget.isCapturing
                      ? const Color(0xff704EF9)
                      : const Color(0xff323434),
              size: 28.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class StaticBlueBorderPainter extends CustomPainter {
  final bool isCapturing;
  StaticBlueBorderPainter({required this.isCapturing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isCapturing ? Colors.white : const Color(0xff704EF9)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant StaticBlueBorderPainter oldDelegate) =>
      oldDelegate.isCapturing != isCapturing;
}
