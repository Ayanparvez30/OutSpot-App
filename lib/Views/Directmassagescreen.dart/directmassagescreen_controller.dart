import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:outspot/Model/Global_model.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Model/friends_model.dart';

import 'package:outspot/Model/groupmember_model.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/socketService.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Groups/groups_controller.dart';
import 'package:outspot/Views/Message/camera_controller.dart';
import 'package:outspot/Views/Message/camera_screen.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:get/get.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/NewChat/new_chat_controller.dart';
import 'package:outspot/Views/No%20Community/memberPage.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';

class DirectmassagescreenController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  // Focus for the message input — used by the empty-state CTA to pop the
  // keyboard and nudge the user to type the first message.
  final FocusNode messageFocusNode = FocusNode();

  late final ScrollController scrollController;

  final RxnString selectedUserName = RxnString();

  late final SocketService socketService;
  // Guards onClose: if chat init returns early (invalid chatId/senderId),
  // socketService is never assigned — touching it would throw
  // LateInitializationError.
  bool _socketInited = false;

  final ImagePicker _picker = ImagePicker();

  final Rxn<XFile> pendingImage = Rxn<XFile>();
  final Map<int, Map<String, String>> userCache = {};

  RxList<Map<String, dynamic>> item = <Map<String, dynamic>>[].obs;
  Map<String, String> _getUserBasic(int userId) =>
      userCache[userId] ?? const {'name': '', 'avatarUrl': ''};

  bool _socketBound = false;
  RxString avatarurl = ''.obs;
  Rx<String> groupname = "".obs;
  var friends1 = <FriendsModel>[].obs;
  var friendData = Rxn<FriendsModel>();
  RxBool isMuted = false.obs; // মিউট স্ট্যাটাস ট্র্যাক করার জন্য

  // অ্যাডমিন কিনা তা চেক করার জন্য একটি গেটার
  RxBool get isAdmin =>
      (userRole.value.toLowerCase() == 'admin' || isCreator.value).obs;

  final RxInt chatId = 0.obs;
  var senderId = 0.obs;
  var frienduserId = 0.obs;
  var groupid = 0.obs;
  var communityId = 0.obs;
  var groupimageurl = "".obs;

  var username = RxnString(null);
  var friendName = "".obs;
  var profiledata = <String, dynamic>{}.obs;
  var firsName = RxnString(null);
  var lastName = RxnString(null);
  var communityName = "".obs;
  var communityImage = "".obs;
  var membersList = <dynamic>[].obs;
  var isCreator = false.obs;
  var hasJoined = false.obs;
  var isOwnCommunity = false.obs;
  var communityweekpoints = 0.obs;
  var communitytotalpoints = 0.obs;
  var isGlobalChat = false.obs;
  var globalChatName = ''.obs;
  Timer? _expiryTimer;

  // Pagination: store all messages, display in batches
  final List<Map<String, dynamic>> _allMessages = [];
  static const int _pageSize = 20;
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreMessages = true.obs;
  RxBool showScrollDownArrow = false.obs;
  RxBool initialScrollPending = false.obs;
  @override
  void onInit() async {
    super.onInit();
    _expiryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _removeExpiredMessages();
    });

    loadUserProfile();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    log("🔵 DM Screen Received arguments: $args");

    // parse helper
    int? _asInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final fid = _asInt(args['Id']);
    final groupId = _asInt(args['groupId']);
    final communityid = _asInt(args['communityId']);
    final globalCid = _asInt(args['chatId']);
    final existingChatId = _asInt(args['existingChatId']);
    final username = args['username'] ?? 'Unknown User';

    if (fid == null &&
        groupId == null &&
        communityid == null &&
        globalCid == null) {
      log("Missing all IDs");
      isLoading.value = false; // don't leave the shimmer spinning forever
      return;
    }

    if (globalCid != null) {
      isGlobalChat.value = true;
      chatId.value = globalCid;
      globalChatName.value = username.toString();
      log("Open Global Chat chatId=${chatId.value}, name=$globalChatName");
      globalId();
      await fetchGlobalRooms();
    } else if (fid != null) {
      frienduserId.value = fid;
      await getUserProfile(frienduserId.value);
      if (existingChatId != null && existingChatId > 0) {
        chatId.value = existingChatId;
        // log('Using existing chatId=$existingChatId for friend=$fid');
      } else {
        await createChat(userId: frienduserId.value);
      }
    } else if (groupId != null) {
      groupname.value = username;
      groupid.value = groupId;
      chatId.value = groupId;
      log(
        "🔵 Group chat opened — groupId=$groupId, groupName=${groupname.value}, chatId=${chatId.value}",
      );
      await getMember(groupId);
      await getChatIdFromGroup(groupId);
    } else if (communityid != null) {
      communityId.value = communityid;
      await getCommunityChatId(communityId.value);
      await fetchCommunityDetails(communityid);
      // log("Fetching chat ID for community: $communityid");
    }

    await _waitUntil(
      () => senderId.value > 0 && chatId.value > 0,
      timeoutMs: 8000,
    );

    if (senderId.value <= 0 || chatId.value <= 0) {
      // log(
      //   'Failed to initialize chat: senderId=${senderId.value}, chatId=${chatId.value}',
      // );
      isLoading.value = false; // don't leave the shimmer spinning forever
      return;
    }
    await fetchMuteStatus(chatId.value);
    socketService = SocketService(ApiConstants.socketUrl);
    socketService.connect(chatId: chatId.value, userId: senderId.value);

    socketService.setChatId(chatId.value, senderId.value);
    _socketInited = true;

    bindSocketListeners();
    joinCurrentRoom();

    await getchatwithchatId(initialLoad: true);
    markChatAsRead();

    ever<int>(chatId, (cid) {
      if (cid > 0) joinCurrentRoom();
    });
  }

  Future<void> fetchCommunityDetails(int communityId) async {
    try {
      final response = await ApiService.fetchCommunityDetails(communityId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        communityName.value = data["name"] ?? "Unknown";
        communityImage.value = data["imageUrl"] ?? "";

        final List<dynamic> membersData = (data["members"] as List?) ?? [];
        membersList.assignAll(membersData);

        communitytotalpoints.value = 0;
        communityweekpoints.value = 0;

        for (var member in membersData) {
          final totalRaw = member["totalPoints"] ?? 0;
          final weekRaw = member["thisWeekPoints"] ?? 0;

          communitytotalpoints.value +=
              (totalRaw is num
                  ? totalRaw.toInt()
                  : int.tryParse('$totalRaw') ?? 0);
          communityweekpoints.value +=
              (weekRaw is num
                  ? weekRaw.toInt()
                  : int.tryParse('$weekRaw') ?? 0);
        }
        isCreator.value = data["isCreator"] ?? false;
        hasJoined.value = data["isMember"] ?? false;
        log(" fetchCommunityDetails : ${response.body}");
      } else {
        log("❌ fetchCommunityDetails failed: ${response.body}");
      }
    } catch (e) {
      log("⚠️ Exception in fetchCommunityDetails: $e");
    }
  }

  Future<void> getCommunityChatId(int communityId) async {
    try {
      log("Fetching chat ID for community: $communityId");

      final response = await ApiService.getCommunityChatId(communityId);

      if (response.containsKey('chatId')) {
        chatId.value = response['chatId'];

        log("✅ Community Chat ID: ${chatId.value}");
      } else {
        log("⚠️ No 'chatId' field found in response: $response");
      }
    } catch (e) {
      log("❌ Error fetching community chat ID: $e");
    }
  }

  void _removeExpiredMessages() {
    final now = DateTime.now();
    final before = item.length;
    item.removeWhere((msg) {
      final expiresAt = msg['expiresAt'];
      if (expiresAt == null || expiresAt.toString().isEmpty) return false;
      final expiry = DateTime.tryParse(expiresAt.toString());
      return expiry != null && expiry.isBefore(now);
    });
    if (item.length != before) {
      item.refresh();
      log('🗑️ Removed ${before - item.length} expired messages');
    }
  }

  @override
  void onClose() {
    // Make sure keyboard is dismissed on iOS when this controller tears
    // down — otherwise the next screen's TextField may receive the
    // lingering focus and re-show the keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    _expiryTimer?.cancel();
    // Only touch the socket if chat init actually completed — otherwise
    // socketService is unassigned (LateInitializationError).
    if (_socketInited) {
      // Remove all socket listeners bound by this controller so a stale
      // listener from a previous chat doesn't fire for the current chat
      // (which would incorrectly mark other chats as read).
      socketService.off('newMessage');
      socketService.off('chatRead');
      socketService.off('messageDelivered');
      socketService.off('disappearingMessagesChanged');
      socketService.off('messagesExpired');
      socketService.off('messagesDeleted');
      // Signal leaving BEFORE disconnect so disappearing chats hide/clear the
      // viewed messages for this user. Socket emit may not survive the immediate
      // disconnect below, so back it up with an HTTP call (fire-and-forget).
      final leavingChatId = chatId.value;
      socketService.exitChat(leavingChatId);
      ApiService.exitChat(leavingChatId);
      socketService.disconnect();
    }
    scrollController.dispose();
    messageFocusNode.dispose();
    _debounce?.cancel();
    // Refresh chat list so new conversations appear immediately
    if (Get.isRegistered<MessagesScreenController>()) {
      Get.find<MessagesScreenController>().fetchChats();
    }
    super.onClose();
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];

        final userId = data["id"];
        senderId.value = userId;
      } else {
        log("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
    }
  }

  Future<void> _waitUntil(
    bool Function() cond, {
    int timeoutMs = 5000,
    int stepMs = 100,
  }) async {
    final started = DateTime.now();
    while (!cond()) {
      await Future.delayed(Duration(milliseconds: stepMs));
      if (DateTime.now().difference(started).inMilliseconds > timeoutMs) break;
    }
  }

  Future<void> joinCurrentRoom() async {
    final cid = chatId.value;
    final me = senderId.value;

    if (cid > 0 && me > 0 && _socketInited && socketService.isConnected()) {
      // joinRoom now also emits enterChat (covers the onConnect auto-join path),
      // so no separate enterChat call is needed here.
      socketService.joinRoom(chatId: cid, userId: me);
      // log('✅ joined chatId=$cid, userId=$me');
    } else {
      log('⚠️ join skipped cid=$cid me=$me inited=$_socketInited');
    }
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

  bool _mergeHeuristic(Map<String, dynamic> inc) {
    final bool mine =
        (inc['isMine'] == true) ||
        (_toInt(inc['senderId']) == senderId.value) ||
        (_toInt((inc['sender'] as Map?)?['id']) == senderId.value);

    if (!mine) return false;

    final String type = (inc['type'] ?? '') as String;
    final String content =
        (inc['content'] ?? inc['text'] ?? '').toString().trim();
    final String? img = (inc['imageUrl'] ?? inc['mediaUrl'])?.toString();
    final dtInc = _dt(inc['createdAt']);

    int scanned = 0;
    for (int i = item.length - 1; i >= 0 && scanned < 20; i--, scanned++) {
      final m = item[i];
      if (m['isMine'] != true) continue;

      final sameType = (m['type'] ?? '') == type;
      final dtLocal = _dt(m['createdAt']);
      if ((dtInc.difference(dtLocal)).inSeconds.abs() > 10) continue;

      final sameText =
          ((m['content'] ?? m['text'] ?? '').toString().trim() == content) &&
          content.isNotEmpty;
      final sameImg =
          ((m['imageUrl'] ?? m['mediaUrl'])?.toString() == img) &&
          (img != null && img.isNotEmpty);

      if (sameType && (sameText || sameImg)) {
        // merge
        item[i] = {
          ...m,
          ...inc,
          'tempId': m['tempId'] ?? inc['tempId'],
          'uploading': false,
          'failed': false,
        };
        item.refresh();
        return true;
      }
    }
    return false;
  }

  Future<void> _warmUserBasicIfMissing(int userId) async {
    final c = _getUserBasic(userId);
    if (c['name']!.isNotEmpty && c['avatarUrl']!.isNotEmpty) return;
    try {
      final p = await ApiService.getanyUserProfile(userId);
      final first = (p['firstName'] ?? '').toString();
      final last = (p['lastName'] ?? '').toString();
      final full = '$first $last'.trim();
      final minime = (p['minime'] as List?) ?? [];
      final av =
          (minime.isNotEmpty
                  ? (minime[0]['avatarUrl'] ?? '')
                  : (p['avatarUrl'] ?? ''))
              .toString();
      cacheUserBasic(userId: userId, name: full, avatarUrl: av);

      for (int i = item.length - 1; i >= 0; i--) {
        final m = item[i];
        final sid =
            _toInt((m['sender'] as Map?)?['id']) ?? _toInt(m['senderId']);
        if (sid == userId) {
          final s = (m['sender'] as Map?) ?? {};
          item[i] = {
            ...m,
            'sender': {
              ...s,
              'id': userId,
              'firstName': full.split(' ').first,
              'lastName': full.split(' ').skip(1).join(' '),
              'avatarUrl': _normalizeAvatarUrl(av),
            },
          };
        }
      }
      item.refresh();
    } catch (_) {}
  }

  void bindSocketListeners() {
    log('🔵 bindSocketListeners() called.');
    if (_socketBound) {
      log('⚠️ Listeners already bound. Skipping.');
      return;
    }
    _socketBound = true;
    // log('✅ Listeners are now bound for ChatID: ${chatId.value}');

    int _safeInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    socketService.listenToEvent('newMessage', (raw) async {
      try {
        final data = Map<String, dynamic>.from(raw as Map);

        // 🔍 DEBUG LOG
        // log('📥 Received Msg: ${data['content']} | ID: ${data['id']}');

        final incomingChatId = _safeInt(data['chatId']);

        if (incomingChatId != chatId.value) return;

        final senderIdEcho = _safeInt(
          data['senderId'] ?? data['sender']?['id'] ?? data['userId'],
        );
        final bool isMine = senderIdEcho == senderId.value;

        final senderMap = (data['sender'] as Map?) ?? const {};
        String name =
            ('${senderMap['firstName'] ?? ''} ${senderMap['lastName'] ?? ''}')
                .trim();
        if (name.isEmpty) name = 'Unknown';
        String avatar = (senderMap['avatarUrl'] ?? '').toString();

        final parsedReply = _parseReplyTo(data);
        final msg = <String, dynamic>{
          'id': data['id'], // Server ID
          'tempId': data['tempId']?.toString(),
          'chatId': incomingChatId,
          'senderId': senderIdEcho,
          'isMine': isMine,
          // Only set when present so merging an echo onto our optimistic
          // message doesn't wipe the local reply snapshot.
          if (parsedReply != null) 'replyTo': parsedReply,
          // Server now echoes this on every delivery path — carry it so the
          // "Forwarded" label shows on socket-delivered messages too.
          'forwarded': data['forwarded'] == true,
          'type':
              (data['imageUrl'] != null && '${data['imageUrl']}'.isNotEmpty)
                  ? 'image'
                  : 'text',
          'text': data['content'] ?? '',
          'content': data['content'],
          'mediaUrl': data['imageUrl'],
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          'readBy': List<int>.from(data['readBy'] ?? []),
          'deliveredTo': List<int>.from(data['deliveredTo'] ?? []),
          'isSystem': data['isSystem'] ?? false,
          'expiresAt': data['expiresAt'],
          'sender': {
            ...senderMap,
            'id': senderIdEcho,
            'firstName': name,
            'avatarUrl': avatar,
          },
        };

        final String? t = msg['tempId']?.toString();
        if (t != null && t.isNotEmpty) {
          final idx = item.indexWhere((m) => m['tempId']?.toString() == t);
          if (idx != -1) {
            log('✅ Updating local message by TempID: $t');
            item[idx] = {
              ...item[idx],
              ...msg,
              'uploading': false,
              'failed': false,
            };
            item.refresh();
            return;
          }
        }

        if (isMine) {
          if (_mergeHeuristic(msg)) {
            log('✅ Merged with local message using Heuristic check');
            return;
          }
        }

        // The server often echoes our OWN message back without the tempId and
        // with a slightly different (or missing) image URL — so neither the
        // tempId match nor the URL heuristic above catches it, and it gets added
        // as a duplicate bubble (sometimes empty when the echo has no imageUrl).
        // Since the server echoes our sends in order, confirm the OLDEST
        // still-unconfirmed (no server id) mine message instead of adding a new
        // bubble.
        if (isMine && msg['id'] != null) {
          final DateTime echoAt = _dt(msg['createdAt']);
          for (int i = 0; i < item.length; i++) {
            final m = item[i];
            if (m['isMine'] != true || m['id'] != null) continue;
            if (echoAt.difference(_dt(m['createdAt'])).inSeconds.abs() > 120) {
              continue;
            }
            final String echoImg =
                (msg['mediaUrl'] ?? msg['imageUrl'] ?? '').toString();
            item[i] = {
              ...m,
              'id': msg['id'],
              'readBy': msg['readBy'] ?? m['readBy'],
              'deliveredTo': msg['deliveredTo'] ?? m['deliveredTo'],
              // Adopt the server media URL only when present; otherwise keep our
              // good local copy so an empty echo can't blank the bubble.
              if (echoImg.isNotEmpty) 'imageUrl': echoImg,
              if (echoImg.isNotEmpty) 'mediaUrl': echoImg,
              'uploading': false,
              'failed': false,
            };
            item.refresh();
            log('✅ Confirmed pending mine message with server id ${msg['id']}');
            return;
          }
        }

        log('➕ Adding new message ID: ${msg['id']}');
        addAndSortMessage(msg, fromMe: isMine);

        // Confirm delivery to server for messages from others
        if (!isMine && data['id'] != null) {
          socketService.emit('messageDelivered', {
            'chatId': incomingChatId,
            'messageId': data['id'],
          });
          log('📨 Emitted messageDelivered for msgId=${data['id']}');
        }

        if (Get.currentRoute == '/DirectMessageScreen') {
          markChatAsRead();
        }
      } catch (e) {
        log('⚠️ newMessage parse error: $e | data=$raw');
      }
    });

    // Listen for read receipts from other users
    socketService.listenToEvent('chatRead', (raw) {
      try {
        final data = Map<String, dynamic>.from(raw as Map);
        final readChatId = _safeInt(data['chatId']);
        final readerId = _safeInt(data['userId']);

        if (readChatId != chatId.value || readerId == senderId.value) return;

        // Mark all messages as read by this user.
        // Also: now that the recipient has read the chat, system messages
        // (e.g. "X set disappearing messages to ...") have served their
        // purpose. Stamp them with a 30s expiry so they auto-clear.
        final expireAt = DateTime.now()
            .add(const Duration(seconds: 30))
            .toIso8601String();
        for (var i = 0; i < item.length; i++) {
          final rbSet = <int>{...((item[i]['readBy'] as List?) ?? const [])};
          rbSet.add(readerId);
          item[i]['readBy'] = rbSet.toList();

          if (item[i]['isSystem'] == true &&
              (item[i]['expiresAt'] == null ||
                  item[i]['expiresAt'].toString().isEmpty)) {
            item[i]['expiresAt'] = expireAt;
          }
        }
        item.refresh();
        log('✅ chatRead: user $readerId read chat $readChatId');
      } catch (e) {
        log('⚠️ chatRead parse error: $e');
      }
    });

    // Listen for delivery confirmations from other users
    socketService.listenToEvent('messageDelivered', (raw) {
      try {
        final data = Map<String, dynamic>.from(raw as Map);
        final deliveredChatId = _safeInt(data['chatId']);
        final deliveredUserId = _safeInt(data['userId']);
        final lastDeliveredId = _safeInt(data['lastDeliveredMessageId']);

        if (deliveredChatId != chatId.value ||
            deliveredUserId == senderId.value)
          return;

        // Mark all messages up to lastDeliveredId as delivered
        for (var i = 0; i < item.length; i++) {
          final msgId = _safeInt(item[i]['id']);
          if (msgId > 0 && msgId <= lastDeliveredId) {
            final dtSet = <int>{
              ...((item[i]['deliveredTo'] as List?) ?? const []),
            };
            dtSet.add(deliveredUserId);
            item[i]['deliveredTo'] = dtSet.toList();
          }
        }
        item.refresh();
        log(
          '📨 messageDelivered: user $deliveredUserId delivered up to msgId=$lastDeliveredId',
        );
      } catch (e) {
        log('⚠️ messageDelivered parse error: $e');
      }
    });

    // Listen for disappearing messages setting changes
    socketService.listenToEvent('disappearingMessagesChanged', (raw) {
      try {
        final data = Map<String, dynamic>.from(raw as Map);
        final eventChatId = _safeInt(data['chatId']);
        if (eventChatId != chatId.value) return;

        // Add the system message from the event to the chat
        final label = data['label'] ?? '';
        final changedBy = _safeInt(data['changedBy']);
        log(
          '⏱️ disappearingMessagesChanged: chatId=$eventChatId, label=$label, changedBy=$changedBy',
        );
      } catch (e) {
        log('⚠️ disappearingMessagesChanged parse error: $e');
      }
    });

    // Listen for expired messages cleanup — remove locally without refetching
    socketService.listenToEvent('messagesExpired', (raw) {
      try {
        final data = Map<String, dynamic>.from(raw as Map);
        final List<dynamic> expiredIds = data['messageIds'] ?? [];
        if (expiredIds.isNotEmpty) {
          item.removeWhere((m) => expiredIds.contains(m['id']));
          item.refresh();
          log('🗑️ Removed ${expiredIds.length} expired messages locally');
        } else {
          // Fallback: remove by expiresAt check
          _removeExpiredMessages();
        }
      } catch (e) {
        _removeExpiredMessages();
        log('⚠️ messagesExpired parse error: $e');
      }
    });

    // Listen for messages deleted after read — remove locally without refetching
    socketService.listenToEvent('messagesDeleted', (raw) {
      try {
        final data = Map<String, dynamic>.from(raw as Map);
        final List<dynamic> deletedIds = data['messageIds'] ?? [];
        if (deletedIds.isNotEmpty) {
          item.removeWhere((m) => deletedIds.contains(m['id']));
          item.refresh();
          log('🗑️ Removed ${deletedIds.length} deleted messages locally');
        }
      } catch (e) {
        log('⚠️ messagesDeleted parse error: $e');
      }
    });

    // If the current user is banned from this community/group, eject them.
    void handleBanned(dynamic raw, String label) {
      try {
        final data = Map<String, dynamic>.from(raw as Map);
        final bannedId = int.tryParse('${data['userId'] ?? ''}') ?? -1;
        if (bannedId == senderId.value) {
          AppSnackbar.error('You have been banned from this $label.');
          if (Get.isRegistered<MessagesScreenController>()) {
            Get.find<MessagesScreenController>().fetchChats();
          }
          // Leave the chat — back to the conversation list.
          if (Get.key.currentState?.canPop() == true) Get.back();
        }
      } catch (e) {
        log('⚠️ banned event parse error: $e');
      }
    }

    socketService.listenToEvent(
      'community.member_banned',
      (raw) => handleBanned(raw, 'community'),
    );
    socketService.listenToEvent(
      'group.member_banned',
      (raw) => handleBanned(raw, 'group'),
    );
  }

  /// Delete the user's OWN messages for everyone. Server filters to caller-owned
  /// ids and broadcasts `messagesDeleted` (handled by the listener above, which
  /// removes them from [item] — including for the sender).
  void deleteMyMessages(List<int> messageIds) {
    if (messageIds.isEmpty) return;
    socketService.sendMessage('deleteMessage', {
      'chatId': chatId.value,
      'messageIds': messageIds,
    });
    log('🗑️ deleteMessage emit: $messageIds');
  }

  /// Admin (group admin / community creator) deletes any message.
  Future<bool> adminDeleteMessage(int messageId) async {
    try {
      final res = await ApiService.adminDeleteMessage(messageId);
      // Server emits messagesDeleted; local removal handled by the listener.
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      log('❌ adminDeleteMessage error: $e');
      return false;
    }
  }

  /// Report a single message to the moderation team.
  Future<bool> reportMessage({
    required int messageId,
    required String reason,
    String? note,
  }) async {
    try {
      final res = await ApiService.reportMessage(
        messageId: messageId,
        reason: reason,
        note: note,
      );
      log('🚩 reportMessage($messageId) → ${res.statusCode} ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      log('❌ reportMessage error: $e');
      return false;
    }
  }

  String _normalizeAvatarUrl(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http')) return s;
    if (s.startsWith('/')) return '${ApiConstants}$s';
    return '${ApiConstants}/$s';
  }

  bool _isVideoPath(String p) {
    p = p.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.mkv') ||
        p.endsWith('.avi') ||
        p.endsWith('.webm') ||
        p.endsWith('.m4v');
  }

  bool _isVideoUrl(String? u) {
    if (u == null) return false;
    return _isVideoPath(u);
  }

  // ── Reply / quote (item 8) ────────────────────────────────────────────────
  /// The message currently being replied to (null = not replying).
  final Rxn<Map<String, dynamic>> replyingTo = Rxn<Map<String, dynamic>>();

  void startReply(Map msg) {
    final sender = msg['sender'] ?? {};
    replyingTo.value = {
      'id': msg['id'],
      'senderName':
          (msg['sender']?['firstName'] ??
                  sender['username'] ??
                  (msg['isMine'] == true ? 'You' : ''))
              .toString(),
      'content':
          (msg['text'] ?? msg['caption'] ?? msg['content'] ?? '').toString(),
      'imageUrl': msg['imageUrl'] ?? msg['mediaUrl'],
      'isMine': msg['isMine'] ?? false,
    };
    messageFocusNode.requestFocus();
  }

  void cancelReply() => replyingTo.value = null;

  // Per-message keys (by id) so tapping a reply quote can scroll to the
  // original message via Scrollable.ensureVisible.
  final Map<int, GlobalKey> messageKeys = {};

  /// Briefly highlighted message (after jumping to it from a reply chip).
  final RxnInt highlightedMessageId = RxnInt();

  GlobalKey keyForMessage(int id) =>
      messageKeys.putIfAbsent(id, () => GlobalKey());

  void _flashHighlight(int id) {
    highlightedMessageId.value = id;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (highlightedMessageId.value == id) highlightedMessageId.value = null;
    });
  }

  // Centre the target's (now-built) widget precisely. Runs ensureVisible twice
  // so variable image heights settle and it lands exactly on the message.
  Future<void> _centerOn(int id) async {
    final ctx = messageKeys[id]?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 240),
      alignment: 0.45,
      curve: Curves.easeInOut,
    );
    await Future.delayed(const Duration(milliseconds: 30));
    final ctx2 = messageKeys[id]?.currentContext;
    if (ctx2 != null) {
      await Scrollable.ensureVisible(
        ctx2,
        alignment: 0.45,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
      );
    }
    _flashHighlight(id);
  }

  int _displayIndexOfId(String mid) {
    final ri = item.indexWhere((m) => '${m['id']}' == mid);
    return ri < 0 ? -1 : item.length - 1 - ri;
  }

  /// Scroll to + briefly highlight the original message of a reply.
  ///
  /// The target is often off-screen in the lazy list (not built → no context).
  /// A single proportional jump is unreliable with variable image heights, so
  /// we step one viewport at a time toward it (which builds the items along the
  /// way) until its key exists, then centre exactly.
  Future<void> jumpToMessage(int id) async {
    if (!scrollController.hasClients) return;

    // Already on-screen → centre directly.
    if (messageKeys[id]?.currentContext != null) {
      await _centerOn(id);
      return;
    }

    final realIndex = item.indexWhere((m) => '${m['id']}' == '$id');
    if (realIndex < 0) {
      AppSnackbar.info('Original message isn\'t loaded.');
      return;
    }
    final targetDisplay = item.length - 1 - realIndex;

    for (int attempt = 0; attempt < 40; attempt++) {
      if (messageKeys[id]?.currentContext != null) {
        await _centerOn(id);
        return;
      }

      // Which way to step? Find the display-index window currently built.
      int? maxBuilt; // largest display index built (toward older / top)
      int? minBuilt; // smallest display index built (toward newer / bottom)
      messageKeys.forEach((mid, key) {
        if (key.currentContext == null) return;
        final di = _displayIndexOfId('$mid');
        if (di < 0) return;
        if (maxBuilt == null || di > maxBuilt!) maxBuilt = di;
        if (minBuilt == null || di < minBuilt!) minBuilt = di;
      });

      final pos = scrollController.position;
      final step = pos.viewportDimension * 0.85;
      double target;
      if (maxBuilt != null && targetDisplay > maxBuilt!) {
        // Older than the visible window → larger offset (reverse list).
        target = pos.pixels + step;
      } else if (minBuilt != null && targetDisplay < minBuilt!) {
        target = pos.pixels - step;
      } else {
        // Fallback: proportional nudge.
        final max = pos.maxScrollExtent;
        target =
            item.length <= 1 ? 0.0 : (targetDisplay / (item.length - 1)) * max;
      }
      target = target.clamp(0.0, pos.maxScrollExtent);
      await scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 25));
    }

    // Last try.
    if (messageKeys[id]?.currentContext != null) await _centerOn(id);
  }

  int? get _replyToId {
    final id = replyingTo.value?['id'];
    return id is int ? id : int.tryParse('${id ?? ''}');
  }

  /// Normalize a server message's reply info into the shape the quote chip
  /// expects ({id, senderName, content, imageUrl}) so BOTH sender and receiver
  /// render the reply mention. Handles a nested reply object (replyTo /
  /// replyToMessage / parentMessage) OR a bare replyToMessageId, which is
  /// resolved from the already-loaded messages.
  Map<String, dynamic>? _parseReplyTo(Map data) {
    final raw =
        data['replyTo'] ?? data['replyToMessage'] ?? data['parentMessage'];
    if (raw is Map) {
      final rs = (raw['sender'] as Map?) ?? const {};
      final nm =
          ('${rs['firstName'] ?? ''} ${rs['lastName'] ?? ''}').trim();
      return {
        'id': raw['id'],
        'content':
            (raw['content'] ?? raw['text'] ?? raw['caption'] ?? '').toString(),
        'imageUrl': raw['imageUrl'] ?? raw['mediaUrl'],
        'senderName':
            nm.isNotEmpty
                ? nm
                : (raw['senderName'] ?? rs['username'] ?? '').toString(),
      };
    }
    // Only an id echoed → resolve the original from loaded messages.
    final rid = _toInt(
          data['replyToMessageId'] ??
              data['replyToId'] ??
              (raw is num ? raw : null),
        ) ??
        0;
    if (rid != 0) {
      Map? orig;
      for (final m in _allMessages) {
        if (_toInt(m['id']) == rid) {
          orig = m;
          break;
        }
      }
      if (orig == null) {
        for (final m in item) {
          if (_toInt(m['id']) == rid) {
            orig = m;
            break;
          }
        }
      }
      if (orig != null) {
        final os = (orig['sender'] as Map?) ?? const {};
        final onm =
            (orig['sender']?['firstName'] ?? os['username'] ?? '').toString();
        return {
          'id': rid,
          'content':
              (orig['text'] ?? orig['caption'] ?? orig['content'] ?? '')
                  .toString(),
          'imageUrl': orig['imageUrl'] ?? orig['mediaUrl'],
          'senderName': (orig['isMine'] == true) ? 'You' : onm,
        };
      }
      // Original not loaded yet — still show a (tappable) reply chip.
      return {'id': rid, 'content': '', 'imageUrl': null, 'senderName': ''};
    }
    return null;
  }

  /// Snapshot of the reply target for the optimistic local message so the quote
  /// chip renders immediately (before the server echoes `replyTo`).
  Map<String, dynamic>? _localReplyTo() {
    final r = replyingTo.value;
    if (r == null) return null;
    return {
      'id': r['id'],
      'content': r['content'],
      'imageUrl': r['imageUrl'],
      'senderName': r['senderName'],
    };
  }

  Future<bool> sendPendingStrict({String? caption}) async {
    final XFile? img = pendingImage.value;
    final XFile? vid = pendingVideo.value;
    final String? cap =
        (caption != null && caption.trim().isNotEmpty) ? caption.trim() : null;

    // Bail if the socket was never created (chat init returned early) — touching
    // socketService before it's assigned throws LateInitializationError.
    if (!_socketInited || !socketService.isConnected()) return false;

    // Snapshot the reply target (if any) before clearing it, so both the local
    // message and the outgoing socket payload carry it.
    final int? replyId = _replyToId;
    final Map<String, dynamic>? replyLocal = _localReplyTo();
    cancelReply();

    final XFile? media = vid ?? img;
    if (media != null) {
      final now = DateTime.now();
      final tempId = 'm-${now.microsecondsSinceEpoch}';
      final bool isVideo = _isVideoPath(media.path);

      // Show message immediately with local preview + uploading state
      final msg = {
        'tempId': tempId,
        'chatId': chatId.value,
        'senderId': senderId.value,
        'type': 'image',
        'isVideo': isVideo,
        'text': cap,
        'caption': cap,
        'localPath': isVideo ? null : media.path,
        'localVideoPath': isVideo ? media.path : null,
        'createdAt': now.toIso8601String(),
        'isMine': true,
        'uploading': true,
        'failed': false,
        'readBy': <int>[],
        'deliveredTo': <int>[],
        'replyTo': replyLocal,
      };
      addAndSortMessage(msg, fromMe: true);

      // Clear input immediately so user can keep chatting
      pendingImage.value = null;
      pendingVideo.value = null;
      messageController.clear();

      // Upload in the background
      try {
        final mediaUrl = await ApiService.uploadChatImage(file: media);

        // Update the placeholder message with the real URL
        final idx = item.indexWhere((m) => m['tempId'] == tempId);
        if (idx != -1) {
          item[idx] = {
            ...item[idx],
            'imageUrl': mediaUrl,
            'mediaUrl': mediaUrl,
            'uploading': false,
            'isVideo': isVideo || _isVideoUrl(mediaUrl),
          };
          item.refresh();
        }

        socketService.sendMessage('sendMessage', {
          'tempId': tempId,
          'chatId': chatId.value,
          'senderId': senderId.value,
          'type': 'image',
          'imageUrl': mediaUrl,
          'content': cap ?? '',
          'meta': {'isVideo': isVideo || _isVideoUrl(mediaUrl)},
          'createdAt': now.toIso8601String(),
          if (replyId != null) 'replyToMessageId': replyId,
        });

        return true;
      } catch (e) {
        // Mark as failed so user can retry
        final idx = item.indexWhere((m) => m['tempId'] == tempId);
        if (idx != -1) {
          item[idx] = {...item[idx], 'uploading': false, 'failed': true};
          item.refresh();
        }
        log('❌ media upload failed: $e');
        return false;
      }
    }

    // ---- TEXT only
    if (cap == null) return false;

    final now = DateTime.now();
    final tempId = 't-${now.microsecondsSinceEpoch}';

    final msg = {
      'tempId': tempId,
      'chatId': chatId.value,
      'senderId': senderId.value,
      'type': 'text',
      'text': cap,
      'content': cap,
      'createdAt': now.toIso8601String(),
      'isMine': true,
      'uploading': false,
      'failed': false,
      'readBy': <int>[],
      'deliveredTo': <int>[],
      'replyTo': replyLocal,
    };
    addAndSortMessage(msg, fromMe: true);

    socketService.sendMessage('sendMessage', {
      'tempId': tempId,
      'chatId': chatId.value,
      'senderId': senderId.value,
      'type': 'text',
      'content': cap,
      'createdAt': now.toIso8601String(),
      if (replyId != null) 'replyToMessageId': replyId,
    });

    messageController.clear();
    return true;
  }

  var grouptotalpopint = 0.obs;
  var groupweeklypopint = 0.obs;
  Future<void> getMember(int groupIds) async {
    try {
      final groupData = await ApiService.getGroupDetails(groupIds);
      final groupObj = Group.fromJson(groupData);
      final members = groupObj.members;

      final int totalPoints = members.fold(0, (sum, m) => sum + m.points);
      final int totalWeekPoints = members.fold(
        0,
        (sum, m) => sum + m.thisWeekPoints,
      );
      grouptotalpopint.value = totalPoints;
      groupweeklypopint.value = totalWeekPoints;

      // log("Group Data: $groupData");
    } catch (e) {
      print('Error fetching members: $e');
      log('Error details: $e');
    }
  }

  RxBool isLocked = false.obs;
  RxString userRole = ''.obs;

  Future<void> getChatIdFromGroup(int groupId) async {
    final chat = await fetchChatForGroup(groupId);

    if (chat != null) {
      log('Fetched chat object: $chat');
      chatId.value = chat.id;
      groupimageurl.value = chat.imageUrl ?? "";
      isLocked.value = chat.isLocked;

      final String groupName = chat.name ?? "Unknown Group";
      print("Group name for ID $groupId is: $groupName");
      log("Chat ID for group: ${chat.id}");
      log("Group image url: ${groupimageurl.value}");
    } else {
      log("❌ Chat not found for group $groupId");
    }
  }

  Future<ChatModel?> fetchChatForGroup(int groupId) async {
    try {
      final Map<String, dynamic> data = await ApiService.getGroupDetails(
        groupId,
      );
      log('🔎 group raw: ${jsonEncode(data)}');

      final String name = (data['groupName'] ?? data['name'] ?? '').toString();
      final String img =
          (data['groupImage'] ?? data['imageUrl'] ?? '').toString();
      final List members = (data['members'] as List?) ?? const [];
      final bool isLocked = data['isLocked'] == true;

      // 🔹 Find the current user and get their role directly from the map
      final currentMember = members.firstWhere(
        (m) => m['id'] == senderId.value,
        orElse: () => null,
      );

      if (currentMember != null) {
        userRole.value = currentMember['role'] ?? '';
        log('👤 Current user role: ${userRole.value}');
      } else {
        userRole.value = '';
        log('⚠️ Current user not found in members');
      }
      return ChatModel(
        id: groupId,
        name: name.isNotEmpty ? name : null,
        isGroup: true,
        isCommunity: false,
        isLocked: isLocked,
        imageUrl: img,
        users: members.map((m) => FriendsModel.fromJson(m)).toList(),
        messages: const [],
      );
    } catch (e, st) {
      log('❌ fetchChatForGroup error: $e\n$st');
      return null;
    }
  }

  Future<void> createChat({required int userId}) async {
    try {
      List<int> userIds = [userId];

      log(
        'CREATE_CHAT: calling POST /chats/create with UserId=$userIds, isGroup=false',
      );

      Map<String, dynamic> chat = await ApiService.createChat(
        userIds: userIds,
        isGroup: false,
      );

      log('CREATE_CHAT: full server response: $chat');
      log('CREATE_CHAT: response keys: ${chat.keys.toList()}');

      int chatIds = chat['chatId'] ?? chat['id'] ?? 0;
      if (chatIds == 0) {
        log(
          'CREATE_CHAT: WARNING - could not find chatId or id in response, trying first int value',
        );
        for (var v in chat.values) {
          if (v is int && v > 0) {
            chatIds = v;
            break;
          }
        }
      }
      chatId.value = chatIds;
      log('CREATE_CHAT: chatId set to: ${chatId.value}');
    } catch (e) {
      log('CREATE_CHAT: ERROR: $e');
    }
  }

  var userweekpoints = 0.obs;
  var usertotalpoints = 0.obs;
  Future<void> getUserProfile(int id) async {
    try {
      final profileData = await ApiService.getanyUserProfile(id);

      log("📥 Full User Profile: ${json.encode(profileData)}");

      profiledata.value = profileData;

      final firstName = profileData['firstName'] ?? '';
      final lastName = profileData['lastName'] ?? '';
      final fullName = "$firstName $lastName".trim();
      final thisweekpoint = profileData["thisWeekPoints"] ?? "";
      final totalpoints = profileData["totalPoints"] ?? "";
      final minimeList = profileData['minime'] as List<dynamic>? ?? [];
      final avatarUrl =
          minimeList.isNotEmpty ? (minimeList[0]['avatarUrl'] ?? '') : '';
      cacheUserBasic(userId: id, name: fullName, avatarUrl: avatarUrl);
      log("👤 Username: $username");
      log("🖼️ Avatar: $avatarUrl");
      userweekpoints.value = thisweekpoint;
      usertotalpoints.value = totalpoints;
      friendName.value = fullName;
      avatarurl.value = avatarUrl;
    } catch (e) {
      log("❌ Error: $e");
    }
  }

  Future<void> getFriendProfile(int id) async {
    try {
      final response = await ApiService.fetchFriendProfile(id);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData["success"] == true) {
          // Convert the JSON data into a FriendsModel instance
          final friend = (jsonData["data"]);
          final avatar =
              friend.minime.isNotEmpty
                  ? (friend.minime[0]['avatarUrl'] ?? '')
                  : '';
          avatarurl.value = avatar;

          log(friend.avatarUrl);
          log("📥 Full Friend Data: ${json.encode(jsonData["data"])}");

          friendData.value = friend;

          print("✅ Friend Profile Loaded: ${friend.fullName}");
        } else {
          print("❌ Failed: ${jsonData["message"]}");
        }
      } else {
        print("❌ Server Error8: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }

  // Start true so the shimmer shows from the very first frame (onInit runs
  // several awaits before the first fetch). Otherwise the screen flickers
  // empty-state → shimmer → empty-state.
  var isLoading = true.obs;

  // Direct chats personalize the empty state with the friend's name
  // ("Say hi to Bappi"), so keep shimmering until that name has loaded —
  // otherwise the generic "No messages yet" flashes first. Group/community/
  // global use generic copy and don't need to wait.
  bool get isChatHeaderReady {
    final isDirect =
        groupid.value == 0 &&
        communityId.value == 0 &&
        !isGlobalChat.value;
    if (!isDirect) return true;
    return friendName.value.isNotEmpty;
  }

  Future<void> getchatwithchatId({bool initialLoad = false}) async {
    isLoading.value = true;
    try {
      log(
        "📡 Fetching chat messages for chatId: ${chatId.value}, isGlobal=${isGlobalChat.value}",
      );

      List<dynamic> data;
      if (isGlobalChat.value) {
        data = await ApiService.getGlobalChatMessages(
          chatId: chatId.value,
          page: 1,
          limit: 100,
        );
      } else {
        data = await ApiService.getChatMessages(chatId.value);
      }

      data.sort((a, b) {
        DateTime timeA =
            DateTime.tryParse(a['createdAt'].toString()) ?? DateTime(1970);
        DateTime timeB =
            DateTime.tryParse(b['createdAt'].toString()) ?? DateTime(1970);
        return timeA.compareTo(timeB);
      });

      // Store all messages, filter expired
      _allMessages.clear();
      final now = DateTime.now();
      for (var msg in data) {
        final expiresAt = msg['expiresAt'];
        if (expiresAt != null && expiresAt.toString().isNotEmpty) {
          final expiry = DateTime.tryParse(expiresAt.toString());
          if (expiry != null && expiry.isBefore(now)) continue;
        }
        final bool isMyMessage = calcIsMine(msg);
        // For own sent messages: only trust readBy from server,
        // clear deliveredTo so it's only set by real-time socket events.
        // This prevents false double-ticks for offline/logged-out users.
        final cleanedMsg = <String, dynamic>{...msg, 'isMine': isMyMessage};
        // Normalize reply info into the quote-chip shape (covers both sender
        // and receiver). Original is already in _allMessages (added earlier in
        // this oldest→newest loop) for id-only echoes.
        final parsedReply = _parseReplyTo(msg);
        if (parsedReply != null) {
          cleanedMsg['replyTo'] = parsedReply;
        } else {
          cleanedMsg.remove('replyTo');
        }
        if (isMyMessage) {
          final readBy = List<int>.from(msg['readBy'] ?? []);
          if (readBy.any((id) => id != senderId.value)) {
            // Message was actually read — keep both readBy and deliveredTo
          } else {
            // Not read — clear deliveredTo so we only show double-tick
            // when a real-time messageDelivered socket event arrives
            cleanedMsg['deliveredTo'] = <int>[];
          }
        }
        _allMessages.add(cleanedMsg);
      }

      // Show only last _pageSize messages initially
      item.clear();
      final startIndex =
          (_allMessages.length > _pageSize)
              ? _allMessages.length - _pageSize
              : 0;
      item.addAll(_allMessages.sublist(startIndex));
      hasMoreMessages.value = startIndex > 0;

      log("✅ Loaded ${_allMessages.length} total, showing ${item.length}");
    } catch (e) {
      log("❌ Error loading chats: $e");
    } finally {
      isLoading.value = false;
      // With reverse:true the list is already pinned to the bottom (offset 0 =
      // newest) the moment it renders — no jump-to-bottom needed, so there's no
      // flicker/bounce even while images finish loading.
      if (initialLoad) {
        initialScrollPending.value = false;
        showScrollDownArrow.value = false;
      }
    }
  }

  void _onScroll() {
    // reverse:true → the TOP of the list is at maxScrollExtent. Load older
    // messages when scrolled near the top.
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100 &&
        hasMoreMessages.value &&
        !isLoadingMore.value) {
      loadMoreMessages();
    }
    // Show/hide scroll-to-bottom arrow
    showScrollDownArrow.value = !_nearBottom;
  }

  void loadMoreMessages() {
    if (isLoadingMore.value || !hasMoreMessages.value) return;
    isLoadingMore.value = true;

    final currentCount = item.length;
    final totalCount = _allMessages.length;
    final remaining = totalCount - currentCount;

    if (remaining <= 0) {
      hasMoreMessages.value = false;
      isLoadingMore.value = false;
      return;
    }

    final loadCount = remaining < _pageSize ? remaining : _pageSize;
    final startIndex = totalCount - currentCount - loadCount;

    // Prepend older messages. With reverse:true, inserting at data-index 0 keeps
    // every currently-visible message at the same VISUAL index, so the scroll
    // position stays put automatically — no manual offset restore needed.
    item.insertAll(0, _allMessages.sublist(startIndex, startIndex + loadCount));
    hasMoreMessages.value = startIndex > 0;
    isLoadingMore.value = false;

    log(
      "📜 Loaded $loadCount more, showing ${item.length}/${_allMessages.length}",
    );
  }

  Future<void> pickImageOnly({ImageSource source = ImageSource.gallery}) async {
    // NOTE: do NOT pass imageQuality/maxWidth here. On iOS, image_picker's
    // resize/re-encode path mishandles wide-gamut (Display P3 / HDR) photos
    // from newer iPhones (14/16/17) and tints the result green. Picking the
    // original keeps the correct colours.
    final x = await _picker.pickImage(source: source);
    if (x == null) {
      log('🟡 pickImageOnly: user cancelled');
      return;
    }
    pendingImage.value = x;
    log('🖼️ picked: ${x.name}');
  }

  void clearPendingImage() {
    pendingImage.value = null;
    log('🧹 pending image cleared');
  }

  Future<void> loadFriendList() async {
    try {
      final response = await ApiService.fetchFriendList();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          List<dynamic> data = jsonData['data'];
          friends1.value = data.map((e) => FriendsModel.fromJson(e)).toList();
          print("Loaded ${friends1.length} friends from server.");
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

  DateTime _parseDT(dynamic v) {
    if (v is DateTime) return v;
    if (v is int) {
      if (v > 100000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }

  void scrollToBottom({bool animated = false, bool deferred = false}) {
    if (deferred) {
      // Used after list rebuild (initial load, new messages) — wait for layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performScrollToBottom(animated);
      });
    } else {
      // Immediate — used when user taps the scroll-down button
      _performScrollToBottom(animated);
    }
  }

  void _performScrollToBottom(bool animated) {
    if (!scrollController.hasClients) return;
    // reverse:true → the bottom (newest message) is offset 0.
    const target = 0.0;

    if (animated) {
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(target);
    }
    showScrollDownArrow.value = false;
  }

  bool get _nearBottom {
    if (!scrollController.hasClients) return true;
    // reverse:true → bottom (newest) is offset 0.
    return scrollController.offset < 200;
  }

  DateTime parseDT(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (e) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void addAndSortMessage(Map<String, dynamic> msg, {bool fromMe = false}) {
    msg['createdAt'] ??= DateTime.now().toIso8601String();

    final tempId = msg['tempId'];
    final serverId = msg['id'];

    final idx = item.indexWhere(
      (m) =>
          (serverId != null && m['id'] == serverId) ||
          (tempId != null && m['tempId'] == tempId),
    );

    if (idx != -1) {
      item[idx] = {...item[idx], ...msg};
    } else {
      item.add(msg);
    }

    // সর্টিং (Server Time + ID Tie breaker)
    item.sort((a, b) {
      final timeA = _parseDT(a['createdAt']);
      final timeB = _parseDT(b['createdAt']);

      int comparison = timeA.compareTo(timeB);

      if (comparison == 0) {
        final int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return idA.compareTo(idB);
      }
      return comparison;
    });

    item.refresh();

    if (fromMe || _nearBottom) {
      // Smooth animated scroll for live messages (send / incoming near bottom).
      // The instant jump is only for initial load (handled separately).
      scrollToBottom(deferred: true, animated: true);
    }
  }

  void markChatAsRead() async {
    if (item.isEmpty) {
      log("🟡 No messages to mark as read");
      return;
    }

    final lastMessage = item.last;
    final int? lastMessageId = int.tryParse('${lastMessage['id']}');
    if (lastMessageId == null) {
      log("🟡 No valid last message ID");
      return;
    }

    try {
      // Notify the server
      final response = await ApiService.markChatAsRead(chatId.value);
      log("✅ Chat marked as read: $response");

      // Update local state
      for (var i = 0; i < item.length; i++) {
        final mid = int.tryParse('${item[i]['id']}') ?? -1;
        if (mid > 0 && mid <= lastMessageId) {
          final rbSet = <int>{...((item[i]['readBy'] as List?) ?? const [])};
          rbSet.add(senderId.value);
          item[i]['readBy'] = rbSet.toList();
        }
      }
      item.refresh();

      // Notify MessagesScreenController
      if (Get.isRegistered<MessagesScreenController>()) {
        Get.find<MessagesScreenController>().markChatAsReadLocal(
          chatId.value,
          lastMessageId,
          senderId.value,
        );
      }
    } catch (e) {
      log("❌ Failed to mark chat as read: $e");
    }
  }

  bool calcIsMine(Map m) {
    final sid =
        _toInt(m['senderId']) ??
        _toInt(m['userId']) ??
        _toInt((m['sender'] as Map?)?['id']);
    return sid == senderId.value;
  } // Controller fields

  void cacheUserBasic({required int userId, String? name, String? avatarUrl}) {
    final prev = userCache[userId] ?? {};
    userCache[userId] = {
      'name': name ?? prev['name'] ?? '',
      'avatarUrl':
          (avatarUrl != null && avatarUrl.isNotEmpty)
              ? _normalizeAvatarUrl(avatarUrl)
              : (prev['avatarUrl'] ?? ''),
    };
  }

  final Rxn<XFile> pendingVideo = Rxn<XFile>();

  Future<void> pickMediaOnly() async {
    XFile? picked;

    try {
      picked = await _picker.pickMedia();
      // picked = await _picker.pickImage(source: ImageSource.gallery);
    } catch (_) {
      picked = null;
    }

    if (picked == null) {
      log(' pickMediaOnlyMessengerLike: user cancelled / not supported');
      return;
    }

    if (_isVideoPath(picked.path)) {
      pendingVideo.value = picked;
      pendingImage.value = null;
      log('🎬 picked video (pending only): ${picked.name}');
    } else {
      pendingImage.value = picked;
      pendingVideo.value = null;
      log('🖼️ picked image (pending only): ${picked.name}');
    }
  }

  /// Display name of the current chat (friend / group / global).
  String get chatDisplayName {
    if (friendName.value.trim().isNotEmpty) return friendName.value.trim();
    if (groupname.value.trim().isNotEmpty) return groupname.value.trim();
    if (globalChatName.value.trim().isNotEmpty) {
      return globalChatName.value.trim();
    }
    return 'User';
  }

  /// Open the in-app camera in snap-to-friend mode (from the camera button).
  /// After capture + edit, the capture screen shows a "Send to {name}" button
  /// that routes the media back here via [sendSnapFile].
  void openAppCameraForSnap() {
    final cam = Get.put(CameraControllers());
    cam.setSnapTarget(chatId: chatId.value, name: chatDisplayName);
    // Open the in-app camera as its own route (NOT the main-screen tab — pushing
    // a second MainScreen mounts a duplicate CameraScreen and its GlobalKeys,
    // crashing the layout). Clear the snap target once the camera is closed.
    Get.to(() => const CameraScreen())?.then((_) => cam.clearSnapTarget());
  }

  /// Send a captured/edited snap file straight into this chat.
  Future<void> sendSnapFile(String path, {required bool isVideo}) async {
    if (isVideo) {
      pendingVideo.value = XFile(path);
      pendingImage.value = null;
    } else {
      pendingImage.value = XFile(path);
      pendingVideo.value = null;
    }
    if (Get.isRegistered<CameraControllers>()) {
      Get.find<CameraControllers>().clearSnapTarget();
    }
    await sendPendingStrict();
  }

  /// Take a photo directly from the device camera (snap to friend flow).
  Future<void> pickFromCamera() async {
    try {
      // No imageQuality/maxWidth — see pickImageOnly: that resize path tints
      // wide-gamut (P3/HDR) iPhone photos green.
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) {
        log('🟡 pickFromCamera: user cancelled');
        return;
      }
      pendingImage.value = picked;
      pendingVideo.value = null;
      log('📷 captured from camera: ${picked.name}');
    } catch (e) {
      log('❌ pickFromCamera error: $e');
    }
  }

  void onTapHeaderAvatar() {
    log(
      '🔵 onTapHeaderAvatar called — communityId=${communityId.value}, groupid=${groupid.value}, friendUserId=${frienduserId.value}',
    );

    if (communityId.value != 0) {
      log('🔵 Navigating to MembersPage for community: ${communityId.value}');

      Get.toNamed(Routes.community, arguments: {"id": communityId.value});
      return;
    }
    if (groupid.value != 0) {
      log(
        '🔵 Navigating to GroupMembersPage for group: ${groupid.value}, name: ${groupname.value}',
      );
      Get.toNamed(
        Routes.groupMembersPage,
        arguments: {"groupId": groupid.value, "groupName": groupname.value},
      );
      return;
    }

    log('🔵 Navigating to friend profile');
    final model = buildFriendModelForHeader();
    if (model == null) {
      log('🔴 Friend model is null, cannot navigate');
      return;
    }
    Get.toNamed(Routes.friendsProfile, arguments: model);
  }

  FriendsModel? buildFriendModelForHeader() {
    if (groupid.value != 0) return null;
    if (friendData.value != null) return friendData.value;
    final p = Map<String, dynamic>.from(profiledata);
    if (p.isNotEmpty) {
      String avatar = '';
      final minime = (p['minime'] as List?) ?? [];
      if (minime.isNotEmpty && minime.first is Map) {
        avatar = (minime.first['avatarUrl'] ?? '').toString();
      }
      avatar = avatar.isNotEmpty ? avatar : (p['avatarUrl'] ?? '').toString();

      int toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

      return FriendsModel(
        id: frienduserId.value,
        username: (p['username'] ?? '').toString(),
        firstName: (p['firstName'] ?? '').toString(),
        lastName: (p['lastName'] ?? '').toString(),
        avatarUrl: avatar,
        totalPoints: toInt(p['totalPoints']),
        thisWeekPoints: toInt(p['thisWeekPoints']),
        profileUrl: (p['profileUrl'] ?? '').toString(),
      );
    }

    final parts = friendName.value.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return FriendsModel(
      id: frienduserId.value,
      username: friendName.value,
      firstName: first,
      lastName: last,
      avatarUrl: avatarurl.value,
      totalPoints: 0,
      thisWeekPoints: 0,
      profileUrl: '',
    );
  }

  Future<void> _sendGlobalTextOnly() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    if (!_socketInited || !socketService.isConnected()) {
      log('⚠️ socket not connected, skip global send');
      return;
    }

    final int? replyId = _replyToId;
    final Map<String, dynamic>? replyLocal = _localReplyTo();
    cancelReply();

    final now = DateTime.now();
    final tempId = 'g-${now.microsecondsSinceEpoch}';
    final local = <String, dynamic>{
      'tempId': tempId,
      'id': null,
      'chatId': chatId.value,
      'senderId': senderId.value,
      'type': 'text',
      'text': text,
      'content': text,
      'imageUrl': null,
      'mediaUrl': null,
      'createdAt': now.toIso8601String(),
      'isMine': true,
      'uploading': false,
      'failed': false,
      'readBy': <int>[],
      'deliveredTo': <int>[],
      'replyTo': replyLocal,
    };

    addAndSortMessage(local, fromMe: true);
    socketService.sendMessage('sendMessage', {
      'tempId': tempId,
      'chatId': chatId.value,
      'senderId': senderId.value,
      'type': 'text',
      'content': text,
      'createdAt': now.toIso8601String(),
      if (replyId != null) 'replyToMessageId': replyId,
    });

    messageController.clear();
  }

  Future<void> onSend() async {
    final raw = messageController.text;
    final hasMedia = pendingImage.value != null || pendingVideo.value != null;

    log(
      'onPressSend() raw="$raw" '
      'isGlobal=${isGlobalChat.value} hasMedia=$hasMedia',
    );

    final caption = raw.trim();

    if (caption.isEmpty && !hasMedia) {
      log('onPressSend: nothing to send, returning');
      return;
    }

    if (isGlobalChat.value && !hasMedia) {
      log('onPressSend: GLOBAL TEXT ONLY → _sendGlobalTextOnly');
      await _sendGlobalTextOnly();
      return;
    }

    log('onPressSend: normal / media → sendPendingStrict');
    await sendPendingStrict(caption: caption);
  }

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
        }
      } else {
        print('❌ Failed to fetch Global ID: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error fetching Global ID: $e');
    }
  }

  ///
  // MessagesScreenController ক্লাসের ভেতরে ভেরিয়েবল এবং ফাংশনগুলো যোগ করুন

  final TextEditingController citySearchController = TextEditingController();
  var placePredictions = <Map<String, dynamic>>[].obs;
  Timer? _debounce;

  final String _googleApiKey = "AIzaSyDtd4M5UM7EOLQc2sA3P0OHn7gN3W53iLs";

  void searchCities(String input) {
    final cleanInput = input.trim();
    isCitySearching.value = cleanInput.isNotEmpty;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.trim().isEmpty) {
        placePredictions.clear();
        return;
      }
      if (cleanInput.isEmpty) {
        placePredictions.clear();
        return;
      }
      final String sessionToken =
          DateTime.now().millisecondsSinceEpoch.toString();
      final String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(cities)&components=country:us&language=en&key=$_googleApiKey&sessiontoken=$sessionToken";

      log("🔍 Searching URL: $url");

      try {
        final response = await http.get(Uri.parse(url));
        log("📨 Google API Response: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'OK') {
            placePredictions.value = List<Map<String, dynamic>>.from(
              data['predictions'],
            );
          } else {
            log(
              "⚠️ Google API Error Status: ${data['status']} - ${data['error_message']}",
            );
            placePredictions.clear();
          }
        }
      } catch (e) {
        log("❌ Network Error: $e");
      }
    });
  }

  var isCitySearching = false.obs;

  Future<void> joinGlobalChatByCity(String cityName) async {
    try {
      // EasyLoading.show(status: 'Joining $cityName...');

      final response = await ApiService.getGlobalchatIds(city: cityName);
      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          log("✅ Successfully joined global chat for city: $data");
          final info = GlobalChatInfo.fromJson(data);

          globalChatInfo.value = info;
          chatId.value = info.chatId;
          globalChatName.value = info.name;
          isGlobalChat.value = true;

          // Persist the selected city
          await UserPreference.saveSelectedCity(cityName);

          // Update the chat list controller's global chat info too
          if (Get.isRegistered<MessagesScreenController>()) {
            final msgCtrl = Get.find<MessagesScreenController>();
            msgCtrl.globalChatInfo.value = info;
            msgCtrl.globalLastMessage.value = info.latestMessage;
          }

          if (_socketInited && socketService.isConnected()) {
            socketService.joinRoom(
              chatId: chatId.value,
              userId: senderId.value,
            );
          }

          if (Get.currentRoute == Routes.directMessageScreen) {
            item.clear();
            await getchatwithchatId();
          } else {
            Get.toNamed(
              Routes.directMessageScreen,
              arguments: {
                "username": info.name,
                "chatId": info.chatId,
                "isGlobal": true,
              },
              preventDuplicates: false,
            );
          }
        } else {
          AppSnackbar.error(data['message'] ?? "Failed to join.");
        }
      } else {
        AppSnackbar.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      log("❌ Exception joining global chat: $e");
    }
  }

  var globalRooms = <GlobalModel>[].obs;
  var isGlobalLoading = false.obs;

  Future<void> fetchGlobalRooms() async {
    try {
      // isGlobalLoading.value = true;

      final roomsData = await ApiService.getGlobalRooms();
      log("📥 Raw Global Rooms Data: $roomsData");

      final List<GlobalModel> loadedRooms =
          roomsData.map((json) {
            return GlobalModel.fromJson(json);
          }).toList();

      globalRooms.assignAll(loadedRooms);

      log("🌍 Fetched ${roomsData} Global Rooms");
    } catch (e) {
      log("❌ Error loading global rooms: $e");
    } finally {
      // isGlobalLoading.value = false;
    }
  }
  // চ্যাট লক করার ফাংশন

  // চ্যাট আনলক করার ফাংশন
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

  Future<void> leaveGroup() async {
    try {
      // Close any open dialogs/bottom sheets first
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back();
      }

      AppLoading.show();
      final response = await ApiService.leaveGroup(chatId.value);
      AppLoading.hide();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'You have left the group';

        // Refresh messages list so the chat tile disappears.
        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }

        // Remove group from other local caches instantly.
        final gid = chatId.value;
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
      log('⚠️ Exception in leaveGroup: $e');
      AppSnackbar.error('Something went wrong: $e');
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

  Future<void> fetchMuteStatus(int id) async {
    try {
      // isLoading.value = true; // যদি মেসেজ লোড হওয়ার সময় Shimmer দেখাতে চান তবে এটি রাখতে পারেন
      final status = await ApiService.getMuteStatus(id);
      isMuted.value = status;
      log("🔔 Current Mute Status for Chat $id: ${isMuted.value}");
    } catch (e) {
      log("⚠️ Error fetching mute status: $e");
    } finally {
      // isLoading.value = false;
    }
  }

  // directmassagescreen_controller.dart এর ভেতর
  Future<void> leaveCommunityLogic(int commId) async {
    try {
      AppLoading.show();
      final response = await ApiService.leaveCommunity(commId);
      AppLoading.hide();

      if (response.statusCode == 200) {
        AppSnackbar.success("Successfully left the community");

        // ১. মেসেজ লিস্ট রিফ্রেশ করা
        if (Get.isRegistered<MessagesScreenController>()) {
          Get.find<MessagesScreenController>().fetchChats();
        }
        final NocommunityController communityController =
            Get.isRegistered<NocommunityController>()
                ? Get.find<NocommunityController>()
                : Get.put(NocommunityController());
        communityController.onInit();

        Get.until(
          (route) => route.isFirst || route.settings.name == Routes.mainscreen,
        );
      } else {
        AppSnackbar.error("Failed to leave community");
      }
    } catch (e) {
      AppLoading.hide();
      log("Leave Error: $e");
    }
  }
}
