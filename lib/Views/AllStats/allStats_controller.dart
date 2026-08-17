// import 'dart:developer';

// import 'package:get/get.dart';
// import 'package:outspot/Network_Manager/api_service.dart';
// import 'package:outspot/Network_Manager/user_preference.dart';

// class AllStatsController extends GetxController {
//   // Observable variables

//   var spotsVisited = 0.obs;
//   var friends = 0.obs;
//   var community = 0.obs;
//   var challengesCompleted = 0.obs;
//   var communityName = "".obs; // RxnString theke "".obs e convert korun
//   var communityImage = "".obs;
//   var isLoading = false.obs;
//   @override
//   void onInit() {
//     super.onInit();
//     loadInitialData();
//   }

//   Future<void> getMyStats(int userId) async {
//     try {
//       isLoading.value = true;
//       final data = await ApiService.fetchUserStats(userId);

//       if (data != null) {
//         spotsVisited.value = data["spotsVisited"] ?? 0;
//         friends.value = data["friends"] ?? 0;
//         community.value = data["community"] ?? 0;
//         challengesCompleted.value = data["challengesCompleted"] ?? 0;

//         // JSON structure onujayi nested data check korun
//         if (data["myCommunity"] != null) {
//           // .value assign korar shomoy null check o string conversion nishchit korun
//           communityName.value =
//               data["myCommunity"]["name"]?.toString() ?? "No Name";
//           communityImage.value =
//               data["myCommunity"]["imageUrl"]?.toString() ?? "";

//           log("✅ Community Updated: ${communityName.value}");
//         } else {
//           log("⚠️ No community found in data");
//         }
//       }
//     } catch (e) {
//       log("❌ Error in getMyStats: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> loadInitialData() async {
//     // 1. Storage theke ID nilam
//     int? savedId = await UserPreference.getUserId();

//     if (savedId != null && savedId != 0) {
//       // 2. Apnar function-ti dynamic ID diye call korlam
//       await getMyStats(savedId);
//     } else {
//       print("User ID zero or null in storage");
//     }
//   }
// }
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/resturant_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';

class AllStatsController extends GetxController {
  var spotsVisited = 0.obs;
  var friends = 0.obs;
  var community = 0.obs;
  var challengesCompleted = 0.obs;
  var communityName = "".obs;
  var communityImage = "".obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var myCommunityId = 0.obs;
  RxString lastCommunityImage = ''.obs;

  int? _savedUserId;

  /// When false, onInit does NOT auto-load the logged-in user's stats. Used by
  /// FriendsStats so it doesn't race the friend load with an own-stats load.
  final bool autoLoadOwn;
  AllStatsController({this.autoLoadOwn = true});

  /// Single shared, PERMANENT instance. Using one stable instance (instead of a
  /// fenix binding + scattered Get.put) avoids instance churn where one instance
  /// loads data while a screen's Obx reads a different (empty) one — which left
  /// the stats screen stuck on an infinite shimmer.
  static AllStatsController get instance {
    if (!Get.isRegistered<AllStatsController>()) {
      Get.put(AllStatsController(autoLoadOwn: false), permanent: true);
    }
    return Get.find<AllStatsController>();
  }

  /// Whose stats are currently loaded (own id or a friend id). Used to reload
  /// when the singleton controller is reused for a different user.
  int? currentStatsUserId;
  int? ownUserId;

  // Re-entrancy guards — the screens trigger loads from postFrame callbacks on
  // every rebuild, so without these the same load fires repeatedly and never
  // settles (infinite shimmer).
  bool _loadingInitial = false;
  int? _loadingForUserId;

