class MinimeModel {
  final int id;
  final String? avatarUrl;
  final String? shirt;
  final String? pant;
  final String? shoes;
  final String? glasses;
  final String? lipstick;
  final String? jewelry;
  final String? bag;
  final bool isSaved;
  final bool isDraft;
  final String? createdAt;
  final String? updatedAt;
  final int userId;
  final String? bodyType;

  MinimeModel({
    required this.id,
    this.avatarUrl,
    this.shirt,
    this.pant,
    this.shoes,
    this.glasses,
    this.lipstick,
    this.jewelry,
    this.bag,
    required this.isSaved,
    required this.isDraft,
    this.createdAt,
    this.updatedAt,
    required this.userId,
      this.bodyType,
  });

  factory MinimeModel.fromJson(Map<String, dynamic> json) {
    return MinimeModel(
      id: json['id'],
      avatarUrl: json['avatarUrl'],
      shirt: json['shirt'],
      pant: json['pant'],
      shoes: json['shoes'],
      glasses: json['glasses'],
      lipstick: json['lipstick'],
      jewelry: json['jewelry'],
      bag: json['bag'],
      isSaved: json['isSaved'] ?? false,
      isDraft: json['isDraft'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      userId: json['userId'],
      bodyType: json['bodyType'],
    );
  }
}
