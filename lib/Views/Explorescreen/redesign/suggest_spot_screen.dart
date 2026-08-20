import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/Network_Manager/spot_suggestion_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/colors.dart';

/// "Know a spot we're missing?" — the form for telling us about a place Google
/// has never heard of.
///
/// The user has to be standing at it. Location is read when the screen opens
/// and again the moment they submit, and nothing can be sent until we have it,
/// because the coordinates *are* the submission — an admin can correct a
/// misspelled name later, but never where the place is.
class SuggestSpotScreen extends StatefulWidget {
  const SuggestSpotScreen({super.key});

  @override
  State<SuggestSpotScreen> createState() => _SuggestSpotScreenState();
}

class _SuggestSpotScreenState extends State<SuggestSpotScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();

  String _categoryKey = SpotSuggestionService.categories.first.key;
  File? _photo;

  Position? _position;
  bool _locating = true;
  bool _submitting = false;

  /// Null while the list is still loading, so the header can stay quiet rather
  /// than flashing "you can send one today" and then contradicting itself.
  MySuggestions? _mine;

  @override
  void initState() {
    super.initState();
    _readLocation();
    _loadMine();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _readLocation() async {
    setState(() => _locating = true);
    final pos = await LocationHelper.getCurrentPosition(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _position = pos;
      _locating = false;
    });
  }

  Future<void> _loadMine() async {
    final mine = await SpotSuggestionService.fetchMine();
    if (!mounted) return;
    setState(() => _mine = mine);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final shot = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ExploreColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8.h),
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.white),
                  title: Text(
                    'Take a photo',
                    style: GoogleFonts.notoSans(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: Text(
                    'Choose from gallery',
                    style: GoogleFonts.notoSans(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
    );
    if (shot == null) return;

    // Downscaled here rather than server-side: it's one photo, and a 12MP
    // original over a phone connection is the difference between a submission
    // that lands and one that times out.
    final picked = await picker.pickImage(
      source: shot,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_name.text.trim().isEmpty) {
      AppSnackbar.warning('Give the place a name first.');
      return;
    }

    // Re-read rather than trusting the fix from when the screen opened — the
    // user may have walked since, and the whole promise is "I am here now".
    final pos = await LocationHelper.getCurrentPosition(forceRefresh: true);
    if (!mounted) return;
    if (pos == null) {
      AppSnackbar.error(
        'We could not read your location. Turn location on and try again.',
      );
      return;
    }
    setState(() {
      _position = pos;
      _submitting = true;
    });

    final result = await SpotSuggestionService.submit(
      name: _name.text.trim(),
      categoryKey: _categoryKey,
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: _address.text,
      note: _note.text,
      imageFile: _photo,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.ok) {
      Get.back();
      AppSnackbar.success(result.message);
    } else {
      AppSnackbar.error(result.message);
    }
  }

  bool get _canSubmit =>
      !_submitting && _position != null && (_mine?.canSubmitToday ?? true);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Same back control the rest of the redesign uses, at the same size.
          leading: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: SizedBox(height: 35, child: CustomBackButton()),
            ),
          ),
          title: Text(
            'Suggest a spot',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              ExploreDim.pageMargin.w,
              figPx(8).w,
              ExploreDim.pageMargin.w,
              figPx(32).w,
            ),
            children: [
              _intro(),
              SizedBox(height: figPx(14).w),
              _locationCard(),
              SizedBox(height: figPx(20).w),

              _label('Name of the place'),
              _field(
                _name,
                hint: 'e.g. Rooftop 88',
                icon: Icons.storefront_outlined,
                maxLength: 200,
              ),
              SizedBox(height: figPx(18).w),

              _label('Category'),
              _categoryPicker(),
              SizedBox(height: figPx(18).w),

              _label('Address', hint: 'optional'),
              _field(
                _address,
                hint: 'Street, floor, landmark',
                icon: Icons.map_outlined,
                maxLength: 300,
              ),
              SizedBox(height: figPx(18).w),

              _label('Anything we should know?', hint: 'optional'),
              _field(
                _note,
                hint: 'What makes it worth adding',
                icon: Icons.chat_bubble_outline,
                maxLines: 3,
                maxLength: 1000,
              ),
              SizedBox(height: figPx(18).w),

              _label('Photo', hint: 'optional'),
              _photoPicker(),
              SizedBox(height: figPx(24).w),

              _submitButton(),
              if (_mine != null && _mine!.suggestions.isNotEmpty) ...[
                SizedBox(height: figPx(28).w),
                _mineList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hero card. Carries the reward in the same gold points badge the spot cards
  /// use, so "50 points" reads as the app's own currency rather than as text.
  Widget _intro() {
    final reward = _mine?.rewardPoints ?? 50;
    return Container(
      padding: EdgeInsets.all(figPx(16).w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E165B), ExploreColors.surface],
        ),
        borderRadius: BorderRadius.circular(ExploreDim.cardRadius.w),
        border: Border.all(color: ExploreColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: figPx(40).w,
            height: figPx(40).w,
            decoration: BoxDecoration(
              color: ExploreColors.pill,
              borderRadius: BorderRadius.circular(figPx(12).w),
            ),
            child: Icon(
              Icons.add_location_alt_outlined,
              size: figPx(20).w,
              color: ExploreColors.textPrimary,
            ),
          ),
          SizedBox(width: figPx(12).w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Know a spot we\'re missing?',
                  style: ExploreText.heading.copyWith(fontSize: figPx(15).sp),
                ),
                SizedBox(height: figPx(6).w),
                Text(
                  'Small places Google doesn\'t list. Stand at it, send it in — '
                  'if it goes on the map you earn',
                  style: ExploreText.meta.copyWith(height: 1.5),
                ),
                SizedBox(height: figPx(8).w),
                _pointsBadge(reward),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The spot card's points badge, same fill, border and gold.
  Widget _pointsBadge(int points) {
    return Container(
      height: ExploreDim.badgeHeight.w,
      padding: EdgeInsets.symmetric(horizontal: ExploreDim.badgePadH.w),
      decoration: BoxDecoration(
        color: ExploreColors.pointsBadgeFill,
        borderRadius: BorderRadius.circular(ExploreDim.badgeHeight.w / 2),
        border: Border.all(color: ExploreColors.pointsBadgeBorder),
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
            '$points points',
            style: ExploreText.meta.copyWith(
              color: ExploreColors.pointsText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Makes the "you must be here" rule visible instead of only enforcing it at
  /// submit time, so a refusal is never a surprise.
  Widget _locationCard() {
    final Color tint;
    final IconData icon;
    final String title;
    final String detail;

    if (_locating) {
      tint = ExploreColors.gold;
      icon = Icons.my_location;
      title = 'Finding where you are…';
      detail = 'Hold on a moment';
    } else if (_position == null) {
      tint = ExploreColors.closedNow;
      icon = Icons.location_disabled;
      title = 'Location is off';
      detail = 'Turn it on to suggest a spot';
    } else {
      tint = ExploreColors.openNow;
      icon = Icons.location_on;
      title = 'You\'re here';
      detail =
          '${_position!.latitude.toStringAsFixed(5)}, '
          '${_position!.longitude.toStringAsFixed(5)}';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: figPx(14).w,
        vertical: figPx(12).w,
      ),
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(ExploreDim.cardRadius.w),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: figPx(32).w,
            height: figPx(32).w,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tint, size: figPx(16).w),
          ),
          SizedBox(width: figPx(10).w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ExploreText.spotName.copyWith(
                    fontSize: figPx(13).sp,
                    color: tint,
                  ),
                ),
                Text(detail, style: ExploreText.meta),
              ],
            ),
          ),
          if (!_locating && _position == null)
            GestureDetector(
              onTap: _readLocation,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: figPx(12).w,
                  vertical: figPx(6).w,
                ),
                decoration: BoxDecoration(
                  color: ExploreColors.pill,
                  borderRadius: BorderRadius.circular(figPx(16).w),
                ),
                child: Text('Retry', style: ExploreText.pillLabel),
              ),
            ),
        ],
      ),
    );
  }

  /// Section heading — the same weight and size the feed's row titles use.
  Widget _label(String text, {String? hint}) => Padding(
    padding: EdgeInsets.only(bottom: figPx(8).w, left: figPx(2).w),
    child: Row(
      children: [
        Container(
          width: figPx(3).w,
          height: figPx(14).w,
          decoration: BoxDecoration(
            color: ExploreColors.gold,
            borderRadius: BorderRadius.circular(figPx(2).w),
          ),
        ),
        SizedBox(width: figPx(8).w),
        Text(text, style: ExploreText.heading.copyWith(fontSize: figPx(14).sp)),
        if (hint != null) ...[
          SizedBox(width: figPx(6).w),
          Text(hint, style: ExploreText.meta),
        ],
      ],
    ),
  );

  /// Fields borrow the search pill's shape — same radius, same fill, same
  /// border — with a leading glyph so each one is recognisable at a glance.
  Widget _field(
    TextEditingController controller, {
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: figPx(14).w),
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(
          maxLines > 1 ? ExploreDim.cardRadius.w : ExploreDim.searchRadius.w,
        ),
        border: Border.all(color: ExploreColors.border),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? figPx(14).w : 0),
            child: Icon(
              icon,
              size: figPx(16).w,
              color: ExploreColors.textMuted,
            ),
          ),
          SizedBox(width: figPx(10).w),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              maxLength: maxLength,
              cursorColor: ExploreColors.textPrimary,
              style: ExploreText.searchField.copyWith(
                color: ExploreColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                hintText: hint,
                hintStyle: ExploreText.searchField,
                contentPadding: EdgeInsets.symmetric(vertical: figPx(14).w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Identical to Explore's own filter pills, Figma glyph and all — a category
  /// should look the same wherever the user meets it.
  Widget _categoryPicker() {
    return Wrap(
      spacing: figPx(8).w,
      runSpacing: figPx(8).w,
      children:
          SpotSuggestionService.categories.map((c) {
            final isOn = c.key == _categoryKey;
            return GestureDetector(
              onTap: () => setState(() => _categoryKey = c.key),
              child: Container(
                height: ExploreDim.pillHeight.w,
                padding: EdgeInsets.symmetric(
                  horizontal: ExploreDim.pillPadH.w,
                ),
                decoration: BoxDecoration(
                  color:
                      isOn
                          ? ExploreColors.pill
                          : ExploreColors.pill.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(ExploreDim.pillRadius.w),
                  border: Border.all(
                    color:
                        isOn ? ExploreColors.textPrimary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExploreIcons.svg(c.icon, size: ExploreDim.pillIcon.w),
                    SizedBox(width: ExploreDim.pillGap.w),
                    Text(
                      c.label,
                      style: ExploreText.pillLabel.copyWith(
                        color:
                            isOn
                                ? ExploreColors.textPrimary
                                : ExploreColors.textPrimary.withValues(
                                  alpha: 0.7,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _photoPicker() {
    if (_photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(ExploreDim.cardRadius.w),
        child: Stack(
          children: [
            Image.file(
              _photo!,
              width: double.infinity,
              height: ExploreDim.cardImageHeight.w,
              fit: BoxFit.cover,
            ),
            // Same gradient scrim the spot cards lay over their photo, so the
            // controls stay readable on a bright picture.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: ExploreDim.saveTop.w,
              right: ExploreDim.saveRight.w,
              child: GestureDetector(
                onTap: () => setState(() => _photo = null),
                child: Container(
                  width: ExploreDim.circleButton.w,
                  height: ExploreDim.circleButton.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: ExploreColors.border),
                  ),
                  child: Icon(
                    Icons.close,
                    size: ExploreDim.circleButtonIcon.w,
                    color: ExploreColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: figPx(96).w,
        decoration: BoxDecoration(
          color: ExploreColors.surface,
          borderRadius: BorderRadius.circular(ExploreDim.cardRadius.w),
          border: Border.all(color: ExploreColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: figPx(40).w,
              height: figPx(40).w,
              decoration: BoxDecoration(
                color: ExploreColors.pill.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(figPx(12).w),
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                color: ExploreColors.textPrimary,
                size: figPx(18).w,
              ),
            ),
            SizedBox(width: figPx(12).w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a photo',
                  style: ExploreText.spotName.copyWith(fontSize: figPx(13).sp),
                ),
                Text('Optional, but it helps', style: ExploreText.meta),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    final blockedForToday = _mine != null && !_mine!.canSubmitToday;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: figPx(50).w,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    _canSubmit
                        ? const [
                          AppColors.btnGradientLeft,
                          AppColors.btnGradientRight,
                        ]
                        : [ExploreColors.surface, ExploreColors.surface],
              ),
              borderRadius: BorderRadius.circular(figPx(28).w),
              border: Border.all(
                color: _canSubmit ? Colors.transparent : ExploreColors.border,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(figPx(28).w),
                onTap: _canSubmit ? _submit : null,
                child: Center(
                  child:
                      _submitting
                          ? SizedBox(
                            width: figPx(20).w,
                            height: figPx(20).w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ExploreColors.textPrimary,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: figPx(16).w,
                                color: ExploreColors.textPrimary.withValues(
                                  alpha: _canSubmit ? 1 : 0.4,
                                ),
                              ),
                              SizedBox(width: figPx(8).w),
                              Text(
                                'Send this spot',
                                style: ExploreText.heading.copyWith(
                                  fontSize: figPx(15).sp,
                                  color: ExploreColors.textPrimary.withValues(
                                    alpha: _canSubmit ? 1 : 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        ),
        if (blockedForToday) ...[
          SizedBox(height: figPx(10).w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: figPx(12).w,
              vertical: figPx(8).w,
            ),
            decoration: BoxDecoration(
              color: ExploreColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(figPx(12).w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: figPx(14).w,
                  color: ExploreColors.gold,
                ),
                SizedBox(width: figPx(6).w),
                Flexible(
                  child: Text(
                    'One a day — come back tomorrow',
                    style: ExploreText.meta.copyWith(color: ExploreColors.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _mineList() {
    final mine = _mine!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('What you\'ve sent', hint: '${mine.suggestions.length}'),
        Padding(
          padding: EdgeInsets.only(left: figPx(11).w, bottom: figPx(10).w),
          child: Text(
            'Anything still waiting is removed after ${mine.expiryDays} days.',
            style: ExploreText.meta,
          ),
        ),
        ...mine.suggestions.map(_mineTile),
      ],
    );
  }

  Widget _mineTile(SpotSuggestion s) {
    final (Color tint, String label, IconData icon) =
        s.isApproved
            ? (ExploreColors.openNow, 'On the map', Icons.check_circle_outline)
            : s.isRejected
            ? (ExploreColors.closedNow, 'Not added', Icons.cancel_outlined)
            : (ExploreColors.gold, 'Waiting', Icons.hourglass_empty);

    return Container(
      margin: EdgeInsets.only(bottom: figPx(10).w),
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(ExploreDim.cardRadius.w),
        border: Border.all(color: ExploreColors.border),
      ),
      // IntrinsicHeight measures the text column first, so the rail beside it
      // has a real height to stretch to. Without it the Row sits in the
      // ListView's unbounded vertical space, the rail resolves to zero height,
      // and any tap lands on a zero-size box — which is what threw
      // "Cannot hit test a render box with no size" and killed scrolling.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A slim status rail — reads at a glance down a list, without a
            // coloured badge competing with the card's own chrome.
            Container(
              width: figPx(4).w,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(ExploreDim.cardRadius.w),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(figPx(12).w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ExploreText.spotName.copyWith(
                              fontSize: figPx(13).sp,
                            ),
                          ),
                        ),
                        SizedBox(width: figPx(8).w),
                        Icon(icon, size: figPx(13).w, color: tint),
                        SizedBox(width: figPx(4).w),
                        Text(
                          label,
                          style: ExploreText.meta.copyWith(color: tint),
                        ),
                      ],
                    ),
                    if (s.address.isNotEmpty) ...[
                      SizedBox(height: figPx(3).w),
                      Text(
                        s.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ExploreText.meta,
                      ),
                    ],
                    // The admin wrote this for the reporter to read, so it belongs
                    // on screen and not just in a notification they may have
                    // swiped away.
                    if (s.isRejected && s.rejectReason.isNotEmpty) ...[
                      SizedBox(height: figPx(8).w),
                      Container(
                        padding: EdgeInsets.all(figPx(8).w),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(figPx(8).w),
                        ),
                        child: Text(
                          s.rejectReason,
                          style: ExploreText.meta.copyWith(
                            color: tint,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
