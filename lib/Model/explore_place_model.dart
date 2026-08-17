class ExplorePlaceModel {
  final String placeId;
  final String name;
  final String address;
  final String photoUrl;
  final int points;
  final double distanceMiles;
  final double lat;
  final double lng;
  final double rating;
  final int userRatingsTotal;

  ExplorePlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.photoUrl,
    required this.points,
    required this.distanceMiles,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.userRatingsTotal,
  });

  factory ExplorePlaceModel.fromJson(Map<String, dynamic> json) {
    // Search endpoint can return slightly different field names than
    // category endpoint. Try each alias so both work uniformly.
    String _str(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return '';
    }

    num _num(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num) return v;
        if (v is String) {
          final p = num.tryParse(v);
          if (p != null) return p;
        }
      }
      return 0;
    }

    return ExplorePlaceModel(
      placeId: _str(['placeId', 'place_id', 'id']),
      name: _str(['name', 'title']),
      address: _str(['address', 'formattedAddress', 'vicinity']),
      photoUrl: _str(['photoUrl', 'image', 'imageUrl', 'photo', 'thumbnail']),
      points: _num(['points']).toInt(),
      distanceMiles:
          _num(['distanceMiles', 'distance_miles', 'distance']).toDouble(),
      lat: _num(['lat', 'latitude']).toDouble(),
      lng: _num(['lng', 'longitude', 'lon']).toDouble(),
      rating: _num(['rating']).toDouble(),
      userRatingsTotal:
          _num(['userRatingsTotal', 'user_ratings_total', 'totalReviews'])
              .toInt(),
    );
  }
}
