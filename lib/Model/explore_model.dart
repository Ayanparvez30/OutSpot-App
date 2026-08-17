class ExploreCategoryModel {
  final String key;
  final String title;
  final String icon;
  final int newCount;
  final int points;

  ExploreCategoryModel({
    required this.key,
    required this.title,
    required this.icon,
    required this.newCount,
    required this.points,
  });

  factory ExploreCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExploreCategoryModel(
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      icon: json['icon'] ?? '',
      newCount: json['newCount'] ?? 0,
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'icon': icon,
      'newCount': newCount,
      'points': points,
    };
  }
}
