import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/utils/routes.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_or_submid_controller.dart';

class Friends extends GetView<FriendListController> {
  Friends({super.key});

  // Pagination — load 20 initially, 20 more on scroll
  static const int _pageSize = 20;
  final RxInt visibleCount = _pageSize.obs;

  // Pull-to-refresh: trigger on a small pull instead of the default ~25% drag
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final RxDouble _overscrollAccum = 0.0.obs;
  static const double _pullTrigger = 36; // px of overscroll to fire refresh

  void _loadMore(int total) {
    if (visibleCount.value < total) {
      visibleCount.value = (visibleCount.value + _pageSize).clamp(0, total);
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
          /// 🔹 Friends List (Real-time)
          Expanded(
            child: RefreshIndicator(
              key: _refreshKey,
              color: AppColors.bgGradientTop,
              onRefresh: () => controller.refreshAll(),
              backgroundColor: Colors.black,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  // Fire refresh on a tiny pull-down instead of the
                  // default ~25% viewport drag.
                  if (n is OverscrollNotification && n.overscroll < 0) {
                    _overscrollAccum.value += -n.overscroll;
                    if (_overscrollAccum.value > _pullTrigger &&
                        !controller.isLoading.value) {
                      _overscrollAccum.value = 0;
                      _refreshKey.currentState?.show();
                    }
                  } else if (n is ScrollEndNotification ||
                      n is ScrollStartNotification) {
                    _overscrollAccum.value = 0;
                  }
                  return false;
                },
                child: Obx(() {
                  // Show shimmer while loading initially
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              ],
                            ),
                          ),
                    );
                  }

                  // Controller এর observable friends list
                  final friendsToShow = controller.friends1;

                  // Search filter
                  final allFilteredFriends =
                      controller.query.value.isEmpty
                          ? friendsToShow.toList()
                          : friendsToShow
                              .where(
                                (f) => f.fullName.toLowerCase().contains(
                                  controller.query.value.toLowerCase(),
                                ),
                              )
                              .toList();

                  if (allFilteredFriends.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 200.h),
                        Center(
                          child: Text(
                            "No friends found",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }

                  final total = allFilteredFriends.length;
                  final count = visibleCount.value.clamp(0, total);
                  final filteredFriends = allFilteredFriends.sublist(0, count);
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        // horizontal: 12.w,
                      ),
                      itemCount: filteredFriends.length + (hasMore ? 1 : 0),
                      separatorBuilder:
                          (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Divider(
                              color: AppColors.MainColor,
                              thickness: 0.5,
                            ),
                          ),
                      itemBuilder: (context, index) {
                        if (index >= filteredFriends.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: Color(0xffC574F7),
                                ),
                              ),
                            ),
                          );
                        }
                        final friend = filteredFriends[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap:
                              () =>
                                  friend.isPendingSent
                                      ? _showCancelDialog(friend)
                                      : _showFriendDialog(friend),
                          child: Column(
                            children: [
                              SizedBox(height: 6.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipOval(
                                    child:
                                        (friend.avatarUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                              imageUrl: friend.avatarUrl,
                                              width: 70.w, // radius * 2
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
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    width: 70.w,
                                                    height: 35.h,
                                                    color: Colors.grey.shade800,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 30,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
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

                                  // SizedBox(width: 5),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend.fullName,
                                          style: GoogleFonts.notoSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        if (friend.isPendingSent)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.bgGradientTop
                                                  .withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              border: Border.all(
                                                color: AppColors.MainColor,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12.sp,
                                                  color: Colors.white70,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  "Pending accept",
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                "assets/svg/level/coinshape1.svg",
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                compactNumber(friend.totalPoints),
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
                                                compactNumber(friend.thisWeekPoints),
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
                              SizedBox(height: 7.h),
                            ],
                          ),
                        );
                      },
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
                      child: SvgPicture.asset('assets/svg/icons/Cross.svg'),
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
                            errorWidget:
                                (context, url, error) => Container(
                                  width: 200.w,
                                  height: 100.h,
                                  color: AppColors.bgGradientTop,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                          )
                          : Container(
                            width: 110.w,
                            height: 100.h,
                            color: AppColors.bgGradientTop,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
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
                        height: 32.h,
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
                            Routes.friendsProfile,
                            arguments: friend, // ✅ পুরো model পাঠাও
                          );
                        },

                        child: Text(
                          'View Profile',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 25.w),
                    GestureDetector(
                      onTap: () async {
                        Get.back(); // close the dialog first
                        final chatId = _findExistingChatId(friend.id);
                        Get.toNamed(
                          Routes.directMessageScreen,
                          arguments: {
                            "Id": friend.id,
                            if (chatId != null) "existingChatId": chatId,
                          },
                        );
                      },
                      child: _roundIcon(
                        'assets/svg/icons/massegeIcon.svg',
                        const Color(0xffFF5555),
                      ),
                    ),
                    SizedBox(width: 24.w),
                    GestureDetector(
                      onTap: () {
                        SendorSubmidController.preSelectedFriendId = friend.id;
                        Get.offAllNamed(
                          Routes.mainscreen,
                          arguments: {"tab": 2},
                        );
                      },
                      child: _roundIcon(
                        'assets/svg/icons/camera1.svg',
                        const Color(0xff58C1F0),
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

  void _showCancelDialog(FriendsModel friend) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: AppColors.bgGradientTop, size: 40),
              SizedBox(height: 14.h),
              Text(
                "Request pending",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Your friend request to ${friend.firstName.isNotEmpty ? friend.firstName : friend.username} is waiting to be accepted.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.white70),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.MainColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        "Keep",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF5555),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () {
                        Get.back();
                        controller.cancelSentRequest(friend);
                      },
                      child: Text(
                        "Cancel request",
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

  int? _findExistingChatId(int friendId) {
    if (Get.isRegistered<MessagesScreenController>()) {
      final msgCtrl = Get.find<MessagesScreenController>();
      for (final chat in msgCtrl.chatss) {
        if (!chat.isGroup && !chat.isCommunity) {
          if (chat.users.any((u) => u.id == friendId)) {
            return chat.id;
          }
        }
      }
    }
    return null;
  }

  Widget _roundIcon(String image, Color bg) => Container(
    padding: EdgeInsets.all(10.r),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: SvgPicture.asset(image, color: Colors.white),
  );
}
