// notification_model.dart
import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final int userId;
  final int actorId;
  final String type;
  final String title;
  final String description;
  final bool isRead;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? actorUsername;
  final String? actorFirstName;
  final String? actorLastName;
  final int? challengeId;
  final int? friendId;
  final String? frequency;
  final int? points;
  // From `data` on ban/unban notifications — used for deep-linking.
  final int? communityId;
  final int? chatId;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    required this.title,
    required this.description,
    required this.isRead,
    required this.createdAt,
    this.avatarUrl,
    this.actorUsername,
    this.actorFirstName,
    this.actorLastName,
    this.challengeId,
    this.friendId,
    this.frequency,
    this.points,
    this.communityId,
    this.chatId,
    required this.icon,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? '') as String;
    // Ban/unban notifications nest ids under `data`; fall back to top-level.
    final data = json['data'] is Map ? json['data'] as Map : const {};
    int? _idFrom(dynamic v) =>
        v == null ? null : int.tryParse('$v');
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      actorId: json['actorId'] ?? 0,
      type: type,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
      actorUsername: json['actorUsername'] as String?,
      actorFirstName: json['actorFirstName'] as String?,
      actorLastName: json['actorLastName'] as String?,
      challengeId: json['challengeId'] != null ? int.tryParse('${json['challengeId']}') : null,
      friendId: json['friendId'] != null ? int.tryParse('${json['friendId']}') : null,
      frequency: json['frequency'] as String?,
      points: json['points'] != null ? int.tryParse('${json['points']}') : null,
      communityId: _idFrom(data['communityId'] ?? json['communityId']),
      chatId: _idFrom(data['chatId'] ?? json['chatId']),
      icon: NotificationModel.iconFromType(type),
    );
  }

  static IconData iconFromType(String type) {
    switch (type) {
      case 'FRIEND_ACCEPTED':
        return Icons.person_add;
      case 'FRIEND_REQUEST':
        return Icons.person;
      case 'MESSAGE':
        return Icons.chat;
      case 'NEW_CHALLENGE':
      case 'DAILY_CHALLENGE':
      case 'WEEKLY_CHALLENGE':
        return Icons.emoji_events;
      case 'COMMUNITY_BANNED':
      case 'GROUP_BANNED':
      case 'COMMUNITY_REMOVED':
      case 'GROUP_REMOVED':
        return Icons.block;
      case 'COMMUNITY_UNBANNED':
      case 'GROUP_UNBANNED':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String timeAgo() {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
