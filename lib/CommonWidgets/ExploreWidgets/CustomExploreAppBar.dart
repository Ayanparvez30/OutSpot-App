import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_saved_screen.dart';

class CustomExploreAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomExploreAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Find-or-create: a mid-session cleanup (Get.deleteAll on logout/401) can
    // wipe these controllers while this app bar rebuilds → "not found" crash.
    // Recreate them defensively instead.
    final controller =
        Get.isRegistered<ExploreController>()
            ? Get.find<ExploreController>()
            : Get.put(ExploreController());
    final mainController =
        Get.isRegistered<MainscreeenController>()
            ? Get.find<MainscreeenController>()
            : Get.put(MainscreeenController());

    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,

      // Two icons share the leading slot now (profile + saved), so it needs
      // more than AppBar's default 56px or the bookmark is clipped away.
      leadingWidth: 104.w,

      // --- Leading: Profile Picture + Saved ---
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
      Padding(
        padding: EdgeInsets.only(left: 18.w),
        child: GestureDetector(
          onTap: () => Get.toNamed(Routes.myProfile),
          child: Obx(() {
            final imageUrl = controller.avatarurl.value;
            if (imageUrl.isEmpty) {
              return CircleAvatar(
                radius: 20,
                backgroundColor: Colors.transparent,
                child: const Icon(Icons.person, color: Colors.grey),
              );
            }
            return CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  alignment: Alignment.topCenter,
                  width: 40.w,
                  height: 30.h,
                  fit: BoxFit.cover,
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
          SizedBox(width: 10.w),
          // Saved spots — the bookmark from the redesign's top nav.
          GestureDetector(
            onTap: () => Get.to(() => const ExploreSavedScreen()),
            child: Container(
              width: 34.w,
              height: 34.w,
              padding: EdgeInsets.all(7.sp),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff49205C),
              ),
              child: ExploreIcons.svg(
                ExploreIcons.cardSave,
                size: 18.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      // --- Title: Achievements Icon ---
      title: GestureDetector(
        onTap: () {
          Get.toNamed(Routes.viewAchievements);
        },
        child: Obx(() {
          final ttl = mainController.myAchievements.value?.title;
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

      // --- Actions: Leaderboard & Notification ---
      actions: [
        Row(
          children: [
            // Leaderboard Icon
            GestureDetector(
              onTap: () => Get.toNamed(Routes.leaderboardGlobal),
              child: SvgPicture.asset(
                "assets/svg/icons/dashBoardIcon.svg",
                height: 34.w,
                width: 34.w,
              ),
            ),
            SizedBox(width: 10.w),

            // Notification Icon with Red Dot
            GestureDetector(
              onTap: () {
                controller.clearNotificationDot();
                Get.toNamed(Routes.notification1);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 10.w),
                    width: 34.w,
                    height: 34.w,
                    padding: EdgeInsets.all(5.sp),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff703A8B),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/svg/icons/notification_icon.svg",
                        height: 18.sp,
                        width: 18.sp,
                      ),
                    ),
                  ),
                  Obx(
                    () =>
                        controller.notificationRedDot.value
                            ? Positioned(
                              right: 10,
                              top: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
