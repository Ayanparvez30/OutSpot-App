import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/point_submit_Dialog.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Model/explore_place_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Views/Camerascreen/capturescreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class CameraControllers extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  // final ccc = Get.put(MessagesScreenController());
  late IO.Socket socket;

  Timer? _recordTimer;
  final int maxRecordDuration = 15;

  bool _isHardwareBusy = false;
  bool _wantsToRecord = false;

  DateTime? _recordingStartTime;

  CameraController? cameraController;
  late AnimationController rotationController;
  bool _isRequestingPermission = false;
  bool _isCameraPageVisible = false;

  late List<CameraDescription> cameras;
  final RxBool isCameraReady = false.obs;
  final RxBool isCapturing = false.obs;
  final RxInt cameraGeneration = 0.obs;
  int selectedCameraIdx = 0;

  var currentUserId = 0.obs;
  final RxnString avatarUrl = RxnString();
  RxString avatarurl = ''.obs;
  RxList minimeList = [].obs;
  bool _isInitRunning = false;
  // Set when initCamera() is called while one is already running. The in-flight
  // run honors it on completion so a request never gets silently dropped.
  bool _pendingInit = false;
  // Set true when the controller is being torn down (onClose/dispose). Used to
  // abort an in-flight initCamera() that races with teardown, instead of letting
  // safeRelease dispose the controller mid-initialize() (causes "used after
  // disposed" crash).
  bool _disposed = false;
  int _initRetryCount = 0;
  static const int _maxRetries = 2;

  RxDouble minZoom = 1.0.obs;
  RxDouble maxZoom = 1.0.obs;
  RxDouble currentZoom = 1.0.obs;
  double _baseScale = 1.0;

  // --- Serialized, coalescing zoom application ---
  // Gesture events arrive at ~60-120Hz. Each setZoomLevel() rebuilds the
  // Camera2 repeating capture request — which, while recording, feeds BOTH the
  // preview AND the encoder surface — so firing one per gesture event
  // concurrently floods the session with reconfigurations and stutters the
  // video ("glitchy zoom", esp. on Samsung A55). We decouple the gesture rate
  // from the hardware rate: gesture handlers only store a target + move the
  // on-screen indicator; a single in-flight worker pushes the LATEST target to
  // the camera, coalescing everything in between.
  double _targetZoom = 1.0; // newest zoom the user asked for (already clamped)
  double _appliedZoom = 1.0; // last zoom actually pushed to the hardware
  bool _isApplyingZoom = false; // a worker loop is currently draining to target
  static const double _zoomEpsilon = 0.01; // "converged / close enough"
  static const double _zoomMinStep = 0.02; // drop sub-step jitter (saves refreshes)

  // Devices report absurd digital-zoom maxima (50x–100x+). Cap to a realistic
  // ceiling so pinch/drag zoom stays usable (similar to a phone's default app).
  static const double _maxZoomCap = 8.0;
  double _cappedMaxZoom(double deviceMax) =>
      deviceMax > _maxZoomCap ? _maxZoomCap : deviceMax;

  // Flash (Persisted State)
  Rx<FlashMode> currentFlashMode = FlashMode.off.obs;

  // Timer
  RxInt selectedTimer = 0.obs; // 0=off, 3=3s, 10=10s
  RxInt countdownValue = 0.obs;
  RxBool isCountingDown = false.obs;
  // 4. Tap to Focus
  RxBool showFocusCircle = false.obs;
  Rx<Offset> focusPoint = const Offset(0, 0).obs; // Screen coordinates
  Timer? _focusResetTimer;
  // 1. Exposure (Brightness)
  RxDouble minExposure = (-2.0).obs;
  RxDouble maxExposure = 2.0.obs;
  RxDouble currentExposureOffset = 0.0.obs;
  RxBool showExposureSlider = false.obs;
  RxBool isToolsExpanded = false.obs;

  // --------------------------------------------------------

  // Explore
  Rxn<ExplorePlaceModel> targetPlace = Rxn<ExplorePlaceModel>();
  RxnString targetCategoryKey = RxnString();
  // The route-arguments object we've already consumed a place/category from.
  // The mainscreen route keeps the SAME arguments object across tab switches,
  // so we use object identity to consume a check-in's place exactly once —
  // re-entering the camera tab afterwards must NOT re-select "Submit for Points".
  Object? _consumedArgs;

  // Snap-to-friend (opened from DirectMessageScreen camera button).
  // When snapChatId > 0 the capture screen shows a "Send to {name}" button.
  final RxInt snapChatId = 0.obs;
  final RxnString snapRecipientName = RxnString();
  bool get isSnapToFriend => snapChatId.value > 0;
  void setSnapTarget({required int chatId, String? name}) {
    snapChatId.value = chatId;
    snapRecipientName.value = name;
  }

  void clearSnapTarget() {
    snapChatId.value = 0;
    snapRecipientName.value = null;
  }

  // True when the camera was PUSHED from the Explore place check-in flow
  // (explore → category → place → Check In). In that mode the screen shows a
  // back button (returns to the place) instead of the profile avatar.
  final RxBool fromCheckIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadUserProfile();
    initCamera();

    // NOTE: do NOT call refreshArgs() here. The screen's build() always calls
    // it, and on first creation onInit + build would both consume the SAME
    // arguments object — the second call would treat it as "already consumed"
    // and wrongly clear the place, so the very first check-in after an app
    // restart wouldn't pre-select "Submit for Points".

    // NOTE: no `..addListener(() => update())` here. That fired a GetX update()
    // on EVERY animation frame for the whole 15s recording, rebuilding the
    // capture-button subtree ~60Hz and compounding the "glitchy while recording"
    // feel. The progress arc now animates via an AnimatedBuilder in the screen
    // (only that CustomPaint repaints per frame); recording state is observed
    // through the existing isCapturing Rx.
    rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    getRedDot();
  }

  /// Re-read the place/category context from the current route arguments.
  ///
  /// MUST run on every camera entry (not just onInit) because this controller
  /// is permanent — onInit fires only once, so a later
  /// Get.offAllNamed(tab:2, place:...) from a place-detail screen would
  /// otherwise be ignored and "Submit for Points" wouldn't pre-select.
  /// Sets the target when a place is supplied, clears it otherwise so a plain
  /// camera capture isn't mistaken for a place submission.
  void refreshArgs() {
    final args = Get.arguments;

    // Check-in push session → the camera route is dedicated to this place for
    // its whole lifetime (a retake rebuilds the screen with the same args), so
    // the place must persist rather than be consumed-once.
    final bool checkIn = args is Map && args['fromCheckIn'] == true;
    fromCheckIn.value = checkIn;

    // Consume the place/category context only the FIRST time we see this exact
    // arguments object. Re-entering the camera tab (tab switch) keeps the same
    // mainscreen arguments, so without this guard a stale check-in would
    // re-select "Submit for Points" every time — even on a plain camera open.
    final bool isFreshArgs = !identical(args, _consumedArgs);
    _consumedArgs = args;

    if (args is Map &&
        args['place'] is ExplorePlaceModel &&
        (isFreshArgs || checkIn)) {
      targetPlace.value = args['place'] as ExplorePlaceModel;
      targetCategoryKey.value = args['categoryKey']?.toString();
      final p = targetPlace.value!;
      log("📍 Place context set: ${p.name} (${p.placeId}), key=${targetCategoryKey.value}");
    } else if (isFreshArgs && args is Map && args['categoryKey'] != null) {
      targetCategoryKey.value = args['categoryKey']?.toString();
      targetPlace.value = null;
      log("🔑 Category context set: ${targetCategoryKey.value}");
    } else if (!checkIn) {
      // No context, or the same already-consumed arguments → clear so a plain
      // camera capture isn't mistaken for a place check-in. (Never clear during
      // a check-in push session.)
      targetPlace.value = null;
      targetCategoryKey.value = null;
      log("ℹ️ Camera opened without fresh Place/Category context — cleared.");
    }
  }

  @override
  void onReady() {
    if (cameraController == null ||
        !(cameraController?.value.isInitialized ?? false)) {
      initCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isRequestingPermission) return;

    if (state == AppLifecycleState.resumed) {
      if (_isCameraPageVisible &&
          (cameraController == null ||
              !(cameraController?.value.isInitialized ?? false))) {
        initCamera();
      }
      return;
    }

    if (state == AppLifecycleState.detached) {
      safeRelease();
      return;
    }

    if (!_isCameraPageVisible) {
      safeRelease();
    }
  }

  // 3. 🎯 Tap to Focus & Exposure
  Future<void> onTapToFocus(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    if (cameraController == null || !isCameraReady.value) return;

    // Convert tap position to camera coordinates (0.0 to 1.0)
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    try {
      // Set Focus and Exposure point
      await cameraController!.setFocusPoint(offset);
      await cameraController!.setExposurePoint(offset);

      // Update UI for Focus Circle
      focusPoint.value = details.localPosition;
      showFocusCircle.value = true;

      // Auto hide focus circle after 1.5 seconds
      _focusResetTimer?.cancel();
      _focusResetTimer = Timer(const Duration(milliseconds: 1500), () {
        showFocusCircle.value = false;
      });
    } catch (e) {
      log("Error setting focus: $e");
    }
  }

  // 2. 🔆 Exposure / Brightness
  Future<void> setExposure(double value) async {
    if (cameraController == null) return;
    try {
      await cameraController!.setExposureOffset(value);
      currentExposureOffset.value = value;
    } catch (e) {
      log("Error setting exposure: $e");
    }
  }

  void toggleToolsMenu() {
    isToolsExpanded.value = !isToolsExpanded.value;
  }

  void toggleExposureSlider() {
    showExposureSlider.value = !showExposureSlider.value;
  }

  void setPageVisibility(bool visible) {
    final bool ready = cameraController?.value.isInitialized ?? false;

    // Ignore duplicate fires — VisibilityDetector emits repeatedly during tab
    // transitions and the threshold can oscillate, causing init/release thrash
    // (rapid dispose+initialize churn that wedges the camera hardware).
    if (_isCameraPageVisible == visible) {
      // EXCEPTION: when we should be visible but the camera isn't alive, init
      // anyway. Navigating in via Get.offAllNamed(tab:2) can destroy the old
      // camera screen without ever firing visible=false, leaving this flag stale
      // (true). The fresh screen's visible=true event would then be deduped here
      // and the camera would never open. This recovers that case.
      if (visible && !ready && !_isInitRunning) {
        _initRetryCount = 0;
        initCamera();
      }
      return;
    }
    _isCameraPageVisible = visible;
    if (visible) {
      _initRetryCount = 0; // fresh retry budget each time we enter the page
      if (!ready) {
        initCamera();
      }
    } else {
      if (cameraController != null || _isInitRunning) {
        safeRelease();
      }
    }
  }
  // Future<void> initCamera() async {
  //   if (_isInitRunning) return;
  //   _isInitRunning = true;
  //   final status = await Permission.camera.request();
  //   if (!status.isGranted) {
  //     _isInitRunning = false;
  //     return;
  //   }

  //   try {
  //     cameras = await availableCameras();
  //     if (cameras.isEmpty) {
  //       _isInitRunning = false;
  //       return;
  //     }

  //     await cameraController?.dispose();
  //     cameraController = CameraController(
  //       cameras[selectedCameraIdx],
  //       ResolutionPreset.high,
  //       enableAudio: true,
  //     );
  //     await cameraController!.initialize();
  //     isCameraReady.value = true;
  //     update();
  //   } catch (e, st) {
  //     log("Camera init error", error: e, stackTrace: st);
  //     isCameraReady.value = false;
  //     update();
  //   } finally {
  //     _isInitRunning = false; // ✅ guard reset
  //   }
  // }
  Future<void> initCamera() async {
    // Coalesce concurrent calls — remember the request, honor it on completion.
    if (_isInitRunning) {
      _pendingInit = true;
      return;
    }
    _isInitRunning = true;
    // Fresh init clears any stale teardown flag from a previous lifecycle.
    _disposed = false;

    // True only when an actual initialize() attempt failed (vs. a precondition
    // bail like "not foregrounded yet"). Only real failures trigger retries.
    bool attemptFailed = false;

    try {
      // Only hit the (slow, OS-pausing) permission *request* when not already
      // granted. On every later tab return a status check is instant — this is
      // the main reason re-entering the camera tab used to take ~1s.
      var camStatus = await Permission.camera.status;
      if (!camStatus.isGranted) {
        _isRequestingPermission = true;
        camStatus = await Permission.camera.request();
        await Permission.microphone.request();
        _isRequestingPermission = false;
      }

      if (!camStatus.isGranted) {
        isCameraReady.value = false;
        update();
        return; // no permission — lifecycle/visibility will retry, don't spam
      }

      // Camera hardware can only bind while foregrounded. Wait briefly (e.g.
      // for a permission dialog to dismiss), but never busy-loop forever — bail
      // and let the lifecycle/visibility observers re-trigger us on resume.
      int waited = 0;
      while (WidgetsBinding.instance.lifecycleState !=
              AppLifecycleState.resumed &&
          waited < 2000) {
        await Future.delayed(const Duration(milliseconds: 50));
        waited += 50;
        if (_disposed) return;
      }
      if (WidgetsBinding.instance.lifecycleState !=
          AppLifecycleState.resumed) {
        return;
      }

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        isCameraReady.value = false;
        update();
        return;
      }

      if (cameraController != null) {
        try {
          await cameraController!.dispose();
        } catch (_) {}
        cameraController = null;
      }

      // Bail if the controller was torn down during the awaits above.
      if (_disposed) return;

      final controller = CameraController(
        cameras[selectedCameraIdx],
        ResolutionPreset.veryHigh,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      cameraController = controller;

      // initialize() can hang indefinitely when the previous controller hasn't
      // released the hardware yet (rapid tab switches). Time-box it so the
      // _isInitRunning guard never sticks true — that was the "loader stuck
      // forever, camera never initializes" failure.
      await controller.initialize().timeout(const Duration(seconds: 6));

      // Teardown happened while initialize() was running — dispose the
      // controller we just created and stop (don't touch Rx state below).
      if (_disposed) {
        try {
          await controller.dispose();
        } catch (_) {}
        cameraController = null;
        return;
      }

      // Pre-warm video recording pipeline (fast start on iOS)
      try {
        await controller.prepareForVideoRecording();
      } catch (_) {}

      // Disable flash completely on init to prevent screen flash on iOS
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      // ✨ RESTORE ZOOM & FLASH STATE
      minZoom.value = await controller.getMinZoomLevel();
      maxZoom.value = _cappedMaxZoom(await controller.getMaxZoomLevel());
      currentZoom.value = minZoom.value;
      // Reset the coalescing-zoom state for this fresh controller so a worker
      // orphaned by the previous lifecycle can't apply a stale target/wedge.
      _targetZoom = minZoom.value;
      _appliedZoom = minZoom.value;
      _baseScale = 1.0;
      _baseZoomForDrag = minZoom.value;
      _isApplyingZoom = false;
      await controller.setZoomLevel(minZoom.value);

      // Query actual exposure range and sync slider
      try {
        minExposure.value = await controller.getMinExposureOffset();
        maxExposure.value = await controller.getMaxExposureOffset();
        // Reset to 0 (neutral) on fresh init
        currentExposureOffset.value = 0.0;
        await controller.setExposureOffset(0.0);
      } catch (_) {}

      // Restore Flash logic
      if (currentFlashMode.value != FlashMode.off) {
        try {
          await controller.setFlashMode(currentFlashMode.value);
        } catch (e) {
          // Fallback if mode not supported (e.g. front camera)
          currentFlashMode.value = FlashMode.off;
        }
      } else {
        await controller.setFlashMode(FlashMode.off);
      }

      isCameraReady.value = true;
      update();
    } catch (e, st) {
      log("Camera init error", error: e, stackTrace: st);
      try {
        await cameraController?.dispose();
      } catch (_) {}
      cameraController = null;
      isCameraReady.value = false;
      attemptFailed = true;
      update();
    } finally {
      _isInitRunning = false;
      _isRequestingPermission = false;

      // IMPORTANT: this runs even on the early `return`s above (a finally always
      // executes). Those early returns previously skipped the retry logic, which
      // is what wedged the camera on rapid tab switches — the loader stuck
      // forever because nothing re-triggered init.
      final bool pending = _pendingInit;
      _pendingInit = false;

      // A release that raced this init set _disposed while we were on the camera
      // page — that teardown is stale now (page is still visible), so re-init.
      final bool staleTeardown = _disposed && _isCameraPageVisible;

      if (isCameraReady.value) {
        _initRetryCount = 0;
      } else if (_isCameraPageVisible &&
          (pending || staleTeardown || attemptFailed)) {
        _disposed = false; // page is visible → any teardown flag is stale
        if (!pending && !staleTeardown && attemptFailed) {
          _initRetryCount++;
        }
        final bool withinBudget =
            pending || staleTeardown || _initRetryCount <= _maxRetries;
        if (withinBudget) {
          // Re-run on a later turn so this call fully unwinds first.
          Future.delayed(
            (pending || staleTeardown)
                ? Duration.zero
                : const Duration(milliseconds: 400),
            () {
              final ready = cameraController?.value.isInitialized ?? false;
              if (_isCameraPageVisible && !ready && !_isInitRunning) {
                initCamera();
              }
            },
          );
        }
      }
    }
  }

  Future<void> switchCamera() async {
    if (cameras.isEmpty) return;
    isCameraReady.value = false;

    // Toggle between front and back only (skip extra lenses like ultra-wide)
    final currentDir = cameras[selectedCameraIdx].lensDirection;
    final targetDir =
        currentDir == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;
    final targetIdx = cameras.indexWhere((c) => c.lensDirection == targetDir);
    if (targetIdx != -1) {
      selectedCameraIdx = targetIdx;
    } else {
      selectedCameraIdx = (selectedCameraIdx + 1) % cameras.length;
    }

    await cameraController?.dispose();
    cameraController = CameraController(
      cameras[selectedCameraIdx],
      ResolutionPreset.veryHigh,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await cameraController!.initialize();

    // Pre-warm video recording pipeline
    try {
      await cameraController!.prepareForVideoRecording();
    } catch (_) {}

    // Reset zoom to minimum
    minZoom.value = await cameraController!.getMinZoomLevel();
    maxZoom.value = _cappedMaxZoom(await cameraController!.getMaxZoomLevel());
    currentZoom.value = minZoom.value;
    _baseScale = 1.0;
    // Reset coalescing-zoom state for the new camera (its min/max differ); any
    // in-flight worker captured the old controller and bails on identity.
    _targetZoom = minZoom.value;
    _appliedZoom = minZoom.value;
    _baseZoomForDrag = minZoom.value;
    _isApplyingZoom = false;
    await cameraController!.setZoomLevel(minZoom.value);

    // Sync exposure range for new camera
    try {
      minExposure.value = await cameraController!.getMinExposureOffset();
      maxExposure.value = await cameraController!.getMaxExposureOffset();
      currentExposureOffset.value = 0.0;
      await cameraController!.setExposureOffset(0.0);
    } catch (_) {}

    // Reset flash on switch for safety
    currentFlashMode.value = FlashMode.off;
    await cameraController!.setFlashMode(FlashMode.off);

    cameraGeneration.value++;
    isCameraReady.value = true;
    update();
  }

  // --------------------------------------------------------
  // ✨ FEATURE METHODS (Sound, Zoom, Flash, Timer)
  // --------------------------------------------------------

  // 🔊 Sound
  void playShutterSound() {
    SystemSound.play(SystemSoundType.click);
  }

  // 🔍 Zoom
  void onScaleStart(ScaleStartDetails details) {
    _baseScale = currentZoom.value;
  }

  // Pinch-to-zoom (preview). Synchronous + fire-and-forget safe: it only
  // records the target and kicks the serialized worker — never awaits the
  // hardware here (that flooding was the source of the glitch).
  void onScaleUpdate(ScaleUpdateDetails details) {
    if (cameraController == null || !isCameraReady.value) return;
    _requestZoom(_baseScale * details.scale);
  }

  double _baseZoomForDrag = 1.0;

  // Drag-to-zoom while holding the record button. Same path as pinch — store
  // the target, let the worker push it to the hardware.
  void onZoomDrag(double dragDistance) {
    if (cameraController == null || !isCameraReady.value) return;

    // Define how many pixels of upward drag equals reaching the max zoom.
    // Higher = LESS sensitive (more finger travel per zoom step).
    const double maxDragSensitivity = 500.0;

    final double zoomDelta =
        (dragDistance / maxDragSensitivity) * (maxZoom.value - minZoom.value);
    _requestZoom(_baseZoomForDrag + zoomDelta);
  }

  // Record the latest requested zoom and move the on-screen indicator
  // synchronously (so the "x" tracks the finger smoothly), then make sure a
  // single worker is draining that target to the camera hardware. Never throws
  // — gesture handlers call this fire-and-forget.
  void _requestZoom(double scale) {
    final double lo = minZoom.value, hi = maxZoom.value;
    final double clamped = _clampZoom(scale);

    // Always let an exact rail (min/max) through so you can fully snap to 1x or
    // max; otherwise drop sub-step jitter — each redundant setZoomLevel forces a
    // full Camera2 crop-region / capture-session refresh.
    final bool atRail =
        clamped <= lo + _zoomEpsilon || clamped >= hi - _zoomEpsilon;
    if (!atRail && (clamped - _targetZoom).abs() < _zoomMinStep) return;
    if ((clamped - _targetZoom).abs() < _zoomEpsilon &&
        (clamped - currentZoom.value).abs() < _zoomEpsilon) {
      return;
    }

    _targetZoom = clamped;
    currentZoom.value = clamped; // drives the "x" indicator Obx at gesture rate
    _pumpZoom();
  }

  // Single-flight serialized worker. Only one runs at a time (_isApplyingZoom);
  // it keeps pushing the freshest _targetZoom to the hardware, ONE awaited
  // setZoomLevel at a time, until the hardware matches the target. This is what
  // replaces the concurrent setZoomLevel flood that stuttered recording.
  void _pumpZoom() async {
    if (_isApplyingZoom) return; // a worker is already draining
    _isApplyingZoom = true; // set BEFORE the first await (no parallel loop)
    final CameraController? owner = cameraController; // identity captured

    try {
      while (true) {
        // Re-validate every iteration: the controller can be disposed/swapped
        // (switchCamera) or nulled (safeRelease) while we were awaiting. A
        // nulled controller would throw a synchronous TypeError from `!`, so we
        // null-check + identity-check here instead of using `cameraController!`.
        final CameraController? ctrl = cameraController;
        if (ctrl == null ||
            !identical(ctrl, owner) ||
            _disposed ||
            !isCameraReady.value ||
            !ctrl.value.isInitialized) {
          break;
        }

        // Clamp the latest target to the LIVE range and compare the CLAMPED
        // value to what's applied — so a target sitting past a rail still counts
        // as "reached" and the loop converges instead of busy-spinning.
        final double apply = _clampZoom(_targetZoom);
        if ((apply - _appliedZoom).abs() < _zoomEpsilon) break; // converged

        try {
          await ctrl.setZoomLevel(apply);
        } catch (e) {
          log("⚠️ setZoomLevel failed: $e");
          break; // next gesture restarts the pump
        }
        // The controller may have been swapped/disposed while we awaited
        // (switchCamera/safeRelease). If so we're orphaned — don't commit
        // _appliedZoom (it now belongs to the live controller's worker) and stop.
        if (!identical(cameraController, owner)) break;
        _appliedZoom = apply;

        // A newer target may have arrived during the await — re-clamp and, if it
        // still differs, throttle one frame then coalesce on the next pass.
        if ((_clampZoom(_targetZoom) - _appliedZoom).abs() < _zoomEpsilon) break;
        await Future.delayed(const Duration(milliseconds: 16));
      }
    } finally {
      // Only the worker that still owns the LIVE controller may manage the
      // shared guard / re-kick. If the controller was swapped or cleared under
      // us (switchCamera / safeRelease both reset _isApplyingZoom themselves),
      // we're orphaned and a newer worker may already own the flag — touching it
      // here could clobber the live worker into a second concurrent pump.
      if (identical(cameraController, owner)) {
        _isApplyingZoom = false;
        // Lost-wakeup guard: a gesture may have updated _targetZoom in the
        // window between our last read and clearing the flag — restart so the
        // final value is never dropped (zoom would otherwise "stick" behind).
        if (!_disposed &&
            isCameraReady.value &&
            (_clampZoom(_targetZoom) - _appliedZoom).abs() >= _zoomEpsilon) {
          _pumpZoom();
        }
      }
    }
  }

  double _clampZoom(double v) {
    final double lo = minZoom.value, hi = maxZoom.value;
    return v < lo ? lo : (v > hi ? hi : v);
  }

  // ⚡ Flash Toggle Logic
  Future<void> toggleFlashMode() async {
    if (cameraController == null || !isCameraReady.value) return;

    FlashMode nextMode;

    if (currentFlashMode.value == FlashMode.off) {
      nextMode = FlashMode.always;
    } else if (currentFlashMode.value == FlashMode.always) {
      nextMode = FlashMode.auto;
    } else {
      nextMode = FlashMode.off;
    }

    try {
      await cameraController!.setFlashMode(nextMode);
      currentFlashMode.value = nextMode;
    } catch (e) {
      log("Error switching flash: $e");
    }
  }

  IconData getFlashIcon() {
    switch (currentFlashMode.value) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
      default:
        return Icons.flash_off;
    }
  }

  // ⏲️ Timer
  void toggleTimer() {
    if (selectedTimer.value == 0) {
      selectedTimer.value = 3;
    } else if (selectedTimer.value == 3) {
      selectedTimer.value = 10;
    } else {
      selectedTimer.value = 0;
    }
  }

  Future<File> flipImage(String path) async {
    final original = File(path);
    final bytes = await original.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return original;
    final flipped = img.flipHorizontal(decoded);
    final newPath = path.replaceFirst('.jpg', '_flipped.jpg');
    return File(newPath)
      ..writeAsBytesSync(img.encodeJpg(flipped, quality: 100));
  }

  final RxnString lastCapturedPath = RxnString();

  // 📸 Capture Image (Guarded & Auto-Recovered)
  Future<void> captureImage() async {
    final ctrl = cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (_isHardwareBusy || ctrl.value.isRecordingVideo) {
      log("⚠️ Camera busy. Ignoring capture.");
      return;
    }

    if (selectedTimer.value > 0) {
      isCountingDown.value = true;
      countdownValue.value = selectedTimer.value;
      while (countdownValue.value > 0) {
        await Future.delayed(const Duration(seconds: 1));
        countdownValue.value--;
      }
      isCountingDown.value = false;
    }

    try {
      playShutterSound();

      // Lock focus/exposure before capture for faster shot
      try {
        await ctrl.setFocusMode(FocusMode.locked);
        await ctrl.setExposureMode(ExposureMode.locked);
      } catch (_) {}

      final XFile capturedFile = await ctrl.takePicture();

      // Unlock focus/exposure for next shot
      try {
        await ctrl.setFocusMode(FocusMode.auto);
        await ctrl.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      lastCapturedPath.value = capturedFile.path;

      final bool isFront =
          cameras[selectedCameraIdx].lensDirection == CameraLensDirection.front;

      // Instant transition — no slide animation, like Snapchat/Instagram
      await Get.to(
        () => CapturePreviewScreen(
          filePath: capturedFile.path,
          isVideo: false,
          profileImage: avatarurl.value,
          placeData: targetPlace.value,
          categoryKey: targetCategoryKey.value,
          isFrontCamera: isFront,
          snapChatId: snapChatId.value,
          snapRecipientName: snapRecipientName.value,
        ),
        transition: Transition.noTransition,
      );
    } catch (e, st) {
      log("Capture failed", error: e, stackTrace: st);
    }
  }

  // 🎥 Start Video
  Future<void> startVideoRecording() async {
    final ctrl = cameraController;
    if (ctrl == null || !ctrl.value.isInitialized || _isHardwareBusy) return;

    _wantsToRecord = true;
    _isHardwareBusy = true;
    _baseZoomForDrag = currentZoom.value;

    try {
      // Show UI feedback IMMEDIATELY so user sees the recording started
      isCapturing.value = true;
      rotationController.duration = Duration(seconds: maxRecordDuration);
      rotationController.forward(from: 0);
      update();
      playShutterSound();

      // Yield to the event loop so the UI updates and animations start smoothly
      // before the heavy platform channel calls block the main thread.
      await Future.delayed(const Duration(milliseconds: 50));

      if (!_wantsToRecord) {
        _isHardwareBusy = false;
        _resetUI();
        log("📸 Falling back to image capture due to early micro-tap (before hardware start)...");
        await captureImage();
        return;
      }

      // Lock focus/exposure for faster recording start (no AF hunting)
      try {
        await ctrl.setFocusMode(FocusMode.locked);
        await ctrl.setExposureMode(ExposureMode.locked);
      } catch (_) {}

      await ctrl.startVideoRecording();
      _recordingStartTime = DateTime.now();
      _isHardwareBusy = false;

      if (!_wantsToRecord) {
        bool shouldFallback = await _executeSafeStop(discard: true);
        if (shouldFallback) {
          log("📸 Falling back to image capture due to early micro-tap...");
          await captureImage();
        }
      } else {
        _recordTimer?.cancel();
        _recordTimer = Timer(
          Duration(seconds: maxRecordDuration),
          () => stopVideoRecording(),
        );
      }
    } catch (e) {
      _isHardwareBusy = false;
      _resetUI();
      log("Recording start error: $e");
    }
  }

  // 🛑 Stop Video Request (INSTANT UI STOP)
  Future<void> stopVideoRecording() async {
    _wantsToRecord = false;
    _resetUI();

    if (_isHardwareBusy) return;

    _isHardwareBusy = true;
    bool shouldFallback = false;
    try {
      final elapsed =
          _recordingStartTime != null
              ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
              : 0;

      bool shouldDiscard = elapsed < 1000;
      shouldFallback = await _executeSafeStop(discard: shouldDiscard);
    } catch (e) {
      log("Stop error: $e");
    } finally {
      _isHardwareBusy = false;
    }

    if (shouldFallback) {
      log("📸 Falling back to image capture due to micro-tap...");
      await captureImage();
    }
  }

  // 🔒 Safe Hardware Stop (NO RESTART, JUST WAIT IN BACKGROUND)
  Future<bool> _executeSafeStop({required bool discard}) async {
    final ctrl = cameraController;
    if (ctrl == null || !ctrl.value.isRecordingVideo) return false;

    try {
      if (_recordingStartTime != null) {
        final elapsed =
            DateTime.now().difference(_recordingStartTime!).inMilliseconds;
        if (elapsed < 1000) {
          await Future.delayed(Duration(milliseconds: 1000 - elapsed));
        }
      }

      final XFile videoFile = await ctrl.stopVideoRecording();

      // Unlock focus/exposure for next shot
      try {
        await ctrl.setFocusMode(FocusMode.auto);
        await ctrl.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      if (discard) {
        log("⚠️ Micro-tap detected: Video discarded silently.");
        _deleteFileSilent(videoFile.path);
        return true;
      } else {
        if (videoFile.path.isEmpty || videoFile.path == '/') return false;

        Get.to(
          () => CapturePreviewScreen(
            filePath: videoFile.path,
            isVideo: true,
            profileImage: avatarurl.value,
            placeData: targetPlace.value,
            categoryKey: targetCategoryKey.value,
            snapChatId: snapChatId.value,
            snapRecipientName: snapRecipientName.value,
          ),
          transition: Transition.noTransition,
        );
        return false;
      }
    } catch (e) {
      log("Safe stop error: $e");
      return false;
    }
  }

  void _resetUI() {
    isCapturing.value = false;
    rotationController
      ..reset()
      ..stop();
    update();
  }

  void _deleteFileSilent(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  // ... (Safe Release & Backend methods remain exactly as they were)
  Future<void> safeRelease() async {
    if (_isRequestingPermission) return;
    // An init is in flight: disposing now would crash initialize() mid-run.
    // Mark teardown so initCamera disposes its own controller and bails.
    if (_isInitRunning) {
      _disposed = true;
      return;
    }
    try {
      _recordTimer?.cancel();
      if (rotationController.isAnimating) {
        rotationController
          ..stop()
          ..reset();
      }
      final ctrl = cameraController;
      if (ctrl != null) {
        if (ctrl.value.isInitialized && ctrl.value.isRecordingVideo) {
          await ctrl.stopVideoRecording();
        }
        await ctrl.dispose();
      }
    } catch (_) {
    } finally {
      cameraController = null;
      isCameraReady.value = false;
      isCapturing.value = false;
      // Release the zoom-worker guard: any in-flight pump is now orphaned (its
      // owner controller is gone) and won't clear the flag itself.
      _isApplyingZoom = false;
      update();
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> getPlaceName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return "";

      final p = placemarks.first;

      // smart composition with fallbacks
      final parts = <String>[
        if ((p.name ?? "").trim().isNotEmpty) p.name!.trim(),
        if ((p.subLocality ?? "").trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? "").trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? "").trim().isNotEmpty)
          p.administrativeArea!.trim(),
        if ((p.country ?? "").trim().isNotEmpty) p.country!.trim(),
      ];

      return parts.where((e) => e.isNotEmpty).toList().join(", ");
    } catch (e) {
      // reverse geocoding fail -> just return empty; server can accept empty or you can show a toast
      return "";
    }
  }

  var totalPoints = 0.obs;
  Future<void> submitFileForPoints({
    required String filePath,
    bool showLoading = true,
    VoidCallback? onSuccessNavigation,
  }) async {
    try {
      final file = File(filePath);

      final position = await getCurrentPosition();
      final latitude = position.latitude.toString();
      final longitude = position.longitude.toString();
      final placeName = await getPlaceName(
        position.latitude,
        position.longitude,
      );

      final response = await ApiService.submitForPoints(
        file: file,
        placeName: placeName.isNotEmpty ? placeName : "Unknown location",
        latitude: latitude,
        longitude: longitude,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool awarded = data['awarded'] ?? true;

        if (awarded) {
          log("✅ Submit for points success: ${response.body}");
          log("✅ place name: ${placeName}");
          totalPoints.value = data['points'] ?? 0;
          log("💰 Points received: $totalPoints");
          onSuccessNavigation?.call();
        } else {
          final String reason = data['reason'] ?? '';
          final String retryIn = data['retryIn'] ?? '';
          log("❌ Not awarded. Reason: $reason");

          String title;
          String message;
          IconData icon;

          switch (reason) {
            case 'duplicate-place-within-window':
              title = "Already Visited";
              message =
                  data['message'] ??
                  "You've already earned points at this spot.${retryIn.isNotEmpty ? ' Visit again in $retryIn!' : ''}";
              icon = Icons.info_outline;
              break;
            case 'duplicate-nearby-within-window':
              title = "Nearby Spot Already Visited";
              message =
                  data['message'] ??
                  "You've already earned points near this location.${retryIn.isNotEmpty ? ' Try a new spot or come back in $retryIn!' : ''}";
              icon = Icons.location_on_outlined;
              break;
            default:
              title = "Points Not Awarded";
              message =
                  data['message'] ??
                  "Could not award points right now. Please try again later.";
              icon = Icons.info_outline;
          }

          PointSubmitDialog.showFailed(
            title: title,
            message: message,
            icon: icon,
            iconColor: Colors.orangeAccent,
          );
        }
      } else {
        log("❌ Submit failed: ${response.statusCode} — ${response.body}");
        if (showLoading) {
          AppSnackbar.error("Submit failed (${response.statusCode})");
        }
      }
    } catch (e) {
      log("❌ Submit error: $e");
      if (showLoading) {
        AppSnackbar.error("Something went wrong");
      }
    }
  }

  Future<void> uploadCapturedFile({
    required String filePath,
    required bool isVideo,
    List<int>? chatIds,
    String? challengeId,
    bool postToStory = false,
    bool showLoading = true,
    VoidCallback? onSuccessNavigation,
  }) async {
    try {
      if (showLoading) {
        // EasyLoading.show(status: "Sending...");
        AppLoading.show();
      }

      final file = File(filePath);
      final position = await getCurrentPosition();
      final latitude = position.latitude.toString();
      final longitude = position.longitude.toString();

      final response = await ApiService.sendCapture(
        file: file,
        type: isVideo ? "VIDEO" : "IMAGE",
        chatIds: chatIds,
        challengeId: challengeId,
        postToStory: postToStory,
        latitude: latitude,
        longitude: longitude,
      );

      if (showLoading) AppLoading.hide();

      // EasyLoading.dismiss();

      if (response.statusCode == 200) {
        log("📦 Sending media to chatIds => ${chatIds}");
        log("✅ Upload success: ${response.body}");

        if (onSuccessNavigation != null) {
          onSuccessNavigation();
        }
      } else {
        log("❌ Upload failed: ${response.statusCode} — ${response.body}");
        if (showLoading) {
          AppSnackbar.error("Upload failed (${response.statusCode})");
        }
      }
    } catch (e) {
      if (showLoading) AppLoading.hide();

      // EasyLoading.dismiss();

      log("❌ Upload error: $e");
      if (showLoading) {
        AppSnackbar.error("Something went wrong");
      }
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];
        minimeList.value = data["minime"] ?? '';
        avatarurl.value = minimeList.last['avatarUrl'] ?? '';
        log("${avatarurl.value}");
      } else {
        log("❌ Server error: ${response.statusCode}");
        AppSnackbar.error("Server returned ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
    }
  }

  // NOTIFICATION
  final _badgeService = Get.find<NotificationBadgeService>();
  RxBool get notificationRedDot => _badgeService.notificationRedDot;
  Future<void> getRedDot() => _badgeService.getRedDot();
  Future<void> clearNotificationDot() => _badgeService.clearNotificationDot();

  @override
  void onClose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    rotationController.dispose();
    safeRelease();
    super.onClose();
  }

  @override
  void dispose() {
    _disposed = true;
    safeRelease();
    super.dispose();
  }
}
