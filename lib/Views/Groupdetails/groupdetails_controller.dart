import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/group_model.dart';
import 'package:outspot/Model/groupmember_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Groups/groups_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/NewChat/new_chat_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class GroupdetailsController extends GetxController {
  var admin = "".obs;
  var Id = 0.obs;
  var isMuted = false.obs;
  var isLoading = false.obs;

  final RxInt groupId = 0.obs;
  final RxString group = ''.obs;

  final isAdmin = false.obs;
  final RxBool isLoadingMembers = true.obs;
  var myRole = ''.obs;
  final RxBool isLocked = false.obs;
  RxList<GroupMember> groupUsers = <GroupMember>[].obs;

  // Pagination for large member lists
  static const int _pageSize = 20;
  RxInt visibleMemberCount = _pageSize.obs;

  void loadMoreMembers() {
    if (visibleMemberCount.value < groupUsers.length) {
      visibleMemberCount.value =
          (visibleMemberCount.value + _pageSize).clamp(0, groupUsers.length);
    }
  }

  bool get hasMoreMembers => visibleMemberCount.value < groupUsers.length;

  @override
  Future<void> onInit() async {
    super.onInit();

    final args = (Get.arguments as Map?) ?? const {};
    log('🔵 GroupdetailsController args: $args');

    final gidRaw = args['groupId'];
    groupId.value = _toIntSafe(gidRaw);
    log('🔵 Parsed groupId: ${groupId.value}');
    await loadUserProfile();
    await getMember(groupId.value);
    await fetchMuteStatus(groupId.value);
  }

  int _toIntSafe(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];

        final userId = data["id"];
        Id.value = userId;

        log(" User ID: $userId");
      } else {
        log(" Server error: ${response.statusCode}");
      }
    } catch (e) {
      log(" Error loading profile: $e");
    }
  }

  Future<void> getMember(int groupId) async {
    try {
      isLoadingMembers.value = true;

      log('🔵 Fetching group details for groupId: $groupId');
      final groupData = await ApiService.getGroupDetails(groupId);
      log('🔵 Group API response: $groupData');
      final groupObj = Group.fromJson(groupData);

      group.value = groupObj.groupName;
      this.groupId.value = groupObj.groupId;
      this.group.value = groupObj.groupName;
      this.isLocked.value = groupObj.isLocked;
      groupUsers.assignAll(groupObj.members);
      log('🔵 Group loaded: name=${groupObj.groupName}, members=${groupUsers.length}, isLocked=${groupObj.isLocked}');

      final me = groupUsers.firstWhereOrNull((u) => u.id == Id.value);

      log('👤 My userId: ${Id.value}, found in group: ${me != null}, role: ${me?.role}');

      if (me != null) {
        myRole.value = me.role;
        isAdmin.value = me.role.toUpperCase().trim() == 'ADMIN';
      } else {
        myRole.value = 'UNKNOWN';
        isAdmin.value = false;
      }
      log('🔑 isAdmin: ${isAdmin.value}');

      if (kDebugMode) {
        final preview = groupUsers.take(2).toList();
      }

      // set admin flag
      final userId = Id.value;
      final mez = groupUsers.firstWhere(
        (u) => u.id == userId,
        orElse:
            () => GroupMember(
              firstName: "",
              lastName: "",
              id: 0,
              username: '',
              name: '',
              points: 0,
              thisWeekPoints: 0,
              role: '',
              joinedAt: DateTime.now(),
            ),
      );
      isAdmin.value = mez.role.toUpperCase().trim() == 'ADMIN';
    } finally {
      isLoadingMembers.value = false;
    }
  }

  Future<void> fetchMuteStatus(int chatId) async {
    try {
      isLoading.value = true;
      final status = await ApiService.getMuteStatus(chatId);
      isMuted.value = status;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleMute(int chatId) async {
    try {
      AppLoading.show();
      if (isMuted.value) {
        await ApiService.unmuteChatNotifications(chatId);
        isMuted.value = false;
        AppLoading.hide();
        AppSnackbar.success('Notifications unmuted');
      } else {
        await ApiService.muteChatNotifications(chatId);
        isMuted.value = true;
        AppLoading.hide();
        AppSnackbar.success('Notifications muted');
      }
    } catch (e) {
      AppLoading.hide();
      AppSnackbar.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Admin-only: remove a member from this group chat after admin confirms.
  /// Mirrors `removeMember` in community_controller.dart.
  Future<void> removeMember(int memberId) async {
    try {
      AppLoading.show();
      final response = await ApiService.removeUserFromGroup(
        chatId: groupId.value,
        userId: memberId,
      );
      AppLoading.hide();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Member removed';

        groupUsers.removeWhere((u) => u.id == memberId);

        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }

        AppSnackbar.success(message);
      } else {
        final err = jsonDecode(response.body);
        AppSnackbar.error(err['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      AppLoading.hide();
      log('⚠️ Exception in removeMember: $e');
      AppSnackbar.error('Something went wrong: $e');
    }
  }

  /// Admin-only: ban a member from this group chat. Stronger than remove — the
  /// server prevents re-joining. Mirrors [removeMember].
  Future<void> banMember(int memberId, {String? reason}) async {
    try {
      AppLoading.show();
      final response = await ApiService.banGroupMember(
        groupId.value,
        memberId,
        reason: reason,
      );
      AppLoading.hide();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        groupUsers.removeWhere((u) => u.id == memberId);
        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }
        AppSnackbar.success(data['message'] ?? 'Member banned from group');
      } else {
        final err = jsonDecode(response.body);
        AppSnackbar.error(err['message'] ?? 'Failed to ban member');
      }
    } catch (e) {
      AppLoading.hide();
      log('⚠️ Exception in banMember: $e');
      AppSnackbar.error('Something went wrong: $e');
    }
  }

  Future<void> leaveGroup() async {
    try {
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back();
      }

      AppLoading.show();
      final response = await ApiService.leaveGroup(groupId.value);
      AppLoading.hide();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'You have left the group';

        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }

        final gid = groupId.value;
        if (Get.isRegistered<NewChatController>()) {
          Get.find<NewChatController>().groups.removeWhere((g) => g.id == gid);
        }
        if (Get.isRegistered<GroupsController>()) {
          Get.find<GroupsController>().groupChats.removeWhere(
            (g) => g.id == gid,
          );
        }

        Get.until(
          (route) =>
              route.settings.name == Routes.newChat ||
              route.settings.name == Routes.mainscreen ||
              route.isFirst,
        );

        AppSnackbar.success(message);
      } else {
        AppSnackbar.error('Failed to leave group: ${response.body}');
      }
    } catch (e) {
      AppLoading.hide();
      AppSnackbar.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> lockChat(int chatId) async {
    try {
      AppLoading.show();
      await ApiService.lockGroupChat(chatId);
      isLocked.value = true;
      AppLoading.hide();

      AppSnackbar.success('You locked the group chat');

      if (Get.isRegistered<GroupsController>()) {
        Get.find<GroupsController>().fetchChats();
      }
    } catch (e) {
      AppLoading.hide();
      log("failed to lock chat: $e");
      AppSnackbar.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> unlockChat(int chatId) async {
    try {
      AppLoading.show();
      await ApiService.unlockGroupChat(chatId);
      isLocked.value = false;
      AppLoading.hide();

      AppSnackbar.success('You unlocked the group chat');

      if (Get.isRegistered<GroupsController>()) {
        Get.find<GroupsController>().fetchChats();
      }
    } catch (e) {
      AppLoading.hide();
      log("failed to unlock chat: $e");
      AppSnackbar.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
