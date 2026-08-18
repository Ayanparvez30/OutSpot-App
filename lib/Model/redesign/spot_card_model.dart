/// Data behind one Spot Card in the Explore redesign.
///
/// The backend hands out places in two different shapes today and the card has
/// to render both without a translation layer per caller:
///
/// * `/api/explore/category/:key/places` → `placeId`, `photoUrl`, `points`,
///   `userRatingsTotal`
/// * `/api/restaurants/top-trending/week` → `id`, `photos[]`/`image`,
///   `pointsCollected`, `totalReviews`, plus `friendsCount`/`friendsPreview`
///
/// So every field reads from the keys both endpoints might use, and every value
/// is coerced rather than cast — the app's existing convention (see AGENTS.md):
/// assume the backend may send a String where an int is expected, or omit the
/// key entirely, and fall back instead of throwing.
library;

import 'package:outspot/Model/explore_place_model.dart';

class SpotFriend {
  final int id;
  final String username;

  /// First + last name as assembled by the backend; may be blank.
  final String name;
  final String avatar;

  const SpotFriend({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
  });

  /// Round-trips through the feed cache. Deliberately writes the same keys
  /// [SpotFriend.fromJson] reads, so a cached entry parses exactly like a
  /// fresh server response.
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'avatar': avatar,
  };

  /// Preferred label — the real name when set, else the username.
  String get displayName => name.trim().isNotEmpty ? name.trim() : username;

  factory SpotFriend.fromJson(Map<String, dynamic> json) => SpotFriend(
    id: _toInt(json['id']),
    username: _toStr(json['username']),
    name: _toStr(json['name']),
    avatar: _toStr(json['avatar'] ?? json['avatarUrl']),
  );
}

class SpotCardModel {
  final String placeId;
  final String name;
  final String photoUrl;

  /// Street address. Blank on the carousel card, shown on search result rows.
  final String address;

  /// Points awarded for being spotted here.
  final int points;

  final double distanceMiles;

  /// Needed by PlaceDetailsScreen, which takes an [ExplorePlaceModel].
  final double lat;
  final double lng;

  final double rating;
  final int reviewCount;

  /// null when the backend couldn't determine opening hours — the card then
  /// omits the Open/Closed chip rather than guessing "Closed".
  final bool? openNow;

  /// Already formatted by the backend as `$`…`$$$$`; blank when unknown.
  final String priceRange;

  /// Google place types, used to derive the second category tag.
  final List<String> types;

  /// Section label the card was served under ("Trending", "Café", …).
  final String category;

  final int friendsCount;
  final List<SpotFriend> friends;

  /// Wheelchair accessibility. The backend reads Google's
  /// `wheelchair_accessible_entrance` for the place-detail screen but does not
  /// forward it per card yet, so this stays false until that field is exposed —
  /// the icon simply doesn't render.
  final bool accessible;

  const SpotCardModel({
    required this.placeId,
    required this.name,
    required this.photoUrl,
    required this.address,
    required this.points,
    required this.distanceMiles,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    required this.openNow,
    required this.priceRange,
    required this.types,
    required this.category,
    required this.friendsCount,
    required this.friends,
    required this.accessible,
  });

  factory SpotCardModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackCategory = '',
  }) {
    final photos = json['photos'];
    final photo = _toStr(
      json['photoUrl'] ??
          json['image'] ??
          (photos is List && photos.isNotEmpty ? photos.first : ''),
    );

    final rawFriends = json['friendsPreview'];
    final friends =
        rawFriends is List
            ? rawFriends
                .whereType<Map>()
                .map((e) => SpotFriend.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : <SpotFriend>[];

    final rawTypes = json['types'];

    return SpotCardModel(
      placeId: _toStr(json['placeId'] ?? json['id']),
      name: _toStr(json['name']),
      photoUrl: photo,
      address: _toStr(json['address']),
      points: _toInt(json['points'] ?? json['pointsCollected']),
      distanceMiles: _toDouble(json['distanceMiles']),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['userRatingsTotal'] ?? json['totalReviews']),
      openNow: _toBoolOrNull(json['openNow']),
      priceRange: _toStr(json['priceRange']),
      types:
          rawTypes is List
              ? rawTypes.map((e) => e.toString()).toList()
              : const <String>[],
      category: _toStr(json['category']).isNotEmpty
          ? _toStr(json['category'])
          : fallbackCategory,
      // friendsCount can exceed friends.length — the backend previews 3.
      friendsCount: _toInt(json['friendsCount']),
      friends: friends,
      accessible: json['accessible'] == true,
    );
  }

  /// Second tag on the card's first info line, derived from Google's types
  /// ("coffee_shop" → "Coffee Shop"). Blank when nothing usable is present, in
  /// which case the card drops the tag and its separator.
  String get typeLabel {
    const skip = {
      'point_of_interest',
      'establishment',
      'food',
      'store',
      'health',
      'business',
    };
    for (final t in types) {
      if (skip.contains(t)) continue;
      return t
          .split('_')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }
    return '';
  }

  /// Round-trips through the feed cache — see [SpotFriend.toJson].
  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'name': name,
    'photoUrl': photoUrl,
    'address': address,
    'points': points,
    'distanceMiles': distanceMiles,
    'lat': lat,
    'lng': lng,
    'rating': rating,
    'userRatingsTotal': reviewCount,
    'openNow': openNow,
    'priceRange': priceRange,
    'types': types,
    'category': category,
    'friendsCount': friendsCount,
    'friendsPreview': friends.map((f) => f.toJson()).toList(),
    'accessible': accessible,
  };

  /// The shape `PlaceDetailsScreen` expects.
  ///
  /// Every card in the redesign opens that same screen with the same arguments
  /// the old Explore category list used, so check-in, the "Too Far" dialog and
  /// the camera flow behind it keep working untouched.
  ExplorePlaceModel toExplorePlace() => ExplorePlaceModel(
    placeId: placeId,
    name: name,
    address: address,
    photoUrl: photoUrl,
    points: points,
    distanceMiles: distanceMiles,
    lat: lat,
    lng: lng,
    rating: rating,
    userRatingsTotal: reviewCount,
  );

  /// "1,263" — thousands separated, as the review counts read in the design.
  String get reviewCountLabel {
    final s = reviewCount.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// "0.2 mi" — blank when the backend had no location to measure from.
  String get distanceLabel =>
      distanceMiles > 0 ? '${distanceMiles.toStringAsFixed(1)} mi' : '';

  /// "SamR7 and 2 others were spotted here", matching the redesign's copy.
  /// Falls back to the invitation line when nobody has been spotted yet.
  String get friendsLabel {
    if (friends.isEmpty) {
      return 'Be the first of your friends to be spotted here!';
    }
    final first = friends.first.displayName;
    final others = friendsCount - 1;
    if (others <= 0) return '$first was spotted here';
    if (others == 1) return '$first and 1 other were spotted here';
    return '$first and $others others were spotted here';
  }
}

String _toStr(dynamic v) => v == null ? '' : v.toString();

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

bool? _toBoolOrNull(dynamic v) {
  if (v is bool) return v;
  final s = v?.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}
