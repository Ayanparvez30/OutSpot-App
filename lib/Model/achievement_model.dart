class Achievement {
  final int totalPoints;
  final String title;

  /// Current tier's point window: [currentMin] .. [currentMax].
  final int currentMin;
  final int currentMax;

  /// Next tier name and the point total at which it unlocks. [nextTitle] is
  /// empty at the top tier.
  final String nextTitle;
  final int nextAt;

  /// Points still needed to reach the next tier (0 at the top tier).
  final int pointsToNext;

  /// Fill fraction (0..1) within the current tier.
  final double progress;

  final List<AchievementTier> tiers;

  const Achievement({
    required this.totalPoints,
    required this.title,
    required this.currentMin,
    required this.currentMax,
    required this.nextTitle,
    required this.nextAt,
    required this.pointsToNext,
    required this.progress,
    required this.tiers,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      totalPoints: (json['totalPoints'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      currentMin: (json['currentMin'] ?? 0) as int,
      currentMax: (json['currentMax'] ?? 0) as int,
      nextTitle: (json['nextTitle'] ?? '') as String,
      nextAt: (json['nextAt'] ?? 0) as int,
      pointsToNext: (json['pointsToNext'] ?? 0) as int,
      progress: (json['progress'] ?? 0.0).toDouble(),
      tiers:
          (json['tiers'] as List?)
              ?.map((t) => AchievementTier.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class AchievementTier {
  final String name;

  /// Total points required to reach this tier.
  final int pointsRequired;

  const AchievementTier({required this.name, required this.pointsRequired});

  factory AchievementTier.fromJson(Map<String, dynamic> json) {
    return AchievementTier(
      name: (json['name'] ?? '') as String,
      pointsRequired: (json['pointsRequired'] ?? 0) as int,
    );
  }
}
