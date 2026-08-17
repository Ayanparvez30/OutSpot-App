import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/recomended_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';

class Requests extends GetView<FriendListController> {
  Requests({super.key});

  // Pagination — load 20 initially, 20 more on scroll
  static const int _pageSize = 20;
  final RxInt visibleRecommendedCount = _pageSize.obs;
  final RxInt visibleRequestsCount = _pageSize.obs;

  void loadMoreRecommended(int total) {
    if (visibleRecommendedCount.value < total) {
      visibleRecommendedCount
          .value = (visibleRecommendedCount.value + _pageSize).clamp(0, total);
    }
  }

  void loadMoreRequests(int total) {
    if (visibleRequestsCount.value < total) {
      visibleRequestsCount.value = (visibleRequestsCount.value + _pageSize)
          .clamp(0, total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: [0, 0.3],

          radius: 1.5,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.bgGradientTop,
              backgroundColor: Colors.black,
              onRefresh: () => controller.refreshAll(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  if (scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 200) {
                    loadMoreRequests(controller.requests.length);
                    loadMoreRecommended(controller.recommendedFriends.length);
                  }
                  return false;
                },
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.h),
                      itemCount: 8,
                      itemBuilder:
                          (_, __) => Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: Row(
                              children: [
                                ShimmerPlaceholder(
                                  width: 48.w,
                                  height: 48.w,
                                  radius: 24.w,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ShimmerPlaceholder(
                                        width: 140.w,
                                        height: 14.h,
                                        radius: 4,
                                      ),
                                      SizedBox(height: 8.h),
                                      ShimmerPlaceholder(
                                        width: 90.w,
                                        height: 10.h,
                                        radius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                ShimmerPlaceholder(
                                  width: 60.w,
                                  height: 28.h,
                                  radius: 14,
                                ),
                                SizedBox(width: 6.w),
                                ShimmerPlaceholder(
                                  width: 60.w,
                                  height: 28.h,
                                  radius: 14,
                                ),
                              ],
                            ),
                          ),
                    );
                  }
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        /// 🔹 Friend Requests
                        Obx(() {
                          final allFilteredRequests =
                              controller.requests.reversed
                                  .where(
                                    (f) => f.fullName.toLowerCase().contains(
                                      controller.query.value.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                          final reqVisible = visibleRequestsCount.value.clamp(
                            0,
                            allFilteredRequests.length,
                          );
                          final filteredRequests = allFilteredRequests.sublist(
                            0,
                            reqVisible,
                          );

                          if (filteredRequests.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(20.h),
                              child: Text(
                                "No requests found",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredRequests.length,
                            itemBuilder: (_, index) {
                              final f = filteredRequests[index];
                              return Column(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      _showFriendDialog(f);
                                    },
                                    child: _requestTile(f),
                                  ),
                                  if (index != filteredRequests.length - 1)
                                    Divider(
                                      color: AppColors.bgGradientTop,
                                      thickness: 0.5,
                                      height: 1,
                                    ),
                                ],
                              );
                            },
                          );
                        }),

                        SizedBox(height: 12.h),

                        /// 🔹 Recommended Friends Header
                        Container(
                          width: double.infinity,
                          color: AppColors.btnGradientLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 15.h,
                              vertical: 5.h,
                            ),
                            child: Text(
                              "Recommended ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        /// 🔹 Recommended Friends List
                        Obx(() {
                          final allFilteredRecommended =
                              controller.recommendedFriends
                                  .where(
                                    (f) =>
                                        f.username?.toLowerCase().contains(
                                          controller.query.value.toLowerCase(),
                                        ) ??
                                        false,
                                  )
                                  .toList();
                          final recVisible = visibleRecommendedCount.value
                              .clamp(0, allFilteredRecommended.length);
                          final filteredRecommended = allFilteredRecommended
                              .sublist(0, recVisible);

                          // if (filteredRecommended.isEmpty) {
                          //   return Padding(
                          //     padding: EdgeInsets.all(20.h),
                          //     child: Text(
                          //       "No recommendations found",
                          //       style: TextStyle(
                          //         fontSize: 14.sp,
                          //         color: Colors.white,
                          //       ),
                          //     ),
                          //   );
                          // }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredRecommended.length,
                            separatorBuilder:
                                (_, __) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    color:
                                        AppColors
                                            .bgGradientTop, // ichchha moto color change korte paro
                                    thickness: 0.5,
                                  ),
                                ),
                            itemBuilder: (_, index) {
                              final f = filteredRecommended[index];
                              return ListTile(
                                onTap: () {
                                  Get.toNamed(
                                    Routes.nonPrivateProfile,
                                    arguments: f.id,
                                  );
                                },
                                leading: ClipOval(
                                  child:
                                      (f.avatarUrl != null &&
                                              f.avatarUrl!.isNotEmpty)
                                          ? CachedNetworkImage(
                                            imageUrl: f.avatarUrl!,
                                            width: 50.w,
                                            height: 35.h,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.topCenter,
                                            placeholder:
                                                (context, url) =>
                                                    ShimmerPlaceholder(
                                                      width: 50.w,
                                                      height: 35.h,
                                                    ),
                                          )
                                          : Container(
                                            width: 50.w,
                                            height: 35.h,
                                            // color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                ),
                                title: Text(
                                  ((f.firstName?.isNotEmpty == true ||
                                          f.lastName?.isNotEmpty == true)
                                      ? '${f.firstName ?? ''} ${f.lastName ?? ''}'
                                          .trim()
                                      : f.username),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: _scoresRow1(f),
                                trailing:
                                    f.reason != null
                                        ? SizedBox(
                                          width: 130.w,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                f.reason!.type == "MUTUAL"
                                                    ? "Mutual Friend"
                                                    : "Community",
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (f.reason!.type ==
                                                          "MUTUAL" &&
                                                      f.reason!.via !=
                                                          null) ...[
                                                    ClipOval(
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            f
                                                                .reason!
                                                                .via!
                                                                .avatarUrl,
                                                        width: 20.w,
                                                        height: 15.h,
                                                        fit: BoxFit.cover,
                                                        alignment:
                                                            Alignment.topCenter,
                                                        placeholder:
                                                            (context, url) =>
                                                                ShimmerPlaceholder(
                                                                  width: 20.w,
                                                                  height: 15.h,
                                                                ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Flexible(
                                                      child: Text(
                                                        f.reason!.via!.username,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: Colors.white,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                  if (f.reason!.type ==
                                                          "COMMUNITY" &&
                                                      f.reason!.community !=
                                                          null) ...[
                                                    CircleAvatar(
                                                      radius: 10,
                                                      backgroundImage:
                                                          CachedNetworkImageProvider(
                                                            f
                                                                .reason!
                                                                .community!
                                                                .imageUrl,
                                                          ),
                                                      backgroundColor:
                                                          Colors.black,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Flexible(
                                                      child: Text(
                                                        f
                                                            .reason!
                                                            .community!
                                                            .name,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: Colors.white,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                        : null,
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestTile(FriendsModel f) {
    return Column(
      children: [
        SizedBox(height: 12.h),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              GestureDetector(
                child: ClipOval(
                  child:
                      (f.avatarUrl.isNotEmpty)
                          ? CachedNetworkImage(
                            imageUrl: f.avatarUrl,
                            width: 60.w, // radius * 2
                            height: 32.h,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder:
                                (context, url) => ShimmerPlaceholder(
                                  width: 70.w,
                                  height: 35.h,
                                ),
                          )
                          : Container(
                            width: 70.w,
                            height: 35.h,
                            // color: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey.shade600,
                            ),
                          ),
                ),
                // child: CircleAvatar(
                //   radius: 20,
                //   backgroundColor: Colors.grey.shade200,
                //   backgroundImage:
                //       (f.avatarUrl.isNotEmpty) ? NetworkImage(f.avatarUrl) : null,
                //   child:
                //       (f.avatarUrl.isEmpty)
                //           ? Icon(Icons.person, size: 20, color: Colors.grey.shade600)
                //           : null,
                // ),
              ),
              // SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.fullName,
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: Colors.white,
                    ),
                  ),
                  _scoresRow(f),
                ],
              ),
              Spacer(),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => controller.acceptFriendRequest(f),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "Accept",
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () {
                      controller.declineRequest(f);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        // border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "Decline",
                        style: GoogleFonts.notoSans(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 15.w),
            ],
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _scoresRow(FriendsModel f) {
    return Row(
      children: [
        SvgPicture.asset("assets/svg/level/coinshape1.svg", height: 12.h),
        SizedBox(width: 4.w),
        Text(compactNumber(f.totalPoints), style: TextStyle(color: Colors.white)),
        SizedBox(width: 5.w),
        Container(height: 10.h, width: 1.w, color: AppColors.bgGradientTop),
        SizedBox(width: 5.w),
        SvgPicture.asset("assets/svg/level/coinshape2.svg", height: 12.h),
        SizedBox(width: 4.w),
        Text(
          compactNumber(f.thisWeekPoints),
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _scoresRow1(RecommendedFriend f) {
    return Row(
      children: [
        SvgPicture.asset("assets/svg/level/coinshape1.svg", height: 12.h),
        SizedBox(width: 4.w),
        Text(compactNumber(f.totalPoints), style: TextStyle(color: Colors.white)),
        SizedBox(width: 5.w),
        Container(height: 10.h, width: 1.w, color: AppColors.bgGradientTop),
        SizedBox(width: 5.w),
        SvgPicture.asset("assets/svg/level/coinshape2.svg", height: 12.h),
        SizedBox(width: 4.w),
        Text(
          compactNumber(f.thisWeekPoints),
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  void _showFriendDialog(FriendsModel friend) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, right: 8.0),
                      child: Image.asset(
                        'assets/Images/close-svgrepo-com (4).png',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // CircleAvatar(
                //   radius: 70.r,
                //   backgroundColor: Colors.grey.shade200,
                //   backgroundImage:
                //       (friend.avatarUrl.isNotEmpty)
                //           ? NetworkImage(friend.avatarUrl)
                //           : null,
                //   child:
                //       (friend.avatarUrl.isEmpty)
                //           ? Icon(Icons.person, size: 40.r, color: Colors.grey)
                //           : null,
                // ),
                ClipOval(
                  child:
                      (friend.avatarUrl.isNotEmpty)
                          ? CachedNetworkImage(
                            imageUrl: friend.avatarUrl,
                            width: 200.w, // radius * 2
                            height: 100.h,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder:
                                (context, url) => ShimmerPlaceholder(
                                  width: 200.w,
                                  height: 100.h,
                                ),
                          )
                          : Container(
                            width: 48.w,
                            height: 48.h,
                            // color: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey.shade600,
                            ),
                          ),
                ),
                SizedBox(height: 15.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      friend.firstName.isNotEmpty
                          ? friend.firstName
                          : 'No name',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      friend.lastName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  '@${friend.username}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
                SizedBox(height: 8.h),
                Divider(color: AppColors.bgGradientTop),
                SizedBox(height: 15.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _scoreColumn(
                        title: 'Overall',
                        icon: 'assets/svg/level/coinshape1.svg',
                        value: compactNumber(friend.totalPoints),
                      ),
                      Container(
                        width: 1,
                        height: 8.h,
                        color: AppColors.bgGradientTop,
                      ),
                      _scoreColumn(
                        title: 'This Week',
                        icon: 'assets/svg/level/coinshape2.svg',
                        value: compactNumber(friend.thisWeekPoints),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    SizedBox(
                      width: 140.w,
                      height: 45.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff6A4BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        onPressed: () {
                          Get.back(); // close the dialog first
                          Get.toNamed(
                            Routes.nonPrivateProfile,

                            // arguments: friend.id,
                            arguments: friend,
                            // arguments: {"Id": friend.id},
                          );
                        },

                        child: Text(
                          'View Profile',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    SizedBox(
                      width: 140.w,
                      height: 45.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff42D880),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),

                        onPressed: () {
                          controller.acceptFriendRequest(friend);
                          Get.back();
                        },

                        child: Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreColumn({
    required String icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            SvgPicture.asset(icon, height: 16.h),
            SizedBox(width: 6.w),
            Text(value, style: TextStyle(fontSize: 16.sp, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _roundIcon(String image, Color bg) => Container(
    padding: EdgeInsets.all(10.r),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Image.asset(image, color: Colors.white),
  );
}
