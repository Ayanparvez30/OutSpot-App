import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_background.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_search_and_filters.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/spot_search_row.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';
import 'package:outspot/Network_Manager/redesign/explore_feed_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explore_Category/placeDetailsScreen.dart';

/// The search flow from the redesign — Figma frames "EXPLORE - Search"
/// (7319:14533), "Search Input" (7319:14586) and "Searched" (7319:14616).
///
/// A screen of its own rather than a section of the feed: the design gives
/// search a back chevron, its own top bar and the keyboard open on arrival.
///
/// Results use [SpotSearchRow] (361×76), not the carousel card — search shows
/// many places at once and the design switches to a compact row for it.
class ExploreSearchScreen extends StatefulWidget {
  final double lat;
  final double lng;

  /// Restricts results to one category; 'all' searches everything.
  final String category;

  const ExploreSearchScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.category = 'all',
  });

  @override
  State<ExploreSearchScreen> createState() => _ExploreSearchScreenState();
}

class _ExploreSearchScreenState extends State<ExploreSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<SpotCardModel> _results = [];
  bool _searching = false;
  String _query = '';
  Timer? _debounce;

  /// Guards against a slow earlier request overwriting a newer one's results.
  int _requestId = 0;

  /// Recent searches, shown while the field is empty.
  List<({int id, String query})> _history = [];

  @override
  void initState() {
    super.initState();
    // Figma opens this screen with the keyboard already up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await ExploreFeedService.searchHistory();
    if (mounted) setState(() => _history = h);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    setState(() => _query = q);
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q.trim().isEmpty) return;
    final id = ++_requestId;
    setState(() => _searching = true);
    final res = await ExploreFeedService.search(
      query: q.trim(),
      lat: widget.lat,
      lng: widget.lng,
      category: widget.category,
    );
    // A newer keystroke already fired — drop this stale response.
    if (!mounted || id != _requestId) return;
    setState(() {
      _results = res;
      _searching = false;
    });

    // Record only searches that found something — a half-typed word that
    // matched nothing isn't worth offering back later.
    if (res.isNotEmpty) {
      await ExploreFeedService.addSearchHistory(q);
      await _loadHistory();
    }
  }

  Future<void> _removeHistory(({int id, String query}) entry) async {
    setState(() => _history = _history.where((e) => e.id != entry.id).toList());
    final ok = await ExploreFeedService.deleteSearchHistory(entry.id);
    if (!ok) await _loadHistory(); // put it back if the server disagreed
  }

  Future<void> _clearHistory() async {
    final previous = _history;
    setState(() => _history = []);
    final ok = await ExploreFeedService.clearSearchHistory();
    if (!ok && mounted) setState(() => _history = previous);
  }

  @override
  Widget build(BuildContext context) {
    final pad = ExploreDim.pageMargin.w;
    return ExploreBackground(
      child: Column(
        children: [
          _topBar(pad),
          Expanded(child: _body(pad)),
        ],
      ),
    );
  }

  /// Back chevron + the same input field the feed uses — Figma's 76px
  /// "Search Top Nav Bar", chevron 20px, gap 16.
  Widget _topBar(double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, figPx(8).w, pad, figPx(12).w),
      child: Row(
        children: [
          // The app's own back glyph, as every other pushed screen uses.
          Padding(
            padding: EdgeInsets.only(right: figPx(16).w),
            child: SizedBox(height: 35,
              child: const CustomBackButton()),
          ),
          Expanded(
            child: ExploreSearchField(
              controller: _controller,
              focusNode: _focus,
              onChanged: _onChanged,
              onSubmitted: _run,
              onClear: () => _onChanged(''),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(double pad) {
    if (_query.trim().isEmpty) {
      return _history.isEmpty
          ? _note('Search for a spot', 'Try a name, a cuisine or a neighbourhood.')
          : _historyList(pad);
    }
    if (_searching && _results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ExploreColors.gold),
      );
    }
    if (_results.isEmpty) {
      return _note('No spots found', 'Try a different search.');
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, figPx(24).w),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final s = _results[i];
        return SpotSearchRow(spot: s, onTap: () => _openSpot(s));
      },
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
        categoryKey: widget.category,
        userLat: widget.lat,
        userLng: widget.lng,
      ),
      routeName: Routes.placeDetails,
    );
  }

  /// Recent searches. Tapping one re-runs it live rather than replaying old
  /// results, which would be stale.
  Widget _historyList(double pad) {
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, figPx(24).w),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: figPx(8).w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recent searches',
                  style: ExploreText.heading.copyWith(fontSize: figPx(14).sp),
                ),
              ),
              GestureDetector(
                onTap: _clearHistory,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: figPx(4).w),
                  child: Text(
                    'Clear all',
                    style: ExploreText.meta.copyWith(color: ExploreColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final entry in _history)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _controller.text = entry.query;
              _onChanged(entry.query);
              _run(entry.query);
            },
            child: Container(
              height: figPx(48).w,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ExploreColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: figPx(18).w,
                    color: ExploreColors.textMuted,
                  ),
                  SizedBox(width: figPx(12).w),
                  Expanded(
                    child: Text(
                      entry.query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ExploreText.meta.copyWith(
                        color: ExploreColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _removeHistory(entry),
                    child: Padding(
                      padding: EdgeInsets.all(figPx(6).w),
                      child: Icon(
                        Icons.close,
                        size: figPx(16).w,
                        color: ExploreColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _note(String title, String subtitle) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: ExploreDim.pageMargin.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: ExploreText.spotName),
          SizedBox(height: figPx(6).w),
          Text(subtitle, textAlign: TextAlign.center, style: ExploreText.meta),
        ],
      ),
    ),
  );
}
