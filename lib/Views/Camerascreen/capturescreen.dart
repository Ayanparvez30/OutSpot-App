import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show HapticFeedback;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/video_error_log.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import 'package:outspot/Model/explore_place_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Views/Message/camera_controller.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';
import 'package:outspot/Views/Camerascreen/camerascreen_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import 'editors/edit_state.dart';
import 'editors/text_editor.dart';
import 'editors/draw_editor.dart';
import 'editors/emoji_editor.dart';
import 'editors/crop_editor.dart';
import 'editors/tune_editor.dart';
import 'editors/filter_editor.dart';
import 'editors/pixelate_editor.dart';
import 'editors/blur_editor.dart';
import 'package:video_editor/video_editor.dart';
import 'package:easy_video_editor/easy_video_editor.dart' as eve;
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path_provider/path_provider.dart';

class CapturePreviewScreen extends StatefulWidget {
  final String filePath;
  final String profileImage;
  final bool isVideo;
  final ExplorePlaceModel? placeData;
  final String? categoryKey;
  final bool isFrontCamera;

  // Snap-to-friend: when snapChatId > 0 show a "Send to {name}" button that
  // sends the captured/edited media straight into that direct-message chat.
  final int snapChatId;
  final String? snapRecipientName;

  const CapturePreviewScreen({
    super.key,
    required this.filePath,
    required this.profileImage,
    this.isVideo = false,
    this.placeData,
    this.categoryKey,
    this.isFrontCamera = false,
    this.snapChatId = 0,
    this.snapRecipientName,
  });

