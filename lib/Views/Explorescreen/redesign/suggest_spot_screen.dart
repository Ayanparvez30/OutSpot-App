import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/location_helper.dart';
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
      builder: (ctx) => SafeArea(
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
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
            children: [
              _intro(),
              SizedBox(height: 16.h),
              _locationCard(),
              SizedBox(height: 16.h),

              _label('Name of the place'),
              _field(_name, hint: 'e.g. Rooftop 88', maxLength: 200),
              SizedBox(height: 14.h),

              _label('Category'),
              _categoryPicker(),
              SizedBox(height: 14.h),

              _label('Address'),
              _field(_address, hint: 'Street, floor, landmark', maxLength: 300),
              SizedBox(height: 14.h),

              _label('Anything we should know?'),
              _field(
                _note,
                hint: 'What makes it worth adding',
                maxLines: 3,
                maxLength: 1000,
              ),
              SizedBox(height: 14.h),

              _label('Photo'),
              _photoPicker(),
              SizedBox(height: 24.h),

              _submitButton(),
              if (_mine != null && _mine!.suggestions.isNotEmpty) ...[
                SizedBox(height: 28.h),
                _mineList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    final reward = _mine?.rewardPoints ?? 50;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ExploreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Know a spot we\'re missing?',
            style: GoogleFonts.notoSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Small places Google doesn\'t list. You have to be there to send '
            'one in. If we add it to the map, you get $reward points.',
            style: GoogleFonts.notoSans(
              fontSize: 12.sp,
              height: 1.5,
              color: ExploreColors.textMuted,
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
    final String text;

    if (_locating) {
      tint = ExploreColors.textMuted;
      icon = Icons.my_location;
      text = 'Finding where you are…';
    } else if (_position == null) {
      tint = ExploreColors.closedNow;
      icon = Icons.location_disabled;
      text = 'Location is off — turn it on to suggest a spot';
    } else {
      tint = ExploreColors.openNow;
      icon = Icons.location_on;
      text =
          'Using your location: '
          '${_position!.latitude.toStringAsFixed(5)}, '
          '${_position!.longitude.toStringAsFixed(5)}';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSans(fontSize: 12.sp, color: tint),
            ),
          ),
          if (!_locating && _position == null)
            TextButton(
              onPressed: _readLocation,
              child: Text(
                'Retry',
                style: GoogleFonts.notoSans(
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      text,
      style: GoogleFonts.notoSans(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  Widget _field(
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.notoSans(fontSize: 14.sp, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          fontSize: 13.sp,
          color: AppColors.hintTextColor,
        ),
        counterText: '',
        filled: true,
        fillColor: ExploreColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: ExploreColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: ExploreColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: ExploreColors.pill),
        ),
      ),
    );
  }

  Widget _categoryPicker() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: SpotSuggestionService.categories.map((c) {
        final selected = c.key == _categoryKey;
        return GestureDetector(
          onTap: () => setState(() => _categoryKey = c.key),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: selected ? ExploreColors.pill : ExploreColors.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected ? ExploreColors.pill : ExploreColors.border,
              ),
            ),
            child: Text(
              c.label,
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : ExploreColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _photoPicker() {
    if (_photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              _photo!,
              width: double.infinity,
              height: 160.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _photo = null),
              child: CircleAvatar(
                radius: 14.r,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 16.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          color: ExploreColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: ExploreColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: ExploreColors.textMuted,
              size: 24.sp,
            ),
            SizedBox(height: 6.h),
            Text(
              'Add a photo (optional)',
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                color: ExploreColors.textMuted,
              ),
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
          height: 50.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _canSubmit
                    ? const [
                        AppColors.btnGradientLeft,
                        AppColors.btnGradientRight,
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.12),
                      ],
              ),
              borderRadius: BorderRadius.circular(28.r),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28.r),
                onTap: _canSubmit ? _submit : null,
                child: Center(
                  child: _submitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send this spot',
                          style: GoogleFonts.notoSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(
                              alpha: _canSubmit ? 1 : 0.4,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (blockedForToday) ...[
          SizedBox(height: 8.h),
          Text(
            'You\'ve already sent one today. Try again tomorrow.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 12.sp,
              color: ExploreColors.gold,
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
        Text(
          'What you\'ve sent',
          style: GoogleFonts.notoSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'We remove anything still waiting after ${mine.expiryDays} days.',
          style: GoogleFonts.notoSans(
            fontSize: 11.sp,
            color: ExploreColors.textMuted,
          ),
        ),
        SizedBox(height: 10.h),
        ...mine.suggestions.map(_mineTile),
      ],
    );
  }

  Widget _mineTile(SpotSuggestion s) {
    final (Color tint, String label) = s.isApproved
        ? (ExploreColors.openNow, 'On the map')
        : s.isRejected
        ? (ExploreColors.closedNow, 'Not added')
        : (ExploreColors.gold, 'Waiting');

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ExploreColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ExploreColors.border),
      ),
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
                  style: GoogleFonts.notoSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.notoSans(fontSize: 10.sp, color: tint),
                ),
              ),
            ],
          ),
          if (s.address.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              s.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSans(
                fontSize: 11.sp,
                color: ExploreColors.textMuted,
              ),
            ),
          ],
          // The admin wrote this for the reporter to read, so it belongs on
          // screen and not just in the notification they may have swiped away.
          if (s.isRejected && s.rejectReason.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              s.rejectReason,
              style: GoogleFonts.notoSans(
                fontSize: 11.sp,
                height: 1.4,
                color: ExploreColors.closedNow,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
