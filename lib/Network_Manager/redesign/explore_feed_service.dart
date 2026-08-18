import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/user_preference.dart';

/// Network layer for the redesigned Explore feed.
///
/// Deliberately additive: it calls the endpoints that already exist and are
/// already proven, so the data behind the new design is byte-for-byte what the
/// current screen shows. Nothing here needs a backend change.
///
/// Endpoints used:
/// * `GET /explore/category/:key/places` → `{ places: [...] }`
/// * `GET /restaurants/top-trending/week` → `{ restaurants: [...] }`
/// * `GET /explore/search` → search results
///
/// Sections the design asks for that have no endpoint yet — "Spots Your
/// Friends Visited Recently", "Spots to Boost Your Points" and the Dessert
/// category — are simply absent rather than faked; each returns empty and the
/// carousel hides itself.
class ExploreFeedService {
  static Future<Map<String, String>> _headers() async {
    final token = (await UserPreference.getToken())?.trim();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Anything but 200 is logged and downgraded to an empty section — one dead
  /// carousel must not take the whole feed down with it.
  static List<SpotCardModel> _parse(
    http.Response res,
    String listKey,
    String label, {
    String fallbackCategory = '',
  }) {
    if (res.statusCode != 200) {
      log('❌ Explore feed "$label" → HTTP ${res.statusCode}');
      return const [];
    }
    try {
      final body = jsonDecode(res.body);
      final list = body is Map ? body[listKey] : null;
      if (list is! List) {
        log('⚠️ Explore feed "$label": no "$listKey" array in response');
        return const [];
      }
      return list
          .whereType<Map>()
          .map(
            (e) => SpotCardModel.fromJson(
              Map<String, dynamic>.from(e),
              fallbackCategory: fallbackCategory,
            ),
          )
          .toList();
    } catch (e) {
      log('⚠️ Explore feed "$label" parse error: $e');
      return const [];
    }
  }

  /// "Spots Trending This Week". This is the one endpoint that already returns
  /// `friendsPreview`/`friendsCount`, so cards in this section show the
  /// spotted-here row with real people.
  static Future<List<SpotCardModel>> trendingThisWeek({
    required double lat,
    required double lng,
    int radius = 16093,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/restaurants/top-trending/week'
      '?lat=$lat&lng=$lng&radius=$radius&limit=$limit',
    );
    try {
      final res = await http.get(url, headers: await _headers());
      return _parse(
        res,
        'restaurants',
        'trending',
        fallbackCategory: 'Trending',
      );
    } catch (e) {
      log('❌ Explore feed "trending" failed: $e');
      return const [];
    }
  }

  /// One category carousel — `restaurants`, `cafes`, `bars`, `outdoors`,
  /// `venue-events`. `dessert` is accepted here but the server has no such
  /// category yet, so it comes back empty until that entry is added.
  static Future<List<SpotCardModel>> category({
    required String key,
    required String title,
    required double lat,
    required double lng,
    int radius = 16093,
    int pageSize = 10,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/category/$key/places'
      '?lat=$lat&lng=$lng&radius=$radius&page=1&pageSize=$pageSize',
    );
    try {
      final res = await http.get(url, headers: await _headers());
      return _parse(res, 'places', key, fallbackCategory: title);
    } catch (e) {
      log('❌ Explore feed "$key" failed: $e');
      return const [];
    }
  }

  /// "Spots Your Friends Visited Recently" — friends' check-ins, newest first.
  /// Returns empty for a user with no friends, or none who checked in nearby
  /// inside the window; the carousel then hides itself.
  static Future<List<SpotCardModel>> friendsVisited({
    required double lat,
    required double lng,
    int radius = 16093,
    int limit = 10,
    int days = 30,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/friends-visited'
      '?lat=$lat&lng=$lng&radius=$radius&limit=$limit&days=$days',
    );
    try {
      final res = await http.get(url, headers: await _headers());
      return _parse(
        res,
        'places',
        'friends-visited',
        fallbackCategory: 'Visited',
      );
    } catch (e) {
      log('❌ Explore feed "friends-visited" failed: $e');
      return const [];
    }
  }

  /// "Spots to Boost Your Points" — highest-value nearby places the user has
  /// not checked in at yet.
  static Future<List<SpotCardModel>> pointsBoost({
    required double lat,
    required double lng,
    int radius = 16093,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/points-boost'
      '?lat=$lat&lng=$lng&radius=$radius&limit=$limit',
    );
    try {
      final res = await http.get(url, headers: await _headers());
      return _parse(
        res,
        'places',
        'points-boost',
        fallbackCategory: 'Points Boost',
      );
    } catch (e) {
      log('❌ Explore feed "points-boost" failed: $e');
      return const [];
    }
  }

  /// Bookmark a place. Idempotent server-side — saving twice is a no-op — so
  /// the UI can fire this without first checking what it already saved.
  static Future<bool> savePlace(SpotCardModel spot) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/explore/saved'),
        headers: await _headers(),
        body: jsonEncode({
          'placeId': spot.placeId,
          'placeName': spot.name,
          'latitude': spot.lat,
          'longitude': spot.lng,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      log('❌ savePlace failed: $e');
      return false;
    }
  }

  /// Remove a bookmark. Also idempotent.
  static Future<bool> unsavePlace(String placeId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/explore/saved/$placeId'),
        headers: await _headers(),
      );
      return res.statusCode == 200;
    } catch (e) {
      log('❌ unsavePlace failed: $e');
      return false;
    }
  }

  /// Just the saved place ids, so the feed can fill in bookmark icons without
  /// pulling Google details for every saved spot.
  static Future<Set<String>> savedPlaceIds() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/explore/saved/ids'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) return {};
      final body = jsonDecode(res.body);
      final ids = body is Map ? body['placeIds'] : null;
      if (ids is! List) return {};
      return ids.map((e) => e.toString()).toSet();
    } catch (e) {
      log('❌ savedPlaceIds failed: $e');
      return {};
    }
  }

  /// Full cards for the Saved screen, newest bookmark first.
  static Future<List<SpotCardModel>> savedPlaces({
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/saved?lat=$lat&lng=$lng',
    );
    try {
      final res = await http.get(url, headers: await _headers());
      return _parse(res, 'places', 'saved', fallbackCategory: 'Saved');
    } catch (e) {
      log('❌ savedPlaces failed: $e');
      return const [];
    }
  }

  /// Backs the search field. Mirrors the parameters the current screen sends.
  static Future<List<SpotCardModel>> search({
    required String query,
    required double lat,
    required double lng,
    String category = 'all',
    int radius = 32187,
    int limit = 20,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/search'
      '?q=${Uri.encodeComponent(query)}'
      '&lat=$lat&lng=$lng&radius=$radius&limit=$limit&category=$category',
    );
    try {
      final res = await http.get(url, headers: await _headers());
      // The search endpoint has used both keys across versions; try the
      // documented one first and fall back rather than showing nothing.
      final byPlaces = _parse(res, 'places', 'search');
      if (byPlaces.isNotEmpty) return byPlaces;
      return _parse(res, 'results', 'search');
    } catch (e) {
      log('❌ Explore search failed: $e');
      return const [];
    }
  }
}
