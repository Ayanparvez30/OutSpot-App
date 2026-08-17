import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:get/route_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';

class ViewAchievements extends GetView<MainscreeenController> {
  const ViewAchievements({super.key});
  @override
  Widget build(BuildContext context) {
    // Refresh every time the screen opens so newly collected points show up
    // (the controller is persistent, so it won't re-fetch on its own).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAchievements();
    });
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        // Opaque dark (not transparent) so the route paints no white during the
        // slide-up transition on iOS. The full-screen skscafold.png covers this,
        // so there's no visible change once settled.
        backgroundColor: AppColors.bgGradientBottom,
        body: Stack(
          children: [
            // Gradient BG
            Positioned.fill(
              child: Image.asset(
                "assets/Images/skscafold.png",
                width: double.infinity,
                alignment: Alignment.topCenter,
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 20.h,
                      horizontal: 20.w,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.back();
                          },
                          child: UnconstrainedBox(
                            child: SvgPicture.asset(
                              "assets/svg/icons/back_icon.svg",
                              width: 25.r,
                              height: 25.r,
                              // fit: BoxFit.scaleDown,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Padding(
                          padding: EdgeInsets.only(left: 68.w),
                          child: Text(
                            "Achievements",
                            style: GoogleFonts.notoSans(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 6.h),
                          _achievementTile(tierName: "Legendary Explorer"),
                          SizedBox(height: 6.h),
                          SvgPicture.asset(
                            "assets/svg/level/legendary_explorer.svg",
                            width: 280.w,
                          ),

                          SizedBox(height: 25.h),
                          _achievementTile(tierName: "City Sniper"),
                          SizedBox(height: 6.h),
                          SvgPicture.asset(
                            "assets/svg/level/city_snipper.svg",
                            width: 280.w,
                          ),
                          SizedBox(height: 25.h),
                          _achievementTile(tierName: "Urban Explorer"),
                          SizedBox(height: 6.h),
                          SvgPicture.asset(
                            "assets/svg/level/urbar_explorer.svg",
                            width: 280.w,
                          ),
                          SizedBox(height: 25.h),
                          _achievementTile(tierName: "New Explorer"),
                          SizedBox(height: 6.h),
                          SvgPicture.asset(
                            "assets/svg/level/new_explorer.svg",
                            width: 280.w,
                          ),
                        ],
                      ),
                    ],
                  ),

                  Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: 24.h, bottom: 40.h),
                    decoration: BoxDecoration(color: const Color(0xFF2D0731)),
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ===== Counter metrics row =====
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _metric(
                                    label: "Your Points",
                                    value:
                                        compactNumber(controller.achievementpoints.value),
                                    showCoin: true,
                                  ),
                                ),
                                _metricDivider(),
                                Expanded(
                                  child: _metric(
                                    label: "Next Tier At",
                                    value:
                                        controller.isMaxLevel
                                            ? "Top"
                                            : compactNumber(controller.nextLevelAtPoints),
                                    showCoin: true,
                                  ),
                                ),
                                _metricDivider(),
                                SizedBox(width: 5),
                                // Current tier shown as its badge image (small),
                                // wrapped in Expanded + BoxFit.contain so it
                                // scales down to fit on every device.
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Current",
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.notoSans(
                                          color: Colors.white60,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                      SizedBox(height: 5.h),
                                      SizedBox(
                                        height: 26.h,
                                        width: double.infinity,
                                        child: SvgPicture.asset(
                                          _tierSvgForTitle(
                                            controller.achievementTitle.value,
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 22.h),

                          // ===== Progress bar with point endpoints =====
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${controller.achievementpoints.value} pts",
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.sp,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    Text(
                                      controller.isMaxLevel
                                          ? "Max"
                                          : "${controller.nextLevelAtPoints} pts",
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.sp,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: controller.progress.value,
                                    minHeight: 9.h,
                                    borderRadius: BorderRadius.circular(10.r),
                                    backgroundColor: const Color(0xFF3D1F56),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF7B51F3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10.h),
                          controller.isMaxLevel
                              ? Text(
                                "Top tier reached!",
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                  color: AppColors.white,
                                ),
                              )
                              : Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/svg/bluepoint.svg",
                                    ),
                                    SizedBox(width: 6.w),
                                    Flexible(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${controller.pointnextlevel.value} more until ",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            TextSpan(
                                              text: controller.nextTitle.value,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  // SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A single counter metric (label on top, big value below). When [showCoin]
  // is set, a coin icon sits before the value.
  Widget _metric({
    required String label,
    required String value,
    bool showCoin = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCoin) ...[
              SvgPicture.asset(
                "assets/svg/bluepoint.svg",
                width: 14.r,
                height: 14.r,
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              value,
              style: GoogleFonts.notoSans(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricDivider() {
    return Container(width: 1, height: 34.h, color: Colors.white24);
  }

  // Maps the current tier title to its badge SVG (case-insensitive, with a safe
  // fallback) so the "Current" counter shows the tier image, not text.
  String _tierSvgForTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.contains('legendary')) {
      return "assets/svg/level/legendary_explorer.svg";
    }
    if (t.contains('sniper') || t.contains('city')) {
      return "assets/svg/level/city_snipper.svg";
    }
    if (t.contains('urban')) {
      return "assets/svg/level/urbar_explorer.svg";
    }
    return "assets/svg/level/new_explorer.svg";
  }

  // Badge above each tier — shows the points required to reach that tier
  // (from the backend's `tiers[].pointsRequired`), not a level number.
  Widget _achievementTile({required String tierName}) {
    return Obx(() {
      final pts = controller.pointsForTier(tierName);
      return Container(
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(20.sp),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              "assets/svg/bluepoint.svg",
              width: 12.r,
              height: 12.r,
            ),
            SizedBox(width: 5.w),
            Text(
              pts == null ? "— pts" : "$pts pts",
              style: GoogleFonts.notoSans(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    });
  }
}
