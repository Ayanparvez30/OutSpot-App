class GlobalLeaderboard {
  final WindowInfo? window;
  final List<UserLeaderboard> leaderboard;
  final int? myRank;
  final UserLeaderboard? myInfo;
  final String? prize;

  GlobalLeaderboard({
    this.window,
    required this.leaderboard,
    this.myRank,
    this.myInfo,
    this.prize,
  });

  factory GlobalLeaderboard.fromMap(Map<String, dynamic> map) {
    return GlobalLeaderboard(
      window: map['window'] != null && map['window'] is Map<String, dynamic>
          ? WindowInfo.fromMap(map['window'])
          : null,
      leaderboard: (map['leaderboard'] as List<dynamic>? ?? [])
          .map((e) => UserLeaderboard.fromMap(e))
          .toList(),
      myRank: map['myRank'] != null
          ? int.tryParse(map['myRank'].toString())
          : null,
      myInfo: map['myInfo'] != null && map['myInfo'] is Map<String, dynamic>
          ? UserLeaderboard.fromMap(map['myInfo'])
          : null,
      prize: map['prize']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'window': window?.toMap(),
        'leaderboard': leaderboard.map((e) => e.toMap()).toList(),
        'myRank': myRank,
        'myInfo': myInfo?.toMap(),
        'prize': prize,
      };
}

class WindowInfo {
  final String weekStart;
  final String weekEnd;
  final String label;
  final String remaining;

  WindowInfo({
    required this.weekStart,
    required this.weekEnd,
    required this.label,
    required this.remaining,
  });

  factory WindowInfo.fromMap(Map<String, dynamic> map) {
    return WindowInfo(
      weekStart: (map['weekStart'] ?? '').toString(),
      weekEnd: (map['weekEnd'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      remaining: (map['remaining'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'label': label,
        'remaining': remaining,
      };
}

class UserLeaderboard {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int points;
  final int rank;
  final String prize;

  final String? _fullName;

  UserLeaderboard({
    required this.userId,
    required this.username,
    String? fullName,
    this.firstName = '',
    this.lastName = '',
    this.avatarUrl,
    required this.points,
    required this.rank,
    required this.prize,
  }) : _fullName = fullName;

  String get fullName {
    // Prefer API-provided fullName, then firstName+lastName, then username
    if (_fullName != null && _fullName.trim().isNotEmpty) return _fullName;
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return name.isNotEmpty ? name : username;
  }

  factory UserLeaderboard.fromMap(Map<String, dynamic> m) {
    int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    return UserLeaderboard(
      userId: _toInt(m['userId']),
      username: (m['username'] ?? '').toString(),
      fullName: m['fullName']?.toString(),
      firstName: (m['firstName'] ?? '').toString(),
      lastName: (m['lastName'] ?? '').toString(),
      avatarUrl: (m['avatarUrl']?.toString().isNotEmpty ?? false)
          ? m['avatarUrl'].toString()
          : null,
      points: _toInt(m['points']),
      rank: _toInt(m['rank']),
      prize: (m['prize'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'points': points,
        'rank': rank,
        'prize': prize,
      };
}
