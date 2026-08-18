import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The redesign's own icons, exported straight out of the Figma file
/// (`5havCsIrjWIRrxelFCgXGA`) rather than approximated with Material glyphs.
///
/// They live in `assets/svg/explore_redesign/` and weigh 64 KB for all
/// fourteen — worth contrasting with the app's existing category art, where a
/// single `assets/svg/icons/cafes.svg` is 6.3 MB because a full-resolution
/// photo is base64'd inside a 62×62 icon. Nothing here embeds a raster.
abstract final class ExploreIcons {
  static const String _dir = 'assets/svg/explore_redesign';

  // Category pills
  static const String pillTrending = '$_dir/pill_trending.svg';
  static const String pillRestaurants = '$_dir/pill_restaurants.svg';
  static const String pillCafes = '$_dir/pill_cafes.svg';
  static const String pillBars = '$_dir/pill_bars.svg';
  static const String pillDessert = '$_dir/pill_dessert.svg';
  static const String pillOutdoors = '$_dir/pill_outdoors.svg';
  static const String pillVenueEvents = '$_dir/pill_venue_events.svg';

  // Spot card
  static const String cardSave = '$_dir/card_save.svg';
  static const String cardPoints = '$_dir/card_points.svg';
  static const String cardRatingStar = '$_dir/card_rating_star.svg';
  static const String cardTrendingTag = '$_dir/card_trending_tag.svg';
  static const String cardCafeTag = '$_dir/card_cafe_tag.svg';
  static const String cardAccessible = '$_dir/card_accessible.svg';

  // Search field
  static const String search = '$_dir/search.svg';

  /// Renders one of the above at [size].
  ///
  /// [color] tints the glyph. Several exports already carry Figma's own fill
  /// (the gold `#F8AC00`, for instance), so pass null to keep the artwork
  /// exactly as designed and only override when a state demands it.
  static Widget svg(String asset, {required double size, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
