import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/challange_others_user_model.dart';
import 'package:outspot/Model/challenge_card_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Views/Challenges/ChallengeManager.dart';
import 'package:outspot/Views/Challenges/challenge_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:shimmer/shimmer.dart';

class DailyChallenge extends GetView<ChallengeController> {
  DailyChallenge({super.key});

  final controller = Get.find<ChallengeController>();
  final ChallengeCardModel c = Get.arguments;

  @override
  Widget build(BuildContext context) {
    // controller.fetchOtherSubmissionsSingle(c.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchOtherSubmissionsSingle(c.id);
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
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Container(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 12.w),
                          child: GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              child: UnconstrainedBox(
                                child: SvgPicture.asset(
                                  "assets/svg/icons/back_icon.svg",
                                  width: 25.r,
                                  height: 25.r,
                                  // fit: BoxFit.scaleDown,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.only(left: 67.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  c.frequency.toUpperCase() == "DAILY"
                                      ? AppColors.yellow
                                      : Colors.blue,
                              borderRadius: BorderRadius.circular(14.sp),
                            ),
                            child: Text(
                              c.frequency.toUpperCase() == "DAILY"
                                  ? "Daily Challenge"
                                  : "Weekly Challenge",
                              // "${c.frequency} Challenge",
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                        Spacer(),

                        Padding(
                          padding: EdgeInsets.only(right: 15.w),
                          child: Container(
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
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        c.title,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 24.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        textAlign: TextAlign.center,
                        c.preview,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 9.h),
                    photos(c),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
              width: double.infinity,
              // height: 265.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                image: DecorationImage(
                  image: AssetImage(
                    c.frequency.toUpperCase() == "DAILY"
                        ? "assets/Images/skdaileychallange.png"
                        : "assets/Images/skweeklychallanges .png",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 50.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
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
                    child: Text(
                      c.status.toLowerCase() == "completed"
                          ? "Completed"
                          : "Incomplete",
                      style: GoogleFonts.notoSans(
                        color: AppColors.fillnoti,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    c.status.toLowerCase() == "completed"
                        ? "Reward Received"
                        : "Complete to get",
                    style: GoogleFonts.notoSans(color: AppColors.readUnread),
                  ),
                  SizedBox(width: 7),
                  // if (c.status.toLowerCase() == "incomplete")
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 1.2.h,
                      horizontal: 4.w,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.sp),
                      border: Border.all(width: 1.w, color: Color(0xffFAC139)),
                    ),
                    child: Row(
                      children: [
                        // Image.asset("assets/Images/skcoin.png", scale: 2),
                        SvgPicture.asset("assets/svg/Icon-Outline-Coin-P.svg"),
                        SizedBox(width: 3.w),
                        Text(
                          compactNumber(c.points),
                          style: GoogleFonts.notoSans(
                            color: AppColors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Padding(
              padding: EdgeInsets.only(left: 15.w, right: 12.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Others who completed this",
                      style: GoogleFonts.notoSans(
                        color: AppColors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Newest / Oldest filter
                  Obx(() {
                    final newest = controller.participantsSortNewest.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.fillnoti,
                          width: 1.2.w,
                        ),
                        borderRadius: BorderRadius.circular(20.sp),
                      ),
                      child: PopupMenuButton<bool>(
                        color: AppColors.bgGradientBottom,
                        initialValue: newest,
                        padding: EdgeInsets.zero,
                        onSelected: controller.setParticipantsSort,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.sp),
                        ),
                        itemBuilder:
                            (_) => [
                              PopupMenuItem(
                                value: true,
                                child: Text(
                                  "Newest",
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: false,
                                child: Text(
                                  "Oldest",
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort,
                                color: AppColors.white,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                newest ? "Newest" : "Oldest",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.white,
                                size: 18.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                // 🟢 Shimmer Loading Logic
                if (controller.isLoading.value) {
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 5, // কয়টি ফেক রো দেখাবে
                    separatorBuilder:
                        (_, __) => Divider(
                          thickness: 1,
                          color: AppColors.fillnoti,
                          indent: 17.w,
                          endIndent: 17.w,
                        ),
                    itemBuilder: (_, __) => _buildShimmerTile(),
                  );
                }

                // এম্পটি স্টেট
                if (controller.otherParticipantSummaries.isEmpty) {
                  return Center(
                    child: Text(
                      "This challenge has not been completed by any user yet.",
                      style: GoogleFonts.notoSans(
                        color: AppColors.white,
                        fontSize: 15.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // ডাটা লোড হওয়ার পর আসল লিস্ট
                // client-side infinite scroll over the windowed list
                final visible = controller.otherParticipantSummaries;
                final hasMore = controller.hasMoreParticipants;
                return NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll.metrics.pixels >=
                            scroll.metrics.maxScrollExtent - 300 &&
                        hasMore) {
                      controller.loadMoreParticipants();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    // +1 row for the bottom loader while more remain.
                    itemCount: visible.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= visible.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffC574F7),
                              ),
                            ),
                          ),
                        );
                      }
                      final user = visible[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openProfile(user),
                          child: completedUserTile(user),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      // No divider directly above the bottom loader.
                      if (hasMore && index >= visible.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Divider(
                        thickness: 1,
                        color: AppColors.fillnoti,
                        indent: 17.w,
                        endIndent: 17.w,
                      );
                    },
                  ),
                );
              }),
            ),
            if (c.uploadedCount < c.requiredCount)
              Padding(
                padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 30.h),
                child: GestureDetector(
                  onTap: () {
                    ChallengeManager.instance.saveChallenge(c);
                    Get.offAllNamed(Routes.mainscreen, arguments: {'tab': 2});
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.btnGradientLeft,
                          AppColors.btnGradientRight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // center e ana
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset("assets/svg/camera.svg"),
                        SizedBox(width: 8.w),
                        Text(
                          "Snap a Pic",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget photos(ChallengeCardModel c) {
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

    if (photos.isEmpty) {
      return Container(
        height: 80.h,
        child: Center(
          child: DottedBorder(
            borderType: BorderType.Circle,
            dashPattern: [3, 3],
            color: Colors.white,
            strokeWidth: 2,
            child: CircleAvatar(
              radius: 22.sp,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      );
    } else {
      return Container(
        // 🔥 Height ektu barano hoyeche jate icon overflow na hoy
        height: 80.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior:
              Clip.none, // 🔥 Scroll area-teo clip bondho kora hoyeche
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...List.generate(
                photos.length,
                (i) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Stack(
                    clipBehavior: Clip.none, // 🔥 Very Important
                    children: [
                      // Main Image Circle
                      GestureDetector(
                        onTap:
                            () => controller.showPhotoViewer(
                              Get.context!,
                              photos,
                              i,
                            ),
                        child: Container(
                          margin: EdgeInsets.only(
                            top: 8.h,
                          ), // 🔥 Check icon er jonno upor theke ektu niche namano hoyeche
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
                          padding: EdgeInsets.all(2.7.w),
                          child: Container(
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 23.sp,
                              backgroundImage: CachedNetworkImageProvider(
                                photos[i],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ✅ Check Icon - Positioned adjust kora hoyeche
                      Positioned(
                        right: 0,
                        top:
                            4.h, // 🔥 Image container-er margin-er sathe match kore set kora hoyeche
                        // child: Container(
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     color:
                        //         Colors
                        //             .transparent, // Background lagle white dite paren
                        //   ),
                        //   child: SvgPicture.asset(
                        //     "assets/svg/checkCircleicon.svg",
                        //     width: 20.sp, // Icon size adjust
                        //     height: 20.sp,
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
                    ],
                  ),
                ),
              ),

              if (!isFull)
                Padding(
                  padding: EdgeInsets.only(
                    left: 10.w,
                    top: 8.h,
                  ), // Top padding image er sathe milate
                  child: DottedBorder(
                    borderType: BorderType.Circle,
                    dashPattern: [3, 3],
                    color: Colors.white,
                    strokeWidth: 2,
                    child: CircleAvatar(
                      radius: 22.sp,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget completedUserTile(ParticipantSummary user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 17.w),
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 5.h),
              // Red ring removed per request — plain avatar.
              child: _buildAvatar(user.avatarUrl),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: GoogleFonts.notoSans(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      // Image.asset("assets/Images/skcoinn.png", scale: 2.3),
                      SvgPicture.asset("assets/svg/bluepoint.svg"),
                      SizedBox(width: 3),
                      Text(
                        compactNumber(user.totalPoints),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7.w),
                        child: SizedBox(
                          width: 8,
                          child: Text(
                            "|",
                            style: GoogleFonts.notoSans(
                              color: AppColors.fillnoti,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SvgPicture.asset("assets/svg/Icon-Outline-Coin-P.svg"),
                      SizedBox(width: 3),
                      Text(
                        compactNumber(user.weeklyPoints),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      // SizedBox(width: 8),
                    ],
                  ),
                  // SizedBox(height: 4.h),
                  if (user.relationship.isFriend ||
                      user.relationship.sharedCommunities.isNotEmpty ||
                      user.relationship.sharedGroups.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (user.relationship.isFriend)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.fillnoti,
                                  width: 1.4.w,
                                ),
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(13.sp),
                              ),
                              child: Row(
                                children: [
                                  // Image.asset(
                                  //   "assets/Images/skpppp.png",
                                  //   width: 12,
                                  //   height: 12,
                                  //   color: AppColors.fillnoti,
                                  // ),
                                  Text(
                                    "Friend",
                                    style: GoogleFonts.notoSans(
                                      color: AppColors.fillnoti,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(width: 6.w),
                          if (user.relationship.sharedCommunities.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.fillnoti,
                                  width: 1.4.w,
                                ),
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(13.sp),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    user
                                            .relationship
                                            .sharedCommunities
                                            .isNotEmpty
                                        ? user
                                            .relationship
                                            .sharedCommunities
                                            .first
                                            .toString()
                                        : " ",
                                    style: GoogleFonts.notoSans(
                                      color: AppColors.fillnoti,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(width: 6.w),
                          if (user.relationship.sharedGroups.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.fillnoti,
                                  width: 1.4.w,
                                ),
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(13.sp),
                              ),
                              child: Row(
                                children: [
                                  // Image.asset(
                                  //   "assets/Images/2person.png",

                                  //   width: 12.w,
                                  //   height: 15.w,
                                  // ),
                                  Text(
                                    user.relationship.sharedGroups.isNotEmpty
                                        ? user.relationship.sharedGroups.first
                                            .toString()
                                        : " ",
                                    style: GoogleFonts.notoSans(
                                      color: AppColors.fillnoti,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open the tapped participant's profile. Tapping yourself → your own
  // profile; a friend → the rich friends profile; anyone else → non-private
  // profile. Friend status comes straight from the relationship in the data.
  Future<void> _openProfile(ParticipantSummary user) async {
    if (user.userId == 0) return;
    final myId = await UserPreference.getUserId();
    if (myId == user.userId) {
      Get.toNamed(Routes.myProfile);
      return;
    }
    Get.toNamed(
      user.relationship.isFriend
          ? Routes.friendsProfile
          : Routes.nonPrivateProfile,
      arguments: {'id': user.userId},
    );
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.15),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 20.r, backgroundColor: Colors.black),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100.w, height: 12.h, color: Colors.black),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(width: 40.w, height: 10.h, color: Colors.black),
                    SizedBox(width: 10.w),
                    Container(width: 40.w, height: 10.h, color: Colors.black),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(width: 60.w, height: 10.h, color: Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    final size = 36.w;
    final hasUrl = (url != null && url.isNotEmpty);
    if (!hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.person),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: CachedNetworkImage(
        alignment: Alignment.topCenter,
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerPlaceholderCircle(size: size),
        errorWidget:
            (_, __, ___) => SizedBox(
              width: size,
              height: size,
              child: const Icon(Icons.person),
            ),
      ),
    );
  }
}
