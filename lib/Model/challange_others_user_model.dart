class ParticipantSummary {
  final int userId;
  final String username;
  final String avatarUrl;
  final int uploadedCount;
  final bool completed;
  final int earnedPoints;
  final int weeklyPoints;
  final int totalPoints;
  final Relationship relationship;

  /// Submission/completion time used for the newest↔oldest sort. May be null
  /// if the backend doesn't include a timestamp — callers then fall back to the
  /// API order ([apiIndex]).
  final DateTime? submittedAt;

  /// Position of this item in the raw API response. Used as a stable tiebreaker
  /// and as the time proxy when [submittedAt] is null (assumes the API returns
  /// newest-first, so a lower index == newer). Set by the controller after parse.
  int apiIndex;

  ParticipantSummary({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.uploadedCount,
    required this.completed,
    required this.earnedPoints,
    required this.weeklyPoints,
    required this.totalPoints,
    required this.relationship,
    this.submittedAt,
    this.apiIndex = 0,
  });

  factory ParticipantSummary.fromJson(Map<String, dynamic> json) {
    return ParticipantSummary(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      uploadedCount: json['uploadedCount'] ?? 0,
      completed: json['completed'] ?? false,
      earnedPoints: json['earnedPoints'] ?? 0,
      weeklyPoints: json['weeklyPoints'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      relationship: Relationship.fromJson(json['relationship'] ?? {}),
      submittedAt: _parseDate(
        json['submittedAt'] ??
            json['completedAt'] ??
            json['lastSubmittedAt'] ??
            json['latestSubmissionAt'] ??
            json['createdAt'] ??
            json['updatedAt'],
      ),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is int) {
      // epoch millis (or seconds)
      return DateTime.fromMillisecondsSinceEpoch(v < 1e12 ? v * 1000 : v);
    }
    return DateTime.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'uploadedCount': uploadedCount,
      'completed': completed,
      'earnedPoints': earnedPoints,
      'weeklyPoints': weeklyPoints,
      'totalPoints': totalPoints,
      'relationship': relationship.toJson(),
    };
  }
}

class Relationship {
  final bool isFriend;
  final List<dynamic> sharedCommunities;
  final List<dynamic> sharedGroups;
  final List<dynamic> badges;

  Relationship({
    required this.isFriend,
    required this.sharedCommunities,
    required this.sharedGroups,
    required this.badges,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      isFriend: json['isFriend'] ?? false,
      sharedCommunities: json['sharedCommunities'] ?? [],
      sharedGroups: json['sharedGroups'] ?? [],
      badges: json['badges'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFriend': isFriend,
      'sharedCommunities': sharedCommunities,
      'sharedGroups': sharedGroups,
      'badges': badges,
    };
  }
}
