import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/visited_spot_model.dart';
import 'package:outspot/Model/lockerItem_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/FriendsProfile/friendsFriends.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/NonPrivateProfile/non_private_profile_controller.dart';
import 'package:outspot/Utils/share_helper.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';

class FriendsProfileController extends GetxController {
  var avatarUrl = "".obs;
  var mediaUrl = ''.obs;

  /// Friend profile data
  var isLoading = false.obs;
  var friendData = {}.obs;
  var minimeImages = <String>[].obs;
  var friendCount = 0.obs;
  var communities = <dynamic>[].obs;

  /// Saved stories
  var savedStories = <StoryModel>[].obs;
  var isStoriesLoading = false.obs;
  var selectedTab = 'Saved Stories'.obs;
  var lockerItems = <LockerItem>[].obs;
  var isLoadingLocker = false.obs;

  // List of friends
  var friends1 = <FriendsModel>[].obs;

  // Visited spots
  var recentVisitedSpots = <VisitedSpotModel>[].obs;

  int? currentUserId;

  /// Reactive id of the user whose data is CURRENTLY loaded & ready to show.
  /// The controller is a singleton shared across stacked profile routes, so the
  /// UI gates on this: until it matches the route's friendId, a loader is shown
  /// instead of the previously-viewed friend's data (kills the wrong-profile
  /// flash when navigating friend → friend-of-friend, and on back-navigation).
  final loadedUserId = RxnInt();

  Timer? _pollTimer;

  // Scroll controller — initialScrollOffset puts the SliverAppBar at its
  // collapsed (230.h) state on first load. User drags DOWN to scroll up,
  // which expands the avatar back to full-screen height.
  late final ScrollController profileScrollController;

  @override
  void onInit() {
    super.onInit();

    final screenH = Get.height;
    final collapsedH = 180.h;
    profileScrollController = ScrollController(
      initialScrollOffset: screenH - collapsedH,
    );

    int friendId;

    // Get.arguments হচ্ছে পুরো model
    if (Get.arguments is FriendsModel) {
      friendId = (Get.arguments as FriendsModel).id;
    } else if (Get.arguments is Map<String, dynamic>) {
      // map থেকে id নাও
      friendId = (Get.arguments as Map<String, dynamic>)["id"] as int;
    } else if (Get.arguments is int) {
      friendId = Get.arguments as int;
    } else {
      log("⚠️ No friendId found in arguments");
      return;
    }

    // Load everything for this friend
    loadProfile(friendId);
    log('prev: ${Get.previousRoute}, current: ${Get.currentRoute}');
  }

  /// (Re)load the whole profile for [friendId]. Safe to call again with a new id
  /// when this (singleton) controller is reused for a different person — it
  /// cancels the old poll and reloads, so the screen never shows stale data.
  Future<void> loadProfile(int friendId) async {
    currentUserId = friendId;
    // Hide any previously-loaded friend's data until THIS friend is ready.
    loadedUserId.value = null;
    _pollTimer?.cancel();

    loadFriends();
    getSavedStories(friendId);
    fetchLockerData(friendId);
    getMyStats(friendId);

    // Primary data (avatar, name, communities). Gate the UI on this completing
    // so the screen never flashes the previous friend.
    await fetchfriendProfile(friendId);

    // Only reveal if this is still the requested user (guards against a newer
    // navigation having superseded this load).
    if (currentUserId == friendId) {
      loadedUserId.value = friendId;
    }

    _startPolling(friendId);
  }

  void _startPolling(int friendId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchfriendProfile(friendId);
      getSavedStories(friendId);
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    profileScrollController.dispose();
    super.onClose();
  }

