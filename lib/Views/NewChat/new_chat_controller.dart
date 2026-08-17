import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';

class NewChatController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  var friends = <FriendsModel>[].obs;
  var groups = <ChatModel>[].obs;
  var query = ''.obs;
  var isLoading = false.obs;

  // Pagination
  static const int _friendsPageSize = 20;
  static const int _groupsInitialCount = 5;
  RxInt visibleFriendsCount = _friendsPageSize.obs;
  RxBool showAllGroups = false.obs;

  void loadMoreFriends() {
    final total = filteredFriends.length;
    if (visibleFriendsCount.value < total) {
      visibleFriendsCount.value =
          (visibleFriendsCount.value + _friendsPageSize).clamp(0, total);
    }
  }

  void toggleShowAllGroups() {
    showAllGroups.value = !showAllGroups.value;
  }

  bool get hasMoreFriends => visibleFriendsCount.value < filteredFriends.length;

  List<ChatModel> get visibleGroups {
    if (showAllGroups.value) return filteredGroups;
    return filteredGroups.length > _groupsInitialCount
        ? filteredGroups.sublist(0, _groupsInitialCount)
        : filteredGroups;
  }

  List<FriendsModel> get visibleFriends {
    final total = filteredFriends;
    final count = visibleFriendsCount.value.clamp(0, total.length);
    return total.sublist(0, count);
  }

  @override
  void onInit() {
    super.onInit();
    loadFriends();
    loadGroups();
  }

  List<FriendsModel> get filteredFriends {
    if (query.value.isEmpty) return friends;
    final q = query.value.toLowerCase();
    return friends.where((f) {
      final fullName = f.fullName.toLowerCase();
      final username = f.username.toLowerCase();
      return fullName.contains(q) || username.contains(q);
    }).toList();
  }

  List<ChatModel> get filteredGroups {
    if (query.value.isEmpty) return groups;
    final q = query.value.toLowerCase();
    return groups
        .where((g) => (g.name?.toLowerCase() ?? '').contains(q))
        .toList();
  }

  Future<void> loadFriends() async {
    try {
      isLoading.value = true;
      final response = await ApiService.fetchFriendList();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          final List<dynamic> data = jsonData['data'];
          // Only accepted friends can be chatted with. Exclude pending sent
          // requests (status == 'PENDING_SENT') — those aren't friends yet.
          friends.value =
              data
                  .map((e) => FriendsModel.fromJson(e))
                  .where((f) => !f.isPendingSent)
                  .toList();
          log('Loaded ${friends.length} accepted friends for new chat.');
        }
      }
    } catch (e) {
      log('Error loading friends: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadGroups() async {
    try {
      final rawData = await ApiService.getAllChats();
      final chatList = rawData.map((e) => ChatModel.fromJson(e)).toList();
      final groupList =
          chatList.where((c) => c.isGroup && !c.isCommunity).toList();

      // Deduplicate by id
      final seen = <int>{};
      groups.value =
          groupList.where((g) => seen.add(g.id)).toList();
      log('Loaded ${groups.length} groups for new chat.');
    } catch (e) {
      log('Error loading groups: $e');
    }
  }
  @override
  void onClose() {
    // ২. স্ক্রিন থেকে বের হওয়ার সময় টেক্সট এবং কোয়েরি ক্লিয়ার করে দিন
    searchController.clear();
    query.value = "";
    super.onClose();
  }
}
