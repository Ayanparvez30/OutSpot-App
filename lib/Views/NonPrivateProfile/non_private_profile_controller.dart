import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/FriendsProfile/friendsFriends.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/SettingScreen/setting_controller.dart';
import 'package:outspot/Utils/share_helper.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class NonPrivateProfileController extends GetxController {
  RxBool isPrivate = false.obs;
  var communities = <dynamic>[].obs;
  var mediaUrl = ''.obs;
  // Viewed user's bio — shown below the points (visible for everyone).
  var bio = ''.obs;
  var friendCount = 0.obs;
  var hasIncomingRequest = false.obs;
  late FriendsModel friend1;

  // lists
  var friends1 = <FriendsModel>[].obs; // current friends (local cache)
  RxList<FriendsModel> requests = <FriendsModel>[].obs; // incoming
  RxList<FriendsModel> sentRequests = <FriendsModel>[].obs; // sent

  // flags
  RxBool isRequested = false.obs;
  RxBool isFriend = false.obs;
  // Button-level loading for friend actions (send/cancel/accept/decline).
  // Drives ONLY the action button's spinner — must NOT blank the whole screen.
  RxBool isLoading = false.obs;
  // Initial profile-fetch loading — gates the whole screen (shows the loader
  // until the viewed user's data is ready).
  RxBool isProfileLoading = true.obs;

  // stories
  RxList<StoryModel> savedStories = <StoryModel>[].obs;
  var isStoriesLoading = false.obs;

  // current profile being viewed
  var friendRx = Rxn<FriendsModel>();
  FriendsModel get friend => friendRx.value!;
  set friend(FriendsModel f) => friendRx.value = f;

  FriendListController? get _friendListController =>
      Get.isRegistered<FriendListController>()
          ? Get.find<FriendListController>()
          : null;

  var friendFriends = <Map<String, dynamic>>[].obs; // Friend's friends list
  var lastCommunityAvatar = "".obs; // Last community image
  var minimeImages = <String>[].obs;
  var avatarUrl = "".obs;

  Timer? _pollTimer;

  // Scroll controller — initialScrollOffset puts the SliverAppBar at its
  // collapsed state on first load. User drags DOWN to expand the avatar
  // back to full screen height.
  late final ScrollController profileScrollController;

  @override
  void onInit() {
    super.onInit();

    final screenH = Get.height;
    final collapsedH = 150.h;
    profileScrollController = ScrollController(
      initialScrollOffset: screenH - collapsedH,
    );

    final args = Get.arguments;
    if (args is FriendsModel) {
      friend = args;
    } else if (args is Map && args['friend'] is FriendsModel) {
      friend = args['friend'];
    } else if (args is Map && args['id'] != null) {
      friend = FriendsModel(
        id: args['id'] is int ? args['id'] : int.tryParse(args['id'].toString()) ?? 0,
        username: args['username'] ?? '',
        firstName: args['firstName'] ?? '',
        lastName: args['lastName'] ?? '',
        avatarUrl: args['avatarUrl'] ?? '',
        totalPoints: args['totalPoints'] ?? 0,
        thisWeekPoints: args['thisWeekPoints'] ?? 0,
        profileUrl: args['profileUrl'] ?? '',
      );
    } else if (args is int && args > 0) {
      friend = FriendsModel(
        id: args,
        username: '',
        firstName: '',
        lastName: '',
        avatarUrl: '',
        totalPoints: 0,
        thisWeekPoints: 0,
        profileUrl: '',
      );
    } else {
      log("NonPrivateProfile: No valid arguments received");
      return;
    }

    // এখন আর friend ব্যবহার করলে error হবে না
    loadUserSummary(friend.id);
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    profileScrollController.dispose();
    super.onClose();
  }

  /// Call this from the screen after you have the `FriendsModel friend` argument.
  Future<void> init(FriendsModel f) async {
    friend = f;

    // load saved stories (existing behavior)
    await getSavedStories(friend.id);

    // friendshipStatus is already set by loadUserSummary (called in onInit)
  }

  /// Check local lists to set flags for UI
  void checkFriendStatusLocal() {
    try {
      // reset
      isFriend.value = false;
      isRequested.value = false;
      hasIncomingRequest.value = false;

      // Already friend?
      if (friends1.any((x) => x.id == friend.id)) {
        isFriend.value = true;
        return;
      }

      // I sent request?
      if (sentRequests.any((x) => x.id == friend.id)) {
        isRequested.value = true;
        return;
      }

      // They sent me?
      if (requests.any((x) => x.id == friend.id)) {
        hasIncomingRequest.value = true;
        return;
      }
    } catch (e) {
      log("checkFriendStatusLocal error: $e");
    }
  }

  // ------------------- API calls -------------------

  Future<void> loadIncomingRequests() async {
    try {
      final response = await ApiService.incomingFriendRequestsList();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] is List) {
          final List<dynamic> data = jsonData['data'];
          final fresh =
              data.map((item) => FriendsModel.fromJson(item)).toList();

          // update reactive list (only if different to avoid excessive rebuild)
          if (!_listEqualsById(requests, fresh)) {
            requests.value = fresh;
          } else {
            // force refresh if needed
            requests.refresh();
          }

          // update hasIncomingRequest based on current profile (if set)
          if (friend != null) {
            hasIncomingRequest.value = requests.any((f) => f.id == friend.id);
          }
        } else {
          AppSnackbar.error(jsonData['message'] ?? 'Failed to fetch incoming requests');
        }
      } else {
        AppSnackbar.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  Future<void> loadSentRequests() async {
    try {
      final res = await ApiService.fetchSentFriendRequests();
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as List? ?? [];
        final fresh = data.map((item) => FriendsModel.fromJson(item)).toList();

        if (!_listEqualsById(sentRequests, fresh)) {
          sentRequests.value = fresh;
        } else {
          sentRequests.refresh();
        }

        // update isRequested if current profile matches
        if (friend != null) {
          isRequested.value = sentRequests.any((f) => f.id == friend.id);
        }
      } else {
        // ignore silently or show snack if you want
        log("loadSentRequests server error: ${res.statusCode}");
      }
    } catch (e) {
      log("loadSentRequests error: $e");
    }
  }

  Future<void> getSavedStories(int targetUserId) async {
    try {
      isStoriesLoading.value = true;
      final response = await ApiService.fetchSavedStories(targetUserId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List stories = data["savedStories"] ?? [];
        savedStories.assignAll(
          stories
              .map((e) {
                final map = Map<String, dynamic>.from(e as Map);
                // Some endpoints nest the actual story under 'story'.
                if (map['story'] is Map) {
                  return StoryModel.fromJson(
                    Map<String, dynamic>.from(map['story']),
                  );
                }
                return StoryModel.fromJson(map);
              })
              // Hide stories whose mediaUrl isn't a real http(s) URL (e.g. a
              // stale device-local path saved by mistake).
              .where((s) => _isValidStoryUrl(s.mediaUrl))
              .toList(),
        );
        log("✅ Saved Stories Loaded: ${savedStories.length}");
      } else if (response.statusCode == 403) {
        isPrivate.value = true;
      } else {
        savedStories.clear();
        log("❌ Failed: ${response.statusCode}");
      }
    } catch (e) {
      savedStories.clear();
      log("⚠️ Error fetching saved stories: $e");
    } finally {
      isStoriesLoading.value = false;
    }
  }

  // Future<void> fetchfriendProfile(int friendId) async {
  //   try {
  //     isLoading.value = true;
  //     final response = await ApiService.fetchFriendProfile(friendId);
  //     if (response.statusCode != 200) {
  //       log("❌ Server Error: ${response.statusCode}");
  //       return;
  //     }
  //     final jsonData = json.decode(response.body);
  //     if (jsonData["success"] != true) {
  //       log("❌ Failed: ${jsonData["message"]}");
  //       return;
  //     }
  //     final data = jsonData["data"] ?? {};
  //     if (data["minime"] != null && (data["minime"] as List).isNotEmpty) {
  //       avatarUrl.value = data["minime"][0]["avatarUrl"] ?? "";
  //       minimeImages.value = List<String>.from(
  //         data["minime"].map((m) => m["avatarUrl"] ?? ""),
  //       );
  //     } else {
  //       avatarUrl.value = "";
  //       minimeImages.clear();
  //     }

  //     // Friend's friends
  //     if (data["friendFriends"] != null) {
  //       final friends = List<Map<String, dynamic>>.from(
  //         data["friendFriends"].where((f) => f != null),
  //       );

  //       friendFriends.value =
  //           friends.map((f) {
  //             return {
  //               "id": f["id"] ?? 0,
  //               "username": f["username"] ?? "",
  //               "firstName": f["firstName"] ?? "No name",
  //               "lastName": f["lastName"] ?? "",
  //               "avatarUrl": f["avatarUrl"] ?? "",
  //               "totalPoints": f["totalPoints"] ?? 0,
  //               "thisWeekPoints": f["thisWeekPoints"] ?? 0,
  //             };
  //           }).toList();

  //       friendCount.value = friendFriends.length;
  //     } else {
  //       friendFriends.clear();
  //       friendCount.value = 0;
  //     }

  //     // Communities
  //     if (data["communities"] != null &&
  //         (data["communities"] as List).isNotEmpty) {
  //       final communities = List<Map<String, dynamic>>.from(
  //         data["communities"],
  //       );
  //       final lastWithImage = communities.reversed.firstWhere(
  //         (c) => (c["imageUrl"] ?? "").toString().isNotEmpty,
  //         orElse: () => {},
  //       );

  //       lastCommunityAvatar.value = lastWithImage["imageUrl"] ?? "";
  //     } else {
  //       lastCommunityAvatar.value = "";
  //     }
  //     log("✅ Friend profile loaded successfully");
  //   } catch (e) {
  //     friendFriends.clear();
  //     friendCount.value = 0;
  //     avatarUrl.value = "";
  //     minimeImages.clear();
  //     lastCommunityAvatar.value = "";
  //     log("❌ Exception: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // ---------------- Actions ----------------

  // Future<void> sendFriendRequest(int id) async {
  //   try {
  //     isLoading.value = true;
  //     EasyLoading.show(status: 'Sending request...');
  //     final response = await ApiService.sendFriendRequest(id);
  //     EasyLoading.dismiss();

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       // Update sentRequests locally (so UI updates)
  //       // Try to add a minimal FriendsModel if backend doesn't return full object
  //       final maybeBody =
  //           response.body.isNotEmpty ? jsonDecode(response.body) : null;
  //       FriendsModel? newSent;
  //       try {
  //         if (maybeBody != null && maybeBody['data'] != null) {
  //           newSent = FriendsModel.fromJson(maybeBody['data']);
  //         }
  //       } catch (_) {}

  //       if (newSent != null) {
  //         if (!sentRequests.any((s) => s.id == newSent!.id)) {
  //           sentRequests.add(newSent);
  //         }
  //       } else {
  //         // fallback: mark isRequested true
  //         isRequested.value = true;
  //       }

  //       Get.snackbar('Success', 'Friend request sent.');
  //       _startPollingForAcceptance();
  //     } else if (response.statusCode == 400) {
  //       final body = jsonDecode(response.body);
  //       String errorMsg = body['error'] ?? 'Failed to send request';
  //       Get.snackbar('Info', errorMsg);
  //       if (errorMsg.toLowerCase().contains('already friends')) {
  //         isFriend.value = true;
  //       }
  //     } else {
  //       Get.snackbar('Error', 'Failed to send request');
  //     }
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     Get.snackbar('Error', e.toString());
  //   } finally {
  //     isLoading.value = false;
  //     // ensure UI reflects latest lists
  //     checkFriendStatusLocal();
  //   }
  // }
  Future<void> sendFriendRequest(int id) async {
    try {
      // 👉 Instant optimistic update
      isRequested.value = true;

      isLoading.value = true;
      final response = await ApiService.sendFriendRequest(id);
      isLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppSnackbar.success('Friend request sent.');
      } else {
        // ❌ API ব্যর্থ হলে আবার undo
        isRequested.value = false;
        AppSnackbar.error('Failed to send request');
      }
    } catch (e) {
      isRequested.value = false;
      isLoading.value = false;
      AppSnackbar.error(e.toString());
    }
  }

  void _startPollingForAcceptance() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _friendListController?.loadFriendList();
        if (_friendListController != null) {
          friends1.value = _friendListController!.friends1;
        }
        final nowFriend = friends1.any((x) => x.id == friend.id);
        if (nowFriend) {
          isFriend.value = true;
          isRequested.value = false;
          timer.cancel();
          _pollTimer = null;
          // navigate to friend's profile
          Get.offNamed(Routes.friendsProfile, arguments: friend);
        }
      } catch (e) {
        log("Polling error: $e");
      }
    });
  }

  Future<void> acceptFriendRequest(FriendsModel friendModel) async {
    try {
      isLoading.value = true;
      final res = await ApiService.acceptFriendRequest(friendModel.id);
      final data = jsonDecode(res.body.isEmpty ? '{}' : res.body);

      final ok =
          (res.statusCode == 200) &&
          (data["message"] == "Friend request accepted." ||
              data['success'] == true);

      if (ok) {
        log("✅ Friend request accepted for id=${friendModel.id}");

        // 1) Remove from incoming requests
        requests.removeWhere((f) => f.id == friendModel.id);

        // 2) Add to friend list instantly (avoid duplicate)
        if (!friends1.any((f) => f.id == friendModel.id)) {
          friends1.add(friendModel);
          // Also update central FriendListController if exists
          if (Get.isRegistered<FriendListController>()) {
            Get.find<FriendListController>().friends1.add(friendModel);
          }
        }

        // 3) Update profile UI flags
        isFriend.value = true;
        isRequested.value = false;
        hasIncomingRequest.value = false;

        if (Get.isRegistered<MyProfileController>()) {
          Get.find<MyProfileController>().incrementFriendCount();
        }

        AppSnackbar.success("Friend request accepted.");

        // Optional: navigate to friend's profile
        Get.offNamed(Routes.friendsProfile, arguments: friendModel);
        Get.delete<NonPrivateProfileController>();
      } else {
        AppSnackbar.error((data["message"] ?? "Failed to accept request."));
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong");
      log("acceptFriendRequest error: $e");
    } finally {
      isLoading.value = false;
      // ensure flags reflect current lists
      checkFriendStatusLocal();
    }
  }

  Future<void> declineRequest(FriendsModel friendModel) async {
    try {
      isLoading.value = true;

      // ✅ Instant UI update
      hasIncomingRequest.value = false;
      isRequested.value = false;
      isFriend.value = false;

      // API call
      final res = await ApiService.declineFriendRequest(friendModel.id);

      if (res.statusCode == 200 || res.statusCode == 204) {
        // remove from local lists
        requests.removeWhere((f) => f.id == friendModel.id);
        sentRequests.removeWhere((f) => f.id == friendModel.id);
        friends1.removeWhere((f) => f.id == friendModel.id);

        AppSnackbar.success("Friend request declined.");
      } else {
        // ❌ API ব্যর্থ হলে revert back
        hasIncomingRequest.value = requests.any((f) => f.id == friend.id);
        isRequested.value = sentRequests.any((f) => f.id == friend.id);
        isFriend.value = friends1.any((f) => f.id == friend.id);

        final message =
            res.body.isNotEmpty
                ? (json.decode(res.body)['message'] ??
                    "Failed to decline request")
                : "Failed to decline request";

        AppSnackbar.error(message);
      }
    } catch (e) {
      hasIncomingRequest.value = requests.any((f) => f.id == friend.id);
      isRequested.value = sentRequests.any((f) => f.id == friend.id);
      isFriend.value = friends1.any((f) => f.id == friend.id);

      AppSnackbar.error("Something went wrong");
      log("declineRequest error: $e");
    } finally {
      isLoading.value = false;
      checkFriendStatusLocal();
    }
  }

  Future<void> blockUser(int id) async {
    try {
      final response = await ApiService.blockUser(id);

      if (response.statusCode == 200) {
        log("User blocked successfully");
        final data = json.decode(response.body);
        if (data['message'] != null) {
          AppSnackbar.success(data['message']);
        }
      } else {
        AppSnackbar.error("Failed to block user");
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  void shareText([BuildContext? context]) {
    final name = '${friend.firstName} ${friend.lastName}'.trim();
    final user = friend.username.isNotEmpty ? '@${friend.username}' : '';
    final displayName = name.isNotEmpty ? name : user;
    final message = 'Check out $displayName $user on OutSpot! Search for $user to connect.';
    shareTextWithOrigin(message, context);
  }

  Future<void> updateProfilePrivacy(bool value) async {
    isLoading.value = true;
    try {
      final response = await ApiService.setProfilePrivacy(value);

      if (response.statusCode == 200) {
        isPrivate.value = value;
        Get.find<SettingController>().isPrivate.value = value;

        final data = jsonDecode(response.body);
        final message = data['message'] ?? "Privacy updated";
        log("✅ $message");
        AppSnackbar.success(message);
      } else {
        log("❌ Failed: ${response.statusCode}");
        AppSnackbar.error("Failed to update privacy");
      }
    } catch (e) {
      log("⚠️ Error updating privacy: $e");
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// (Re)load this screen for a different user id. Needed because the controller
  /// is a singleton that gets reused when navigating profile → friend-of-friend.
  /// Resets state and refetches so it never shows the previous person.
  void loadForId(int id) {
    if (id <= 0) return;
    isProfileLoading.value = true; // gate the screen until the new user loads
    friend = FriendsModel(
      id: id,
      username: '',
      firstName: '',
      lastName: '',
      avatarUrl: '',
      totalPoints: 0,
      thisWeekPoints: 0,
      profileUrl: '',
    );
    isPrivate.value = false;
    isFriend.value = false;
    isRequested.value = false;
    hasIncomingRequest.value = false;
    savedStories.clear();
    friendFriends.clear();
    friendCount.value = 0;
    recentCommunityImageUrl.value = '';
    loadUserSummary(id);
    getSavedStories(id);
  }

  /// Open the friend's friends list (only meaningful for a public profile —
  /// a private one returns an empty list, so the list stays empty / unreachable).
  void goToFriendsList() {
    if (friendFriends.isEmpty) return;
    Get.to(
      () => const FriendFriends(),
      arguments: {"friends": friendFriends.toList()},
    );
  }

  // ---------------- Helpers ----------------

  /// A story is renderable only if its media is a real network URL. Stale
  /// device-local paths (e.g. "/data/user/0/.../cache/x.jpg") just show a
  /// broken-image placeholder, so we drop them.
  bool _isValidStoryUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  bool _listEqualsById(List<FriendsModel> a, List<FriendsModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final aIds = a.map((e) => e.id).toList()..sort();
    final bIds = b.map((e) => e.id).toList()..sort();
    for (int i = 0; i < aIds.length; i++) {
      if (aIds[i] != bIds[i]) return false;
    }
    return true;
  }

  Future<bool> reportFriend(int reportedId) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;

      final response = await ApiService.reportFriend(reportedId);
      final ok = response.statusCode >= 200 && response.statusCode < 300;

      final body = response.body ?? '';
      Map<String, dynamic>? data;
      if (body.isNotEmpty) {
        try {
          data = jsonDecode(body) as Map<String, dynamic>;
        } catch (e) {
          log('reportFriend JSON decode failed: $e');
        }
      }

      log("reportFriend status: ${response.statusCode}");
      log("reportFriend body: $body");

      if (ok) {
        final msg = data?['message'] ?? 'User reported successfully';
        AppSnackbar.success(msg.toString());
        return true;
      } else {
        final err =
            data?['error'] ?? data?['message'] ?? 'Failed to report user';
        AppSnackbar.error(err.toString());
        return false;
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ⬇️ controller vars (add these if not present)

  final recentCommunityImageUrl = ''.obs;

  // ✅ Only friendCount + recent community image url
  Future<void> loadUserSummary(int userId) async {
    isProfileLoading.value = true;
    try {
      // GET: returns the "data" map directly (as per your example)
      final data = await ApiService.getanyUserProfile(userId);

      // Update basic profile details from API
      final firstName = data['firstName']?.toString() ?? '';
      final lastName = data['lastName']?.toString() ?? '';
      final username = data['username']?.toString() ?? '';
      bio.value = (data['bio'] ?? '').toString();
      final totalPts = (data['totalPoints'] is int)
          ? data['totalPoints']
          : int.tryParse('${data['totalPoints'] ?? 0}') ?? 0;
      final weekPts = (data['thisWeekPoints'] is int)
          ? data['thisWeekPoints']
          : int.tryParse('${data['thisWeekPoints'] ?? 0}') ?? 0;

      // Extract avatar from minime array (always visible for all users)
      String profileAvatar = '';
      if (data['minime'] != null && data['minime'] is List) {
        final minimeList = data['minime'] as List;
        minimeImages.value = List<String>.from(
          minimeList.map((m) => m['avatarUrl']?.toString() ?? ''),
        );
        if (minimeList.isNotEmpty) {
          profileAvatar = minimeList[0]['avatarUrl']?.toString() ?? '';
        }
      }

      // Update avatar observable
      if (profileAvatar.isNotEmpty) {
        avatarUrl.value = profileAvatar;
      }

      // Update friend model with fresh data
      friend = FriendsModel(
        id: userId,
        username: username.isNotEmpty ? username : friend.username,
        firstName: firstName.isNotEmpty ? firstName : friend.firstName,
        lastName: lastName.isNotEmpty ? lastName : friend.lastName,
        avatarUrl: profileAvatar.isNotEmpty ? profileAvatar : friend.avatarUrl,
        totalPoints: totalPts > 0 ? totalPts : friend.totalPoints,
        thisWeekPoints: weekPts > 0 ? weekPts : friend.thisWeekPoints,
        profileUrl: friend.profileUrl,
      );

      log("Profile updated: username=${friend.username}, fullName=${friend.fullName}, avatar=${friend.avatarUrl}");

      // Update communities
      if (data['communities'] is List) {
        communities.value = data['communities'];
      }

      // Check privacy — reset on each load
      isPrivate.value = data['isPrivate'] == true;

      // Friendship status from API
      final status = data['friendshipStatus']?.toString() ?? 'NONE';
      switch (status) {
        case 'ACCEPTED':
          isFriend.value = true;
          isRequested.value = false;
          hasIncomingRequest.value = false;
          // NOTE: no manual isPrivate override here — the server already sends
          // isPrivate=false for accepted friends (bypass). Trust the server flag.
          break;
        case 'PENDING_SENT':
          isFriend.value = false;
          isRequested.value = true;
          hasIncomingRequest.value = false;
          break;
        case 'PENDING_RECEIVED':
          isFriend.value = false;
          isRequested.value = false;
          hasIncomingRequest.value = true;
          break;
        default: // NONE
          isFriend.value = false;
          isRequested.value = false;
          hasIncomingRequest.value = false;
      }

      // Friend's friends list
      if (data['friends'] is List) {
        friendFriends.value = List<Map<String, dynamic>>.from(data['friends']);
      }

      // 1) Friend count (int; fallback 0)
      final fcRaw = data['friendCount'];
      final fc = (fcRaw is int) ? fcRaw : int.tryParse('$fcRaw') ?? 0;
      log("frind count ${fc}");
      friendCount.value = fc;

      // 2) Recent community image (mostRecent.imageUrl OR first non-empty from communities[])
      String imageUrl = '';

      // mostRecent first (can be null per your sample)
      if (data['mostRecent'] != null) {
        final mr = Map<String, dynamic>.from(data['mostRecent']);
        final mrUrl = (mr['imageUrl'] ?? '').toString().trim();
        if (mrUrl.isNotEmpty) imageUrl = mrUrl;
      }

      // fallback: scan communities[] for first non-empty imageUrl
      if (imageUrl.isEmpty &&
          data['communities'] is List &&
          (data['communities'] as List).isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(data['communities']);
        for (final c in list) {
          final u = (c['imageUrl'] ?? '').toString().trim();
          if (u.isNotEmpty) {
            imageUrl = u;
            break;
          }
        }
      }

      recentCommunityImageUrl.value = imageUrl; // can be ''

      log(
        "✅ Summary loaded → friends=$fc, recentCommunityImageUrl='${recentCommunityImageUrl.value}'",
      );
    } catch (e) {
      // safe defaults
      friendCount.value = 0;
      recentCommunityImageUrl.value = '';
      log("❌ loadUserSummary error: $e");
    } finally {
      isProfileLoading.value = false;
    }
  }
}
