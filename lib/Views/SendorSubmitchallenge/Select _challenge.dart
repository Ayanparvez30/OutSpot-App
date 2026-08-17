import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/challenge_card_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_or_submid_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class SelectChallenge extends GetView<SendorSubmidController> {
  const SelectChallenge({super.key});
  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Select a Challenge",
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            color: Colors.white,
            onPressed: () {
              Get.back();
            },
            icon: SvgPicture.asset(
              "assets/svg/icons/back_icon.svg",
              width: 25.r,
              height: 25.r,
            ),

            padding: EdgeInsets.all(8.w),
            constraints: const BoxConstraints(),
          ),
        ),
        body: SafeArea(
          child: Obx(() {
            return ListView.builder(
              itemCount: controller.challenges.length,
              padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 10.h),
              itemBuilder: (_, index) {
                final c = controller.challenges[index];
                final item = controller.challenges[index];
                // final isSelected = controller.selectedChallenge.value == item;
                return GestureDetector(
                  onTap: () {
                    if (c.requiredCount > c.uploadedCount) {
                      controller.challengeId.value = c.id;

                      // controller.selectindex1.value =
                      //     !controller.selectindex1.value;
                      controller.selectindex1.value = true;
                      controller.selectedChallenges.value = c;
                      Get.back();
                    } else {
                      AppSnackbar.info(
                        "You have already uploaded all required items for this challenge",
                        title: "Required count is full",
                      );
                    }
                  },

                  child: Column(
                    children: [
                      challengeCard(c),
                      if (index < controller.challenges.length)
                        Divider(
                          height: 1.h,
                          thickness: 1.5.h,
                          color: AppColors.fillnoti,
                          indent: 19.w,
                          endIndent: 0,
                        ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget challengeCard(ChallengeCardModel c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.transparent),

            // margin: EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10.h, left: 10.w, right: 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 13.w,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  c.frequency.toUpperCase() == "DAILY"
                                      ? AppColors.SecondaryColor
                                      : AppColors.skyblue,
                              borderRadius: BorderRadius.circular(15.sp),
                            ),
                            child: Text(
                              c.frequency.toUpperCase() == "DAILY"
                                  ? "Daily Challenge"
                                  : "Weekly Challenge",

                              style: GoogleFonts.notoSans(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.sp,
                              vertical: 2.sp,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18.sp),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/Time.svg",
                                  width: 10,
                                  height: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  controller.formatTimeRemaining(
                                    c.timeRemainingMs,
                                  ),
                                  style: GoogleFonts.notoSans(
                                    color: AppColors.timeColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        c.title,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        c.preview,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                          color: AppColors.tex,
                        ),
                      ),

                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Text(
                            "${c.uploadedCount}/${c.requiredCount}",

                            style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                              color: AppColors.white,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () async {
                              if (c.requiredCount > c.uploadedCount) {
                                controller.challengeId.value = c.id;

                                // controller.selectindex1.value =
                                //     !controller.selectindex1.value;
                                controller.selectindex1.value = true;
                                controller.selectedChallenges.value = c;
                                Get.back();
                              } else {
                                AppSnackbar.info(
                                  "You have already uploaded all required items for this challenge",
                                  title: "Required count is full",
                                );
                              }
                            },
                            child: SvgPicture.asset(
                              "assets/svg/send-alt-1-svgrepo-com.svg",
                              width: 19,
                              height: 19,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14.sp),
                              border: Border.all(
                                color:
                                    c.status.toLowerCase() == "completed"
                                        ? AppColors.backgroundColor
                                        : AppColors.fillnoti,
                                width: 1.5.sp,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (c.status.toLowerCase() == "completed")
                                  SvgPicture.asset(
                                    "assets/svg/icons/Check - Thin.svg",
                                    height: 8,
                                    width: 7,
                                    // color: AppColors.backgroundColor,
                                    colorFilter: ColorFilter.mode(
                                      AppColors.backgroundColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                if (c.status.toLowerCase() == "completed")
                                  SizedBox(width: 4.w),
                                Text(
                                  c.status.toLowerCase() == "completed"
                                      ? "Completed"
                                      : "Incomplete",
                                  style: GoogleFonts.notoSans(
                                    color:
                                        c.status.toLowerCase() == "completed"
                                            ? AppColors.backgroundColor
                                            : AppColors.fillnoti,
                                    fontSize: 13.sp,
                                    fontWeight:
                                        c.status.toUpperCase() == "completed"
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 9.w),
                          c.status.toLowerCase() == "completed"
                              ? Text(
                                "Reward Received",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.grey,
                                  fontSize: 13.sp,
                                ),
                              )
                              : Text(
                                "Complete to get",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.grey,
                                  fontSize: 13.sp,
                                ),
                              ),
                          SizedBox(width: 8.w),
                          if (c.status.toLowerCase() != "completed")
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(19.sp),
                                border: Border.all(
                                  color: AppColors.yellow,
                                  width: 1.5.sp,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/svg/Icon-Outline-Coin-P.svg",
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    compactNumber(c.points),
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 15.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
