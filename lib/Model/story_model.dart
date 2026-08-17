/// Lightweight community reference attached to a feed story ({id,name,imageUrl}).
class StoryCommunity {
  final int id;
  final String name;
  final String? imageUrl;

  StoryCommunity({required this.id, required this.name, this.imageUrl});

  factory StoryCommunity.fromJson(Map<String, dynamic> json) {
    return StoryCommunity(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class StoryModel {
  final int id;
  final int userId;
  final String mediaUrl;
  final String type;
  final String visibility;
  final String status;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final StoryUser user;

  /// Viewer's relation to this story: friend | friend-and-community |
  /// community-only | "". Drives avatar treatment in the feed rows.
  final String relation;

  /// Communities this story belongs to (for the community-logo overlay).
  final List<StoryCommunity> communities;

  StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.type,
    required this.visibility,
    required this.status,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.user,
    this.relation = '',
    this.communities = const [],
  });

  StoryCommunity? get primaryCommunity =>
      communities.isNotEmpty ? communities.first : null;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      mediaUrl: json['mediaUrl'] ?? '',
      type: json['type'] ?? '',
      visibility: json['visibility'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      latitude:
          (json['latitude'] != null)
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          (json['longitude'] != null)
              ? double.tryParse(json['longitude'].toString())
              : null,
      user: StoryUser.fromJson(json['user'] ?? {}),
      relation: json['relation']?.toString() ?? '',
      communities:
          (json['communities'] as List?)
              ?.whereType<Map>()
              .map((e) => StoryCommunity.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}

class StoryUser {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final double? locationLat;
  final double? locationLng;

  StoryUser({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.locationLat,
    this.locationLng,
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) {
    // avatarUrl priority: direct avatarUrl > minime (latest) > null
    String? avatar = json['avatarUrl'];
    if ((avatar == null || avatar.isEmpty) && json['minime'] is List && (json['minime'] as List).isNotEmpty) {
      final minimeList = json['minime'] as List;
      avatar = minimeList.last['avatarUrl'];
    }
    if (avatar != null && avatar.isEmpty) avatar = null;

    double? lat;
    double? lng;
    if (json['Location'] != null) {
      lat =
          (json['Location']['latitude'] != null)
              ? double.tryParse(json['Location']['latitude'].toString())
              : null;
      lng =
          (json['Location']['longitude'] != null)
              ? double.tryParse(json['Location']['longitude'].toString())
              : null;
    }

    return StoryUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatarUrl: avatar,
      locationLat: lat,
      locationLng: lng,
    );
  }
}
// class StoryModel {
//   final int id;
//   final int userId;
//   final String mediaUrl;
//   final String type;
//   final String visibility;
//   final String status;
//   final DateTime createdAt;
//   final double? latitude;
//   final double? longitude;
//   final StoryUser user;

//   StoryModel({
//     required this.id,
//     required this.userId,
//     required this.mediaUrl,
//     required this.type,
//     required this.visibility,
//     required this.status,
//     required this.createdAt,
//     required this.latitude,
//     required this.longitude,
//     required this.user,
//   });

//   factory StoryModel.fromJson(Map<String, dynamic> json) {
//     return StoryModel(
//       id: json['id'] ?? 0,
//       userId: json['userId'] ?? 0,
//       mediaUrl: json['mediaUrl'] ?? '',
//       type: json['type'] ?? '',
//       visibility: json['visibility'] ?? '',
//       status: json['status'] ?? '',
//       createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
//       latitude: (json['latitude'] != null)
//           ? double.tryParse(json['latitude'].toString())
//           : null,
//       longitude: (json['longitude'] != null)
//           ? double.tryParse(json['longitude'].toString())
//           : null,
//       user: StoryUser.fromJson(json['user'] ?? {}),
//     );
//   }
// }

// class StoryUser {
//   final int id;
//   final String username;
//   final String? firstName;
//   final String? lastName;
//   final String? avatarUrl;
//   final double? locationLat;
//   final double? locationLng;

//   StoryUser({
//     required this.id,
//     required this.username,
//     this.firstName,
//     this.lastName,
//     this.avatarUrl,
//     this.locationLat,
//     this.locationLng,
//   });

//   factory StoryUser.fromJson(Map<String, dynamic> json) {
//     // Extract avatar URL either directly or from minime if available
//     String? avatar = json['avatarUrl'];
//     if (avatar == null && json['minime'] is List && json['minime'].isNotEmpty) {
//       avatar = json['minime'][0]['avatarUrl'];
//     }

//     double? lat;
//     double? lng;
//     if (json['Location'] != null) {
//       lat = (json['Location']['latitude'] != null)
//           ? double.tryParse(json['Location']['latitude'].toString())
//           : null;
//       lng = (json['Location']['longitude'] != null)
//           ? double.tryParse(json['Location']['longitude'].toString())
//           : null;
//     }

//     return StoryUser(
//       id: json['id'] ?? 0,
//       username: json['username'] ?? '',
//       firstName: json['firstName'],
//       lastName: json['lastName'],
//       avatarUrl: avatar,
//       locationLat: lat,
//       locationLng: lng,
//     );
//   }
// }
