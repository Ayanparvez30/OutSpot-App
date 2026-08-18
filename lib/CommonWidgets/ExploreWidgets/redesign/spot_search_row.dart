import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';

/// A single search result — Figma "Search Result" (node 7319:14621), 361×76.
///
/// Deliberately not the carousel card: search shows many results at once, so
/// the design switches to a compact row.
///
/// ```
/// ┌──────┐  The Flatiron Room Murray Hill              w600 12px  ┌────┐
/// │ 🕐   │  $$$$ · 🍽 American · Open · ★4.5 (1,263) · ♿   w400 12px│ Ⓟ50│
/// │0.6 mi│  9 E 37th St, New York, NY 10016            w400 10px  └────┘
/// └──────┘
///   52px            242px wide info block                     43×20
/// ```
class SpotSearchRow extends StatelessWidget {
  /// Figma draws the row at 76px with a 52px circle. Trimmed slightly on
  /// request so more results fit a handset screen; one number tunes the row.
  static const double _scale = 0.88;

  final SpotCardModel spot;
  final VoidCallback? onTap;

  const SpotSearchRow({super.key, required this.spot, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: figPx(76 * _scale).w,
        // Figma outlines each row; a bottom hairline reads better than a full
        // box in a long list.
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ExploreColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            _leading(),
            SizedBox(width: figPx(12).w),
            Expanded(child: _info()),
            if (spot.points > 0) ...[
              SizedBox(width: figPx(12).w),
              _pointsBadge(),
            ],
          ],
        ),
      ),
    );
  }

  /// The 52px circle on the left.
  ///
  /// Figma fills it with a clock glyph over the distance, but a search result
  /// is far easier to recognise by its photo — so the photo takes the circle
  /// and the distance rides along the bottom on a scrim. Places Google has no
  /// photo for fall back to the designed clock treatment.
  Widget _leading() {
    final size = figPx(52 * _scale).w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ExploreColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          spot.photoUrl.isEmpty
              ? _clockFallback()
              : Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: spot.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => _clockFallback(),
                  ),
                  if (spot.distanceLabel.isNotEmpty)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: figPx(2).w),
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Text(
                          spot.distanceLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: ExploreText.friendsSpotted.copyWith(
                            color: ExploreColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  /// Figma's original treatment, kept for places with no photo.
  Widget _clockFallback() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.schedule,
        size: figPx(18).w,
        color: ExploreColors.textPrimary,
      ),
      SizedBox(height: figPx(2).w),
      Text(
        spot.distanceLabel.isEmpty ? '—' : spot.distanceLabel,
        maxLines: 1,
        style: ExploreText.friendsSpotted.copyWith(
          color: ExploreColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          spot.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ExploreText.meta.copyWith(
            color: ExploreColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: figPx(2).w),
        _metaLine(),
        if (spot.address.isNotEmpty) ...[
          SizedBox(height: figPx(2).w),
          Text(
            spot.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExploreText.friendsSpotted,
          ),
        ],
      ],
    );
  }

  /// `$$$$ · 🍽 American · Open · ★4.5 (1,263) · ♿` — every piece optional, and
  /// the `·` between two pieces only appears when both survive.
  Widget _metaLine() {
    final parts = <Widget>[
      if (spot.priceRange.isNotEmpty)
        Text(spot.priceRange, maxLines: 1, style: ExploreText.meta),
      if (spot.typeLabel.isNotEmpty) _tag(spot.typeLabel),
      if (spot.openNow != null)
        Text(
          spot.openNow! ? 'Open' : 'Closed',
          maxLines: 1,
          style: ExploreText.status(spot.openNow!),
        ),
      if (spot.rating > 0) _rating(),
      if (spot.accessible)
        ExploreIcons.svg(
          ExploreIcons.cardAccessible,
          size: ExploreDim.metaIcon.w,
          // Figma tints the glyph teal in the search row, unlike on the card.
          color: const Color(0xFF66FFE8),
        ),
    ];

    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: figPx(4).w),
            child: Text('·', style: ExploreText.meta),
          ),
        );
      }
      // Natural width, not an equal share: making every piece Flexible splits
      // the row evenly and ellipsises the review count while "$$" sits on
      // spare space.
      children.add(parts[i]);
    }
    // Only the whole line scales, and only when it genuinely doesn't fit.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _tag(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExploreIcons.svg(
        ExploreIcons.pillRestaurants,
        size: ExploreDim.metaIcon.w,
      ),
      SizedBox(width: figPx(2).w),
      Text(label, maxLines: 1, style: ExploreText.meta),
    ],
  );

  Widget _rating() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExploreIcons.svg(
        ExploreIcons.cardRatingStar,
        size: ExploreDim.metaIcon.w,
      ),
      SizedBox(width: figPx(2).w),
      Text(spot.rating.toStringAsFixed(1), style: ExploreText.rating),
      if (spot.reviewCount > 0) ...[
        SizedBox(width: figPx(2).w),
        Text('(${spot.reviewCountLabel})', maxLines: 1, style: ExploreText.meta),
      ],
    ],
  );

  Widget _pointsBadge() => Container(
    height: ExploreDim.badgeHeight.w,
    padding: EdgeInsets.symmetric(horizontal: ExploreDim.badgePadH.w),
    decoration: BoxDecoration(
      color: ExploreColors.pointsBadgeFill,
      borderRadius: BorderRadius.circular(ExploreDim.badgeHeight.w),
      border: Border.all(color: ExploreColors.pointsBadgeBorder, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExploreIcons.svg(ExploreIcons.cardPoints, size: ExploreDim.metaIcon.w),
        SizedBox(width: ExploreDim.badgeGap.w),
        Text(
          '${spot.points}',
          style: ExploreText.meta.copyWith(
            color: ExploreColors.pointsText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
