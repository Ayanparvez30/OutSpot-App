import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_background.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_card.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Network_Manager/redesign/explore_feed_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/Explore_Category/explore_category_controller.dart'
    show PlaceSort;
import 'package:outspot/Views/Explore_Category/placeDetailsScreen.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_feed_controller.dart';

/// "EXPLORE - Expanded Category" (Figma node 7319:14519) — the screen behind a
/// carousel heading's arrow.
///
/// The feed only previews three cards per section; this is the whole list.
/// Same [SpotCard], drawn at Figma's full-width 361×249 with a 140px photo
/// instead of the carousel's 240×241.
class ExploreExpandedCategory extends StatefulWidget {
  /// Section key the feed used — `trending`, `friends-visited`, `points-boost`,
  /// or a plain category (`cafes`, `bars`, …).
  final String sectionKey;

  /// Heading copy, reused verbatim as the screen title.
  final String title;

  final double lat;
  final double lng;

  const ExploreExpandedCategory({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.lat,
    required this.lng,
  });

  @override
  State<ExploreExpandedCategory> createState() =>
      _ExploreExpandedCategoryState();
}

class _ExploreExpandedCategoryState extends State<ExploreExpandedCategory> {
  /// Full list size. The feed asks for three; here the point is to see them all.
  static const int _pageSize = 20;

  /// Figma's expanded card runs 361×249 with a 140px photo, which reads a touch
  /// heavy on a real handset — barely two cards fit the screen. Trimmed to this
  /// fraction on request; raise it back toward 1.0 to return to the drawing.
  static const double _cardScale = 0.88;

  final List<SpotCardModel> _spots = [];
  bool _loading = true;

  /// Reuses [PlaceSort] from the old category screen rather than inventing a
  /// second set of options, so both screens offer the user the same five
  /// choices and mean the same thing by each.
  PlaceSort _sort = PlaceSort.nearest;

