import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:outspot/Utils/text_safe.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:outspot/Model/friendLocation.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Model/resturant_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/utils/routes.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/CommonWidgets/MapWidgets/friend_profile_dialog.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:permission_handler/permission_handler.dart';

/// Client-side sort options for the restaurant list. Applied over the currently
/// loaded pages — the backend stays paginated; sorting is done locally.
enum RestaurantSort { none, nearest, farthest, trending, pointsHigh, pointsLow }

class MapController extends GetxController with WidgetsBindingObserver {
  // final ccc = Get.put(MessagesScreenController());
  GoogleMapController? googleMapController;

  StreamSubscription<Position>? _locationSubscription;
  TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;
  RxBool isSearching = false.obs;
  RxString avatarurl = ''.obs;
  final Map<String, Uint8List> _imageCache = {};
  BitmapDescriptor? _myMarkerIcon;
  RxList minimeList = [].obs;
  RxList storiesList = [].obs;
  final RxSet<Marker> storiesMarkers = <Marker>{}.obs;
  bool hasUserTappedMap = false;
  final RxSet<Marker> userMarker = <Marker>{}.obs;
  final Rx<Position?> currentPos = Rx<Position?>(null);
  List<LatLng> polylineCoordinates = [];
  final RxSet<Polyline> routePolyline = <Polyline>{}.obs;
  final RxSet<Circle> walkingDots = <Circle>{}.obs;
  final RxSet<Marker> friendPosition = <Marker>{}.obs;
  final RxSet<Marker> searchMarker = <Marker>{}.obs;
  RxList<FriendLocation> friendsLocation = <FriendLocation>[].obs;
  Position? lastLocation;
  final String googleApiKey = "AIzaSyDtd4M5UM7EOLQc2sA3P0OHn7gN3W53iLs";
  final RxSet<Polyline> navigationPolyline = <Polyline>{}.obs;
  Rx<LatLng?> selectedDestination = Rx<LatLng?>(null);
  RxString currentCityName = "Loading...".obs;
  RxString currentZipCode = "".obs;
  RxString currentTemperature = "77°F".obs;
  RxString currentTime = "".obs;
  RxList<RestaurantModel> allRestaurants = <RestaurantModel>[].obs;
  RxList<RestaurantModel> filteredRestaurants = <RestaurantModel>[].obs;
  final RxSet<Marker> restaurantMarkers = <Marker>{}.obs;
  /// Category keys the map can filter by. Order and wording match the Explore
  /// pills; `dessert` is the one the redesign adds, and the backend now has a
  /// matching bucket for it.
  final List<String> categories = [
    "trending",
    "restaurants",
    "cafes",
    "bars",
    "dessert",
    "outdoors",
    "venue events",
  ];
  RxString selectedCategory = "".obs;
  RxBool showCategoryList = false.obs;
  Rx<RestaurantModel?> selectedRestaurant = Rx<RestaurantModel?>(null);
  RxBool listOpenedFromBottomSheet =
      false.obs; // Track if list was opened from bottom sheet
  Rx<Map<String, dynamic>?> currentRouteInfo = Rx<Map<String, dynamic>?>(null);
  // MapController এর ভেতরে ভেরিয়েবলগুলোর সাথে এটি যোগ করুন:
  RxBool isCategoryLoading = false.obs;

  // Pagination for category restaurants list.
  static const int _restaurantsPageSize = 20;
  int _restaurantsPage = 1;
  String _restaurantsCategoryKey = '';
  final RxBool hasMoreRestaurants = false.obs;
  final RxBool isLoadingMoreRestaurants = false.obs;

  RxBool cameFromTrending = false.obs;
  RxBool cameFromModel = false.obs;
  RxBool cameFromExploreRoute = false.obs;
  // True when the map was opened focused on a specific place (a shared location,
  // a restaurant model, or a route). Suppresses the initial "center on my
  // current location" camera moves so they don't stomp the focused place.
  bool _suppressAutoCenter = false;
  // ১. নতুন ভেরিয়েবল ডিক্লেয়ার করুন
  RxBool isRouteLoading = false.obs;
  RxBool isMapInitLoading = true.obs;
  Map<String, dynamic>? _pendingRouteData;

  void onMapCreated(GoogleMapController controller) {
    googleMapController = controller;
    applyCustomMapStyle();
    // Dismiss the "Loading Map..." overlay once the map widget is ready
    isMapInitLoading.value = false;
    // If a route was pending and map wasn't ready, draw it now
    if (_pendingRouteData != null) {
      _executePendingRoute();
    }
  }

