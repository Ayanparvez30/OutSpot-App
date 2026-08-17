class VisitedSpotModel {
  final int id;
  final String? placeId;
  final String placeName;
  final double latitude;
  final double longitude;
  final String? mediaUrl;
  final int points;
  final DateTime createdAt;

  VisitedSpotModel({
    required this.id,
    this.placeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.mediaUrl,
    required this.points,
    required this.createdAt,
  });

  factory VisitedSpotModel.fromJson(Map<String, dynamic> json) {
    return VisitedSpotModel(
      id: json['id'] ?? 0,
      placeId: json['placeId'] as String?,
      placeName: json['placeName'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      mediaUrl: json['mediaUrl'] as String?,
      points: json['points'] ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