  @override
  State<CapturePreviewScreen> createState() => _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends State<CapturePreviewScreen> {
  late final CamerascreenController controller;

  /// A usable recipient name, or empty when we don't have a real one (groups /
  /// communities may not pass a name, in which case the old code showed the
  /// awkward "Send to User"). Empty → the UI shows a plain "Send"/"Sent".
  String get _snapName {
    final n = widget.snapRecipientName?.trim() ?? '';
    return (n.isEmpty || n == 'User') ? '' : n;
  }

  VideoPlayerController? _videoController;
  VideoEditorController? _veditorController;
  VideoPlayerController? _editedVideoController; // plays the exported result
  String? _editedVideoPath; // path to last exported video
  bool _isVideoPlaying = true;

  // media_kit player for the DEFAULT preview playback. video_editor's
  // video_player preview auto-pauses at the trim end (~1s) and won't play HDR
  // on iPhone 14; media_kit (libmpv, same engine that works for stories) plays
  // it reliably and loops. video_editor (_veditorController) is still used for
  // trim/crop/export.
  mk.Player? _mkPlayer;
  mkv.VideoController? _mkController;
  bool _mkReady = false;
  bool _mkPlaying = true;

  // Path of the media currently loaded in the media_kit preview player. Lets us
  // detect when the visible player is showing an already-trimmed clip vs the
  // original (so trim — which is relative to the original — reopens the original).
  String? _mkLoadedPath;

  // Live trim preview: a listener on the trim controller + a position-stream
  // subscription that keep the VISIBLE media_kit player clamped to the current
  // [startTrim, endTrim] selection while the Trim panel is open.
  VoidCallback? _trimPreviewListener;
  StreamSubscription<Duration>? _trimPositionSub;

  // Serializes async video-edit applies: each call claims a token, only the
  // latest may mutate the preview/_editedVideoPath. Kills the "second Done
  // applies the previous trim" race. _isApplyingVideoEdit also makes the
  // send/save path bypass the stale _editedVideoPath cache.
  int _videoApplyToken = 0;
  bool _isApplyingVideoEdit = false;

  final isUploadingStory = false.obs;
  final _isSendingSnap = false.obs; // snap-to-friend send (not the Story flow)

  // Edit state
  final EditState _editState = EditState();
  ActiveEditor _activeEditor = ActiveEditor.none;
  String? _croppedImagePath;
  String? _preRegionImagePath; // snapshot before blur/pixelate edits
  // True only after a CROP (which changes the aspect ratio → BoxFit.contain).
  // Pixelate/blur also write _croppedImagePath but keep the original aspect,
  // so the preview must stay BoxFit.cover for them — hence a dedicated flag
  // instead of keying the fit off `_croppedImagePath == null`.
  bool _isCropped = false;
  final List<String> _tempFiles = []; // Track temp files for cleanup

  // Drawing state
  List<Offset> _currentDrawPoints = [];
  final GlobalKey _drawEditorKey = GlobalKey();

  // Region selection state (for pixelate/blur)
  Offset? _regionStart;
  Offset? _regionEnd;
  bool _isProcessingRegion = false;

  // Text editing state
  int? _editingTextIndex;

  // Quick exposure slider on capture screen
  // bool _showExposureSlider = false;
  bool _showDeleteZone = false;

  // Composite export key (captures full canvas with overlays)
  final GlobalKey _compositeKey = GlobalKey();
  // Base image key (captures only image + filters/tune, no overlays)
  final GlobalKey _baseImageKey = GlobalKey();

  TextStyle _getTextLayerFont(
    String fontName, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    switch (fontName) {
      case 'Poppins':
        return GoogleFonts.poppins(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Montserrat':
        return GoogleFonts.montserrat(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Raleway':
        return GoogleFonts.raleway(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Oswald':
        return GoogleFonts.oswald(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Comfortaa':
        return GoogleFonts.comfortaa(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Righteous':
        return GoogleFonts.righteous(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Nunito':
        return GoogleFonts.nunito(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Quicksand':
        return GoogleFonts.quicksand(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Fredoka':
        return GoogleFonts.fredoka(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Baloo 2':
        return GoogleFonts.baloo2(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Archivo Black':
        return GoogleFonts.archivoBlack(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Rubik':
        return GoogleFonts.rubik(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Abril Fatface':
        return GoogleFonts.abrilFatface(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Lora':
        return GoogleFonts.lora(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Merriweather':
        return GoogleFonts.merriweather(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Cinzel':
        return GoogleFonts.cinzel(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Cormorant Garamond':
        return GoogleFonts.cormorantGaramond(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Lobster':
        return GoogleFonts.lobster(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Pacifico':
        return GoogleFonts.pacifico(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Dancing Script':
        return GoogleFonts.dancingScript(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Caveat':
        return GoogleFonts.caveat(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Satisfy':
        return GoogleFonts.satisfy(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Great Vibes':
        return GoogleFonts.greatVibes(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Sacramento':
        return GoogleFonts.sacramento(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Kaushan Script':
        return GoogleFonts.kaushanScript(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Shadows Into Light':
        return GoogleFonts.shadowsIntoLight(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Indie Flower':
        return GoogleFonts.indieFlower(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Amatic SC':
        return GoogleFonts.amaticSc(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Cookie':
        return GoogleFonts.cookie(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Permanent Marker':
        return GoogleFonts.permanentMarker(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Press Start 2P':
        return GoogleFonts.pressStart2p(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Bungee':
        return GoogleFonts.bungee(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Bangers':
        return GoogleFonts.bangers(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Russo One':
        return GoogleFonts.russoOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Titan One':
        return GoogleFonts.titanOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Concert One':
        return GoogleFonts.concertOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Black Ops One':
        return GoogleFonts.blackOpsOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Orbitron':
        return GoogleFonts.orbitron(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Audiowide':
        return GoogleFonts.audiowide(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Leckerli One':
        return GoogleFonts.leckerliOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Courgette':
        return GoogleFonts.courgette(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Alfa Slab One':
        return GoogleFonts.alfaSlabOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Bree Serif':
        return GoogleFonts.breeSerif(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Acme':
        return GoogleFonts.acme(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      case 'Lilita One':
        return GoogleFonts.lilitaOne(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      default:
        return GoogleFonts.notoSans(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    controller =
        Get.isRegistered<CamerascreenController>()
            ? Get.find<CamerascreenController>()
            : Get.put(CamerascreenController());

    if (widget.isVideo) {
      _initVideo();
    }
  }

  VoidCallback? _videoListener;

  void _onVideoUpdate() {
    if (!mounted) return;
    final video = _veditorController?.video;
    if (video == null || !video.value.isInitialized) return;

    // NOTE: looping is handled natively by setLooping(true) below. The old
    // manual "if position >= duration → seekTo(0) + play" fought with it and,
    // when AVFoundation mis-reported the duration (iOS bug), fired almost
    // immediately → the preview appeared to "stick"/auto-pause after ~1s. We
    // now only sync the play/pause UI state here.
    if (_isVideoPlaying != video.value.isPlaying) {
      setState(() => _isVideoPlaying = video.value.isPlaying);
    }
  }

  StreamSubscription<String>? _mkErrorSub;

  /// media_kit player used for the default preview (plays/loops reliably,
  /// incl. HDR on iPhone 14, where video_player stalls).
  Future<void> _initMkPreview() async {
    try {
      final player = mk.Player();
      final controller = mkv.VideoController(player);
      // Surface any playback error remotely (helps debug the 2nd-preview
      // freeze on re-entry) + locally.
      _mkErrorSub = player.stream.error.listen((e) {
        logVideoError('camera_preview_mk_stream', e, url: widget.filePath);
      });
      await player.setPlaylistMode(mk.PlaylistMode.loop);
      await player.open(mk.Media(widget.filePath), play: true);
      await player.play();
      log('🎬 mk preview opened: ${widget.filePath}');
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _mkPlayer = player;
        _mkController = controller;
        _mkReady = true;
        _mkPlaying = true;
        _mkLoadedPath = widget.filePath;
      });
    } catch (e, st) {
      logVideoError('camera_preview_mk', e, url: widget.filePath, stack: st);
    }
  }

  /// Progress bar for the DEFAULT preview — driven by the media_kit player so
  /// the seek bar/timer and the video are always the SAME player (in sync).
  Widget _buildMkProgressBar() {
    final player = _mkPlayer!;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70.h,
      child: StreamBuilder<Duration>(
        stream: player.stream.position,
        builder: (context, snap) {
          final pos = snap.data ?? player.state.position;
          final dur = player.state.duration;
          final maxMs = dur.inMilliseconds <= 0 ? 1 : dur.inMilliseconds;
          final val = (pos.inMilliseconds / maxMs).clamp(0.0, 1.0);
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleMkPreview,
                  child: Icon(
                    _mkPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDuration(pos),
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.h,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 6.r,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 12.r,
                      ),
                      activeTrackColor: const Color(0xFFAB50F6),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: val,
                      onChanged: (v) {
                        player.seek(
                          Duration(milliseconds: (v * maxMs).round()),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDuration(dur),
                  style: GoogleFonts.notoSans(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(Icons.loop, color: Colors.white38, size: 14.sp),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleMkPreview() {
    final p = _mkPlayer;
    if (p == null) return;
    if (_mkPlaying) {
      p.pause();
    } else {
      p.play();
    }
    setState(() => _mkPlaying = !_mkPlaying);
  }

  void _initVideo() {
    _initMkPreview();
    _veditorController = VideoEditorController.file(
      File(widget.filePath),
      minDuration: const Duration(milliseconds: 500),
      maxDuration: const Duration(minutes: 10),
      // Compact circle handles + a TRANSPARENT gutter background so the side
      // "boxes" (previously painted black54 in the horizontalMargin space) blend
      // into the panel instead of showing as dark blocks.
      trimStyle: TrimSliderStyle(
        edgesType: TrimSliderEdgesType.circle,
        edgesSize: 8,
        background: Colors.transparent,
        lineColor: Colors.white.withValues(alpha: 0.6),
        onTrimmingColor: const Color(0xFFAB50F6),
        onTrimmedColor: const Color(0xFFAB50F6),
        // The package's position line is driven by vc.video, which we keep
        // PAUSED (media_kit is the visible player) — so it would sit frozen.
        // Hide it and draw our own smooth line from media_kit's position stream
        // (see the Trim panel overlay).
        positionLineColor: Colors.transparent,
        positionLineWidth: 0,
        borderRadius: 6.0,
        lineWidth: 2,
        iconColor: Colors.white,
        iconSize: 14,
      ),
    );
    _veditorController!
        .initialize(aspectRatio: 9 / 16)
        .then((_) async {
          if (!mounted) return;
          final video = _veditorController!.video;
          final videoDuration = video.value.duration;
          if (videoDuration > Duration.zero) {
            _veditorController!.updateTrim(0.0, 1.0);
          }
          await video.setLooping(true);
          await video.seekTo(Duration.zero);
          // Do NOT play the video_editor's player in the default preview —
          // media_kit drives playback there. Keep it paused + muted so it never
          // fights the media_kit player (the earlier per-frame pause vs its
          // auto-loop caused a setState storm → UI freeze) or double-plays
          // audio. video_editor plays it only when the user enters an edit mode.
          await video.setVolume(0);

          // Attach named listener so we can remove it on dispose
          _videoListener = _onVideoUpdate;
          video.addListener(_videoListener!);

          if (!mounted) return;
          setState(() {
            _isVideoPlaying = false;
            _videoController = video;
          });
        })
        .catchError((e) {
          debugPrint('VIDEO INIT ERROR: $e');
          // Report remotely so camera-preview failures on devices we can't test
          // (e.g. iPhone 14 HDR) show up in Crashlytics with device + codec.
          logVideoError('camera_preview_init', e, url: widget.filePath);
        });
  }

  /// While the Trim panel is open, make the VISIBLE media_kit player follow the
  /// current [startTrim, endTrim] selection live. We drive media_kit (the only
  /// visible/audible player) — never vc.video — so there's no double audio, no
  /// per-frame vc.video pausing, and no iOS stall.
  Future<void> _attachTrimPreview() async {
    final vc = _veditorController;
    final p = _mkPlayer;
    if (vc == null || p == null || _trimPreviewListener != null) return;

    // Trim is defined against the ORIGINAL clip; if a previous apply left a
    // trimmed clip loaded, reopen the original so the window lines up.
    if (_mkLoadedPath != widget.filePath) {
      await p.open(mk.Media(widget.filePath));
      _mkLoadedPath = widget.filePath;
    }
    if (_trimPreviewListener != null) return; // re-entrancy guard after await

    // Disable media_kit's whole-file loop while trimming. With loop on, when
    // playback reaches the file END it jumps to 0 (the strip start) — that's
    // why the playhead "started from suru". With `none`, playback never wraps to
    // 0 on its own; WE loop strictly within [startTrim, endTrim] below.
    await p.setPlaylistMode(mk.PlaylistMode.none);
    await p.seek(vc.startTrim);
    await p.play();
    if (mounted) setState(() => _mkPlaying = true);

    // Keep playback strictly inside [startTrim, endTrim] (event-driven via
    // media_kit's position stream — NOT a per-frame callback). The moving
    // playhead line is drawn from this same stream by the Trim panel overlay
    // (no vc.video seeking — that was glitchy). Looping a hair BEFORE endTrim
    // avoids hitting true EOF (which would pause/stall the player).
    _trimPositionSub = p.stream.position.listen((pos) async {
      // While the user is actively dragging a handle the controller listener
      // below positions the playhead — don't fight it here.
      if (vc.isTrimming) return;
      final start = vc.startTrim;
      final end = vc.endTrim;
      // 80ms guard so we wrap before EOF when endTrim == video end.
      if (pos < start || pos + const Duration(milliseconds: 80) >= end) {
        await p.seek(start);
        await p.play();
      }
    });

    // Each handle drag fires notifyListeners(). If the new window no longer
    // contains the playhead, snap it to the window start so playback (and the
    // line) jump into the current selection.
    _trimPreviewListener = () {
      final start = vc.startTrim;
      final end = vc.endTrim;
      final pos = p.state.position;
      if (pos < start || pos > end) {
        p.seek(start);
      }
    };
    vc.addListener(_trimPreviewListener!);
  }

  /// Tear down the live trim preview (called when leaving the Trim panel).
  void _detachTrimPreview() {
    final vc = _veditorController;
    if (_trimPreviewListener != null && vc != null) {
      try {
        vc.removeListener(_trimPreviewListener!);
      } catch (_) {}
    }
    _trimPreviewListener = null;
    _trimPositionSub?.cancel();
    _trimPositionSub = null;
    // Restore whole-file looping for the normal (post-trim) preview.
    _mkPlayer?.setPlaylistMode(mk.PlaylistMode.loop);
  }

  void _toggleVideoPlayback() {
    // Use edited player if available, otherwise editor's player
    final vc =
        (_editedVideoController != null &&
                _editedVideoController!.value.isInitialized)
            ? _editedVideoController!
            : (_veditorController?.video ?? _videoController);
    if (vc == null) return;
    setState(() {
      if (vc.value.isPlaying) {
        vc.pause();
        _isVideoPlaying = false;
      } else {
        vc.play();
        _isVideoPlaying = true;
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    // Remove video listener BEFORE disposing controllers
    if (_videoListener != null && _veditorController != null) {
      try {
        _veditorController!.video.removeListener(_videoListener!);
      } catch (_) {}
      _videoListener = null;
    }
    // Tear down the live trim preview hooks if the screen closes while the Trim
    // panel is open.
    if (_trimPreviewListener != null) {
      try {
        _veditorController?.removeListener(_trimPreviewListener!);
      } catch (_) {}
      _trimPreviewListener = null;
    }
    _trimPositionSub?.cancel();
    _editedVideoController?.dispose();
    _veditorController?.dispose();
    _mkErrorSub?.cancel();
    _mkPlayer?.dispose();
    _cleanupTempFiles();
    super.dispose();
  }

  void _cleanupTempFiles() {
    for (final path in _tempFiles) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    _tempFiles.clear();
  }

  String get _currentImagePath => _croppedImagePath ?? widget.filePath;

  // ================= EXPORT =================

  Future<String> _exportVideoPath() async {
    final vc = _veditorController;
    final vs = _editState.videoEditState;

    // Debug log all state
    log('[VideoExport] === Export Check ===');
    log('[VideoExport] vc initialized: ${vc?.initialized}');
    log('[VideoExport] vc minTrim: ${vc?.minTrim}, maxTrim: ${vc?.maxTrim}');
    log(
      '[VideoExport] vc startTrim: ${vc?.startTrim}, endTrim: ${vc?.endTrim}',
    );
    log('[VideoExport] vs.hasEdits: ${vs.hasEdits}');
    log('[VideoExport] vs.rotation: ${vs.rotation}, speed: ${vs.speed}');
    log(
      '[VideoExport] vs.cropRatio: ${vs.cropRatio}, flip: ${vs.flipDirection}',
    );
    log('[VideoExport] input path: $_currentImagePath');

    // Check trim from video_editor controller
    final isTrimmed =
        vc != null && vc.initialized && (vc.minTrim > 0.0 || vc.maxTrim < 1.0);

    log('[VideoExport] isTrimmed: $isTrimmed');

    try {
      final inputSize = File(_currentImagePath).lengthSync();
      log('[VideoExport] Starting native export...');
      log(
        '[VideoExport] Input size: ${(inputSize / 1024 / 1024).toStringAsFixed(1)}MB',
      );

      final hasEditsToApply = isTrimmed || vs.hasEdits;

      // No edits — return original (already recorded at 1080p, ~6MB for 10s)
      if (!hasEditsToApply) {
        log('[VideoExport] No edits, returning original');
        return _currentImagePath;
      }

      // Apply edits
      var builder = eve.VideoEditorBuilder(videoPath: _currentImagePath);

      if (isTrimmed) {
        final startMs = vc.startTrim.inMilliseconds;
        final endMs = vc.endTrim.inMilliseconds;
        log('[VideoExport] Trim: ${startMs}ms - ${endMs}ms');
        builder = builder.trim(startTimeMs: startMs, endTimeMs: endMs);
      }

      if (vs.hasCrop) {
        final ratio = _mapCropRatio(vs.cropRatio!);
        if (ratio != null) {
          log('[VideoExport] Crop: ${vs.cropRatio}');
          builder = builder.crop(aspectRatio: ratio);
        }
      }

      if (vs.hasRotation) {
        final degree = _mapRotation(vs.rotation);
        if (degree != null) {
          log('[VideoExport] Rotate: ${vs.rotation}°');
          builder = builder.rotate(degree: degree);
        }
      }

      if (vs.hasSpeed) {
        log('[VideoExport] Speed: ${vs.speed}x');
        builder = builder.speed(speed: vs.speed);
      }

      if (vs.hasFlip) {
        final dir =
            vs.flipDirection == 'horizontal'
                ? eve.FlipDirection.horizontal
                : eve.FlipDirection.vertical;
        log('[VideoExport] Flip: ${vs.flipDirection}');
        builder = builder.flip(flipDirection: dir);
      }

      final result = await builder.export(
        onProgress: (p) => log('[VideoExport] Progress: ${(p * 100).toInt()}%'),
      );

      if (result != null) {
        final outSize = File(result).lengthSync();
        log(
          '[VideoExport] Edit done: ${(outSize / 1024 / 1024).toStringAsFixed(1)}MB',
        );

        // If output is larger than input, compress with FFmpeg (bitrate control)
        if (outSize > inputSize) {
          log('[VideoExport] Output inflated, compressing with FFmpeg...');
          final compressed = await _ffmpegCompress(result, inputSize);
          _tempFiles.add(result);
          if (compressed != result) _tempFiles.add(compressed);
          return compressed;
        }

        _tempFiles.add(result);
        return result;
      }

      log('[VideoExport] Export returned null');
    } catch (e, st) {
      log('[VideoExport] Error: $e', stackTrace: st);
    }

    return _currentImagePath;
  }

  /// Compress video with FFmpeg to match or beat the original file size.
  Future<String> _ffmpegCompress(String inputPath, int targetSize) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Calculate target bitrate from target size and duration
      // targetSize in bytes, get duration from input
      final inputFile = File(inputPath);
      final inputBytes = inputFile.lengthSync();

      // Use a bitrate that produces ~80% of original size
      // Formula: bitrate = (targetSize * 8) / duration_seconds
      // We don't know exact duration here, so use a fixed reasonable bitrate
      // Target: match original file size with good quality
      // Calculate bitrate from original size (targetSize) and video duration
      // bitrate = (targetSize_bytes * 8) / duration_seconds
      // Fallback: 5Mbps for crisp 1080p social content
      const videoBitrate = '5M';
      const audioBitrate = '128k';

      final command =
          '-i "$inputPath" -c:v mpeg4 -b:v $videoBitrate -c:a aac -b:a $audioBitrate -y "$outputPath"';

      log('[FFmpeg] Command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outFile = File(outputPath);
        if (outFile.existsSync()) {
          final outSize = outFile.lengthSync();
          log(
            '[FFmpeg] Compressed: ${(inputBytes / 1024 / 1024).toStringAsFixed(1)}MB → ${(outSize / 1024 / 1024).toStringAsFixed(1)}MB',
          );
          return outputPath;
        }
      }

      final output = await session.getOutput();
      log('[FFmpeg] Failed: $output');
    } catch (e) {
      log('[FFmpeg] Error: $e');
    }
    return inputPath;
  }

  eve.VideoAspectRatio? _mapCropRatio(String ratio) {
    switch (ratio) {
      case '16:9':
        return eve.VideoAspectRatio.ratio16x9;
      case '9:16':
        return eve.VideoAspectRatio.ratio9x16;
      case '1:1':
        return eve.VideoAspectRatio.ratio1x1;
      case '4:3':
        return eve.VideoAspectRatio.ratio4x3;
      case '3:4':
        return eve.VideoAspectRatio.ratio3x4;
      default:
        return null;
    }
  }

  eve.RotationDegree? _mapRotation(int deg) {
    switch (deg) {
      case 90:
        return eve.RotationDegree.degree90;
      case 180:
        return eve.RotationDegree.degree180;
      case 270:
        return eve.RotationDegree.degree270;
      default:
        return null;
    }
  }

  Future<String> _exportFinalPath() async {
    if (widget.isVideo) {
      // Use the already-edited file ONLY when no apply is in flight — otherwise
      // the cache could hand back a stale clip from a previous trim. While an
      // apply is running, fall through to a fresh export of the current trim.
      if (!_isApplyingVideoEdit &&
          _editedVideoPath != null &&
          File(_editedVideoPath!).existsSync()) {
        log('[VideoExport] Using already-edited file: $_editedVideoPath');
        return _editedVideoPath!;
      }
      // Export with edits or just compress for upload
      return _exportVideoPath();
    }

    final needsPhysicalFlip = widget.isFrontCamera && _croppedImagePath == null;

    if (!_editState.hasEdits && !needsPhysicalFlip) {
      return _currentImagePath;
    }

    try {
      // No other edits — just save the flipped image
      if (!_editState.hasEdits) {
        final bytes = await File(_currentImagePath).readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return _currentImagePath;

        if (needsPhysicalFlip) {
          decoded = img.flipHorizontal(decoded);
        }

        final tempDir = await Directory.systemTemp.createTemp();
        final outPath =
            '${tempDir.path}/flipped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(outPath).writeAsBytes(img.encodeJpg(decoded, quality: 100));
        _tempFiles.add(outPath);
        return outPath;
      }

      // Capture the rendered widget (filter + tune + overlays) via RepaintBoundary.
      final boundary =
          _compositeKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final uiImage = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await uiImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          final tempDir = await Directory.systemTemp.createTemp();
          final outPath =
              '${tempDir.path}/final_${DateTime.now().millisecondsSinceEpoch}.png';
          final pngBytes = byteData.buffer.asUint8List();

          await File(outPath).writeAsBytes(pngBytes);
          _tempFiles.add(outPath);
          return outPath;
        }
      }

      // Fallback: manual pixel processing if RepaintBoundary capture fails
      final bytes = await File(_currentImagePath).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded != null) {
        if (needsPhysicalFlip) {
          decoded = img.flipHorizontal(decoded);
        }
        if (_editState.tuneData.hasChanges) {
          decoded = _applyTune(decoded, _editState.tuneData);
        }
        if (_editState.selectedFilter != null) {
          decoded = _applyFilter(decoded, _editState.selectedFilter!);
        }
        final tempDir = await Directory.systemTemp.createTemp();
        final outPath =
            '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(outPath).writeAsBytes(img.encodePng(decoded));
        _tempFiles.add(outPath);
        return outPath;
      }
    } catch (e) {
      log('Export error: $e');
    }
    return _currentImagePath;
  }

  img.Image _applyTune(img.Image src, TuneData tune) {
    var result = src;
    if (tune.brightness != 0) {
      final b = (tune.brightness * 100).round();
      result = img.adjustColor(result, brightness: b);
    }
    if (tune.contrast != 0) {
      final c = (tune.contrast * 100).round();
      result = img.adjustColor(result, contrast: c);
    }
    if (tune.saturation != 0) {
      final s = 1.0 + tune.saturation;
      result = img.adjustColor(result, saturation: s);
    }
    return result;
  }

  img.Image _applyFilter(img.Image src, FilterPreset filter) {
    final m = filter.matrix;
    final result = img.Image.from(src);
    for (final pixel in result) {
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      pixel.r = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0, 255).toInt();
      pixel.g = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0, 255).toInt();
      pixel.b =
          (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0, 255).toInt();
    }
    return result;
  }

  // ================= REGION EFFECT (Pixelate/Blur) =================

  Future<void> _applyRegionEffect() async {
    if (_regionStart == null || _regionEnd == null) return;
    if (_isProcessingRegion) return;
    // Save the image path before the first blur/pixelate edit
    _preRegionImagePath ??= _currentImagePath;
    final rect = Rect.fromPoints(_regionStart!, _regionEnd!);
    setState(() {
      _regionStart = null;
      _regionEnd = null;
    });
    if (rect.width < 10 || rect.height < 10) return;

    final isPixelate = _activeEditor == ActiveEditor.pixelate;
    final blockSize = _pixelateEditorKey.currentState?.blockSize ?? 10;
    final blurRadius = _blurEditorKey.currentState?.blurRadius ?? 10.0;

    // Get display size for coordinate conversion
    final renderBox =
        _compositeKey.currentContext?.findRenderObject() as RenderBox?;
    final displayWidth =
        renderBox?.size.width ?? MediaQuery.of(context).size.width;
    final displayHeight =
        renderBox?.size.height ?? MediaQuery.of(context).size.height;
    final imagePath = _currentImagePath;

    setState(() => _isProcessingRegion = true);

    try {
      // Extract all values as primitives for isolate
      final newPath = await compute(_processRegionInIsolate, <String, dynamic>{
        'imagePath': imagePath,
        'rectLeft': rect.left,
        'rectTop': rect.top,
        'rectWidth': rect.width,
        'rectHeight': rect.height,
        'displayWidth': displayWidth,
        'displayHeight': displayHeight,
        'isPixelate': isPixelate,
        'blockSize': blockSize,
        'blurRadius': blurRadius,
      });

      if (newPath != null && mounted) {
        _tempFiles.add(newPath);
        setState(() {
          _croppedImagePath = newPath;
          _isProcessingRegion = false;
        });
      } else if (mounted) {
        setState(() => _isProcessingRegion = false);
      }
    } catch (e) {
      debugPrint('Region effect error: $e');
      if (mounted) setState(() => _isProcessingRegion = false);
    }
  }

  static String? _processRegionInIsolate(Map<String, dynamic> params) {
    try {
      final imageBytes = File(params['imagePath'] as String).readAsBytesSync();
      var decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final displayWidth = params['displayWidth'] as double;
      final displayHeight = params['displayHeight'] as double;

      // BoxFit.cover: image is scaled uniformly by the larger ratio,
      // then centered — excess is cropped.
      final imgW = decoded.width.toDouble();
      final imgH = decoded.height.toDouble();
      final coverScale =
          (imgW / displayWidth > imgH / displayHeight)
              ? imgH /
                  displayHeight // height-limited: image wider than display
              : imgW / displayWidth; // width-limited: image taller than display

      // Offset from centering (the cropped/hidden portion on each side)
      final visibleImgW = displayWidth * coverScale;
      final visibleImgH = displayHeight * coverScale;
      final offsetX = (imgW - visibleImgW) / 2;
      final offsetY = (imgH - visibleImgH) / 2;

      final rectLeft = params['rectLeft'] as double;
      final rectTop = params['rectTop'] as double;
      final rectWidth = params['rectWidth'] as double;
      final rectHeight = params['rectHeight'] as double;

      // Convert screen coords → image coords accounting for cover fit
      final x = (rectLeft * coverScale + offsetX).round().clamp(
        0,
        decoded.width - 1,
      );
      final y = (rectTop * coverScale + offsetY).round().clamp(
        0,
        decoded.height - 1,
      );
      final w = (rectWidth * coverScale).round().clamp(1, decoded.width - x);
      final h = (rectHeight * coverScale).round().clamp(1, decoded.height - y);

      var cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      if (params['isPixelate'] as bool) {
        cropped = img.pixelate(cropped, size: params['blockSize'] as int);
      } else {
        cropped = img.gaussianBlur(
          cropped,
          radius: (params['blurRadius'] as double).round(),
        );
      }
      decoded = img.compositeImage(decoded, cropped, dstX: x, dstY: y);

      final outPath =
          '${Directory.systemTemp.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File(outPath).writeAsBytesSync(img.encodeJpg(decoded, quality: 100));
      return outPath;
    } catch (e) {
      return null;
    }
  }

  // ================= ACTIONS =================

  Future<void> _saveToCameraRollTapped() async {
    try {
      final finalPath = await _exportFinalPath();
      try {
        if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
          AppToast.error('Permission denied');
          return;
        }
      } catch (_) {}

      widget.isVideo
          ? await Gal.putVideo(finalPath, album: 'Outspot')
          : await Gal.putImage(finalPath, album: 'Outspot');
      AppToast.success('Saved to Gallery');
    } catch (e) {
      AppSnackbar.error("Save failed: $e");
    }
  }

  Future<void> _exportAndUpload({required bool postToStory}) async {
    final cController = Get.find<CameraControllers>();
    isUploadingStory.value = true;
    try {
      final path = await _exportFinalPath();
      final uploadFile = File(path);
      log('[Upload] path: $path');
      log('[Upload] exists: ${uploadFile.existsSync()}');
      log(
        '[Upload] size: ${uploadFile.existsSync() ? uploadFile.lengthSync() : 0} bytes',
      );
      log('[Upload] isVideo: ${widget.isVideo}');
      await cController.uploadCapturedFile(
        filePath: path,
        isVideo: widget.isVideo,
        postToStory: postToStory,
        showLoading: false,
        onSuccessNavigation: () {
          controller.toggleSelection();
          AppToast.success(postToStory ? "Post to Story" : "Uploaded");
        },
      );
    } catch (e) {
      AppToast.error("Something went wrong");
    } finally {
      isUploadingStory.value = false;
    }
  }

  /// Snap-to-friend: export the edited media and send it straight into the
  /// direct-message chat it was opened from, then pop back to that chat.
  Future<void> _sendSnapToFriend() async {
    // Use a dedicated flag (NOT isUploadingStory) so the Story button doesn't
    // show its loading spinner when sending a snap to a friend.
    if (_isSendingSnap.value) return;
    _isSendingSnap.value = true;
    try {
      final path = await _exportFinalPath();
      if (!Get.isRegistered<DirectmassagescreenController>()) {
        AppToast.error("Chat not available");
        return;
      }
      final dm = Get.find<DirectmassagescreenController>();
      await dm.sendSnapFile(path, isVideo: widget.isVideo);
      // Pop the camera + preview screens, returning to the chat.
      Get.until((route) => route.settings.name == Routes.directMessageScreen);
      AppToast.success(_snapName.isEmpty ? "Sent" : "Sent to $_snapName");
    } catch (e) {
      AppSnackbar.error("$e");
    } finally {
      _isSendingSnap.value = false;
    }
  }

  void _setActiveEditor(ActiveEditor editor) {
    final previousEditor = _activeEditor;
    final newEditor = _activeEditor == editor ? ActiveEditor.none : editor;

    // If opening a video edit tool, discard the edited preview to re-edit from original
    if (widget.isVideo && newEditor != ActiveEditor.none) {
      _editedVideoController?.dispose();
      _editedVideoController = null;
      _editedVideoPath = null;
    }

    setState(() {
      _activeEditor = newEditor;
    });

    // Enter/exit the LIVE trim preview (media_kit follows the handles).
    if (widget.isVideo) {
      if (newEditor == ActiveEditor.videoTrim) {
        _attachTrimPreview();
      } else if (previousEditor == ActiveEditor.videoTrim) {
        _detachTrimPreview();
      }
    }

    // When closing a video editor panel, apply edits and refresh preview
    if (widget.isVideo && newEditor == ActiveEditor.none) {
      final wasVideoEditor = [
        ActiveEditor.videoTrim,
        ActiveEditor.videoCrop,
        ActiveEditor.videoRotate,
        ActiveEditor.videoSpeed,
        ActiveEditor.videoFlip,
      ].contains(previousEditor);

      if (wasVideoEditor) {
        // Crop commits its ratio inside its own onDone and then calls
        // _applyVideoEditAndRefresh itself, so don't double-fire (that was the
        // duplicate native export on crop). Trim/rotate/speed/flip have no such
        // commit step, so they rely on THIS auto-apply — which means trim is
        // applied no matter how the panel is dismissed (Done button OR toggling
        // the tool off).
        final ownsApply = previousEditor == ActiveEditor.videoCrop;
        if (!ownsApply) {
          _applyVideoEditAndRefresh();
        }
      } else {
        _resumeVideoPlayback();
      }
    }
  }

  void _resumeVideoPlayback() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final vc = _veditorController?.video;
      if (vc == null) return;
      vc.seekTo(vc.value.position).then((_) {
        vc.setLooping(true);
        vc.play();
        if (mounted) setState(() => _isVideoPlaying = true);
      });
    });
  }

  Future<void> _applyVideoEditAndRefresh() async {
    // Claim a token: only the LATEST apply may mutate the preview. This kills
    // the "second Done applies the previous trim" race when a prior export is
    // still in flight.
    final int token = ++_videoApplyToken;
    _isApplyingVideoEdit = true;

    // Freeze + pause the visible player so the full original doesn't keep
    // playing (with audio) during the multi-second export.
    if (mounted) {
      setState(() {
        _isVideoPlaying = false;
        _mkPlaying = false;
      });
    }
    await _mkPlayer?.pause();

    try {
      // Make sure the live trim clamp is detached before exporting.
      _detachTrimPreview();
      // Pause the editor controller while exporting
      _veditorController?.video.pause();

      final editedPath = await _exportVideoPath();

      // A newer apply superseded this one while we were exporting — discard.
      if (token != _videoApplyToken || !mounted) return;

      if (editedPath != _currentImagePath) {
        log('[VideoEdit] Reloading preview with: $editedPath');

        // Keep no video_player preview (it freezes after ~1s on iOS). Store the
        // edited path for export/send, and play the edited video via media_kit.
        _editedVideoController?.dispose();
        _editedVideoController = null;
        _editedVideoPath = editedPath;

        await _mkPlayer?.open(mk.Media(editedPath));
        _mkLoadedPath = editedPath;
        if (token != _videoApplyToken || !mounted) return;
        if (mounted) setState(() => _mkPlaying = true);
      } else {
        // No net edit (trim widened back to full, or export fell back to the
        // original). Re-point media_kit at the ORIGINAL and clear the stale
        // edited path, so a previously-trimmed clip is never left on screen.
        _editedVideoController?.dispose();
        _editedVideoController = null;
        _editedVideoPath = null;

        await _mkPlayer?.open(mk.Media(widget.filePath));
        _mkLoadedPath = widget.filePath;
        if (token != _videoApplyToken || !mounted) return;
        if (mounted) setState(() => _mkPlaying = true);
      }
    } catch (e) {
      log('[VideoEdit] Apply error: $e');
      try {
        await _mkPlayer?.play();
        if (mounted) setState(() => _mkPlaying = true);
      } catch (_) {}
    } finally {
      if (token == _videoApplyToken) _isApplyingVideoEdit = false;
    }
  }

  bool _isCropOpening = false;

  Future<void> _openCropEditor() async {
    if (widget.isVideo) {
      Fluttertoast.showToast(msg: "Video editing is not supported.");
      return;
    }

    // Prevent multiple taps
    if (_isCropOpening) return;
    _isCropOpening = true;

    String imageForCrop = _currentImagePath;

    try {
      final boundary =
          _baseImageKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        // Use pixelRatio 1.5 instead of 3.0 for much faster snapshot
        final uiImage = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await uiImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          final tempDir = await Directory.systemTemp.createTemp();
          final snapPath =
              '${tempDir.path}/crop_snap_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(snapPath).writeAsBytes(byteData.buffer.asUint8List());
          _tempFiles.add(snapPath);
          imageForCrop = snapPath;
        }
      }
    } catch (e) {
      log('Snapshot for crop failed: $e, falling back to: $imageForCrop');
    }

    if (!mounted) {
      _isCropOpening = false;
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CropEditorScreen(
              imagePath: imageForCrop,
              onDone: (croppedPath) {
                _tempFiles.add(croppedPath);
                setState(() {
                  _croppedImagePath = croppedPath;
                  _isCropped = true; // aspect changed → preview uses contain
                  // Reset visual-only edits since they are baked into the cropped image
                  _editState.selectedFilter = null;
                  _editState.tuneData = TuneData();
                  // Keep text, emoji, draw overlays — they remain editable
                });
                Navigator.pop(context);
              },
            ),
      ),
    );
    _isCropOpening = false;
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main image/video with overlays
          Positioned.fill(
            child: RepaintBoundary(key: _compositeKey, child: _buildCanvas()),
          ),

          // Region selection gesture (pixelate/blur) — above canvas, below UI controls
          if (_activeEditor == ActiveEditor.pixelate ||
              _activeEditor == ActiveEditor.blur)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  setState(() {
                    _regionStart = details.localPosition;
                    _regionEnd = details.localPosition;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _regionEnd = details.localPosition;
                  });
                },
                onPanEnd: (_) {
                  _applyRegionEffect();
                },
              ),
            ),

          // Region selection overlay
          if (_regionStart != null && _regionEnd != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _RegionSelectionPainter(
                  start: _regionStart!,
                  end: _regionEnd!,
                  isPixelate: _activeEditor == ActiveEditor.pixelate,
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessingRegion)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFAB50F6)),
                  ),
                ),
              ),
            ),

          // Back button
          Positioned(
            top: 40.h,
            left: 10.w,
            child: IconButton(
              color: Colors.white,
              onPressed: () {
                Get.back();
              },
              icon: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 25.r,
                height: 25.r,
              ),

              padding: EdgeInsets.all(8.w),
              constraints: const BoxConstraints(),
            ),
          ),

          // // Quick exposure/brightness slider (left side)
          // Positioned(
          //   left: 15.w,
          //   top: 100.h,
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       GestureDetector(
          //         onTap:
          //             () => setState(
          //               () => _showExposureSlider = !_showExposureSlider,
          //             ),
          //         child: Container(
          //           padding: const EdgeInsets.all(8),
          //           decoration: BoxDecoration(
          //             color:
          //                 _showExposureSlider
          //                     ? Colors.white.withValues(alpha: 0.2)
          //                     : Colors.black.withValues(alpha: 0.4),
          //             shape: BoxShape.circle,
          //           ),
          //           child: Icon(
          //             Icons.brightness_6,
          //             color:
          //                 _showExposureSlider
          //                     ? Colors.yellowAccent
          //                     : Colors.white,
          //             size: 22.sp,
          //           ),
          //         ),
          //       ),
          //       if (_showExposureSlider) ...[
          //         SizedBox(height: 8.h),
          //         SizedBox(
          //           height: 180.h,
          //           child: RotatedBox(
          //             quarterTurns: 3,
          //             child: SliderTheme(
          //               data: SliderTheme.of(context).copyWith(
          //                 trackHeight: 2,
          //                 thumbShape: const RoundSliderThumbShape(
          //                   enabledThumbRadius: 6,
          //                 ),
          //                 overlayShape: const RoundSliderOverlayShape(
          //                   overlayRadius: 12,
          //                 ),
          //                 activeTrackColor: Colors.yellowAccent,
          //                 inactiveTrackColor: Colors.white30,
          //                 thumbColor: Colors.white,
          //               ),
          //               child: Slider(
          //                 value:
          //                     widget.isVideo
          //                         ? _editState.videoEditState.brightness
          //                         : _editState.tuneData.brightness,
          //                 min: -1.0,
          //                 max: 1.0,
          //                 onChanged: (v) {
          //                   setState(() {
          //                     if (widget.isVideo) {
          //                       _editState.videoEditState.brightness = v;
          //                     } else {
          //                       _editState.tuneData = TuneData(
          //                         brightness: v,
          //                         contrast: _editState.tuneData.contrast,
          //                         saturation: _editState.tuneData.saturation,
          //                       );
          //                     }
          //                   });
          //                 },
          //               ),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ],
          //   ),
          // ),

          // Right-side tool buttons
          if (!widget.isVideo)
            Positioned(top: 40.h, right: 16.w, child: _buildToolButtons()),
          if (widget.isVideo)
            Positioned(top: 40.h, right: 16.w, child: _buildVideoToolButtons()),

          // Bottom: editor panel or action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_activeEditor != ActiveEditor.none)
                  _buildActiveEditorPanel(),
                if (_activeEditor == ActiveEditor.none)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 30),
                    child: _buildBottomActions(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    final hasColorFilter =
        _editState.tuneData.hasChanges || _editState.selectedFilter != null;

    Widget imageWidget;
    if (widget.isVideo) {
      imageWidget = _buildVideoCanvas();
    } else {
      imageWidget = Image.file(
        File(_croppedImagePath ?? widget.filePath),
        // Only a crop changes the aspect ratio (→ contain). Pixelate/blur keep
        // the original dimensions, so stay full-screen cover — otherwise the
        // preview zoomed out / letterboxed the moment you used those tools.
        fit: _isCropped ? BoxFit.contain : BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      );

      final needsVisualFlip = widget.isFrontCamera && _croppedImagePath == null;

      if (needsVisualFlip) {
        imageWidget = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: imageWidget,
        );
      }
    }

    // Apply color filters for real-time preview
    if (hasColorFilter && !widget.isVideo) {
      List<double> matrix;
      if (_editState.selectedFilter != null) {
        matrix = List<double>.from(_editState.selectedFilter!.matrix);
        // Combine with tune if needed
        if (_editState.tuneData.hasChanges) {
          matrix = _editState.tuneData.toColorMatrix();
          // Simple combination: apply filter matrix on top
          if (_editState.selectedFilter != null) {
            matrix = _multiplyMatrices(
              _editState.selectedFilter!.matrix,
              matrix,
            );
          }
        }
      } else {
        matrix = _editState.tuneData.toColorMatrix();
      }
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: imageWidget,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _baseImageKey, child: imageWidget),

        // Draw paths overlay
        if (_editState.drawPaths.isNotEmpty || _currentDrawPoints.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: DrawingPainter(
                paths: _editState.drawPaths,
                currentPoints:
                    _currentDrawPoints.isNotEmpty ? _currentDrawPoints : null,
                currentColor: _getDrawColor(),
                currentStrokeWidth: _getDrawStrokeWidth(),
                currentOpacity: _getDrawOpacity(),
                currentBrushType: _getDrawBrushType(),
              ),
            ),
          ),

        // Text layers
        ..._editState.textLayers.asMap().entries.map((entry) {
          final i = entry.key;
          final layer = entry.value;
          return Positioned(
            left: layer.position.dx,
            top: layer.position.dy,
            child: _TextGestureWidget(
              text: layer.text,
              fontSize: layer.fontSize,
              color: layer.color,
              opacity: layer.opacity,
              fontFamily: layer.fontFamily,
              getTextStyle: _getTextLayerFont,
              onTap: () {
                setState(() {
                  _editingTextIndex = i;
                  _activeEditor = ActiveEditor.text;
                });
              },
              onUpdate: (delta, newFontSize) {
                setState(() {
                  _editState.textLayers[i].position += delta;
                  _editState.textLayers[i].fontSize = newFontSize;
                });
              },
              onDelete: () {
                setState(() => _editState.textLayers.removeAt(i));
              },
              onDragOverDelete: (hovering) {
                setState(() => _showDeleteZone = hovering);
              },
            ),
          );
        }),

        // Emoji layers
        ..._editState.emojiLayers.asMap().entries.map((entry) {
          final i = entry.key;
          final layer = entry.value;
          return Positioned(
            left: layer.position.dx,
            top: layer.position.dy,
            child: _EmojiGestureWidget(
              emoji: layer.emoji,
              scale: layer.scale,
              onDelete: () {
                setState(() => _editState.emojiLayers.removeAt(i));
              },
              onUpdate: (delta, newScale) {
                setState(() {
                  _editState.emojiLayers[i].position += delta;
                  _editState.emojiLayers[i].scale = newScale;
                });
              },
              onDragOverDelete: (hovering) {
                setState(() => _showDeleteZone = hovering);
              },
            ),
          );
        }),

        // Delete zone at bottom — shows when dragging emoji/text
        if (_showDeleteZone)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.red.withOpacity(0.8),
                    Colors.red.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 36.sp),
                  SizedBox(height: 4.h),
                  Text(
                    'Drop here to delete',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                  SizedBox(height: 70.h),
                ],
              ),
            ),
          ),

        if (_activeEditor == ActiveEditor.draw)
          Positioned.fill(
            child: Listener(
              onPointerDown: (event) {
                _currentDrawPoints = [event.localPosition];
                setState(() {});
              },
              onPointerMove: (event) {
                _currentDrawPoints.add(event.localPosition);
                // Only rebuild every 3 points for smoother performance
                if (_currentDrawPoints.length % 3 == 0) {
                  setState(() {});
                }
              },
              onPointerUp: (_) {
                setState(() {
                  if (_currentDrawPoints.isNotEmpty) {
                    _editState.drawPaths.add(
                      DrawPath(
                        points: List.from(_currentDrawPoints),
                        color: _getDrawColor(),
                        strokeWidth: _getDrawStrokeWidth(),
                        opacity: _getDrawOpacity(),
                        brushType: _getDrawBrushType(),
                      ),
                    );
                    _currentDrawPoints = [];
                  }
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  final GlobalKey<PixelateEditorPanelState> _pixelateEditorKey = GlobalKey();
  final GlobalKey<BlurEditorPanelState> _blurEditorKey = GlobalKey();

  Color _getDrawColor() {
    final state = _drawEditorKey.currentState;
    if (state is DrawEditorPanelState) return state.currentColor;
    return Colors.white;
  }

  double _getDrawStrokeWidth() {
    final state = _drawEditorKey.currentState;
    if (state is DrawEditorPanelState) return state.currentStrokeWidth;
    return 4.0;
  }

  double _getDrawOpacity() {
    final state = _drawEditorKey.currentState;
    if (state is DrawEditorPanelState) return state.currentOpacity;
    return 1.0;
  }

  BrushType _getDrawBrushType() {
    final state = _drawEditorKey.currentState;
    if (state is DrawEditorPanelState) return state.currentBrushType;
    return BrushType.pen;
  }

  List<double> _multiplyMatrices(List<double> a, List<double> b) {
    // 4x5 matrix multiplication (treating as 5x5 with [0,0,0,0,1] last row)
    final result = List<double>.filled(20, 0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        if (col == 4) sum += a[row * 5 + 4];
        result[row * 5 + col] = sum;
      }
    }
    return result;
  }

  // ================= TOOL BUTTONS =================

  Widget _buildToolButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _toolIconButton(
          'assets/svg/icons/text_icon.svg',
          ActiveEditor.text,
          isAsset: true,
        ),
        SizedBox(height: 18.h),
        _toolIconButton(
          'assets/svg/icons/emoji_icon.svg',
          ActiveEditor.emoji,
          isAsset: true,
          scale: 4,
        ),

        SizedBox(height: 18.h),
        _toolIconButton(
          'assets/svg/icons/gesture_icon.svg',
          ActiveEditor.draw,
          isAsset: true,
        ),

        SizedBox(height: 18.h),
        _toolButton(Icons.grid_on, 'Pixelate', ActiveEditor.pixelate),
        SizedBox(height: 18.h),
        _toolButton(Icons.blur_on, 'Blur', ActiveEditor.blur),
        SizedBox(height: 18.h),
        _toolButton(Icons.crop_rotate, 'Crop', ActiveEditor.crop),
        SizedBox(height: 18.h),
        _toolButton(Icons.tune, 'Tune', ActiveEditor.tune),
        SizedBox(height: 18.h),
        _toolButton(Icons.filter_vintage, 'Filter', ActiveEditor.filter),
      ],
    );
  }

  Widget _buildVideoToolButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _toolButton(Icons.content_cut, 'Trim', ActiveEditor.videoTrim),
        SizedBox(height: 14.h),
        // Crop hidden for now — kept for future use
        // _toolButton(Icons.crop, 'Crop', ActiveEditor.videoCrop),
        // SizedBox(height: 14.h),
        _toolButton(Icons.rotate_right, 'Rotate', ActiveEditor.videoRotate),
        SizedBox(height: 14.h),
        _toolButton(Icons.speed, 'Speed', ActiveEditor.videoSpeed),
        SizedBox(height: 14.h),
        _toolButton(Icons.flip, 'Flip', ActiveEditor.videoFlip),
      ],
    );
  }

  Widget _toolIconButton(
    String asset,
    ActiveEditor editor, {
    bool isAsset = false,
    double scale = 3,
  }) {
    final isActive = _activeEditor == editor;
    return GestureDetector(
      onTap: () {
        if (editor == ActiveEditor.crop) {
          _openCropEditor();
        } else {
          _setActiveEditor(editor);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFFAB50F6).withOpacity(0.3)
                  : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          asset,
          width: 21.sp,
          height: 21.sp,
          colorFilter: ColorFilter.mode(
            isActive ? const Color(0xFFAB50F6) : Colors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, ActiveEditor editor) {
    final isActive = _activeEditor == editor;
    return GestureDetector(
      onTap: () {
        if (editor == ActiveEditor.crop) {
          _openCropEditor();
        } else {
          _setActiveEditor(editor);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFFAB50F6).withOpacity(0.3)
                  : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFFAB50F6) : Colors.white,
          size: 22.sp,
        ),
      ),
    );
  }

  // ================= EDITOR PANELS =================

  Widget _buildActiveEditorPanel() {
    switch (_activeEditor) {
      case ActiveEditor.text:
        final editingIndex = _editingTextIndex;
        final editingLayer =
            editingIndex != null && editingIndex < _editState.textLayers.length
                ? _editState.textLayers[editingIndex]
                : null;
        return TextEditorPanel(
          editingLayer: editingLayer,
          onAdd: (layer) {
            setState(() {
              if (editingIndex != null &&
                  editingIndex < _editState.textLayers.length) {
                _editState.textLayers[editingIndex] = layer;
              } else {
                _editState.textLayers.add(layer);
              }
              _editingTextIndex = null;
              _activeEditor = ActiveEditor.none;
            });
          },
          onDelete:
              editingLayer != null
                  ? () {
                    setState(() {
                      _editState.textLayers.removeAt(editingIndex!);
                      _editingTextIndex = null;
                      _activeEditor = ActiveEditor.none;
                    });
                  }
                  : null,
          onClose: () {
            setState(() {
              _editingTextIndex = null;
              _activeEditor = ActiveEditor.none;
            });
          },
        );
      case ActiveEditor.draw:
        return DrawEditorPanel(
          key: _drawEditorKey,
          paths: _editState.drawPaths,
          onAddPath: (path) {
            setState(() => _editState.drawPaths.add(path));
          },
          onUndo: () {
            if (_editState.drawPaths.isNotEmpty) {
              setState(() => _editState.drawPaths.removeLast());
            }
          },
          onClearAll: () {
            if (_editState.drawPaths.isNotEmpty) {
              setState(() => _editState.drawPaths.clear());
            }
          },
          onClose: () => _setActiveEditor(ActiveEditor.none),
        );
      case ActiveEditor.emoji:
        return EmojiEditorPanel(
          onAdd: (layer) {
            setState(() => _editState.emojiLayers.add(layer));
          },
          onClose: () => _setActiveEditor(ActiveEditor.none),
        );
      case ActiveEditor.tune:
        return TuneEditorPanel(
          tuneData: _editState.tuneData,
          onChanged: (data) {
            setState(() => _editState.tuneData = data);
          },
          onClose: () => _setActiveEditor(ActiveEditor.none),
        );
      case ActiveEditor.filter:
        return FilterEditorPanel(
          imagePath: _currentImagePath,
          selectedFilter: _editState.selectedFilter,
          onSelect: (filter) {
            setState(() => _editState.selectedFilter = filter);
          },
          onClose: () => _setActiveEditor(ActiveEditor.none),
        );
      case ActiveEditor.pixelate:
        return PixelateEditorPanel(
          key: _pixelateEditorKey,
          onAdd: (region) {
            setState(() => _editState.pixelateRegions.add(region));
          },
          onUndo: () {
            if (_editState.pixelateRegions.isNotEmpty) {
              setState(() => _editState.pixelateRegions.removeLast());
            }
          },
          onReset: () {
            setState(() {
              _editState.pixelateRegions.clear();
              if (_preRegionImagePath != null) {
                _croppedImagePath =
                    _preRegionImagePath == widget.filePath
                        ? null
                        : _preRegionImagePath;
                _preRegionImagePath = null;
              }
            });
          },
          onClose: () => _setActiveEditor(ActiveEditor.none),
        );
      case ActiveEditor.blur:
        return BlurEditorPanel(
          key: _blurEditorKey,
          onAdd: (region) {
            setState(() => _editState.blurRegions.add(region));
          },
          onUndo: () {
            if (_editState.blurRegions.isNotEmpty) {
              setState(() => _editState.blurRegions.removeLast());
            }
          },
          onReset: () {
            setState(() {
              _editState.blurRegions.clear();
              if (_preRegionImagePath != null) {
                _croppedImagePath =
                    _preRegionImagePath == widget.filePath
                        ? null
                        : _preRegionImagePath;
                _preRegionImagePath = null;
              }
            });
          },
          onClose: () => _setActiveEditor(ActiveEditor.none),
        );
      case ActiveEditor.videoTrim:
        if (_veditorController == null || !_veditorController!.initialized) {
          return const SizedBox.shrink();
        }
        return _videoPanelWrapper(
          icon: Icons.content_cut,
          title: 'Trim',
          // No custom onDone: the default close (check button) calls
          // _setActiveEditor(none), which auto-applies the trim. Apply is now
          // race-safe (token guard) and reopens the original when the trim is
          // widened back to full, so the result always matches the selection.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live duration readout: how long the trimmed selection is vs the
              // full video. Rebuilds as either handle is dragged.
              AnimatedBuilder(
                animation: _veditorController!,
                builder: (_, __) {
                  final vc = _veditorController!;
                  final selected = vc.endTrim - vc.startTrim;
                  final total = vc.video.value.duration;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected: ${_formatTrimDuration(selected)}',
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Total: ${_formatTrimDuration(total)}',
                          style: GoogleFonts.notoSans(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: SizedBox(
                  height: 60.h,
                  child: Stack(
                    children: [
                      TrimSlider(
                        controller: _veditorController!,
                        height: 60.h,
                        // MUST be 0. At maxTrim==1 the right handle center sits
                        // at _rect.right = _fullLayout.width + _horizontalMargin,
                        // i.e. (horizontalMargin + edgeWidth) px OUTSIDE the
                        // gesture surface. Grabbable overlap is
                        // (24 - _horizontalMargin), so a LARGER margin makes the
                        // right handle HARDER to grab (opposite of intuition).
                        // circle edges → edgeWidth == lineWidth (2), so margin 0
                        // → _horizontalMargin 2 → ~22px grab zone (package max),
                        // and no gutter (no dark side box).
                        horizontalMargin: 0,
                        hasHaptic: true,
                      ),
                      // Smooth playhead line, driven directly by media_kit's
                      // position stream (the package's own line is hidden — it
                      // tracks the paused vc.video). No seekTo, so no glitch.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: LayoutBuilder(
                            builder: (ctx, c) {
                              final player = _mkPlayer;
                              if (player == null) {
                                return const SizedBox.shrink();
                              }
                              return StreamBuilder<Duration>(
                                stream: player.stream.position,
                                builder: (_, snap) {
                                  final total =
                                      player.state.duration.inMilliseconds;
                                  if (total <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  final pos =
                                      (snap.data ?? player.state.position)
                                          .inMilliseconds;
                                  final ratio = (pos / total).clamp(0.0, 1.0);
                                  final x = (ratio * c.maxWidth - 1).clamp(
                                    0.0,
                                    c.maxWidth - 2,
                                  );
                                  return Stack(
                                    children: [
                                      Positioned(
                                        left: x,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 2,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TrimTimeline(
                controller: _veditorController!,
                padding: EdgeInsets.symmetric(horizontal: 15.w),
              ),
            ],
          ),
        );
      case ActiveEditor.videoCrop:
        if (_veditorController == null || !_veditorController!.initialized) {
          return const SizedBox.shrink();
        }
        return _videoPanelWrapper(
          icon: Icons.crop,
          title: 'Crop',
          subtitle: _editState.videoEditState.cropRatio,
          onDone: () async {
            final vc = _veditorController!;
            vc.updateCrop(vc.cacheMinCrop, vc.cacheMaxCrop);

            // Use the selected preferred aspect ratio as the export ratio
            final preferredRatio = vc.preferredCropAspectRatio;
            if (preferredRatio != null) {
              if ((preferredRatio - 16 / 9).abs() < 0.01) {
                _editState.videoEditState.cropRatio = '16:9';
              } else if ((preferredRatio - 9 / 16).abs() < 0.01) {
                _editState.videoEditState.cropRatio = '9:16';
              } else if ((preferredRatio - 1.0).abs() < 0.01) {
                _editState.videoEditState.cropRatio = '1:1';
              } else if ((preferredRatio - 4 / 3).abs() < 0.01) {
                _editState.videoEditState.cropRatio = '4:3';
              } else if ((preferredRatio - 3 / 4).abs() < 0.01) {
                _editState.videoEditState.cropRatio = '3:4';
              }
              log(
                '[Crop] Set cropRatio: ${_editState.videoEditState.cropRatio}',
              );
            } else {
              _editState.videoEditState.cropRatio = null;
              log('[Crop] No preferred ratio — clearing cropRatio');
            }

            _setActiveEditor(ActiveEditor.none);
            await _applyVideoEditAndRefresh();
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _videoCropButton('Free', null),
                SizedBox(width: 8.w),
                _videoCropButton('9:16', 9 / 16),
                SizedBox(width: 8.w),
                _videoCropButton('1:1', 1.0),
                SizedBox(width: 8.w),
                _videoCropButton('16:9', 16 / 9),
                SizedBox(width: 8.w),
                _videoCropButton('4:3', 4 / 3),
                SizedBox(width: 8.w),
                _videoCropButton('3:4', 3 / 4),
              ],
            ),
          ),
        );

      case ActiveEditor.videoRotate:
        return _videoPanelWrapper(
          icon: Icons.rotate_right,
          title: 'Rotate',
          subtitle:
              _editState.videoEditState.rotation == 0
                  ? null
                  : '${_editState.videoEditState.rotation}°',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rotateButton(Icons.rotate_left, 'Left', RotateDirection.left),
              SizedBox(width: 40.w),
              _rotateButton(Icons.rotate_right, 'Right', RotateDirection.right),
            ],
          ),
        );

      case ActiveEditor.videoSpeed:
        return _videoPanelWrapper(
          icon: Icons.speed,
          title: 'Speed',
          subtitle: '${_editState.videoEditState.speed}x',
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: const Color(0xFFAB50F6),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: _editState.videoEditState.speed,
                  min: 0.25,
                  max: 4.0,
                  divisions: 15,
                  label: '${_editState.videoEditState.speed}x',
                  onChanged: (v) {
                    final speed = double.parse(v.toStringAsFixed(2));
                    setState(() => _editState.videoEditState.speed = speed);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final s in [0.25, 0.5, 1.0, 1.5, 2.0, 4.0])
                      _speedChip(s),
                  ],
                ),
              ),
            ],
          ),
        );

      case ActiveEditor.videoFlip:
        return _videoPanelWrapper(
          icon: Icons.flip,
          title: 'Flip',
          subtitle: _editState.videoEditState.flipDirection,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _flipButton(Icons.swap_horiz, 'Horizontal', 'horizontal'),
              SizedBox(width: 40.w),
              _flipButton(Icons.swap_vert, 'Vertical', 'vertical'),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _videoCropButton(String label, double? ratio) {
    final isActive = _veditorController?.preferredCropAspectRatio == ratio;
    return GestureDetector(
      onTap: () {
        final vc = _veditorController;
        if (vc == null) return;
        setState(() {
          vc.preferredCropAspectRatio = ratio;
          // Force crop to use the new ratio
          if (ratio != null) {
            // Calculate centered crop box for this ratio
            final videoAr = vc.video.value.aspectRatio;
            double minX, minY, maxX, maxY;
            if (ratio >= videoAr) {
              // Ratio is wider than video — crop top/bottom
              final newHeight = videoAr / ratio;
              final padding = (1.0 - newHeight) / 2;
              minX = 0;
              maxX = 1;
              minY = padding;
              maxY = 1 - padding;
            } else {
              // Ratio is taller than video — crop left/right
              final newWidth = ratio / videoAr;
              final padding = (1.0 - newWidth) / 2;
              minX = padding;
              maxX = 1 - padding;
              minY = 0;
              maxY = 1;
            }
            vc.updateCrop(Offset(minX, minY), Offset(maxX, maxY));
          } else {
            // Free: reset to full frame
            vc.updateCrop(const Offset(0, 0), const Offset(1, 1));
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFFAB50F6).withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive ? const Color(0xFFAB50F6) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSans(
            color: isActive ? const Color(0xFFAB50F6) : Colors.white54,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _rotateButton(IconData icon, String label, RotateDirection direction) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _veditorController?.rotate90Degrees(direction);
          final cur = _editState.videoEditState.rotation;
          _editState.videoEditState.rotation =
              direction == RotateDirection.right
                  ? (cur + 90) % 360
                  : (cur + 270) % 360;
        });
      },
      child: _actionCircleButton(icon, label),
    );
  }

  Widget _flipButton(IconData icon, String label, String direction) {
    final isActive = _editState.videoEditState.flipDirection == direction;
    return GestureDetector(
      onTap: () {
        setState(() {
          _editState.videoEditState.flipDirection = isActive ? null : direction;
        });
      },
      child: _actionCircleButton(icon, label, isActive: isActive),
    );
  }

  Widget _speedChip(double value) {
    final isActive = (_editState.videoEditState.speed - value).abs() < 0.01;
    return GestureDetector(
      onTap: () => setState(() => _editState.videoEditState.speed = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFFAB50F6).withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive ? const Color(0xFFAB50F6) : Colors.white12,
          ),
        ),
        child: Text(
          '${value}x',
          style: GoogleFonts.notoSans(
            color: isActive ? const Color(0xFFAB50F6) : Colors.white54,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _actionCircleButton(
    IconData icon,
    String label, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color(0xFFAB50F6).withValues(alpha: 0.3)
                    : const Color(0xFFAB50F6).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isActive
                      ? const Color(0xFFAB50F6)
                      : const Color(0xFFAB50F6).withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 26.sp),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: isActive ? const Color(0xFFAB50F6) : Colors.white54,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  // Format a trim duration: seconds with one decimal under a minute
  // (e.g. "4.2s"), mm:ss otherwise (e.g. "1:05").
  String _formatTrimDuration(Duration d) {
    final ms = d.inMilliseconds.clamp(0, 1 << 31);
    if (ms < 60000) {
      return '${(ms / 1000).toStringAsFixed(1)}s';
    }
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _videoPanelWrapper({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onDone,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: Color(0xff1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFAB50F6), size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    title,
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAB50F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.notoSans(
                          color: const Color(0xFFAB50F6),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: onDone ?? () => _setActiveEditor(ActiveEditor.none),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFAB50F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 18.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  // ================= WIDGET HELPERS =================
  Widget _buildVideoCanvas() {
    final vc = _veditorController;
    if (vc == null || !vc.initialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: const [0.0, 0.6],
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
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isCropMode = _activeEditor == ActiveEditor.videoCrop;
    final isEditing = [
      ActiveEditor.videoTrim,
      ActiveEditor.videoCrop,
      ActiveEditor.videoRotate,
      ActiveEditor.videoSpeed,
      ActiveEditor.videoFlip,
    ].contains(_activeEditor);

    final hasEditedPreview =
        _editedVideoController != null &&
        _editedVideoController!.value.isInitialized &&
        !isEditing;
    final activePlayer = hasEditedPreview ? _editedVideoController! : vc.video;

    // Check if crop has been applied (not full frame)
    final bool hasCrop =
        vc.minCrop != const Offset(0, 0) || vc.maxCrop != const Offset(1, 1);

    // Default preview = media_kit only. Keep video_editor's player (vc.video)
    // paused here so we don't get DOUBLE playback (its progress bar was running
    // independently and stalling at ~1s); it's used only when actually editing.
    final bool showDefaultPreview =
        !isCropMode && !hasEditedPreview && !hasCrop;
    if (_mkPlayer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = _mkPlayer;
        if (p == null) return;
        final playing = p.state.playing;
        if (showDefaultPreview) {
          if (_mkPlaying && !playing) p.play();
          // NOTE: do NOT pause _veditorController.video here. It's already kept
          // paused+muted in _initVideo; pausing it every frame fought with
          // video_editor's auto-loop and froze the UI on re-entry.
        } else if (playing) {
          p.pause();
        }
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isCropMode)
          CropGridViewer.edit(controller: vc)
        else if (hasEditedPreview)
          GestureDetector(
            onTap: _toggleVideoPlayback,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _editedVideoController!.value.size.width,
                  height: _editedVideoController!.value.size.height,
                  child: VideoPlayer(_editedVideoController!),
                ),
              ),
            ),
          )
        else if (hasCrop)
          // Show cropped preview with black background (letterboxed)
          GestureDetector(
            onTap: _toggleVideoPlayback,
            child: Container(
              color: Colors.black,
              child: Center(child: CropGridViewer.preview(controller: vc)),
            ),
          )
        else if (_mkReady && _mkController != null)
          // Default preview via media_kit — plays/loops reliably (incl. HDR on
          // iPhone 14); video_editor's video_player stalled after ~1s.
          GestureDetector(
            onTap: _toggleMkPreview,
            child: SizedBox.expand(
              child: mkv.Video(
                controller: _mkController!,
                fit: BoxFit.cover,
                controls: mkv.NoVideoControls,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: _toggleVideoPlayback,

            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: vc.video.value.size.width,
                  height: vc.video.value.size.height,
                  child: VideoPlayer(vc.video),
                ),
              ),
            ),
          ),

        // Play overlay — when the media_kit preview is active, reflect its state.
        if ((_mkReady && _mkController != null
                ? !_mkPlaying
                : !_isVideoPlaying) &&
            !isCropMode)
          Center(
            child: GestureDetector(
              onTap:
                  (_mkReady && _mkController != null)
                      ? _toggleMkPreview
                      : _toggleVideoPlayback,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            ),
          ),

        if (!isCropMode &&
            showDefaultPreview &&
            _mkReady &&
            _mkController != null)
          _buildMkProgressBar()
        else if (!isCropMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 70.h,
            child: ValueListenableBuilder(
              valueListenable: activePlayer,
              builder: (context, VideoPlayerValue value, child) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleVideoPlayback,
                        child: Icon(
                          _isVideoPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Builder(
                        builder: (_) {
                          final spd = _editState.videoEditState.speed;
                          final pos = Duration(
                            milliseconds:
                                (value.position.inMilliseconds / spd).round(),
                          );
                          return Text(
                            _formatDuration(pos),
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: VideoProgressIndicator(
                            activePlayer,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFAB50F6),
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Builder(
                        builder: (_) {
                          final spd = _editState.videoEditState.speed;
                          final dur = Duration(
                            milliseconds:
                                (value.duration.inMilliseconds / spd).round(),
                          );
                          return Text(
                            _formatDuration(dur),
                            style: GoogleFonts.notoSans(
                              color: Colors.white70,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 6.w),
                      if (_editState.videoEditState.hasSpeed)
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Text(
                            '${_editState.videoEditState.speed}x',
                            style: GoogleFonts.notoSans(
                              color: const Color(0xFFAB50F6),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Icon(Icons.loop, color: Colors.white38, size: 14.sp),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => _saveOptionsSheet(controller),
            );
          },
          child: UnconstrainedBox(
            child: SvgPicture.asset(
              "assets/svg/icons/saveButton_icon.svg",
              height: 45,
              width: 45,

              // fit: BoxFit.scaleDown,
            ),
          ),
        ),

        Obx(
          () => GestureDetector(
            onTap:
                isUploadingStory.value
                    ? null
                    : () async => _exportAndUpload(postToStory: true),
            child: Opacity(
              opacity: isUploadingStory.value ? 0.85 : 1.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color:
                      controller.isSelecteds.value
                          ? const Color(0xff202122)
                          : const Color(0xff6677FC),
                  borderRadius: BorderRadius.circular(23.sp),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    controller.isSelecteds.value
                        ? CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xff323434),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              width: 30.h,
                              height: 30.w,
                              alignment: Alignment.topCenter,
                              imageUrl: widget.profileImage,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const ShimmerPlaceholder(),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.person),
                            ),
                          ),
                        )
                        : Container(
                          width: 23.w,
                          height: 23.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2.w,
                              color: const Color(0xffFFFFFF),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 15.sp,
                            color: const Color(0xffFFFFFF),
                          ),
                        ),
                    SizedBox(width: 10.w),
                    if (isUploadingStory.value)
                      SizedBox(
                        height: 23.w,
                        width: 23.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        "Story",
                        style: TextStyle(
                          color: const Color(0xffFFFFFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Flexible(
          child: GestureDetector(
            onTap:
                widget.snapChatId > 0
                    ? _sendSnapToFriend
                    : () async {
                      try {
                        final path = await _exportFinalPath();
                        Get.toNamed(
                          Routes.sendSubmitchallange,
                          arguments: {
                            "isVideo": widget.isVideo,
                            "filePath": path,
                            "place": widget.placeData,
                            "categoryKey": widget.categoryKey,
                          },
                        );
                      } catch (e) {
                        AppSnackbar.error("$e");
                      }
                    },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.btnGradientLeft,
                    AppColors.btnGradientRight,
                  ],
                ),
                borderRadius: BorderRadius.circular(23.sp),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.snapChatId > 0
                          ? (_snapName.isEmpty ? "Send" : "Send to $_snapName")
                          : "Send or Submit",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Obx(
                    () =>
                        _isSendingSnap.value
                            ? SizedBox(
                              height: 22,
                              width: 22,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : UnconstrainedBox(
                              child: SvgPicture.asset(
                                "assets/svg/icons/send_icon.svg",
                                height: 22,
                                width: 22,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Save the currently edited photo/video to the user's Profile or Vault.
  /// The backend `/stories/{profile,vault}` endpoints require a PUBLIC http(s)
  /// URL, so the exported file must be uploaded to S3 first (postToStory:false =
  /// upload-only) and its returned `fileUrl` passed as `imageUrl`. The old code
  /// sent the raw device path, which the backend rejected with 400 — surfaced
  /// to the user as a misleading "Already saved" while nothing was saved.
  Future<void> _uploadThenSave({required bool toVault}) async {
    try {
      final path = await _exportFinalPath();
      final type = widget.isVideo ? "VIDEO" : "IMAGE";

      final uploadRes = await ApiService.sendCapture(
        file: File(path),
        type: type,
        postToStory: false,
      );
      if (uploadRes.statusCode != 200) {
        AppToast.error("Upload failed (${uploadRes.statusCode})");
        return;
      }
      final fileUrl = (jsonDecode(uploadRes.body)['fileUrl'] ?? '').toString();
      if (!fileUrl.startsWith('http')) {
        AppToast.error("Upload failed");
        return;
      }

      final body = {"imageUrl": fileUrl, "type": type};
      final response =
          toVault
              ? await ApiService.storieSaveVault(body)
              : await ApiService.storieSaveProfile(body);

      if (response.statusCode == 200) {
        AppToast.success(toVault ? "Saved to Vault" : "Saved to Profile");
      } else if (response.statusCode == 400) {
        AppToast.info("Already saved");
      } else {
        AppToast.error("Failed: ${response.statusCode}");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  Widget _saveOptionsSheet(CamerascreenController controller) {
    final options = ["Save to Profile", "Save to Vault", "Save to Camera Roll"];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 36.w),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xff202122),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Save Photo",
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              fontSize: 10.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, thickness: 0.6, color: Colors.black),
          SizedBox(
            height: 140.h,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder:
                  (_, __) => const Divider(
                    height: 1,
                    thickness: 0.6,
                    color: Colors.black,
                  ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    if (options[index] == "Save to Profile") {
                      await _uploadThenSave(toVault: false);
                    } else if (options[index] == "Save to Vault") {
                      await _uploadThenSave(toVault: true);
                    } else if (options[index] == "Save to Camera Roll") {
                      try {
                        await _saveToCameraRollTapped();
                      } catch (e) {
                        AppSnackbar.error("Something went wrong: $e");
                      }
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 46.h,
                    child: Text(
                      options[index],
                      style: GoogleFonts.notoSans(
                        color: const Color(0xffC574F7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Region selection painter for pixelate/blur
class _RegionSelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isPixelate;

  _RegionSelectionPainter({
    required this.start,
    required this.end,
    required this.isPixelate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    final paint =
        Paint()
          ..color = (isPixelate ? Colors.orange : Colors.blue).withOpacity(0.3)
          ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    final borderPaint =
        Paint()
          ..color = isPixelate ? Colors.orange : Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RegionSelectionPainter old) =>
      old.start != start || old.end != end;
}

class _EmojiGestureWidget extends StatefulWidget {
  final String emoji;
  final double scale;
  final VoidCallback onDelete;
  final void Function(Offset delta, double newScale) onUpdate;
  final void Function(bool hovering) onDragOverDelete;

  const _EmojiGestureWidget({
    required this.emoji,
    required this.scale,
    required this.onDelete,
    required this.onUpdate,
    required this.onDragOverDelete,
  });

  @override
  State<_EmojiGestureWidget> createState() => _EmojiGestureWidgetState();
}

class _EmojiGestureWidgetState extends State<_EmojiGestureWidget> {
  double _baseScale = 1.0;
  bool _isDragging = false;
  bool _wasOverDelete = false;

  bool _isOverDeleteZone(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    return globalPos.dy > screenHeight - 150;
  }

  @override
  Widget build(BuildContext context) {
    final size = (40 * widget.scale).sp;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (_) {
        _baseScale = widget.scale;
        _isDragging = true;
        _wasOverDelete = false;
        widget.onDragOverDelete(false);
      },
      onScaleUpdate: (details) {
        final newScale = (_baseScale * details.scale).clamp(0.3, 6.0);
        widget.onUpdate(details.focalPointDelta, newScale);

        final over = _isOverDeleteZone(context);
        if (over && !_wasOverDelete) {
          HapticFeedback.mediumImpact();
        }
        _wasOverDelete = over;
        widget.onDragOverDelete(over);
      },
      onScaleEnd: (_) {
        if (_isDragging && _wasOverDelete) {
          HapticFeedback.heavyImpact();
          widget.onDelete();
        }
        _isDragging = false;
        _wasOverDelete = false;
        widget.onDragOverDelete(false);
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(widget.emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }
}

class _TextGestureWidget extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double opacity;
  final String fontFamily;
  final TextStyle Function(
    String fontFamily, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  })
  getTextStyle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(Offset delta, double newFontSize) onUpdate;
  final void Function(bool hovering) onDragOverDelete;

  const _TextGestureWidget({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.opacity,
    required this.fontFamily,
    required this.getTextStyle,
    required this.onTap,
    required this.onDelete,
    required this.onUpdate,
    required this.onDragOverDelete,
  });

  @override
  State<_TextGestureWidget> createState() => _TextGestureWidgetState();
}

class _TextGestureWidgetState extends State<_TextGestureWidget> {
  double _baseFontSize = 24.0;
  bool _isDragging = false;
  bool _wasOverDelete = false;
  int _pointerCount = 0;

  bool _isOverDeleteZone(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    return globalPos.dy > screenHeight - 150;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pointerCount++,
      onPointerUp: (_) => _pointerCount = (_pointerCount - 1).clamp(0, 10),
      onPointerCancel: (_) => _pointerCount = (_pointerCount - 1).clamp(0, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_isDragging) widget.onTap();
        },
        onScaleStart: (_) {
          _baseFontSize = widget.fontSize;
          _isDragging = true;
          _wasOverDelete = false;
          widget.onDragOverDelete(false);
        },
        onScaleUpdate: (details) {
          final newFontSize = (_baseFontSize * details.scale).clamp(
            10.0,
            100.0,
          );
          widget.onUpdate(details.focalPointDelta, newFontSize);

          final over = _isOverDeleteZone(context);
          if (over && !_wasOverDelete) {
            HapticFeedback.mediumImpact();
          }
          _wasOverDelete = over;
          widget.onDragOverDelete(over);
        },
        onScaleEnd: (_) {
          if (_isDragging && _wasOverDelete) {
            HapticFeedback.heavyImpact();
            widget.onDelete();
          }
          _isDragging = false;
          _wasOverDelete = false;
          widget.onDragOverDelete(false);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Opacity(
            opacity: widget.opacity,
            child: Text(
              widget.text,
              style: widget.getTextStyle(
                widget.fontFamily,
                color: widget.color,
                fontSize: widget.fontSize.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drag-to-delete wrapper for text layers and other overlays
class _DraggableLayerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final void Function(Offset delta) onMove;
  final VoidCallback onDelete;
  final void Function(bool hovering) onDragOverDelete;

  const _DraggableLayerWidget({
    required this.child,
    this.onTap,
    required this.onMove,
    required this.onDelete,
    required this.onDragOverDelete,
  });

  @override
  State<_DraggableLayerWidget> createState() => _DraggableLayerWidgetState();
}

class _DraggableLayerWidgetState extends State<_DraggableLayerWidget> {
  bool _isDragging = false;
  bool _wasOverDelete = false;

  bool _isOverDeleteZone(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    return globalPos.dy > screenHeight - 150;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onScaleStart: (_) {
        _isDragging = true;
        _wasOverDelete = false;
        widget.onDragOverDelete(false);
      },
      onScaleUpdate: (details) {
        widget.onMove(details.focalPointDelta);

        final over = _isOverDeleteZone(context);
        if (over && !_wasOverDelete) {
          HapticFeedback.mediumImpact();
        }
        _wasOverDelete = over;
        widget.onDragOverDelete(over);
      },
      onScaleEnd: (_) {
        if (_isDragging && _wasOverDelete) {
          HapticFeedback.heavyImpact();
          widget.onDelete();
        }
        _isDragging = false;
        _wasOverDelete = false;
        widget.onDragOverDelete(false);
      },
      child: widget.child,
    );
  }
}
