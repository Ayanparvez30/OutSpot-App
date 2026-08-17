import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:outspot/Network_Manager/video_cache_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';

import '../../Utils/routes.dart';

class CamerascreenController extends GetxController
    with GetTickerProviderStateMixin {
  // late CameraController cameraController;
  late Future<void> initializeControllerFuture;
  int get storyCount => userStories.length;
  String? currentUserId;

  bool get isMyCurrentStory {
    if (userStories.isEmpty || currentUserId == null) return false;

    // story.userId অথবা story.user.id দুইভাবেই আসতে পারে
    final storyOwnerId = userStories[currentIndex.value].user.id.toString();
    return storyOwnerId == currentUserId;
  }

  RxList<StoryModel> userStories = <StoryModel>[].obs;
  RxInt currentIndex = 0.obs;

  // Community story pagination (when the viewer was opened for a community).
  int? _communityId;
  int _communityPage = 1;
  bool _communityHasMore = false;
  bool _communityLoadingMore = false;

  String get currentMediaUrl =>
      userStories.isEmpty ? '' : userStories[currentIndex.value].mediaUrl;
  String? get currentAvatar {
    if (userStories.isEmpty) return null;
    final url = userStories[currentIndex.value].user.avatarUrl;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  String get currentFirstName =>
      userStories.isEmpty
          ? ''
          : userStories[currentIndex.value].user.firstName ?? '';
  String get currentLastName =>
      userStories.isEmpty
          ? ''
          : userStories[currentIndex.value].user.lastName ?? '';
  DateTime get currentCreatedAt =>
      userStories.isEmpty
          ? DateTime.now()
          : userStories[currentIndex.value].createdAt;
  final RxBool isCapturing = false.obs;
  late AnimationController rotationController;

  late List<CameraDescription> cameras;

  int selectedCameraIdx = 0;

  final RxBool isCameraReady = false.obs;

  final Rx<Color> borderColor = Colors.white.obs;
  RxBool isSelecteds = true.obs;

  final mediaUrl = ''.obs;
  final avatarUrl = RxnString();
  final firstName = ''.obs;
  final lastName = ''.obs;
  final postTime = ''.obs;
  @override
  void onInit() async {
    super.onInit();
    rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _initStoryProgress();

    final args = Get.arguments;

    // Set our own id up-front so isMyCurrentStory is correct on the FIRST
    // bottom-sheet open. loadUserProfile() sets it too, but only after a network
    // round-trip — so the first open of your OWN story used to show the friend
    // options. Prefer the id passed in args, then the locally cached id.
    if (args is Map && args["currentUserId"] != null) {
      currentUserId = args["currentUserId"].toString();
    } else {
      final cachedId = await UserPreference.getUserId();
      if (cachedId != null && cachedId != 0) {
        currentUserId = cachedId.toString();
      }
    }

    loadUserProfile();

    if (args != null && args["stories"] != null) {
      final list = List<StoryModel>.from(args["stories"]);

      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return -1;
        if (bt == null) return 1;
        return at.compareTo(bt);
      });

      userStories.value = list;

      currentIndex.value = args["startIndex"] ?? 0;

      // Community context → enable story pagination in the viewer.
      final cid = args["communityId"];
      if (cid != null) {
        _communityId = (cid is int) ? cid : int.tryParse('$cid');
        _communityPage =
            (args["communityPage"] is int) ? args["communityPage"] : 1;
        _communityHasMore = args["communityHasMore"] == true;
      }

      await _prepareCurrentAndStartTimer();
    }
  }

  /// Load the next page of a community's stories and append them to the viewer.
  Future<void> _loadMoreCommunityStories() async {
    if (_communityId == null ||
        !_communityHasMore ||
        _communityLoadingMore) {
      return;
    }
    _communityLoadingMore = true;
    try {
      final next = _communityPage + 1;
      final res = await ApiService.fetchStoriesFeed(
        filter: 'all',
        bucket: 'community',
        communityId: _communityId,
        page: next,
        pageSize: 20,
      );
      if (res.statusCode == 200) {
        final j = (jsonDecode(res.body) as Map).cast<String, dynamic>();
        final more =
            (j['stories'] as List? ?? const [])
                .map(
                  (e) =>
                      StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList();
        if (more.isNotEmpty) userStories.addAll(more);
        _communityPage = (j['page'] is int) ? j['page'] : next;
        _communityHasMore = j['hasMore'] == true;
      }
    } catch (e) {
      log("loadMoreCommunityStories error: $e");
    } finally {
      _communityLoadingMore = false;
    }
  }

  Timer? storyTimer;
  static const int storyDurationSeconds = 15;
  late AnimationController storyProgressController;
  bool _storyProgressInitialized = false;

  void _initStoryProgress() {
    if (_storyProgressInitialized) return;
    storyProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: storyDurationSeconds),
    );
    _storyProgressInitialized = true;
  }

  bool isMyStory(StoryModel story) {
    if (currentUserId == null) return false;
    return story.userId.toString() == currentUserId;
  }

  void startStoryTimer() {
    stopStoryTimer();
    _initStoryProgress();
    storyProgressController.duration =
        const Duration(seconds: storyDurationSeconds);
    storyProgressController.value = 0.0;
    storyProgressController.forward();
    storyTimer = Timer(Duration(seconds: storyDurationSeconds), () {
      nextStory();
    });
  }

  void stopStoryTimer() {
    storyTimer?.cancel();
    _cancelVideoSubs();
    if (_storyProgressInitialized) {
      storyProgressController.stop();
      storyProgressController.value = 0.0;
    }
  }

  final RxList<FriendsModel> friends = <FriendsModel>[].obs;

  FriendsModel? findFriendById(int id) {
    try {
      return friends.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  // Story.user → FriendsModel (fallback-builder)
  FriendsModel buildFriendFromStoryUser(StoryUser u) {
    return FriendsModel(
      id: u.id ?? 0,
      username: u.username ?? '',
      firstName: u.firstName ?? '',
      lastName: u.lastName ?? '',
      avatarUrl: u.avatarUrl ?? '',
      totalPoints: 0,
      thisWeekPoints: 0,
      profileUrl: '',
    );
  }

  Future<void> _waitForImageReady(String url) async {
    final completer = Completer<void>();
    final provider = CachedNetworkImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (image, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );

    stream.addListener(listener);

    await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );
  }

  Future<void> _prepareCurrentAndStartTimer() async {
    stopStoryTimer();
    if (userStories.isEmpty) return;

    final gen = _navGeneration;
    final current = userStories[currentIndex.value];

    if (_isVideoType(current.type)) {
      await initVideoController(current.mediaUrl);
      if (_navGeneration != gen) return; // user already tapped next

      // Wait for video to actually start playing, then start timer
      _waitForVideoAndStartTimer(gen);
    } else {
      await _waitForImageReady(current.mediaUrl);
      if (_navGeneration != gen) return;
      startStoryTimer();
    }
  }

  /// Waits for video to play, then starts timer. User can skip anytime via tap.
  StreamSubscription? _videoPositionSub;
  StreamSubscription? _videoCompleteSub;
  StreamSubscription? _videoPlayingSub;

  void _waitForVideoAndStartTimer(int gen) {
    _cancelVideoSubs();

    final player = mkPlayer;
    if (player == null) return;

    _initStoryProgress();
    storyProgressController.value = 0.0;

    // Sync progress bar to video position (progress = position / duration)
    _videoPositionSub = player.stream.position.listen((pos) {
      if (_navGeneration != gen || mkPlayer != player) return;
      final dur = player.state.duration;
      if (dur.inMilliseconds > 0) {
        final progress = pos.inMilliseconds / dur.inMilliseconds;
        storyProgressController.value = progress.clamp(0.0, 1.0);
      }
    });

    // Auto-advance when video finishes (no looping)
    _videoCompleteSub = player.stream.completed.listen((completed) {
      if (_navGeneration != gen || mkPlayer != player) return;
      if (completed) {
        log('✅ Video ended, next story');
        nextStory();
      }
    });
  }

  void _cancelVideoSubs() {
    _videoPositionSub?.cancel();
    _videoCompleteSub?.cancel();
    _videoPlayingSub?.cancel();
    _videoPositionSub = null;
    _videoCompleteSub = null;
    _videoPlayingSub = null;
  }


  int _navGeneration = 0;

  Future<void> nextStory() async {
    if (userStories.isEmpty) return;

    // Nearing the end of a community's stories → pull the next page so the user
    // can keep swiping (waits for it before deciding to close at the end).
    if (_communityHasMore &&
        !_communityLoadingMore &&
        currentIndex.value >= userStories.length - 2) {
      await _loadMoreCommunityStories();
    }

    if (currentIndex.value < userStories.length - 1) {
      _navGeneration++;
      final gen = _navGeneration;
      stopStoryTimer();
      await _disposeVideo();
      currentIndex.value++;
      if (_navGeneration != gen) return; // interrupted by another nav
      await _prepareCurrentAndStartTimer();
    } else {
      Get.back();
    }
  }

  Future<void> previousStory() async {
    if (userStories.isEmpty) return;

    if (currentIndex.value > 0) {
      _navGeneration++;
      final gen = _navGeneration;
      stopStoryTimer();
      await _disposeVideo();
      currentIndex.value--;
      if (_navGeneration != gen) return;
      await _prepareCurrentAndStartTimer();
    }
  }

  bool _isVideoType(String? t) => (t ?? '').trim().toLowerCase() == 'video';

  void _restartStoryTimer() {
    stopStoryTimer();
    startStoryTimer();
  }

  // void _handleMediaType() {
  //   if (userStories.isEmpty) return;

  //   final current = userStories[currentIndex.value];

  //   if (_isVideoType(current.type)) {
  //     initVideoController(current.mediaUrl);
  //   } else {
  //     stopVideo();
  //   }
  // }
  Future<void> _handleMediaType() async {
    if (userStories.isEmpty) return;
    final current = userStories[currentIndex.value];
    if (_isVideoType(current.type)) {
      await initVideoController(current.mediaUrl);
    } else {
      stopVideo();
      await _waitForImageReady(current.mediaUrl);
    }
  }

  Future<void> saveCurrentStoryToProfile() async {
    try {
      final currentStory = userStories[currentIndex.value];

      final body = {"storyId": currentStory.id};

      final response = await ApiService.storieSaveProfile(body);

      if (response.statusCode == 200) {
        AppToast.success("Save to Profile");
        _refreshProfileIfRegistered();
      } else if (response.statusCode == 400) {
        AppToast.error("Image Already Saved");
      } else {
        AppSnackbar.error("Failed to save story: ${response.statusCode}");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  Future<void> saveCurrentStoryToVault() async {
    try {
      final currentStory = userStories[currentIndex.value];

      final body = {"storyId": currentStory.id};

      final response = await ApiService.storieSaveVault(body);

      if (response.statusCode == 200) {
        AppToast.success("Save to vault");
        _refreshProfileIfRegistered();
      } else if (response.statusCode == 400) {
        AppToast.error("Image Already Saved");
      } else {
        AppSnackbar.error("Failed to save to vault: ${response.statusCode}");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  void _refreshProfileIfRegistered() {
    try {
      final profileCtrl = Get.find<MyProfileController>();
      profileCtrl.getSavedStories();
      profileCtrl.fetchVaultStories(profileCtrl.userId);
    } catch (_) {}
  }

  Future<void> removeCurrentStory() async {
    try {
      final storyId = userStories[currentIndex.value].id;

      final response = await ApiService.storiesRemove(storyId);

      if (response.statusCode == 200) {
        userStories.removeAt(currentIndex.value);

        // Delete succeeded → drop this story from the Explore feed locally
        // (no full reload). Bubble disappears if its group becomes empty.
        if (Get.isRegistered<ExploreController>()) {
          Get.find<ExploreController>().removeStoryLocally(storyId);
        }
        // Also drop its marker from the Map in real time.
        if (Get.isRegistered<MapController>()) {
          Get.find<MapController>().removeStoryLocally(storyId);
        }

        if (userStories.isEmpty) {
          Get.back();
        } else if (currentIndex.value >= userStories.length) {
          currentIndex.value = userStories.length - 1;
        }
        AppToast.success("Story Removed");
      } else {
        AppSnackbar.error("Failed to remove story: ${response.statusCode}");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  void toggleSelection() {
    if (isSelecteds.value) {
      isSelecteds.value = false;
      isSelecteds.refresh();
    }
  }

  Future<void> captureImages() async {
    isCapturing.value = true;
    await rotationController.forward(from: 0);
    await Future.delayed(
      const Duration(milliseconds: 400),
    ); // Simulate camera delay
    isCapturing.value = false;
    rotationController.reset();
    // Here you can navigate to preview if you want
  }

  // --- media_kit player for story videos ---
  mk.Player? mkPlayer;
  mkv.VideoController? mkVideoController;
  RxBool isVideoInitialized = false.obs;
  RxInt videoGeneration = 0.obs;

  // Legacy video_player (kept for capturescreen local preview)
  VideoPlayerController? videoController;

  Future<void> initVideoController(String videoUrl) async {
    await _disposeVideo();

    isVideoInitialized.value = false;

    // Pause background caching while playing stories
    VideoCacheService.instance.pause();

    try {
      // Check cache first — play from local if available
      String playPath;
      final cachedPath = await VideoCacheService.instance.getCachedPath(videoUrl);
      if (cachedPath != null) {
        playPath = cachedPath;
        log('📁 From cache: $playPath');
      } else {
        // Not cached yet — download and cache
        log('⬇️ Downloading: $videoUrl');
        final file = await DefaultCacheManager().getSingleFile(videoUrl);
        playPath = file.path;
        log('📁 Cached: $playPath');
      }

      mkPlayer = mk.Player();
      mkVideoController = mkv.VideoController(mkPlayer!);
      mkPlayer!.setPlaylistMode(mk.PlaylistMode.none);
      await mkPlayer!.open(mk.Media(playPath));

      isVideoInitialized.value = true;
      videoGeneration.value++;
      log('✅ Video ready: $videoUrl');
    } catch (e) {
      log('❌ Video init failed: $e');
      isVideoInitialized.value = false;
    }
  }

  void stopVideo() {
    _disposeVideo();
  }

  Future<void> _disposeVideo() async {
    try {
      await mkPlayer?.stop();
      await mkPlayer?.dispose();
    } catch (_) {}
    mkPlayer = null;
    mkVideoController = null;
    isVideoInitialized.value = false;
  }

  final RxBool isSelected = false.obs;
  @override
  void onClose() {
    stopStoryTimer();
    stopVideo();
    if (_storyProgressInitialized) storyProgressController.dispose();
    rotationController.dispose();
    super.onClose();
  }

  void sharePost() {
    // Handle share logic
    print('Share Post');
    Get.back();
    shareText();
  }

  void saveToProfile() {
    Get.back();
    saveCurrentStoryToProfile();
    print('Saved to Profile');
  }

  void saveToVault() {
    Get.back();
    saveCurrentStoryToVault();
    print('Saved to Vault');
  }

  void saveToCameraRoll() {
    // Handle save to camera roll logic
    // Get.snackbar(
    //   "Not Implemented",
    //   "Save to Camera Roll not yet implemented.",
    //   backgroundColor: Colors.orange,
    //   colorText: Colors.white,
    // );
    saveToCameraRolls();
    print('Saved to Camera Roll');
  }

  void removePost() {
    Get.back();
    removeCurrentStory();
    print('Post Removed');
  }

  void shareText() {
    final currentStory = userStories[currentIndex.value];
    // Attribute to the actual story owner — this viewer also shows friends' /
    // community stories, so don't assume it's "my" story.
    final owner = currentStory.user;
    final fullName =
        '${owner.firstName ?? ''} ${owner.lastName ?? ''}'.trim();
    final displayName =
        fullName.isNotEmpty ? fullName : owner.username;
    final caption =
        isMyCurrentStory
            ? 'Check out my latest story on OutSpot!'
            : "Check out $displayName(@${owner.username})'s story on OutSpot!";
    // Share as a real image message (inline image), not a raw URL in the text.
    showSendToSheet(caption, imageUrl: currentStory.mediaUrl);
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];

        currentUserId = data["id"].toString();

        log("✅ Current User ID: $currentUserId");
      } else {
        log("❌ Server error: ${response.statusCode}");
        AppSnackbar.error("Server returned ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
    }
  }

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String _extFromUrl(String url, {required String fallback}) {
    try {
      final last = Uri.parse(url).pathSegments.last;
      final pure = last.split('?').first;
      final dot = pure.lastIndexOf('.');
      if (dot >= 0 && dot < pure.length - 1) {
        return pure.substring(dot).toLowerCase();
      }
    } catch (_) {}
    return fallback;
  }

  String _filenameForStory(int id, String url, {required bool isVideo}) {
    final ext = _extFromUrl(url, fallback: isVideo ? '.mp4' : '.jpg');
    return 'Outspot_${id}$ext';
  }

  Future<File> _downloadToCache(String url) =>
      DefaultCacheManager().getSingleFile(url);

  Future<void> saveToCameraRolls() async {
    Get.back();
    try {
      if (!_isMobile) {
        AppToast.warning("Gallery save works only on Android/iOS.");
        return;
      }

      final story = userStories[currentIndex.value];
      final url = story.mediaUrl;
      final isVideo = _isVideoType(story.type);

      final file = await _downloadToCache(url);
      final path = file.path;
      final name = _filenameForStory(story.id, url, isVideo: isVideo);

      bool saved = false;
      try {
        final has = await Gal.hasAccess().onError((_, __) => true);
        if (!has) {
          final ok = await Gal.requestAccess();
          if (!ok) throw 'perm_denied';
        }
        if (isVideo) {
          await Gal.putVideo(path, album: 'Outspot');
        } else {
          await Gal.putImage(path, album: 'Outspot');
        }
        saved = true;
      } catch (_) {
        final perm = await PhotoManager.requestPermissionExtend();
        if (!perm.isAuth) throw 'Permission denied';

        if (isVideo) {
          await PhotoManager.editor.saveVideo(
            File(path),
            title: name,

            relativePath: 'Pictures/Outspot',
          );
        } else {
          final bytes = await File(path).readAsBytes();
          await PhotoManager.editor.saveImage(
            bytes,
            filename: name,
            relativePath: 'Pictures/Outspot',
          );
        }
        saved = true;
      }

      if (saved) {
        AppToast.success("Saved to gallery");
      } else {
        AppToast.error("Failed to save to gallery.");
      }
    } catch (e) {
      AppSnackbar.error("Failed to save: $e");
      log("Failed to save: $e");
    }
  }
}
