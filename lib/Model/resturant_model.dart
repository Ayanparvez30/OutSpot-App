class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String image;
  final List<String> photos; // একাধিক ছবির জন্য
  final String category;
  final String priceRange;
  final String status; // "Open" or "Closed"
  final double rating;
  final int totalReviews;
  final String phone;
  final String website;
  final List<String> openingHours; // weekdayText
  final int points;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.image,
    required this.photos,
    required this.category,
    required this.priceRange,
    required this.status,
    required this.rating,
    required this.totalReviews,
    required this.phone,
    required this.website,
    required this.openingHours,
    required this.points,
  });

  // JSON থেকে মডেলে কনভার্ট করার ফ্যাক্টরি মেথড
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Restaurant',
      address: json['address']?.toString() ?? '',
      lat: (json['lat'] is int) 
          ? (json['lat'] as int).toDouble() 
          : (json['lat'] ?? 0.0),
      lng: (json['lng'] is int) 
          ? (json['lng'] as int).toDouble() 
          : (json['lng'] ?? 0.0),
      image: json['image']?.toString() ?? '',
      photos: json['photos'] != null 
          ? List<String>.from(json['photos']) 
          : [],
      category: json['category']?.toString() ?? '',
      priceRange: json['priceRange']?.toString() ?? '\$10-20', 
      status: json['status']?.toString() ?? 'Closed',
      rating: (json['rating'] is int) 
          ? (json['rating'] as int).toDouble() 
          : (json['rating'] ?? 0.0),
      totalReviews: json['totalReviews'] ?? 0,
      phone: json['phone']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      openingHours: json['openingHours'] != null
          ? List<String>.from(json['openingHours'])
          : (json['weekdayText'] != null
              ? List<String>.from(json['weekdayText'])
              : []),
      points: json['points'] ?? 0,
    );
  }
}

class PaginatedRestaurants {
  final List<RestaurantModel> restaurants;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  PaginatedRestaurants({
    required this.restaurants,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  factory PaginatedRestaurants.empty() => PaginatedRestaurants(
        restaurants: const [],
        page: 1,
        pageSize: 0,
        totalCount: 0,
        hasMore: false,
      );
}