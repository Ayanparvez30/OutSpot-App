import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outspot/Model/place_detail_model.dart';
import 'package:outspot/Model/resturant_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/CommonWidgets/MapWidgets/bottomsheet_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:outspot/Utils/shared_location.dart';
import 'package:outspot/CommonWidgets/MapWidgets/image_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:outspot/Model/explore_place_model.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Views/Message/camera_screen.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_feed_controller.dart';

import '../../Utils/colors.dart';

class RestaurantBottomSheet extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantBottomSheet({super.key, required this.restaurant});

  @override
  State<RestaurantBottomSheet> createState() => _RestaurantBottomSheetState();
}

class _RestaurantBottomSheetState extends State<RestaurantBottomSheet>
    with SingleTickerProviderStateMixin {
  final MapController mapController = Get.find();

  /// Shared with Explore so a bookmark made here shows up on the Saved screen
  /// and on the feed's cards.
  late final ExploreFeedController _feed =
      Get.isRegistered<ExploreFeedController>()
          ? Get.find<ExploreFeedController>()
          : Get.put(ExploreFeedController());
  final BottomSheetController sheetController = Get.put(
    BottomSheetController(),
  );

  late AnimationController _animController;
  double _dragOffset = 0;

  // Extra details (distance, services, reviews) fetched like PlaceDetailsScreen
  PlaceDetailModel? _detail;
  bool _loadingDetail = true;
  final Set<String> _expandedReviews = {};

  // Points recovered from the /explore/search endpoint when the place was
  // opened with 0 points (e.g. from a shared location). See _resolvePoints().
  int _searchPoints = 0;

  RestaurantModel get restaurant => widget.restaurant;

  // App points for this place. When the place is opened from Google (a shared
  // location or a map search), restaurant.points is 0 — so prefer the app's
  // place-detail points, then the /explore/search lookup, then the model.
  int get _displayPoints {
    if ((_detail?.points ?? 0) > 0) return _detail!.points;
    if (restaurant.points > 0) return restaurant.points;
    return _searchPoints;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fetchPlaceDetails();
    // Opened with no points (e.g. from a shared location / Google) → recover the
    // real points via the same search API the map's search field uses.
    if (restaurant.points <= 0) {
      _resolvePoints();
    }
  }

  /// When the place arrives with 0 points, look it up via /explore/search (which
  /// returns the app's real points) and adopt them — so a place shows the same
  /// points whether opened from Trending or from a shared chat message.
  Future<void> _resolvePoints() async {
    final pos = mapController.currentPos.value;
    if (pos == null || restaurant.name.trim().isEmpty) return;
    try {
      final raw = mapController.selectedCategory.value.trim().toLowerCase();
      final category = raw.isEmpty ? 'restaurants' : raw.replaceAll(' ', '-');

      final response = await ApiService.searchExplorePlaces(
        query: restaurant.name,
        lat: pos.latitude,
        lng: pos.longitude,
        category: category,
      );
      if (!mounted || response.statusCode != 200) return;

      final data = json.decode(response.body);
      final places = List<Map<String, dynamic>>.from(data['places'] ?? []);
      if (places.isEmpty) return;

      // Prefer an exact place-id match; otherwise fall back to the first result.
      Map<String, dynamic> match = places.firstWhere(
        (p) => (p['id']?.toString() ?? '') == restaurant.id,
        orElse: () => places.first,
      );

      final pts = (match['points'] as num?)?.toInt() ?? 0;
      if (pts > 0 && mounted) {
        setState(() => _searchPoints = pts);
      }
    } catch (e) {
      debugPrint('resolve points error: $e');
    }
  }

  Future<void> _fetchPlaceDetails() async {
    final pos = mapController.currentPos.value;
    final placeId = restaurant.id;
    if (placeId.isEmpty || pos == null) {
      if (mounted) setState(() => _loadingDetail = false);
      return;
    }
    try {
      final response = await ApiService.fetchPlaceDetails(
        placeId: placeId,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final placeData = data['place'] ?? data;
        if (mounted) {
          setState(() {
            _detail = PlaceDetailModel.fromJson(placeData);
            _loadingDetail = false;
          });
        }
      } else if (mounted) {
        setState(() => _loadingDetail = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 600);
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
      // Dismiss with animation
      _animController.addListener(_dismissListener);
      _animController.forward(from: 0);
    } else {
      // Snap back
      _animController.addListener(_snapBackListener);
      _animController.forward(from: 0);
    }
  }

  void _dismissListener() {
    setState(() {
      _dragOffset = _dragOffset + (600 - _dragOffset) * _animController.value;
    });
    if (_animController.isCompleted) {
      _animController.removeListener(_dismissListener);
      // If list was opened from this bottom sheet, restore the list view with search state
      if (mapController.listOpenedFromBottomSheet.value) {
        mapController.showCategoryList.value = true;
        mapController.isSearching.value =
            true; // Keep search bar visible with category name
      }
      mapController.selectedRestaurant.value = null;
      mapController.listOpenedFromBottomSheet.value = false;
      mapController.searchMarker.clear();
    }
  }

  void _snapBackListener() {
    setState(() {
      _dragOffset = _dragOffset * (1 - _animController.value);
    });
    if (_animController.isCompleted) {
      _animController.removeListener(_snapBackListener);
      _animController.reset();
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // iOS only dials when the tel: URL is bare digits with an optional leading
    // "+". Spaces / parentheses / dashes (e.g. "(510) 656-8000") get
    // percent-encoded and iOS silently refuses to open the dialer — so strip
    // everything except digits and a leading plus.
    var cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.contains('+')) {
      final hadLeadingPlus = cleaned.startsWith('+');
      cleaned = cleaned.replaceAll('+', '');
      if (hadLeadingPlus) cleaned = '+$cleaned';
    }
    if (cleaned.isEmpty) return;

    final Uri launchUri = Uri(scheme: 'tel', path: cleaned);
    try {
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback for platforms that don't honour externalApplication.
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Error launching phone: $e");
    }
  }

  Future<void> _launchWebsite(String url) async {
    if (url.isEmpty) return;

    String finalUrl = url;
    if (!finalUrl.startsWith("http")) {
      finalUrl = "https://$finalUrl";
    }

    final Uri launchUri = Uri.parse(finalUrl);
    try {
      // iOS তে canLaunchUrl সবসময় সঠিক কাজ করে না, তাই সরাসরি launch করি
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: platformDefault mode try করি
        await launchUrl(launchUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Error launching website: $e");
    }
  }

  void _openImageViewer(List<String> images, int initialIndex) {
    Get.to(
      () => ImageViewerScreen(images: images, initialIndex: initialIndex),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Container(
          height: 500.h,
          width: double.infinity,
          decoration: BoxDecoration(
            // Figma paints the sheet's top with a #63149F → #16001C gradient
            // rather than a flat purple; the header sits on the bright end and
            // the body fades into the dark.
          gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: const [0.0, 0.6],
        ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              // ড্র্যাগ হ্যান্ডেল
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 15.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header ---
                      _buildHeader(),

                      SizedBox(height: 12.h),

                      // --- Spot Actions (Figma "Spot Actions", 361x36) ---
                      _buildSpotActions(),

                      SizedBox(height: 16.h),

                      // --- Top 3 Photos Preview (Always visible) ---
                      if (restaurant.photos.isNotEmpty) _buildTopPhotos(),

                      SizedBox(height: 20.h),

                      // --- Tab Bar (Overview | Photos) ---
                      _buildTabs(),

                      Divider(color: Colors.white24, height: 1),
                      SizedBox(height: 15.h),

                      // --- Tab Content (Switching based on selection) ---
                      Obx(() {
                        if (sheetController.selectedTab.value == 0) {
                          return _buildOverviewContent(context);
                        } else {
                          return _buildPhotosContent();
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // হেডার অংশ (নাম, রেটিং, স্ট্যাটাস)
  /// Figma "Bottom Sheet Top Nav" (393×153): grabber, name, two metadata
  /// lines with the points badge, and the close button — in that order.
  ///
  /// The old header carried its own directions/send buttons; those now live in
  /// the actions row below, so keeping them here showed the same icon twice
  /// doing the same thing. Only the close button stays.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                restaurant.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () {
                // Unchanged: restore the category list if the sheet was opened
                // from it, then clear the selection.
                if (mapController.listOpenedFromBottomSheet.value) {
                  mapController.showCategoryList.value = true;
                  mapController.isSearching.value = true;
                }
                mapController.selectedRestaurant.value = null;
                mapController.listOpenedFromBottomSheet.value = false;
                mapController.isSearching.value = false;
              },
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 18.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        // Line 1: category · distance
        Row(
          children: [
            ExploreIcons.svg(ExploreIcons.pillTrending, size: 12.sp),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                restaurant.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  color: const Color(0xffBABABA),
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        // Line 2: price · open/closed · rating (reviews) · points badge
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6.w,
                runSpacing: 2.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (restaurant.priceRange.trim().isNotEmpty)
                    Text(
                      restaurant.priceRange,
                      style: GoogleFonts.notoSans(
                        color: const Color(0xffBABABA),
                        fontSize: 12.sp,
                      ),
                    ),
                  if (restaurant.status.trim().isNotEmpty)
                    Text(
                      restaurant.status,
                      style: GoogleFonts.notoSans(
                        color:
                            restaurant.status.toLowerCase().contains('open')
                                ? const Color(0xff42D880)
                                : const Color(0xffFF7474),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (restaurant.rating > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExploreIcons.svg(
                          ExploreIcons.cardRatingStar,
                          size: 12.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: GoogleFonts.notoSans(
                            color: const Color(0xffF8AC00),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (restaurant.totalReviews > 0) ...[
                          SizedBox(width: 2.w),
                          Text(
                            '(${restaurant.totalReviews})',
                            style: GoogleFonts.notoSans(
                              color: const Color(0xffBABABA),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _pointsBadge(),
          ],
        ),
      ],
    );
  }

  /// Figma "Points Badge Small" — 43×20, #3B2625 on a #9D8813 hairline.
  Widget _pointsBadge() {
    // _searchPoints is filled by _resolvePoints() when the search endpoint has
    // a better figure than the marker payload carried; until then the
    // restaurant's own value stands.
    final pts = _searchPoints > 0 ? _searchPoints : restaurant.points;
    return Container(
        height: 20.h,
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        decoration: BoxDecoration(
          color: const Color(0xff3B2625),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xff9D8813), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExploreIcons.svg(ExploreIcons.cardPoints, size: 12.sp),
            SizedBox(width: 3.w),
            Text(
              '$pts',
              style: GoogleFonts.notoSans(
                color: const Color(0xffFFEA00),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
    );
  }

  /// Figma "Spot Actions" — Check In plus five round buttons, 36px, gap 8.
  ///
  /// Check In is deliberately a copy of the PlaceDetailsScreen behaviour, not a
  /// new flow: same closed-place guard, same `CameraScreen` push, same
  /// arguments. Anything else would award points down a different path.
  Widget _buildSpotActions() {
    // Same guard PlaceDetailsScreen applies: once status is known and the place
    // isn't open, Check In is replaced by a disabled "Closed" chip. While status
    // is unknown the button stays live, matching that screen.
    final status = restaurant.status.trim();
    final isClosed =
        status.isNotEmpty && !status.toLowerCase().contains('open');

    return SizedBox(
      height: 36.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          isClosed ? _closedChip() : _checkInButton(),
          SizedBox(width: 8.w),
          _roundAction(
            ExploreIcons.sheetDirections,
            onTap: () async {
              await mapController.drawRouteToDestination(
                LatLng(restaurant.lat, restaurant.lng),
              );
              mapController.selectedRestaurant.value = null;
              mapController.listOpenedFromBottomSheet.value = false;
            },
          ),
          SizedBox(width: 8.w),
          _saveAction(),
          SizedBox(width: 8.w),
          if (restaurant.phone.trim().isNotEmpty) ...[
            _roundAction(
              ExploreIcons.sheetCall,
              onTap: () => _makePhoneCall(restaurant.phone.trim()),
            ),
            SizedBox(width: 8.w),
          ],
          if (restaurant.website.trim().isNotEmpty) ...[
            _roundAction(
              ExploreIcons.sheetWebsite,
              onTap: () => _launchWebsite(restaurant.website.trim()),
            ),
            SizedBox(width: 8.w),
          ],
          _roundAction(
            ExploreIcons.sheetSend,
            onTap: () {
              final display =
                  '${restaurant.name}\n${restaurant.address}\n'
                  '${restaurant.rating} stars - ${restaurant.category}';
              showSendToSheet(
                SharedLocation.encode(
                  displayText: display,
                  placeId: restaurant.id,
                  lat: restaurant.lat,
                  lng: restaurant.lng,
                  name: restaurant.name,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _checkInButton() {
    return GestureDetector(
      onTap: () {
        // Identical to PlaceDetailsScreen: push the camera in this flow with
        // the place and category, so back returns here and the visit is
        // recorded exactly the same way.
        Get.to(
          () => const CameraScreen(),
          arguments: {
            'place': _asExplorePlace(),
            'categoryKey':
                mapController.selectedCategory.value.isNotEmpty
                    ? mapController.selectedCategory.value
                    : restaurant.category,
            'fromCheckIn': true,
          },
        );
      },
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xffE2206D),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Text(
          'Check In',
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _closedChip() => Container(
    height: 36.h,
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(24.r),
    ),
    child: Text(
      'Closed',
      style: GoogleFonts.notoSans(
        color: Colors.white54,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// Round action button. [asset] is a Figma export, not a Material glyph —
  /// the designed icons differ enough from Material's that mixing them showed.
  Widget _roundAction(String asset, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.h,
        height: 36.h,
        decoration: const BoxDecoration(
          color: Color(0xff78368F),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: ExploreIcons.svg(asset, size: 20.sp, color: Colors.white),
        ),
      ),
    );
  }

  /// Bookmark, backed by the same saved-places endpoints the Explore cards use,
  /// so a spot saved from the map shows up on the Saved screen too.
  Widget _saveAction() {
    return Obx(() {
      final saved = _feed.savedPlaceIds.contains(restaurant.id);
      return GestureDetector(
        onTap: () => _feed.toggleSaved(_asSpotCard()),
        child: Container(
          width: 36.h,
          height: 36.h,
          decoration: const BoxDecoration(
            color: Color(0xff78368F),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: ExploreIcons.svg(
              ExploreIcons.sheetSave,
              size: 20.sp,
              // Filled state is the same glyph tinted gold, as on the cards.
              color: saved ? const Color(0xffF8AC00) : Colors.white,
            ),
          ),
        ),
      );
    });
  }

  /// The shape `CameraScreen` and `PlaceDetailsScreen` expect.
  ExplorePlaceModel _asExplorePlace() => ExplorePlaceModel(
    placeId: restaurant.id,
    name: restaurant.name,
    address: restaurant.address,
    photoUrl: restaurant.image,
    points: restaurant.points,
    // The map sheet has no distance of its own; the check-in flow re-measures
    // against live GPS anyway, so 0 here is not used for any decision.
    distanceMiles: 0,
    lat: restaurant.lat,
    lng: restaurant.lng,
    rating: restaurant.rating,
    userRatingsTotal: restaurant.totalReviews,
  );

  /// The shape the saved-places controller expects.
  SpotCardModel _asSpotCard() => SpotCardModel(
    placeId: restaurant.id,
    name: restaurant.name,
    photoUrl: restaurant.image,
    address: restaurant.address,
    points: restaurant.points,
    distanceMiles: 0,
    lat: restaurant.lat,
    lng: restaurant.lng,
    rating: restaurant.rating,
    reviewCount: restaurant.totalReviews,
    openNow: restaurant.status.toLowerCase().contains('open'),
    priceRange: restaurant.priceRange,
    types: const [],
    category: restaurant.category,
    friendsCount: 0,
    friends: const [],
    accessible: false,
  );

  /// Figma "Friends Spotted Card": gold glyph, title, overlapping avatars and
  /// the spotted-here line.
  Widget _buildFriendsSpottedCard() {
    final friends = _detail?.friends ?? const [];
    final count = _detail?.friendsCount ?? 0;
    final shown = friends.take(3).toList();
    final avatar = 36.w;
    final step = avatar - 6.w; // Figma overlaps the avatars by 6px

    final first = shown.isNotEmpty ? shown.first.name : '';
    final others = count - 1;
    final line =
        others <= 0
            ? '$first was spotted here'
            : others == 1
            ? '$first and 1 other were spotted here'
            : '$first and $others others were spotted here';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xffC574F7).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExploreIcons.svg(ExploreIcons.friendsSpotted, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friends Spotted',
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (shown.isNotEmpty)
                      SizedBox(
                        width: step * (shown.length - 1) + avatar,
                        height: avatar,
                        child: Stack(
                          children: [
                            for (var i = 0; i < shown.length; i++)
                              Positioned(
                                left: step * i,
                                child: Container(
                                  width: avatar,
                                  height: avatar,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xff2C003E),
                                      width: 1.5,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child:
                                      shown[i].avatar.isEmpty
                                          ? Icon(
                                            Icons.person,
                                            size: 18.sp,
                                            color: Colors.white54,
                                          )
                                          : CachedNetworkImage(
                                            imageUrl: shown[i].avatar,
                                            fit: BoxFit.cover,
                                            // Minime renders are full-body.
                                            alignment: Alignment.topCenter,
                                            errorWidget:
                                                (_, __, ___) => Icon(
                                                  Icons.person,
                                                  size: 18.sp,
                                                  color: Colors.white54,
                                                ),
                                          ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          color: const Color(0xffBABABA),
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPhotos() {
    if (restaurant.photos.isEmpty) {
      return SizedBox(
        height: 100.h,
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            List<String> allImages = [restaurant.image];
            _openImageViewer(allImages, 0);
          },
          child: _buildPhoto(restaurant.image),
        ),
      );
    }
    return SizedBox(
      height: 100.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                List<String> allImages = [
                  restaurant.image,
                  ...restaurant.photos,
                ];
                _openImageViewer(allImages, 1);
              },
              child: _buildPhoto(restaurant.photos[0]),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      List<String> allImages = [
                        restaurant.image,
                        ...restaurant.photos,
                      ];
                      _openImageViewer(allImages, 2);
                    },
                    child: _buildPhoto(
                      restaurant.photos.length > 1
                          ? restaurant.photos[1]
                          : restaurant.image,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      List<String> allImages = [
                        restaurant.image,
                        ...restaurant.photos,
                      ];
                      _openImageViewer(allImages, 3);
                    },
                    child: _buildPhoto(
                      restaurant.photos.length > 2
                          ? restaurant.photos[2]
                          : restaurant.image,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // কাস্টম ট্যাব বার
  Widget _buildTabs() {
    return Obx(
      () => Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabItem("Overview", 0),
            SizedBox(width: 25.w),
            _buildTabItem("Photos", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = sheetController.selectedTab.value == index;
    return GestureDetector(
      onTap: () => sheetController.selectedTab.value = index,
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: isSelected ? Color(0xffC574F7) : Colors.grey,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          if (isSelected)
            Container(height: 3.h, width: 70.w, color: Color(0xffB166DE))
          else
            SizedBox(height: 3.h, width: 70.w),
        ],
      ),
    );
  }

  // --- OVERVIEW TAB CONTENT ---
  Widget _buildOverviewContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gamification Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Image.asset("assets/Images/skcoin.png", scale: 1.7),
              SizedBox(width: 10.w),
              Text(
                "Visit to get $_displayPoints Points",
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Figma "Friends Spotted Card" — 361×91, #C574F7 at 20%, r=12.
        // Hidden entirely when nobody has been here: an empty card reads as a
        // loading failure rather than as "no friends yet".
        if ((_detail?.friendsCount ?? 0) > 0) ...[
          _buildFriendsSpottedCard(),
          SizedBox(height: 12.h),
        ],

        // Distance (from API)
        if (_detail?.distanceMiles != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_walk,
                  color: Colors.blueAccent,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "${_detail!.distanceMiles!.toStringAsFixed(2)} mi away",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],

        // Description (from API)
        if (_detail?.description != null &&
            _detail!.description!.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _detail!.description!,
              style: GoogleFonts.notoSans(
                color: Colors.white60,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],

        // Sections chips (from API)
        if (_detail != null && _detail!.sections.isNotEmpty) ...[
          _buildChipSection(
            "Sections",
            _detail!.sections,
            const Color(0xff704EF9),
          ),
          SizedBox(height: 10.h),
        ],

        // Cuisine chips (from API)
        if (_detail != null && _detail!.cuisine.isNotEmpty) ...[
          _buildChipSection("Cuisine", _detail!.cuisine, Colors.orangeAccent),
          SizedBox(height: 10.h),
        ],

        // Services chips (from API)
        if (_detail != null && _detail!.services.isNotEmpty) ...[
          _buildChipSection("Services", _detail!.services, Colors.tealAccent),
          SizedBox(height: 10.h),
        ],

        // Opening Hours
        //
        // The Material wrapper is required, not decorative: ExpansionTile paints
        // its ink splash onto the nearest Material ancestor, and a plain
        // Container with a background sits in between — which made Flutter throw
        // "ListTile background color or ink splashes may be invisible" on every
        // sheet open. `clipBehavior` keeps the splash inside the rounded corners.
        Material(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12.r),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white70,
              title: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white70, size: 18),
                  SizedBox(width: 10.w),
                  Text(
                    "Opening Hours",
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              children:
                  restaurant.openingHours
                      .map(
                        (hours) => Padding(
                          padding: EdgeInsets.only(
                            bottom: 5.h,
                            left: 16.w,
                            right: 16.w,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "• ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Expanded(
                                child: Text(
                                  hours,
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
        SizedBox(height: 5.h),

        _buildInfoRow(Icons.location_on_outlined, restaurant.address),
        SizedBox(height: 5.h),
        _buildInfoRow(
          Icons.payments_outlined,
          "Price ${restaurant.priceRange}",
        ),
        SizedBox(height: 5.h),
        _buildInfoRow(Icons.phone, "${restaurant.phone}"),
        SizedBox(height: 5.h),
        if (restaurant.website.isNotEmpty)
          _buildInfoRow(Icons.language, restaurant.website, isLink: true),

        // Reviews (from API)
        if (_detail != null && _detail!.reviews.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildReviewsSection(_detail!.reviews),
        ],

        // Shimmer hint while details load
        if (_loadingDetail) ...[
          SizedBox(height: 14.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Loading details...",
              style: GoogleFonts.notoSans(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],

        SizedBox(height: 20.h),

        // Buttons
        Row(
          children: [
            // Only show Call when there's actually a phone number.
            if (restaurant.phone.trim().isNotEmpty) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(restaurant.phone),
                  icon: Icon(Icons.call, color: Colors.white),
                  label: Text(
                    "Call",
                    style: GoogleFonts.notoSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffFF6B6B),

                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: StadiumBorder(),
                  ),
                ),
              ),
              SizedBox(width: 15.w),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  gradient: const LinearGradient(
                    colors: [Color(0xffA060FA), Color(0xffFF8E8E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _launchWebsite(restaurant.website),
                  icon: const Icon(Icons.language, color: Colors.white),
                  label: Text(
                    "Website",
                    style: GoogleFonts.notoSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 90.h),
      ],
    );
  }

  // --- PHOTOS TAB CONTENT ---
  Widget _buildPhotosContent() {
    if (restaurant.photos.isEmpty) {
      return Center(
        child: Text(
          "No photos available",
          style: GoogleFonts.notoSans(color: Colors.white70),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true, // স্ক্রল ভিউয়ের ভেতরে কাজ করার জন্য
      physics: NeverScrollableScrollPhysics(), // প্যারেন্ট স্ক্রল ব্যবহার করবে
      padding: EdgeInsets.only(bottom: 110.h),
      itemCount: restaurant.photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // প্রতি সারিতে ২টি ছবি
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 1.2, // ছবির সাইজ ঠিক রাখার জন্য
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            List<String> allImages = [restaurant.image, ...restaurant.photos];
            _openImageViewer(allImages, index + 1);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: restaurant.photos[index],
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(color: Colors.black12),
              errorWidget:
                  (c, u, e) => Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (c, u) => Container(color: Colors.black12),
        errorWidget:
            (c, u, e) =>
                Container(color: Colors.grey, child: Icon(Icons.broken_image)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSans(
                color: isLink ? Colors.blueAccent : Colors.white,
                fontSize: 14.sp,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSans(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          children:
              items.map((item) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.notoSans(
                      color: color,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(List<PlaceReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reviews",
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        ...reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(PlaceReview review) {
    final key = review.author + review.timeAgo;
    final isExpanded = _expandedReviews.contains(key);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedReviews.remove(key);
          } else {
            _expandedReviews.add(key);
          }
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.r),
                    child:
                        review.authorPhoto.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: review.authorPhoto,
                              width: 30.w,
                              height: 30.w,
                              fit: BoxFit.cover,
                              errorWidget:
                                  (_, __, ___) => CircleAvatar(
                                    radius: 15.r,
                                    backgroundColor: Colors.white24,
                                    child: Icon(
                                      Icons.person,
                                      size: 16.sp,
                                      color: Colors.white54,
                                    ),
                                  ),
                            )
                            : CircleAvatar(
                              radius: 15.r,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.person,
                                size: 16.sp,
                                color: Colors.white54,
                              ),
                            ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      review.author,
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    review.timeAgo,
                    style: GoogleFonts.notoSans(
                      color: Colors.white38,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14.sp,
                  );
                }),
              ),
              SizedBox(height: 6.h),
              Text(
                review.text,
                style: GoogleFonts.notoSans(
                  color: Colors.white60,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
                maxLines: isExpanded ? null : 4,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
              if (review.text.length > 150)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      isExpanded ? "show less" : "show more",
                      style: GoogleFonts.notoSans(
                        color: Colors.white30,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
