import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Model/notificaton_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Notification1/filterNotification.dart';
import 'package:outspot/Views/Notification1/notification_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class Notification2Screen extends GetView<Notification1Controller> {
  Notification2Screen({Key? key}) : super(key: key);

  final searchText = "".obs;

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
    return Container(
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
        body: Column(
          children: [
            // 🔍 Search bar section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              child: TextField(
                onChanged: (value) => searchText.value = value.toLowerCase(),
                cursorColor: AppColors.white,
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputBorderColor,
                  ),
                  suffixIcon: Container(
                    width: 80.w,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.to(Filternotification());
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFAB50F6),
                                    Color(0xFFFB7D6C),
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Image.asset(
                                'assets/Images/filterImage.png',
                                width: 20.w,
                                height: 20.h,
                              ),
                            ),
                          ),
                        ),
                        SvgPicture.asset('assets/svg/icons/searchImage.svg'),
                      ],
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
            ),

            // 🔔 Notification list
            Expanded(
              child: Obx(() {
                // Shimmer loading
                if (controller.isLoading.value) {
                  return ListView.builder(
                    padding: EdgeInsets.all(16.h),
                    itemCount: 10,
                    itemBuilder:
                        (_, __) => Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerPlaceholder(
                                width: 48.w,
                                height: 48.w,
                                radius: 24.w,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShimmerPlaceholder(
                                      width: 200.w,
                                      height: 14.h,
                                      radius: 4,
                                    ),
                                    SizedBox(height: 8.h),
                                    ShimmerPlaceholder(
                                      width: 150.w,
                                      height: 12.h,
                                      radius: 4,
                                    ),
                                    SizedBox(height: 6.h),
                                    ShimmerPlaceholder(
                                      width: 60.w,
                                      height: 10.h,
                                      radius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  );
                }

                final allFiltered =
                    controller.notifications.where((item) {
                      final search = searchText.value;
                      return item.title.toLowerCase().contains(search) ||
                          item.description.toLowerCase().contains(search);
                    }).toList();

                final total = allFiltered.length;
                final count = visibleCount.value.clamp(0, total);
                final filtered = allFiltered.sublist(0, count);
                final hasMore = count < total;

                return RefreshIndicator(
                  color: const Color(0xFFAB50F6),
                  backgroundColor: const Color(0xff323434),
                  onRefresh: () async {
                    await controller.loadNotifications();
                    visibleCount.value = _pageSize;
                  },
                  child:
                      allFiltered.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                              ),
                              const Center(
                                child: Text(
                                  "No notifications",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          )
                          : NotificationListener<ScrollNotification>(
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
                              itemCount: filtered.length + (hasMore ? 1 : 0),
                              separatorBuilder:
                                  (_, __) => Divider(
                                    color: AppColors.bgGradientTop,
                                    thickness: 1,
                                  ),
                              itemBuilder: (context, index) {
                                if (index >= filtered.length) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
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
                                final item = filtered[index];

                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.h,
                                  ),
                                  child: ListTile(
                                    leading: ClipOval(
                                      child:
                                          (item.avatarUrl != null &&
                                                  item.avatarUrl!.isNotEmpty)
                                              ? CachedNetworkImage(
                                                imageUrl: item.avatarUrl!,
                                                width: 60.w,
                                                height: 35.h,
                                                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                                placeholder:
                                                    (context, url) =>
                                                        ShimmerPlaceholder(
                                                          width: 60.w,
                                                          height: 35.h,
                                                        ),
                                              )
                                              : Image.asset(
                                                "assets/Images/cleanLogo.png",
                                                width: 45.w,
                                                height: 60.h,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                    title: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.notoSans(
                                          fontSize: 15.sp,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: item.title,
                                            style: GoogleFonts.notoSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                          TextSpan(
                                            text: " ${item.description}",
                                            style: GoogleFonts.notoSans(
                                              fontSize: 14.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "  ${item.timeAgo()}",
                                            style: GoogleFonts.notoSans(
                                              fontSize: 12.sp,
                                              color: const Color(0xffB1B1B1),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    onLongPress: () {
                                      showCommunityOptionsBottomSheet(
                                        context,
                                        onEdit: () {
                                          Get.back();
                                          AppSnackbar.info(
                                            "Edit option tapped for ${item.title}",
                                            title: "Edit",
                                          );
                                        },
                                        onDelete: () {
                                          controller.deleteNotification(
                                            item.id,
                                          );
                                          Get.back();
                                        },
                                      );
                                    },

                                    onTap: () {
                                      _onNotificationTap(item);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMainTab(int tab) {
    if (Get.isRegistered<MainscreeenController>()) {
      final controller = Get.find<MainscreeenController>();
      controller.changeTab(tab);
      Get.until((route) => route.settings.name == Routes.mainscreen);
    } else {
      Get.offAllNamed(Routes.mainscreen, arguments: {"tab": tab});
    }
  }

  /// 🔽 Modal Bottom Sheet for Edit/Delete options
  void _onNotificationTap(NotificationModel item) {
    switch (item.type) {
      case 'FRIEND_ACCEPTED':
        Get.toNamed(Routes.friendsProfile, arguments: {"id": item.actorId});
        break;
      case 'FRIEND_REQUEST':
        Get.toNamed(Routes.friendlist, arguments: {"tab": 1});
        break;
      case 'NEW_CHALLENGE':
      case 'DAILY_CHALLENGE':
      case 'WEEKLY_CHALLENGE':
        _navigateToMainTab(3);
        break;
      case 'MESSAGE':
        _navigateToMainTab(0);
        break;
      case 'COMMUNITY_BANNED':
      case 'COMMUNITY_UNBANNED':
        if (item.communityId != null) {
          Get.toNamed(Routes.community, arguments: {"id": item.communityId});
        } else {
          _navigateToMainTab(0);
        }
        break;
      case 'GROUP_BANNED':
      case 'GROUP_UNBANNED':
        // The group chat itself is no longer accessible after a ban → chat list.
        _navigateToMainTab(0);
        break;
      default:
        _navigateToMainTab(0);
        break;
    }
  }

  void showCommunityOptionsBottomSheet(
    BuildContext context, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: Color(0xff323434),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container(
                //   width: 50.w,
                //   height: 5.h,
                //   margin: EdgeInsets.only(bottom: 10.h),
                //   decoration: BoxDecoration(
                //     color: Colors.grey.shade300,
                //     borderRadius: BorderRadius.circular(10.r),
                //   ),
                // ),
                Center(
                  child: Text(
                    "Notification Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(color: Colors.black),

                // 🟦 Edit Option
                GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Center(
                      child: Text(
                        "Mark as Read",
                        style: TextStyle(
                          color: Color(0xff66CCFC),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                Divider(color: Colors.black),
                // 🔴 Delete Option
                GestureDetector(
                  onTap: onDelete,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Center(
                      child: Text(
                        "Delete Notification",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
