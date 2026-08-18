import 'dart:async';
import 'dart:developer' show log;

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_search_and_filters.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Network_Manager/redesign/explore_feed_cache.dart';
import 'package:outspot/Network_Manager/redesign/explore_feed_service.dart';

/// One carousel's worth of state.
class FeedSection {
  final String key;
  final String title;

  /// Category key to hit on the server; empty for sections with no endpoint
  /// yet, which stay empty rather than showing invented data.
  final String categoryKey;

  final RxList<SpotCardModel> spots = <SpotCardModel>[].obs;
  final RxBool loading = false.obs;

  FeedSection({
    required this.key,
    required this.title,
    required this.categoryKey,
  });
}

/// Drives the redesigned Explore feed.
///
/// Kept separate from the existing `ExploreController` on purpose: the old
/// screen keeps running untouched, so the redesign can be switched on or rolled
/// back without disturbing anything the client already signed off on.
class ExploreFeedController extends GetxController {
  /// The nine carousels, in the order the redesign lists them.
  ///
  /// Three have no backend behind them yet and are marked below — they load
  /// empty and hide themselves, which is honest, rather than being filled with
  /// whatever endpoint happens to be nearby.
  late final List<FeedSection> sections = [
    FeedSection(
      key: 'trending',
      title: 'Spots Trending This Week',
      categoryKey: 'trending',
    ),
    FeedSection(
      key: 'friends-visited',
      title: 'Spots Your Friends Visited Recently',
      categoryKey: 'friends-visited',
    ),
    FeedSection(
      key: 'points-boost',
      title: 'Spots to Boost Your Points',
      categoryKey: 'points-boost',
    ),
    FeedSection(
      key: 'restaurants',
      title: 'Restaurants Worth Being Spotted At',
      categoryKey: 'restaurants',
    ),
    FeedSection(key: 'cafes', title: 'Cafés Near You', categoryKey: 'cafes'),
    FeedSection(
      key: 'bars',
      title: 'Bars to Be Spotted At',
      categoryKey: 'bars',
    ),
    FeedSection(
      key: 'dessert',
      title: 'Dessert Spots Worth Your Cravings',
      categoryKey: 'dessert',
    ),
    FeedSection(
      key: 'outdoors',
      title: 'Outdoor Spots to Visit',
      categoryKey: 'outdoors',
    ),
    FeedSection(
      key: 'venue-events',
      title: 'Venue Events Near You',
      categoryKey: 'venue-events',
    ),
  ];

  /// Cards fetched per carousel on the feed. Deliberately small: nine sections
  /// × ten places meant a long wait before anything rendered, and only two or
  /// three cards are ever visible in a row anyway. The heading's arrow opens
  /// the full list.
  static const int previewCount = 3;

  final Rxn<ExploreCategory> selectedCategory = Rxn<ExploreCategory>();
  final RxList<SpotCardModel> searchResults = <SpotCardModel>[].obs;
  final RxBool searching = false.obs;
  final RxString searchQuery = ''.obs;

  final RxBool locating = true.obs;
  final RxString locationError = ''.obs;

  /// True while fresh data is being fetched behind cards that are already on
  /// screen. The feed uses it for a quiet indicator instead of a spinner that
  /// would hide content the user can already read.
  final RxBool refreshingInBackground = false.obs;

  /// Saved place ids. Local-only until a SavedPlace table exists — tapping the
  /// bookmark updates the icon and nothing else, by design.
  final RxSet<String> savedPlaceIds = <String>{}.obs;

  /// Exposed so the search and expanded-category screens can reuse the fix
  /// this controller already resolved instead of asking for GPS again.
  double? get lat => _lat;
  double? get lng => _lng;

  double? _lat;
  double? _lng;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Cold start: paint the previous run's feed first, then bring it up to date.
  ///
  /// The old behaviour — wait for GPS, then wait for nine network calls, then
  /// render — left the screen empty for several seconds every single launch.
  Future<void> _bootstrap() async {
    // 1. Whatever we had last time goes up immediately, before GPS is even
    //    asked for. If it turns out to be from another city step 3 replaces it.
    final cached = await ExploreFeedCache.load();
    if (cached != null) {
      _applyCache(cached);
      locating.value = false; // something is on screen; no full-screen spinner
    } else {
      locating.value = true;
    }

    locationError.value = '';
    try {
      final Position? pos = await LocationHelper.getCurrentPosition();
      if (pos == null) {
        // Cached cards are better than an error screen; only complain when
        // there was nothing to fall back on.
        if (cached == null) locationError.value = 'Location unavailable';
        locating.value = false;
        return;
      }
      _lat = pos.latitude;
      _lng = pos.longitude;
      log('📍 Explore feed location: $_lat, $_lng');
    } catch (e) {
      log('❌ Explore feed location failed: $e');
      if (cached == null) locationError.value = 'Location unavailable';
      locating.value = false;
      return;
    }

    // 2. Moved far enough that the cached cards describe somewhere else? They
    //    stay on screen anyway — an empty feed while the new area loads is
    //    worse than briefly stale distances, and step 3 replaces them section
    //    by section as each one answers. Logged so a wrong-city feed is
    //    traceable rather than mysterious.
    if (cached != null && !cached.isNear(_lat!, _lng!)) {
      log(
        'ℹ️ Explore cache is ${cached.metersFrom(_lat!, _lng!).round()}m away — '
        'showing it while the new area loads',
      );
    }

    locating.value = false;

    // 3. Always revalidate. Cards already showing stay put until their
    //    section's fresh data arrives, so nothing ever blanks out mid-scroll.
    await loadAll(background: cached != null);
  }

