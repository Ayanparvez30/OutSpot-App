import 'package:flutter/material.dart';

class FriendModel {
  // ───────── original fields ─────────
  final String name;
  final String image;   // asset path or network URL
  final String score1;  // e.g. 1.2k
  final String score2;  // e.g. 21

  // ───────── new optional fields ─────
  final String label;        // Contact, Mutual Friend, Group, …
  final String extra;        // From contact list, Andrew Smith, …
  final IconData? badgeIcon; // small trailing icon (group / community)

  FriendModel({
    required this.name,
    required this.image,
    required this.score1,
    required this.score2,
    this.label = '',
    this.extra = '',
    this.badgeIcon,
  });

  /// JSON → Model
  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        name:      json['name']    as String,
        image:     json['image']   as String,
        score1:    json['score1']  as String,
        score2:    json['score2']  as String,
        label:     (json['label']  ?? '') as String,
        extra:     (json['extra']  ?? '') as String,
        badgeIcon: _iconFromString(json['badgeIcon']),
      );

  /// Model → JSON   (handy if you need to cache / send back)
  Map<String, dynamic> toJson() => {
        'name'      : name,
        'image'     : image,
        'score1'    : score1,
        'score2'    : score2,
        'label'     : label,
        'extra'     : extra,
        'badgeIcon' : badgeIcon?.codePoint, // store icon codePoint
      };

  // helper: convert the stored value (int or String) back to an IconData
  static IconData? _iconFromString(dynamic v) {
    if (v == null) return null;
    if (v is int) return IconData(v, fontFamily: 'MaterialIcons');
    return null;
  }
}
// class FriendModel {
//   final int id;
//   final String username;
//   final String firstName;
//   final String lastName;
//   final String? avatarUrl;
//   final int totalPoints;
//   final int thisWeekPoints;

//   FriendModel({
//     required this.id,
//     required this.username,
//     required this.firstName,
//     required this.lastName,
//     this.avatarUrl,
//     required this.totalPoints,
//     required this.thisWeekPoints,
//   });

//   factory FriendModel.fromJson(Map<String, dynamic> json) {
//     return FriendModel(
//       id: json['id'],
//       username: json['username'] ?? '',
//       firstName: json['firstName'] ?? '',
//       lastName: json['lastName'] ?? '',
//       avatarUrl: json['avatarUrl'],
//       totalPoints: json['totalPoints'] ?? 0,
//       thisWeekPoints: json['thisWeekPoints'] ?? 0,
//     );
//   }
// }

