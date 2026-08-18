import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_search_and_filters.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_carousel.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explore_Category/placeDetailsScreen.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_expanded_category.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_feed_controller.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_search_screen.dart';

/// The redesigned Explore feed body: search field, seven category pills, then
/// the carousels — Figma "EXPLORE" frame, node 7319:14445.
///
/// This is the new design living beside the old one. The existing
/// [Views/Explorescreen/explore.dart] screen is untouched, so switching back is
/// a matter of rendering that instead of this.
///
/// Drop it into a screen that already provides the purple background, the top
/// nav bar and the bottom tab bar — it renders the feed only, exactly the part
/// the redesign covers.
class ExploreFeedRedesign extends StatefulWidget {
  /// True when the feed is dropped into a parent that already scrolls — the
  /// current Explore screen wraps its whole body in a `SingleChildScrollView`.
  /// It then lays out as a plain Column: nesting a vertical ListView inside
  /// another vertical scrollable throws on unbounded height.
  ///
  /// Standalone (false) it owns its own ListView and pull-to-refresh.
  final bool embedded;

  const ExploreFeedRedesign({super.key, this.embedded = false});

  @override
  State<ExploreFeedRedesign> createState() => _ExploreFeedRedesignState();
}

class _ExploreFeedRedesignState extends State<ExploreFeedRedesign> {
  final TextEditingController _search = TextEditingController();
  late final ExploreFeedController c;

  @override
  void initState() {
    super.initState();
    c =
        Get.isRegistered<ExploreFeedController>()
            ? Get.find<ExploreFeedController>()
            : Get.put(ExploreFeedController());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Zero when embedded: the host screen already applies its own horizontal
  /// padding, so re-applying the Figma margin doubled the gap on both sides.
  double get _pad => widget.embedded ? 0 : ExploreDim.pageMargin.w;

  /// The heading arrow — full list for one section.
  void _openSection(String sectionKey, String title) {
    final lat = c.lat, lng = c.lng;
    if (lat == null || lng == null) return;
    Get.to(
      () => ExploreExpandedCategory(
        sectionKey: sectionKey,
        title: title,
        lat: lat,
        lng: lng,
      ),
    );
  }

  void _openSearch() {
    final lat = c.lat, lng = c.lng;
    if (lat == null || lng == null) return;
    Get.to(
      () => ExploreSearchScreen(
        lat: lat,
        lng: lng,
        category: c.selectedCategory.value?.key ?? 'all',
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
  void _openSpot(SpotCardModel spot, String categoryKey) {
    if (spot.placeId.isEmpty) return;
    final lat = c.lat, lng = c.lng;
    Get.to(
      () => PlaceDetailsScreen(
        place: spot.toExplorePlace(),
        categoryKey: categoryKey,
        userLat: lat,
        userLng: lng,
      ),
      routeName: Routes.placeDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.locating.value) {
        return Padding(
          padding: EdgeInsets.only(top: figPx(48).w),
          child: const Center(
            child: CircularProgressIndicator(color: ExploreColors.gold),
          ),
        );
      }

      if (c.locationError.value.isNotEmpty) {
        return _locationErrorState();
      }

      final children = <Widget>[
        // Breathing room between the stories row and the search field.
        SizedBox(height: figPx(12).w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _pad),
          child: ExploreSearchField(
            controller: _search,
            // Tapping opens the dedicated search screen, as in the redesign,
            // rather than searching inline.
            onTap: _openSearch,
          ),
        ),
        SizedBox(height: ExploreDim.carouselItemGap.w),
        ExploreCategoryFilter(
          horizontalPadding: _pad,
          selected: c.selectedCategory.value,
          onSelect: c.selectCategory,
        ),
        SizedBox(height: figPx(20).w),
        ..._feed(),
      ];

      if (widget.embedded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      }

      return RefreshIndicator(
        onRefresh: c.refreshFeed,
        color: ExploreColors.gold,
        backgroundColor: ExploreColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: figPx(24).w),
          children: children,
        ),
      );
    });
  }

  List<Widget> _feed() {
    final visible = c.visibleSections;

    if (visible.isEmpty) {
      return [
        _emptyNote(
          'Nothing to show for this filter yet.',
          'This category has no feed on the server yet.',
        ),
      ];
    }

    return [
      for (final s in visible)
        Obx(() {
          final carousel = SpotCarousel(
            title: s.title,
            spots: s.spots,
            isLoading: s.loading.value,
            savedPlaceIds: c.savedPlaceIds,
            horizontalPadding: _pad,
            onSeeAll: () => _openSection(s.categoryKey, s.title),
            onSpotTap: (spot) => _openSpot(spot, s.categoryKey),
            onSave: c.toggleSaved,
          );
          // SpotCarousel collapses itself when a finished section is empty, so
          // the spacer must collapse with it or the feed grows blank gaps.
          if (!s.loading.value && s.spots.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(bottom: figPx(24).w),
            child: carousel,
          );
        }),
    ];
  }

  Widget _emptyNote(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _pad, vertical: figPx(32).w),
      child: Column(
        children: [
          Text(title, style: ExploreText.spotName),
          SizedBox(height: figPx(6).w),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ExploreText.meta,
          ),
        ],
      ),
    );
  }

  Widget _locationErrorState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _pad, vertical: figPx(40).w),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: figPx(32).w,
            color: ExploreColors.textMuted,
          ),
          SizedBox(height: figPx(12).w),
          Text('Location unavailable', style: ExploreText.spotName),
          SizedBox(height: figPx(6).w),
          Text(
            'Explore needs your location to find spots near you.',
            textAlign: TextAlign.center,
            style: ExploreText.meta,
          ),
          SizedBox(height: figPx(16).w),
          GestureDetector(
            onTap: c.refreshFeed,
            child: Container(
              height: ExploreDim.pillHeight.w,
              padding: EdgeInsets.symmetric(horizontal: ExploreDim.pillPadH.w),
              decoration: BoxDecoration(
                color: ExploreColors.pill,
                borderRadius: BorderRadius.circular(ExploreDim.pillRadius.w),
              ),
              alignment: Alignment.center,
              child: Text('Try again', style: ExploreText.pillLabel),
            ),
          ),
        ],
      ),
    );
  }
}
