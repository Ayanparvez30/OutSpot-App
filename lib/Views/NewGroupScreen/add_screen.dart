import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Views/NewGroupScreen/new_group_screen_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class AddScreen extends GetView<NewGroupScreenController> {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NewGroupScreenController());
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
              Get.back();
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
            'Add To Group',

            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                TextFormField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(
                      left: 25.w,
                      top: 12.h,
                      bottom: 12.h,
                    ),
                    hintText: "Search Friends",
                    hintStyle: GoogleFonts.notoSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
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
                      borderSide: BorderSide(
                        color: AppColors.fillnoti,
                        width: 1.5.w,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(
                        color: AppColors.fillnoti,
                        width: 1.5.w,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(
                        color: AppColors.fillnoti,
                        width: 1.5.w,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  style: GoogleFonts.notoSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                  ),
                  onChanged: (value) => controller.query.value = value,
                ),

                Expanded(
                  child: Obx(() {
                    final friendsToShow = controller.filteredFriends;
                    if (friendsToShow.isEmpty) {
                      return Center(
                        child: Text(
                          "No friends found",
                          style: GoogleFonts.notoSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.all(16.h),
                      itemCount: friendsToShow.length,
                      separatorBuilder:
                          (_, __) => Divider(color: AppColors.fillnoti),
                      itemBuilder: (context, index) {
                        final friend = friendsToShow[index];

                        return GestureDetector(
                          onTap: () {
                            controller.toggleFriendSelection(friend);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatar(friend.avatarUrl),

                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      friend.fullName,
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.sp,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        // Image.asset(
                                        //   "assets/Images/coinshape1.png",
                                        // ),
                                        UnconstrainedBox(
                                          child: SvgPicture.asset(
                                            "assets/svg/bluepoint.svg",
                                            height: 14.w,
                                            width: 13.w,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          compactNumber(friend.totalPoints),
                                          style: GoogleFonts.notoSans(
                                            fontSize: 12.sp,
                                            color: AppColors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Container(
                                          height: 10.h,
                                          width: 1.5.w,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 8.w),
                                        UnconstrainedBox(
                                          child: SvgPicture.asset(
                                            "assets/svg/Icon-Outline-Coin-P.svg",
                                            height: 14.w,
                                            width: 13.w,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          compactNumber(friend.thisWeekPoints),
                                          style: GoogleFonts.notoSans(
                                            fontSize: 12.sp,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Add check icon if selected
                              Obx(() {
                                final selected = controller.isSelected(friend);
                                return Container(
                                  height: 35.w,
                                  width: 35.w,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        AppColors.circlegradient,
                                        AppColors.circlegradient1,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    // border: Border.all(
                                    //   color: Color(0xffE8EAEB),
                                    //   width: .9.w,
                                    // ),
                                  ),
                                  child:
                                      selected
                                          // ? Icon(
                                          //   Icons.check,
                                          //   color:
                                          //       selected
                                          //           ? Colors.white
                                          //           : Colors.transparent,
                                          // )
                                          ? UnconstrainedBox(
                                            child: SvgPicture.asset(
                                              "assets/svg/icons/Check - Thin.svg",
                                              height: 14.w,
                                              width: 13.w,
                                            ),
                                          )
                                          : SizedBox(),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                // Spacer(),
                CustomWidgets().CustomButton(
                  text: "Done",
                  onPressed: () {
                    if (controller.groupId.value != null &&
                        controller.groupId.value > 0) {
                      log("addmember");
                      controller.addmember();
                    } else if (controller.newGroupController.text
                        .trim()
                        .isEmpty) {
                      AppSnackbar.error("Please enter a group name.");
                    } else if (controller.selectedFriendIds.isEmpty) {
                      AppSnackbar.error(
                        "Please select friends to add to the group.",
                      );
                    } else {
                      log("createGroupChat");
                      controller.createGroupChat();
                    }
                  },
                ),
                SizedBox(height: 35.h),
              ],
            ),
          ),
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
