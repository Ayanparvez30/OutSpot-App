import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';

import 'package:outspot/utils/routes.dart';
import 'friendList_controller.dart';

class SearchUser extends GetView<FriendListController> {
  SearchUser({super.key});

  // Pagination
  static const int _pageSize = 20;
  final RxInt visibleCount = _pageSize.obs;

  void _loadMore(int total) {
    if (visibleCount.value < total) {
      visibleCount.value = (visibleCount.value + _pageSize).clamp(0, total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.clearSearch();
        Get.back();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            center: Alignment.topRight,
            stops: [0.1, 0.5],

            radius: 1.5,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,

          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              "Search Users",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: [
              GestureDetector(
                onTap: () {
                  controller.clearSearch();
                  Get.back();
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 20.w),
                  child: SvgPicture.asset(
                    'assets/svg/icons/Cross.svg',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                child: TextField(
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Search users…",
                    hintStyle: TextStyle(color: AppColors.fillnoti),
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/svg/icons/searchImage.svg',
                        height: 16.h,
                        width: 16.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 5.h,
                      horizontal: 16.w,
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
                      borderSide: BorderSide(color: AppColors.fillnoti),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (controller.isSearching.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.searchResults.isEmpty) {
                    return const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final total = controller.searchResults.length;
                  final count = visibleCount.value.clamp(0, total);
                  final items = controller.searchResults.sublist(0, count);
                  final hasMore = count < total;

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >=
                              scroll.metrics.maxScrollExtent - 200 &&
                          hasMore) {
                        _loadMore(total);
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      itemCount: items.length + (hasMore ? 1 : 0),
                      separatorBuilder:
                          (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Divider(
                              color: AppColors.MainColor,
                              thickness: 1,
                            ),
                          ),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xffC574F7),
                                ),
                              ),
                            ),
                          );
                        }
                        final user = items[index];

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final friendModel = FriendsModel.fromJson(user);

                            final isFriend = controller.friends1.any(
                              (f) => f.username == friendModel.username,
                            );

                            if (isFriend) {
                              Get.toNamed(
                                Routes.friendsProfile,
                                arguments: friendModel,
                              );
                            } else {
                              Get.toNamed(
                                Routes.nonPrivateProfile,
                                arguments: friendModel,
                              );
                            }
                          },
                          child: Column(
                            children: [
                              SizedBox(height: 8.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipOval(
                                    child:
                                        (user['avatarUrl'] != null &&
                                                (user['avatarUrl'] as String)
                                                    .isNotEmpty)
                                            ? CachedNetworkImage(
                                              imageUrl: user['avatarUrl'],
                                              width: 70.w,
                                              height: 35.h,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                              placeholder:
                                                  (context, url) =>
                                                      ShimmerPlaceholder(
                                                        width: 70.w,
                                                        height: 35.h,
                                                      ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        width: 70.w,
                                                        height: 35.h,
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 30,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                        ),
                                                      ),
                                            )
                                            : Container(
                                              width: 70.w,
                                              height: 35.h,
                                              child: Icon(
                                                Icons.person,
                                                size: 30,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                              .trim(),
                                          style: GoogleFonts.notoSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              "assets/svg/level/coinshape1.svg",
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              compactNumber(user['totalPoints'] ?? 0),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Container(
                                              height: 10.h,
                                              width: 1.5.w,
                                              color: AppColors.bgGradientTop,
                                            ),
                                            SizedBox(width: 8.w),
                                            SvgPicture.asset(
                                              "assets/svg/level/coinshape2.svg",
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              compactNumber(user['thisWeekPoints'] ?? 0),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
