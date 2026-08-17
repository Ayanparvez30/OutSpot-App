import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/routes.dart';

class PointSubmitDialog {
  // ::::: SUCCESS DIALOG :::::
  static void showSuccess({
    required String? imageUrl,
    required int points,
    required String Placename,
    VoidCallback? onViewChallenge,
    VoidCallback? onViewLeaderboard,
    VoidCallback? onBackToCamera,
  }) {
    showGeneralDialog(
      context: Get.context!,
      barrierDismissible: false,
      barrierLabel: "Success Dialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Background Overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xff4A148C).withOpacity(0.9),
              ),

              // Content
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff2D0731),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image
                          Padding(
                            padding: EdgeInsets.all(20.sp),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: CachedNetworkImage(
                                imageUrl:
                                    imageUrl ??
                                    "assets/Images/congratulation.png",
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        const ShimmerPlaceholder(),
                                errorWidget:
                                    (context, url, error) => Image.asset(
                                      "assets/Images/congratulation.png",
                                    ),
                              ),
                            ),
                          ),

                          // Title
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.notoSans(
                                  fontSize: 18.sp,
                                  height: 1.35,
                                ),
                                children: [
                                  TextSpan(
                                    text: "How was ",
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "$Placename",
                                    style: GoogleFonts.notoSans(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "?",
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Text(
                          //   "How was $Placename?",

                          //   style: GoogleFonts.notoSans(
                          //     fontSize: 22.sp,
                          //     fontWeight: FontWeight.w700,
                          //     color: Colors.white,
                          //   ),
                          // ),
                          SizedBox(height: 15.h),

                          // Points Section — FittedBox so it always fits the
                          // dialog width on any screen (no RenderFlex overflow).
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "You received",
                                  style: GoogleFonts.notoSans(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                SvgPicture.asset(
                                  "assets/svg/level/coinshape2.svg",
                                  height: 20.h,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  "$points", // Dynamic Points
                                  style: GoogleFonts.notoSans(
                                    fontSize: 17.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Buttons
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              children: [
                                _CustomGradientButton(
                                  text: "Ok!",
                                 
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.btnGradientLeft,
                                      AppColors.btnGradientRight,
                                    ],
                                  ),
                                  onPressed: () {
                                    // Same as the "Too Far" dialog's Go Back:
                                    // pop the dialog + capture/camera routes back
                                    // to the place details screen in the stack
                                    // (not a full reset to the home tabs).
                                    Get.until(
                                      (route) =>
                                          route.settings.name ==
                                              Routes.placeDetails ||
                                          route.isFirst,
                                    );
                                  },
                                ),
                                SizedBox(height: 20.h),
                                SizedBox(height: 10.h),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Top Banner Text
              Positioned(
                top: 50.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "You got points!",
                    style: GoogleFonts.notoSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Bottom Back Button
              // Positioned(
              //   bottom: 40.h,
              //   left: 0,
              //   right: 0,
              //   child: Center(
              //     child: TextButton.icon(
              //       onPressed: () {
              //         Get.back();
              //         Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
              //       },
              //       icon: Icon(
              //         Icons.arrow_back_ios,
              //         color: Colors.white70,
              //         size: 18.sp,
              //       ),
              //       label: Text(
              //         "Back",
              //         style: GoogleFonts.notoSans(
              //           fontSize: 16.sp,
              //           fontWeight: FontWeight.w600,
              //           color: Colors.white70,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  // ::::: FAILED / INFO DIALOG :::::
  // Returns a Future that completes when the dialog is dismissed, so callers
  // can sequence follow-up prompts after the user acknowledges the failure.
  static Future<void> showFailed({
    String title = "Submission failed!",
    String message = "There was an error submitting your points. Please try again.",
    IconData icon = Icons.error,
    Color iconColor = Colors.red,
    String? actionText,
    VoidCallback? onAction,
    // Bottom "Go Back" row — override its label and/or action (default: just
    // pop the dialog). When [onBack] is provided the dialog is non-dismissible
    // by tapping outside, and the Android back button routes through [onBack].
    String backText = "Go Back",
    VoidCallback? onBack,
  }) {
    return showDialog(
      context: Get.context!,
      barrierDismissible: onBack == null,
      builder: (BuildContext context) {
        return PopScope(
          canPop: onBack == null,
          onPopInvoked: (didPop) {
            if (!didPop && onBack != null) onBack();
          },
          child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 10.w),
          backgroundColor: const Color(0xff2D0731),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30.h),
              Icon(icon, size: 80.sp, color: iconColor),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              if (actionText != null && onAction != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _CustomGradientButton(
                    text: actionText,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.btnGradientLeft,
                        AppColors.btnGradientRight,
                      ],
                    ),
                    onPressed: () {
                      Get.back();
                      onAction();
                    },
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              GestureDetector(
                onTap: onBack ?? () => Get.back(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 22.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      backText,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
          ),
        );
      },
    );
  }
}

// Internal Helper Widget for Buttons
class _CustomGradientButton extends StatelessWidget {
  final String text;
  // final String imagePath;
  final Gradient gradient;
  final VoidCallback onPressed;

  const _CustomGradientButton({
    required this.text,
    // required this.imagePath,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 45.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(imagePath, scale: 2.5),
            SizedBox(width: 17.w),
            Text(
              text,
              style: GoogleFonts.notoSans(
                decoration: TextDecoration.none,
                fontSize: 16.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
