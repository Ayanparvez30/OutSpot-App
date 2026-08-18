import 'dart:convert';
import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Last-good copy of the Explore feed, kept in SharedPreferences.
///
/// Without it every cold start showed nine empty carousels for as long as the
/// Google-backed sections took to answer. With it the feed paints instantly
/// from the previous run and quietly swaps in fresh data when it lands, so the
/// user never stares at a blank screen.
///
/// The location the cache was built at is stored alongside it: a cache from
/// another city is worse than none, so [isNear] decides whether the old cards
/// are still worth showing while the new ones load.
class ExploreFeedCache {
  static const String _key = 'explore_feed_cache_v1';

  /// How far the user can move before the cached feed counts as somewhere else.
  ///
  /// 800m is roughly "still in the same neighbourhood" — near enough that the
  /// same cafés and bars are still the right answer, far enough that crossing
  /// town invalidates it.
  static const double _sameAreaMeters = 800;

  /// Age at which the cache is dropped outright. Opening hours and "Open now"
  /// go stale quickly, so a day-old feed is shown only as a stopgap; anything
  /// older is discarded rather than presented as current.
  static const Duration maxAge = Duration(hours: 24);

  final double lat;
  final double lng;
  final DateTime savedAt;

  /// section key → that carousel's cards.
  final Map<String, List<SpotCardModel>> sections;

  const ExploreFeedCache({
    required this.lat,
    required this.lng,
    required this.savedAt,
    required this.sections,
  });

  bool get isExpired => DateTime.now().difference(savedAt) > maxAge;

  /// True when [toLat]/[toLng] is close enough that these cards still describe
  /// the user's surroundings.
  bool isNear(double toLat, double toLng) =>
      _metersBetween(lat, lng, toLat, toLng) <= _sameAreaMeters;

  /// Distance from the cached position, in metres — handy for logging why a
  /// cache was or wasn't reused.
  double metersFrom(double toLat, double toLng) =>
      _metersBetween(lat, lng, toLat, toLng);

  static Future<void> save({
    required double lat,
    required double lng,
    required Map<String, List<SpotCardModel>> sections,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'lat': lat,
        'lng': lng,
        'savedAt': DateTime.now().toIso8601String(),
        'sections': sections.map(
          (k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()),
        ),
      };
      await prefs.setString(_key, jsonEncode(payload));
    } catch (e) {
      // A cache that fails to write is a missed optimisation, not an error the
      // user should ever see.
      log('⚠️ Explore feed cache save failed: $e');
    }
  }

  /// Returns null when there is no cache, it can't be parsed, or it has aged
  /// past [maxAge].
  static Future<ExploreFeedCache?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final rawSections = decoded['sections'];
      final sections = <String, List<SpotCardModel>>{};
      if (rawSections is Map) {
        rawSections.forEach((k, v) {
          if (v is! List) return;
          sections[k.toString()] =
              v
                  .whereType<Map>()
                  .map(
                    (e) => SpotCardModel.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList();
        });
      }
      if (sections.isEmpty) return null;

      final cache = ExploreFeedCache(
        lat: (decoded['lat'] as num?)?.toDouble() ?? 0,
        lng: (decoded['lng'] as num?)?.toDouble() ?? 0,
        savedAt:
            DateTime.tryParse(decoded['savedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        sections: sections,
      );
      if (cache.isExpired) {
        log('ℹ️ Explore feed cache expired, ignoring');
        return null;
      }
      return cache;
    } catch (e) {
      log('⚠️ Explore feed cache read failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Great-circle distance in metres.
double _metersBetween(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;
