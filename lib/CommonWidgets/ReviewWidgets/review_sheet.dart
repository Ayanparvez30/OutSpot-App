import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Network_Manager/app_review_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/colors.dart';

/// Rate OutSpot — one to five stars plus optional words.
///
/// Raised two ways: automatically from Explore on the third launch, and on
/// demand from Settings, where it reopens whatever the user wrote last so they
/// can change it. The same sheet handles both; [existing] is what makes it an
/// edit rather than a first review.
///
/// Always dismissible. Nothing in the app is gated behind leaving a review —
/// both stores forbid that, and it would be a rotten thing to do besides.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    this.existing,
    this.showLater = false,
    this.onLater,
  });

  /// The user's current review, when they're editing rather than writing.
  final MyReview? existing;

  /// Only the automatic prompt offers "Later" — from Settings the user came
  /// here deliberately, so swiping the sheet away is enough.
  final bool showLater;
  final VoidCallback? onLater;

  /// Opens the sheet. Returns true when a review was actually saved.
  static Future<bool> show({
    MyReview? existing,
    bool showLater = false,
    VoidCallback? onLater,
  }) async {
    final saved = await Get.bottomSheet<bool>(
      ReviewSheet(existing: existing, showLater: showLater, onLater: onLater),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    return saved == true;
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _comment = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  bool _saving = false;

  bool get _isEditing => (widget.existing?.hasReviewed ?? false);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _saving) return;
    setState(() => _saving = true);

    final ok = await AppReviewService.submit(
      rating: _rating,
      comment: _comment.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Get.back(result: true);
      AppSnackbar.success(
        _isEditing ? 'Your review has been updated.' : 'Thanks for your review!',
      );
    } else {
      AppSnackbar.error('Could not save your review. Please try again.');
    }
  }

  /// Wording that follows the stars, so the sheet reacts as you tap.
  String get _ratingLabel => switch (_rating) {
    1 => 'Not good',
    2 => 'Could be better',
    3 => 'It\'s okay',
    4 => 'Really good',
    5 => 'Love it!',
    _ => 'Tap a star to rate',
  };

  @override
  Widget build(BuildContext context) {
    // Lifts the sheet above the keyboard while the comment box has focus.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E165B), Color(0xFF1C011F)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: AppColors.inputBorderColor, width: 1),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle — signals the sheet can simply be swiped away.
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                _isEditing ? 'Edit your review' : 'Enjoying OutSpot?',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _isEditing
                    ? 'Change your rating or what you wrote.'
                    : 'Let us know how we\'re doing — it only takes a moment.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: AppColors.white.withValues(alpha: 0.65),
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = star <= _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40.sp,
                        color:
                            filled
                                ? const Color(0xFFF8AC00)
                                : AppColors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 8.h),
              Text(
                _ratingLabel,
                style: GoogleFonts.notoSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color:
                      _rating > 0
                          ? const Color(0xFFF8AC00)
                          : AppColors.white.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: 18.h),

              TextField(
                controller: _comment,
                maxLines: 3,
                maxLength: 1000,
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  color: AppColors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Tell us more (optional)',
                  hintStyle: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    color: AppColors.hintTextColor,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white.withValues(alpha: 0.06),
                  contentPadding: EdgeInsets.all(14.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: Color(0xFFDA5EF3)),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          _rating > 0
                              ? const [
                                AppColors.btnGradientLeft,
                                AppColors.btnGradientRight,
                              ]
                              // Greyed out until a star is picked — the rating
                              // is the one thing the server insists on.
                              : [
                                AppColors.white.withValues(alpha: 0.12),
                                AppColors.white.withValues(alpha: 0.12),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28.r),
                      onTap: _rating > 0 ? _submit : null,
                      child: Center(
                        child:
                            _saving
                                ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                                : Text(
                                  _isEditing ? 'Update review' : 'Submit review',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white.withValues(
                                      alpha: _rating > 0 ? 1 : 0.4,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.showLater) ...[
                SizedBox(height: 4.h),
                TextButton(
                  onPressed:
                      _saving
                          ? null
                          : () {
                            widget.onLater?.call();
                            Get.back(result: false);
                          },
                  child: Text(
                    'Maybe later',
                    style: GoogleFonts.notoSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
