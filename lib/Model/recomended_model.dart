class RecommendedFriend {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String avatarUrl;
  final int totalPoints;
  final int thisWeekPoints;
  final Reason? reason;

  RecommendedFriend({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    required this.avatarUrl,
    required this.totalPoints,
    required this.thisWeekPoints,
    this.reason,
  });

  factory RecommendedFriend.fromJson(Map<String, dynamic> json) {
    // Some endpoints nest the user fields under a `user` object, and the
    // recommended endpoint may use snake_case (first_name) while others use
    // camelCase (firstName). Read defensively so the name always resolves.
    final Map u = (json['user'] is Map) ? json['user'] as Map : json;

    String? pick(String camel, String snake) {
      final v = u[camel] ?? u[snake] ?? json[camel] ?? json[snake];
      final s = v?.toString();
      return (s == null || s.isEmpty) ? null : s;
    }

    return RecommendedFriend(
      id: u['id'] ?? json['id'] ?? 0,
      username: (u['username'] ?? json['username'] ?? '').toString(),
      firstName: pick('firstName', 'first_name'),
      lastName: pick('lastName', 'last_name'),
      avatarUrl:
          (u['avatarUrl'] ?? u['avatar_url'] ?? json['avatarUrl'] ?? '')
              .toString(),
      totalPoints: u['totalPoints'] ?? json['totalPoints'] ?? 0,
      thisWeekPoints: u['thisWeekPoints'] ?? json['thisWeekPoints'] ?? 0,
      reason: json['reason'] != null ? Reason.fromJson(json['reason']) : null,
    );
  }
}

class Reason {
  final String type; // "MUTUAL" or "COMMUNITY"
  final String label;
  final Via? via; // for MUTUAL
  final Community? community; // for COMMUNITY

  Reason({
    required this.type,
    required this.label,
    this.via,
    this.community,
  });

  factory Reason.fromJson(Map<String, dynamic> json) {
    return Reason(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      via: json['via'] != null ? Via.fromJson(json['via']) : null,
      community: json['community'] != null
          ? Community.fromJson(json['community'])
          : null,
    );
  }
}

class Via {
  final int id;
  final String username;
  final String avatarUrl;

  Via({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });

  factory Via.fromJson(Map<String, dynamic> json) {
    return Via(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}

class Community {
  final int id;
  final String name;
  final String imageUrl;

  Community({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
