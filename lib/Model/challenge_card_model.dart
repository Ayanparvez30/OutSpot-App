class ChallengeCardModel {
  final int id;
  final String title;
  final String preview;
  final String frequency; 
  final String tier; 
  final int points;
  final int requiredCount;
   int uploadedCount;
  final String status; 
  final int timeRemainingMs;
  final String windowKey; 
  final String zone; 

  ChallengeCardModel({
    required this.id,
    required this.title,
    required this.preview,
    required this.frequency,
    required this.tier,
    required this.points,
    required this.requiredCount,
    required this.uploadedCount,
    required this.status,
    required this.timeRemainingMs,
    required this.windowKey,
    required this.zone,
  });

  factory ChallengeCardModel.fromJson(Map<String, dynamic> json) {
    return ChallengeCardModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      preview: json['preview'] ?? '',
      frequency: json['frequency'] ?? '',
      tier: json['tier'] ?? '',
      points: json['points'] ?? 0,
      requiredCount: json['requiredCount'] ?? 0,
      uploadedCount: json['uploadedCount'] ?? 0,
      status: json['status'] ?? '',
      timeRemainingMs: json['timeRemainingMs'] ?? 0,
      windowKey: json['windowKey'] ?? '',
      zone: json['zone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'preview': preview,
      'frequency': frequency,
      'tier': tier,
      'points': points,
      'requiredCount': requiredCount,
      'uploadedCount': uploadedCount,
      'status': status,
      'timeRemainingMs': timeRemainingMs,
      'windowKey': windowKey,
      'zone': zone,
    };
  }
}
