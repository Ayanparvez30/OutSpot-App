class BlockedUserResponse {
  final bool success;
  final String message;
  final List<BlockedUser> data;

  BlockedUserResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BlockedUserResponse.fromJson(Map<String, dynamic> json) {
    return BlockedUserResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data:
          (json['data'] as List<dynamic>? ?? [])
              .map((x) => BlockedUser.fromJson(x))
              .toList(),
    );
  }
}

class BlockedUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int totalPoints;

  BlockedUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.totalPoints,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? "",
      firstName: json['firstName'] ?? "",
      lastName: json['lastName'] ?? "",
      avatarUrl: json['avatarUrl'],
      totalPoints: json['totalPoints'] ?? 0,
    );
  }
}
