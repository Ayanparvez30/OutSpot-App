import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Groups/groups_controller.dart';
import 'package:shimmer/shimmer.dart';

class Groups extends GetView<GroupsController> {
  const Groups({super.key});

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
          backgroundColor: Colors.transparent,

          leading: GestureDetector(
            onTap: () {
              Get.toNamed(Routes.mainscreen);
              // Get.back();
            },
            child: Container(
              padding: EdgeInsets.all(12),
              child: UnconstrainedBox(
                child: SvgPicture.asset(
                  "assets/svg/icons/back_icon.svg",
                  width: 28.r,
                  height: 28.r,
                  // fit: BoxFit.scaleDown,
                ),
              ),
            ),
          ),
          title: Text(
            "Groups",
            style: GoogleFonts.notoSans(
              color: AppColors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),

        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: GoogleFonts.notoSans(color: AppColors.white),
                        onChanged: (value) => controller.query.value = value,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                          ),
                          hintText: "Search...",
                          hintStyle: GoogleFonts.notoSans(
                            color: AppColors.fillnoti,
                          ),
                          suffixIcon: UnconstrainedBox(
                            child: SvgPicture.asset(
                              "assets/svg/icons/searchImage.svg",
                              width: 17.w,
                              height: 17.w,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide(color: AppColors.fillnoti),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide(color: AppColors.fillnoti),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide(color: AppColors.fillnoti),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Add friend logic
                        Get.toNamed(Routes.newGroupScreen);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.circlegradient,
                              AppColors.circlegradient1,
                            ],
                          ),

                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "New Group",
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            SvgPicture.asset(
                              "assets/svg/icons/plus.svg",
                              width: 17,
                              height: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildShimmerList();
                  }
                  final filteredGroups = controller.filteredGroupChats;

                  // If no groups match the search query
                  if (filteredGroups.isEmpty) {
                    return Center(
                      child: Text(
                        controller.query.value.isEmpty
                            ? ""
                            : "No matching groups found",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredGroups.length,
                    separatorBuilder:
                        (context, index) => Divider(
                          indent: 26.w,
                          height: .6.h,
                          color: AppColors.fillnoti,
                        ), // Divider between items
                    itemBuilder: (context, index) {
                      final chat = filteredGroups[index];
                      final hasImage =
                          chat.imageUrl != null && chat.imageUrl!.isNotEmpty;
                      int totalPoints = chat.users.fold(
                        0,
                        (sum, user) => sum + user.totalPoints,
                      );
                      int thisWeekPoints = chat.users.fold(
                        0,
                        (sum, user) => sum + user.thisWeekPoints,
                      );
                      return GestureDetector(
                        onTap: () async {
                          controller.saveFavoriteGroupId(
                            chat.id,
                            chat.name ?? "",
                          );
                          await controller.getMember(chat.id);

                          Get.toNamed(
                            Routes.groupMembersPage,
                            arguments: {'groupId': chat.id ?? ''},
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 10.h,
                            horizontal: 20.w,
                          ),
                          decoration: BoxDecoration(),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.sp,
                                backgroundColor: AppColors.yellow,

                                backgroundImage:
                                    hasImage
                                        ? CachedNetworkImageProvider(
                                          chat.imageUrl!,
                                        )
                                        : null,

                                child:
                                    !hasImage
                                        ? Padding(
                                          padding: EdgeInsets.all(4.sp),
                                          child: ClipOval(
                                            child: SvgPicture.asset(
                                              "assets/svg/icons/groups.svg",
                                              colorFilter: ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                              width: 29,
                                              height: 29,
                                            ),
                                          ),
                                        )
                                        : null,
                              ),

                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  chat.name ?? 'Unknown Group',
                                  style: GoogleFonts.notoSans(
                                    color: AppColors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Spacer(),
                              // Image.asset(
                              //   "assets/Images/user.png",
                              //   scale: .9,
                              //   color: AppColors.backgroundColor,
                              // ),
                              SvgPicture.asset(
                                "assets/svg/user-alt-1-svgrepo-com (1).svg",
                                width: 10,
                                height: 12,
                                colorFilter: ColorFilter.mode(
                                  AppColors
                                      .backgroundColor, // আপনার কালার ভেরিয়েবল
                                  BlendMode.srcIn,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "${chat.users.length}",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(width: 7.w),
                              UnconstrainedBox(
                                child: SvgPicture.asset(
                                  "assets/svg/Icon-Outline-Coin-P.svg",
                                  height: 14.w,
                                  width: 13.w,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "$totalPoints",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 ২. শিমার লিস্ট জেনারেট করার ফাংশন
  Widget _buildShimmerList() {
    return ListView.separated(
      itemCount: 8, // আনুমানিক ৮টি লোডিং আইটেম দেখাবে
      separatorBuilder:
          (context, index) => Divider(
            indent: 26.w,
            height: .6.h,
            color: AppColors.fillnoti.withOpacity(0.3),
          ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.15),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
            child: Row(
              children: [
                // Avatar Placeholder
                Container(
                  width: 40.sp,
                  height: 40.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12.w),
                // Title Placeholder
                Expanded(
                  child: Container(
                    height: 16.sp,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                Spacer(),
                // Stats Placeholder (Right side)
                Container(
                  width: 80.w,
                  height: 16.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
