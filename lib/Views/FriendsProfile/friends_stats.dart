import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/CommonWidgets/community_access.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';
import 'package:outspot/Views/AllStats/challengeCompleted.dart';
import 'package:outspot/Views/AllStats/sportVisited.dart';
import 'package:outspot/Views/FriendsProfile/friendsFriends.dart';
import 'package:outspot/utils/routes.dart';

class FriendsStats extends GetView<AllStatsController> {
  const FriendsStats({super.key});

  @override
  Widget build(BuildContext context) {
    // Single shared controller (created permanent, autoLoadOwn:false). We load
    // this friend's stats below.
    AllStatsController.instance;
    final int friendId = Get.arguments;

    // Load (or reload) this friend's stats. Guarded so it doesn't re-fire on
    // every Obx rebuild, and self-heals if the singleton was showing someone
    // else (own / another friend).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentStatsUserId != friendId) {
        controller.loadStatsForUser(friendId);
      }
    });
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: [0.1, 0.5],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Container(
                // color: Colors.amber,
                padding: EdgeInsets.all(15.w),
                child: SvgPicture.asset(
                  'assets/svg/icons/back_icon.svg',
                  color: Colors.white,
                  height: 20.h,
                ),
              ),
            ),
            title: Text(
              'Stats',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 18.sp,
              ),
            ),
            centerTitle: true,
          ),
          body: Obx(() {
            // While the friend's stats load, show shimmer placeholders on the
            // stat lines — never the previous (stale) values.
            if (controller.isLoading.value) {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                  // Controller already holds the friend's spots → shows their data.
                  onTap: () => Get.to(() => SpotsVisitedScreen()),
                ),
                _buildDivider(),
                _buildStatTile(
                  imageUrl: 'assets/svg/icons/friends.svg',
                  title: "${controller.friends.value}",
                  subtitle: "friends",
                  iconBgColor: Colors.pink.withOpacity(0.2),
                  onTap: () {
                    if (controller.friendFriends.isEmpty) return;
                    Get.to(
                      () => const FriendFriends(),
                      arguments: {"friends": controller.friendFriends.toList()},
                    );
                  },
                ),
                // NOTE: the "groups" count tile was removed — it duplicated the
                // "My Community" item below.
                _buildDivider(),
                _buildStatTile(
                  imageUrl: 'assets/svg/icons/challenges.svg',
                  title: "${controller.challengesCompleted.value}",
                  subtitle: "challenges completed",
                  iconBgColor: Colors.red.withOpacity(0.2),
                  // Controller holds the friend's challenges → shows their data.
                  onTap: () => Get.to(() => ChallengesCompletedScreen()),
                ),
                _buildDivider(),
                // Only show the community tile when this friend is actually in a
                // community. Otherwise show a plain "no community" row instead of
                // an empty/confusing tile.
                if (controller.communityName.value.trim().isNotEmpty ||
                    controller.myCommunityId.value != 0)
                  _buildStatTile(
                    imageUrl: controller.communityImage.value,
                    title: controller.communityName.value,
                    subtitle: "My Community",
                    isNetworkImage: true,
                    iconBgColor: Colors.blue.withOpacity(0.2),
                    // Only enter if I'm a member of the friend's community, else a
                    // soft popup explains I can't access it.
                    onTap:
                        () => openCommunityIfMember(
                          controller.myCommunityId.value,
                          communityName: controller.communityName.value,
                        ),
                  )
                else
                  _buildEmptyCommunityTile(),
                _buildDivider(),
              ],
            );
          }),
        ),
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
    VoidCallback? onTap, // onTap callback function add kora hoyeche
  }) {
    return InkWell(
      // Ripple effect-er jonno InkWell use kora hoyeche
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // Click area shape
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // Icon/Image Section
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
            // Text Section
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

  /// Shown when the friend isn't a member of any community.
  Widget _buildEmptyCommunityTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined, color: Colors.white54),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Not in any community",
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
          ),
        ],
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
