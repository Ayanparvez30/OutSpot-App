import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/No%20Community/memberPage.dart';
import 'package:outspot/Views/No%20Community/noCommunity.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';

class SearchCommunity extends StatelessWidget {
  const SearchCommunity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NocommunityController());

    // Refresh joined/created lists every time the screen opens
    // so stale data from previous sessions is cleared
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMyCommunities();
      controller.fetchInitialCommunities();
    });

    return WillPopScope(
      onWillPop: () async {
        Get.to(
          () => const Nocommunity(),
          transition: Transition.fadeIn,
          duration: 200.milliseconds,
        );
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
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
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Search Communities',
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 10.w, top: 5.h),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/svg/icons/Cross.svg',
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Get.to(
                      () => const Nocommunity(),
                      transition: Transition.fadeIn,
                      duration: 200.milliseconds,
                    );
                    // Get.until(
                    //   (route) => route.settings.name == Routes.noCommunity,
                    // );
                  },
                ),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
            child: Column(
              children: [
                TextField(
                  onChanged: controller.filterCommunities,
                  cursorColor: AppColors.white,
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search ...',
                    hintStyle: GoogleFonts.notoSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inputBorderColor,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/svg/icons/searchImage.svg',
                        height: 16.h,
                        width: 16.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide(color: AppColors.inputBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide(color: AppColors.inputBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide(color: AppColors.inputBorderColor),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.filteredCommunities.isEmpty) {
                      return _buildShimmerList();
                    }

                    if (controller.filteredCommunities.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Communities Found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.filteredCommunities.length,
                            separatorBuilder:
                                (context, index) => Divider(
                                  color: AppColors.btnGradientLeft.withOpacity(
                                    0.3,
                                  ),
                                  thickness: 0.5,
                                ),
                            itemBuilder: (context, index) {
                              final community =
                                  controller.filteredCommunities[index];
                              final int communityId = community['id'] ?? 0;

                              return Obx(() {
                                final bool isMember = controller.isUserMember(
                                  communityId,
                                );
                                final bool isCreator = controller.isUserCreator(
                                  communityId,
                                );
                                final bool hasAnyCommunity =
                                    controller.joinedCommunities.isNotEmpty ||
                                    controller.createdCommunities.isNotEmpty;

                                return ListTile(
                                  onTap:
                                      () => Get.toNamed(
                                        Routes.community,
                                        arguments: {"id": communityId},
                                      ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                  ),
                                  leading: Builder(
                                    builder: (_) {
                                      final bool hasImage =
                                          community['imageUrl'] != null &&
                                          community['imageUrl'] != "";
                                      // No image → show a people icon on a soft
                                      // orange circle, same as MyProfile.
                                      return CircleAvatar(
                                        radius: 25.r,
                                        backgroundColor:
                                            hasImage
                                                ? AppColors.appBackground
                                                : Colors.orangeAccent
                                                    .withOpacity(0.2),
                                        backgroundImage:
                                            hasImage
                                                ? CachedNetworkImageProvider(
                                                  community['imageUrl'],
                                                )
                                                : null,
                                        child:
                                            hasImage
                                                ? null
                                                : Icon(
                                                  Icons.people_outline,
                                                  color: Colors.orangeAccent,
                                                  size: 24.r,
                                                ),
                                      );
                                    },
                                  ),
                                  title: Text(
                                    community['name'] ?? "Community",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svg/icons/friends1.svg',
                                        width: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "${community['membersCount'] ?? 0}",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing:
                                      (isMember || isCreator)
                                          ? Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xff703A8B),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            child: Text(
                                              "Joined",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 22.w,
                                              vertical: 8.h,
                                            ),
                                          )
                                          : SizedBox(
                                            width: 85.w,
                                            height: 32.h,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if (hasAnyCommunity) {
                                                  _showAlreadyJoinedDialog();
                                                } else {
                                                  await controller
                                                      .joinCommunity(
                                                        communityId,
                                                      );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xff704EF9,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        20.r,
                                                      ),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Text(
                                                'Join Now',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                );
                              });
                            },
                          ),

                          if (controller.hasMoreData.value &&
                              controller.filteredCommunities.length >= 10)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 25.h),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white10,
                                          thickness: 1,
                                          indent: 10.w,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                        ),
                                        child:
                                            controller.isMoreLoading.value
                                                ? const CircularProgressIndicator(
                                                  color: Color(0xff704EF9),
                                                  strokeWidth: 2,
                                                )
                                                : Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 6.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xff703A8B),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                  ),
                                                  child: GestureDetector(
                                                    onTap:
                                                        () =>
                                                            controller
                                                                .loadMoreCommunities(),

                                                    child: Text(
                                                      "View ${controller.take} more",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white10,
                                          thickness: 1,
                                          endIndent: 10.w,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xff2D0731),
          highlightColor: const Color(0xff4A148C),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                CircleAvatar(radius: 25, backgroundColor: Colors.white24),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 10.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlreadyJoinedDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: const Color(
          0xff1A041D,
        ), // আরও ডিপ এবং লাক্সারি লুকের জন্য ডার্ক টোন
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // কাস্টম আইকন কন্টেইনার
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xff704EF9).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xff704EF9).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: const Color(0xff704EF9),
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 24.h),

              // হেডলাইন
              Text(
                'Limit Reached', // প্রফেশনাল টার্মিনোলজি
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // ডেসক্রিপশন
              Text(
                'To maintain community quality, you can only be a member of one community at a time.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // প্রফেশনাল বাটন লেআউট
              Row(
                children: [
                  // Expanded(
                  //   child: TextButton(
                  //     onPressed: () => Get.back(),
                  //     style: TextButton.styleFrom(
                  //       padding: EdgeInsets.symmetric(vertical: 14.h),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12.r),
                  //       ),
                  //     ),
                  //     child: Text(
                  //       'Dismiss',
                  //       style: TextStyle(
                  //         color: Colors.white60,
                  //         fontSize: 15.sp,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff704EF9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(Colors.white10),
                      ),
                      child: Text(
                        'Understood',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withOpacity(0.85),
      transitionCurve: Curves.easeInOutBack, // স্মুথ পপ-আপ এনিমেশন
    );
  }
}