  void _safeAnimateCamera(CameraUpdate update) {
    try {
      googleMapController?.animateCamera(update);
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startClock();
    _initMap();
  }

  Future<void> _initMap() async {
    // Fallback timeout — dismiss loader after 8 seconds no matter what
    Future.delayed(const Duration(seconds: 8), () {
      if (isMapInitLoading.value) {
        log('⏱️ Map init timeout — dismissing loader');
        isMapInitLoading.value = false;
      }
    });

    // Request permission
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      log('⚠️ Location permission not granted — loading map without GPS');
      isMapInitLoading.value = false;
      // Still load other data that doesn't need location
      await Future.wait([
        loadUserProfile(),
        _loadFriendsLocation(),
        fetchStoriesWithLocation(),
        getRedDot(),
      ]);
      return;
    }

    // Show last known position instantly while GPS locks
    Position? lastPos;
    try {
      lastPos = await Geolocator.getLastKnownPosition();
    } catch (e) {
      log('⚠️ getLastKnownPosition error: $e');
    }
    if (lastPos != null) {
      currentPos.value = Position(
        latitude: lastPos.latitude,
        longitude: lastPos.longitude,
        timestamp: lastPos.timestamp,
        accuracy: lastPos.accuracy,
        altitude: lastPos.altitude,
        altitudeAccuracy: lastPos.altitudeAccuracy,
        heading: lastPos.heading,
        headingAccuracy: lastPos.headingAccuracy,
        speed: lastPos.speed,
        speedAccuracy: lastPos.speedAccuracy,
      );
      lastLocation = currentPos.value;
      _safeAnimateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lastPos.latitude, lastPos.longitude),
          16,
        ),
      );
    }

    // Check arguments early so trending data loads immediately
    _checkArguments();

    // Run everything in parallel — any failure is logged but doesn't block UI
    try {
      await Future.wait([
        getPreciseLocation().catchError((e) {
          log('⚠️ getPreciseLocation error: $e');
        }),
        loadUserProfile().catchError((e) {
          log('⚠️ loadUserProfile error: $e');
        }),
        _loadFriendsLocation().catchError((e) {
          log('⚠️ _loadFriendsLocation error: $e');
        }),
        fetchStoriesWithLocation().catchError((e) {
          log('⚠️ fetchStoriesWithLocation error: $e');
        }),
        getRedDot().catchError((e) {
          log('⚠️ getRedDot error: $e');
        }),
      ]);
    } catch (e) {
      log('⚠️ _initMap parallel fetch error: $e');
    }

    // Dismiss loader as soon as core fetches finish
    isMapInitLoading.value = false;

    // Ensure minime marker is set after both position and avatar are ready
    if (currentPos.value != null && avatarurl.value.isNotEmpty) {
      try {
        await _setMarker(currentPos.value!);
      } catch (_) {}
    }

    // Animate to current location in the background (non-blocking)
    _animateToCurrentWhenReady();

    _initLocationStream(skipPermission: true);

    // Check if navigated here with a route destination from explore details
    await _checkPendingRoute();
  }

  Future<void> _animateToCurrentWhenReady() async {
    // Opened focused on a specific place → don't yank the camera to current.
    if (_suppressAutoCenter) return;
    // Wait up to 3 seconds for googleMapController to be assigned by onMapCreated
    for (int i = 0; i < 15; i++) {
      if (googleMapController != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // Re-check after waiting: a focus/route may have been requested meanwhile.
    if (_suppressAutoCenter) return;
    // Best-effort camera animation — don't block on missing data
    if (googleMapController != null && currentPos.value != null) {
      try {
        final pos = currentPos.value!;
        googleMapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(pos.latitude, pos.longitude),
              zoom: 17.0,
              tilt: 50.0,
            ),
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _checkPendingRoute() async {
    try {
      if (!Get.isRegistered<MainscreeenController>()) return;
      final mainCtrl = Get.find<MainscreeenController>();
      final routeTo = mainCtrl.pendingRouteTo;
      if (routeTo == null) return;
      mainCtrl.pendingRouteTo = null;

      final lat = (routeTo['lat'] as num).toDouble();
      final lng = (routeTo['lng'] as num).toDouble();
      if (lat == 0.0 && lng == 0.0) {
        log('❌ Route aborted: invalid coordinates 0,0');
        return;
      }

      // Store for retry in onMapCreated if map isn't ready yet
      _pendingRouteData = routeTo;
      cameFromExploreRoute.value = true;
      // Route framing should win — block any pending auto-recenter.
      _suppressAutoCenter = true;

      if (googleMapController != null && currentPos.value != null) {
        _executePendingRoute();
      } else {
        log('⏳ Map not ready, route will draw when onMapCreated fires');
      }
    } catch (e) {
      log('❌ _checkPendingRoute error: $e');
    }
  }

  void pendingRouteFromExplore(Map<String, dynamic> routeData) {
    _pendingRouteData = routeData;
    cameFromExploreRoute.value = true;
    _suppressAutoCenter = true;
    if (googleMapController != null && currentPos.value != null) {
      _executePendingRoute();
    }
  }

  Future<void> _executePendingRoute() async {
    final routeData = _pendingRouteData;
    if (routeData == null) return;
    _pendingRouteData = null;

    try {
      final lat = (routeData['lat'] as num).toDouble();
      final lng = (routeData['lng'] as num).toDouble();
      final name = routeData['name'] as String? ?? 'Destination';
      final destination = LatLng(lat, lng);

      // Wait for position if not available yet
      for (int i = 0; i < 20; i++) {
        if (currentPos.value != null) break;
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (currentPos.value == null) {
        log('❌ Route failed: position unavailable');
        AppToast.error('Could not get your location');
        return;
      }

      log('📍 Drawing route to explore place: $name ($lat, $lng)');
      addSearchMarker(destination, title: name);
      await drawRouteToDestinationForDifferrent(destination);
    } catch (e) {
      log('❌ _executePendingRoute error: $e');
      AppToast.error('Failed to draw route');
    }
  }

  Future<void> refreshMapData() async {
    _imageCache.clear();
    _myMarkerIcon = null;
    await Future.wait([
      loadUserProfile(),
      _loadFriendsLocation(),
      fetchStoriesWithLocation(),
    ]);
    if (currentPos.value != null && avatarurl.value.isNotEmpty) {
      await _setMarker(currentPos.value!);
    }
  }

  void _checkArguments() {
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('trending')) {
        String cat = args['trending'];
        cameFromTrending.value = true;
        filterRestaurantsByCategory(cat);
      }
      if (args.containsKey('model') && args['model'] is RestaurantModel) {
        final RestaurantModel model = args['model'];
        selectedRestaurant.value = model;
        searchController.text = model.name;
        isSearching.value = true;
        cameFromModel.value = true;
        // Keep the camera on this place — don't auto-recenter to current.
        _suppressAutoCenter = true;
        // Animate camera to the restaurant location
        _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(LatLng(model.lat, model.lng), 16),
        );
      }
      // A location shared into chat — focus & open it on the map.
      if (args.containsKey('sharedLocation') &&
          args['sharedLocation'] is Map) {
        // Keep the camera on the shared place — don't auto-recenter to current.
        _suppressAutoCenter = true;
        _focusSharedLocation(Map<String, dynamic>.from(args['sharedLocation']));
      }
    }
  }

  /// Focus a location shared from chat: wait for the map to be ready, then drop
  /// a marker, animate the camera, and open its place sheet.
  Future<void> _focusSharedLocation(Map<String, dynamic> data) async {
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final name = data['name']?.toString();
    final placeId = data['placeId']?.toString();

    // Wait (up to ~5s) for onMapCreated so the camera actually moves.
    for (int i = 0; i < 25; i++) {
      if (googleMapController != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    addSearchMarker(
      LatLng(lat, lng),
      title: (name != null && name.isNotEmpty) ? name : null,
      placeId: (placeId != null && placeId.isNotEmpty) ? placeId : null,
    );
  }

  // @override
  // void onResume() {
  //   sendLocationToServer();
  //   _loadFriendsLocation();
  // }

  // @override
  // void onPause() {}

  void onMapTapped(LatLng tappedLocation) {
    // Ignore taps while a route is active — only the route should be shown.
    // (Otherwise tapping drops a search marker / triggers a place lookup.)
    if (isRouteActive) return;
    hasUserTappedMap = true;
    addSearchMarker(tappedLocation);
  }

  // আপডেট করা addSearchMarker ফাংশন
  void addSearchMarker(LatLng latLng, {String? title, String? placeId}) async {
    selectedDestination.value = latLng;
    searchMarker.value = {
      Marker(
        markerId: const MarkerId('search'),
        position: latLng,
        infoWindow: InfoWindow(title: title ?? 'Selected location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
      ),
    };

    // Show search appbar with the place name
    if (title != null) {
      searchController.text = title;
      isSearching.value = true;
    }

    _safeAnimateCamera(CameraUpdate.newLatLngZoom(latLng, 16));

    // Fetch place details and show bottom sheet
    if (placeId != null) {
      await _fetchAndShowPlaceSheet(placeId);
    } else if (title != null) {
      // Try to find placeId from text search
      await _searchPlaceIdAndShowSheet(title, latLng);
    }
  }

  Future<void> _fetchAndShowPlaceSheet(String placeId) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=place_id,name,formatted_address,formatted_phone_number,website,geometry,photos,rating,user_ratings_total,opening_hours,business_status,price_level,types&language=en&key=$googleApiKey";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final model = _placeResultToRestaurantModel(result);
          selectedRestaurant.value = model;
        }
      }
    } catch (e) {
      log('Place details fetch error: $e');
    }
  }

  Future<void> _searchPlaceIdAndShowSheet(String query, LatLng latLng) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&radius=100&keyword=$query&language=en&key=$googleApiKey";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final placeId = data['results'][0]['place_id'];
          await _fetchAndShowPlaceSheet(placeId);
        }
      }
    } catch (e) {
      log('Nearby search error: $e');
    }
  }

  RestaurantModel _placeResultToRestaurantModel(Map<String, dynamic> result) {
    final location = result['geometry']?['location'];
    final lat = (location?['lat'] ?? 0.0).toDouble();
    final lng = (location?['lng'] ?? 0.0).toDouble();

    // Build photo URLs
    List<String> photos = [];
    if (result['photos'] != null) {
      for (var photo in result['photos']) {
        final ref = photo['photo_reference'];
        if (ref != null) {
          photos.add(
            "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$ref&key=$googleApiKey",
          );
        }
      }
    }

    // Price range
    final priceLevel = result['price_level'] ?? 1;
    final priceRange = '\$' * priceLevel;

    // Status
    final openNow = result['opening_hours']?['open_now'] ?? false;
    final status = openNow ? 'Open' : 'Closed';

    // Category from types
    final types = List<String>.from(result['types'] ?? []);
    String category = 'establishment';
    for (final t in types) {
      if (t != 'point_of_interest' && t != 'establishment') {
        category = t.replaceAll('_', ' ');
        break;
      }
    }

    return RestaurantModel(
      id: result['place_id'] ?? '',
      name: result['name'] ?? 'Unknown',
      address: result['formatted_address'] ?? '',
      lat: lat,
      lng: lng,
      image: photos.isNotEmpty ? photos.first : '',
      photos: photos,
      category: category,
      priceRange: priceRange.isEmpty ? '\$\$' : priceRange,
      status: status,
      rating: (result['rating'] ?? 0.0).toDouble(),
      totalReviews: result['user_ratings_total'] ?? 0,
      phone: result['formatted_phone_number'] ?? '',
      website: result['website'] ?? '',
      openingHours:
          result['opening_hours']?['weekday_text'] != null
              ? List<String>.from(result['opening_hours']['weekday_text'])
              : [],
      points: 0,
    );
  }

  void _initLocationStream({bool skipPermission = false}) async {
    if (!skipPermission) {
      PermissionStatus status = await Permission.location.request();
      if (!status.isGranted) return;
    }

    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (lastLocation == null) {
        _handleNewLocation(pos);
      } else {
        double distance = Geolocator.distanceBetween(
          lastLocation!.latitude,
          lastLocation!.longitude,
          pos.latitude,
          pos.longitude,
        );

        if (distance > 10) {
          _handleNewLocation(pos);
        }
      }
    });
  }

  void _handleNewLocation(Position pos) {
    currentPos.value = pos;
    _addPolylinePoint(pos);
    _setMarker(pos);
    sendLocationToServer();
    _checkAndReloadFriendMarkers();

    // Don't re-centre the camera on the user while a route is active. Otherwise
    // every location update fights the route's fit-to-bounds zoom, snapping the
    // map back onto the user and forcing them to keep zooming out to see the
    // whole route. During a route the camera stays where fitBounds put it.
    if (currentRouteInfo.value == null) {
      _safeAnimateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    }
  }

  // void _initLocationStream() async {
  //   PermissionStatus status = await Permission.location.request();
  //   if (!status.isGranted) {
  //     // Get.snackbar("Permission", "Location permission denied");
  //     return;
  //   }
  //   Geolocator.getPositionStream(
  //     locationSettings: const LocationSettings(
  //       accuracy: LocationAccuracy.best,
  //       distanceFilter: 5,
  //     ),
  //   ).listen((pos) {
  //     currentPos.value = pos;
  //     _updateMarker(pos);
  //     sendLocationToServer();
  //   });
  // }

  void _addPolylinePoint(Position pos) {
    final newPoint = LatLng(pos.latitude, pos.longitude);
    polylineCoordinates.add(newPoint);
    lastLocation = pos;
    _updatePolyline();
  }

  void _updatePolyline() {
    routePolyline.value = {
      Polyline(
        polylineId: const PolylineId("walking_history"),
        points: List<LatLng>.from(polylineCoordinates),
        color: Colors.redAccent,
        width: 5,
        jointType: JointType.round,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
      ...navigationPolyline,
    };
  }

  void _startClock() {
    // প্রতি সেকেন্ডে সময় আপডেট হবে
    Stream.periodic(const Duration(seconds: 1), (i) {
      final now = DateTime.now();
      // 12-hour format logic (e.g., 9:41 PM)
      String period = now.hour >= 12 ? 'PM' : 'AM';
      int hour = now.hour > 12 ? now.hour - 12 : now.hour;
      hour = hour == 0 ? 12 : hour;
      String minute = now.minute.toString().padLeft(2, '0');
      currentTime.value = "$hour:$minute $period";
    }).listen((event) {});
  }

  // 3. লোকেশন থেকে সিটি এবং জিপ কোড বের করা (আপনার initCurrentLocation এর ভেতরে এটি কল হবে)
  Future<void> _getAddressAndWeather(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentCityName.value = place.locality ?? "Unknown";
        currentZipCode.value = place.postalCode ?? "";

        // লোকেশন পাওয়ার পর ওয়েদার কল করুন
        _fetchWeather(lat, lng);
      }
    } catch (e) {
      log("Address error: $e");
    }
  }

  // 4. ওয়েদার এপিআই (OpenWeatherMap)
  Future<void> _fetchWeather(double lat, double lng) async {
    String apiKey = "6ec3b483a74b7b288541d9cca6debbdb";
    String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$apiKey&units=imperial";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        double temp = data['main']['temp'];
        currentTemperature.value = "${temp.toStringAsFixed(0)}°F";
      }
    } catch (e) {
      log("Weather fetch error: $e");
    }
  }

  Future<void> drawRouteToDestination(LatLng destination) async {
    if (currentPos.value == null) return;
    // Clear all other map UI (categories, search, restaurant list/markers) so
    // only the route is shown, then draw the walking route.
    _enterRouteMode(destination);
    await drawRouteToDestinationForDifferrent(destination, mode: 'walking');
  }

  /// Resets category/search state so the map shows only the active route.
  void _enterRouteMode(LatLng destination) {
    selectedDestination.value = destination;
    isSearching.value = false;
    searchController.clear();
    selectedCategory.value = '';
    allRestaurants.clear();
    filteredRestaurants.clear();
    restaurantMarkers.clear();
    searchMarker.clear();
    selectedRestaurant.value = null;
    showCategoryList.value = false;
    listOpenedFromBottomSheet.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// True while a navigation route is being displayed.
  bool get isRouteActive => navigationPolyline.isNotEmpty;

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty || googleMapController == null) return;

    double minLat = points.first.latitude;
    double minLong = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLong = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLong) minLong = point.longitude;
      if (point.longitude > maxLong) maxLong = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLong),
      northeast: LatLng(maxLat, maxLong),
    );

    // `newLatLngBounds` silently no-ops if the map isn't laid out yet or while
    // it races other camera moves — that's why the route opened zoomed-in and
    // needed a manual pinch-out. Run it after a short delay and retry a couple
    // of times so the whole route reliably fits on screen.
    Future<void> animate([int attempt = 0]) async {
      try {
        await googleMapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 70),
        );
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 300));
          await animate(attempt + 1);
        }
      }
    }

    Future.delayed(const Duration(milliseconds: 350), () => animate());
  }

  Future<void> _setMarker(Position pos) async {
    if (avatarurl.value.isEmpty) return;
    try {
      _myMarkerIcon ??= await getCustomMarker(avatarurl.value);
      userMarker.value = {
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(pos.latitude, pos.longitude),
          // No infoWindow — the native white name bubble lingered on the map
          // after the profile popup was dismissed.
          icon: _myMarkerIcon!,
          onTap: () => Get.toNamed(Routes.myProfile),
        ),
      };
      userMarker.refresh();
      log('✅ Minime marker set at ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      log('❌ _setMarker error: $e');
    }
  }

  Future<void> sendLocationToServer() async {
    if (currentPos.value != null) {
      Map<String, dynamic> locationData = {
        "latitude": currentPos.value!.latitude,
        "longitude": currentPos.value!.longitude,
      };
      final respons = await ApiService.updateLocation(locationData);
      if (respons.statusCode == 200) {
        // Get.snackbar("Success", "Location updated");
        log("Location Update successfully");
        log("${currentPos.value!.latitude}");
        log("${currentPos.value!.longitude}");
      } else {
        // Get.snackbar("Error", "Failed to update location");
        log("error to update location");
      }
    }
  }

  // Threshold constants for smart friend loading
  static const int _friendThreshold = 100; // apply radius filter above this
  static const double _radiusMeters = 48280; // 30 miles
  static const int _maxMarkers = 100;
  static const double _reloadDistanceMeters =
      1609; // ~1 mile — reload markers when user moves this far
  LatLng? _lastMarkerLoadCenter; // track where markers were last loaded from

  /// Public hook to reload friend markers while the map is already open
  /// (e.g. when a FRIEND_ACCEPTED notification arrives).
  Future<void> refreshFriendsLocation() => _loadFriendsLocation();

  /// Instantly remove an unfriended user's marker from the map. Safe to call
  /// from any screen — it's a no-op if that friend isn't currently shown, so it
  /// never touches the network or risks a race with _loadFriendsLocation.
  void removeFriendFromMap(int friendId) {
    friendsLocation.removeWhere((f) => f.userId == friendId);
    friendPosition.removeWhere((m) => m.markerId.value == friendId.toString());
  }

  Future<void> _loadFriendsLocation() async {
    try {
      List<FriendLocation> locations = await ApiService.fetchFriendsLocation();
      friendsLocation.assignAll(locations);

      final List<FriendLocation> displayFriends;

      if (locations.length <= _friendThreshold) {
        // Small friend list — show ALL, no radius filter
        displayFriends = locations;
      } else if (currentPos.value != null) {
        // Large friend list — filter by 30-mile radius, sort nearest first, cap at 100
        final lat = currentPos.value!.latitude;
        final lng = currentPos.value!.longitude;

        final withDistance =
            locations
                .map((friend) {
                  final d = Geolocator.distanceBetween(
                    lat,
                    lng,
                    friend.latitude,
                    friend.longitude,
                  );
                  return (friend: friend, distance: d);
                })
                .where((e) => e.distance <= _radiusMeters)
                .toList();

        // Sort by distance so closest friends always get priority
        withDistance.sort((a, b) => a.distance.compareTo(b.distance));
        displayFriends =
            withDistance.take(_maxMarkers).map((e) => e.friend).toList();

        // Remember where we loaded from so we can reload on significant move
        _lastMarkerLoadCenter = LatLng(lat, lng);
      } else {
        // No location yet — just cap at max
        displayFriends = locations.take(_maxMarkers).toList();
      }

      // Load marker images in batches of 5
      friendPosition.clear();
      const batchSize = 5;
      for (var i = 0; i < displayFriends.length; i += batchSize) {
        final batch = displayFriends.skip(i).take(batchSize);
        final futures = batch.map((friend) async {
          try {
            if (friend.avatarUrl.isEmpty) return;
            final customIcon = await getCustomMarker(friend.avatarUrl);
            friendPosition.add(
              Marker(
                markerId: MarkerId(friend.userId.toString()),
                position: LatLng(friend.latitude, friend.longitude),
                // No infoWindow — tapping opens the profile card; the native
                // white name bubble used to stay stuck after it was dismissed.
                icon: customIcon,
                onTap: () {
                  _onFriendMarkerTapped(friend);
                },
              ),
            );
          } catch (e) {
            log('Error loading marker for ${friend.username}: $e');
          }
        });
        await Future.wait(futures);
        // UI থ্রেড ব্লক হওয়া ঠেকাতে এবং মেমোরি ক্র্যাশ এড়াতে ছোট্ট ডিল্যে
        await Future.delayed(const Duration(milliseconds: 15));
      }

      log(
        "Friends loaded on map: ${displayFriends.length} / ${locations.length} total",
      );
    } catch (e) {
      log('error to load friend locations $e');
    }
  }

  /// Call this when user location updates significantly to reload nearby markers
  void _checkAndReloadFriendMarkers() {
    if (currentPos.value == null) return;
    // Only apply reload logic for large friend lists
    if (friendsLocation.length <= _friendThreshold) return;

    final current = LatLng(
      currentPos.value!.latitude,
      currentPos.value!.longitude,
    );
    if (_lastMarkerLoadCenter == null) {
      _loadFriendsLocation();
      return;
    }

    final moved = Geolocator.distanceBetween(
      _lastMarkerLoadCenter!.latitude,
      _lastMarkerLoadCenter!.longitude,
      current.latitude,
      current.longitude,
    );

    if (moved >= _reloadDistanceMeters) {
      log(
        '📍 User moved ${moved.toStringAsFixed(0)}m — reloading nearby friend markers',
      );
      _loadFriendsLocation();
    }
  }

  void navigateToFriend(FriendLocation friend) {
    _safeAnimateCamera(
      CameraUpdate.newLatLngZoom(LatLng(friend.latitude, friend.longitude), 16),
    );
    _onFriendMarkerTapped(friend);
    // drawRouteToDestination(LatLng(friend.latitude, friend.longitude));
  }

  Future<void> searchAndNavigate(String query) async {
    if (query.trim().isEmpty) return;

    List<FriendLocation> matchedFriends =
        friendsLocation.where((friend) {
          return friend.firstName.toLowerCase().contains(query.toLowerCase()) ||
              friend.lastName.toLowerCase().contains(query.toLowerCase()) ||
              friend.username.toLowerCase().contains(query.toLowerCase());
        }).toList();

    if (matchedFriends.isNotEmpty) {
      if (matchedFriends.length == 1) {
        final friend = matchedFriends.first;
        _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(friend.latitude, friend.longitude),
            16,
          ),
        );
        _onFriendMarkerTapped(friend);
        drawRouteToDestination(LatLng(friend.latitude, friend.longitude));
      } else {
        showModalBottomSheet(
          context: Get.context!,
          backgroundColor: Color(0xff2D0731),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return ListView.builder(
              itemCount: matchedFriends.length,
              itemBuilder: (context, index) {
                final friend = matchedFriends[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: friend.avatarUrl,
                        alignment: Alignment.topCenter,
                        width: 40.w,
                        height: 30.h,
                        fit: BoxFit.cover,

                        placeholder:
                            (context, url) => const ShimmerPlaceholder(),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(
                    "${friend.firstName} ${friend.lastName}",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "@${friend.username}",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _safeAnimateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(friend.latitude, friend.longitude),
                        16,
                      ),
                    );
                    _onFriendMarkerTapped(friend);
                  },
                );
              },
            );
          },
        );
      }
    } else {
      // Use Google Places API for better accuracy with location bias
      try {
        String locationBias = '';
        if (currentPos.value != null) {
          locationBias =
              '&location=${currentPos.value!.latitude},${currentPos.value!.longitude}&radius=50000';
        }
        final url =
            "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$query&inputtype=textquery&fields=geometry,name,formatted_address&language=en$locationBias&key=$googleApiKey";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              (data['candidates'] as List).isNotEmpty) {
            final location = data['candidates'][0]['geometry']['location'];
            final name = data['candidates'][0]['name'] ?? query;
            addSearchMarker(
              LatLng(location['lat'], location['lng']),
              title: name,
            );
            return;
          }
        }
        // Fallback to geocoding
        final locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          addSearchMarker(LatLng(loc.latitude, loc.longitude), title: query);
        } else {
          AppToast.error("Could not find this location");
        }
      } catch (e) {
        log("Search error: $e");
        AppToast.error("Could not find this location");
      }
    }
  }

  Future<void> fetchStoriesWithLocation() async {
    try {
      final response = await ApiService.fetchStory();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body); // ✅
        // List stories = data["stories"];
        List stories =
            ((data["stories"] as List?) ?? const <dynamic>[])
                .where((item) {
                  final s = (item is Map) ? item : null;
                  if (s == null) return false;
                  final type = (s["type"] ?? "").toString().toUpperCase();
                  return type == "IMAGE";
                })
                .take(20)
                .toList();

        storiesList.value =
            stories
                .map(
                  (story) => {
                    "id": story["id"],
                    "username": story["user"]["username"],
                    "avatarUrl": story["user"]["avatarUrl"],
                    "mediaUrl": story["mediaUrl"],
                    "latitude": story["latitude"],
                    "longitude": story["longitude"],
                  },
                )
                .toList();

        _updateStoryMarkers(stories);
        log("Stories with location fetched: ${storiesList.length}");
        // Get.snackbar("Sucess", "Stories get successfully");
      } else {
        // Get.snackbar("Error", "Failed to load stories");
        log("Server error: ${response.statusCode}");
      }
    } catch (e) {
      // Get.snackbar("Error", "Something went wrong while fetching stories");
      log("Error: $e");
    }
  }

  Future<void> _updateStoryMarkers(List stories) async {
    storiesMarkers.clear();

    // Cluster stories by user AND proximity — one marker per PLACE a person
    // storied. Each post captures the GPS at that moment, so the same spot
    // drifts a few metres between posts: those collapse into one bubble. But
    // stories from genuinely DIFFERENT places stay as separate markers, so a
    // user who storied at two locations still shows two bubbles.
    const double sameSpotMeters = 80;
    final Map<String, List<List<Map>>> perUser = {};
    for (final s in stories) {
      if (s is! Map) continue;
      if (s['latitude'] == null || s['longitude'] == null) continue;
      final u = (s['user'] as Map?) ?? const {};
      final key = (u['id'] ?? u['username'] ?? s['id']).toString();
      final double lat = (s['latitude'] as num).toDouble();
      final double lng = (s['longitude'] as num).toDouble();

      final clusters = perUser[key] ??= <List<Map>>[];
      // Find an existing nearby cluster for this user; else start a new one.
      List<Map>? target;
      for (final c in clusters) {
        final rep = c.first;
        final d = Geolocator.distanceBetween(
          (rep['latitude'] as num).toDouble(),
          (rep['longitude'] as num).toDouble(),
          lat,
          lng,
        );
        if (d <= sameSpotMeters) {
          target = c;
          break;
        }
      }
      if (target == null) {
        clusters.add(<Map>[s]);
      } else {
        target.add(s);
      }
    }
    // Flatten every user's clusters into one list — one entry per marker.
    final groups = perUser.values.expand((e) => e).toList();

    // Process in batches of 5 to avoid overwhelming the device
    const batchSize = 5;
    for (var i = 0; i < groups.length; i += batchSize) {
      final batch = groups.skip(i).take(batchSize);
      final futures = batch.map((group) async {
        try {
          // Representative = the person's most recent story (last in feed
          // order); its location + image drive the single marker.
          final story = group.last;
          final double latitude = (story['latitude'] as num).toDouble();
          final double longitude = (story['longitude'] as num).toDouble();
          final user = (story['user'] as Map?) ?? const {};
          final String firstName = (user['firstName'] ?? '').toString().trim();
          final String lastName = (user['lastName'] ?? '').toString().trim();
          final String fullName = '$firstName $lastName'.trim();
          // Show the person's name, not the @username, under the circle.
          final String displayName =
              fullName.isNotEmpty
                  ? fullName
                  : (user['username'] ?? '').toString();
          String imageUrl = story['mediaUrl'];

          final imageBytes = await _fetchImageBytes(imageUrl);

          // Label the marker with the person's NAME. We deliberately do NOT
          // geocode/show the story's address anymore — where someone storied
          // should not be revealed on the map.
          final markerImage = await createMarkerWithText(
            imageBytes: imageBytes,
            label: displayName.truncateSafe(14),
          );
          final customIcon = BitmapDescriptor.fromBytes(markerImage);

          final String sid = story['id'].toString();

          // One marker per user: tapping opens ALL of this person's stories.
          final List<StoryModel> tappedStories =
              group
                  .map(
                    (e) => StoryModel.fromJson(e.cast<String, dynamic>()),
                  )
                  .toList();

          storiesMarkers.add(
            Marker(
              markerId: MarkerId(sid),
              position: LatLng(latitude, longitude),
              // No infoWindow — the native white bubble showed the name + full
              // address; the name is already under the circle and the address
              // is intentionally hidden.
              icon: customIcon,
              // Draw stories ABOVE avatar/friend markers so they're never
              // hidden behind a mini-me.
              zIndexInt: 2,
              onTap: () => _openStoryFromMap(tappedStories, 0),
            ),
          );
        } catch (e) {
          log('Error loading story marker: $e');
        }
      });
      await Future.wait(futures);
      // UI থ্রেড ব্লক হওয়া ঠেকাতে ছোট্ট ডিল্যে
      await Future.delayed(const Duration(milliseconds: 15));
    }
  }

  /// Remove a deleted story from the map in real time (no re-fetch) so its
  /// marker disappears immediately — mirrors Explore's [removeStoryLocally].
  void removeStoryLocally(int storyId) {
    final String sid = storyId.toString();
    storiesMarkers.removeWhere((m) => m.markerId.value == sid);
    storiesList.removeWhere((s) => (s is Map ? s['id'] : s).toString() == sid);
    storiesMarkers.refresh();
  }

  /// Open the full-screen story viewer for a story tapped on the map — mirrors
  /// the Explore page flow so seen/state handling is identical.
  void _openStoryFromMap(List<StoryModel> stories, int startIndex) {
    if (stories.isEmpty) return;
    // currentUserId is omitted — the story viewer resolves it itself (from args
    // or the locally cached id), so "isMyStory" still works correctly.
    Get.toNamed(
      Routes.postscreen,
      arguments: {"stories": stories, "startIndex": startIndex},
    );
  }


  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];
        minimeList.value = data["minime"] ?? '';
        final newAvatar = minimeList.last['avatarUrl'] ?? '';
        if (newAvatar != avatarurl.value) {
          _myMarkerIcon = null; // avatar changed, rebuild icon
        }
        avatarurl.value = newAvatar;
        log("my mini me: ${avatarurl.value}");
        // Re-create marker now that avatar is available
        if (avatarurl.value.isNotEmpty && currentPos.value != null) {
          await _setMarker(currentPos.value!);
        }
      } else {
        log("❌ Server error: ${response.statusCode}");
        // Get.snackbar(
        //   "Error",
        //   "Server returned ${response.statusCode}",
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        // );
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
      // Get.snackbar(
      //   "Error",
      //   "Something went wrong. Please try again.",
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      //   snackPosition: SnackPosition.TOP,
      // );
    }
  }

  void _onFriendMarkerTapped(FriendLocation friend) {
    selectedDestination.value = LatLng(friend.latitude, friend.longitude);
    // Slide the friend card up from the bottom (not a centered pop-in).
    showGeneralDialog(
      context: Get.context!,
      barrierDismissible: true,
      barrierLabel: 'friend',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => FriendProfileDialog(friend: friend),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  Future<Uint8List> _fetchImageBytes(String imageUrl) async {
    if (_imageCache.containsKey(imageUrl)) return _imageCache[imageUrl]!;
    final response = await http.get(Uri.parse(imageUrl));
    _imageCache[imageUrl] = response.bodyBytes;
    return response.bodyBytes;
  }

  Future<BitmapDescriptor> getCustomMarker(String imageUrl) async {
    final bytes = await _fetchImageBytes(imageUrl);

    // Avatar PNGs are full-body characters on a large mostly-transparent canvas.
    // If used as-is, the marker's TAP area is the whole canvas — so tapping the
    // empty space beside an avatar still hits it, and overlapping avatars/story
    // markers swallow each other's taps. Trim the transparent margins so the tap
    // area matches the visible avatar.
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final trimmed = img.trim(decoded, mode: img.TrimMode.transparent);
        final resized = img.copyResize(trimmed, width: 130);
        final png = img.encodePng(resized);
        return BitmapDescriptor.fromBytes(Uint8List.fromList(png));
      }
    } catch (_) {
      // fall through to the original (untrimmed) path
    }

    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 200);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> getCustomMarkerForStories(
    String imageUrl,
    String label,
  ) async {
    final bytes = await _fetchImageBytes(imageUrl);
    final markerImage = await createMarkerWithText(
      imageBytes: bytes,
      label: label,
    );
    return BitmapDescriptor.fromBytes(markerImage);
  }

  Future<Uint8List> createMarkerWithText({
    required Uint8List imageBytes,
    required String label,
  }) async {
    // Smaller than the avatar markers so story circles don't cover them and
    // steal taps meant for the avatar.
    const double width = 100;
    const double height = 120;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(Offset(0, 0), Offset(width, height)),
    );

    final center = Offset(width / 2, 46);
    final radius = 34.0;

    // Draw circle border
    final paintBorder =
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
    canvas.drawCircle(center, radius + 3, paintBorder);

    // Load image
    final image = await decodeImageFromList(imageBytes);

    // Create circular path
    final Path clipPath =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    // Draw image inside circular area
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromCircle(center: center, radius: radius);
    canvas.drawImageRect(image, src, dst, Paint());
    canvas.restore();
    final double fontSize = 15.sp;
    final outlineStyle = GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      foreground:
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = Colors.white,
    );

    final outlinePainter = TextPainter(
      text: TextSpan(text: label, style: outlineStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    outlinePainter.layout(maxWidth: width);
    final double textX = (width - outlinePainter.width) / 2;
    final double textY = 88;
    outlinePainter.paint(canvas, Offset(textX, textY));
    final fillStyle = GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.redAccent,
    );
    final fillPainter = TextPainter(
      text: TextSpan(text: label, style: fillStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    fillPainter.layout(maxWidth: width);
    fillPainter.paint(canvas, Offset(textX, textY));
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> applyCustomMapStyle() async {
    if (googleMapController == null) return;
    final style = await DefaultAssetBundle.of(
      Get.context!,
    ).loadString('assets/Images/map_style.json');
    googleMapController!.setMapStyle(style);
  }

  Future<void> getPreciseLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPos.value = position;
      _setMarker(position);
      lastLocation = position;
      // Don't recenter to current when the map was opened on a specific place.
      if (!_suppressAutoCenter) {
        _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
        );
      }
      // _getAddressAndWeather already calls _fetchWeather inside
      _getAddressAndWeather(position.latitude, position.longitude);
    } catch (e) {
      log("Error fetching current location: $e");
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _locationSubscription = null;
    googleMapController?.dispose();
    googleMapController = null;
    super.onClose();
  }

  final _badgeService = Get.find<NotificationBadgeService>();
  RxBool get notificationRedDot => _badgeService.notificationRedDot;
  Future<void> getRedDot() => _badgeService.getRedDot();
  Future<void> clearNotificationDot() => _badgeService.clearNotificationDot();

  // void filterRestaurantsByCategory(String categoryTitle) async {
  //   selectedCategory.value = categoryTitle;
  //   searchController.text = categoryTitle;
  //   isSearching.value = true;

  //   selectedRestaurant.value = null;
  //   showCategoryList.value = true;
  //   String categoryKey = categoryTitle.toLowerCase().replaceAll(' ', '-');

  //   if (currentPos.value == null) return;
  //   try {
  //     EasyLoading.show(status: 'Loading $categoryTitle...');
  //     List<RestaurantModel> restaurants = await ApiService.fetchRestaurants(
  //       categoryKey: categoryKey,
  //       lat: currentPos.value!.latitude,
  //       lng: currentPos.value!.longitude,
  //     );

  //     log("Restaurants fetched for $categoryTitle: ${restaurants.length}");
  //     allRestaurants.value = restaurants;
  //     filteredRestaurants.value = restaurants;
  //     _updateRestaurantMarkers();
  //     EasyLoading.dismiss();
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     print("Error in controller: $e");
  //     // EasyLoading.dismiss();
  //   }
  // }

  void filterRestaurantsByCategory(String categoryTitle) async {
    selectedCategory.value = categoryTitle;
    searchController.text = categoryTitle;
    isSearching.value = true;

    selectedRestaurant.value = null;
    showCategoryList.value = true;
    String categoryKey = categoryTitle.toLowerCase().replaceAll(' ', '-');

    if (currentPos.value == null) return;

    try {
      // EasyLoading বাদ দিয়ে আমাদের কাস্টম ভেরিয়েবল true করা হলো
      isCategoryLoading.value = true;

      // নতুন ডাটা আসার আগে পুরোনো ডাটা মুছে দেওয়া হলো
      allRestaurants.clear();
      filteredRestaurants.clear();
      restaurantMarkers.clear();

      // Reset pagination for this category.
      _restaurantsCategoryKey = categoryKey;
      _restaurantsPage = 1;
      hasMoreRestaurants.value = false;

      final result = await ApiService.fetchRestaurants(
        categoryKey: categoryKey,
        lat: currentPos.value!.latitude,
        lng: currentPos.value!.longitude,
        page: _restaurantsPage,
        pageSize: _restaurantsPageSize,
      );

      log(
        "Restaurants fetched for $categoryTitle: ${result.restaurants.length} "
        "(page=${result.page}/${result.totalCount}, hasMore=${result.hasMore})",
      );
      allRestaurants.value = result.restaurants;
      filteredRestaurants.value = result.restaurants;
      hasMoreRestaurants.value = result.hasMore;
      _updateRestaurantMarkers();
    } catch (e) {
      log("Error in controller: $e");
    } finally {
      // কাজ শেষে লোডিং বন্ধ করা হলো
      isCategoryLoading.value = false;
    }
  }

  Future<void> loadMoreRestaurantsByCategory() async {
    if (isLoadingMoreRestaurants.value) return;
    if (!hasMoreRestaurants.value) return;
    if (_restaurantsCategoryKey.isEmpty) return;
    if (currentPos.value == null) return;

    try {
      isLoadingMoreRestaurants.value = true;
      final nextPage = _restaurantsPage + 1;

      final result = await ApiService.fetchRestaurants(
        categoryKey: _restaurantsCategoryKey,
        lat: currentPos.value!.latitude,
        lng: currentPos.value!.longitude,
        page: nextPage,
        pageSize: _restaurantsPageSize,
      );

      if (result.restaurants.isNotEmpty) {
        _restaurantsPage = nextPage;
        allRestaurants.addAll(result.restaurants);
        filteredRestaurants.addAll(result.restaurants);
        _updateRestaurantMarkers();
      }
      hasMoreRestaurants.value = result.hasMore;
      log(
        "Restaurants loadMore page=$nextPage added=${result.restaurants.length} "
        "hasMore=${result.hasMore}",
      );
    } catch (e) {
      log("Error loading more restaurants: $e");
    } finally {
      isLoadingMoreRestaurants.value = false;
    }
  }

  // --- Sort / filter (client-side over the loaded pages) ---
  // Default to "Nearest" for everyone (sorts by live distance to the user).
  final Rx<RestaurantSort> restaurantSort = RestaurantSort.nearest.obs;

  double _distanceTo(Position pos, RestaurantModel r) =>
      Geolocator.distanceBetween(pos.latitude, pos.longitude, r.lat, r.lng);

  /// [filteredRestaurants] reordered by the active [restaurantSort]. The UI
  /// renders this so the raw paginated list stays intact for append-on-scroll.
  List<RestaurantModel> get displayedRestaurants {
    final list = filteredRestaurants.toList();
    final pos = currentPos.value;
    switch (restaurantSort.value) {
      case RestaurantSort.nearest:
        if (pos != null) {
          list.sort(
            (a, b) => _distanceTo(pos, a).compareTo(_distanceTo(pos, b)),
          );
        }
        break;
      case RestaurantSort.farthest:
        if (pos != null) {
          list.sort(
            (a, b) => _distanceTo(pos, b).compareTo(_distanceTo(pos, a)),
          );
        }
        break;
      case RestaurantSort.trending:
        // Proxy for "trending on Google": most-reviewed first, then top rated.
        list.sort((a, b) {
          final byReviews = b.totalReviews.compareTo(a.totalReviews);
          if (byReviews != 0) return byReviews;
          return b.rating.compareTo(a.rating);
        });
        break;
      case RestaurantSort.pointsHigh:
        list.sort((a, b) => b.points.compareTo(a.points));
        break;
      case RestaurantSort.pointsLow:
        list.sort((a, b) => a.points.compareTo(b.points));
        break;
      case RestaurantSort.none:
        break;
    }
    return list;
  }

  void setRestaurantSort(RestaurantSort option) =>
      restaurantSort.value = option;

  void onRestaurantSelected(RestaurantModel rest) {
    // Mark that list was opened from bottom sheet context
    listOpenedFromBottomSheet.value = true;
    showCategoryList.value = false;
    selectedRestaurant.value = rest;
    _safeAnimateCamera(
      CameraUpdate.newLatLngZoom(LatLng(rest.lat, rest.lng), 16),
    );
  }

  void closeRestaurantListSheet() {
    // Hide the list sheet but keep the loaded restaurants & markers so the user
    // can reopen it via the floating button (see reopenRestaurantListSheet).
    showCategoryList.value = false;
    listOpenedFromBottomSheet.value = false;
  }

  /// Reopen the restaurant list sheet after it was closed (loaded data is kept).
  void reopenRestaurantListSheet() {
    selectedRestaurant.value = null;
    showCategoryList.value = true;
  }

  /// True when a list was loaded but its sheet is currently hidden — used to
  /// show the floating "show list" button.
  bool get canReopenRestaurantList =>
      !showCategoryList.value &&
      selectedRestaurant.value == null &&
      filteredRestaurants.isNotEmpty;

  void closeBottomSheet() {
    selectedRestaurant.value = null;
    showCategoryList.value = false;
  }

  void _updateRestaurantMarkers() async {
    final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(60, 60)),
      'assets/Images/Pin.png',
    );

    final Set<Marker> newMarkers = {};

    // 1000+ ডেটার ক্ষেত্রে ক্র্যাশ ঠেকাতে ব্যাচ প্রসেসিং (100 টা করে)
    const int batchSize = 100;
    for (int i = 0; i < filteredRestaurants.length; i += batchSize) {
      final batch = filteredRestaurants.skip(i).take(batchSize);
      for (var rest in batch) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(rest.id),
            position: LatLng(rest.lat, rest.lng),
            icon: customIcon,
            onTap: () {
              log("Marker tapped: ${rest.name}, id: ${rest.id}");
              selectedRestaurant.value = rest;
              log("selectedRestaurant set: ${selectedRestaurant.value?.name}");
              _safeAnimateCamera(
                CameraUpdate.newLatLngZoom(LatLng(rest.lat, rest.lng), 16),
              );
            },
          ),
        );
      }
      // UI থ্রেড ফ্রি রাখতে ছোট্ট ডিল্যে, যাতে অ্যাপ ল্যাগ বা ক্র্যাশ না করে
      await Future.delayed(const Duration(milliseconds: 10));
    }

    restaurantMarkers.value = newMarkers;
    log("Markers updated with Custom Icon: ${restaurantMarkers.length}");
  }

  Future<BitmapDescriptor> getBitmapFromSvg(String path, int size) async {
    final String svgString = await rootBundle.loadString(path);
    final SvgStringLoader loader = SvgStringLoader(svgString);
    final PictureInfo pictureInfo = await vg.loadPicture(loader, null);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );
    canvas.scale(size / pictureInfo.size.width, size / pictureInfo.size.height);
    canvas.drawPicture(pictureInfo.picture);
    final image = await recorder.endRecording().toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    pictureInfo.picture.dispose();
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width, // এখানে ইমেজের সাইজ কন্ট্রোল হবে
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  void clearRestaurantSearch() {
    isSearching.value = false;
    searchController.clear();
    selectedCategory.value = '';
    allRestaurants.clear();
    filteredRestaurants.clear();
    restaurantMarkers.clear();
    selectedRestaurant.value = null;
    showCategoryList.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<BitmapDescriptor> getCustomSearchMarker() async {
    final ByteData data = await rootBundle.load('assets/Images/mapicon.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 150,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;
    final int size = 200;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double radius = size / 2;
    final Offset center = Offset(radius, radius);
    final Paint redPaint = Paint()..color = Colors.transparent;
    canvas.drawCircle(center, radius, redPaint);
    final Paint whitePaint = Paint()..color = Colors.transparent;
    canvas.drawCircle(center, radius - 8, whitePaint);
    final double imageSize = size * 0.8;
    final double offset = (size - imageSize) / 2;
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect dstRect = Rect.fromLTWH(offset, offset, imageSize, imageSize);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // MapController ক্লাসের ভেতরে এই ফাংশনটি রিপ্লেস করুন
  Future<void> drawRouteToDestinationForDifferrent(
    LatLng destination, {
    String mode = 'driving',
  }) async {
    if (currentPos.value == null) return;

    // 🔥 EasyLoading.show(...) বাদ দিয়ে আমাদের কাস্টম লোডিং ট্রু করে দিলাম
    isRouteLoading.value = true;

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${currentPos.value!.latitude},${currentPos.value!.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$mode&key=$googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if ((data['routes'] as List).isNotEmpty) {
          String encodedPoints =
              data['routes'][0]['overview_polyline']['points'];
          List<LatLng> routePoints = _decodePolyline(encodedPoints);

          // কালার লজিক
          Color routeColor;
          switch (mode) {
            case 'driving':
              routeColor = Colors.green;
              break;
            case 'bicycling':
              routeColor = Colors.amber;
              break;
            case 'transit':
              routeColor = Colors.yellow;
              break;
            case 'walking':
            default:
              routeColor = Colors.blue;
              break;
          }

          navigationPolyline.value = {
            Polyline(
              polylineId: const PolylineId("navigation_route"),
              points: routePoints,
              color: routeColor,
              width: 5,
            ),
          };
          _updatePolyline();
          _fitBounds(routePoints);

          var leg = data['routes'][0]['legs'][0];
          String distance = leg['distance']['text'];
          String duration = leg['duration']['text'];

          currentRouteInfo.value = {
            "distance": distance,
            "duration": duration,
            "mode": mode,
            "color": routeColor,
          };
        } else {
          log("No route found for mode: $mode");
          AppToast.error("No route found for $mode mode");
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      log("Error fetching route: $e");
    } finally {
      // 🔥 কাজ শেষ হলে লোডিং ফলস করে দিলাম
      isRouteLoading.value = false;
    }
  }

  void clearRoute() {
    navigationPolyline.clear();
    _updatePolyline();
    currentRouteInfo.value = null;
    searchMarker.clear();
    selectedDestination.value = null;
  }
}

FriendsModel toFriendsModel(FriendLocation friend) {
  return FriendsModel(
    id: friend.userId,
    username: friend.username,
    firstName: friend.firstName,
    lastName: friend.lastName,
    avatarUrl: friend.avatarUrl,
    totalPoints: friend.totalPoints,
    thisWeekPoints: friend.thisWeekPoints,
    profileUrl: friend.profileUrl,
  );
}