  /// Shared with the feed rather than kept locally: bookmarking here has to
  /// reach the server and be reflected back on the carousels, which a private
  /// Set never did — the old local one only changed the icon on this screen
  /// and forgot it on the way back.
  late final ExploreFeedController _feed =
      Get.isRegistered<ExploreFeedController>()
          ? Get.find<ExploreFeedController>()
          : Get.put(ExploreFeedController());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final spots = switch (widget.sectionKey) {
      'trending' => await ExploreFeedService.trendingThisWeek(
        lat: widget.lat,
        lng: widget.lng,
        limit: _pageSize,
      ),
      'friends-visited' => await ExploreFeedService.friendsVisited(
        lat: widget.lat,
        lng: widget.lng,
        limit: _pageSize,
      ),
      'points-boost' => await ExploreFeedService.pointsBoost(
        lat: widget.lat,
        lng: widget.lng,
        limit: _pageSize,
      ),
      _ => await ExploreFeedService.category(
        key: widget.sectionKey,
        title: widget.title,
        lat: widget.lat,
        lng: widget.lng,
        pageSize: _pageSize,
      ),
    };
    if (!mounted) return;
    setState(() {
      _spots
        ..clear()
        ..addAll(spots);
      _loading = false;
    });
  }

  /// The list in the order the active sort asks for. Mirrors
  /// `ExploreCategoryController.displayedPlaces` exactly — same comparisons,
  /// same tie-breaks — so a place ranked third there ranks third here.
  List<SpotCardModel> get _sorted {
    final list = _spots.toList();
    switch (_sort) {
      case PlaceSort.nearest:
        list.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      case PlaceSort.farthest:
        list.sort((a, b) => b.distanceMiles.compareTo(a.distanceMiles));
      case PlaceSort.trending:
        // Proxy for "trending on Google": most-reviewed first, then top rated.
        list.sort((a, b) {
          final byReviews = b.reviewCount.compareTo(a.reviewCount);
          if (byReviews != 0) return byReviews;
          return b.rating.compareTo(a.rating);
        });
      case PlaceSort.pointsHigh:
        list.sort((a, b) => b.points.compareTo(a.points));
      case PlaceSort.pointsLow:
        list.sort((a, b) => a.points.compareTo(b.points));
      case PlaceSort.none:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final pad = ExploreDim.pageMargin.w;
    final sorted = _sorted;
    return ExploreBackground(
      child: Column(
          children: [
            _header(pad),
            Expanded(
              child:
                  _loading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: ExploreColors.gold,
                        ),
                      )
                      : _spots.isEmpty
                      ? _empty()
                      : RefreshIndicator(
                        onRefresh: _load,
                        color: ExploreColors.gold,
                        backgroundColor: ExploreColors.surface,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, figPx(24).w),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: sorted.length,
                          separatorBuilder:
                              (_, __) =>
                                  SizedBox(height: ExploreDim.carouselItemGap.w),
                          itemBuilder: (_, i) {
                            final s = sorted[i];
                            return Obx(
                              () => SpotCard(
                                spot: s,
                                // Figma's expanded card: full width, 140px.
                                width: double.infinity,
                                imageHeight: figPx(140 * _cardScale).w,
                                isSaved: _feed.savedPlaceIds.contains(
                                  s.placeId,
                                ),
                                onSave: () => _feed.toggleSaved(s),
                                onTap: () => _openSpot(s),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Opens the same [PlaceDetailsScreen] the old Explore category list opened,
  /// with the same four arguments and the same `routeName`.
  ///
  /// That naming is load-bearing: the "Too Far" check-in dialog and the submit
  /// flow both pop back to `Routes.placeDetails`, so pushing this screen any
  /// other way would strand the user. `userLat`/`userLng` are equally required
  /// — the screen fetches nothing without them and renders blank.
  void _openSpot(SpotCardModel spot) {
    if (spot.placeId.isEmpty) return;
    Get.to(
      () => PlaceDetailsScreen(
        place: spot.toExplorePlace(),
        categoryKey: widget.sectionKey,
        userLat: widget.lat,
        userLng: widget.lng,
      ),
      routeName: Routes.placeDetails,
    );
  }

  /// Back chevron + title, matching Figma's 54px "Heading Top Nav Bar".
  Widget _header(double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, figPx(8).w, pad, figPx(12).w),
      child: SizedBox(
        height: figPx(54).w,
        // Stack, not a Row: the title centres on the screen rather than in
        // whatever space the back button leaves over.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              // Keeps a long title clear of the back glyph on both sides.
              padding: EdgeInsets.symmetric(horizontal: figPx(48).w),
              child: Text(
                widget.title,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: ExploreText.heading.copyWith(fontSize: figPx(18).sp),
              ),
            ),
            // The app's own back glyph, as every other pushed screen uses.
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 35,
                child: CustomBackButton()),
            ),
            // Sort — the dot marks a non-default order, the same cue the old
            // category screen gives.
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showSortSheet,
                child: Padding(
                  padding: EdgeInsets.all(figPx(4).w),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.tune,
                        color: ExploreColors.textPrimary,
                        size: figPx(24).w,
                      ),
                      if (_sort != PlaceSort.nearest)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: figPx(8).w,
                            height: figPx(8).w,
                            decoration: const BoxDecoration(
                              color: Color(0xffFAC139),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same five options, same copy and the same sheet styling as the old
  /// category screen, so the two read as one feature rather than two.
  void _showSortSheet() {
    const options = <(String, IconData, PlaceSort)>[
      ('Nearest first', Icons.near_me, PlaceSort.nearest),
      ('Farthest first', Icons.social_distance, PlaceSort.farthest),
      ('Trending (Google)', Icons.trending_up, PlaceSort.trending),
      ('Points: High to Low', Icons.arrow_downward, PlaceSort.pointsHigh),
      ('Points: Low to High', Icons.arrow_upward, PlaceSort.pointsLow),
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xff1A0420),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: const Color(0xff683381), width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort by',
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              ...options.map((o) {
                final selected = _sort == o.$3;
                final color = selected ? const Color(0xffC574F7) : Colors.white;
                return ListTile(
                  dense: true,
                  leading: Icon(o.$2, color: color, size: 22.sp),
                  title: Text(
                    o.$1,
                    style: GoogleFonts.notoSans(
                      color: color,
                      fontSize: 14.sp,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w400,
                    ),
                  ),
                  trailing:
                      selected
                          ? const Icon(Icons.check, color: Color(0xffC574F7))
                          : null,
                  onTap: () {
                    setState(() => _sort = o.$3);
                    Get.back();
                  },
                );
              }),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: ExploreDim.pageMargin.w),
      child: Text(
        'Nothing here yet.',
        textAlign: TextAlign.center,
        style: ExploreText.meta,
      ),
    ),
  );
}
