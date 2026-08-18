import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_card.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';

/// One horizontal section of the Explore redesign — Figma's "Spot Carousel"
/// (361×281): a 28px heading row, a 12px gap, then 241px cards spaced 16 apart.
///
/// The redesign stacks nine of these ("Spots Trending This Week", "Cafés Near
/// You", …). They differ only by title and payload, so the screen owns the
/// fetching and this widget stays presentational.
class SpotCarousel extends StatelessWidget {
  final String title;
  final List<SpotCardModel> spots;

  /// Section still fetching — shows placeholder cards so the row keeps its
  /// height and the page doesn't jump as sections land.
  final bool isLoading;

  /// The heading's circle button. Null hides it, matching sections that have
  /// nothing more to show.
  final VoidCallback? onSeeAll;

  final void Function(SpotCardModel spot)? onSpotTap;
  final void Function(SpotCardModel spot)? onSave;

  /// Saved place ids. Design-only until the SavedPlace table exists.
  final Set<String> savedPlaceIds;

  /// Left/right inset. Zero when the host screen already pads its body —
  /// Explore wraps everything in a `SingleChildScrollView(padding: 16)`, and
  /// adding the Figma margin on top of that doubled the gap.
  final double horizontalPadding;

  const SpotCarousel({
    super.key,
    required this.title,
    required this.spots,
    this.isLoading = false,
    this.onSeeAll,
    this.onSpotTap,
    this.onSave,
    this.savedPlaceIds = const {},
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    // A section that finished loading with nothing in it is dropped entirely —
    // an empty carousel reads as a bug to the user.
    if (!isLoading && spots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: _heading(),
        ),
        SizedBox(height: ExploreDim.carouselGap.w),
        SizedBox(height: ExploreDim.cardHeight.w, child: _items()),
      ],
    );
  }

  Widget _heading() {
    return SizedBox(
      height: ExploreDim.headingHeight.w,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ExploreText.heading,
            ),
          ),
          if (onSeeAll != null) ...[
            SizedBox(width: ExploreDim.carouselGap.w),
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                width: ExploreDim.circleButton.w,
                height: ExploreDim.circleButton.w,
                decoration: BoxDecoration(
                  color: ExploreColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: ExploreColors.border, width: 1),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: ExploreDim.circleButtonIcon.w,
                  color: ExploreColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _items() {
    final count = isLoading && spots.isEmpty ? 3 : spots.length;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(width: ExploreDim.carouselItemGap.w),
      itemBuilder: (_, i) {
        if (isLoading && spots.isEmpty) return const _SkeletonCard();
        final spot = spots[i];
        return SpotCard(
          spot: spot,
          isSaved: savedPlaceIds.contains(spot.placeId),
          onTap: onSpotTap == null ? null : () => onSpotTap!(spot),
          onSave: onSave == null ? null : () => onSave!(spot),
        );
      },
    );
  }
}

/// Same footprint as a real card so the row doesn't resize when data lands.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ExploreDim.cardWidth.w,
      height: ExploreDim.cardHeight.w,
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(ExploreDim.cardRadius.w),
        border: Border.all(color: ExploreColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: ExploreDim.cardImageHeight.w,
            color: ExploreColors.border.withValues(alpha: 0.25),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              ExploreDim.cardInfoPadH.w,
              ExploreDim.cardInfoPadTop.w,
              ExploreDim.cardInfoPadH.w,
              ExploreDim.cardInfoPadBottom.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(figPx(140), figPx(14)),
                SizedBox(height: ExploreDim.cardRowGap.w * 3),
                _bar(figPx(180), figPx(10)),
                SizedBox(height: ExploreDim.cardRowGap.w * 3),
                _bar(figPx(120), figPx(10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double w, double h) => Container(
    width: w.w,
    height: h.w,
    decoration: BoxDecoration(
      color: ExploreColors.border.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(4.r),
    ),
  );
}
