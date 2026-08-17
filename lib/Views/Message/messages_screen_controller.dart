import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';
import 'package:outspot/main.dart' show flutterLocalNotificationsPlugin;
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/No%20Community/memberPage.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MessagesScreenController extends GetxController {
  late IO.Socket socket;

  final RxnInt selectedChatId = RxnInt();
  final RxnInt selectedUserId = RxnInt();
  final RxnString selectedUserName = RxnString();
  late List<CameraDescription> cameras;
  final RxBool isCameraReady = false.obs;
  int selectedCameraIdx = 0;
  RxList<MessageModel> messages = <MessageModel>[].obs;

  RxList<Map<String, dynamic>> item = <Map<String, dynamic>>[].obs;

  final TextEditingController messageController = TextEditingController();
  RxList texts = ["All", "Unread", "Groups"].obs;
  RxnString selectedImagePath = RxnString();

  RxList<ChatModel> chatss = <ChatModel>[].obs;

  RxInt selectedIndex = 0.obs;
  var currentUserId = 0.obs;
  var isConnected = false.obs;
  var chatId = 0.obs;
  var isLoading = false.obs;
  var isMuted = false.obs;

  final RxBool hasUnread = false.obs;

  RxBool isSearching = false.obs;
  RxString searchQuery = ''.obs;
  RxString searchText = ''.obs;

  // Client-side pagination
  static const int _pageSize = 20;
  RxInt visibleChatCount = _pageSize.obs;

  void loadMoreChats() {
    visibleChatCount.value += _pageSize;
  }

  void resetPagination() {
    visibleChatCount.value = _pageSize;
  }

  final RxnString avatarUrl = RxnString();

  Rx<int> selectedTabIndex = 0.obs;
  Timer? pollingTimer;
  StreamSubscription? _fcmSub;

  // Track chats that the user has locally marked as read.
  // Maps chatId -> the highest message ID that was marked as read.
  // Only suppresses unread indicator when latestMessage.id <= this value,
  // so NEW messages (higher ID) will correctly show as unread.
  final Map<int, int> _localReadOverrides = {};

  @override
  void onInit() {
    super.onInit();

    initSocket();

    // Load user profile first so currentUserId is set before fetchChats
    // filters chats. Then fetch chats and join socket rooms.
    loadUserProfile().then((_) {
      fetchChats().then((_) {
        checkUnreadStatusOnInit();
        joinAllChatRooms();
      });
    });

    ever<List<ChatModel>>(chatss, (_) {
      // Update UI immediately — don't block on network calls
      filterChats(searchController.text);
      _refreshUnreadDot();
      // Join new rooms in background (non-blocking)
      joinAllChatRooms();
    });

    // Refresh chat list when a foreground FCM notification arrives
    _fcmSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('FCM foreground message received, refreshing chat list...');
      fetchChats();
    });

    getRedDot();
    globalId();
  }

  @override
  void onClose() {
    _fcmSub?.cancel();
    super.onClose();
  }

  Future<void> fetchChats() async {
    try {
      // Only show loading shimmer on first load when list is empty
      if (chatss.isEmpty) {
        isLoading.value = true;
      }
      final rawData = await ApiService.getAllChats();
      log("📦 Fetched ${rawData.length} chats from API");
      final chatList = rawData.map((e) => ChatModel.fromJson(e)).toList();

      // Log all chats before filtering
      for (var chat in chatList) {
        log(
          'FETCH_CHATS: chat id=${chat.id}, isGroup=${chat.isGroup}, isCommunity=${chat.isCommunity}, '
          'users=${chat.users.map((u) => "id=${u.id},name=${u.firstName} ${u.lastName},username=${u.username}").toList()}, '
          'messages=${chat.messages.length}',
        );
      }

      final validChats =
          chatList.where((chat) {
            if (chat.isGroup || chat.isCommunity) return true;
            final myId = currentUserId.value;

            final otherUser = chat.users.firstWhereOrNull((u) => u.id != myId);

            if (otherUser == null) {
              log(
                "FETCH_CHATS: FILTERED OUT chat ${chat.id} - no other user found (myId=$myId)",
              );
              return false;
            }

            final hasValidName =
                (otherUser.firstName?.isNotEmpty ?? false) ||
                (otherUser.lastName?.isNotEmpty ?? false) ||
                (otherUser.username?.isNotEmpty ?? false);

            if (!hasValidName) {
              log(
                "FETCH_CHATS: FILTERED OUT Ghost Chat (ID: ${chat.id}) - No Name Found for user id=${otherUser.id}",
              );
            }

            return hasValidName;
          }).toList();

      log(
        "FETCH_CHATS: ${chatList.length} total -> ${validChats.length} valid (filtered ${chatList.length - validChats.length})",
      );

      // Deduplicate before assigning to prevent flash of duplicate items
      final uniqueValid = getUniqueChats(validChats);
      chatss.assignAll(uniqueValid);

      // Re-apply local read overrides so the red dot doesn't flicker back
      // when API data hasn't yet reflected the user's read action.
      // Only apply if the latestMessage ID is <= the override (i.e. no new message).
      final myId = currentUserId.value;
      if (myId > 0) {
        for (var chat in chatss) {
          final overrideMsgId = _localReadOverrides[chat.id];
          if (overrideMsgId != null &&
              chat.latestMessage != null &&
              chat.latestMessage!.id <= overrideMsgId &&
              !chat.latestMessage!.readBy.contains(myId)) {
            chat.latestMessage!.readBy.add(myId);
          }
        }
      }

      for (var chat in validChats) {
        if (chat.isGroup) {
          log("✅ Group Chat: ${chat.name}");
        }
      }

      // Re-apply the active filter (Unread / Groups tab, or search) to the
      // freshly-fetched list. Without this, a pull-to-refresh while on the
      // Unread/Groups tab dropped the filter and showed ALL chats again.
      reapplyFilters();

      // EasyLoading.dismiss();
    } catch (e) {
      // EasyLoading.dismiss();
      log(" Error loading chats: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void checkUnreadStatusOnInit() {
    final myId = currentUserId.value;
    if (myId <= 0) return;

    for (var chat in chatss) {
      final isUnread = isChatUnreadForMe(chat, myId);
      if (isUnread) {
        // log("❌ Chat ID ${chat.id}: Last message is unread for user ID $myId");
      } else {
        // log("✅ Chat ID ${chat.id}: Last message is read for user ID $myId");
      }
    }

    chatss.refresh();
    log("✅ Checked unread status for all chats during onInit");
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  DateTime _dt(dynamic v) {
    if (v is DateTime) return v;
    if (v is int) {
      if (v > 100000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  final Set<int> _joinedRooms = {};

  Future<void> joinAllChatRooms() async {
    if (!socket.connected) return;

    final uid = currentUserId.value;
    if (uid <= 0) {
      print('⏸️ skip join: currentUserId not ready');
      return;
    }

    for (final c in chatss) {
      if (_joinedRooms.contains(c.id)) continue;

      socket.emit('joinChat', c.id);

      // print('➡️ joinChat (list): chatId=${c.id}');
      _joinedRooms.add(c.id);
    }
    if (globalChatInfo.value != null) {
      final gid = globalChatInfo.value!.chatId;

      if (!_joinedRooms.contains(gid)) {
        socket.emit('joinChat', gid);
        log('🌍 joinChat (Global): chatId=$gid');
        _joinedRooms.add(gid);
      }
    }
  }

  final Rxn<MessageModel> globalLastMessage = Rxn<MessageModel>();

  void onNewMessage(dynamic raw) {
    try {
      final data = Map<String, dynamic>.from(raw as Map);

      final cid = _toInt(data['chatId']) ?? _toInt(data['chatID']) ?? 0;
      if (cid == 0) return;
      if (globalChatInfo.value != null && cid == globalChatInfo.value!.chatId) {
        final sid =
            _toInt(data['senderId']) ??
            _toInt((data['sender'] as Map?)?['id']) ??
            _toInt(data['userId']) ??
            -1;

        final msgJson = {
          'id': data['id'],
          'content': data['content'] ?? '',
          'imageUrl': data['imageUrl'],
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          'senderId': sid,
          'readBy': [],
          'deliveredTo': [],
          'type':
              (data['imageUrl'] != null && '${data['imageUrl']}'.isNotEmpty)
                  ? 'image'
                  : 'text',
        };

        globalLastMessage.value = MessageModel.fromJson(msgJson);
        log("🌍 Global Chat Updated: ${msgJson['content']}");
        return;
      }

      final idx = chatss.indexWhere((c) => c.id == cid);
      if (idx == -1) {
        log('New message for unknown chatId=$cid, fetching chat list...');
        fetchChats();
        return;
      }

      final sid =
          _toInt(data['senderId']) ??
          _toInt((data['sender'] as Map?)?['id']) ??
          _toInt(data['userId']) ??
          -1;

      final msgJson = {
        'id': data['id'],
        'content': data['content'] ?? '',
        'imageUrl': data['imageUrl'],
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'senderId': sid,
        'readBy': [],
        'deliveredTo': [],
        'type':
            (data['imageUrl'] != null && '${data['imageUrl']}'.isNotEmpty)
                ? 'image'
                : 'text',
      };

      final chat = chatss[idx];
      final newMsg = MessageModel.fromJson(msgJson);
      chat.messages.add(newMsg);

      // Replace latestMessage with the actual new message
      // so hasUnreadChats checks against the real latest message
      chat.latestMessage = newMsg;

      // Clear local read override — this is a new message, so the old
      // "I already read this chat" override no longer applies
      _localReadOverrides.remove(cid);

      // If I sent this message, mark it as read by me immediately
      final myId = currentUserId.value;
      if (sid == myId && myId > 0) {
        newMsg.readBy.add(myId);
      }

      chatss.refresh();
      filterChats(searchController.text);
      reapplyFilters();

      log("🔔 New message in Chat ID: $cid, senderId: $sid");

      // Emit delivery confirmation so sender gets double-tick,
      // regardless of whether user is viewing the chat or not.
      final myIdForDelivery = currentUserId.value;
      if (sid != myIdForDelivery &&
          myIdForDelivery > 0 &&
          data['id'] != null) {
        try {
          socket.emit('messageDelivered', {
            'chatId': cid,
            'messageId': data['id'],
          });
          log('📨 Emitted messageDelivered (from list) for msgId=${data['id']}');
        } catch (_) {}
      }

      // Show local in-app notification if user is NOT viewing this chat
      _showInAppNotificationIfNeeded(
        incomingChatId: cid,
        senderId: sid,
        myId: myId,
        content: data['content']?.toString() ?? '',
        hasImage: data['imageUrl'] != null &&
            '${data['imageUrl']}'.isNotEmpty,
        chat: chat,
      );
    } catch (e) {
      log('❌ Error in onNewMessage: $e | raw=$raw');
    }
  }

  void _showInAppNotificationIfNeeded({
    required int incomingChatId,
    required int senderId,
    required int myId,
    required String content,
    required bool hasImage,
    required ChatModel chat,
  }) {
    // Don't notify for my own messages
    if (senderId == myId || myId <= 0) return;

    // Don't notify if user is currently viewing this specific chat
    try {
      if (Get.currentRoute == '/DirectMessageScreen' &&
          Get.isRegistered<DirectmassagescreenController>()) {
        final dm = Get.find<DirectmassagescreenController>();
        if (dm.chatId.value == incomingChatId) return;
      }
    } catch (_) {}

    // Build notification title and body
    final sender = chat.users.firstWhereOrNull((u) => u.id == senderId);
    String title = '';
    if (sender != null) {
      title = '${sender.firstName} ${sender.lastName}'.trim();
    }
    if (title.isEmpty) {
      title = chat.isGroup || chat.isCommunity
          ? (chat.name ?? 'New message')
          : 'New message';
    }
    final body = hasImage && content.isEmpty ? '📷 Photo' : content;

    try {
      flutterLocalNotificationsPlugin.show(
        incomingChatId,
        title,
        body.isEmpty ? 'You have a new message' : body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            channelDescription: 'Default notification channel',
            icon: 'ic_notification',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        payload: 'MESSAGE|$senderId|$incomingChatId',
      );
      log('🔔 Local notification shown for chat $incomingChatId from $senderId');
    } catch (e) {
      log('❌ Local notification error: $e');
    }
  }

  void reapplyFilters() {
    if (isSearching.value) {
      filterChats(searchController.text);
    } else {
      filterChatTab();
    }
  }

  /// Lightweight refresh for tick/read status changes only.
  void _notifyTickChange() {
    filteredChats.refresh();
    _refreshUnreadDot();
  }

  /// Apply a read receipt from the server — updates BOTH the latestMessage
  /// and every message in the chat (since reader likely read all unread ones).
  /// Forces reactive rebuild so the blue tick appears instantly without
  /// needing the user to open/close the chat.
  void _applyReadReceipt(int cid, int readerId) {
    final idx = chatss.indexWhere((c) => c.id == cid);
    if (idx == -1) return;

    final chat = chatss[idx];
    bool changed = false;

    // Mark all messages in the chat as read by this user
    for (final m in chat.messages) {
      if (!m.readBy.contains(readerId)) {
        m.readBy.add(readerId);
        changed = true;
      }
    }

    // Also update latestMessage (may be a separate object from messages.last)
    if (chat.latestMessage != null &&
        !chat.latestMessage!.readBy.contains(readerId)) {
      chat.latestMessage!.readBy.add(readerId);
      changed = true;
    }

    if (!changed) return;

    // Trigger reactive rebuild — refresh both lists and re-apply filters
    chatss.refresh();
    filteredChats.refresh();
    reapplyFilters();
    _refreshUnreadDot();
  }

  /// Recalculate the unread dot state explicitly.
  void _refreshUnreadDot() {
    hasUnread.value = hasUnreadChats;
  }

  bool _socketInitialized = false;
  bool isMessageUnread(Map<String, dynamic> message, int myId) {
    if (message.isEmpty) return false;
    final List readBy = message['readBy'] ?? [];
    return !readBy.contains(myId);
  }

  void initSocket() {
    if (_socketInitialized) return;
    _socketInitialized = true;

    socket = IO.io(ApiConstants.socketUrl, {
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
    });

    socket.off('newMessage');
    socket.off('messageRead');
    socket.off('chatRead');
    socket.off('messageDelivered');

    socket.onAny((event, data) => print('📥 [onAny] $event -> $data'));

    socket.onConnect((_) async {
      isConnected.value = true;
      print(' Messages socket connected: ${socket.id}');
      _joinedRooms.clear();
      await joinAllChatRooms();
    });

    socket.onReconnect((_) async {
      print(' reconnected, rejoin all rooms…');
      _joinedRooms.clear();
      await joinAllChatRooms();
    });

    socket.onDisconnect((_) {
      isConnected.value = false;
      print(' Messages socket disconnected');
    });

    socket.on('newMessage', onNewMessage);

    // socket.on("newMessage", (data) {
    //   try {
    //     final newChat = ChatModel.fromJson(data);

    //     final idx = chatss.indexWhere((c) => c.id == newChat.id);
    //     if (idx == -1) {
    //       chatss.insert(0, newChat);
    //     } else {
    //       chatss[idx] = newChat;
    //       chatss.refresh();
    //     }

    //     print("💬 Realtime newMessage updated for chat: ${newChat.id}");
    //   } catch (e) {
    //     print("❌ Error parsing newMessage: $e");
    //   }
    // });  //for ghost chat
    socket.on('messageRead', (data) {
      try {
        final cid = _toInt(data['chatId']) ?? 0;
        final readerId = _toInt(data['userId']) ?? 0;
        if (cid <= 0 || readerId <= 0) return;

        _applyReadReceipt(cid, readerId);
        log("✅ messageRead: user $readerId read chat $cid");
      } catch (e) {
        log("❌ messageRead error: $e");
      }
    });

    socket.on('chatRead', (data) {
      try {
        final cid = _toInt(data['chatId']) ?? 0;
        final readerId = _toInt(data['userId']) ?? 0;
        if (cid <= 0 || readerId <= 0) return;

        _applyReadReceipt(cid, readerId);
        log("✅ chatRead: user $readerId read chat $cid");
      } catch (e) {
        log("❌ chatRead error: $e");
      }
    });

    socket.on('messageDelivered', (data) {
      try {
        final cid = _toInt(data['chatId']) ?? 0;
        final deliveredUserId = _toInt(data['userId']) ?? 0;
        if (cid <= 0 || deliveredUserId <= 0) return;

        final idx = chatss.indexWhere((c) => c.id == cid);
        if (idx == -1) return;

        final chat = chatss[idx];
        if (chat.latestMessage != null &&
            !chat.latestMessage!.deliveredTo.contains(deliveredUserId)) {
          chat.latestMessage!.deliveredTo.add(deliveredUserId);
          _notifyTickChange();
        }
      } catch (e) {
        log("❌ messageDelivered error: $e");
      }
    });

    socket.on('newChat', (data) {
      try {
        final chatId = data['chatId'];
        if (chatId != null && !_joinedRooms.contains(chatId)) {
          socket.emit('joinNewChat', chatId);
          _joinedRooms.add(chatId);
          log('Auto-joined new chat room: $chatId');
        }
        fetchChats();
      } catch (e) {
        log('Error handling newChat: $e');
      }
    });

    socket.on('messagesExpired', (data) {
      try {
        log('messagesExpired event received, refreshing chats');
        fetchChats();
      } catch (e) {
        log('Error handling messagesExpired: $e');
      }
    });

    socket.on('messagesDeleted', (data) {
      try {
        log('messagesDeleted event received, refreshing chats');
        fetchChats();
      } catch (e) {
        log('Error handling messagesDeleted: $e');
      }
    });

    socket.connect();
  }

  Future<void> loadUserProfile() async {
    try {
      // Try cached userId first for immediate availability
      final cachedId = await UserPreference.getUserId();
      if (cachedId != null && cachedId > 0 && currentUserId.value <= 0) {
        currentUserId.value = cachedId;
      }

      final r = await ApiService.fetchUserProfile();
      if (r.statusCode != 200) return log("❌ ${r.statusCode} | ${r.body}");

      final data =
          (json.decode(r.body)['data'] as Map?)?.cast<String, dynamic>();
      if (data == null) return log('❌ data null');

      final uid = int.tryParse('${data['id']}');
      if (uid == null) return log('❌ invalid id: ${data['id']}');
      currentUserId.value = uid;

      // Bring up the realtime notification-badge socket for this user so the
      // bell red dot updates live across the app — even when push is disabled.
      _badgeService.connectSocket(uid);

      if (socket.connected) {
        _joinedRooms.clear();
        await joinAllChatRooms();
      }

      String? top = (data['avatarUrl'] as String?)?.trim();
      final m = data['minime'];
      String? mini =
          (m is List && m.isNotEmpty)
              ? (m.last['avatarUrl'] as String?)?.trim()
              : null;

      String? body = (data['bodyShapeUrl'] as String?)?.trim();

      avatarUrl.value =
          (top?.isNotEmpty == true)
              ? top
              : (mini?.isNotEmpty == true)
              ? mini
              : (body?.isNotEmpty == true)
              ? body
              : null;

      log("✅ id=$uid, avatar=${avatarUrl.value ?? '(none)'}");
    } catch (e, st) {
      log("❌ $e");
      log("$st");
    } finally {
      EasyLoading.dismiss();
    }
  }

  void setSelectedChat(ChatModel chat, int? currentUserId) {
    chatId.value = chat.id;
    print('Selected Chat ID: ${chatId.value}');

    if (!chat.isGroup && !chat.isCommunity) {
      final otherUser = chat.users.firstWhereOrNull(
        (u) => u.id != currentUserId,
      );
      selectedUserId.value = otherUser?.id;
      selectedUserName.value =
          (otherUser?.fullName?.isNotEmpty == true)
              ? otherUser!.fullName
              : otherUser?.fullName ?? "Unknown";
    } else {
      selectedUserId.value = null;
      selectedUserName.value = chat.name ?? "Group";
    }
  }

  void selectIndex(int index) {
    selectedIndex.value = index;
  }

  // RxList tabimagelist =
  //     [
  //       "assets/Images/skchatt1x.png",
  //       "assets/Images/skmap1x.png",
  //       "assets/Images/skvamerashaddow.png",
  //       "assets/Images/skchallangeshadow.png",
  //       "assets/Images/skexploreshaddow.png",
  //     ].obs;

  Future<void> getchatwitguserId() async {
    try {
      final chatid = chatId;
      final data = await ApiService.getChatMessages(chatid.value);

      log("📦 Chat messages count: ${data.length}");
      for (var i = 0; i < data.length; i++) {
        log("💬 Message #$i: ${data[i]}");
      }

      messages.clear();
      item.addAll(data);
    } catch (e) {
      log("❌ Error loading chats: $e");
    }
  }

  final TextEditingController searchController = TextEditingController();

  var filteredChats = <ChatModel>[].obs;

  void filterChats(String query) {
    final allChats = getUniqueChats(chatss);

    if (query.isEmpty) {
      filteredChats.assignAll(allChats);
    } else {
      final results =
          allChats.where((chat) {
            final name =
                chat.isCommunity
                    ? (chat.name ?? 'Unknown Community')
                    : chat.isGroup
                    ? (chat.name ?? 'Unknown Group')
                    : getUserName(chat);

            return name.toLowerCase().contains(query.toLowerCase());
          }).toList();

      filteredChats.assignAll(results);
    }
  }

  String getUserName(ChatModel chat) {
    final int meId =
        currentUserId.value is int
            ? currentUserId.value
            : int.tryParse('${currentUserId.value}') ?? -1;

    final otherUser = chat.users.firstWhereOrNull((u) => u.id != meId);

    if (otherUser == null) return '';

    final first = (otherUser.firstName ?? '').trim();
    final last = (otherUser.lastName ?? '').trim();
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');

    return full.isNotEmpty ? full : (otherUser.username ?? '');
  }

  bool isValidHttpUrl(String? s) {
    if (s == null || s.trim().isEmpty) return false;
    final uri = Uri.tryParse(s.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void openFriendProfile(ChatModel chat) {
    // if (chat.isGroup) return;

    if (chat.isGroup) {
      log("Group tapped: ${chat.id}");
      Get.toNamed(Routes.groupMembersPage, arguments: {'groupId': chat.id});
      return;
    }
    if (chat.isCommunity) {
      log("Community tapped: ${chat.id}");
      Get.toNamed(
        Routes.community,
        arguments: {"id": chat.communityId ?? chat.id},
      );
      return;
    }

    final myId =
        // ignore: unnecessary_type_check
        currentUserId.value is int
            ? currentUserId.value
            : int.tryParse('${currentUserId.value}') ?? -1;

    final others = chat.users.where((u) => u.id != myId).toList();
    final friend =
        others.isNotEmpty
            ? others.first
            : (chat.users.isNotEmpty ? chat.users.first : null);

    if (friend != null) {
      log("Friend tapped: ${friend.id}");
      Get.toNamed(Routes.friendsProfile, arguments: friend);
    }
  }

  String? getChatAvatar(ChatModel chat, int myUserId) {
    if (chat.isGroup == true || chat.isCommunity == true) {
      return (chat.imageUrl != null && chat.imageUrl!.isNotEmpty)
          ? chat.imageUrl
          : null;
    } else {
      final otherUser = chat.users.firstWhere(
        (u) => u.id != myUserId,
        orElse:
            () =>
                chat.users.isNotEmpty
                    ? chat.users.first
                    : FriendsModel(
                      id: 0,
                      username: 'Unknown',
                      firstName: '',
                      lastName: '',
                      avatarUrl: '',
                      totalPoints: 0,
                      thisWeekPoints: 0,
                      profileUrl: '',
                    ),
      );
      return otherUser.avatarUrl.isNotEmpty ? otherUser.avatarUrl : null;
    }
  }

  String getDisplayName(ChatModel chat) {
    if (chat.isCommunity == true) return chat.name ?? 'Community';
    if (chat.isGroup == true) return chat.name ?? 'Unknown Group';
    return getUserName(chat);
  }

  String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  List<ChatModel> getUniqueChats(List<ChatModel> chatList) {
    final bestByKey = <String, ChatModel>{};

    for (final chat in chatList) {
      String key;

      if (chat.isCommunity) {
        key = 'community:${chat.communityId ?? chat.id}';
      } else if (chat.isGroup) {
        key = 'group:${(chat.name ?? 'Unknown Group').toLowerCase()}';
      } else {
        final ids = chat.users.map((u) => u.id).toList()..sort();
        key = 'dm:${ids.join("-")}';
      }

      final existing = bestByKey[key];
      if (existing == null || chat.messages.length > existing.messages.length) {
        bestByKey[key] = chat;
      }
    }
    return bestByKey.values.toList();
  }

  String getTitleIcon(int level) {
    if (level >= 20) return "assets/Images/sklegency.png";
    if (level >= 10) return "assets/Images/sksniper.png";
    if (level >= 5) return "assets/Images/skcamera.png";
    return "assets/Images/skfootprint.png";
  }

  void filterChatTab() {
    resetPagination();
    switch (selectedTabIndex.value) {
      case 0:
        filteredChats.assignAll(chatss);
        break;

      case 1:
        filteredChats.assignAll(
          chatss
              .where((chat) => isChatUnreadForMe(chat, currentUserId.value))
              .toList(),
        );
        break;

      case 2:
        filteredChats.assignAll(
          chatss.where((chat) => chat.isGroup && !chat.isCommunity).toList(),
        );
        break;
      default:
        filteredChats.assignAll(chatss);
    }
  }

  /////
  DateTime _parseDT(String? v) {
    if (v == null || v.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime lastActivityOf(ChatModel c) {
    // Base order on the backend's stable recency key (lastActivityAt). It does
    // not change when a message disappears/clears, so the chat keeps its
    // position instead of dropping to the bottom (the bug this fixes).
    DateTime best = _parseDT(c.lastActivityAt);

    // A freshly sent/received message that the server's key doesn't reflect yet
    // is genuinely the latest activity — let it float the chat to the top.
    if (c.latestMessage != null) {
      final t = _parseDT(c.latestMessage!.createdAt);
      if (t.isAfter(best)) best = t;
    }
    if (c.messages.isNotEmpty) {
      final t = _parseDT(c.messages.last.createdAt);
      if (t.isAfter(best)) best = t;
    }
    return best;
  }

  List<ChatModel> get sortedFilteredChats {
    final list = List<ChatModel>.from(filteredChats);
    list.sort((a, b) => lastActivityOf(b).compareTo(lastActivityOf(a)));
    if (list.length > visibleChatCount.value) {
      return list.sublist(0, visibleChatCount.value);
    }
    return list;
  }

  bool get hasMoreChats {
    final list = List<ChatModel>.from(filteredChats);
    return list.length > visibleChatCount.value;
  }

  // void markChatAsReadLocal(int cid, int lastSeenId, int myUid) {
  //   if (myUid <= 0) {
  //     log("❌ Invalid user ID: $myUid");
  //     return;
  //   }

  //   final idx = chatss.indexWhere((c) => c.id == cid);
  //   if (idx == -1) {
  //     log("❌ Chat ID $cid not found in chat list.");
  //     return;
  //   }

  //   final chat = chatss[idx];
  //   log("📥 Updating chat ID: $cid, Last Seen Message ID: $lastSeenId");

  //   for (var m in chat.messages) {
  //     if (m.id <= lastSeenId && !m.readBy.contains(myUid)) {
  //       m.readBy.add(myUid);
  //       log("✅ Message ID ${m.id} marked as read by User ID $myUid");
  //     }
  //   }

  //   if (chat.latestMessage != null &&
  //       !chat.latestMessage!.readBy.contains(myUid)) {
  //     chat.latestMessage!.readBy.add(myUid);
  //     log(
  //       "✅ Latest message ID ${chat.latestMessage!.id} updated with User ID $myUid",
  //     );
  //   }

  //   chatss[idx] = chat;
  //   chatss.refresh();
  //   log("🔄 Chat list refreshed after marking messages as read.");
  // }
  void markChatAsReadLocal(int cid, int lastSeenId, int myUid) {
    if (myUid <= 0) {
      log("❌ Invalid user ID: $myUid");
      return;
    }

    // Persist this read locally so fetchChats() re-fetches don't revert it.
    // Store the highest message ID we've read — new messages with higher IDs
    // won't be suppressed.
    final currentOverride = _localReadOverrides[cid] ?? 0;
    if (lastSeenId > currentOverride) {
      _localReadOverrides[cid] = lastSeenId;
    }

    final idx = chatss.indexWhere((c) => c.id == cid);

    if (idx != -1) {
      final chat = chatss[idx];

      for (var m in chat.messages) {
        if (m.id <= lastSeenId && !m.readBy.contains(myUid)) {
          m.readBy.add(myUid);
        }
      }

      if (chat.latestMessage != null &&
          !chat.latestMessage!.readBy.contains(myUid)) {
        chat.latestMessage!.readBy.add(myUid);
      }

      chatss[idx] = chat;
      chatss.refresh();
      _refreshUnreadDot();
      log("🔄 Chat list updated for ID: $cid");
    } else if (globalChatInfo.value != null &&
        globalChatInfo.value!.chatId == cid) {
      log("🌍 Marking GLOBAL Chat as read locally (ID: $cid)");

      if (globalLastMessage.value != null) {
        //
        if (!globalLastMessage.value!.readBy.contains(myUid)) {
          globalLastMessage.value!.readBy.add(myUid);
          globalLastMessage.refresh(); //
        }
      }

      var info = globalChatInfo.value!;
      if (info.latestMessage != null) {
        if (!info.latestMessage!.readBy.contains(myUid)) {
          info.latestMessage!.readBy.add(myUid);

          globalChatInfo.refresh();
        }
      }
    } else {
      log("❌ Chat ID $cid not found in local list or global chat.");
    }
  }

  bool get hasUnreadChats {
    final myId = currentUserId.value;
    if (myId <= 0) return false;
    // Only check private (1-on-1) chats for the nav bar indicator
    for (var chat in chatss) {
      if (chat.isGroup || chat.isCommunity || chat.isMuted) continue;
      if (isChatUnreadForMe(chat, myId)) {
        return true;
      }
    }
    return false;
  }

  bool isChatUnreadForMe(ChatModel chat, int myId) {
    if (myId <= 0) return false;

    // Source of truth is latestMessage only. Do NOT fall back to messages.last:
    // the server clears latestMessage to null for disappearing chats while the
    // messages array still holds the old row, so the fallback would mark a
    // cleared chat as unread (stale red dot).
    final msg = chat.latestMessage;
    if (msg == null) return false;

    // If I sent the last message, it's not unread for me
    if (msg.senderId == myId) return false;

    // Check local override — if I've marked this chat as read locally
    // and no newer message has arrived, treat it as read
    final overrideMsgId = _localReadOverrides[chat.id];
    if (overrideMsgId != null && msg.id <= overrideMsgId) return false;

    // If readBy doesn't include me, it's unread
    return !msg.readBy.contains(myId);
  }

  void resetListState() {
    isSearching.value = false;
    searchController.clear();
    selectedTabIndex.value = 0;
    filterChats('');
    filterChatTab();
  }

  Future<void> toggleMute(int chatId) async {
    try {
      isLoading.value = true;
      if (isMuted.value) {
        await ApiService.unmuteChatNotifications(chatId);
        isMuted.value = false;
      } else {
        await ApiService.muteChatNotifications(chatId);
        isMuted.value = true;
      }
    } finally {
      isLoading.value = false;
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

  void removeChat(int chatId) {
    chatss.removeWhere((c) => c.id == chatId);
  }

  ////////////////////////////////NOTIFICATION////////////////////////////

  final _badgeService = Get.find<NotificationBadgeService>();
  RxBool get notificationRedDot => _badgeService.notificationRedDot;
  Future<void> getRedDot() => _badgeService.getRedDot();
  Future<void> clearNotificationDot() => _badgeService.clearNotificationDot();

  Rxn<GlobalChatInfo> globalChatInfo = Rxn<GlobalChatInfo>();
  Future<void> globalId() async {
    try {
      final savedCity = await UserPreference.getSelectedCity();
      final response =
          savedCity != null && savedCity.isNotEmpty
              ? await ApiService.getGlobalchatIds(city: savedCity)
              : await ApiService.getGlobalchatId();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        log("✅ Global Data: $data");

        if (data['success'] == true) {
          final info = GlobalChatInfo.fromJson(data);
          globalChatInfo.value = info;

          if (info.latestMessage != null) {
            globalLastMessage.value = info.latestMessage;
          }

          if (socket.connected) {
            socket.emit('joinChat', info.chatId);
            log('🌍 Joined Global Chat immediately: ${info.chatId}');
            _joinedRooms.add(info.chatId);
          }
        }
      } else {
        print('❌ Failed to fetch Global ID: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error fetching Global ID: $e');
    }
  }

  void clearData() {
    chatss.clear();
    messages.clear();
    filteredChats.clear();
    item.clear();
    currentUserId.value = 0;
    _joinedRooms.clear();
    _localReadOverrides.clear();
    globalChatInfo.value = null;
    globalLastMessage.value = null;

    // সকেট ডিসকানেক্ট করা (যাতে ব্যাকগ্রাউন্ডে মেসেজ না আসে)
    if (socket.connected) {
      socket.disconnect();
    }
  }
  // MessagesScreenController এ
Future<void> refreshAvatarOnly() async {
  try {
    final r = await ApiService.fetchUserProfile();
    if (r.statusCode != 200) return;

    final data = (json.decode(r.body)['data'] as Map?)
        ?.cast<String, dynamic>();
    if (data == null) return;

    // শুধু avatar update করুন — socket বা userId touch করবেন না
    String? top = (data['avatarUrl'] as String?)?.trim();
    final m = data['minime'];
    String? mini = (m is List && m.isNotEmpty)
        ? (m.last['avatarUrl'] as String?)?.trim()
        : null;
    String? body = (data['bodyShapeUrl'] as String?)?.trim();

    avatarUrl.value = (top?.isNotEmpty == true)
        ? top
        : (mini?.isNotEmpty == true)
            ? mini
            : (body?.isNotEmpty == true)
                ? body
                : null;

    log("✅ Avatar refreshed: ${avatarUrl.value}");
  } catch (e) {
    log("❌ refreshAvatarOnly error: $e");
  }
}
}

class GlobalChatInfo {
  final int chatId;
  final String name;
  final bool isLocked;
  final int memberCount;
  final MessageModel? latestMessage;

  GlobalChatInfo({
    required this.chatId,
    required this.name,
    required this.isLocked,
    this.memberCount = 0,
    this.latestMessage,
  });

  factory GlobalChatInfo.fromJson(Map<String, dynamic> json) {
    return GlobalChatInfo(
      chatId: int.tryParse('${json['chatId']}') ?? 0,

      name: (json['name']?.toString() ?? 'Unknown').replaceAll(
        RegExp(r'^Global Chat\s*[-–]\s*'),
        '',
      ),

      isLocked: json['isLocked'] == true,

      memberCount: int.tryParse('${json['memberCount']}') ?? 0,

      latestMessage:
          json['latestMessage'] != null &&
                  json['latestMessage'] is Map<String, dynamic>
              ? MessageModel.fromJson(json['latestMessage'])
              : null,
    );
  }
}
