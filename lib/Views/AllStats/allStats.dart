import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';
import 'package:outspot/Views/AllStats/challengeCompleted.dart';
import 'package:outspot/Views/AllStats/sportVisited.dart';
import 'package:outspot/utils/routes.dart';

class AllStats extends GetView<AllStatsController> {
  const AllStats({super.key});

  @override
  Widget build(BuildContext context) {
    // This is MY stats. If the (singleton) controller was last showing a friend
    // (via FriendsStats), fully reload my own data; otherwise just refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.ownUserId == null ||
          controller.currentStatsUserId != controller.ownUserId) {
        controller.loadInitialData();
      } else {
        controller.refreshStats();
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.1, 0.5],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Dark purple background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () {
              if (Get.key.currentState?.canPop() == true) {
                Get.back();
              } else {
                Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
              }
            },
            child: Container(
              // color: Colors.amber,
              padding: EdgeInsets.all(15.w),
              child: SvgPicture.asset('assets/svg/icons/back_icon.svg'),
            ),
          ),
          title: Text(
            'Stats',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 48.sp),
                  SizedBox(height: 12.h),
                  Text(
                    'Something went wrong',
                    style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () => controller.loadInitialData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff704EF9),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
          // Shimmer until MY stats are actually loaded — not just isLoading.
          // (Before loadInitialData runs, or while the controller still holds a
          // friend's data, this avoids flashing wrong/stale values like the
          // "My Community" placeholder + wrong icon.)
          if (controller.isLoading.value ||
              controller.ownUserId == null ||
              controller.currentStatsUserId != controller.ownUserId) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: List.generate(5, (_) => _buildShimmerTile()),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildStatTile(
                imageUrl: 'assets/svg/icons/location.svg',
                title: "${controller.spotsVisited.value}",
                subtitle: "spots visited",
                iconBgColor: Colors.deepPurple.withOpacity(0.3),
                onTap: () {
                  Get.to(
                    () => SpotsVisitedScreen(),
                  )?.then((_) => controller.refreshStats());
                },
              ),
              _buildDivider(),
              _buildStatTile(
                imageUrl: 'assets/svg/icons/friends.svg',
                title: "${controller.friends.value}",
                subtitle: "friends",
                iconBgColor: Colors.pink.withOpacity(0.2),
                onTap: () {
                  Get.toNamed(
                    Routes.friendlist,
                  )?.then((_) => controller.refreshStats());
                },
              ),
              _buildDivider(),
              // NOTE: the community COUNT tile was removed — it duplicated the
              // "My Community" item shown at the bottom of this list.
              _buildStatTile(
                imageUrl: 'assets/svg/icons/challenges.svg',
                title: "${controller.challengesCompleted.value}",
                subtitle: "challenges completed",
                iconBgColor: Colors.red.withOpacity(0.2),
                onTap: () {
                  Get.to(
                    () => ChallengesCompletedScreen(),
                  )?.then((_) => controller.refreshStats());
                },
              ),
              _buildDivider(),

              Obx(() {
                if (controller.community.value == 0) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Get.toNamed(
                        Routes.noCommunity,
                      )?.then((_) => controller.refreshStats());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/svg/icons/joinCommunity.svg',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Join a Community',
                              style: TextStyle(
                                color: const Color(0xff42D880),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  if (controller.lastCommunityImage.value.isEmpty) {
                    controller.loadMostRecentCommunityImage();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (controller.myCommunityId.value != 0) {
                          Get.toNamed(
                            Routes.community,
                            arguments: {"id": controller.myCommunityId.value},
                          )?.then((_) => controller.refreshStats());
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50.r,
                            height: 50.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white10,
                            ),
                            child: ClipOval(
                              child:
                                  controller.lastCommunityImage.value.isNotEmpty
                                      ? CachedNetworkImage(
                                        imageUrl:
                                            controller.lastCommunityImage.value,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) =>
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                        errorWidget:
                                            (context, url, error) => const Icon(
                                              Icons.groups,
                                              color: Colors.white,
                                            ),
                                      )
                                      : const Icon(
                                        Icons.groups,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.communityName.value.isNotEmpty
                                      ? controller.communityName.value
                                      : 'My Community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "my community",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildShimmerTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          const ShimmerPlaceholder(width: 50, height: 50, radius: 25),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerPlaceholder(width: 50, height: 16, radius: 4),
              SizedBox(height: 8),
              ShimmerPlaceholder(width: 130, height: 12, radius: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String imageUrl,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    bool isNetworkImage = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child:
                    isNetworkImage && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  const ShimmerPlaceholder(radius: 0),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.group, color: Colors.white),
                        )
                        : imageUrl.isNotEmpty
                        ? SvgPicture.asset(
                          imageUrl,
                          fit: BoxFit.scaleDown,
                          errorBuilder:
                              (c, e, s) =>
                                  const Icon(Icons.image, color: Colors.white),
                        )
                        : const Icon(Icons.group, color: Colors.white),
              ),
            ),
            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
      height: 1,
    );
  }
}
