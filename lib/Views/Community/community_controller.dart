import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/member.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/No%20Community/searchCommunity.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class CommunityController extends GetxController {
  // Community details
  final RxList<dynamic> membersList = <dynamic>[].obs;
  final RxBool hasJoined = false.obs;
  final RxString communityName = "".obs;
  final RxString communityImage = "".obs;
  final RxString communityBio = "".obs;
  final RxInt creatorId = 0.obs; // ✅ অ্যাডমিন আইডি ট্র্যাক করার জন্য

  RxBool isCreator = false.obs;
  var isLoading = false.obs;
  var searchQuery = "".obs;
  var filteredMembers = <Map<String, dynamic>>[].obs;

  // Reactive member count for UI/state updates
  final RxInt memberCount = 0.obs;

  // ✅ নতুন ভেরিয়েবল: ইউজার অন্য কোনো কমিউনিটিতে আছে কি না চেক করার জন্য
  var userHasExistingCommunity = false.obs;

  bool get isOwnCommunity => isCreator.value;
  var isLoaded = false.obs;

  // ==================== Fetch single community details ====================
  Future<void> fetchCommunityDetails(int communityId) async {
    try {
      isLoading.value = true;
      final response = await ApiService.fetchCommunityDetails(communityId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Community info
        communityName.value = data["name"] ?? "Unknown";
        communityImage.value = data["imageUrl"] ?? "";
        communityBio.value = data["bio"] ?? "";
        creatorId.value =
            data["creatorId"] ?? 0; // ✅ সার্ভার থেকে ক্রিয়েটর আইডি সেট করা

        // Members
        membersList.assignAll(data["members"] ?? []);

        isCreator.value = data["isCreator"] ?? false;
        hasJoined.value = data["isMember"] ?? false;

        // ✅ চেক করা হচ্ছে ইউজার অন্য কোনো কমিউনিটিতে অলরেডি জয়েন করা কি না
        // যদি সে বর্তমান কমিউনিটির মেম্বার না হয় কিন্তু তার ডেটাতে অন্য কমিউনিটির তথ্য থাকে
        // (এটি আপনার প্রোফাইল বা এপিআই রেসপন্স অনুযায়ী সত্য হতে হবে)
        userHasExistingCommunity.value = data["userHasOtherCommunity"] ?? false;

        log("🔹 hasJoined: ${hasJoined.value}");
        log("🔹 Members count: ${membersList.length}");
      } else {
        AppSnackbar.error("Failed to load community details");
      }
    } catch (e) {
      log("⚠️ Exception in fetchCommunityDetails: $e");
    } finally {
      isLoading.value = false;
      isLoaded.value = true;
    }
  }

  // Note: Dhore nicchi dynamic communityId upore reactive ba method dynamic format-e ache
  var communityId = 0.obs;

  Future<void> removeMember(int memberId, int communityIdArg) async {
    try {
      // 1. ApiService triggered with both mandatory integer parameters
      final response = await ApiService.removeCommunityMember(
        communityId: communityIdArg,
        userId: memberId,
      );

      // 2. Handle HTTP Status Responses
      if (response.statusCode == 200) {
        log(response.statusCode.toString());
        final data = jsonDecode(response.body);

        // 3. UI Reactive state properties update
        membersList.removeWhere((m) => m['id'] == memberId);
        filteredMembers.removeWhere((m) => m['id'] == memberId);
        memberCount.value = membersList.length;

        // Success Snackbar notification
        AppSnackbar.success(data['message'] ?? "Member removed successfully");
      } else {
        // Backend failure contexts custom handling
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final String errorMessage =
            errorData['error'] ?? "Failed to remove member";

        AppSnackbar.error(errorMessage);
        log(
          "❌ Server Error response code [${response.statusCode}]: ${response.body}",
        );
      }
    } catch (e) {
      log("⚠️ Exception caught removing member: $e");
      AppSnackbar.error("Something went wrong");
    }
  }

  /// 🔹 Filter Members
  void filterMembers(String query) {
    searchQuery.value = query;
    final members = membersList.cast<Map<String, dynamic>>();

    if (query.isEmpty) {
      filteredMembers.assignAll(members);
    } else {
      filteredMembers.assignAll(
        members.where((m) {
          final fullName =
              "${m['firstName'] ?? ''} ${m['lastName'] ?? ''}".toLowerCase();
          return fullName.contains(query.toLowerCase());
        }).toList(),
      );
    }
  }

  // Communities list
  var communities = <Map<String, dynamic>>[].obs;
  var filteredCommunities = <Map<String, dynamic>>[].obs;

  Future<void> deleteCommunity(int communityId) async {
    try {
      final response = await ApiService.deleteCommunity(communityId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["message"] == "Community deleted") {
          communities.removeWhere((c) => c["id"] == communityId);
          filteredCommunities.removeWhere((c) => c["id"] == communityId);
          // Refresh the profile's community stat so it doesn't keep showing the
          // deleted community.
          if (Get.isRegistered<MyProfileController>()) {
            await Get.find<MyProfileController>()
                .loadMostRecentCommunityImage();
          }
          Get.offAll(() => const SearchCommunity());
          AppSnackbar.success("Community deleted successfully");
        }
      }
    } catch (e) {
      log("⚠️ Exception in deleteCommunity: $e");
    }
  }

  Future<void> leaveCommunityFunc(int communityId) async {
    try {
      isLoading.value = true;
      final response = await ApiService.leaveCommunity(communityId);
      if (response.statusCode == 200) {
        hasJoined.value = false;
        userHasExistingCommunity.value = false; // লিভ নিলে এটিও ফলস হবে
        // Refresh the profile's community stat so it reflects the leave.
        if (Get.isRegistered<MyProfileController>()) {
          await Get.find<MyProfileController>().loadMostRecentCommunityImage();
        }
        Get.offAll(() => const SearchCommunity());
        AppSnackbar.success("Successfully left community");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinCommunity(int communityId) async {
    try {
      isLoading.value = true;
      final response = await ApiService.joinCommunity(communityId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == "Joined community & added to chat") {
          hasJoined.value = true;
          userHasExistingCommunity.value = true;
          AppSnackbar.success(data['message']);
          await fetchCommunityDetails(communityId);
        }
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        AppSnackbar.error("You are already a member of a community");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
   var friends1 = <FriendsModel>[].obs; // current friends (API)
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

}
