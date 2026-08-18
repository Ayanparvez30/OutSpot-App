import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';

/// The seven category pills above the feed, in the redesign's order.
///
/// `key` matches what the backend already accepts on
/// `/api/explore/category/:key/places`, so the pills drive the existing
/// endpoints unchanged — except `dessert`, which has no server-side category
/// yet (its Google types currently live inside `cafes`). It's listed here
/// because the design calls for it; selecting it needs the backend entry added
/// before it returns anything.
enum ExploreCategory {
  trending('trending', 'Trending', ExploreIcons.pillTrending),
  restaurants('restaurants', 'Restaurants', ExploreIcons.pillRestaurants),
  cafes('cafes', 'Cafés', ExploreIcons.pillCafes),
  bars('bars', 'Bars', ExploreIcons.pillBars),
  dessert('dessert', 'Dessert', ExploreIcons.pillDessert),
  outdoors('outdoors', 'Outdoors', ExploreIcons.pillOutdoors),
  venueEvents('venue-events', 'Venue Events', ExploreIcons.pillVenueEvents);

  final String key;
  final String label;

  /// The pill's glyph, exported from Figma — see [ExploreIcons].
  final String icon;

  const ExploreCategory(this.key, this.label, this.icon);
}

/// Search field from the redesign — Figma 361×44, r24, fill #1E092A on a
/// #703A8B hairline.
///
/// Presentational only: it reports text changes and submissions upward so the
/// screen can keep driving `/api/explore/search`, which already works.
class ExploreSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  /// Placeholder copy. Defaults to the Explore feed's wording; the Stories tab
  /// passes its own so both fields can share one design.
  final String hintText;

  /// When set, the field becomes a button: taps fire this instead of opening a
  /// keyboard. The feed uses it to push the dedicated search screen, which is
  /// how the redesign models search.
  final VoidCallback? onTap;

  const ExploreSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
    this.onTap,
    this.hintText = 'Search spots...',
  });

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: ExploreDim.searchHeight.w,
      padding: EdgeInsets.symmetric(horizontal: ExploreDim.searchPadH.w),
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(ExploreDim.searchRadius.w),
        border: Border.all(color: ExploreColors.border, width: 1),
      ),
      child: Row(
        children: [
          ExploreIcons.svg(
            ExploreIcons.search,
            size: ExploreDim.searchIcon.w,
            color: ExploreColors.textPrimary,
          ),
          SizedBox(width: ExploreDim.searchGap.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: onTap != null,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: ExploreColors.textPrimary,
              style: ExploreText.searchField.copyWith(
                color: ExploreColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: ExploreText.searchField,
              ),
            ),
          ),
          // Clear button only once there's something to clear, as in the design.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  controller.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
                child: Padding(
                  padding: EdgeInsets.only(left: ExploreDim.searchGap.w),
                  child: Icon(
                    Icons.close,
                    size: figPx(12).w,
                    color: ExploreColors.textPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    if (onTap == null) return field;
    // Absorb taps anywhere on the pill, not just on the text itself.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: field),
    );
  }
}

/// The horizontal pill row. [selected] null means "no filter" — the feed then
/// shows every carousel, which is the default state in the design.
class ExploreCategoryFilter extends StatelessWidget {
  final ExploreCategory? selected;
  final ValueChanged<ExploreCategory?> onSelect;

  /// Zero when the host screen already pads its body.
  final double horizontalPadding;

  const ExploreCategoryFilter({
    super.key,
    required this.selected,
    required this.onSelect,
    this.horizontalPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    const items = ExploreCategory.values;
    return SizedBox(
      height: ExploreDim.pillHeight.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        // +1 for the leading "All" chip. Without an explicit way back, a user
        // who taps Cafés is stuck on Cafés — re-tapping the active pill works
        // but nothing on screen says so.
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: ExploreDim.pillRowGap.w),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _pill(
              label: 'All',
              icon: null,
              isOn: selected == null,
              onTap: () => onSelect(null),
            );
          }
          final c = items[i - 1];
          return _pill(
            label: c.label,
            icon: c.icon,
            isOn: selected == c,
            // Tapping the active pill also clears back to All.
            onTap: () => onSelect(selected == c ? null : c),
          );
        },
      ),
    );
  }

  Widget _pill({
    required String label,
    required String? icon,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ExploreDim.pillPadH.w),
        decoration: BoxDecoration(
          // Figma draws every pill in the same purple. The unselected state is
          // dimmed instead so the active filter is obvious at a glance.
          color:
              isOn
                  ? ExploreColors.pill
                  : ExploreColors.pill.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(ExploreDim.pillRadius.w),
          border: Border.all(
            color: isOn ? ExploreColors.textPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExploreIcons.svg(icon, size: ExploreDim.pillIcon.w),
              SizedBox(width: ExploreDim.pillGap.w),
            ],
            Text(
              label,
              style: ExploreText.pillLabel.copyWith(
                color:
                    isOn
                        ? ExploreColors.textPrimary
                        : ExploreColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
