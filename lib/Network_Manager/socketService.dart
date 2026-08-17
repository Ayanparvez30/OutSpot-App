import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  int chatId = 0;
  int userId = 0;

  SocketService(String url) {
    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      // Own connection — without this, socket_io_client caches the socket per
      // URL and we'd share the SAME socket as MessagesScreenController. That
      // caused: (a) onConnect handlers piling up → joinChat re-fired to every
      // previously-opened chat, and (b) DM's disconnect() killing the
      // messages-list realtime socket.
      'forceNew': true,
    });
  }

  void connect({required int chatId, required int userId}) {
    this.chatId = chatId;
    this.userId = userId;

    socket.io.options?['query'] = {'userId': userId};

    if (!socket.connected) {
      socket.connect();
    } else {
      print('🔄 Reconnecting to ensure userId is passed...');
      socket.disconnect();
      socket.connect();
    }

    // Clear any previously-registered handlers so repeated connect() calls
    // don't stack duplicate listeners (each would re-emit joinChat).
    socket.off('connect');
    socket.off('connect_error');
    socket.off('error');
    socket.off('disconnect');

    socket.onConnect((_) {
      print('✅ Socket connected for User: $userId');

      if (this.chatId > 0) {
        joinRoom(chatId: this.chatId, userId: this.userId);
      }
    });

    socket.onConnectError((error) => print('❌ connect error: $error'));
    socket.onError((e) => print('❌ socket error: $e'));
    socket.onDisconnect((_) => print('⚠️ Socket disconnected'));
  }

  void setChatId(int chatId, int userId) {
    this.chatId = chatId;
    this.userId = userId;
  }

  void joinRoom({required int chatId, required int userId}) {
    if (!socket.connected) {
      print('⚠️ Socket is not connected');
      return;
    }

    socket.emit('joinChat', chatId);
    print('➡️ joinChat sent: chatId=$chatId');

    // Signal "actively viewing" on EVERY join path — including the auto-join
    // from onConnect (which bypasses the controller's joinCurrentRoom). Without
    // this, enterChat was missed whenever the socket connected after bind, so
    // the server never advanced clearedUpToMessageId on exit.
    enterChat(chatId);
  }

  void joinGlobalChat({required int userId}) {}

  // ---------- Disappearing (immediate) read-tracking ----------
  // Tell the server this user is actively viewing the chat. For chats with
  // disappearingSeconds == 1 the server uses enter/exit to drive per-user
  // clearedUpToMessageId (hide-on-exit). No-op server-side for other chats.
  void enterChat(int chatId) {
    if (chatId <= 0) return;
    socket.emit('enterChat', chatId);
    print('➡️ enterChat sent: chatId=$chatId');
  }

  // Tell the server this user left the chat → server hides the viewed
  // messages for this user (and hard-deletes once everyone has exited).
  void exitChat(int chatId) {
    if (chatId <= 0) return;
    socket.emit('exitChat', chatId);
    print('⬅️ exitChat sent: chatId=$chatId');
  }

  // ---------- Helpers ----------
  void listenToEvent(String eventName, void Function(dynamic) callback) {
    socket.on(eventName, callback);
  }

  void off(String eventName) {
    socket.off(eventName);
  }

  void emit(String event, dynamic payload) {
    socket.emit(event, payload);
  }

  void sendMessage(String event, dynamic message) {
    if (socket.connected) {
      socket.emit(event, message);
      print('📤 $event sent');
    } else {
      print('⚠️ Socket not connected');
    }
  }

  void disconnect() {
    socket.disconnect();
    print('🔌 Socket disconnected');
  }

  bool isConnected() => socket.connected;
}
