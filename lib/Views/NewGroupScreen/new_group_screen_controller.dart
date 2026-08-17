import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/group_model.dart';

import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Groupdetails/groupdetails_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/Groups/groups_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/NewChat/new_chat_controller.dart';

class NewGroupScreenController extends GetxController {
  TextEditingController newGroupController = TextEditingController();
  TextEditingController addGroupController = TextEditingController();
  var friends1 = <FriendsModel>[].obs;
  var groups = <GroupItem>[].obs;
  final RxInt chatId = 0.obs;
  final RxInt groupId = 0.obs;
  bool isSelected(FriendsModel f) => selectedFriendIds.contains(f.id);
  RxList<FriendsModel> selectedFriends = <FriendsModel>[].obs;
  RxList<int> memberIds = <int>[].obs;
  RxString query = ''.obs;
  RxBool isEdit = false.obs;
  @override
  void onInit() {
    super.onInit();
    // Dummy data
    loadFriendList();
    final arguments = Get.arguments;
    // log(arguments);

    if (arguments != null) {
      log("$arguments");
      isEdit.value = arguments['isedit'] ?? false;
      var groupIdArg = arguments['groupId'];
      var groupames = arguments['groupName'];

      log('groupNames value: $groupname');
      if (groupames != null) {
        group.value = groupames;
        if (isEdit.value) {
          newGroupController.text = group.value;
        }
        log('groupNames value: $group');
      } else {
        log('No group name provided');
      }
      if (groupIdArg is Map) {
        groupIdArg = groupIdArg['id'];
        log('groupId extracted from map: $groupIdArg');
      }

      if (groupIdArg != null) {
        groupId.value = groupIdArg;

        getChatIdFromGroup(groupId.value);
        getMember(groupId.value);
      } else {
        log('groupId is null or not found in arguments');
      }
    }
  }

