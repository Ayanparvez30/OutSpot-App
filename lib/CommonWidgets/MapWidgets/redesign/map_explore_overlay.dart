import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_search_and_filters.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_saved_screen.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_search_screen.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

/// Search field + category pills floating over the map — Figma's "Search
/// Container" inside the MAP frame (node 7319:14959), 393×92 with an 8px gap.
///
/// Deliberately built from the same [ExploreSearchField] and pill styling the
/// Explore feed uses, so the two screens can't drift apart: the map is the same
/// catalogue seen from above, and it should look like it.
///
/// The map's own filtering is untouched — tapping a pill still calls
/// [MapController.filterRestaurantsByCategory] with the same lowercase key it
/// always received, so markers behave exactly as before.
class MapExploreOverlay extends StatelessWidget {
  final MapController controller;

  /// A dummy controller: the field on the map is a button, not an input. It
  /// pushes the Explore search screen rather than typing in place, which is how
  /// the redesign models search everywhere.
  static final TextEditingController _searchProxy = TextEditingController();

  const MapExploreOverlay({super.key, required this.controller});

  /// Pills in the redesign's order, plus "Saved Spots" — the map is the one
  /// place Figma adds it to the row.
  static const List<(String label, String key, String icon)> _pills = [
    ('Trending', 'trending', ExploreIcons.pillTrending),
    ('Restaurants', 'restaurants', ExploreIcons.pillRestaurants),
    ('Cafés', 'cafes', ExploreIcons.pillCafes),
    ('Bars', 'bars', ExploreIcons.pillBars),
    ('Dessert', 'dessert', ExploreIcons.pillDessert),
    ('Outdoors', 'outdoors', ExploreIcons.pillOutdoors),
    ('Venue Events', 'venue events', ExploreIcons.pillVenueEvents),
    ('Saved Spots', '__saved__', ExploreIcons.cardSave),
  ];

  void _openSearch() {
    final pos = controller.currentPos.value;
    Get.to(
      () => ExploreSearchScreen(
        // The search endpoint needs a centre; 0/0 simply returns no distances
        // rather than failing, so a missing fix doesn't block search.
        lat: pos?.latitude ?? 0,
        lng: pos?.longitude ?? 0,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: figPx(8).w,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ExploreDim.pageMargin.w),
            child: ExploreSearchField(
              controller: _searchProxy,
              onTap: _openSearch,
            ),
          ),
          SizedBox(height: figPx(8).w),
          SizedBox(height: ExploreDim.pillHeight.w, child: _pillRow()),
        ],
      ),
    );
  }

  Widget _pillRow() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: ExploreDim.pageMargin.w),
      itemCount: _pills.length,
      separatorBuilder: (_, __) => SizedBox(width: ExploreDim.pillRowGap.w),
      itemBuilder: (_, i) {
        final (label, key, icon) = _pills[i];
        return Obx(() {
          final isOn = controller.selectedCategory.value == key;
          return GestureDetector(
            onTap: () {
              if (key == '__saved__') {
                Get.to(
                  () => const ExploreSavedScreen(),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 220),
                );
                return;
              }
              // Tapping the active pill clears the filter, matching the feed.
              // Routed through the controller's own reset rather than a blank
              // category key, which would have fired a request for "" and
              // wiped the markers on a server error instead of on purpose.
              isOn
                  ? controller.clearRestaurantSearch()
                  : controller.filterRestaurantsByCategory(key);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: ExploreDim.pillPadH.w),
              decoration: BoxDecoration(
                // Same dimmed-when-inactive treatment as the Explore pills.
                color:
                    isOn
                        ? ExploreColors.pill
                        : ExploreColors.pill.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(ExploreDim.pillRadius.w),
                border: Border.all(
                  color: isOn ? ExploreColors.textPrimary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExploreIcons.svg(icon, size: ExploreDim.pillIcon.w),
                  SizedBox(width: ExploreDim.pillGap.w),
                  Text(label, style: ExploreText.pillLabel),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
