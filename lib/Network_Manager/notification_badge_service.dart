import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';

/// App-wide notification badge state.
///
/// Every notification-bell across the app reads this single [notificationRedDot]
/// Rx (explore / profile / map / challenge / camera / messages), so updating it
/// once lights/clears ALL bells reactively at the same instant.
///
/// Realtime source = a dedicated, user-scoped socket. The backend emits a
/// `notification` event to this user on friend request/accept, challenge, etc.,
/// and we flip the dot immediately — no polling lag. Crucially this works even
/// when the user has disabled push notifications (the FCM listener won't fire
/// then, but the in-app websocket still does). [getRedDot] (HTTP) stays for the
/// authoritative initial value and as a fallback when the socket is down.
class NotificationBadgeService extends GetxService {
  var notificationRedDot = false.obs;

  IO.Socket? _socket;
  int _socketUserId = 0;

  @override
  void onInit() {
    super.onInit();
    // Connect early if we already have a logged-in user cached.
    _connectFromCache();
  }

  Future<void> _connectFromCache() async {
    final uid = await UserPreference.getUserId();
    if (uid != null && uid > 0) connectSocket(uid);
  }

  /// Open (or reuse) the realtime socket for [userId]. Idempotent — calling it
  /// again with the same connected user is a no-op; a new user reconnects.
  /// Call after login / profile load so the dot is live app-wide.
  void connectSocket(int userId) {
    if (userId <= 0) return;
    if (_socket != null && _socketUserId == userId && _socket!.connected) {
      return;
    }
    // Different user (account switch) — tear down the old connection first.
    if (_socket != null && _socketUserId != userId) {
      try {
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }

    _socketUserId = userId;
    // forceNew so this stays a separate connection from the chat sockets (no
    // shared-socket handler/disconnect cross-talk). query.userId lets the
    // backend map this socket to the user and target notification events at it.
    final socket = IO.io(ApiConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'forceNew': true,
      'query': {'userId': userId},
    });
    _socket = socket;

    socket.off('notification');
    socket.on('notification', _onNotificationEvent);

    socket.onConnect((_) {
      log('🔔 badge socket connected for user $userId');
      // In case the backend rooms by an explicit join rather than query.
      socket.emit('joinUser', userId);
      // Re-sync authoritative state on (re)connect — covers anything that
      // happened while the socket was down.
      getRedDot();
    });
    socket.onReconnect((_) => getRedDot());

    socket.connect();
  }

  void _onNotificationEvent(dynamic data) {
    log('🔔 notification socket event: $data');
    // Optional payload {hasUnread: bool}; default to true (something arrived).
    if (data is Map && data['hasUnread'] is bool) {
      notificationRedDot.value = data['hasUnread'] as bool;
    } else {
      notificationRedDot.value = true;
    }
  }

  Future<void> getRedDot() async {
    try {
      final response = await ApiService.getRedDot();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notificationRedDot.value = data['notificationRedDot'] ?? false;
      }
    } catch (e) {
      log("Error fetching red dot: $e");
    }
  }

  Future<void> clearNotificationDot() async {
    try {
      notificationRedDot.value = false;

      final response = await ApiService.resetNotificationRedDot();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          log("Notification red dot reset successfully");
        }
      }
    } catch (e) {
      log("Error clearing red dot: $e");
    }
  }

  @override
  void onClose() {
    try {
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    super.onClose();
  }
}
