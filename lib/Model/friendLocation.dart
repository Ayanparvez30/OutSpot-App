class FriendLocation {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final int totalPoints;
  final int thisWeekPoints;
  final String profileUrl;
  final double latitude;
  final double longitude;

  FriendLocation({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.totalPoints,
    required this.thisWeekPoints,
    required this.profileUrl,
    required this.latitude,
    required this.longitude,
  });

  // Convert JSON to FriendLocation object with null checks
  factory FriendLocation.fromJson(Map<String, dynamic> json) {
    return FriendLocation(
      userId: json['userId'] ?? 0, // Default to 0 if null
      username: json['username'] ?? 'Unknown', // Default to 'Unknown' if null
      firstName: json['firstName'] ?? 'Unknown', // Default to 'Unknown' if null
      lastName: json['lastName'] ?? 'Unknown', // Default to 'Unknown' if null
      avatarUrl: json['avatarUrl'] ?? '', // Default to empty string if null
      totalPoints: json['totalPoints'] ?? 0, // Default to 0 if null
      thisWeekPoints: json['thisWeekPoints'] ?? 0, // Default to 0 if null
      profileUrl: json['profileUrl'] ?? '', // Default to empty string if null
      latitude: json['latitude'] ?? 0.0, // Default to 0.0 if null
      longitude: json['longitude'] ?? 0.0, // Default to 0.0 if null
    );
  }

  // Convert FriendLocation object to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'thisWeekPoints': thisWeekPoints,
      'profileUrl': profileUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
