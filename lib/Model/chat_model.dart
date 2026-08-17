import 'package:outspot/Model/friends_model.dart';

class ChatModel {
  final int id;
  final String? name;
  final bool isGroup;
  final bool isCommunity;
  final bool isLocked;
  final bool isMuted;

  /// Per-chat PASSWORD lock (privacy). Distinct from [isLocked] (group send
  /// freeze). When true the tile hides its preview and opening the chat requires
  /// the password or biometric. Backend sends this; it never sends the hash.
  final bool isPasswordLocked;

  final int? communityId;
  final String? imageUrl;
  final List<FriendsModel> users;
  final List<MessageModel> messages;
  MessageModel? latestMessage;

  /// Stable recency key from the backend (ISO 8601) = max(last message,
  /// chat.updatedAt, join time). Unlike a message timestamp, this does NOT
  /// change when a message disappears/clears — so the chat keeps its position
  /// in the list instead of dropping to the bottom. Used for ordering.
  final String? lastActivityAt;

  ChatModel({
    required this.id,
    this.name,
    required this.isGroup,
    required this.isCommunity,
    required this.isLocked,
    this.isMuted = false,
    this.isPasswordLocked = false,
    this.communityId,
    this.imageUrl,
    required this.users,
    required this.messages,
    this.latestMessage,
    this.lastActivityAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? 0,
      name: json['name'],
      isGroup: json['isGroup'] ?? false,
      isCommunity: json['isCommunity'] ?? false,
      isLocked: json['isLocked'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isPasswordLocked: json['isPasswordLocked'] == true,
      communityId: json['communityId'],
      imageUrl: json['imageUrl'],
      lastActivityAt: json['lastActivityAt'],
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => FriendsModel.fromJson(e))
              .toList() ??
          [],
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => MessageModel.fromJson(e))
              .toList() ??
          [],
      latestMessage:
          json['latestMessage'] != null
              ? MessageModel.fromJson(json['latestMessage'])
              : null,
    );
  }
}

class MessageModel {
  int id;
  String content;
  String? imageUrl;
  String createdAt;
  int senderId;
  List<int> readBy;
  List<int> deliveredTo;
  bool isSystem;
  String? expiresAt;

  MessageModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.senderId,
    required this.readBy,
    required this.deliveredTo,
    this.isSystem = false,
    this.expiresAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'],
      senderId: json['senderId'],
      readBy: List<int>.from(json['readBy'] ?? []),
      deliveredTo: List<int>.from(json['deliveredTo'] ?? []),
      isSystem: json['isSystem'] ?? false,
      expiresAt: json['expiresAt'],
    );
  }
}
