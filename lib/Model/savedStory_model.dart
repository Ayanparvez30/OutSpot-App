class SavedStory {
  final int id;
  final int userId;
  final String mediaUrl;
  final String type;
  final String visibility;
  final String status;
  final DateTime createdAt;

  SavedStory({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.type,
    required this.visibility,
    required this.status,
    required this.createdAt,
  });

  factory SavedStory.fromJson(Map<String, dynamic> json) {
    return SavedStory(
      id: json['id'],
      userId: json['userId'],
      mediaUrl: json['mediaUrl'],
      type: json['type'],
      visibility: json['visibility'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'mediaUrl': mediaUrl,
        'type': type,
        'visibility': visibility,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