  Future<void> loadFriends() async {
    // Use the friend-list endpoint (returns {success, data:[...]}). The old code
    // hit fetchUserProfile() which returns the OWN profile Map and crashed when
    // decoded as a List.
    try {
      final response = await ApiService.fetchFriendList();
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map && jsonData['data'] is List) {
          friends1.value =
              (jsonData['data'] as List)
                  .map((e) => FriendsModel.fromJson(e))
                  .toList();
        }
      }
    } catch (e) {
      log("⚠️ loadFriends error: $e");
    }
  }

  /// Load friend profile by ID (uses unified profile endpoint)
  Future<void> getFriendProfile(int id) async {
    try {
      isLoading.value = true;
      final data = await ApiService.getanyUserProfile(id);

      friendData.value = data;

      if (data["minime"] != null && (data["minime"] as List).isNotEmpty) {
        avatarUrl.value = data["minime"][0]["avatarUrl"] ?? "";
        minimeImages.value = List<String>.from(
          (data["minime"] as List).map((m) => m["avatarUrl"] ?? ""),
        );
      } else {
        avatarUrl.value = "";
        minimeImages.clear();
      }

      friendCount.value =
          (data["friendCount"] is int) ? data["friendCount"] : 0;
      communities.value = data["communities"] ?? [];

      log("Friend Profile Loaded");
    } catch (e) {
      log("Exception in getFriendProfile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Block a user
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

  Future<void> unfriend(int friendId) async {
    try {
      final res = await ApiService.unfriendUser(friendId);
      if (res.statusCode == 200 || res.statusCode == 204) {
        // Remove from friends list
        friends1.removeWhere((f) => f.id == friendId);
        friends1.value = [...friends1];

        log("✅ Unfriended user: $friendId");

        // Update friend count in MyProfileController
        if (Get.isRegistered<MyProfileController>()) {
          Get.find<MyProfileController>().decrementFriendCount();
        }

        // Update AllStatsController if open
        if (Get.isRegistered<AllStatsController>()) {
          final asc = Get.find<AllStatsController>();
          if (asc.friends.value > 0) asc.friends.value--;
        }

        // Update FriendListController list immediately
        if (Get.isRegistered<FriendListController>()) {
          final flc = Get.find<FriendListController>();
          flc.friends1.removeWhere((f) => f.id == friendId);
        }

        // Remove their marker from the map instantly (safe no-op if not shown)
        if (Get.isRegistered<MapController>()) {
          Get.find<MapController>().removeFriendFromMap(friendId);
        }
        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }

        // ✅ Update NonPrivateProfileController state if exists
        if (Get.isRegistered<NonPrivateProfileController>()) {
          final profileController = Get.find<NonPrivateProfileController>();
          profileController.isFriend.value = false;
          profileController.isRequested.value = false;
        }

        AppSnackbar.success("Friend removed successfully.");

        // Stop polling since no longer friends
        _pollTimer?.cancel();

        if (Get.isDialogOpen ?? false) Get.back();

        // Navigate to non-private profile (add friend view)
        final friendModel = FriendsModel(
          id: friendId,
          username: friendData['username'] ?? '',
          firstName: friendData['firstName'] ?? '',
          lastName: friendData['lastName'] ?? '',
          avatarUrl: avatarUrl.value,
          totalPoints: friendData['totalPoints'] ?? 0,
          thisWeekPoints: friendData['thisWeekPoints'] ?? 0,
          profileUrl: '',
        );
        Get.offNamed(Routes.nonPrivateProfile, arguments: friendModel);
      } else {
        final message =
            res.body.isNotEmpty
                ? (json.decode(res.body)['message'] ??
                    "Failed to remove friend")
                : "Failed to remove friend";
        AppSnackbar.error(message);
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong");
      log("Exception in unfriend: $e");
    }
  }

  FriendsModel buildFriendModel(int friendId) {
    return FriendsModel(
      id: friendId,
      username: friendData['username'] ?? '',
      firstName: friendData['firstName'] ?? '',
      lastName: friendData['lastName'] ?? '',
      avatarUrl: avatarUrl.value,
      totalPoints: friendData['totalPoints'] ?? 0,
      thisWeekPoints: friendData['thisWeekPoints'] ?? 0,
      profileUrl: '',
    );
  }

  Future<int?> getOrCreateChat(int friendId) async {
    try {
      // First check existing chats from MessagesScreenController
      if (Get.isRegistered<MessagesScreenController>()) {
        final msgCtrl = Get.find<MessagesScreenController>();
        for (final chat in msgCtrl.chatss) {
          if (!chat.isGroup && !chat.isCommunity) {
            final hasUser = chat.users.any((u) => u.id == friendId);
            if (hasUser) {
              log("Found existing chatId=${chat.id} for friend=$friendId");
              return chat.id;
            }
          }
        }
      }
      // Fallback: create chat via API (only if no existing chat found)
      final chat = await ApiService.createChat(
        userIds: [friendId],
        isGroup: false,
      );
      return chat['chatId'] ?? chat['id'] ?? 0;
    } catch (e) {
      log("Error getting chat: $e");
      return null;
    }
  }

  void shareText([BuildContext? context]) {
    final name =
        '${friendData['firstName'] ?? ''} ${friendData['lastName'] ?? ''}'
            .trim();
    final user =
        friendData['username'] != null ? '@${friendData['username']}' : '';
    final displayName = name.isNotEmpty ? name : user;
    final message =
        'Check out $displayName $user on OutSpot! Search for $user to connect.';
    shareTextWithOrigin(message, context);
  }

  /// Get saved stories
  Future<void> getSavedStories(int targetUserId) async {
    // Only show the loading state on the FIRST fetch.
    // Subsequent polls silently update data without clearing the UI
    // (prevents the grid from flickering blank every 5 seconds).
    final isFirstLoad = savedStories.isEmpty;
    try {
      if (isFirstLoad) isStoriesLoading.value = true;
      final response = await ApiService.fetchSavedStories(targetUserId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List stories = data["savedStories"] ?? [];
        final fresh =
            stories
                .map((e) => StoryModel.fromJson(e))
                // Drop stories whose media isn't a real http(s) URL (stale
                // device-local paths only render a broken-image placeholder).
                .where((s) {
                  final u = s.mediaUrl.trim().toLowerCase();
                  return u.startsWith('http://') || u.startsWith('https://');
                })
                .toList();

        // Only reassign if the list actually changed, to avoid
        // unnecessary rebuilds that can also cause a flash.
        if (fresh.length != savedStories.length ||
            !_storyListsEqual(fresh, savedStories.toList())) {
          savedStories.assignAll(fresh);
        }
        log("✅ Saved Stories Loaded: ${savedStories.length}");
      } else {
        if (isFirstLoad) savedStories.clear();
        log("❌ Failed: ${response.statusCode}");
      }
    } catch (e) {
      if (isFirstLoad) savedStories.clear();
      log("⚠️ Error fetching saved stories: $e");
    } finally {
      if (isFirstLoad) isStoriesLoading.value = false;
    }
  }

  bool _storyListsEqual(List<StoryModel> a, List<StoryModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  // // শুধু শেষ community রাখার জন্য Rx
  // Rx<Map<String, dynamic>?> lastCommunity = Rx<Map<String, dynamic>?>(null);

  // Future<void> loadRecentCommunities() async {
  //   try {
  //     final response = await ApiService.fetchRecentCommunities();
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['items'] is List && data['items'].isNotEmpty) {
  //         // শেষ community assign করা
  //         lastCommunity.value = Map<String, dynamic>.from(data['items'].last);
  //         log("Last community loaded: ${lastCommunity.value}");
  //       } else {
  //         lastCommunity.value = null;
  //         log("No recent communities found");
  //       }
  //     }
  //   } catch (e) {
  //     lastCommunity.value = null;
  //     log("Error fetching recent communities: $e");
  //   }
  // }

  var friendFriends = <Map<String, dynamic>>[].obs; // Friend's friends list

  var lastCommunityAvatar = "".obs; // Last community image

  Future<void> fetchfriendProfile(int friendId) async {
    try {
      isLoading.value = true;

      // Use unified profile endpoint — works for friends AND non-friends
      final data = await ApiService.getanyUserProfile(friendId);

      // Extract avatar from minime (available for all users)
      String avatar = '';
      if (data['minime'] != null &&
          data['minime'] is List &&
          (data['minime'] as List).isNotEmpty) {
        avatar = data['minime'][0]['avatarUrl']?.toString() ?? '';
      }

      // Check friendship status — redirect if not friends
      final status = data['friendshipStatus']?.toString() ?? 'NONE';
      if (status != 'ACCEPTED') {
        log(
          "Not friends (status: $status) — redirecting to non-private profile",
        );
        _pollTimer?.cancel();
        final model = FriendsModel(
          id: friendId,
          username: data['username']?.toString() ?? '',
          firstName: data['firstName']?.toString() ?? '',
          lastName: data['lastName']?.toString() ?? '',
          avatarUrl: avatar,
          totalPoints: (data['totalPoints'] is int) ? data['totalPoints'] : 0,
          thisWeekPoints:
              (data['thisWeekPoints'] is int) ? data['thisWeekPoints'] : 0,
          profileUrl: '',
        );
        Get.offNamed(Routes.nonPrivateProfile, arguments: model);
        return;
      }

      friendData.value = data;

      // ---------------- Avatar ----------------
      if (data["minime"] != null && (data["minime"] as List).isNotEmpty) {
        avatarUrl.value = data["minime"][0]["avatarUrl"] ?? "";
        minimeImages.value = List<String>.from(
          data["minime"].map((m) => m["avatarUrl"] ?? ""),
        );
      } else {
        avatarUrl.value = "";
        minimeImages.clear();
      }

      // ---------------- Friend's Friends ----------------
      if (data["friends"] != null && (data["friends"] as List).isNotEmpty) {
        final friendsList = List<Map<String, dynamic>>.from(
          (data["friends"] as List).where((f) => f != null),
        );

        friendFriends.value =
            friendsList.map((f) {
              return {
                "id": f["id"] ?? 0,
                "username": f["username"] ?? "",
                "firstName": f["firstName"] ?? "No name",
                "lastName": f["lastName"] ?? "",
                "avatarUrl": f["avatarUrl"] ?? "",
                "totalPoints": f["totalPoints"] ?? 0,
                "thisWeekPoints": f["thisWeekPoints"] ?? 0,
                // viewer's relation to this person (NOT the profile owner's)
                "friendshipStatus":
                    f["friendshipStatus"]?.toString() ?? "NONE",
              };
            }).toList();
      } else {
        friendFriends.clear();
      }

      // ---------------- Communities ----------------
      if (data["communities"] != null &&
          (data["communities"] as List).isNotEmpty) {
        final comms = List<Map<String, dynamic>>.from(data["communities"]);

        final lastWithImage = comms.reversed.firstWhere(
          (c) => (c["imageUrl"] ?? "").toString().isNotEmpty,
          orElse: () => {},
        );

        lastCommunityAvatar.value = lastWithImage["imageUrl"] ?? "";
      } else {
        lastCommunityAvatar.value = "";
      }

      // ---------------- Visited Spots ----------------
      if (data["recentVisitedSpots"] != null &&
          (data["recentVisitedSpots"] as List).isNotEmpty) {
        recentVisitedSpots.value =
            (data["recentVisitedSpots"] as List)
                .map((e) => VisitedSpotModel.fromJson(e))
                .toList();
      } else {
        recentVisitedSpots.clear();
      }

      // ---------------- Friend Count ----------------
      friendCount.value =
          (data["friendCount"] is int) ? data["friendCount"] : 0;

      // ---------------- Communities list ----------------
      communities.value = data["communities"] ?? [];

      log("Friend profile loaded successfully");
    } catch (e) {
      log("Exception fetching friend profile: $e");
      avatarUrl.value = "";
      minimeImages.clear();
      lastCommunityAvatar.value = "";
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to friend's friend list screen
  void goToFriendsList() {
    if (friendFriends.isNotEmpty) {
      Get.to(
        () => const FriendFriends(),
        arguments: {"friends": friendFriends.toList()},
      );
    }
  }

  /// Decrement friend count (unfriend)
  void handleUnfriend(FriendsModel friend) {
    // Remove from friends list
    friends1.removeWhere((f) => f.id == friend.id);

    // Decrement global friend count
    if (Get.isRegistered<MyProfileController>()) {
      Get.find<MyProfileController>().decrementFriendCount();
    }

    log("⚠️ Friend removed: ${friend.fullName}");
  }

  /// Block friend (also decrement count)
  void handleBlock(FriendsModel friend) {
    // Remove from friends list
    friends1.removeWhere((f) => f.id == friend.id);

    // Decrement global friend count
    if (Get.isRegistered<MyProfileController>()) {
      Get.find<MyProfileController>().decrementFriendCount();
    }

    log("⛔ Friend blocked: ${friend.fullName}");
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

  void fetchLockerData(int userId) async {
    try {
      isLoadingLocker(true);
      var data = await ApiService.getLockerData(userId);
      log("Locker data fetched: $data");
      lockerItems.assignAll(data);
    } catch (e) {
      log("Locker error: $e");
    } finally {
      isLoadingLocker(false);
    }
  }

  void changeTab(String tabName) {
    selectedTab.value = tabName;
  }

  var spotsVisited = 0.obs;
  var friends = 0.obs;
  var community = 0.obs;
  var challengesCompleted = 0.obs;
  var communityName = RxnString();

  // Community stats

  var communityImage = "".obs;
  Future<void> getMyStats(int friendId) async {
    try {
      isLoading.value = true;

      final data = await ApiService.fetchUserStats(friendId);

      if (data != null) {
        spotsVisited.value = data["spotsVisited"] ?? 0;
        friends.value = data["friends"] ?? 0;
        community.value = data["community"] ?? 0;
        challengesCompleted.value = data["challengesCompleted"] ?? 0;
        log(
          "User stats updated: SpotsVisited=${spotsVisited.value}, Friends=${friends.value}, Community=${community.value}, ChallengesCompleted=${challengesCompleted.value}",
        );

        if (data["myCommunity"] != null) {
          communityName.value = data["myCommunity"]["name"]?.toString();
          communityImage.value =
              data["myCommunity"]["imageUrl"]?.toString() ?? "";
        }
      }
    } catch (e) {
      log("❌ getMyStats error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInitialData() async {
    int? savedId = await UserPreference.getUserId();

    if (savedId != null && savedId != 0) {
      await getMyStats(savedId);
    } else {
      print("User ID zero or null in storage");
    }
  }
}
