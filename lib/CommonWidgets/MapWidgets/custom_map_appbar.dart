import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/AllStats/sportVisited.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';
import 'package:outspot/Views/Explorescreen/redesign/explore_saved_screen.dart';

class CustomMapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MapController controller;

  const CustomMapAppBar({super.key, required this.controller});

  @override
  Size get preferredSize => Size.fromHeight(48.h);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Stay in search mode whenever a category is selected too — otherwise the
      // search bar disappears (reverts to default) after a tab switch if the
      // isSearching flag desyncs from the selected category.
      final inSearchMode =
          controller.isSearching.value ||
          controller.selectedCategory.value.isNotEmpty;
      return inSearchMode
          ? _buildSearchAppBar() // সার্চ মোড
          : _buildDefaultAppBar(); // নরমাল মোড
    });
  }

  // --- Search Mode AppBar (Updated as a Display Container) ---
  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              if (controller.cameFromModel.value) {
                controller.cameFromModel.value = false;
                controller.clearRestaurantSearch();
                controller.clearRoute();
                Get.to(() => SpotsVisitedScreen());
              } else if (controller.cameFromExploreRoute.value) {
                controller.cameFromExploreRoute.value = false;
                controller.clearRestaurantSearch();
                controller.clearRoute();
                final mainController = Get.find<MainscreeenController>();
                mainController.changeTab(4);
              } else if (controller.cameFromTrending.value) {
                controller.cameFromTrending.value = false;
                controller.clearRestaurantSearch();
                controller.clearRoute();
                final mainController = Get.find<MainscreeenController>();
                mainController.changeTab(4);
              } else {
                controller.clearRestaurantSearch();
                controller.clearRoute();
              }
            },
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset("assets/svg/icons/back_icon.svg"),
              ),
            ),
          ),

          // Display Container (Replaced TextField)
          Expanded(
            // A label, not a button: it shows which category is active. Tapping
            // it used to jump to the old SearchScreen, which threw away the
            // filter the user had just applied. Search now lives on the map
            // overlay, so the wrapper is gone — note it's dropped rather than
            // wrapped in IgnorePointer, which would have killed the ✕ inside.
            child: Container(
                height: 36.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: const Color(0xff1E092A),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xff703A8B), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text Display (Category Name or Searched Query)
                    Expanded(
                      child: Text(
                        controller.searchController.text.isNotEmpty
                            ? controller.searchController.text
                            : (controller.selectedCategory.value.isNotEmpty
                                ? controller.selectedCategory.value
                                : "Search..."),
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Close Icon (To clear search/category)
                    GestureDetector(
                      onTap: () {
                        if (controller.cameFromModel.value) {
                          controller.cameFromModel.value = false;
                          controller.clearRestaurantSearch();
                          controller.clearRoute();
                          Get.to(() => SpotsVisitedScreen());
                        } else if (controller.cameFromExploreRoute.value) {
                          controller.cameFromExploreRoute.value = false;
                          controller.clearRestaurantSearch();
                          controller.clearRoute();
                          final mainController =
                              Get.find<MainscreeenController>();
                          mainController.changeTab(4);
                        } else if (controller.cameFromTrending.value) {
                          controller.cameFromTrending.value = false;
                          controller.clearRestaurantSearch();
                          controller.clearRoute();
                          final mainController =
                              Get.find<MainscreeenController>();
                          mainController.changeTab(4);
                        } else {
                          controller.clearRestaurantSearch();
                          controller.clearRoute();
                        }
                      },
                      child: SvgPicture.asset(
                        "assets/svg/icons/Cross.svg",
                        height: 20.sp,
                        width: 20.sp,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  // --- Default Mode AppBar ---
  AppBar _buildDefaultAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Profile + saved share the leading slot, as on Explore, so the two
      // screens carry the same top bar.
      leadingWidth: 104.w,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
      Padding(
        padding: EdgeInsets.only(left: 18.w),
        child: GestureDetector(
          onTap: () {
            Get.toNamed(Routes.myProfile);
          },
          child:
              controller.avatarurl.value.isEmpty
                  ? CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    child: const Icon(Icons.person, color: Colors.grey),
                  )
                  : CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: controller.avatarurl.value,
                        alignment: Alignment.topCenter,
                        width: 40.w,
                        height: 30.h,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const ShimmerPlaceholder(),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
        ),
      ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () => Get.to(() => const ExploreSavedScreen()),
            child: Container(
              width: 34.w,
              height: 34.w,
              padding: EdgeInsets.all(7.sp),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff703A8B),
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
      centerTitle: true,
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
        // Search moved onto the map itself (see MapExploreOverlay), so this
        // slot carries the leaderboard instead — same pair Explore shows.
        GestureDetector(
          onTap: () => Get.toNamed(Routes.leaderboardGlobal),
          child: Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: SvgPicture.asset(
              "assets/svg/icons/dashBoardIcon.svg",
              height: 34.w,
              width: 34.w,
            ),
          ),
        ),
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
              Obx(() {
                return controller.notificationRedDot.value
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
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ],
    );
  }
}
