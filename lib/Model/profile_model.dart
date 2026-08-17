class UserProfileModel {
  final bool status;
  final String message;
  final UserProfileData? data;

  UserProfileModel({required this.status, required this.message, this.data});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data:
          json['data'] != null ? UserProfileData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data?.toJson()};
  }
}

class UserProfileData {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? bodyType;
  final String? bodyShapeUrl;
  final List<dynamic> minime;

  UserProfileData({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.bio,
    this.bodyType,
    this.bodyShapeUrl,
    required this.minime,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      bio: json['bio'],
      bodyType: json['bodyType'],
      bodyShapeUrl: json['bodyShapeUrl'],
      minime: json['minime'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'bodyType': bodyType,
      'bodyShapeUrl': bodyShapeUrl,
      'minime': minime,
    };
  }
}
