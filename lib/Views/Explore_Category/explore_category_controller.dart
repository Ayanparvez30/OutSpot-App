import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
import 'package:outspot/Model/explore_place_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';

/// Client-side sort options for the places list. Applied over the currently
/// loaded pages — the backend stays paginated; sorting is done locally (per the
/// decision to not change the backend this round).
enum PlaceSort { none, nearest, farthest, trending, pointsHigh, pointsLow }

class ExploreCategoryController extends GetxController {
  RxList<ExplorePlaceModel> places = <ExplorePlaceModel>[].obs;
  RxString categoryKey = ''.obs;
  RxString categoryTitle = ''.obs;

  // --- Sort / filter (client-side over the loaded pages) ---
  // Default to "Nearest first" for everyone (sorts by backend distanceMiles).
  final Rx<PlaceSort> sortOption = PlaceSort.nearest.obs;

  /// [places] reordered by the active [sortOption]. The UI renders this so the
  /// raw paginated list stays intact for append-on-scroll.
  List<ExplorePlaceModel> get displayedPlaces {
    final list = places.toList();
    switch (sortOption.value) {
      case PlaceSort.nearest:
        list.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        break;
      case PlaceSort.farthest:
        list.sort((a, b) => b.distanceMiles.compareTo(a.distanceMiles));
        break;
      case PlaceSort.trending:
        // Proxy for "trending on Google": most-reviewed first, then top rated.
        list.sort((a, b) {
          final byReviews = b.userRatingsTotal.compareTo(a.userRatingsTotal);
          if (byReviews != 0) return byReviews;
          return b.rating.compareTo(a.rating);
        });
        break;
      case PlaceSort.pointsHigh:
        list.sort((a, b) => b.points.compareTo(a.points));
        break;
      case PlaceSort.pointsLow:
        list.sort((a, b) => a.points.compareTo(b.points));
        break;
      case PlaceSort.none:
        break;
    }
    return list;
  }

  void setSort(PlaceSort option) => sortOption.value = option;

  // --- Server-side pagination (page/pageSize/hasMore) ---
  static const int _pageSize = 20;
  int _currentPage = 1;
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreData = true.obs;

  // --- Search ---
  TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;
  RxBool isSearching = false.obs;
  Timer? _searchDebounce;

  // Location cache
  double? _cachedLat;
  double? _cachedLng;

  double? get userLat => _cachedLat;
  double? get userLng => _cachedLng;

  RxBool isInitialLoading = false.obs;

  ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    categoryKey.value = args['categoryKey'];
    categoryTitle.value = args['categoryTitle'];

    // Trending is returned in Google's own trending order — keep it as-is
    // instead of the default "nearest first" re-sort, otherwise the trending
    // list just becomes "closest places" and loses its whole point.
    if (categoryKey.value == 'trending') {
      sortOption.value = PlaceSort.none;
    }

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        loadMoreData();
      }
    });

    getLocationAndFetchCategories();
  }

  Future<void> getLocationAndFetchCategories() async {
    try {
      isInitialLoading.value = true;

      final Position? position = await LocationHelper.getCurrentPosition();
      if (position != null) {
        _cachedLat = position.latitude;
        _cachedLng = position.longitude;
        log("📍 Current Location: $_cachedLat, $_cachedLng");
        await fetchPlaces(_cachedLat!, _cachedLng!);
      }
    } catch (e) {
      log("❌ Error getting location: $e");
      AppSnackbar.error(e.toString(), title: "Location Error");
    } finally {
      isInitialLoading.value = false;
    }
  }

  Future<void> fetchPlaces(double lat, double lng) async {
    try {
      // Reset pagination on fresh load.
      _currentPage = 1;
      hasMoreData.value = false;

      final response = await ApiService.fetchPlacesByCategory(
        categoryKey: categoryKey.value,
        lat: lat,
        lng: lng,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> placeJson = data['places'] ?? [];
        final fetched =
            placeJson.map((json) => ExplorePlaceModel.fromJson(json)).toList();

        hasMoreData.value = data['hasMore'] == true;

        places.assignAll(fetched);
        log("✅ Fetched: ${fetched.length} places "
            "(page=${data['page']}/${data['totalCount']}, hasMore: ${hasMoreData.value})");
      } else {
        log("❌ Failed to fetch places: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error in fetchPlaces: $e");
    }
  }

  Future<void> loadMoreData() async {
    if (isLoadingMore.value || !hasMoreData.value) return;
    if (_cachedLat == null || _cachedLng == null) return;
    // Don't load more pages during search
    if (searchQuery.value.isNotEmpty) return;

    isLoadingMore.value = true;

    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.fetchPlacesByCategory(
        categoryKey: categoryKey.value,
        lat: _cachedLat!,
        lng: _cachedLng!,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> placeJson = data['places'] ?? [];
        final morePlaces =
            placeJson.map((json) => ExplorePlaceModel.fromJson(json)).toList();

        if (morePlaces.isNotEmpty) {
          _currentPage = nextPage;
          places.addAll(morePlaces);
        }
        hasMoreData.value = data['hasMore'] == true;

        log("✅ Loaded more: ${morePlaces.length} places, total: ${places.length}, "
            "hasMore: ${hasMoreData.value}");
      } else {
        log("❌ Failed to load more: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading more: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  // --- Search Logic (API for >= 2 chars, local filter otherwise) ---
  void onSearchChanged(String query) {
    searchQuery.value = query;
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      // Reset to category data
      isSearching.value = false;
      if (_cachedLat != null && _cachedLng != null) {
        fetchPlaces(_cachedLat!, _cachedLng!);
      }
      return;
    }

    if (query.length < 2) {
      // Local filter on current places
      return;
    }

    // Debounce API search for >= 2 chars
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlacesFromApi(query);
    });
  }

  Future<void> _searchPlacesFromApi(String query) async {
    if (_cachedLat == null || _cachedLng == null) return;

    try {
      isSearching.value = true;
      final response = await ApiService.searchExplorePlaces(
        query: query,
        lat: _cachedLat!,
        lng: _cachedLng!,
        category: categoryKey.value,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> placeJson = data['places'] ?? [];
        final searchResults =
            placeJson.map((json) => ExplorePlaceModel.fromJson(json)).toList();

        log("🔍 Search results: ${searchResults.length} places for '$query'");
        places.assignAll(searchResults);
        hasMoreData.value = false; // No pagination for search results
      } else {
        log("❌ Search failed: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Search error: $e");
    } finally {
      isSearching.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
    EasyLoading.dismiss();
  }
}
