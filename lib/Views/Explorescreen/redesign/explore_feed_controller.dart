import 'dart:async';
import 'dart:developer' show log;

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_search_and_filters.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
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

  final Rxn<ExploreCategory> selectedCategory = Rxn<ExploreCategory>();
  final RxList<SpotCardModel> searchResults = <SpotCardModel>[].obs;
  final RxBool searching = false.obs;
  final RxString searchQuery = ''.obs;

  final RxBool locating = true.obs;
  final RxString locationError = ''.obs;

  /// Saved place ids. Local-only until a SavedPlace table exists — tapping the
  /// bookmark updates the icon and nothing else, by design.
  final RxSet<String> savedPlaceIds = <String>{}.obs;

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

  Future<void> _bootstrap() async {
    locating.value = true;
    locationError.value = '';
    try {
      final Position? pos = await LocationHelper.getCurrentPosition();
      if (pos == null) {
        locationError.value = 'Location unavailable';
        locating.value = false;
        return;
      }
      _lat = pos.latitude;
      _lng = pos.longitude;
      log('📍 Explore feed location: $_lat, $_lng');
    } catch (e) {
      log('❌ Explore feed location failed: $e');
      locationError.value = 'Location unavailable';
      locating.value = false;
      return;
    }
    locating.value = false;
    await loadAll();
  }

  Future<void> refreshFeed() => _bootstrap();

  /// Sections load concurrently and render as each lands, so the first
  /// carousel appears without waiting on the slowest one.
  Future<void> loadAll() async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    await Future.wait(sections.map((s) => _loadSection(s, lat, lng)));
  }

  Future<void> _loadSection(FeedSection s, double lat, double lng) async {
    if (s.categoryKey.isEmpty) return; // no endpoint behind it yet
    s.loading.value = true;
    try {
      // Three sections have dedicated endpoints; the rest are plain categories.
      final spots = switch (s.categoryKey) {
        'trending' => await ExploreFeedService.trendingThisWeek(
          lat: lat,
          lng: lng,
        ),
        'friends-visited' => await ExploreFeedService.friendsVisited(
          lat: lat,
          lng: lng,
        ),
        'points-boost' => await ExploreFeedService.pointsBoost(
          lat: lat,
          lng: lng,
        ),
        _ => await ExploreFeedService.category(
          key: s.categoryKey,
          title: s.title,
          lat: lat,
          lng: lng,
        ),
      };
      s.spots.assignAll(spots);
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
