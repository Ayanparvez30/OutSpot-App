import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';

/// One Spot Card from the Explore redesign — Figma node `7319:13947`,
/// 240×241 inside the "Spot Carousel" component.
///
/// Layout, top to bottom, exactly as Figma reports it:
///
/// ```
/// ┌─ 240×132 photo, top corners r16, black 50%→0% scrim ──────┐
/// │  points badge (8,12)                    save button (204,8)│
/// ├─ 240×109 info, pad 12/8/12/12, row gap 2 ─────────────────┤
/// │  Spot Name                                       w600 14px │
/// │  Tag · Tag · 0.2 mi                              w400 12px │
/// │  $ · Open · ★4.4 (449) · ♿                       w400 12px │
/// │  (avatars) SamR7 and 2 others were spotted here   w400 10px │
/// └────────────────────────────────────────────────────────────┘
/// ```
///
/// Every row degrades on its own: a place with no rating, no price band, no
/// opening hours or no friends drops just that piece — including the `·`
/// separator that would otherwise dangle — instead of leaving a gap or
/// rendering "0.0" placeholders.
class SpotCard extends StatelessWidget {
  final SpotCardModel spot;
  final VoidCallback? onTap;

  /// Save/bookmark is design-only for now: there is no SavedPlace table or
  /// endpoint behind it yet, so the host decides what [isSaved] means and
  /// whether [onSave] does anything. Wiring it up is the migration step.
  final bool isSaved;
  final VoidCallback? onSave;

  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.isSaved = false,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [_photo(), Expanded(child: _info())],
        ),
      ),
    );
  }

  // ── photo ────────────────────────────────────────────────────────────────

  Widget _photo() {
    return SizedBox(
      width: ExploreDim.cardWidth.w,
      height: ExploreDim.cardImageHeight.w,
      child: Stack(
        children: [
          Positioned.fill(
            child:
                spot.photoUrl.isEmpty
                    ? Container(color: ExploreColors.border.withValues(alpha: 0.25))
                    : CachedNetworkImage(
                      imageUrl: spot.photoUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Container(
                            color: ExploreColors.border.withValues(alpha: 0.25),
                          ),
                      errorWidget:
                          (_, __, ___) => Container(
                            color: ExploreColors.border.withValues(alpha: 0.25),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: figPx(24).w,
                              color: ExploreColors.textMuted,
                            ),
                          ),
                    ),
          ),
          // Scrim so the white badge text stays legible over bright photos.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (spot.points > 0)
            Positioned(
              left: ExploreDim.badgeLeft.w,
              top: ExploreDim.badgeTop.w,
              child: _pointsBadge(),
            ),
          Positioned(
            right: ExploreDim.saveRight.w,
            top: ExploreDim.saveTop.w,
            child: _saveButton(),
          ),
        ],
      ),
    );
  }

  Widget _pointsBadge() {
    return Container(
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
          ExploreIcons.svg(
            ExploreIcons.cardPoints,
            size: ExploreDim.metaIcon.w,
          ),
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

  Widget _saveButton() {
    return GestureDetector(
      onTap: onSave,
      child: Container(
        width: ExploreDim.circleButton.w,
        height: ExploreDim.circleButton.w,
        decoration: BoxDecoration(
          color: ExploreColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: ExploreColors.border, width: 1),
        ),
        child: Center(
          child: ExploreIcons.svg(
            ExploreIcons.cardSave,
            size: ExploreDim.circleButtonIcon.w,
            color: isSaved ? ExploreColors.gold : ExploreColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── info ─────────────────────────────────────────────────────────────────

  Widget _info() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ExploreDim.cardInfoPadH.w,
        ExploreDim.cardInfoPadTop.w,
        ExploreDim.cardInfoPadH.w,
        ExploreDim.cardInfoPadBottom.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Fills the height the card gives it — the Expanded friends row below
        // needs a bounded box to flex into.
        children: [
          Text(
            spot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExploreText.spotName,
          ),
          SizedBox(height: ExploreDim.cardRowGap.w),
          _infoLine1(),
          SizedBox(height: ExploreDim.cardRowGap.w),
          _infoLine2(),
          SizedBox(height: ExploreDim.cardRowGap.w),
          // Takes whatever height is left rather than demanding its own: the
          // rows above round up by fractions of a pixel, and a fixed friends
          // row turned that into a 1.6px bottom overflow.
          Expanded(child: _friendsRow()),
        ],
      ),
    );
  }

  /// `Trending · Café · 0.2 mi` — separators only appear between pieces that
  /// actually exist.
  Widget _infoLine1() {
    final parts = <Widget>[
      if (spot.category.isNotEmpty)
        _tag(_iconForLabel(spot.category), spot.category),
      if (spot.typeLabel.isNotEmpty)
        _tag(_iconForLabel(spot.typeLabel), spot.typeLabel),
      if (spot.distanceLabel.isNotEmpty)
        Text(spot.distanceLabel, style: ExploreText.meta),
    ];
    return SizedBox(
      height: ExploreDim.metaRowHeight.w,
      child: _separated(parts, ExploreDim.metaGapLine1.w),
    );
  }

  /// `$ · Open · ★ 4.4 (449) · ♿`
  Widget _infoLine2() {
    final parts = <Widget>[
      if (spot.priceRange.isNotEmpty)
        Text(spot.priceRange, style: ExploreText.meta),
      if (spot.openNow != null)
        Text(
          spot.openNow! ? 'Open' : 'Closed',
          style: ExploreText.status(spot.openNow!),
        ),
      if (spot.rating > 0) _ratingChip(),
      if (spot.accessible)
        ExploreIcons.svg(
          ExploreIcons.cardAccessible,
          size: ExploreDim.metaIcon.w,
          color: ExploreColors.textMuted,
        ),
    ];
    return SizedBox(
      height: ExploreDim.metaRowHeight.w,
      child: _separated(parts, ExploreDim.metaGapLine2.w),
    );
  }

  Widget _ratingChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ExploreIcons.svg(
          ExploreIcons.cardRatingStar,
          size: ExploreDim.metaIcon.w,
        ),
        SizedBox(width: ExploreDim.tagIconGap.w),
        Text(spot.rating.toStringAsFixed(1), style: ExploreText.rating),
        if (spot.reviewCount > 0) ...[
          SizedBox(width: ExploreDim.tagIconGap.w),
          // Shrinkable: "(2,263)" beside two long category tags is what pushed
          // the metadata row past the card's right edge.
          Flexible(
            child: Text(
              '(${_compact(spot.reviewCount)})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ExploreText.meta,
            ),
          ),
        ],
      ],
    );
  }

  /// A metadata tag. [icon] is null when nothing in the Figma set matches the
  /// label — the tag then renders as plain text rather than borrowing an
  /// unrelated glyph.
  Widget _tag(String? icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          ExploreIcons.svg(icon, size: ExploreDim.metaIcon.w),
          SizedBox(width: ExploreDim.tagIconGap.w),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExploreText.meta,
          ),
        ),
      ],
    );
  }

  /// Overlapping friend avatars (−6px in Figma) plus the spotted-here line.
  Widget _friendsRow() {
    final shown = spot.friends.take(ExploreDim.friendsPreviewMax).toList();
    final avatar = ExploreDim.friendAvatar.w;
    final step = avatar - ExploreDim.friendOverlap.w;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (shown.isEmpty)
            _avatarCircle(null)
          else
            SizedBox(
              width: step * (shown.length - 1) + avatar,
              height: avatar,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: step * i,
                      child: _avatarCircle(shown[i].avatar),
                    ),
                ],
              ),
            ),
          SizedBox(width: ExploreDim.friendsGap.w),
          Expanded(
            child: Text(
              spot.friendsLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ExploreText.friendsSpotted,
            ),
          ),
        ],
    );
  }

  Widget _avatarCircle(String? url) {
    final size = ExploreDim.friendAvatar.w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: ExploreColors.surface, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          (url == null || url.isEmpty)
              ? Icon(
                Icons.person,
                size: size * 0.6,
                color: ExploreColors.textMuted,
              )
              : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                // Minime renders are full-body; the head sits up top.
                alignment: Alignment.topCenter,
                errorWidget:
                    (_, __, ___) => Icon(
                      Icons.person,
                      size: size * 0.6,
                      color: ExploreColors.textMuted,
                    ),
              ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Joins the pieces of a metadata line with `·`, skipping the separator when
  /// a piece was dropped — a place with no rating must not render `$ · · Open`.
  Widget _separated(List<Widget> parts, double gap) {
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        children
          ..add(SizedBox(width: gap))
          ..add(Text('·', style: ExploreText.meta))
          ..add(SizedBox(width: gap));
      }
      children.add(parts[i] is Flexible ? parts[i] : Flexible(child: parts[i]));
    }
    return Row(mainAxisSize: MainAxisSize.max, children: children);
  }

  /// Figma exports the tag glyphs for Trending and Café only; the pill set
  /// covers the rest, and they're the same artwork. Anything unmatched (a
  /// Google type like "Meal Takeaway") gets no icon rather than a wrong one.
  static String? _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('trending')) return ExploreIcons.cardTrendingTag;
    if (l.contains('caf') || l.contains('coffee') || l.contains('bakery')) {
      return ExploreIcons.cardCafeTag;
    }
    if (l.contains('restaurant') || l.contains('food') || l.contains('deli')) {
      return ExploreIcons.pillRestaurants;
    }
    if (l.contains('bar') || l.contains('pub') || l.contains('brewery')) {
      return ExploreIcons.pillBars;
    }
    if (l.contains('dessert') ||
        l.contains('ice cream') ||
        l.contains('pastry') ||
        l.contains('donut') ||
        l.contains('cake') ||
        l.contains('candy')) {
      return ExploreIcons.pillDessert;
    }
    if (l.contains('park') || l.contains('outdoor') || l.contains('garden')) {
      return ExploreIcons.pillOutdoors;
    }
    if (l.contains('venue') ||
        l.contains('event') ||
        l.contains('club') ||
        l.contains('theater') ||
        l.contains('music')) {
      return ExploreIcons.pillVenueEvents;
    }
    if (l.contains('points')) return ExploreIcons.cardPoints;
    return null;
  }

  /// 1263 → "1,263", matching the review counts in the design.
  static String _compact(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
