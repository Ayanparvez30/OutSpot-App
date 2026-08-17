import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/challenge_card_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Challenges/challenge_controller.dart';
import 'package:outspot/Views/Challenges/photoviewer.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:shimmer/shimmer.dart';

class ChallengeScreen extends GetView<ChallengeController> {
  const ChallengeScreen({super.key});
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
          scrolledUnderElevation: 0,

          // backgroundColor: Color(0xffFFFFFF),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.only(left: 18.w),
            child: GestureDetector(
              onTap: () {
                Get.toNamed(Routes.myProfile);
              },
              child: Obx(() {
                // Read the LIVE avatar from MyProfileController (updated via
                // updateAvatarLocal whenever the profile pic changes), so this
                // header avatar refreshes immediately — like the explore page.
                // Falls back to the challenge controller's value if not loaded.
                final mp = MyProfileController.instance;
                final imageUrl =
                    mp.avatarurl.value.isNotEmpty
                        ? mp.avatarurl.value
                        : controller.avatarurl.value;

                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      width: 40.w,
                      height: 30.h,

                      placeholder: (context, url) => const ShimmerPlaceholder(),
                      errorWidget:
                          (context, url, error) =>
                              const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                );
              }),
            ),
          ),

          title: GestureDetector(
            onTap: () {
              Get.toNamed(Routes.viewAchievements);
            },
            child: Obx(() {
              final accontroller = Get.find<MainscreeenController>();
              final ttl = accontroller.myAchievements.value?.title;

              double iconHeight = 30.h;

              String imagePath;
              if (ttl == "Urban Explorer") {
                imagePath = "assets/svg/level/urbar_explorer.svg";
              } else if (ttl == "Legendary Explorer") {
                imagePath = "assets/svg/level/legendary_explorer.svg";
              } else if (ttl == "City Sniper") {
                imagePath = "assets/svg/level/city_snipper.svg";
              } else if (ttl == "New Explorer") {
                imagePath = "assets/svg/level/new_explorer.svg";
              } else {
                imagePath = "assets/svg/level/new_explorer.svg";
              }

              return SvgPicture.asset(
                imagePath,
                height: iconHeight,
                fit: BoxFit.contain,
              );
            }),
          ),

          actions: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.leaderboardGlobal);
                  },
                  child: SvgPicture.asset(
                    "assets/svg/icons/dashBoardIcon.svg",
                    height: 34.w,
                    width: 34.w,
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () {
                    controller.clearNotificationDot();
                    Get.toNamed(Routes.notification1);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Notification icon container
                      Container(
                        margin: EdgeInsets.only(right: 10.w),
                        width: 34.w,
                        height: 34.w,
                        padding: EdgeInsets.all(5.sp),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.fillnoti,
                          // border: Border.all(color: AppColors.yellow),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/svg/icons/notification_icon.svg",
                            height: 18.sp,
                            width: 18.sp,
                          ),
                        ),
                      ),

                      // 🔴 Red dot (reactive)
                      Obx(() {
                        return controller.notificationRedDot.value
                            ? Positioned(
                              right: 10,
                              top: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            : const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          // Run content to the bottom edge (like Explore) so the bottom
          // safe-area strip isn't an empty "dead space".
          bottom: false,
          child:
          // Obx(
          //   () =>
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),

                Obx(
                  () => Row(
                    children: List.generate(controller.explore.length, (index) {
                      final isSel = controller.selected.value == index;
                      return GestureDetector(
                        onTap: () => controller.selectIndex(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: 10.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            // Selected → brand gradient pill (high contrast);
                            // unselected → subtle dark outlined pill so the
                            // active tab clearly stands out.
                            gradient:
                                isSel
                                    ? const LinearGradient(
                                      colors: [
                                        Color(0xFFAB50F6),
                                        Color(0xFFFB7D6C),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                    : null,
                            color:
                                isSel ? null : Colors.white.withOpacity(0.06),
                            border:
                                isSel
                                    ? null
                                    : Border.all(
                                      color: Colors.white.withOpacity(0.18),
                                      width: 1,
                                    ),
                            borderRadius: BorderRadius.circular(20.sp),
                            boxShadow:
                                isSel
                                    ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFAB50F6,
                                        ).withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            controller.explore[index],
                            style: GoogleFonts.notoSans(
                              fontSize: 12.sp,
                              color:
                                  isSel
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.6),
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                SizedBox(height: 17.h),

                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: 3,
                        itemBuilder: (_, __) => _shimmerCard(),
                      );
                    }

                    if (controller.filtered.isEmpty) {
                      final emptyTitle =
                          controller.selected.value == 1
                              ? "No challenges in progress"
                              : controller.selected.value == 2
                              ? "No completed challenges yet"
                              : "No challenges available";
                      final emptySubtitle =
                          controller.selected.value == 1
                              ? "Start a challenge by uploading your first entry"
                              : controller.selected.value == 2
                              ? "Complete a challenge to see it here"
                              : "";
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                emptyTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (emptySubtitle.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Text(
                                    emptySubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    final list = controller.filtered;
                    return ListView.builder(
                      controller: controller.listScrollController,
                      physics: const BouncingScrollPhysics(),
                      // Clear the floating bottom nav bar + device safe-area
                      // (home indicator) so cards don't peek in the gap below
                      // the nav bar on iOS.
                      padding: EdgeInsets.only(
                        bottom:
                            110.h + MediaQuery.of(context).viewPadding.bottom,
                      ),
                      // +1 trailing slot for the pagination loader (history tabs).
                      itemCount:
                          list.length +
                          (controller.historyLoadingMore.value ? 1 : 0),
                      itemBuilder: (_, idx) {
                        if (idx >= list.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          );
                        }
                        final c = list[idx];
                        return GestureDetector(
                          onTap:
                              () => Get.toNamed(
                                Routes.dailyChallenge,
                                arguments: c,
                              ),
                          child: challengeCard(c),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      // ),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        margin: EdgeInsets.only(bottom: 18.h),
        height: 250.h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10.sp),
        ),
      ),
    );
  }

  Widget tabBtn(String text, int idx, ChallengeController controller) {
    return Obx(
      () => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              controller.selectedTab.value == idx
                  ? Colors.black
                  : Colors.grey[200],
          foregroundColor:
              controller.selectedTab.value == idx ? Colors.white : Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          shape: StadiumBorder(),
          elevation: 0,
        ),
        onPressed: () => controller.selectedTab.value = idx,
        child: Text(text),
      ),
    );
  }

  Widget challengeCard(ChallengeCardModel c) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.fillnoti, width: 1.2.w),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(9.sp),
              topRight: Radius.circular(9.sp),
              bottomRight: Radius.circular(10.sp),
              bottomLeft: Radius.circular(10.sp),
            ),
          ),

          margin: EdgeInsets.only(bottom: 18),
          child: Column(
            children: [
              Stack(
                children: [
                  // Background image (avatarurl)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6.sp),
                      topRight: Radius.circular(6.sp),
                    ),
                    child: Image.asset(
                      c.frequency.toUpperCase() == "DAILY"
                          ? "assets/Images/skdaileychallange.png"
                          : "assets/Images/skweeklychallanges .png",

                      width: double.infinity,
                      height: 200.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.h, left: 10.w, right: 9.w),
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
                                // "${c.frequency} Challenge",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                            Spacer(),
                            // if (c.status.toUpperCase() == "in_progress")
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.sp,
                                vertical: 3.sp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(18.sp),
                              ),
                              child: Row(
                                children: [
                                  // Image.asset(
                                  //   "assets/Images/skclock.png",
                                  //   scale: 2.3,
                                  //   color: AppColors.white,
                                  // ),
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
                                      color: AppColors.white,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 18.sp,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          c.preview,
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            color: AppColors.white,
                          ),
                        ),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 6.h,
                    left: 10.w,
                    right: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _photosRow(c),
                    ),
                  ),
                  SizedBox(height: 15.h),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.h, bottom: 10.h, left: 10.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14.sp),
                        border: Border.all(
                          width: 1.4.w,
                          color: AppColors.fillnoti,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            c.status.toLowerCase() == "completed"
                                ? "Completed"
                                : "Incomplete",
                            style: GoogleFonts.notoSans(
                              color: AppColors.tex,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          c.status.toUpperCase() != "completed"
                              ? Container(
                                margin: EdgeInsets.only(left: 5.w),
                                padding: EdgeInsets.symmetric(
                                  vertical: 2.h,
                                  horizontal: 6.w,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(13.sp),
                                ),
                                child: Row(
                                  children: [
                                    // Image.asset(
                                    //   "assets/Images/skpppp.png",
                                    //   width: 10,
                                    //   height: 12,
                                    //   color: AppColors.white,
                                    // ),
                                    SvgPicture.asset(
                                      "assets/svg/user-alt-1-svgrepo-com (1).svg",
                                      width: 10,
                                      height: 12,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "${c.uploadedCount}/${c.requiredCount}",
                                      style: GoogleFonts.notoSans(
                                        color: AppColors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SizedBox(),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Row(
                      children: [
                        Text(
                          c.requiredCount == c.uploadedCount
                              ? "Reward Received"
                              : "Complete to get",
                          style: GoogleFonts.notoSans(
                            color: AppColors.readUnread,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // if (c.status.toUpperCase() == "incomplete")
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
                              // Image.asset(
                              //   "assets/Images/skcoin.png",
                              //   scale: 2.5,
                              // ),
                              SvgPicture.asset(
                                "assets/svg/Icon-Outline-Coin-P.svg",
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                compactNumber(c.points),
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photosRow(ChallengeCardModel c) {
    return Obx(() {
      final photos =
          controller.submissions
              .where((m) {
                final mid = m['challengeId'];
                final cid = c.id;
                return (mid?.toString() ?? '') == cid.toString();
              })
              .map((m) => (m['mediaUrl'] ?? '').toString())
              .where((u) => u.isNotEmpty)
              .toList();

      final isFull = photos.length >= (c.requiredCount ?? 0);
      final visiblePhotos = photos.toList();

      return SizedBox(
        height: 55.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            ...List.generate(
              visiblePhotos.length,
              (i) => Padding(
                padding: EdgeInsets.only(right: 12.w, top: 5.h),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap:
                          () => controller.showPhotoViewer(
                            Get.context!,
                            photos,
                            i,
                          ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.circlegradient,
                              AppColors.circlegradient1,
                            ],
                          ),
                        ),
                        padding: EdgeInsets.all(2.w),
                        child: Container(
                          width: 48.sp,
                          height: 48.sp,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: visiblePhotos[i],
                              fit: BoxFit.cover,

                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.white.withOpacity(0.1),
                                    highlightColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    child: Container(color: Colors.black),
                                  ),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {},
                        // child: Container(
                        //   decoration: const BoxDecoration(
                        //     color: Colors.transparent,
                        //     shape: BoxShape.circle,
                        //   ),
                        //   padding: const EdgeInsets.all(3),
                        //   child: SvgPicture.asset(
                        //     "assets/svg/checkCircleicon.svg",

                        //     fit: BoxFit.cover,
                        //   ),
                        // ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 1.5),
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.check,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isFull)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: DottedBorder(
                  borderType: BorderType.Circle,
                  dashPattern: const [3, 3],
                  color: Colors.white,
                  strokeWidth: 1.5,
                  child: SizedBox(
                    width: 43.sp,
                    height: 43.sp,
                    child: const CircleAvatar(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
