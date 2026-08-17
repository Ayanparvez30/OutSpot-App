import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Model/group_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:path/path.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';

class GroupsController extends GetxController {
  var groupList = <GroupItem>[].obs;
  final RxInt groupId = 0.obs;
  final RxString group = ''.obs;
  final RxInt totalPoints = 0.obs;
  final RxInt thisWeekPoints = 0.obs;
  final RxList<Map<String, dynamic>> groupUsers = <Map<String, dynamic>>[].obs;
  var currentUserId = 0.obs;
  var admin = "".obs;
  RxList<ChatModel> chatss = <ChatModel>[].obs;
  RxList<ChatModel> groupChats = <ChatModel>[].obs;
  RxString query = ''.obs;

  RxInt favoriteGroupId = RxInt(0);
  var groupnames = "".obs;
  var isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    fetchChats();
    Future.delayed(Duration(seconds: 1), () {
      log("nmbnmbn $groupChats");
    });
  }

  List<ChatModel> get filteredGroupChats {
    if (query.value.isEmpty) {
      return groupChats;
    }
    return groupChats
        .where(
          (chat) => (chat.name?.toLowerCase() ?? '').contains(
            query.value.toLowerCase(),
          ),
        )
        .toList();
  }

  Future<void> fetchChats() async {
    try {
      isLoading.value = true;

      final rawData = await ApiService.getAllChats();
      final chatList = rawData.map((e) => ChatModel.fromJson(e)).toList();
      // log("Fetched ${rawData.length} chats from API");
      chatss.assignAll(chatList);
      groupChats.clear();

      for (var chat in chatList) {
        if (chat.isGroup && !chat.isCommunity) {
          groupChats.add(chat);
          // log("Group added: ${chat.name}");
        } else if (chat.isCommunity) {
          log("Skipping community chat: ${chat.name}");
        } else {
          final otherUser = chat.users.firstWhereOrNull(
            (user) => user.id != currentUserId.value,
          );

          if (otherUser != null) {
            log("Direct Chat with: ${otherUser.username}");
          } else {
            log("Direct Chat with: Unknown User");
          }
        }
      }

      log("Total chats loaded: ${chatList.length}");
      log("Total group chats: ${groupChats.length}");
    } catch (e) {
      log("Error loading chats: $e");

      EasyLoading.showError('Failed to fetch chats');
    } finally {
      isLoading.value = false;
    }
  }

  void saveFavoriteGroupId(int groupId, String groupname) {
    favoriteGroupId.value = groupId;
    this.groupnames.value = groupname;
    log("Saved favorite group ID: $groupId");
  }

  Future<void> leaveGroup() async {
    try {
      final response = await ApiService.leaveGroup(chatId.value);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'You have left the group';

        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }

        groupChats.removeWhere((g) => g.id == chatId.value);
        groupChats.refresh();

        AppSnackbar.success(message);
        Get.offAllNamed(Routes.group);
      } else {
        AppSnackbar.error('Failed to leave group: ${response.body}');
      }
    } catch (e) {
      log('⚠️ Exception in leaveGroup: $e');
      AppSnackbar.error('Something went wrong: $e');
    }
  }

  final RxInt chatId = 0.obs;
  Future<void> getChatIdFromGroup(int groupId) async {
    final chat = await fetchChatForGroup(groupId);
    if (chat != null) {
      log('Fetched chat object: $chat');
      chatId.value = chat.id;

      final String groupName = chat.name ?? "Unknown Group";
      print("Group name for ID $groupId is: $groupName");

      log("Chat ID for group: ${chatId.value}");
    } else {
      log("❌ Chat not found for group $groupId");
    }
  }

  Future<ChatModel?> fetchChatForGroup(int groupId) async {
    return ChatModel(
      id: groupId,
      isGroup: true,
      isCommunity: false,
      isLocked: false,
      users: [],
      messages: [],
    ); // Sample return
  }

  Future<void> getMember(int groupIds) async {
    try {
      final groupData = await ApiService.getGroupDetails(groupIds);

      log("Group Data: $groupData");

      if (groupData['members'] == null || groupData['members'].isEmpty) {
        log('❌ No members found in the group');
        return;
      }

      final members = groupData['members'];

      log("Members: $members");

      final userId = Id.value;

      final currentUser = members.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => null,
      );

      if (currentUser != null && currentUser['role'] == 'ADMIN') {
        log("✅ User is an ADMIN");
        admin.value = currentUser["role"];
      } else {
        log("❌ User is not an ADMIN");
        admin.value = "";
      }
    } catch (e) {
      print('Error fetching members: $e');
      log('Error details: $e');
    }
  }

  var Id = 0.obs;
  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];

        final userId = data["id"];
        Id.value = userId;

        log("✅ User ID: $userId");
      } else {
        log("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
    }
  }

  void selectGroup(ChatModel chat) {
    groupId.value = chat.id ?? 0;
    group.value = chat.name ?? 'Unknown Group';

    totalPoints.value = chat.users.fold(0, (s, u) => s + (u.totalPoints));
    thisWeekPoints.value = chat.users.fold(0, (s, u) => s + (u.thisWeekPoints));

    groupUsers.assignAll(
      chat.users.map(
        (u) => {
          "id": u.id,
          "name": u.fullName,
          "avatarUrl": u.avatarUrl ?? '',
          "points": u.totalPoints,
          "thisWeekPoints": u.thisWeekPoints,
        },
      ),
    );
  }
}
