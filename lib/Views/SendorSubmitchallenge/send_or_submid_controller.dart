import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/point_submit_Dialog.dart';
import 'package:outspot/Model/challenge_card_model.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Model/explore_place_model.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Challenges/ChallengeManager.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class SendorSubmidController extends GetxController {
  /// Set this before navigating to camera to auto-select a friend on send/submit screen.
  static int? preSelectedFriendId;

  // late....
  late final bool isVideo;
  late final String filePath;
  // textediting controller
  TextEditingController searchController = TextEditingController();
  // variables
  var filteredChatss = <ChatModel>[].obs;
  var issending = false.obs;
  var currentUserId = 0.obs;
  var visibleCount = 4.obs;
  var selectedIndexes = <int>[].obs;
  var selectindex = false.obs;
  var selectindex1 = false.obs;
  var isSubmitting = false.obs;
  var lastSubmission = <String, dynamic>{}.obs;
  var selectedChallengeId = 0.obs;
  var selectedChallenges = Rxn<ChallengeCardModel>();
  var searchText = ''.obs;
  var challenges = <ChallengeCardModel>[].obs;
  var totalpoints = 0.obs;
  var pointsFromSubmit = 0.obs;
  // final..
  final RxBool postToStory = false.obs;
  final RxList<int> selectedChatIds = <int>[].obs;
  final RxList<int> selectedUserIds = <int>[].obs;
  final RxList<int> selectedGroupIds = <int>[].obs;
  final RxnString avatarUrl = RxnString();
  // Rx
  RxInt myUserId = 0.obs;
  RxInt challengeId = 0.obs;
  RxString avatarurl = ''.obs;
  RxList minimeList = [].obs;
  RxList<ChatModel> chatss = <ChatModel>[].obs;
  Rxn<ExplorePlaceModel> targetPlace = Rxn<ExplorePlaceModel>();
  RxnString targetCategoryKey = RxnString();
  var isLoadingChats = true.obs;

  // Max acceptable GPS accuracy (metres) for a check-in. Beyond this the fix is
  // too imprecise to trust against a tight place radius, so we don't submit.
  static const double _kMaxSubmitAccuracyMeters = 50;

  // ── Submit-for-points cooldown (1 submission / rateLimit window) ──
  // canSubmitPoints=false → show a live "Try again in mm:ss" countdown instead
  // of the toggle. Server enforces the limit; this is UX only.
  final RxBool canSubmitPoints = true.obs;
  final RxInt submitCooldownSeconds = 0.obs;
  Timer? _cooldownTimer;

  /// "59:59" / "1:02:03" style remaining time.
  String get submitCooldownLabel {
    final s = submitCooldownSeconds.value;
    if (s <= 0) return '';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  /// Fetch the cooldown from the server and (re)start the countdown if active.
  /// Recomputed from the server's retryAfterSeconds on every screen open, so
  /// reopening/revisiting can't drift.
  Future<void> fetchSubmitPointsStatus() async {
    try {
      final res = await ApiService.getSubmitForPointsStatus();
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final bool can = data['canSubmit'] ?? true;
      final int retry =
          (data['retryAfterSeconds'] is num)
              ? (data['retryAfterSeconds'] as num).toInt()
              : 0;
      canSubmitPoints.value = can;
      if (!can && retry > 0) {
        _startCooldown(retry);
      } else {
        _cooldownTimer?.cancel();
        submitCooldownSeconds.value = 0;
        canSubmitPoints.value = true;
      }
    } catch (e) {
      log('⚠️ submit-for-points status error: $e');
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    submitCooldownSeconds.value = seconds;
    canSubmitPoints.value = false;
    // While on cooldown the option can't stay selected.
    selectindex.value = false;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (submitCooldownSeconds.value <= 1) {
        t.cancel();
        submitCooldownSeconds.value = 0;
        canSubmitPoints.value = true; // re-enable "Submit for Points"
      } else {
        submitCooldownSeconds.value--;
      }
    });
  }

  @override
  Future<void> onInit() async {
    super.onInit();

    // ⬇️ arguments safely read
    final args = (Get.arguments ?? <String, dynamic>{}) as Map<String, dynamic>;
    isVideo = (args['isVideo'] as bool?) ?? false;
    filePath = (args['filePath'] as String?) ?? '';
    log("it's file path ${filePath}");
    print("it's video ${isVideo}");

    // ✅ 2. Get 'Place' Data & Log
    if (args['place'] != null && args['place'] is ExplorePlaceModel) {
      targetPlace.value = args['place'];
      log("📍 Received Place Data:");
      log("   - Name: ${targetPlace.value!.name}");
      log("   - ID: ${targetPlace.value!.placeId}");
    } else {
      log("ℹ️ No specific place data received.");
    }
    // ✅ 3. Get 'CategoryKey' & Log
    if (args['categoryKey'] != null) {
      targetCategoryKey.value = args['categoryKey'];
      log("🔑 Received Category Key: ${targetCategoryKey.value}");
    } else {
      log("ℹ️ No category key received.");
    }
    if (targetPlace.value != null && targetCategoryKey.value != null) {
      selectindex.value = true;
      log("✅ Auto-selected 'Submit for Points' because place data exists.");
      // The "Submit for Points" option is visible → check the cooldown so we
      // can show a countdown (and disable it) when the user is rate-limited.
      fetchSubmitPointsStatus();
    } else {
      selectindex.value = false;
    }
    // loadUserProfile();
    // loadUserProfiles();
    await loadUserProfile();
    await loadUserProfiles();
    fetchChats().then((_) => _autoSelectPreSelectedFriend());
    filterChats('');
    fetchChallengeCards();
    ever<List<ChatModel>>(chatss, (_) => filterChats(searchController.text));
    ever<List<int>>(selectedChatIds, (_) => filterChats(searchController.text));
    final savedChallenge = ChallengeManager.instance.selectedChallenge.value;
    if (savedChallenge != null) {
      selectedChallenges.value = savedChallenge;
      challengeId.value = savedChallenge.id;
      selectindex1.value = true;

      log("Challenge loaded from Singleton: ${savedChallenge.title}");
    }
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    ChallengeManager.instance.clear();
    challengeId.value = 0;
    selectindex1.value = false;
    selectedChallenges.value = null;
    super.onClose();
  }

  void _autoSelectPreSelectedFriend() {
    final friendId = preSelectedFriendId;
    if (friendId == null) return;
    preSelectedFriendId = null; // clear after use

    for (final chat in chatss) {
      if (!chat.isGroup && !chat.isCommunity) {
        if (chat.users.any((u) => u.id == friendId)) {
          if (!selectedChatIds.contains(chat.id)) {
            selectedChatIds.add(chat.id);
            log("Auto-selected chat ${chat.id} for friend $friendId");
          }
          break;
        }
      }
    }
  }

  /// Returns true only when points were actually awarded. On failure it returns
  /// false. When [silentError] is true it records the reason in
  /// lastErrorTitle/lastErrorMessage instead of showing its own dialog, so the
  /// caller can show one combined dialog (mixed send flow).
  Future<bool> visitRecorded(
    ExplorePlaceModel place, {
    bool silentError = false,
    bool suppressSuccessDialog = false,
  }) async {
    try {
      AppLoading.show();
      // Fresh GPS fix (no 5-min cache) so the check-in uses where the user
      // ACTUALLY is right now.
      final Position? position = await LocationHelper.getCurrentPosition(
        forceRefresh: true,
      );
      if (position != null) {
        double lat = position.latitude;
        double lng = position.longitude;
        log(
          "📍 Current Location: $lat, $lng "
          "(±${position.accuracy.toStringAsFixed(0)}m, mocked=${position.isMocked})",
        );

        // Block spoofed / mock locations.
        if (position.isMocked) {
          AppLoading.hide();
          const t = "Location Looks Faked";
          const m =
              "Turn off any mock / location-spoofing apps and try again.";
          if (silentError) {
            lastErrorTitle = t;
            lastErrorMessage = m;
          } else {
            AppSnackbar.error(m, title: t);
          }
          return false;
        }

        // GPS too imprecise for a tight check-in radius — don't submit a wrong
        // spot. (A 20m radius is meaningless if the fix is ±100m.)
        if (position.accuracy > _kMaxSubmitAccuracyMeters) {
          AppLoading.hide();
          final t = "Weak GPS Signal";
          final m =
              "Your location isn't precise enough (±${position.accuracy.round()}m). "
              "Move to open sky and try again.";
          if (silentError) {
            lastErrorTitle = t;
            lastErrorMessage = m;
          } else {
            AppSnackbar.error(m, title: t);
          }
          return false;
        }

        return await recordVisit(
          place,
          lat,
          lng,
          silentError: silentError,
          suppressSuccessDialog: suppressSuccessDialog,
          accuracy: position.accuracy,
          isMocked: position.isMocked,
        );
      } else {
        AppLoading.hide();
        if (silentError) {
          lastErrorTitle = "Location Unavailable";
          lastErrorMessage = "Couldn't get your location. Please try again.";
        }
        return false;
      }
    } catch (e) {
      AppLoading.hide();
      log("❌ Error getting location: $e");
      if (silentError) {
        lastErrorTitle = "Location Error";
        lastErrorMessage = "Couldn't get your location. Please try again.";
      } else {
        AppSnackbar.error(e.toString(), title: "Location Error");
      }
      return false;
    }
  }

  Future<bool> recordVisit(
    ExplorePlaceModel place,
    double lat,
    double lng, {
    bool silentError = false,
    bool suppressSuccessDialog = false,
    double? accuracy,
    bool? isMocked,
  }) async {
    try {
      final response = await ApiService.recordVisit(
        placeId: place.placeId,
        name: place.name,
        latitude: lat,
        longitude: lng,
        categoryKey: targetCategoryKey.toString(),
        accuracy: accuracy,
        isMocked: isMocked,
        // Send the captured photo as check-in evidence. Skip for video captures
        // (admin evidence is shown as an image) and when no file is present.
        media: (!isVideo && filePath.isNotEmpty) ? File(filePath) : null,
      );

      log("📥 Response status: ${response.statusCode}");
      log("📦 Response body: ${response.body}");

      final data = json.decode(response.body);
      final bool awarded = data['awarded'] ?? false;
      final int points = data['points'] ?? 0;

      AppLoading.hide();

      // Rate-limited by the submission cooldown → show the live countdown.
      // Prefer the value carried on this response; otherwise re-sync from
      // /submit-for-points/status. (Previously a 429 fell through to a generic
      // "try again later" with no countdown.)
      final String rlReason = (data['reason'] ?? '').toString();
      if (response.statusCode == 429 ||
          rlReason == 'rate-limited' ||
          rlReason == 'cooldown') {
        final int retry =
            (data['retryAfterSeconds'] is num)
                ? (data['retryAfterSeconds'] as num).toInt()
                : 0;
        if (retry > 0) {
          _startCooldown(retry);
        } else {
          fetchSubmitPointsStatus();
        }
        final t = "Please Wait";
        final m =
            data['message'] ??
            "You're submitting too quickly. Try again shortly.";
        if (silentError) {
          lastErrorTitle = t;
          lastErrorMessage = m;
        } else {
          AppSnackbar.error(m, title: t);
        }
        return false;
      }

      if (awarded) {
        log("✅ Visit recorded and awarded $points points.");
        pointsFromSubmit.value = points;
        // Points just awarded → refresh the cooldown so the countdown starts.
        fetchSubmitPointsStatus();
        if (!suppressSuccessDialog) {
          PointSubmitDialog.showSuccess(
            imageUrl: place.photoUrl,
            points: points,
            Placename: place.name,
          );
        }
        return true;
      } else {
        final String reason = data['reason'] ?? '';
        log("❌ Not awarded. Reason: $reason");

        String title;
        String message;
        IconData icon;

        switch (reason) {
          case 'too-far-from-place':
            title = "You're Too Far Away";
            message =
                data['message'] ??
                "You need to be closer to this place to submit.";
            icon = Icons.location_off_outlined;
            break;
          case 'already-visited':
            title = "Already Visited";
            message =
                data['message'] ??
                "You have already submitted points for this place.";
            icon = Icons.info_outline;
            break;
          case 'duplicate-place-within-window':
            title = "Already Visited";
            message =
                data['message'] ?? "You've already earned points at this spot.";
            icon = Icons.info_outline;
            break;
          case 'duplicate-nearby-within-window':
            title = "Nearby Spot Already Visited";
            message =
                data['message'] ??
                "You've already earned points near this location.";
            icon = Icons.location_on_outlined;
            break;
          case 'place-closed':
            title = "Place Closed";
            message =
                data['message'] ?? "This place is closed right now.";
            icon = Icons.lock_clock;
            break;
          case 'mocked-location':
            title = "Location Looks Faked";
            message =
                data['message'] ??
                "Your location looks spoofed. Turn off any mock-location apps and try again.";
            icon = Icons.gpp_bad_outlined;
            break;
          case 'low-accuracy':
            title = "Weak GPS Signal";
            message =
                data['message'] ??
                "Your location isn't precise enough. Move to open sky and try again.";
            icon = Icons.gps_off_outlined;
            break;
          default:
            title = "Points Not Awarded";
            message =
                data['message'] ??
                "Could not award points for this place right now. Please try again later.";
            icon = Icons.info_outline;
        }

        if (silentError) {
          lastErrorTitle = title;
          lastErrorMessage = message;
        } else if (reason == 'too-far-from-place') {
          // Explore place check-in flow (explore → category → place → check-in).
          // The place screen is still in the back stack, so "Go Back" pops the
          // camera/capture routes straight back to it — no need to bounce out to
          // Explore. Non-dismissible + Android back routes the same way.
          await PointSubmitDialog.showFailed(
            title: title,
            message: message,
            icon: icon,
            iconColor: Colors.orangeAccent,
            backText: "Go Back",
            onBack: _goBackToPlaceDetails,
          );
        } else {
          await PointSubmitDialog.showFailed(
            title: title,
            message: message,
            icon: icon,
            iconColor: Colors.orangeAccent,
          );
        }
        return false;
      }
    } catch (e) {
      AppLoading.hide();
      log("❌ Error recording visit: $e");
      if (silentError) {
        lastErrorTitle = "Submission Failed";
        lastErrorMessage = "Something went wrong. Please try again.";
      } else {
        AppSnackbar.error("Something went wrong");
      }
      return false;
    }
  }

  /// Return to the place details screen still sitting in the back stack
  /// (explore → category → place → check-in), popping the camera/capture routes
  /// in between. Falls back to the root if that screen isn't found.
  void _goBackToPlaceDetails() {
    if (Get.isDialogOpen ?? false) Get.back();
    Get.until(
      (route) => route.settings.name == Routes.placeDetails || route.isFirst,
    );
  }

  // The last submission failure (captured silently so it can be shown inside
  // the combined "send to others?" dialog instead of as a separate popup).
  String lastErrorTitle = '';
  String lastErrorMessage = '';

  /// ONE combined dialog shown when a points/challenge submission fails in a
  /// mixed send: it states WHY it failed AND asks whether to still send the
  /// capture to the friends/story the user also selected. Returns the choice.
  Future<bool> confirmSendToOthers() async {
    final title =
        lastErrorTitle.isNotEmpty ? lastErrorTitle : "Couldn't submit";
    final reason =
        lastErrorMessage.isNotEmpty
            ? lastErrorMessage
            : "That submission didn't go through.";
    final res = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "$reason\n\nYou also chose to send this to friends / your story — "
          "do you still want to send it to them?",
          style: GoogleFonts.notoSans(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              "No",
              style: GoogleFonts.notoSans(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              "Yes, send",
              style: GoogleFonts.notoSans(
                color: const Color(0xffC574F7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return res ?? false;
  }

  Future<void> fetchChats() async {
    try {
      // EasyLoading.show(status: 'Loading chats...');
      isLoadingChats.value = true;
      final rawData = await ApiService.getAllChats();
      final chatList = rawData.map((e) => ChatModel.fromJson(e)).toList();

      // chatss.assignAll(chatList);
      // for (var chat in chatList) {
      //   if (chat.isGroup) {
      //     log("✅ Group Chat: ${chat.name ?? 'Unknown Group'}");
      //   } else if (chat.isCommunity) {
      //     log("✅ isCommunity Chat: ${chat.name ?? 'Unknown Group'}");
      //     final otherUser = chat.users.firstWhereOrNull(
      //       (user) => user.id != currentUserId.value,
      //     );
      //     if (otherUser == null) {
      //       log("✅ Direct Chat with: Unknown User");
      //     }
      //   }
      // }
      final validChats =
          chatList.where((chat) {
            if (chat.isGroup || chat.isCommunity) return true;
            final myId = currentUserId.value;
            final otherUser = chat.users.firstWhereOrNull((u) => u.id != myId);
            if (otherUser == null) return false;
            bool hasName =
                (otherUser.firstName?.trim().isNotEmpty ?? false) ||
                (otherUser.lastName?.trim().isNotEmpty ?? false) ||
                (otherUser.username?.trim().isNotEmpty ?? false);

            if (!hasName) return false;
            return true;
          }).toList();
      validChats.sort((a, b) {
        DateTime dateA =
            a.latestMessage != null
                ? DateTime.parse(a.latestMessage!.createdAt)
                : DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dateB =
            b.latestMessage != null
                ? DateTime.parse(b.latestMessage!.createdAt)
                : DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      // ডুপ্লিকেট রিমুভ করে চ্যাট লিস্টে অ্যাসাইন করা
      final uniqueValid = getUniqueChats(validChats);
      chatss.assignAll(uniqueValid);

      log("✅ চ্যাট ফিল্টার করা হয়েছে। টোটাল ভ্যালিড চ্যাট: ${chatss.length}");

      log("✅ Total chats loaded: ${chatList.length}");
    } catch (e) {
      log("❌ Error loading chats: $e");

      // EasyLoading.showError('Failed to load chats');
    } finally {
      // EasyLoading.dismiss();
      isLoadingChats.value = false;
    }
  }

  String getUserName(ChatModel chat) {
    final int meId =
        currentUserId.value is int
            ? currentUserId.value
            : int.tryParse('${currentUserId.value}') ?? -1;

    // 🔧 Compare with user.userId (not user.id)
    final otherUser = chat.users.firstWhereOrNull((u) => u.id != meId);

    if (otherUser == null) return 'Unknown User';

    final first = (otherUser.firstName ?? '').trim();
    final last = (otherUser.lastName ?? '').trim();
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');

    return full.isNotEmpty ? full : (otherUser.username ?? 'Unknown User');
  }

  List<ChatModel> getUniqueChats(List<ChatModel> chatList) {
    final seen = <String>{};
    final uniqueChats = <ChatModel>[];

    for (final chat in chatList) {
      String key;

      // ✅ ADDED: Handle Community Logic
      if (chat.isCommunity) {
        key = 'community:${chat.communityId ?? chat.id}';
      } else if (chat.isGroup) {
        key = 'group:${(chat.name ?? 'Unknown Group').toLowerCase()}';
      } else {
        final ids = chat.users.map((u) => u.id).toList()..sort();
        key = 'dm:${ids.join("-")}';
      }

      if (seen.add(key)) {
        uniqueChats.add(chat);
      }
    }
    return uniqueChats;
  }

  int? getFriendId(ChatModel chat) {
    if (chat.isGroup) return null;

    final otherUser = chat.users.firstWhere(
      (u) => u.id != currentUserId.value,
      orElse: () => chat.users.first,
    );

    return otherUser.id;
  }

  int? getGroupId(ChatModel chat) {
    return chat.isGroup ? chat.id : null;
  }

  String? getChatAvatar(ChatModel chat, int myUserId) {
    // ✅ ADDED: Check for isCommunity || isGroup
    if (chat.isGroup == true || chat.isCommunity == true) {
      return (chat.imageUrl != null && chat.imageUrl!.isNotEmpty)
          ? chat.imageUrl
          : null;
    } else {
      final otherUser = chat.users.firstWhere(
        (u) => u.id != myUserId,
        orElse:
            () =>
                chat.users.isNotEmpty
                    ? chat.users.first
                    : FriendsModel(
                      id: 0,
                      username: 'Unknown',
                      firstName: '',
                      lastName: '',
                      avatarUrl: '',
                      totalPoints: 0,
                      thisWeekPoints: 0,
                      profileUrl: '',
                    ),
      );
      return otherUser.avatarUrl.isNotEmpty ? otherUser.avatarUrl : null;
    }
  }

  void filterChats(String query) {
    final allChats = getUniqueChats(chatss);

    List<ChatModel> results;
    if (query.isEmpty) {
      results = List<ChatModel>.from(allChats);
    } else {
      results =
          allChats.where((chat) {
            final name =
                (chat.isGroup || chat.isCommunity)
                    ? (chat.name ?? 'Unknown')
                    : getUserName(chat);

            return name.toLowerCase().contains(query.toLowerCase());
          }).toList();
    }

    // Sort selected chats to the top
    results.sort((a, b) {
      final aSelected = selectedChatIds.contains(a.id) ? 0 : 1;
      final bSelected = selectedChatIds.contains(b.id) ? 0 : 1;
      return aSelected.compareTo(bSelected);
    });

    filteredChatss.assignAll(results);
  }

  Future<void> loadUserProfiles() async {
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

  Future<void> loadUserProfile() async {
    try {
      final r = await ApiService.fetchUserProfile();
      if (r.statusCode != 200) return log("❌ ${r.statusCode} | ${r.body}");

      final data =
          (json.decode(r.body)['data'] as Map?)?.cast<String, dynamic>();
      if (data == null) return log('❌ data null');

      final uid = int.tryParse('${data['id']}');
      if (uid == null) return log('❌ invalid id: ${data['id']}');
      currentUserId.value = uid;

      String? top = (data['avatarUrl'] as String?)?.trim();
      final m = data['minime'];
      String? mini =
          (m is List && m.isNotEmpty)
              ? (m.first['avatarUrl'] as String?)?.trim()
              : null;
      String? body = (data['bodyShapeUrl'] as String?)?.trim();

      avatarUrl.value =
          (top?.isNotEmpty == true)
              ? top
              : (mini?.isNotEmpty == true)
              ? mini
              : (body?.isNotEmpty == true)
              ? body
              : null;

      log("✅ id=$uid, avatar=${avatarUrl.value ?? '(none)'}");
    } catch (e, st) {
      log("❌ $e");
      log("$st");
    }
  }

  Future<void> fetchChallengeCards() async {
    try {
      final list = await ApiService.getChallengescards();

      challenges.value =
          list.map((e) => ChallengeCardModel.fromJson(e)).toList();

      log("✅ Raw challenges: ${jsonEncode(list)}");
    } catch (e) {
      log(" Exception: $e");
      AppSnackbar.error(e.toString());
    } finally {}
  }

  bool isChallengeComplete(ChallengeCardModel c) =>
      c.uploadedCount >= c.requiredCount;

  Future<void> handleChallengeSubmit(
    BuildContext context,
    ChallengeCardModel c,
  ) async {
    if (isChallengeComplete(c)) {
      totalpoints.value = c.points;
      await achivmentdialog(context);
      return;
    }
    totalpoints.value = c.points;
    await submitChallenge(context, c.id);
  }

  /// Returns true only when the challenge was accepted (HTTP 200). On failure it
  /// returns false. When [silentError] is true it does NOT show its own error
  /// dialog — instead it records the reason in lastErrorTitle/lastErrorMessage so
  /// the caller can show one combined dialog (used by the mixed send flow).
  Future<bool> submitChallenge(
    BuildContext context,
    int challengeid, {
    bool silentError = false,
    // When true (mixed send to friends/story/group), skip the full-screen
    // "Submission Complete!" dialog on success — the caller shows a snackbar
    // instead and navigates to the recipients.
    bool suppressSuccessDialog = false,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;

    _showVerifyingDialog();

    try {
      final result = await ApiService.challengeSubmit(
        challengeId: challengeid,
        filePath: filePath,
      );

      final statusCode = result['_statusCode'] as int? ?? 0;
      log(
        "📡 Challenge submit status: $statusCode, body: ${jsonEncode(result)}",
      );
      _closeVerifyingDialog();

      if (statusCode == 200) {
        lastSubmission.value = result;
        final awarded = result['pointsAwarded'] ?? 0;
        if (awarded > 0) totalpoints.value = awarded;
        log("🎯 Points awarded: $awarded");
        if (selectedChallenges.value != null) {
          selectedChallenges.value!.uploadedCount += 1;
          selectedChallenges.refresh();
        }

        await fetchChallengeCards();
        // EasyLoading.dismiss();
        if (!suppressSuccessDialog) {
          await achivmentdialog(context);
        }
        return true;
      } else if (statusCode == 400) {
        // EasyLoading.dismiss();
        final error = result['error'] ?? 'Submission rejected';
        final reason = result['reason'];
        if (silentError) {
          lastErrorTitle = "Submission Rejected";
          lastErrorMessage =
              (reason is String && reason.isNotEmpty) ? reason : error;
        } else {
          await _showRejectionDialog(context, error, reason);
        }
        return false;
      } else if (statusCode == 409) {
        // EasyLoading.dismiss();
        final error = result['error'] ?? 'Challenge already completed';
        if (silentError) {
          lastErrorTitle = "Already Completed";
          lastErrorMessage = error;
        } else {
          AppSnackbar.error(error);
        }
        return false;
      } else {
        // EasyLoading.dismiss();
        if (silentError) {
          lastErrorTitle = "Submission Failed";
          lastErrorMessage = "Server error ($statusCode). Please try again.";
        } else {
          AppSnackbar.error("Server error: $statusCode");
        }
        return false;
      }
    } catch (e, st) {
      _closeVerifyingDialog();

      log("Submission failed: $e");
      //  EasyLoading.dismiss();
      if (silentError) {
        lastErrorTitle = "Submission Failed";
        lastErrorMessage = "Something went wrong. Please try again.";
      } else {
        AppSnackbar.error(e.toString());
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showVerifyingDialog() {
    Get.dialog(
      PopScope(
        canPop: false, // back button not working
        child: Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Lottie.asset(
                      'assets/Images/loadingAnimation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
                Text(
                  "Verifying your submission...",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closeVerifyingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  Future<void> _showRejectionDialog(
    BuildContext context,
    String error,
    String? reason,
  ) {
    return Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "Rejection Dialog",
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 30.h),
                UnconstrainedBox(
                  child: SvgPicture.asset("assets/svg/warnin.svg"),
                ),
                SizedBox(height: 40.h),
                Text(
                  "Submission Rejected",
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),

                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 14.sp,
                    color: AppColors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                if (reason != null && reason.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      decoration: TextDecoration.none,
                      fontSize: 13.sp,
                      color: AppColors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],

                SizedBox(height: 25.h),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffF8AC00),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      "Try Again",
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 16.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void selectchallengeId(ChallengeCardModel c) {
    selectindex1.value = !selectindex1.value;

    if (selectindex1.value) {
      challengeId.value = c.id;
    } else {
      challengeId.value = 0;
    }
  }

  String formatTimeRemaining(int? ms) {
    if (ms == null) return '';
    if (ms <= 0) return '0s';

    final totalSec = ms ~/ 1000;
    final days = totalSec ~/ 86400;
    final hours = (totalSec % 86400) ~/ 3600;

    if (days > 0 && hours > 0) return '${days}d ${hours}h';
    if (days > 0) return '${days}d';
    if (hours > 0) return '${hours}h';

    final mins = (totalSec % 3600) ~/ 60;
    if (mins > 0) return '${mins}m';

    final secs = totalSec % 60;
    return '${secs}s';
  }

  Future<void> achivmentdialog(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Achievement",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned(
                  top: 50.h,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        Text(
                          "Submitted",
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Color(0xff967DFB),
                            size: 40.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: Color(0xff2D0731),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Image.asset(
                              "assets/Images/sksubmit.png",
                              width: double.infinity,
                              height: 200.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          Text(
                            "Submission Complete!",
                            style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),

                          
                          Obx(() {
                            final challenge = selectedChallenges.value;

                            bool isFull = false;
                            if (challenge != null) {
                              isFull =
                                  challenge.uploadedCount ==
                                  challenge.requiredCount;
                            }

                            final pts =
                                selectindex.value
                                    ? pointsFromSubmit.value
                                    : totalpoints.value;

                            if (pts <= 0) return const SizedBox.shrink();

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  
                                  isFull ? "You got" : "Complete to get",
                                  style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.white.withOpacity(0.7),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: AppColors.yellow),
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/Images/skcoin.png",
                                        width: 18,
                                        height: 18,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "$pts",
                                        style: GoogleFonts.notoSans(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),

                          SizedBox(height: 20.h),
                          CustomButton(
                            image: "assets/svg/icons/challengeTab_icon.svg",
                            text: "View Challenge",
                            gradient: LinearGradient(
                              colors: [AppColors.yellow, AppColors.yellow],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Get.offAllNamed(
                                Routes.mainscreen,
                                arguments: {"tab": 3},
                              );
                            },
                          ),
                          SizedBox(height: 16.h),

                          CustomButton(
                            image: "assets/svg/leaderboard/leaderboard.svg",
                            text: "View Leaderboard",
                            gradient: LinearGradient(
                              colors: [
                                AppColors.btnGradientLeft,
                                AppColors.btnGradientRight,
                              ],
                            ),
                            onPressed: () {
                              // Navigator.of(context).pop();
                              Get.toNamed(
                                Routes.leaderboardGlobal,
                                // arguments: {"from": "sendSubmitchallange"},
                              );
                            },
                          ),
                          SizedBox(height: 20.h),

                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Get.offAllNamed(
                                Routes.mainscreen,
                                arguments: {"tab": 2},
                              );
                            },
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios,
                                    size: 17.sp,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "Back to Camera",
                                    style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // কাস্টম বাটন উইজেট (ডিজাইন ক্লিন রাখার জন্য)
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              text,
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget CustomButton({
    required String image,
    required String text,
    required VoidCallback onPressed,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 45.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(image),
            SizedBox(width: 17.w),
            Text(
              text,
              style: GoogleFonts.notoSans(
                decoration: TextDecoration.none,
                fontSize: 16.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  Future<void> uploadCapturedFile({
    List<int>? chatIds,
    String? challengeId,
    bool postToStoryFlag = false,
    bool showLoading = true,
    VoidCallback? onSuccessNavigation,
  }) async {
    try {
      if (showLoading) {
        // EasyLoading.show(status: "Uploading...");
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
        postToStory: postToStoryFlag,
        latitude: latitude,
        longitude: longitude,
      );

      if (showLoading) AppLoading.hide();
      // EasyLoading.dismiss();

      if (response.statusCode == 200) {
        log("📦 Sending media to chatIds => $chatIds");
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

  Future<String> getPlaceName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return "";

      final p = placemarks.first;

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
      return "";
    }
  }

  Future<void> submitFileForPoints({
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
        placeId: targetPlace.value?.placeId,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool awarded = data['awarded'] ?? true;

        if (awarded) {
          log("✅ Submit for points success: ${response.body}");
          pointsFromSubmit.value = data['points'] ?? 0;
          log("💰 Points received: ${pointsFromSubmit.value}");
          // Points just awarded → refresh cooldown so the countdown starts.
          fetchSubmitPointsStatus();
          onSuccessNavigation?.call();
        } else {
          final String reason = data['reason'] ?? '';
          log("❌ Not awarded. Reason: $reason");

          String title;
          String message;
          IconData icon;

          switch (reason) {
            case 'too-far-from-place':
              title = "You're Too Far Away";
              message =
                  data['message'] ??
                  "You need to be closer to this place to submit.";
              icon = Icons.location_off_outlined;
              break;
            case 'duplicate-place-within-window':
            case 'already-visited':
              title = "Already Visited";
              message =
                  data['message'] ??
                  "You've already earned points at this spot.";
              icon = Icons.info_outline;
              break;
            case 'duplicate-nearby-within-window':
              title = "Nearby Spot Already Visited";
              message =
                  data['message'] ??
                  "You've already earned points near this location.";
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
}
