class PlaceReview {
  final String author;
  final String authorPhoto;
  final int rating;
  final String text;
  final String timeAgo;

  PlaceReview({
    required this.author,
    required this.authorPhoto,
    required this.rating,
    required this.text,
    required this.timeAgo,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      author: json['author'] ?? '',
      authorPhoto: json['authorPhoto'] ?? '',
      rating: json['rating'] ?? 0,
      text: json['text'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
    );
  }
}

class PlaceDetailModel {
  final String placeId;
  final String name;
  final String address;
  final String photoUrl;
  final int points;
  final double? distanceMiles;
  final double lat;
  final double lng;
  final double rating;
  final int userRatingsTotal;
  final String? description;
  final List<String> sections;
  final List<String> cuisine;
  final List<String> services;
  final List<PlaceReview> reviews;
  final String? phone;
  final String? website;
  final String? googleMapsUrl;
  final List<String> photos;
  final List<String> weekdayText;

  /// Friends who have checked in here. Added for the map sheet's "Friends
  /// Spotted" card; the endpoint returns 0/empty when the user has no friends,
  /// so older callers that ignore these fields are unaffected.
  final int friendsCount;
  final List<PlaceFriend> friends;
  final String? priceRange;
  final String? status;

  PlaceDetailModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.photoUrl,
    required this.points,
    this.distanceMiles,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.userRatingsTotal,
    this.description,
    required this.sections,
    required this.cuisine,
    required this.services,
    required this.reviews,
    this.phone,
    this.website,
    this.googleMapsUrl,
    required this.photos,
    required this.weekdayText,
    this.friendsCount = 0,
    this.friends = const [],
    this.priceRange,
    this.status,
  });

  factory PlaceDetailModel.fromJson(Map<String, dynamic> json) {
    final reviewsList = (json['reviews'] as List<dynamic>?)
            ?.map((r) => PlaceReview.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return PlaceDetailModel(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      points: json['points'] ?? 0,
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble(),
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      userRatingsTotal: json['userRatingsTotal'] ?? json['totalReviews'] ?? 0,
      description: json['description'],
      sections: List<String>.from(json['sections'] ?? []),
      cuisine: List<String>.from(json['cuisine'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      reviews: reviewsList,
      phone: json['phone'],
      website: json['website'],
      googleMapsUrl: json['googleMapsUrl'],
      photos: List<String>.from(json['photos'] ?? []),
      weekdayText: List<String>.from(json['weekdayText'] ?? []),
      friendsCount: (json['friendsCount'] as num?)?.toInt() ?? 0,
      friends:
          (json['friendsPreview'] is List)
              ? (json['friendsPreview'] as List)
                  .whereType<Map>()
                  .map((e) => PlaceFriend.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : const [],
      priceRange: json['priceRange'],
      status: json['status'],
    );
  }
}


/// One friend on the map sheet's "Friends Spotted" card.
class PlaceFriend {
  final String name;
  final String avatar;

  const PlaceFriend({required this.name, required this.avatar});

  factory PlaceFriend.fromJson(Map<String, dynamic> json) => PlaceFriend(
    // The backend assembles first+last and falls back to the username.
    name:
        (json['name']?.toString().trim().isNotEmpty ?? false)
            ? json['name'].toString().trim()
            : (json['username']?.toString() ?? ''),
    avatar: json['avatar']?.toString() ?? '',
  );
}
