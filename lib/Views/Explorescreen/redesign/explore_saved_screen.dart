import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_background.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_card.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Network_Manager/redesign/explore_feed_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explore_Category/placeDetailsScreen.dart';

/// The Saved Spots screen, behind the bookmark in the Explore top bar.
///
/// Laid out like the expanded-category screen — same full-width [SpotCard] —
/// because a saved spot is the same object, just reached a different way.
///
/// Un-saving from here removes the row immediately rather than waiting for the
/// server: the list is the user's own bookmarks, so echoing the tap instantly
/// is right, and a failed request puts the card back.
class ExploreSavedScreen extends StatefulWidget {
  const ExploreSavedScreen({super.key});

  @override
  State<ExploreSavedScreen> createState() => _ExploreSavedScreenState();
}

class _ExploreSavedScreenState extends State<ExploreSavedScreen> {
  /// Matches the expanded-category screen so cards look identical either way.
  static const double _cardScale = 0.88;

  final List<SpotCardModel> _spots = [];
  bool _loading = true;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final pos = await LocationHelper.getCurrentPosition();
      _lat = pos?.latitude;
      _lng = pos?.longitude;
    } catch (_) {
      // Distances are a nicety here; the list still works without them.
    }
    // 0/0 is a valid request — the server just returns null distances.
    final spots = await ExploreFeedService.savedPlaces(
      lat: _lat ?? 0,
      lng: _lng ?? 0,
    );
    if (!mounted) return;
    setState(() {
      _spots
        ..clear()
        ..addAll(spots);
      _loading = false;
    });
  }

  Future<void> _unsave(SpotCardModel spot) async {
    final index = _spots.indexWhere((s) => s.placeId == spot.placeId);
    if (index < 0) return;

    setState(() => _spots.removeAt(index));
    final ok = await ExploreFeedService.unsavePlace(spot.placeId);
    if (ok || !mounted) return;

    // Server refused — restore the card where it was rather than silently
    // losing a bookmark the user still has.
    setState(() => _spots.insert(index.clamp(0, _spots.length), spot));
    Get.snackbar(
      'Could not remove',
      'That spot is still saved — check your connection.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ExploreColors.surface,
      colorText: ExploreColors.textPrimary,
    );
  }

  void _openSpot(SpotCardModel spot) {
    if (spot.placeId.isEmpty) return;
    // Same four arguments the rest of the app uses, and the same routeName —
    // the check-in "Too Far" dialog pops back to it.
    Get.to(
      () => PlaceDetailsScreen(
        place: spot.toExplorePlace(),
        categoryKey: 'saved',
        userLat: _lat,
        userLng: _lng,
      ),
      routeName: Routes.placeDetails,
    );
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
                            width: double.infinity,
                            imageHeight: figPx(140 * _cardScale).w,
                            // Everything here is saved by definition, so the
                            // bookmark reads filled and tapping it removes.
                            isSaved: true,
                            onSave: () => _unsave(s),
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

  Widget _header(double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, figPx(8).w, pad, figPx(12).w),
      child: SizedBox(
        height: figPx(54).w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: figPx(44).w),
              child: Text(
                'Saved Spots',
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: ExploreText.heading.copyWith(fontSize: figPx(18).sp),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 35,
                child: CustomBackButton()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: ExploreDim.pageMargin.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExploreIcons.svg(
            ExploreIcons.cardSave,
            size: figPx(32).w,
            color: ExploreColors.textMuted,
          ),
          SizedBox(height: figPx(12).w),
          Text('No saved spots yet', style: ExploreText.spotName),
          SizedBox(height: figPx(6).w),
          Text(
            'Tap the bookmark on any spot to keep it here.',
            textAlign: TextAlign.center,
            style: ExploreText.meta,
          ),
        ],
      ),
    ),
  );
}
