import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/frienlist_model.dart';
import 'package:outspot/Model/recomended_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/Notification1/notification_controller.dart';
import 'package:outspot/main.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class FriendListController extends GetxController
    with SingleGetTickerProviderMixin {
  // --- Data stores
  var friends = <FriendModel>[].obs; // (legacy)
  var friends1 = <FriendsModel>[].obs; // current friends (API)
  RxList<FriendsModel> requests = <FriendsModel>[].obs;
  var isLoading = false.obs;

  var recommendedFriends = <RecommendedFriend>[].obs;
  var expandedIndex = (-1).obs; // -1 মানে কিছু expand হয়নি

  // --- Tabs
  late TabController tabController;

  // --- Extra lists (legacy placeholders)
  RxList<FriendModel> requests1 = <FriendModel>[].obs;
  RxList<FriendModel> recommended = <FriendModel>[].obs;

  // --- Search
  RxString query = ''.obs;
  RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  RxBool isSearching = false.obs;
  Timer? _debounce;

  // --- Auto refresh (polling)
  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 10);
  @override
  void onReady() {
    ever(friends1, (_) {
      // friend list changed
      print("Friend list updated");
    });
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    // Open Requests tab if navigated from notification
    final args = Get.arguments;
    if (args is Map && args['tab'] != null) {
      tabController.index = args['tab'] as int;
    }

    // Initial fetches
    searchUserByName("");
    loadFriendList();
    loadIncomingRequests();
    fetchRecommended();

    // 🔄 Start polling so new requests appear without reopening the screen
    _startPolling();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _pollTimer?.cancel();
    tabController.dispose();
    super.onClose();
  }

  void clearSearch() {
    searchResults.clear();
    query.value = '';
  }

  // -------------------- Helpers --------------------

  List<FriendsModel> get filteredFriends {
    if (query.value.isEmpty) return friends1;
    final q = query.value.toLowerCase();
    return friends1.where((friend) {
      final fullName = friend.fullName.toLowerCase();
      final username = friend.username.toLowerCase();
      return fullName.contains(q) || username.contains(q);
    }).toList();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        // Refresh incoming requests
        await loadIncomingRequests();

        // 🔹 Refresh friend list from server
        await loadFriendList();

        // 🔹 Sync friend count in MyProfileController
        if (Get.isRegistered<MyProfileController>()) {
          final profileController = Get.find<MyProfileController>();
          profileController.friendCount.value = friends1.length;
          log("🔄 Friend count synced: ${profileController.friendCount.value}");
        }
      } catch (e) {
        log("Polling error: $e");
      }
    });
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadFriendList(),
      loadIncomingRequests(),
      fetchRecommended(),
    ]);
  }

  Future<void> fetchRecommended() async {
    try {
      final response = await ApiService.fetchRecommendedFriends();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data["recommended"] != null) {
          recommendedFriends.assignAll(
            (data["recommended"] as List)
                .map((e) => RecommendedFriend.fromJson(e))
                .toList(),
          );
        }
      } else {
        print("⚠️ fetchRecommended failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ fetchRecommended exception: $e");
    }
  }

  // -------------------- API Calls --------------------

  Future<void> loadFriendList() async {
    try {
      if (friends1.isEmpty) isLoading.value = true;
      final response = await ApiService.fetchFriendList();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          final List<dynamic> data = jsonData['data'];

          // Update friends list
          friends1.value = data.map((e) => FriendsModel.fromJson(e)).toList();
          log("Loaded ${friends1.length} friends from server.");

          // 🔹 Sync friend count automatically
          if (Get.isRegistered<MyProfileController>()) {
            Get.find<MyProfileController>().friendCount.value = friends1.length;
            log("🔄 Friend count synced: ${friends1.length}");
          }
        } else {
          AppSnackbar.error(jsonData['message'] ?? 'Failed to fetch friends');
        }
      } else {
        AppSnackbar.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadIncomingRequests() async {
    try {
      final response = await ApiService.incomingFriendRequestsList();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] is List) {
          final List<dynamic> data = jsonData['data'];
          final fresh =
              data.map((item) => FriendsModel.fromJson(item)).toList();

          // ✅ Only update if changed to avoid unnecessary rebuilds
          if (!_listEqualsById(requests, fresh)) {
            requests.value = fresh;
          }
        } else {
          AppSnackbar.error(jsonData['message'] ?? 'Failed to fetch requests');
        }
      } else {
        AppSnackbar.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  // -------------------- Actions --------------------

  // Future<void> acceptFriendRequest(FriendsModel friend) async {
  //   try {
  //     final res = await ApiService.acceptFriendRequest(friend.id);
  //     final data = jsonDecode(res.body.isEmpty ? '{}' : res.body);

  //     final ok = (res.statusCode == 200) &&
  //         (data["message"] == "Friend request accepted." || data['success'] == true);

  //     if (ok) {
  //       log("✅ Friend request accepted for id=${friend.id}");

  //       // 1️⃣ Remove from requests immediately
  //       requests.removeWhere((f) => f.id == friend.id);

  //       // 2️⃣ Add to friend list instantly (avoid duplicate)
  //       if (!friends1.any((f) => f.id == friend.id)) {
  //         friends1.add(friend);
  //       }

  //       if (Get.isRegistered<MyProfileController>()) {
  //         Get.find<MyProfileController>().incrementFriendCount();
  //       }

  //       Get.snackbar(
  //         "Success",
  //         "Friend request accepted.",
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.green,
  //         colorText: Colors.white,
  //       );

  //       // 3️⃣ 🔔 Trigger notification via Notification1Controller
  //       if (Get.isRegistered<Notification1Controller>()) {
  //         Get.find<Notification1Controller>().handleIncomingFriendAccept(friend);
  //       }

  //       // 4️⃣ Optional: Refresh list from server silently
  //       // await loadFriendList();
  //     } else {
  //       Get.snackbar(
  //         "Error",
  //         (data["message"] ?? "Failed to accept request."),
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       "Error",
  //       "Something went wrong",
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  Future<void> acceptFriendRequest(FriendsModel friend) async {
    try {
      final res = await ApiService.acceptFriendRequest(friend.id);
      final data = jsonDecode(res.body.isEmpty ? '{}' : res.body);

      final ok =
          (res.statusCode == 200) &&
          (data["message"] == "Friend request accepted." ||
              data['success'] == true);

      if (ok) {
        log("✅ Friend request accepted for id=${friend.id}");

        // 1️⃣ Remove from requests immediately
        requests.removeWhere((f) => f.id == friend.id);

        // 2️⃣ Add to friend list instantly (avoid duplicate)
        if (!friends1.any((f) => f.id == friend.id)) {
          friends1.add(friend);
        }

        if (Get.isRegistered<MyProfileController>()) {
          Get.find<MyProfileController>().incrementFriendCount();
        }

        AppSnackbar.success("Friend request accepted.");

        // 3️⃣ 🔔 Trigger notification via Notification1Controller
        if (Get.isRegistered<Notification1Controller>()) {
          Get.find<Notification1Controller>().handleIncomingFriendAccept(
            friend,
          );
        }

        // // 4️⃣ ✅ Local Notification দেখানো
        // _showNotificationForFriend(friend);
      } else {
        AppSnackbar.error((data["message"] ?? "Failed to accept request."));
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong");
    }
  }

  /// Decline / cancel friend request
  Future<void> declineRequest(FriendsModel friend) async {
    try {
      log("Sending decline request for friendId: ${friend.id}");
      final res = await ApiService.declineFriendRequest(friend.id);
      log("API Response: ${res.statusCode} => ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204) {
        // ✅ Remove from UI immediately
        requests.removeWhere((f) => f.id == friend.id);

        AppSnackbar.success("Friend request declined.");
        log("Friend request declined for ${friend.id}");
      } else {
        final message =
            res.body.isNotEmpty
                ? (json.decode(res.body)['message'] ??
                    "Failed to decline request")
                : "Failed to decline request";
        AppSnackbar.error(message);
        log("Failed to decline request: $message");
      }
    } catch (e) {
      log("Exception in declineRequest: $e");
      AppSnackbar.error("Something went wrong");
    }
  }

  /// Cancel an outgoing (PENDING_SENT) friend request from the friends tab
  Future<void> cancelSentRequest(FriendsModel friend) async {
    try {
      // Remove from UI instantly
      friends1.removeWhere((f) => f.id == friend.id);

      final res = await ApiService.cancelSentRequest(friend.id);
      if (res.statusCode == 200 || res.statusCode == 204) {
        AppSnackbar.success("Request cancelled.");
      } else {
        // Re-fetch to restore correct state on failure
        await loadFriendList();
        final msg =
            res.body.isNotEmpty
                ? (json.decode(res.body)['message'] ??
                    "Failed to cancel request")
                : "Failed to cancel request";
        AppSnackbar.error(msg);
      }
    } catch (e) {
      await loadFriendList();
      AppSnackbar.error("Something went wrong");
    }
  }

  // -------------------- Search --------------------

  // Live Search Debounce
  void onSearchChanged(String queryStr) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchUserByName(queryStr);
      query.value = queryStr;
    });
  }

  // Search API Call
  Future<void> searchUserByName(String name) async {
    if (name.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isSearching.value = true;
      final response = await ApiService.searchUsers(name);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] is List) {
          searchResults.value = List<Map<String, dynamic>>.from(data["data"]);
        } else {
          searchResults.clear();
        }
      } else {
        log("Search error: ${response.statusCode} => ${response.body}");
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      isSearching.value = false;
    }
  }

  // -------------------- Utils --------------------

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

  //////////////////////////////////////////////////////////////////////////////////
  ///
  ///
  ///
  ////// Increment friend count (accept friend request)
  void handleFriendAccepted(FriendsModel friend) {
    // Remove from requests list
    requests.removeWhere((f) => f.id == friend.id);

    // Add to friend list if not already present
    if (!friends1.any((f) => f.id == friend.id)) {
      friends1.add(friend);
    }

    // Increment global friend count in MyProfileController
    if (Get.isRegistered<MyProfileController>()) {
      Get.find<MyProfileController>().incrementFriendCount();
    }

    log("✅ Friend accepted: ${friend.fullName}");
  }

  //   Future<void> _showNotificationForFriend(FriendsModel friend) async {
  //   const AndroidNotificationDetails androidDetails =
  //       AndroidNotificationDetails(
  //     'friend_channel', // channel id
  //     'Friend Notifications', // channel name
  //     channelDescription: 'Notifications for friend requests',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );

  //   const NotificationDetails platformDetails =
  //       NotificationDetails(android: androidDetails);

  //   await flutterLocalNotificationsPlugin.show(
  //     0, // notification ID
  //     'Friend Request Accepted 🎉',
  //     '${friend.fullName} accepted your friend request.',
  //     platformDetails,
  //     payload: friend.id.toString(),
  //   );
  // }
}
