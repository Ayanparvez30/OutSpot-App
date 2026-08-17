class FriendsModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final int totalPoints;
  final int thisWeekPoints;
  final String profileUrl;
  final String status; // 'ACCEPTED' | 'PENDING_SENT'

  FriendsModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.totalPoints,
    required this.thisWeekPoints,
    required this.profileUrl,
    this.status = 'ACCEPTED',
  });

  bool get isPendingSent => status == 'PENDING_SENT';

  factory FriendsModel.fromJson(Map<String, dynamic> json) {
    return FriendsModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      thisWeekPoints: json['thisWeekPoints'] ?? 0,
      profileUrl: json['profileUrl'] ?? '',
      status: json['status'] ?? 'ACCEPTED',
    );
  }

  String get fullName {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return name.isNotEmpty ? name : username;
  }
}