  /// The viewed user's friends list (each item carries friendshipStatus from
  /// the viewer's perspective) — powers the friends-of-friends drill-down.
  final RxList<Map<String, dynamic>> friendFriends =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (autoLoadOwn) loadInitialData();
  }

  /// Load full stats (numbers + challenges + spots) for any user id.
  Future<void> loadStatsForUser(int userId) async {
    if (_loadingForUserId == userId) return; // already loading this user
    _loadingForUserId = userId;
    currentStatsUserId = userId; // set first so concurrent builds don't re-fire
    isLoading.value = true;
    hasError.value = false;
    // Clear previous user's values so no stale data flashes before the response.
    spotsVisited.value = 0;
    friends.value = 0;
    community.value = 0;
    challengesCompleted.value = 0;
    communityName.value = "";
    communityImage.value = "";
    myCommunityId.value = 0; // reset so a previous user's community doesn't leak
    lastCommunityImage.value = "";
    completedChallenges.clear();
    visitedSpotsList.clear();
    friendFriends.clear();
    try {
      await Future.wait([
        // setCommunity:false — the stats endpoint's `myCommunity` reflects the
        // logged-in user, not the friend, so don't let it leak our own community
        // into the friend's view. The friend's community is loaded from their
        // profile in _loadFriendFriends instead.
        getMyStats(userId, silent: true, setCommunity: false),
        getCompletedChallenges(userId),
        getVisitedSpots(userId),
        _loadFriendFriends(userId),
      ]);
    } catch (e) {
      log("❌ loadStatsForUser error: $e");
      hasError.value = true;
    } finally {
      isLoading.value = false;
      _loadingForUserId = null;
    }
  }

  /// Load the viewed user's friends list (for the friends-of-friends list)
  /// AND their community. The stats endpoint's `myCommunity` is empty for other
  /// users, so derive the friend's community from their profile here — the same
  /// source the FriendsProfile screen uses (most recent community).
  Future<void> _loadFriendFriends(int userId) async {
    try {
      final data = await ApiService.getanyUserProfile(userId);
      if (data['friends'] is List) {
        friendFriends.value = List<Map<String, dynamic>>.from(data['friends']);
      } else {
        friendFriends.clear();
      }

      if (data['communities'] is List &&
          (data['communities'] as List).isNotEmpty) {
        final comms = List<Map<String, dynamic>>.from(data['communities']);
        final last = comms.last;
        // Prefer the most recent community that actually has an image.
        final lastWithImage = comms.reversed.firstWhere(
          (c) => (c['imageUrl'] ?? '').toString().isNotEmpty,
          orElse: () => last,
        );
        community.value = comms.length;
        communityName.value = (last['name'] ?? '').toString();
        communityImage.value =
            (last['imageUrl'] ?? lastWithImage['imageUrl'] ?? '').toString();
        final rawId = last['id'];
        myCommunityId.value =
            rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
      }
    } catch (e) {
      friendFriends.clear();
      log("⚠️ _loadFriendFriends error: $e");
    }
  }

  /// Refresh stats data — call this when returning from a child screen
  Future<void> refreshStats() async {
    if (_savedUserId != null && _savedUserId != 0) {
      await Future.wait([
        getMyStats(_savedUserId!, silent: true),
        loadMostRecentCommunityImage(),
      ]);
    }
  }

  Future<void> getMyStats(
    int userId, {
    bool silent = false,
    bool setCommunity = true,
  }) async {
    try {
      if (!silent) isLoading.value = true;

      final data = await ApiService.fetchUserStats(userId);

      if (data != null) {
        spotsVisited.value = data["spotsVisited"] ?? 0;
        friends.value = data["friends"] ?? 0;
        challengesCompleted.value = data["challengesCompleted"] ?? 0;

        if (setCommunity) {
          community.value = data["community"] ?? 0;
          if (data["myCommunity"] != null) {
            myCommunityId.value = data["myCommunity"]["id"] ?? 0;
            communityName.value =
                data["myCommunity"]["name"]?.toString() ?? "No Name";
            communityImage.value =
                data["myCommunity"]["imageUrl"]?.toString() ?? "";
          }
        }
      }
    } catch (e) {
      log("❌ Error in getMyStats: $e");
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> loadInitialData() async {
    if (_loadingInitial) return; // already loading own stats — don't re-fire
    _loadingInitial = true;
    isLoading.value = true;
    hasError.value = false;

    _savedUserId = await UserPreference.getUserId();

    if (_savedUserId == null || _savedUserId == 0) {
      log("⚠️ User ID zero or null in storage. Fetching from profile API...");
      try {
        final profileResponse = await ApiService.fetchUserProfile();
        if (profileResponse.statusCode == 200) {
          final jsonData = jsonDecode(profileResponse.body);
          final data = jsonData['data'];
          if (data != null && data['id'] != null) {
            _savedUserId = int.tryParse(data['id'].toString());
          }
        }
      } catch (e) {
        log("❌ Error fetching profile to get User ID: $e");
      }
    }

    if (_savedUserId != null && _savedUserId != 0) {
      log("✅ Loading data for User ID: $_savedUserId");
      ownUserId = _savedUserId;
      currentStatsUserId = _savedUserId; // own stats now loaded

      try {
        await Future.wait([
          // silent: these must NOT touch `isLoading` — loadInitialData owns it
          // and clears the shimmer only after ALL of them finish (no 0 flash).
          getMyStats(_savedUserId!, silent: true),
          getCompletedChallenges(_savedUserId!, silent: true),
          getVisitedSpots(_savedUserId!),
          // Load community name/image up front too, so the "My Community" item
          // doesn't flash a placeholder after the shimmer ends.
          loadMostRecentCommunityImage(),
        ]);
      } catch (e) {
        log("❌ loadInitialData error: $e");
        hasError.value = true;
      }
    } else {
      log("⚠️ Could not retrieve User ID.");
      hasError.value = true;
    }

    isLoading.value = false;
    _loadingInitial = false;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////

  var completedChallenges = <dynamic>[].obs;

  Future<void> getCompletedChallenges(int userId, {bool silent = false}) async {
    try {
      // When driven by loadInitialData, that method owns `isLoading` (awaits ALL
      // fetches before clearing the shimmer). Toggling it here too let this
      // fetch finish first and open the gate while stats were still 0 → the
      // "0 flash". silent=true keeps this off the master flag.
      if (!silent) isLoading.value = true;
      completedChallenges.clear(); // আগের ডাটা ক্লিয়ার করুন

      final response = await ApiService.fetchCompletedChallenges(userId);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        log("✅ Completed Challenges Response: $responseData");
        log("✅ User ID for Challenges: $userId");
        // ১. পোস্টম্যান অনুযায়ী ডাটা "success": true কি না চেক করুন
        if (responseData['success'] == true && responseData['data'] != null) {
          // ২. ডাটাগুলো "data" কি-এর ভেতর থেকে নিয়ে এসাইন করুন
          List<dynamic> fetchedData = responseData['data'];
          completedChallenges.assignAll(fetchedData);

          log("✅ Challenges Loaded: ${completedChallenges.length}");
        } else {
          // যদি ফ্রেন্ড না হয় বা অন্য মেসেজ আসে
          log("⚠️ Server Message: ${responseData['message']}");
        }
      } else {
        log("❌ Failed to fetch: ${response.body}");
      }
    } catch (e) {
      log("⚠️ Exception in getCompletedChallenges: $e");
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  var isSpotsLoading = false.obs;
  var visitedSpotsList = <dynamic>[].obs;

  /// Ensure the shared controller holds the LOGGED-IN user's visited spots
  /// before opening [SpotsVisitedScreen] straight from the profile. The screen
  /// itself never loads (so it can't clobber a friend's list), so callers on the
  /// own-profile path must prime it here. Reloads when the controller currently
  /// holds a different user's spots, or nothing yet.
  Future<void> ensureOwnSpotsLoaded() async {
    int? uid = ownUserId ?? _savedUserId;
    // Already showing this user's freshly-loaded spots — nothing to do.
    if (uid != null &&
        uid != 0 &&
        currentStatsUserId == uid &&
        visitedSpotsList.isNotEmpty) {
      return;
    }
    // Show the shimmer immediately so no "No visited spots" flashes while we
    // resolve the id / fetch.
    isSpotsLoading.value = true;
    uid ??= await UserPreference.getUserId();
    if (uid == null || uid == 0) {
      // Fall back to the full init, which resolves the id via the profile API.
      await loadInitialData();
      isSpotsLoading.value = false;
      return;
    }
    ownUserId = uid;
    currentStatsUserId = uid;
    await getVisitedSpots(uid);
  }

  /// placeId → resolved Google Place photo URL, for spots whose check-in had no
  /// evidence photo (or whose photo was cleaned up). Cached so the Spots Visited
  /// list resolves each place only once. '' means "looked up, no photo found".
  final Map<String, String> _placePhotoCache = {};

  /// Fetch the place's own photo as a fallback image for a visited spot. Uses
  /// the existing place-details endpoint (same one the row tap uses), so no
  /// backend change is needed.
  Future<String> resolvePlacePhoto(String placeId) async {
    if (placeId.isEmpty) return '';
    final cached = _placePhotoCache[placeId];
    if (cached != null) return cached;
    try {
      final model = await ApiService.placeFetched(placeId);
      String url = model?.image.trim() ?? '';
      if (url.isEmpty && model != null && model.photos.isNotEmpty) {
        url = model.photos.first.trim();
      }
      _placePhotoCache[placeId] = url;
      return url;
    } catch (e) {
      log('⚠️ resolvePlacePhoto($placeId) failed: $e');
      _placePhotoCache[placeId] = '';
      return '';
    }
  }

  Future<void> getVisitedSpots(int userId) async {
    try {
      isSpotsLoading.value = true;
      final response = await ApiService.fetchSportVisited(userId);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        log(response.statusCode.toString());
        log(response.body);
        List<dynamic> fetchedList = responseData['data'] ?? [];
        visitedSpotsList.assignAll(fetchedList);
        log("✅ Visited Spots Loaded: ${visitedSpotsList.length}");
      } else {
        log("❌ Failed to fetch spots: ${responseData['message']}");
      }
    } catch (e) {
      log("⚠️ Exception in getVisitedSpots: $e");
    } finally {
      isSpotsLoading.value = false;
    }
  }

  // রেস্টুরেন্ট মডেলের একটি অবজার্ভেবল অবজেক্ট
  var restaurant = Rxn<RestaurantModel>();

  Future<void> getDetails(String placeId) async {
    try {
      isLoading.value = true;

      // এখন 'result' এর টাইপ হবে RestaurantModel? (Response নয়)
      final result = await ApiService.placeFetched(placeId);

      if (result != null) {
        restaurant.value = result;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMostRecentCommunityImage() async {
    try {
      final response = await ApiService.fetchRecentCommunities();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['mostRecent'] != null && data['mostRecent'] is Map) {
          final mostRecent = data['mostRecent'];
          lastCommunityImage.value = mostRecent['imageUrl'] ?? '';
          // Update id and name so the tile shows the joined community
          // and tapping it navigates correctly
          final recentId = mostRecent['id'] ?? 0;
          final recentName = mostRecent['name']?.toString() ?? '';
          if (recentId != 0) myCommunityId.value = recentId;
          if (recentName.isNotEmpty) communityName.value = recentName;
          log("✅ Most recent community: id=$recentId, name=$recentName");
        } else {
          lastCommunityImage.value = '';
          log("⚠️ No most recent community found");
        }
      } else {
        lastCommunityImage.value = '';
        log("❌ API Error: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      lastCommunityImage.value = '';
      log("❌ Exception fetching community image: $e");
      log("StackTrace: $stackTrace");
    }
  }
}
