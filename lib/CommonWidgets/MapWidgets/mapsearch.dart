import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:outspot/Model/friendLocation.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Model/resturant_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = Get.find<MapController>();

  List<Map<String, dynamic>> _recentSearches = [];

  // রেজাল্ট রাখার জন্য দুটি আলাদা লিস্ট
  List<FriendLocation> _friendResults = [];
  List<Map<String, dynamic>> _placeResults = [];

  bool _isSearching = false;
  bool _placesLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _loadHistory() async {
    List<Map<String, dynamic>> history =
        await UserPreference.getSearchHistory();
    setState(() {
      _recentSearches = history;
    });
  }

  void _saveSearchToHistory(String title, {String imageUrl = ''}) async {
    if (title.isNotEmpty) {
      await UserPreference.addSearchItem(title, imageUrl);
    }
  }

  // --- Combined Search Function (Friends + Places) ---
  Future<void> _onSearchChanged(String query) async {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _placesLoading = false;
        _friendResults.clear();
        _placeResults.clear();
      });
      return;
    }

    // 1. Search Friends locally — instant, no debounce
    final searchLower = query.toLowerCase();
    List<FriendLocation> matches =
        controller.friendsLocation.where((friend) {
          final name = "${friend.firstName} ${friend.lastName}".toLowerCase();
          final username = friend.username.toLowerCase();
          return name.contains(searchLower) || username.contains(searchLower);
        }).toList();

    setState(() {
      _isSearching = true;
      _placesLoading = true; // backend call pending
      _friendResults = matches;
    });

    // 2. Search Places via backend — debounced so we don't hit the API on
    //    every keystroke. Waits 1.2s after the user stops typing to keep
    //    API/billing usage low (users type slowly).
    _debounce = Timer(const Duration(milliseconds: 1200), () {
      _fetchPlaces(query);
    });
  }

  Future<void> _fetchPlaces(String query) async {
    final pos = controller.currentPos.value;
    if (pos == null) {
      if (mounted) {
        setState(() {
          _placesLoading = false;
          _placeResults.clear();
        });
      }
      return;
    }

    try {
      // Backend requires a category param. Use the map's selected category
      // (e.g. "Bars" → "bars", "Venue Events" → "venue-events"); fall back
      // to 'restaurants' when no category is active on the map.
      final raw = controller.selectedCategory.value.trim().toLowerCase();
      final category = raw.isEmpty ? 'restaurants' : raw.replaceAll(' ', '-');

      final response = await ApiService.searchExplorePlaces(
        query: query,
        lat: pos.latitude,
        lng: pos.longitude,
        limit: 10,
        category: category,
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _placesLoading = false;
            _placeResults = List<Map<String, dynamic>>.from(
              data['places'] ?? [],
            );
          });
        } else {
          setState(() {
            _placesLoading = false;
            _placeResults.clear();
          });
        }
      } else {
        setState(() {
          _placesLoading = false;
          _placeResults.clear();
        });
      }
    } catch (e) {
      print("Error fetching places: $e");
      if (mounted) {
        setState(() {
          _placesLoading = false;
          _placeResults.clear();
        });
      }
    }
  }

  // --- Place Selection & Map Navigation ---
  void _selectPlace(Map<String, dynamic> placeJson) {
    final lat = (placeJson['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (placeJson['lng'] as num?)?.toDouble() ?? 0.0;
    final name = placeJson['name'] ?? 'Unknown';
    final id = placeJson['id'] ?? '';

    _saveSearchToHistory(name);
    controller.searchController.clear();
    Get.back();

    // Set map marker
    controller.selectedDestination.value = LatLng(lat, lng);
    controller.searchMarker.value = {
      Marker(
        markerId: const MarkerId('search'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
      ),
    };

    // Animate camera
    controller.googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
    );

    // Create RestaurantModel and set to selectedRestaurant to show the bottom sheet dynamically
    final model = RestaurantModel(
      id: id,
      name: name,
      address: placeJson['address'] ?? '',
      lat: lat,
      lng: lng,
      image: placeJson['image'] ?? '',
      photos: List<String>.from(placeJson['photos'] ?? []),
      category: placeJson['category'] ?? 'establishment',
      priceRange: placeJson['priceRange'] ?? '\$\$',
      status: placeJson['status'] ?? 'Closed',
      rating: (placeJson['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: placeJson['totalReviews'] ?? 0,
      phone: placeJson['phone'] ?? '',
      website: placeJson['website'] ?? '',
      openingHours: List<String>.from(placeJson['openingHours'] ?? []),
      points: placeJson['points'] ?? 0,
    );

    controller.selectedRestaurant.value = model;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff2D0731),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header & Search Bar ---
              Row(
                children: [
                  const CustomBackButton(),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xff42D880),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller.searchController,
                        // Results show live in the list below — there's nothing
                        // to "search" on submit, so the keyboard shows a plain
                        // Done that just dismisses it (no confusing auto-open).
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 16.sp,
                        ),
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search places...",
                          hintStyle: GoogleFonts.notoSans(
                            color: Colors.white70,
                            fontSize: 16.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              controller.searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: SvgPicture.asset(
                                controller.searchController.text.isNotEmpty
                                    ? "assets/svg/icons/Cross.svg"
                                    : "assets/svg/icons/search_Icons.svg",
                                height: 15.sp,
                                width: 15.sp,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Done just closes the keyboard. Opening a place / saving
                        // to history happens only when the user taps a result.
                        onSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Expanded(
                child:
                    _isSearching
                        ? _buildCombinedSearchResults()
                        : _buildRecentHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Combined Search Results (Friends + Places) ---
  Widget _buildCombinedSearchResults() {
    if (_friendResults.isEmpty && _placeResults.isEmpty) {
      // While the backend place search is in flight → a looping Lottie so the
      // wait feels alive (replaces the old static search icon + "Searching…").
      if (_placesLoading) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/Images/search.json',
                width: 160.w,
                height: 160.w,
                repeat: true,
                fit: BoxFit.contain,
              ),
              Text(
                "Searching…",
                style: GoogleFonts.notoSans(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: Colors.white70,
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              "No places found",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Try a different name or spelling",
              style: GoogleFonts.notoSans(
                color: Colors.white54,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Friends Section
        if (_friendResults.isNotEmpty) ...[
          Text(
            "Friends",
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.greenAccent,
            ),
          ),
          SizedBox(height: 10.h),
          ..._friendResults.map((friend) {
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                    style: GoogleFonts.notoSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "@${friend.username}",
                    style: GoogleFonts.notoSans(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                  ),
                  onTap: () {
                    _saveSearchToHistory(
                      "${friend.firstName} ${friend.lastName}",
                      imageUrl: friend.avatarUrl,
                    );
                    controller.searchController.clear();
                    Get.back();
                    controller.navigateToFriend(friend);
                  },
                ),
                const Divider(color: Colors.white12),
              ],
            );
          }).toList(),
          SizedBox(height: 20.h),
        ],

        // Places Section
        if (_placeResults.isNotEmpty) ...[
          Text(
            "Places",
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.greenAccent,
            ),
          ),
          SizedBox(height: 10.h),
          ..._placeResults.map((place) {
            final description = place['name'] ?? 'Unknown';
            final address = place['address'] ?? '';
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 20.r,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    description,
                    style: GoogleFonts.notoSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  subtitle:
                      address.isNotEmpty
                          ? Text(
                            address,
                            style: GoogleFonts.notoSans(
                              fontSize: 12.sp,
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                          : null,
                  trailing:
                      place['points'] != null && place['points'] > 0
                          ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.orangeAccent),
                            ),
                            child: Text(
                              "${place['points']} pts",
                              style: GoogleFonts.notoSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          )
                          : null,
                  onTap: () {
                    _selectPlace(place);
                  },
                ),
                const Divider(color: Colors.white12),
              ],
            );
          }).toList(),
        ],
      ],
    );
  }

  // --- Recent History Section ---
  Widget _buildRecentHistory() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              color: const Color(0xff42D880),
              size: 48.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              "Type to search places",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Find restaurants, bars, events & friends near you",
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                color: Colors.white54,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await UserPreference.clearSearchHistory();
                  _loadHistory();
                },
                child: Text(
                  "Clear All",
                  style: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final item = _recentSearches[index];
              return _buildHistoryItem(
                item['title'] ?? '',
                item['image'] ?? '',
                index,
              );
            },
          ),
        ),
      ],
    );
  }

  // --- History Item ---
  Widget _buildHistoryItem(String title, String imageUrl, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                controller.searchController.clear();
                Get.back();
                // Check if it's likely a friend or place (based on image presence)
                if (imageUrl.isNotEmpty) {
                  // Try to find the friend again
                  var friend = controller.friendsLocation.firstWhereOrNull(
                    (f) => "${f.firstName} ${f.lastName}" == title,
                  );
                  if (friend != null) controller.navigateToFriend(friend);
                } else {
                  controller.searchAndNavigate(title);
                }
              },
              child: Row(
                children: [
                  imageUrl.isNotEmpty && imageUrl.startsWith('http')
                      ? CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            alignment: Alignment.topCenter,
                            width: 40.w,
                            height: 30.h,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const ShimmerPlaceholder(),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      )
                      : CircleAvatar(
                        radius: 20.r,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.history,
                          color: Colors.white54,
                          size: 20.sp,
                        ),
                      ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.notoSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await UserPreference.removeSearchItem(title);
              _loadHistory();
            },
            child: Padding(
              padding: EdgeInsets.only(left: 10.w),
              child: Icon(Icons.close, color: Colors.grey, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}
