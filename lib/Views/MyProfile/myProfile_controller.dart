import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/savedStory_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Model/visited_spot_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/share_helper.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class MyProfileController extends GetxController {
  /// Tabs. Defaults to 'My Photos' — the 'My Locker' tab is temporarily hidden
  /// (see myProfile.dart), so landing on it would show a blank section.
  var selectedTab = 'My Photos'.obs;
  final mediaUrl = ''.obs;
  // var savedStories = <StoryModel>[].obs;
  RxList<StoryModel> savedStories = <StoryModel>[].obs;
  var isStoriesLoading = true.obs;
  var vaultStories = <SavedStory>[].obs;
  var isVaultLoading = false.obs;

  /// Profile state
  RxInt friendCount = 0.obs;
  int userId = 0;
  var firstname = "".obs;
  var lastname = "".obs;
  var username = "".obs;
  var bio = "".obs;
  // Own account privacy. Source of truth is the locally-saved value — the
  // profile endpoint's isPrivate is viewer-relative (false for your own view).
  var isPrivate = false.obs;
  RxList minimeList = [].obs;
  RxString avatarurl = ''.obs;
  var coins = 0.obs;
  var diamonds = 0.obs;
  var lockerItems = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var communityName = RxnString();
  RxString miniMeImage = ''.obs;
  // var stories = <Map<String, dynamic>>[].obs;
  RxList<StoryModel> stories = <StoryModel>[].obs;
  RxString lastCommunityImage = ''.obs;
  RxString lastCommunityName = ''.obs;
  var myCommunityId = 0.obs;
  var bodyType = "".obs;
  var recentVisitedSpots = <VisitedSpotModel>[].obs;

  // NOTE: the scroll controller + tab GlobalKey live on the MyProfile WIDGET
  // (not here) so two stacked MyProfile routes don't share one instance.

  @override
  void onInit() {
    super.onInit();
    refreshProfileData();
  }

  // Collapse rapid re-triggers (onInit + back-nav + UI actions firing close
  // together) into one refresh so a weak network isn't hit with duplicate
  // storms. A real refresh > 2s later still runs.
  DateTime? _lastProfileRefresh;

  void refreshProfileData({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastProfileRefresh != null &&
        now.difference(_lastProfileRefresh!) < const Duration(seconds: 2)) {
      log("⏭️ refreshProfileData debounced (<2s since last)");
      return;
    }
    _lastProfileRefresh = now;

    _loadCachedAvatar();
    // NOTE: no separate fetchPoints/getMyStats here — loadUserProfile() already
    // fetches points internally and loadInitialData() fetches stats. Calling
    // them here fired each a 2nd time (duplicate stats/points requests).
    loadUserProfile();
    loadFriendCount();
    fetchLockerItems();
    loadMostRecentCommunityImage().then((_) {});

    loadStories();
    getSavedStories();
    getRedDot();
    loadInitialData();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> _loadCachedAvatar() async {
    final cached = await UserPreference.getCachedProfile();
    if (cached != null) {
      final minime = cached['minime'] as List<dynamic>? ?? [];
      if (minime.isNotEmpty) {
        avatarurl.value = minime.last['avatarUrl'] ?? '';
      }
    }
  }

  Future<void> fetchPoints(int userId) async {
    try {
      print("Fetching points for userId: $userId");

      final response = await ApiService.getPoints(userId);
      print("Points status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        coins.value = data["totalPoints"] ?? 0;
        diamonds.value = data["thisWeekPoints"] ?? 0;
      } else {
        coins.value = 0;
        diamonds.value = 0;
        print("Failed to fetch points: ${response.statusCode}");
      }
    } catch (e) {
      coins.value = 0;
      diamonds.value = 0;
      print("Error fetching points: $e");
    }
  }

  Future<void> fetchLockerItems() async {
    try {
      isLoading.value = true;

      final response = await ApiService.getMinimeForLocker();
      log("status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["locker"] is List) {
          lockerItems.value =
              (data["locker"] as List)
                  .where((item) => (item["avatarUrl"]?.toString() ?? "").isNotEmpty)
                  .map((item) => {
                    'id': item['id'] as int?,
                    'avatarUrl': item['avatarUrl']?.toString() ?? '',
                  })
                  .toList();
        } else {
          lockerItems.clear();
        }
      } else {
        // Background fetch — log only, don't pop a scary error on weak net.
        log("Failed to load locker items: ${response.statusCode}");
      }
    } catch (e) {
      log("Error in fetchLockerItems: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void refreshStats() {
    loadUserProfile();
    loadInitialData();
    loadMostRecentCommunityImage();
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];

        firstname.value = data["firstName"] ?? '';
        lastname.value = data["lastName"] ?? '';
        userId = data["id"] ?? 0;
        username.value = data["username"] ?? '';
        bio.value = (data["bio"] ?? '').toString();

        // Own account privacy — mirror the Settings screen's source of truth.
        // isProfilePrivate = the RAW lock state (true even for your own view),
        // so trust it directly and cache it. Fall back to the viewer-relative
        // isPrivate only on old servers, preferring any locally-saved value.
        if (data["isProfilePrivate"] is bool) {
          isPrivate.value = data["isProfilePrivate"];
          await UserPreference.saveProfilePrivacy(isPrivate.value);
        } else if (data["isPrivate"] is bool) {
          final cached = await UserPreference.getProfilePrivacy();
          isPrivate.value = cached ?? data["isPrivate"];
        } else {
          final cached = await UserPreference.getProfilePrivacy();
          if (cached != null) isPrivate.value = cached;
        }

        bodyType.value = data["bodyType"] ?? '';

        minimeList.value = data["minime"] ?? [];

        if (minimeList.isNotEmpty) {
          avatarurl.value = minimeList.last['avatarUrl'] ?? '';
        }

        // Cache for instant avatar on next visit
        UserPreference.cacheProfile(data);

        log("Profile loaded for ${firstname.value} ${lastname.value}");

        // ✅ fetch points and vault stories
        if (userId != 0) {
          await fetchPoints(userId);
          fetchVaultStories(userId);
        }
        log("Points fetched: Coins=${coins.value}, Diamonds=${diamonds.value}");
      } else if (response.statusCode == 401) {
        // Keep — auth failure needs user action.
        log("🔒 Unauthorized - Token expired or invalid");
        AppSnackbar.info("Please log in again.", title: "Session Expired");
      } else {
        // Background load — log only (cached data stays on screen).
        log("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      // Background load (often a weak-net timeout) — log only, no popup.
      log("❌ Error loading profile: $e");
    }
  }

  Future<void> loadFriendCount() async {
    try {
      final response = await ApiService.fetchFriendList();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData["data"];
        friendCount.value = data.length; // Initial value
        log("Friend Count: ${friendCount.value}");
      } else {
        log("Failed: ${response.statusCode}");
      }
    } catch (e) {
      log("Error: $e");
    }
  }

  void incrementFriendCount() {
    friendCount.value++;
    friends.value = friendCount.value;
    log("Friend count incremented: ${friendCount.value}");
  }

  void updateMiniMe(String newImage) {
    miniMeImage.value = newImage;
  }

  void decrementFriendCount() {
    if (friendCount.value > 0) {
      friendCount.value--;
      log("Friend count decremented: ${friendCount.value}");
    }
    // Also sync the stats friends count so UI updates immediately
    friends.value = friendCount.value;
  }

  static MyProfileController get instance {
    if (!Get.isRegistered<MyProfileController>()) {
      Get.put(MyProfileController(), permanent: true);
    }
    return Get.find<MyProfileController>();
  }

  void shareText([BuildContext? context]) {
    final name = '${firstname.value} ${lastname.value}'.trim();
    final user = username.value.isNotEmpty ? '@${username.value}' : '';
    final message = 'Check out $name $user on OutSpot! Search for $user to connect with me.';
    shareTextWithOrigin(message, context);
  }

  void updateAvatarLocal(String newAvatarUrl) {
    avatarurl.value = newAvatarUrl;
    // Get.snackbar(
    //   "Success",
    //   "Mini-me updated locally!",
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    //   snackPosition: SnackPosition.TOP,
    // );
  }

  Future<void> loadStories() async {
    try {
      final response = await ApiService.fetchUserStories();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body["stories"] != null && body["stories"] is List) {
          final List<Map<String, dynamic>> storyList =
              (body["stories"] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

          stories.assignAll(
            storyList.map((e) => StoryModel.fromJson(e)).toList(),
          );
          if (stories.isNotEmpty) {
            log("🎬 First Story mediaUrl: ${stories[0].mediaUrl}");
          }
        } else {
          log("⚠️ No stories found");
          stories.clear();
        }
      } else {
        log("❌ API Error: ${response.statusCode}");
        stories.clear();
      }
    } catch (e, stackTrace) {
      log("❌ Exception fetching stories: $e");
      log("StackTrace: $stackTrace");
      stories.clear();
    }
  }

  Future<void> loadMostRecentCommunityImage() async {
    try {
      final response = await ApiService.fetchRecentCommunities();

      if (response.statusCode == 200) {
    
        final data = jsonDecode(response.body);

        if (data['mostRecent'] != null && data['mostRecent'] is Map) {
          lastCommunityImage.value = data['mostRecent']['imageUrl'] ?? '';
          lastCommunityName.value = data['mostRecent']['name']?.toString() ?? 'Community';
          myCommunityId.value = data['mostRecent']['id'] ?? 0;
          log("✅ Most recent community image: ${lastCommunityImage.value}");
        } else {
          lastCommunityImage.value = '';
          lastCommunityName.value = 'community';
          log("⚠️ No most recent community found");
        }
      } else {
        lastCommunityImage.value = '';
        lastCommunityName.value = 'community';
        log("❌ API Error: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      lastCommunityImage.value = '';
      lastCommunityName.value = 'community';
      log("❌ Exception fetching community image: $e");
      log("StackTrace: $stackTrace");
    }
  }

  Future<void> fetchVaultStories(int userId) async {
    try {
      isVaultLoading.value = true;
      log("Fetching vault stories for user: $userId");

      final stories = await ApiService.fetchSavedVaultStories(userId);

      // Hide vault stories whose media isn't a real http(s) URL (stale
      // device-local paths only render a broken-image placeholder).
      vaultStories.value =
          stories.where((s) {
            final u = s.mediaUrl.trim().toLowerCase();
            return u.startsWith('http://') || u.startsWith('https://');
          }).toList();
      log("Vault stories loaded: ${vaultStories.length}");
    } catch (e) {
      // Background fetch — log only, no popup on weak net.
      log("Error fetching vault stories: $e");
    } finally {
      isVaultLoading.value = false;
    }
  }

  Future<void> getSavedStories() async {
    try {
      isStoriesLoading.value = true;
      final response = await ApiService.fetchSavedStoriesforUser();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List stories = data["savedStories"] ?? [];
        savedStories.assignAll(
          stories
              .map((e) {
                final map = Map<String, dynamic>.from(e as Map);
                // Handle nested story object from saved stories API
                if (map.containsKey('story') && map['story'] is Map) {
                  return StoryModel.fromJson(
                    Map<String, dynamic>.from(map['story']),
                  );
                }
                return StoryModel.fromJson(map);
              })
              // Hide stories whose media isn't a real http(s) URL (stale
              // device-local paths only render a broken-image placeholder).
              .where((s) {
                final u = s.mediaUrl.trim().toLowerCase();
                return u.startsWith('http://') || u.startsWith('https://');
              })
              .toList(),
        );
        log("✅ Saved Stories Loaded: ${savedStories}");
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

  final RxnInt deletingStoryId = RxnInt();

  /// Delete a saved story (My Photos / Vault) by its clone story id.
  /// On success (or 403 = already gone) it is removed from the local grids.
  Future<bool> deleteSavedStory(int storyId) async {
    if (deletingStoryId.value != null) return false;
    deletingStoryId.value = storyId;
    try {
      final res = await ApiService.deleteStory(storyId);
      final code = res.statusCode;
      log("ℹ️ deleteStory($storyId) → $code ${res.body}");
      // Any 2xx = deleted. 403/404 = already gone on the server. In every case
      // the story should disappear from the local grids. (Some DELETE responses
      // come back as 204 No Content, so don't hard-check for 200.)
      final deleted = code >= 200 && code < 300;
      final alreadyGone = code == 403 || code == 404;
      if (deleted || alreadyGone) {
        savedStories.removeWhere((s) => s.id == storyId);
        vaultStories.removeWhere((s) => s.id == storyId);
        // NOTE: snackbar is shown by the caller AFTER it pops the viewer.
        // GetX pushes snackbars as nav routes, so showing one here would be
        // swallowed by the viewer's Get.back().
        return true;
      }
      return false;
    } catch (e) {
      log("❌ deleteSavedStory error: $e");
      return false;
    } finally {
      deletingStoryId.value = null;
    }
  }

  // Notification red dot is realtime via NotificationBadgeService's socket;
  // no polling timer needed. getRedDot() below stays as a one-time seed.
  final _badgeService = Get.find<NotificationBadgeService>();
  RxBool get notificationRedDot => _badgeService.notificationRedDot;
  Future<void> getRedDot() => _badgeService.getRedDot();
  Future<void> clearNotificationDot() => _badgeService.clearNotificationDot();

  // Observable variables

  var spotsVisited = 0.obs;
  var friends = 0.obs;
  var community = 0.obs;
  var challengesCompleted = 0.obs;

  // Community stats

  var communityImage = "".obs;

  // Future<void> getMyStats(int userId) async {
  //   try {
  //     isLoading.value = true;

  //     // ApiService theke data fetch kora
  //     final data = await ApiService.fetchUserStats(userId);

  //     if (data != null) {
  //       // Obx variables update kora
  //       spotsVisited.value = data["spotsVisited"] ?? 0;
  //       friends.value = data["friends"] ?? 0;
  //       friendCount.value = friends.value;
  //       community.value = data["community"] ?? 0;
  //       challengesCompleted.value = data["challengesCompleted"] ?? 0;
  //       log(
  //         "User stats updated: SpotsVisited=${spotsVisited.value}, Friends=${friends.value}, Community=${community.value}, ChallengesCompleted=${challengesCompleted.value}",
  //       );

  //       if (data["myCommunity"] != null) {
  //         communityName.value = data["myCommunity"]["name"] ?? "";
  //         communityImage.value = data["myCommunity"]["imageUrl"] ?? "";
  //       }
  //     }
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> loadInitialData() async {
    int? savedId = await UserPreference.getUserId();

    if (savedId != null && savedId != 0) {
      await getMyStats(savedId);
      await fetchVisitedSpots(savedId);
    } else {
      print("User ID zero or null in storage");
    }
  }

  Future<void> fetchVisitedSpots(int userId) async {
    try {
      final response = await ApiService.fetchVisitedSpots(userId);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List spots =
            jsonData['data'] ?? jsonData['recentVisitedSpots'] ?? [];
        recentVisitedSpots.value =
            spots.map((e) => VisitedSpotModel.fromJson(e)).toList();
      }
    } catch (e) {
      log("Error fetching visited spots: $e");
    }
  }

  Future<void> getMyStats(int userId) async {
    try {
      isLoading.value = true;

      final data = await ApiService.fetchUserStats(userId);

      if (data != null) {
        spotsVisited.value = data["spotsVisited"] ?? 0;
        friends.value = data["friends"] ?? 0;
        friendCount.value = friends.value;
        community.value = data["community"] ?? 0;
        challengesCompleted.value = data["challengesCompleted"] ?? 0;

        if (data["myCommunity"] != null) {
          communityName.value = data["myCommunity"]["name"] ?? "";
          communityImage.value = data["myCommunity"]["imageUrl"] ?? "";
          myCommunityId.value = data["myCommunity"]["id"] ?? 0;
        }
      }
    } catch (e) {
      log("❌ Error updating stats: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