  /// Pull-to-refresh. Re-reads GPS, so moving and pulling down picks up the new
  /// area even when the cached one was still valid.
  Future<void> refreshFeed() async {
    final Position? pos = await LocationHelper.getCurrentPosition(
      forceRefresh: true,
    );
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
    }
    await loadAll();
  }

  void _applyCache(ExploreFeedCache cache) {
    for (final s in sections) {
      final cards = cache.sections[s.key];
      if (cards != null && cards.isNotEmpty) s.spots.assignAll(cards);
    }
    log(
      'ℹ️ Explore feed painted from cache '
      '(${DateTime.now().difference(cache.savedAt).inMinutes} min old)',
    );
  }

  /// Sections load concurrently and render as each lands, so the first
  /// carousel appears without waiting on the slowest one.
  /// [background] true when cards are already on screen: the per-section
  /// skeletons are suppressed so the existing cards stay readable while their
  /// replacements load.
  Future<void> loadAll({bool background = false}) async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    if (background) refreshingInBackground.value = true;
    try {
      await Future.wait(
        sections.map((s) => _loadSection(s, lat, lng, background: background)),
      );
      await _persist(lat, lng);
    } finally {
      refreshingInBackground.value = false;
    }
  }

  /// Store only what actually came back — a section that failed keeps its
  /// previous cards rather than caching an empty list over good data.
  Future<void> _persist(double lat, double lng) async {
    final payload = <String, List<SpotCardModel>>{};
    for (final s in sections) {
      if (s.spots.isNotEmpty) payload[s.key] = s.spots.toList();
    }
    if (payload.isEmpty) return;
    await ExploreFeedCache.save(lat: lat, lng: lng, sections: payload);
  }

  Future<void> _loadSection(
    FeedSection s,
    double lat,
    double lng, {
    bool background = false,
  }) async {
    if (s.categoryKey.isEmpty) return; // no endpoint behind it yet
    // Skeletons only when there is nothing to look at yet.
    s.loading.value = !background || s.spots.isEmpty;
    try {
      // Three sections have dedicated endpoints; the rest are plain categories.
      final spots = switch (s.categoryKey) {
        'trending' => await ExploreFeedService.trendingThisWeek(
          lat: lat,
          lng: lng,
          limit: previewCount,
        ),
        'friends-visited' => await ExploreFeedService.friendsVisited(
          lat: lat,
          lng: lng,
          limit: previewCount,
        ),
        'points-boost' => await ExploreFeedService.pointsBoost(
          lat: lat,
          lng: lng,
          limit: previewCount,
        ),
        _ => await ExploreFeedService.category(
          key: s.categoryKey,
          title: s.title,
          lat: lat,
          lng: lng,
          pageSize: previewCount,
        ),
      };
      // An empty response during a background refresh keeps the cached cards:
      // a transient server hiccup shouldn't wipe a section the user is reading.
      if (spots.isNotEmpty || !background) s.spots.assignAll(spots);
    } finally {
      s.loading.value = false;
    }
  }

  /// Sections to render: everything, or just the matching one when a pill is
  /// active. A pill with no backing endpoint yields no section at all.
  List<FeedSection> get visibleSections {
    final sel = selectedCategory.value;
    if (sel == null) return sections;
    return sections.where((s) => s.categoryKey == sel.key).toList();
  }

  void selectCategory(ExploreCategory? c) => selectedCategory.value = c;

  /// Debounced so typing doesn't fire a request per keystroke.
  void onSearchChanged(String q) {
    searchQuery.value = q;
    _searchDebounce?.cancel();
    if (q.trim().isEmpty) {
      searchResults.clear();
      searching.value = false;
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => runSearch(q),
    );
  }

  Future<void> runSearch(String q) async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null || q.trim().isEmpty) return;
    searching.value = true;
    try {
      final res = await ExploreFeedService.search(
        query: q.trim(),
        lat: lat,
        lng: lng,
        category: selectedCategory.value?.key ?? 'all',
      );
      searchResults.assignAll(res);
    } finally {
      searching.value = false;
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchQuery.value = '';
    searchResults.clear();
    searching.value = false;
  }

  /// Design-only for now; see [savedPlaceIds].
  void toggleSaved(SpotCardModel spot) {
    if (savedPlaceIds.contains(spot.placeId)) {
      savedPlaceIds.remove(spot.placeId);
    } else {
      savedPlaceIds.add(spot.placeId);
    }
  }
}
