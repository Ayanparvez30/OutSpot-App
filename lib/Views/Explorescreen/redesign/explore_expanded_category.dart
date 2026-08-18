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
import 'package:outspot/Views/Explore_Category/placeDetailsScreen.dart';

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
  final Set<String> _saved = {};
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    final pad = ExploreDim.pageMargin.w;
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
                          itemCount: _spots.length,
                          separatorBuilder:
                              (_, __) =>
                                  SizedBox(height: ExploreDim.carouselItemGap.w),
                          itemBuilder: (_, i) {
                            final s = _spots[i];
                            return SpotCard(
                              spot: s,
                              // Figma's expanded card: full width, 140px photo.
                              width: double.infinity,
                              imageHeight: figPx(140 * _cardScale).w,
                              isSaved: _saved.contains(s.placeId),
                              onSave:
                                  () => setState(() {
                                    _saved.contains(s.placeId)
                                        ? _saved.remove(s.placeId)
                                        : _saved.add(s.placeId);
                                  }),
                              onTap: () => _openSpot(s),
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
              padding: EdgeInsets.symmetric(horizontal: figPx(44).w),
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
              child: CustomBackButton(),
            ),
          ],
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
