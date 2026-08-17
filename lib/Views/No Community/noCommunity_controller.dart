import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outspot/Model/community_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Views/Community/community_controller.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';

import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/No%20Community/allCommunities.dart';
import 'package:outspot/Views/No%20Community/memberPage.dart';
import 'package:outspot/Views/No%20Community/searchCommunity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class NocommunityController extends GetxController {
  // Controllers
  TextEditingController newCommunityController = TextEditingController();
  // Community bio (optional) — used by the create & edit forms.
  TextEditingController bioController = TextEditingController();

  // Loading state
  var isLoading = false.obs;
  RxBool isEdit = false.obs;
  var groupImage = "".obs;
  var communityId = 0.obs;
  var createdCommunities = <CommunityModel>[].obs;
  var joinedCommunities = <CommunityModel>[].obs;

  // Communities list
  var communities = <Map<String, dynamic>>[].obs;
  var filteredCommunities = <Map<String, dynamic>>[].obs;

  // Picked image
  var pickedImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();
  var existingCommunityName = ''.obs;
  var existingCommunityImage = ''.obs;
  var existingCommunityBio = ''.obs;

  // Community details
  final RxList<dynamic> membersList = <dynamic>[].obs;
  final RxBool hasJoined = false.obs;
  final RxString communityName = "".obs;
  final RxString communityImage = "".obs;
  final RxString communityBio = "".obs;

  // Current user ID
  RxString currentUserId = "".obs;
  // Community owner's id
  final RxString creatorId = "".obs;
  RxMap<String, dynamic> communityData = <String, dynamic>{}.obs;

  RxBool isCreator = false.obs;
  final hasLoadedOnce = false.obs;

  bool get isOwnCommunity => isCreator.value;
  @override
  void onInit() {
    super.onInit();
    loadCurrentUserId();
    fetchInitialCommunities();
    fetchMyCommunities();
    final args = Get.arguments as Map<String, dynamic>?;
    final communityId = args?["communityId"] ?? 0;

    if (communityId != 0) {
      loadExistingCommunity(communityId);
      getMyCommunities();
    }
  }

  @override
  void onClose() {
    // newCommunityController.dispose();
    super.onClose();
  }

  /// Refresh all community data — call after join/leave/create/delete
  Future<void> refreshAll() async {
    await Future.wait([fetchMyCommunities(), fetchInitialCommunities()]);
  }

  Future<void> fetchMyCommunities() async {
    try {
      isLoading.value = true;
      final response = await ApiService.myCommunity();

      if (response.statusCode == 200) {
        log(response.body);
        final data = jsonDecode(response.body);

        if (data['items'] != null) {
          // clear previous data before adding new
          createdCommunities.clear();
          joinedCommunities.clear();

          final allCommunities =
              (data['items'] as List)
                  .map((e) => CommunityModel.fromJson(e))
                  .toList();

          createdCommunities.addAll(
            allCommunities.where((c) => c.isCreator == true),
          );
          joinedCommunities.addAll(
            allCommunities.where((c) => c.isCreator != true),
          );
          refreshFilteredList();
        }
      } else {
        print("⚠️ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ fetchMyCommunities exception: $e");
    } finally {
      isLoading.value = false;
      hasLoadedOnce.value = true;
    }
  }

  /// Load current user ID from SharedPreferences
  Future<void> loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('profile_data');
      if (profileStr != null) {
        final Map<String, dynamic> profile = jsonDecode(profileStr);
        currentUserId.value = profile["id"].toString();
        log("🔹 Current User ID loaded: ${currentUserId.value}");
      } else {
        currentUserId.value = "";
        log("⚠️ No profile found in SharedPreferences");
      }
    } catch (e) {
      log("⚠️ Failed to load current user ID: $e");
      currentUserId.value = "";
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        pickedImage.value = File(image.path);
        log("✅ Picked Image: ${image.path}");
      }
    } catch (e) {
      log("⚠️ Failed to pick image: $e");
    }
  }

  // Future<void> createCommunity() async {
  //   final name = communityName.value.trim();
  //   if (name.isEmpty) {
  //     AppSnackbar.error("Community name is required");
  //     return;
  //   }

  //   isLoading.value = true;

  //   try {
  //     final res = await ApiService.createCommunity(
  //       name: name,
  //       imageFile: pickedImage.value, // optional
  //     );

  //     if (res.statusCode == 200 || res.statusCode == 201) {
  //       AppSnackbar.success("Community created successfully");
  //       newCommunityController.clear();
  //       Get.to(() => Allcommunities());

  //       // Optional: reset fields
  //       pickedImage.value = null;
  //       communityName.value = '';
  //       // Get.find<MessagesScreenController>().fetchChats();
  //       await Get.find<MyProfileController>().loadMostRecentCommunityImage();
  //       // Optional: fetch communities again
  //       // await fetchCommunities();
  //     } else {
  //       String msg =
  //           res.body.isNotEmpty
  //               ? jsonDecode(res.body)['message'] ??
  //                   'Failed to create community'
  //               : 'Failed to create community';
  //       AppSnackbar.error(msg);
  //     }
  //   } catch (e) {
  //     AppSnackbar.error(e.toString());
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  Future<void> createCommunity() async {
    final name =
        newCommunityController.text.trim(); // সরাসরি কন্ট্রোলার থেকে টেক্সট নিন

    // ১. ভ্যালিডেশন: নাম খালি কি না
    if (name.isEmpty) {
      AppSnackbar.error("Community name is required");
      return;
    }

    // ২. ভ্যালিডেশন: ইউজার অলরেডি কোনো কমিউনিটিতে আছে কি না
    // আপনার লজিক অনুযায়ী createdCommunities বা joinedCommunities খালি না থাকলে সে অলরেডি মেম্বার
    if (createdCommunities.isNotEmpty || joinedCommunities.isNotEmpty) {
      AppSnackbar.error(
        "Limit Reached: You are already a member of a community. Please leave or delete your current community to create a new one.",
      );
      return;
    }

    try {
      // EasyLoading শুরু
      AppLoading.show();
      isLoading.value = true;

      final bio = bioController.text.trim();
      final res = await ApiService.createCommunity(
        name: name,
        imageFile: pickedImage.value,
        bio: bio.isEmpty ? null : bio,
      );

      AppLoading.hide();
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppSnackbar.success("Community created successfully");
        newCommunityController.clear();
        bioController.clear();
        pickedImage.value = null;
        await getMyCommunities();

        // ডাটা রিফ্রেশ করা যাতে লিস্ট আপডেট হয়
        await refreshAll();

        Get.off(() => Allcommunities()); // সরাসরি অল কমিউনিটিতে নিয়ে যাওয়া
      } else {
        final errorData = jsonDecode(res.body);
        AppSnackbar.error(errorData['message'] ?? 'Failed to create community');
      }
    } catch (e) {
      AppLoading.hide();
      AppSnackbar.error("An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }
  // ==================== Communities list ====================

  // Future<void> getAllCommunities() async {
  //   try {
  //     isLoading.value = true;
  //     final response = await ApiService.fetchAllCommunities();

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonData = jsonDecode(response.body);
  //       log("${jsonData}");
  //       if (jsonData["items"] is List) {
  //         final List<dynamic> data = jsonData["items"];

  //         // Convert each community to RxMap for reactivity
  //         communities.value =
  //             data.map((c) => RxMap<String, dynamic>.from(c)).toList();

  //         filteredCommunities.assignAll(communities);

  //         log("✅ Communities loaded: ${communities.length}");
  //       } else {
  //         log("⚠️ items is not a List: ${jsonData["items"]}");
  //       }
  //     } else {
  //       AppSnackbar.error("Failed to load communities");
  //       log("❌ fetchAllCommunities failed: ${response.body}");
  //     }
  //   } catch (e) {
  //     AppSnackbar.error("Something went wrong");
  //     log("⚠️ Exception in getAllCommunities: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  var skip = 0.obs;
  final int take = 10;
  var hasMoreData = true.obs;
  var isMoreLoading = false.obs;

  Future<void> fetchInitialCommunities() async {
    try {
      skip.value = 0;
      hasMoreData.value = true;
      isLoading.value = true;

      final response = await ApiService.fetchAllCommunities(
        skip: 0,
        take: take,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List items = jsonData["items"] ?? [];

        communities.assignAll(
          items.map((c) => RxMap<String, dynamic>.from(c)).toList(),
        );
        filteredCommunities.assignAll(communities);

        // যদি আইটেম সংখ্যা 'take' এর চেয়ে কম হয়, তার মানে আর ডাটা নেই
        if (items.length < take) {
          hasMoreData.value = false;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

 
  Future<void> loadMoreCommunities() async {
    if (isMoreLoading.value || !hasMoreData.value) return;

    try {
      isMoreLoading.value = true;
      skip.value += take; 

      final response = await ApiService.fetchAllCommunities(
        skip: skip.value,
        take: take,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List items = jsonData["items"] ?? [];

        if (items.isEmpty || items.length < take) {
          hasMoreData.value = false; // ডাটা শেষ
        }

        final newItems =
            items.map((c) => RxMap<String, dynamic>.from(c)).toList();
        communities.addAll(newItems);
        filteredCommunities.addAll(newItems);
      }
    } finally {
      isMoreLoading.value = false;
    }
  }

  /// সার্চ ফিল্টার
  void filterCommunities(String query) {
    if (query.isEmpty) {
      filteredCommunities.assignAll(communities);
    } else {
      filteredCommunities.assignAll(
        communities.where(
          (c) => (c['name'] ?? '').toString().toLowerCase().contains(
            query.toLowerCase(),
          ),
        ),
      );
    }
  }

  // // ==================== Fetch single community details ====================
  // Future<void> fetchCommunityDetails(int communityId) async {
  //   try {
  //     final response = await ApiService.fetchCommunityDetails(communityId);

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       // ✅ Reactive assignment ensures UI rebuild
  //       communityName.value = (data["name"] ?? "Unknown").toString();
  //       communityImage.value = (data["imageUrl"] ?? "").toString();

  //       // ✅ Members update
  //       if (data["members"] != null && data["members"] is List) {
  //         membersList.assignAll(
  //           List<Map<String, dynamic>>.from(data["members"]),
  //         );
  //       } else {
  //         membersList.clear();
  //       }

  //       log("🔹 Community: ${communityName.value}");
  //       log("🔹 Members count: ${membersList.length}");
  //     } else {
  //       AppSnackbar.error("Failed to load community details");
  //       log("❌ fetchCommunityDetails failed: ${response.body}");
  //     }
  //   } catch (e) {
  //     AppSnackbar.error("Something went wrong: $e");
  //     log("⚠️ Exception in fetchCommunityDetails: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  RxnInt communityChatId = RxnInt(); // nullable int
  RxBool isMember = false.obs;

  Future<void> fetchCommunityDetails(int communityId) async {
    try {
      isLoading.value = true;

      final response = await ApiService.fetchCommunityDetails(communityId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Basic info
        communityName.value = (data["name"] ?? "Unknown").toString();
        communityImage.value = (data["imageUrl"] ?? "").toString();
        communityBio.value = (data["bio"] ?? "").toString();

        // ✅ NEW: Chat ID
        communityChatId.value = data["chatId"];

        // ✅ NEW: Membership flags
        isMember.value = data["isMember"] ?? false;
        isCreator.value = data["isCreator"] ?? false;

        // ✅ Members list (already sorted from backend)
        if (data["members"] != null && data["members"] is List) {
          membersList.assignAll(
            List<Map<String, dynamic>>.from(data["members"]),
          );
        } else {
          membersList.clear();
        }

        log("🔹 Community: ${communityName.value}");
        log("🔹 Chat ID: ${communityChatId.value}");
        log("🔹 isMember: ${isMember.value}");
        log("🔹 isCreator: ${isCreator.value}");
        log("🔹 Members count: ${membersList.length}");
      } else {
        AppSnackbar.error("Failed to load community details");
        log("❌ fetchCommunityDetails failed: ${response.body}");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong");
      log("⚠️ Exception in fetchCommunityDetails: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // // ==================== Join Community ====================
  // Future<void> joinCommunity(int communityId) async {
  //   try {
  //     if (isCreator.value) return; // creator হলে join button না দেখানোর logic

  //     isLoading.value = true;
  //     final response = await ApiService.joinCommunity(communityId);

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       if (data['message'] == "Joined community & added to chat") {
  //         hasJoined.value = true;
  //         AppSnackbar.success(data['message']);
  //         await fetchCommunityDetails(communityId); // members update
  //       } else {
  //         AppSnackbar.error(data['message'] ?? "Failed to join");
  //       }
  //       // Get.find<MessagesScreenController>().fetchChats();
  //       await Get.find<MyProfileController>().loadMostRecentCommunityImage();
  //     } else {
  //       AppSnackbar.error("Already a member");
  //     }
  //   } catch (e) {
  //     AppSnackbar.error("Something went wrong: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  Future<void> joinCommunity(int communityId) async {
    try {
      AppLoading.show();
      isLoading.value = true;
      final response = await ApiService.joinCommunity(communityId);
      AppLoading.hide();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Safely refresh chats if controller exists
        try {
          if (Get.isRegistered<MessagesScreenController>()) {
            Get.find<MessagesScreenController>().fetchChats();
          }
        } catch (_) {}

        if (data['message'] == "Joined community & added to chat") {
          hasJoined.value = true;
          _addToJoinedList(communityId);
          AppSnackbar.success(data['message']);
        } else {
          AppSnackbar.error(data['message'] ?? "Failed to join");
        }
      } else if (response.statusCode == 409) {
        AppSnackbar.error(
          "You are already in a community. Leave it first to join another one.",
        );
        log("⚠️ Join failed with status 409: ${response.body}");
        return;
      } else if (response.statusCode == 400) {
        _addToJoinedList(communityId);
        AppSnackbar.error("You are already a member of this community");
        log("⚠️ Join failed with status 400: ${response.body}");
      } else if (response.statusCode == 403) {
        // Banned (or otherwise forbidden) — surface the server's reason, e.g.
        // "You are banned from this community".
        String msg = "You are banned from this community";
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] is String) {
            msg = data['message'];
          } else if (data is Map && data['error'] is String) {
            msg = data['error'];
          }
        } catch (_) {}
        AppSnackbar.error(msg);
        log("🚫 Join forbidden (403): ${response.body}");
        return;
      } else {
        // Any other failure — show the server message if present.
        String msg = "Failed to join";
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] is String) msg = data['message'];
        } catch (_) {}
        AppSnackbar.error(msg);
        log("⚠️ Join failed (${response.statusCode}): ${response.body}");
        return;
      }

      await fetchCommunityDetails(communityId);
      await refreshAll();
      await getMyCommunities();

      // Safely refresh profile community image if controller exists
      try {
        if (Get.isRegistered<MyProfileController>()) {
          await Get.find<MyProfileController>().loadMostRecentCommunityImage();
        }
      } catch (_) {}
    } catch (e) {
      AppLoading.hide();
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Community creator bans a member. Stronger than removal — the server blocks
  /// the banned user from re-joining.
  Future<void> banMember(int communityId, int memberId) async {
    try {
      AppLoading.show();
      final res = await ApiService.banCommunityMember(communityId, memberId);
      AppLoading.hide();

      String? serverMsg;
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['message'] is String) serverMsg = data['message'];
      } catch (_) {}

      if (res.statusCode >= 200 && res.statusCode < 300) {
        membersList.removeWhere(
          (m) => m['id'].toString() == memberId.toString(),
        );
        AppSnackbar.success(serverMsg ?? 'Member banned from community');
      } else {
        AppSnackbar.error(serverMsg ?? 'Failed to ban member');
      }
    } catch (e) {
      AppLoading.hide();
      log('⚠️ banMember error: $e');
      AppSnackbar.error('Something went wrong: $e');
    }
  }

  void _addToJoinedList(int communityId) {
    if (!joinedCommunities.any((c) => c.id == communityId)) {
      joinedCommunities.add(
        CommunityModel(
          id: communityId,
          name: '',
          isMember: true,
          isCreator: false,
          membersCount: 0,
        ),
      );
    }
  }

  Future<void> deleteCommunity(int communityId) async {
    try {
      isLoading.value = true;
      log("🛠️ Deleting community with ID: $communityId");

      final response = await ApiService.deleteCommunity(communityId);
      log("📡 Response status: ${response.statusCode}");
      log("📡 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("📄 Parsed data: $data");

        if (data["message"] == "Community deleted") {
          // Remove from local lists
          communities.removeWhere((c) => c["id"] == communityId);
          filteredCommunities.removeWhere((c) => c["id"] == communityId);
          log("✅ Community removed locally. Remaining: ${communities.length}");
          if (Get.isRegistered<MessagesScreenController>()) {
            Get.find<MessagesScreenController>().fetchChats();
          } else {
            Get.put(MessagesScreenController()).fetchChats();
          }

          // Refresh community lists + history and the profile's community stat —
          // same as leaveCommunityFunc — so the profile updates immediately
          // instead of still showing the just-deleted community.
          await refreshAll();
          await getMyCommunities();
          if (Get.isRegistered<MyProfileController>()) {
            await Get.find<MyProfileController>()
                .loadMostRecentCommunityImage();
          }

          Get.back(); // Close bottom sheet or current dialog/screen
          AppSnackbar.success("Community deleted successfully");
        } else {
          log("⚠️ Deletion failed: ${data["message"]}");
          AppSnackbar.error(data["message"] ?? "Failed to delete community");
        }
      } else {
        log("❌ Response status not 200");
        AppSnackbar.error("Failed to delete community");
      }
    } catch (e) {
      log("⚠️ Exception in deleteCommunity: $e");
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 📝 Age existing community name & image store korar jonno

  TextEditingController editCommunityController = TextEditingController();
  // ================= loadExistingCommunity =================
  void loadExistingCommunity(int communityId) async {
    try {
      isLoading.value = true;

      final response = await ApiService.fetchCommunityDetails(communityId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        existingCommunityName.value = data["name"] ?? '';
        existingCommunityImage.value = data["imageUrl"] ?? '';
        existingCommunityBio.value = data["bio"] ?? '';

        newCommunityController.text = existingCommunityName.value;
        bioController.text = existingCommunityBio.value;

        communityName.value = existingCommunityName.value;
        communityImage.value = existingCommunityImage.value;
        communityBio.value = existingCommunityBio.value;
        membersList.assignAll(data["members"] ?? []);

        final currentMember = membersList.firstWhere(
          (m) => m["id"].toString() == currentUserId.value,
          orElse: () => null,
        );

        isCreator.value = currentMember?["isCreator"] ?? false;
        hasJoined.value = currentMember?["isMember"] ?? false;

        log("🔹 Existing community loaded: ${existingCommunityName.value}");
        log("🔹 hasJoined: ${hasJoined.value}");
        log("🔹 isOwnCommunity: ${isOwnCommunity}");
      } else {
        AppSnackbar.error("Failed to load community data");
        log("❌ loadExistingCommunity failed: ${response.body}");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
      log("⚠️ Exception in loadExistingCommunity: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> leaveCommunityFunc(int communityId) async {
    try {
      AppLoading.show();
      isLoading.value = true;
      log("📡 Sending leave request for community ID: $communityId");

      final response = await ApiService.leaveCommunity(communityId);
      AppLoading.hide();

      log("📡 Response status: ${response.statusCode}");
      log("📡 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? "Successfully left community";
        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        } else {
          Get.put(MessagesScreenController()).fetchChats();
        }
        AppSnackbar.success(message);

        hasJoined.value = false;
        membersList.clear();
        communities.removeWhere((c) => c['id'] == communityId);
        filteredCommunities.removeWhere((c) => c['id'] == communityId);

        // Refresh all data + history
        await refreshAll();
        await getMyCommunities();
        if (Get.isRegistered<MyProfileController>()) {
          await Get.find<MyProfileController>().loadMostRecentCommunityImage();
        }

        log("🔹 Community removed locally. Remaining: ${communities.length}");

        Get.offAll(() => const SearchCommunity());
      } else {
        log("❌ Failed to leave community. Status code: ${response.statusCode}");
        AppSnackbar.error("Failed to leave community: ${response.body}");
      }
    } catch (e) {
      AppLoading.hide();
      log("⚠️ Exception in leaveCommunityFunc: $e");
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if current user is creator of a community
  bool isUserCreator(int communityId) {
    try {
      final community = createdCommunities.firstWhere(
        (c) => c.id == communityId,
        orElse:
            () => CommunityModel(
              id: 0,
              name: '',
              membersCount: 0,
              isCreator: false,
              isMember: false,
            ),
      );
      return community.id != 0;
    } catch (_) {
      return false;
    }
  }

  bool isUserMember(int communityId) {
    try {
      final isJoined = joinedCommunities.any((c) => c.id == communityId);
      final isCreated = createdCommunities.any((c) => c.id == communityId);

      // Only check membersList if it belongs to the same communityId being checked
      bool isInMembersList = false;
      if (this.communityId.value == communityId && membersList.isNotEmpty) {
        isInMembersList = membersList.any(
          (m) => m["id"].toString() == currentUserId.value,
        );
      }

      return isJoined || isCreated || isInMembersList;
    } catch (_) {
      return false;
    }
  }

  /// Update community (name and/or image) and reflect instantly
  Future<void> updateCommunityDetails({
    required int communityId,
    String? newName,
    File? newImage,
    String? newBio,
  }) async {
    if (newName == null && newImage == null && newBio == null) {
      AppSnackbar.error("Nothing to update");
      return;
    }

    try {
      isLoading.value = true;

      final response = await ApiService.updateCommunity(
        id: communityId,
        name: newName,
        imageFile: newImage,
        bio: newBio,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Local reactive update
        if (newName != null) communityName.value = newName;
        if (newImage != null) groupImage.value = newImage.path;
        if (newBio != null) communityBio.value = newBio;

        AppSnackbar.success("Community updated successfully");
        Get.to(() => Allcommunities());

        // Fetch fresh community data and update reactive variables
        final resDetails = await ApiService.fetchCommunityDetails(communityId);
        if (resDetails.statusCode == 200) {
          final data = jsonDecode(resDetails.body);
          communityName.value = data["name"] ?? communityName.value;
          communityImage.value = data["imageUrl"] ?? communityImage.value;
          communityBio.value = data["bio"] ?? communityBio.value;
          membersList.assignAll(data["members"] ?? []);
        }

        final idx = communities.indexWhere((c) => c["id"] == communityId);
        if (idx != -1) {
          communities[idx]["name"] = communityName.value;
          communities[idx]["imageUrl"] = communityImage.value;
        }

        // The community detail screen (CommunityScreen) uses a separate
        // controller and caches details (isLoaded), so it won't re-fetch on
        // return. Refresh it here so the edited name/image/bio show immediately
        // instead of only after a restart.
        if (Get.isRegistered<CommunityController>()) {
          Get.find<CommunityController>().fetchCommunityDetails(communityId);
        }
      } else {
        String msg =
            response.body.isNotEmpty
                ? jsonDecode(response.body)['message'] ?? "Failed to update"
                : "Failed to update";
        AppSnackbar.error(msg);
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Update community and navigate to MembersPage
  Future<void> saveAndGoToMembers(int id) async {
    try {
      isLoading.value = true;

      await updateCommunityDetails(
        communityId: id,
        newName: newCommunityController.text.trim(),
        newImage: pickedImage.value,
        newBio: bioController.text.trim(),
      );

      // Update local variable
      communityName.value = newCommunityController.text;

      AppSnackbar.success("Community updated!");

      // Navigate to MembersPage
      Get.to(() => MembersPage(communityId: id));
    } catch (e) {
      AppSnackbar.error("Failed to update community");
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all fields for creating a new community
  void resetNewCommunity() {
    pickedImage.value = null; // Clear picked image
    communityImage.value = ""; // Clear network image
    newCommunityController.clear(); // Clear text field
    communityName.value = ""; // Clear reactive name
    communityId.value = 0; // Reset ID
  }

  // Full activity history (joined + left actions)
  var communityHistory = <Map<String, dynamic>>[].obs;
  var historyLoaded = false.obs;
  var historyLoading = false.obs;

  // Cache of community member counts fetched on-demand (communityId -> count)
  var memberCounts = <int, int>{}.obs;

  Future<void> fetchMemberCount(int communityId) async {
    if (communityId == 0) return;
    if (memberCounts.containsKey(communityId)) return;
    try {
      final response = await ApiService.fetchCommunityDetails(communityId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final members = data['members'];
        final count = members is List ? members.length : 0;
        memberCounts[communityId] = count;
        memberCounts.refresh();
      }
    } catch (e) {
      log('❌ fetchMemberCount error: $e');
    }
  }

  // Pagination
  static const int _historyPageSize = 20;
  RxInt visibleHistoryCount = _historyPageSize.obs;

  void loadMoreHistory() {
    if (visibleHistoryCount.value < communityHistory.length) {
      visibleHistoryCount.value = (visibleHistoryCount.value + _historyPageSize)
          .clamp(0, communityHistory.length);
    }
  }

  bool get hasMoreHistory =>
      visibleHistoryCount.value < communityHistory.length;

  Future<void> getMyCommunities() async {
    try {
      historyLoading.value = true;
      isLoading(true);
      var response = await ApiService.fetchCommunityActivity();
      log("🔹 getMyCommunities status: ${response.statusCode}");
      log("🔹 getMyCommunities body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List rawItems = data['items'] ?? [];
        log("🔹 Raw items count: ${rawItems.length}");

        // Store full history (joined + left)
        communityHistory.assignAll(
          rawItems.map((item) => Map<String, dynamic>.from(item)).toList(),
        );
        log(
          "🔹 communityHistory length after assign: ${communityHistory.length}",
        );

        createdCommunities.value =
            rawItems
                .where((item) => item['action'] == "joined")
                .map<CommunityModel>(
                  (item) =>
                      CommunityModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList();

        hasLoadedOnce(true);
        historyLoaded.value = true;
        // Reset pagination on fresh load
        visibleHistoryCount.value = _historyPageSize;
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      isLoading(false);
      historyLoading.value = false;
    }
  }

  var filteredMyCommunities = <CommunityModel>[].obs;
  var isSearching = false.obs;

  /// ২. My Communities ফিল্টার করার ফাংশন (Join & Create উভয় লিস্টের ওপর ভিত্তি করে)
  void filterMyCommunities(String query) {
    if (query.isEmpty) {
      isSearching.value = false;
      // সার্চ খালি থাকলে আবার সব ডাটা রিফ্রেশ করবে
      refreshFilteredList();
    } else {
      isSearching.value = true;
      // ওনারশিপ এবং মেম্বারশিপ সব ডাটা একসাথে করে ফিল্টার করবে
      final all = [...createdCommunities, ...joinedCommunities];

      filteredMyCommunities.assignAll(
        all
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  /// ৩. ফিল্টার করা লিস্টটি মেইন ডাটার সাথে সিঙ্ক করা
  void refreshFilteredList() {
    filteredMyCommunities.assignAll([
      ...createdCommunities,
      ...joinedCommunities,
    ]);
  }
}
