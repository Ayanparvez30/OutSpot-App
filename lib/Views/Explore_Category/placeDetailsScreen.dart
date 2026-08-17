import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/explore_place_model.dart';
import 'package:outspot/Model/place_detail_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:outspot/Utils/shared_location.dart';
import 'package:outspot/CommonWidgets/MapWidgets/image_viewer_screen.dart';
import 'package:outspot/Views/Message/camera_screen.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:shimmer/shimmer.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final ExplorePlaceModel place;
  final String categoryKey;
  final double? userLat;
  final double? userLng;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.categoryKey,
    this.userLat,
    this.userLng,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  PlaceDetailModel? _detail;
  bool _isLoading = true;
  final Set<String> _expandedReviews = {};
  int _selectedTab = 0; // 0 = Overview, 1 = Photos

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (widget.userLat == null || widget.userLng == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await ApiService.fetchPlaceDetails(
        placeId: widget.place.placeId,
        lat: widget.userLat!,
        lng: widget.userLng!,
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final placeData = data['place'] ?? data;
        setState(() {
          _detail = PlaceDetailModel.fromJson(placeData);
          _isLoading = false;
        });
      } else {
        log('❌ Place details failed: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      log('❌ Place details error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  bool _hasValidCoordinates() {
    final lat = _detail?.lat ?? widget.place.lat;
    final lng = _detail?.lng ?? widget.place.lng;
    return !(lat == 0.0 && lng == 0.0);
  }

  void _navigateToRoute() {
    final destLat = _detail?.lat ?? widget.place.lat;
    final destLng = _detail?.lng ?? widget.place.lng;
    final name = widget.place.name;
    final routeData = {"lat": destLat, "lng": destLng, "name": name};

    if (Get.isRegistered<MainscreeenController>() &&
        Get.isRegistered<MapController>()) {
      final mainCtrl = Get.find<MainscreeenController>();
      final mapCtrl = Get.find<MapController>();
      mainCtrl.changeTab(1);
      mapCtrl.pendingRouteFromExplore(routeData);
      Get.until((route) => route.settings.name == Routes.mainscreen);
    } else {
      Get.offAllNamed(
        Routes.mainscreen,
        arguments: {
          "tab": 1,
          "routeTo": routeData,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final detail = _detail;

    final distanceText =
        detail?.distanceMiles != null
            ? "${detail!.distanceMiles!.toStringAsFixed(2)} mi away"
            : "${place.distanceMiles.toStringAsFixed(2)} mi away";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset(
            "assets/svg/icons/back_icon.svg",
            width: 25.r,
            height: 25.r,
          ),
          padding: EdgeInsets.all(8.w),
          constraints: const BoxConstraints(),
        ),
      ),
      // --- Sticky bottom bar: Check In + Route ---
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20.w,
          12.h,
          20.w,
          MediaQuery.of(context).padding.bottom + 12.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgGradientBottom,
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: () {
                // Only allow check-in while the place is OPEN. Status comes from
                // the place detail ("Open"/"Closed"); when it's loaded and NOT
                // open, show a disabled "Closed" state instead of the button.
                // (While status is still null/loading we keep Check In enabled.)
                final s = _detail?.status;
                final isClosed =
                    s != null && !s.toLowerCase().contains('open');
                if (isClosed) {
                  return Container(
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_clock,
                          size: 16.sp,
                          color: Colors.white38,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Closed — can't check in",
                          style: GoogleFonts.notoSans(
                            decoration: TextDecoration.none,
                            fontSize: 14.sp,
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () {
                    // Open the camera IN THIS FLOW (pushed) so it doesn't bounce
                    // through the home tabs. Back returns to this place; the same
                    // CameraScreen + place/category context is reused.
                    Get.to(
                      () => const CameraScreen(),
                      arguments: {
                        'place': place,
                        'categoryKey': widget.categoryKey,
                        'fromCheckIn': true,
                      },
                    );
                  },
                  child: Container(
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.btnGradientLeft,
                          AppColors.btnGradientRight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      "Check In",
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 16.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }(),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () {
                final display = '${place.name}\n${place.address}\n${place.rating} stars - ${place.points} points';
                // Embed the place so the recipient can tap the message to
                // reopen it on the map.
                final msg = SharedLocation.encode(
                  displayText: display,
                  placeId: place.placeId,
                  lat: place.lat,
                  lng: place.lng,
                  name: place.name,
                );
                showSendToSheet(msg);
              },
              child: CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xff703A8B),
                child: Icon(Icons.send, color: Colors.white, size: 20.sp),
              ),
            ),
            if (_hasValidCoordinates()) ...[
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: () => _navigateToRoute(),
                child: CircleAvatar(
                  radius: 22.r,
                  backgroundColor: const Color(0xff703A8B),
                  child: Icon(Icons.directions, color: Colors.white, size: 22.sp),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: const [0.2, 0.6],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Top Image (always from place card) ---
              GestureDetector(
                onTap: () {
                  final imgs = _allImages();
                  if (imgs.isEmpty) return;
                  Get.to(
                    () => ImageViewerScreen(images: imgs, initialIndex: 0),
                    transition: Transition.fadeIn,
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 300.h,
                  child: place.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.photoUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const ShimmerPlaceholder(),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // --- Name and Rating Row ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18.sp,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                place.rating.toString(),
                                style: GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                " (${place.userRatingsTotal})",
                                style: GoogleFonts.notoSans(
                                  color: Colors.white54,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // --- Status & Price (from API) ---
                    if (detail?.status != null || detail?.priceRange != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Row(
                          children: [
                            if (detail?.status != null) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      detail!.status!.toLowerCase().contains(
                                            'open',
                                          )
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  detail.status!,
                                  style: GoogleFonts.notoSans(
                                    color:
                                        detail.status!.toLowerCase().contains(
                                              'open',
                                            )
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ],
                            if (detail?.priceRange != null)
                              Text(
                                detail!.priceRange!,
                                style: GoogleFonts.notoSans(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // --- Address ---
                    Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              place.address,
                              style: GoogleFonts.notoSans(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Distance ---
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: Colors.blueAccent,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            distanceText,
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Tabs (Overview | Photos) ---
                    Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTabItem("Overview", 0),
                            _buildTabItem("Photos", 1),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    SizedBox(height: 12.h),

                    // --- Photos tab content ---
                    if (_selectedTab == 1 &&
                        detail != null &&
                        detail.photos.isNotEmpty)
                      _buildPhotosGrid(detail.photos),

                    if (_selectedTab == 1 &&
                        (detail == null || detail.photos.isEmpty))
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.h),
                        child: Center(
                          child: Text(
                            "No photos available",
                            style: GoogleFonts.notoSans(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),

                    // --- Overview tab content ---
                    if (_selectedTab == 0) ...[
                      // Description (from API)
                      if (detail?.description != null &&
                          detail!.description!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Text(
                            detail.description!,
                            style: GoogleFonts.notoSans(
                              color: Colors.white60,
                              fontSize: 13.sp,
                              height: 1.5,
                            ),
                          ),
                        ),

                      // Sections chips
                      if (detail != null && detail.sections.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: _buildChipSection(
                            "Sections",
                            detail.sections,
                            const Color(0xff704EF9),
                          ),
                        ),

                      // Cuisine chips
                      if (detail != null && detail.cuisine.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: _buildChipSection(
                            "Cuisine",
                            detail.cuisine,
                            Colors.orangeAccent,
                          ),
                        ),

                      // Services chips
                      if (detail != null && detail.services.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: _buildChipSection(
                            "Services",
                            detail.services,
                            Colors.tealAccent,
                          ),
                        ),

                      if (_isLoading) _buildDetailShimmer(),

                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child:
                            const Divider(color: Colors.white24, thickness: 1),
                      ),

                      // Points Reward Box
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff704EF9).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xff704EF9).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Rewards for Check-in",
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  "assets/Images/skcoin.png",
                                  scale: 2,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  "+${compactNumber(place.points)}",
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xffFAC139),
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Phone & Website
                      if (detail?.phone != null || detail?.website != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            children: [
                              if (detail?.phone != null) ...[
                                Icon(
                                  Icons.phone,
                                  color: Colors.white54,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  detail!.phone!,
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white70,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                              ],
                              if (detail?.website != null) ...[
                                Icon(
                                  Icons.language,
                                  color: Colors.white54,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    detail!.website!,
                                    style: GoogleFonts.notoSans(
                                      color: Colors.blueAccent,
                                      fontSize: 13.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Opening Hours
                      if (detail != null && detail.weekdayText.isNotEmpty)
                        _buildOpeningHours(detail.weekdayText),

                      // Reviews
                      if (detail != null && detail.reviews.isNotEmpty)
                        _buildReviewsSection(detail.reviews),
                    ],

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 14.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: 200.w,
              height: 14.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 14.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: List.generate(
                4,
                (_) => Container(
                  width: 80.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: List.generate(
                3,
                (_) => Container(
                  width: 70.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: isSelected ? const Color(0xffC574F7) : Colors.grey,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          if (isSelected)
            Container(
              height: 3.h,
              width: 70.w,
              color: const Color(0xffB166DE),
            )
          else
            SizedBox(height: 3.h, width: 70.w),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 8.h),
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openViewerAt(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: photos[index],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black12),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  List<String> _allImages() {
    // When the detail endpoint returns its own photos[], treat that as the
    // canonical gallery — its first item is the same photo as the hero
    // (place.photoUrl), just served via a different URL, so prepending the
    // hero would duplicate. Fall back to the hero only if photos[] empty.
    final photos = _detail?.photos ?? const <String>[];
    final filtered = photos.where((p) => p.isNotEmpty).toList();
    if (filtered.isNotEmpty) return filtered;
    final hero = widget.place.photoUrl;
    return hero.isNotEmpty ? [hero] : const [];
  }

  void _openViewerAt(int index) {
    final imgs = _allImages();
    if (imgs.isEmpty) return;
    final safeIndex = index.clamp(0, imgs.length - 1);
    Get.to(
      () => ImageViewerScreen(images: imgs, initialIndex: safeIndex),
      transition: Transition.fadeIn,
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

  Widget _buildOpeningHours(List<String> weekdayText) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Opening Hours",
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          ...weekdayText.map(
            (day) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                day,
                style: GoogleFonts.notoSans(
                  color: Colors.white60,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
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
