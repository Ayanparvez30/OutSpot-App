import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_search_and_filters.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_card.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_carousel.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_feed_controller.dart';

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

  void _openSpot(SpotCardModel spot) {
    if (spot.placeId.isEmpty) return;
    // Reuses the existing place-detail route so the card behaves like every
    // other place entry point in the app.
    Get.toNamed(Routes.placeDetails, arguments: {'placeId': spot.placeId});
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
            onChanged: c.onSearchChanged,
            onSubmitted: c.runSearch,
            onClear: c.clearSearch,
          ),
        ),
        SizedBox(height: ExploreDim.carouselItemGap.w),
        ExploreCategoryFilter(
          horizontalPadding: _pad,
          selected: c.selectedCategory.value,
          onSelect: (cat) {
            c.selectCategory(cat);
            // Keep an active search in step with the new filter.
            if (c.searchQuery.value.trim().isNotEmpty) {
              c.runSearch(c.searchQuery.value);
            }
          },
        ),
        SizedBox(height: figPx(20).w),
        if (c.searchQuery.value.trim().isNotEmpty)
          _searchResults()
        else
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
            onSpotTap: _openSpot,
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

  Widget _searchResults() {
    return Obx(() {
      if (c.searching.value && c.searchResults.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: figPx(32).w),
          child: const Center(
            child: CircularProgressIndicator(color: ExploreColors.gold),
          ),
        );
      }
      if (c.searchResults.isEmpty) {
        return _emptyNote(
          'No spots found',
          'Try a different search or category.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _pad),
            child: Text(
              'Results for "${c.searchQuery.value.trim()}"',
              style: ExploreText.heading,
            ),
          ),
          SizedBox(height: ExploreDim.carouselGap.w),
          // Results use the same card, stacked instead of scrolled sideways —
          // a full-width list reads better than a carousel for search.
          for (final spot in c.searchResults)
            Padding(
              padding: EdgeInsets.fromLTRB(
                _pad,
                0,
                _pad,
                ExploreDim.carouselItemGap.w,
              ),
              child: SpotCard(
                spot: spot,
                isSaved: c.savedPlaceIds.contains(spot.placeId),
                onTap: () => _openSpot(spot),
                onSave: () => c.toggleSaved(spot),
              ),
            ),
        ],
      );
    });
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
