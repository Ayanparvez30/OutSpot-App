/// Design tokens for the Explore redesign, read straight off the Figma file
/// `5havCsIrjWIRrxelFCgXGA`, page "App Redesign" (node 7299:20962).
///
/// Nothing here is invented: every colour and measurement below is the value
/// Figma reports for that layer. Keeping them in one place means a card, a pill
/// and the search field can't drift apart, and re-reading the Figma file later
/// is a diff against this file rather than a hunt through widgets.
///
/// The old Explore screen is untouched — these are additive, so the previous
/// design stays available to fall back on.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma draws the redesign at 393pt wide; ScreenUtil's design size is 360
/// (set in main.dart). Passing raw Figma px to `.w` renders ~9% oversized, so
/// convert first: `figPx(240).w` puts a 240px Figma card on screen as 240 real
/// px on a 393-wide device, and scales proportionally on anything else.
double figPx(double figmaPx) => figmaPx * (360 / 393);

/// Colours, exactly as Figma reports them.
abstract final class ExploreColors {
  /// Card, search field and circle-button fill.
  static const Color surface = Color(0xFF1E092A);

  /// The 1px outline shared by cards, the search field and circle buttons.
  static const Color border = Color(0xFF703A8B);

  /// Category pill fill.
  static const Color pill = Color(0xFF78368F);

  /// Points badge on the card image.
  static const Color pointsBadgeFill = Color(0xFF3B2625);
  static const Color pointsBadgeBorder = Color(0xFF9D8813);
  static const Color pointsText = Color(0xFFFFEA00);

  /// Headings, spot names, pill labels.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary metadata — category tags, distance, price, review count.
  static const Color textMuted = Color(0xFFBABABA);

  /// Small glyphs and the rating number.
  static const Color gold = Color(0xFFF8AC00);

  static const Color openNow = Color(0xFF42D880);
  static const Color closedNow = Color(0xFFFF7474);
}

/// Type ramp. Figma specifies Noto Sans; the app's global theme is Roboto, so
/// the family is set explicitly here to match the design rather than inherit.
abstract final class ExploreText {
  /// Carousel heading — "Spots Trending This Week".
  static TextStyle get heading => GoogleFonts.notoSans(
    fontSize: figPx(16).sp,
    fontWeight: FontWeight.w600,
    color: ExploreColors.textPrimary,
    height: 22 / 16,
  );

  /// Spot name on a card.
  static TextStyle get spotName => GoogleFonts.notoSans(
    fontSize: figPx(14).sp,
    fontWeight: FontWeight.w600,
    color: ExploreColors.textPrimary,
    height: 19 / 14,
  );

  /// Category tags, distance, price, review count, separators.
  static TextStyle get meta => GoogleFonts.notoSans(
    fontSize: figPx(12).sp,
    fontWeight: FontWeight.w400,
    color: ExploreColors.textMuted,
    height: 16 / 12,
  );

  /// Open / Closed — same size as [meta] but medium, and colour-coded.
  static TextStyle status(bool isOpen) => GoogleFonts.notoSans(
    fontSize: figPx(12).sp,
    fontWeight: FontWeight.w500,
    color: isOpen ? ExploreColors.openNow : ExploreColors.closedNow,
    height: 16 / 12,
  );

  /// The rating number itself (the review count beside it uses [meta]).
  static TextStyle get rating => GoogleFonts.notoSans(
    fontSize: figPx(12).sp,
    fontWeight: FontWeight.w500,
    color: ExploreColors.gold,
    height: 16 / 12,
  );

  /// "SamR7 and 2 others were spotted here" — the smallest text on the card.
  static TextStyle get friendsSpotted => GoogleFonts.notoSans(
    fontSize: figPx(10).sp,
    fontWeight: FontWeight.w400,
    color: ExploreColors.textMuted,
    // Figma's 140×24 text box holds two 10px lines — 1.2, not 1.4, or the row
    // grows 4px and tips the 241px card into a bottom overflow.
    height: 12 / 10,
  );

  /// Category pill label.
  static TextStyle get pillLabel => GoogleFonts.notoSans(
    fontSize: figPx(12).sp,
    fontWeight: FontWeight.w600,
    color: ExploreColors.textPrimary,
    height: 16 / 12,
  );

  /// Search field placeholder and typed text.
  static TextStyle get searchField => GoogleFonts.notoSans(
    fontSize: figPx(16).sp,
    fontWeight: FontWeight.w400,
    color: ExploreColors.textMuted,
    height: 22 / 16,
  );
}

/// Geometry, in Figma px — pass through [figPx] and `.w` at the use site.
abstract final class ExploreDim {
  // Spot card
  static final double cardWidth = figPx(240);
  static final double cardHeight = figPx(241);
  static final double cardRadius = figPx(16);
  static final double cardImageHeight = figPx(132);
  static final double cardInfoPadH = figPx(12);
  static final double cardInfoPadTop = figPx(8);
  static final double cardInfoPadBottom = figPx(12);
  static final double cardRowGap = figPx(2);

  // Circle button (save, and the carousel's "see all")
  static final double circleButton = figPx(28);
  static final double circleButtonIcon = figPx(12);
  static final double saveTop = figPx(8);
  static final double saveRight = figPx(8);

  // Points badge
  static final double badgeLeft = figPx(8);
  static final double badgeTop = figPx(12);
  static final double badgeHeight = figPx(20);
  static final double badgePadH = figPx(7);
  static final double badgeGap = figPx(3);

  // Metadata rows
  static final double metaIcon = figPx(12);
  static final double metaRowHeight = figPx(16);
  static final double metaGapLine1 = figPx(4);
  static final double metaGapLine2 = figPx(2);
  static final double tagIconGap = figPx(2);

  // Friends spotted
  static final double friendsRowHeight = figPx(32);
  static final double friendAvatar = figPx(28);
  static final double friendOverlap = figPx(6); // negative gap in Figma
  static final double friendsGap = figPx(4);
  static final double friendsPadTop = figPx(4);
  static const int friendsPreviewMax = 3;

  // Carousel
  static final double carouselGap = figPx(12); // heading → items
  static final double carouselItemGap = figPx(16); // card → card
  static final double headingHeight = figPx(28);

  // Search field
  static final double searchHeight = figPx(44);
  static final double searchRadius = figPx(24);
  static final double searchPadH = figPx(16);
  static final double searchGap = figPx(8);
  static final double searchIcon = figPx(16);

  // Category pills
  static final double pillHeight = figPx(32);
  static final double pillRadius = figPx(24);
  static final double pillPadH = figPx(12);
  static final double pillGap = figPx(4); // icon → label
  static final double pillRowGap = figPx(8); // pill → pill
  static final double pillIcon = figPx(12);

  /// Horizontal page margin — the Figma body is 361 wide inside a 393 frame.
  static final double pageMargin = figPx(16);
}