  Future<void> loadFriendList() async {
    try {
      final response = await ApiService.fetchFriendList();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          List<dynamic> data = jsonData['data'];
          // Exclude pending sent requests (status == 'PENDING_SENT') — only
          // accepted friends can be added to a group.
          friends1.value =
              data
                  .map((e) => FriendsModel.fromJson(e))
                  .where((f) => !f.isPendingSent)
                  .toList();
          print("Loaded ${friends1.length} accepted friends from server.");
        } else {
          AppSnackbar.error(jsonData['message'] ?? 'Failed to fetch friends');
        }
      } else {
        AppSnackbar.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  List<FriendsModel> get filteredFriends {
    final q = query.value.trim().toLowerCase();

    final existingMemberSet = memberIds.toSet();

    return friends1.where((friend) {
      if (existingMemberSet.contains(friend.id)) return false;
      if (q.isEmpty) return true;
      final fullName = friend.fullName.toLowerCase();
      final username = friend.username.toLowerCase();
      return fullName.contains(q) || username.contains(q);
    }).toList();
  }

  final selectedFriendIds = <int>[].obs;

  void toggleFriendSelection(FriendsModel friend) {
    if (memberIds.contains(friend.id)) {
      return;
    }
    final friendId = friend.id;

    if (selectedFriends.contains(friend)) {
      selectedFriends.remove(friend);
      selectedFriendIds.remove(friendId);
    } else {
      selectedFriends.add(friend);
      selectedFriendIds.add(friendId);
    }
    print('Selected Friend IDs: $selectedFriendIds');
  }

  var groupname = "".obs;
  var group = "".obs;
  final RxnInt selectedUserId = RxnInt();
  var pickedImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  void createGroupChat() async {
    final userIds = List<int>.from(selectedFriendIds);
    final groupName = newGroupController.text.trim();
    final imagePath = pickedImage.value?.path;

    if (groupName.isEmpty) {
      print('Group name required');
      return;
    }
    if (userIds.isEmpty) {
      print('Select at least one friend');
      return;
    }

    try {
      AppLoading.show();
      final res = await ApiService.createGroupChat(
        userIds,
        groupName,
        imagePath ?? '',
      );
      AppLoading.hide();

      log('RAW RES: $res');

      final chat = (res['chat'] ?? {}) as Map<String, dynamic>;
      final String name = (chat['name'] as String?) ?? '';
      final int? cid = chat['id'] as int?;

      groupname.value = name;
      selectedUserId.value = cid;

      final msg = res['message'] as String? ?? '';
      if (msg.toLowerCase().contains('already exists')) {
        log('ℹ️ Group exists; opening previous chat');
      } else {
        log('✅ New group created');
      }
      log('Group Name: $name');
      log('Selected User ID: $cid');

      if (cid != null) {
        if (Get.isRegistered<GroupdetailsController>()) {
          Get.delete<GroupdetailsController>();
        }

        Get.find<MessagesScreenController>().fetchChats();

        // Refresh groups list in NewChatController
        if (Get.isRegistered<NewChatController>()) {
          Get.find<NewChatController>().loadGroups();
        }

        newGroupController.clear();
        pickedImage.value = null;
        selectedFriendIds.clear();

        // Pop back to NewChat screen (remove NewGroupScreen and AddScreen)
        Get.until((route) {
          final name = route.settings.name;
          if (name == Routes.newGroupScreen ||
              name == Routes.addscreen) {
            return false;
          }
          return true;
        });
      } else {
        log('⚠️ chat.id missing in response');
      }
      
    } catch (e, st) {
      AppLoading.hide();
      log('createGroupChat error: $e');
      AppSnackbar.error('Failed to create group');
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

  void updateGroupChat() async {
    final groupName = newGroupController.text.trim();

    String? imageToSend;

    if (pickedImage.value != null && pickedImage.value is File) {
      imageToSend = (pickedImage.value as File).path;
    } else {
      imageToSend = groupImage.value;
    }

    if (groupName.isEmpty) {
      print('Group name required');
      return;
    }

    try {
      AppLoading.show();
      final res = await ApiService.editGroupChat(
        groupName,
        imageToSend,
        groupId.value,
      );
      AppLoading.hide();
      log('Group updated successfully: $res');
      log('RAW RES: $res');

      final chat = (res['chat'] ?? {}) as Map<String, dynamic>;
      final String name = (chat['name'] as String?) ?? '';
      final int? cid = chat['id'] as int?;

      groupname.value = name;
      selectedUserId.value = cid;

      final msg = res['message'] as String? ?? '';
      if (msg.toLowerCase().contains('already exists')) {
        log('ℹ️ Group exists; opening previous chat');
      } else {
        log('✅ New group created');
      }
      log('Group Name: $name');
      log('Selected User ID: $cid');

      if (cid != null) {
        // Refresh the existing GroupdetailsController instead of deleting it
        if (Get.isRegistered<GroupdetailsController>()) {
          Get.find<GroupdetailsController>().getMember(cid);
        }

        // Refresh groups in NewChat and Messages
        if (Get.isRegistered<NewChatController>()) {
          Get.find<NewChatController>().loadGroups();
        }
        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }

        newGroupController.clear();
        pickedImage.value = null;

        // Go back to the GroupMembersPage that's already in the stack
        Get.back();
      } else {
        log('⚠️ chat.id missing in response');
      }
    } catch (e, st) {
      AppLoading.hide();
      log('updateGroupChat error: $e');
      AppSnackbar.error('Failed to update group');
    }
  }

  void addmember() async {
    if (selectedFriendIds.isEmpty) {
      AppSnackbar.error("Please select at least one friend to add.");
      return;
    }

    try {
      List<int> newUserIds =
          selectedFriendIds.where((userId) {
            return !memberIds.contains(userId);
          }).toList();

      if (newUserIds.isEmpty) {
        AppSnackbar.info(
          "All selected users are already members of the group.",
        );
        print('All selected users are already members of the group.');
        return;
      }

      await ApiService.addUsersToGroup(newUserIds, chatId.value);

      if (groupId.value == null) {
        AppSnackbar.error("Group ID is missing.");
      } else {
        if (Get.isRegistered<GroupdetailsController>()) {
          Get.delete<GroupdetailsController>();
        }
        Get.toNamed(
          Routes.groupMembersPage,
          arguments: {"groupId": groupId.value},
        );
        selectedFriendIds.clear();
      }
    } catch (e) {
      print('Error adding users to the group: $e');
      AppSnackbar.error("An error occurred while adding users.");
    }
  }

  Future<void> getChatIdFromGroup(int groupId) async {
    final chat = await fetchChatForGroup(groupId);
    if (chat != null) {
      log('Fetched chat object: $chat');
      chatId.value = chat.id;
      List<int> userIds = chat.users.map((user) => user.id).toList();
      log("${userIds.toList()}");

      groupname.value = chat.name ?? "";
      // print("Group name for ID $groupId is: $groupName");
      log("Chat ID for group: ${groupname}");
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

  var groupImage = "".obs;
  Future<void> getMember(int groupIds) async {
    try {
      // Calling the ApiService to get group details (which is a Map)
      final groupData = await ApiService.getGroupDetails(groupIds);

      log("Group Data: ${groupData}");
      // Fetching groupImage from the response
      String? fetchedGroupImage = groupData['groupImage'] as String?;

      if (fetchedGroupImage != null && fetchedGroupImage.isNotEmpty) {
        groupImage.value =
            fetchedGroupImage; // Update the RxString with the image URL
        print('Group Image: $fetchedGroupImage');
      } else {
        print('Group image not found.');
        groupImage.value = ""; // Clear if no image is available
      }
      // Check if the 'members' key exists and is not empty
      if (groupData.containsKey('members') && groupData['members'] is List) {
        final members = groupData['members'] as List;

        if (members.isNotEmpty) {
          // Clear existing memberIds
          memberIds.clear();

          memberIds.addAll(
            members.map<int>((member) => member['id'] as int).toList(),
          );

          print('Member IDs: $memberIds');
          print('Members found: $members');
        } else {
          print('No members found in the group.');
        }
      } else {
        print('Invalid API response: "members" key is missing or not a list.');
      }
    } catch (e) {
      print('Error fetching members: $e');
    }
  }
}
