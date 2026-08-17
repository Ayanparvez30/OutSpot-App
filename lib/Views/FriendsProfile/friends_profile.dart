import 'package:cached_network_image/cached_network_image.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/story_media.dart';
import 'package:outspot/CommonWidgets/community_access.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';
import 'package:outspot/Views/AllStats/sportVisited.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/lockerItem_model.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Views/FriendsProfile/friendsFriends.dart';
import 'package:outspot/Views/FriendsProfile/friends_profile_controller.dart';
import 'package:outspot/Views/FriendsProfile/friends_stats.dart';
import 'package:outspot/Views/MyProfile/miniMeUpdated.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_or_submid_controller.dart';

class FriendsProfile extends GetView<FriendsProfileController> {
  const FriendsProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final FriendsModel friend;
    if (args is FriendsModel) {
      friend = args;
    } else if (args is Map) {
      friend = FriendsModel(
        id: args['id'] ?? 0,
        username: args['username'] ?? '',
        firstName: args['firstName'] ?? '',
        lastName: args['lastName'] ?? '',
        avatarUrl: args['avatarUrl'] ?? '',
        totalPoints: args['totalPoints'] ?? 0,
        thisWeekPoints: args['thisWeekPoints'] ?? 0,
        profileUrl: args['profileUrl'] ?? '',
      );
    } else {
      friend = FriendsModel(
        id: args is int ? args : 0,
        username: '',
        firstName: '',
        lastName: '',
        avatarUrl: '',
        totalPoints: 0,
        thisWeekPoints: 0,
        profileUrl: '',
      );
    }
    final int friendId = friend.id;

    // If this (singleton) controller is showing a different person (e.g. we
    // navigated friend → friend-of-friend), reload it for the requested id.
    // Self-heals on back-navigation too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (friendId > 0 && controller.currentUserId != friendId) {
        controller.loadProfile(friendId);
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
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            center: Alignment.topRight,
            stops: [0.1, 0.5],

            radius: 1.5,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Obx(() {
            // The controller is a singleton shared across stacked profile routes.
            // Until it has loaded THIS friend's data, show a loader instead of the
            // previously-viewed friend's data (prevents the wrong-profile flash).
            // BUT if we arrived with the friend's basic data already (e.g. from
            // Accept, which passes the full model with an avatar), render
            // immediately and load the rest underneath — no jarring blank.
            if (controller.loadedUserId.value != friendId &&
                friend.avatarUrl.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return CustomScrollView(
              controller: controller.profileScrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Header — collapsed (230.h) by default, drag DOWN to expand
                // up to full screen height showing the entire avatar.
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height,
                  collapsedHeight: 180.h,
                  toolbarHeight: 56.h,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leadingWidth: 50.w,
                  leading: IconButton(
                    onPressed: () => Get.back(),
                    icon: SvgPicture.asset(
                      "assets/svg/icons/back_icon.svg",
                      width: 25.r,
                      height: 25.r,
                    ),
                    padding: EdgeInsets.all(8.w),
                    constraints: const BoxConstraints(),
                  ),
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: GestureDetector(
                        onTap: () {
                          _showProfileOptions(context, friendId);
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.h),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bgGradientBottom,
                          ),
                          child: SvgPicture.asset(
                            "assets/svg/icons/menuDot.svg",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final topPadding = MediaQuery.of(context).padding.top;
                      final gradientBg = const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff6D1277),
                            Color(0xff8E21EA),
                            Color(0xffFF7474),
                            Color(0xff774E7C),
                          ],
                        ),
                      );
                      return SizedBox(
                        height: constraints.maxHeight,
                        width: double.infinity,
                        child: Obx(() {
                          // Fall back to the avatar passed in args (e.g. from
                          // Accept) so the header shows instantly instead of a
                          // shimmer while the full profile loads underneath.
                          final avatar =
                              controller.avatarUrl.value.isNotEmpty
                                  ? controller.avatarUrl.value
                                  : friend.avatarUrl;
                          if (avatar.isEmpty) {
                            return Container(
                              decoration: gradientBg,
                              child: const ShimmerPlaceholder(radius: 0),
                            );
                          }
                          return Container(
                            decoration: gradientBg,
                            padding: EdgeInsets.only(top: topPadding),
                            child: CachedNetworkImage(
                              imageUrl: avatar,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              placeholder:
                                  (context, url) =>
                                      const ShimmerPlaceholder(radius: 0),
                              errorWidget:
                                  (context, url, error) =>
                                      const ShimmerPlaceholder(radius: 0),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),

                      // ------------------- Name -------------------
                      Text(
                        "${controller.friendData['firstName'] ?? ''} ${controller.friendData['lastName'] ?? ''}",
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // ------------------- Username -------------------
                      Text(
                        "@${controller.friendData['username'] ?? ''}",
                        style: TextStyle(fontSize: 13.sp, color: Colors.white),
                      ),

                      SizedBox(height: 8.h),

                      // ------------------- Points -------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset("assets/svg/level/coinshape1.svg"),
                          SizedBox(width: 4.w),
                          Text(
                            compactNumber(controller.friendData['totalPoints'] ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            height: 12.h,
                            width: 1.5.w,
                            color: AppColors.bgGradientTop,
                          ),
                          SizedBox(width: 9.w),
                          SvgPicture.asset("assets/svg/level/coinshape2.svg"),
                          SizedBox(width: 4.w),
                          Text(
                            compactNumber(controller.friendData['thisWeekPoints'] ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // ------------------- Bio -------------------
                      Obx(() {
                        final bio =
                            (controller.friendData['bio'] ?? '')
                                .toString()
                                .trim();
                        if (bio.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(
                            top: 10.h,
                            left: 24.w,
                            right: 24.w,
                          ),
                          child: Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSans(
                              color: Colors.white70,
                              fontSize: 13.sp,
                              height: 1.4,
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: 14.h),

                      // ------------------- Action Buttons -------------------
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // UNFRIEND BUTTON
                            GestureDetector(
                              onTap: () async {
                                await controller.unfriend(friendId);

                                if (Get.isBottomSheetOpen ?? false) Get.back();
                                if (Get.isDialogOpen ?? false) Get.back();

                                if (Get.isRegistered<FriendListController>()) {
                                  final friendListController =
                                      Get.find<FriendListController>();
                                  friendListController.friends1.removeWhere(
                                    (f) => f.id == friendId,
                                  );
                                }

                                Get.toNamed(
                                  Routes.nonPrivateProfile,
                                  arguments: friend,
                                );

                                AppSnackbar.success(
                                  "User unfriended successfully",
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 50.w,
                                  vertical: 15.h,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5.w,
                                  ),
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/Images/Group 51239.png",
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "Unfriend",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Chat
                            ElevatedButton(
                              onPressed: () async {
                                final chatId = await controller.getOrCreateChat(
                                  friendId,
                                );
                                if (chatId != null && chatId > 0) {
                                  Get.toNamed(
                                    Routes.directMessageScreen,
                                    arguments: {
                                      "Id": friendId,
                                      "existingChatId": chatId,
                                    },
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffFF7474),
                                shape: const CircleBorder(),
                                padding: EdgeInsets.all(14.r),
                              ),
                              child: SvgPicture.asset(
                                // "assets/Images/chat-round-line-svgrepo-com.png"
                                'assets/svg/icons/massegeIcon.svg',
                                color: Colors.white,
                              ),
                            ),

                            // Camera
                            ElevatedButton(
                              onPressed: () {
                                SendorSubmidController.preSelectedFriendId =
                                    friendId;
                                Get.offAllNamed(
                                  Routes.mainscreen,
                                  arguments: {"tab": 2},
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffF8AC00),
                                shape: const CircleBorder(),
                                padding: EdgeInsets.all(14.r),
                              ),
                              child: SvgPicture.asset(
                                'assets/svg/icons/camera1.svg',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // // ------------------- Friends & Community -------------------
                      // Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 24.w),
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         child: Obx(() {
                      //           final hasFriends = controller.friendCount.value > 0;

                      //           return GestureDetector(
                      //             onTap:
                      //                 hasFriends
                      //                     ? () => Get.to(
                      //                       () => FriendFriends(),
                      //                       arguments: friend,
                      //                     )
                      //                     : null,
                      //             child: Container(
                      //               padding: EdgeInsets.all(10.r),
                      //               decoration: BoxDecoration(
                      //                 borderRadius: BorderRadius.circular(12.r),
                      //                 border: Border.all(color: Colors.grey.shade300),
                      //               ),
                      //               child: Column(
                      //                 children: [
                      //                   Text(
                      //                     "Friends",
                      //                     style: TextStyle(
                      //                       fontSize: 16.sp,
                      //                       fontWeight: FontWeight.w900,
                      //                       color: Colors.white,
                      //                     ),
                      //                   ),
                      //                   SizedBox(height: 10.h),
                      //                   Padding(
                      //                     padding: EdgeInsets.only(left: 50.w),
                      //                     child: Row(
                      //                       children: [
                      //                         Image.asset(
                      //                           'assets/Images/user-svgrepo-com (3).png',
                      //                           height: 16.h,
                      //                           width: 16.w,
                      //                           color: Colors.white,
                      //                         ),
                      //                         SizedBox(width: 5.w),
                      //                         Text(
                      //                           "${controller.friendCount.value}",
                      //                           style: TextStyle(color: Colors.white),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //           );
                      //         }),
                      //       ),

                      //       SizedBox(width: 12.w),
                      //       Expanded(
                      //         child: GestureDetector(
                      //           onTap: () {},
                      //           child: Container(
                      //             padding: EdgeInsets.all(10.r),
                      //             decoration: BoxDecoration(
                      //               borderRadius: BorderRadius.circular(12.r),
                      //               border: Border.all(color: Colors.grey.shade300),
                      //             ),
                      //             child: Column(
                      //               children: [
                      //                 Text(
                      //                   "Community",
                      //                   style: TextStyle(
                      //                     fontSize: 16.sp,
                      //                     fontWeight: FontWeight.w900,
                      //                     color: Colors.white,
                      //                   ),
                      //                 ),
                      //                 SizedBox(height: 10.h),
                      //                 Obx(() {
                      //                   if (controller
                      //                       .lastCommunityAvatar
                      //                       .value
                      //                       .isEmpty) {
                      //                     return Text(
                      //                       "No Community",
                      //                       style: TextStyle(
                      //                         color: Colors.white,
                      //                         fontSize: 12.sp,
                      //                       ),
                      //                     );
                      //                   }

                      //                   return CircleAvatar(
                      //                     radius: 16.r,
                      //                     backgroundColor: Colors.grey.shade200,
                      //                     backgroundImage: NetworkImage(
                      //                       controller.lastCommunityAvatar.value,
                      //                     ),
                      //                   );
                      //                 }),
                      //               ],
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          // color: const Color(
                          //   0xFF2D0D45,
                          // ), // Deep purple background
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0xff703A8B)),
                        ),
                        child: Column(
                          children: [
                            // Top Section: Stats numbers
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Obx(
                                () => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        // Load this friend's spots into the shared
                                        // stats controller, then open the screen.
                                        final asc = AllStatsController.instance;
                                        if (asc.currentStatsUserId !=
                                            friendId) {
                                          asc.loadStatsForUser(friendId);
                                        }
                                        Get.to(() => SpotsVisitedScreen());
                                      },
                                      child: _buildStatItem(
                                        icon: Icons.location_on_outlined,
                                        value:
                                            "${controller.spotsVisited.value}",
                                        label: "Spots Visited",
                                        iconColor: Colors.deepPurpleAccent,
                                      ),
                                    ),
                                    _buildVerticalDivider(),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => controller.goToFriendsList(),
                                      child: _buildStatItem(
                                        icon: Icons.person_outline,
                                        value: "${controller.friends.value}",
                                        label: "Friends",
                                        iconColor: Colors.pinkAccent,
                                      ),
                                    ),
                                    _buildVerticalDivider(),
                                    Obx(() {
                                      if (controller.communities.isEmpty) {
                                        return _buildStatItem(
                                          icon: Icons.people_outline,
                                          value: "None",
                                          label: "Community",
                                          iconColor: Colors.orangeAccent,
                                          valueFontSize: 15.sp,
                                        );
                                      }

                                      final lastCommunity =
                                          controller.communities.last;
                                      final String name =
                                          lastCommunity['name'] ?? 'Community';
                                      final String imageUrl =
                                          lastCommunity['imageUrl'] ??
                                          controller.lastCommunityAvatar.value;
                                      final int communityId =
                                          (lastCommunity['id'] is int)
                                              ? lastCommunity['id']
                                              : int.tryParse(
                                                    '${lastCommunity['id']}',
                                                  ) ??
                                                  0;

                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        // Enter only if I'm a member of this
                                        // community, else show a soft popup.
                                        onTap:
                                            () => openCommunityIfMember(
                                              communityId,
                                              communityName: name,
                                            ),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: Colors
                                                  .orangeAccent
                                                  .withOpacity(0.2),
                                              backgroundImage:
                                                  imageUrl.isNotEmpty
                                                      ? CachedNetworkImageProvider(
                                                        imageUrl,
                                                      )
                                                      : null,
                                              child:
                                                  imageUrl.isEmpty
                                                      ? const Icon(
                                                        Icons.people_outline,
                                                        color:
                                                            Colors.orangeAccent,
                                                        size: 20,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 28.h,
                                              width: 80.w,
                                              child: Center(
                                                child: Text(
                                                  name,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              "Community",
                                              style: TextStyle(
                                                color: const Color(0xff95A4A7),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom Section: Show All Stats Button
                            GestureDetector(
                              onTap: () {
                                // FriendsStats (GetView<AllStatsController>) loads
                                // the friend's stats itself via Get.arguments —
                                // don't pre-create the controller here (that would
                                // auto-load MY stats and race the friend load).
                                Get.to(
                                  () => const FriendsStats(),
                                  arguments: friendId,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(
                                    0xff703A8B,
                                  ), // Slightly lighter purple for the bottom
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      "Show All Stats",
                                      style: TextStyle(
                                        color: Color(0xffC574F7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    // SizedBox(width: 8),
                                    // Icon(
                                    //   Icons.arrow_forward_ios,
                                    //   size: 16,
                                    //   color: Color(0xffC574F7),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // // ------------------- Saved Stories Grid -------------------
                      // Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 12.w),
                      //   child: Obx(() {
                      //     if (controller.savedStories.isEmpty) {
                      //       return const Center(child: Text("No saved stories"));
                      //     }

                      //     return GridView.builder(
                      //       shrinkWrap: true,
                      //       physics: const NeverScrollableScrollPhysics(),
                      //       padding: const EdgeInsets.all(16),
                      //       itemCount: controller.savedStories.length,
                      //       gridDelegate:
                      //           const SliverGridDelegateWithFixedCrossAxisCount(
                      //             crossAxisCount: 4,
                      //             crossAxisSpacing: 2,
                      //             mainAxisSpacing: 2,
                      //             childAspectRatio: 0.7,
                      //           ),
                      //       itemBuilder: (context, index) {
                      //         final story = controller.savedStories[index];
                      //         return ClipRRect(
                      //           borderRadius: BorderRadius.circular(8),
                      //           child: Image.network(
                      //             story.mediaUrl,
                      //             fit: BoxFit.cover,
                      //             errorBuilder:
                      //                 (_, __, ___) => const Icon(Icons.broken_image),
                      //           ),
                      //         );
                      //       },
                      //     );
                      //   }),
                      // ),
                      /* --- Saved Stories (only visible if stories exist) --- */
                      Obx(() {
                        // While loading, don't render anything (no placeholder, no label)
                        if (controller.isStoriesLoading.value) {
                          return const SizedBox.shrink();
                        }
                        // Hide the entire section when there are no saved stories
                        if (controller.savedStories.isEmpty) {
                          return SizedBox(height: 20.h);
                        }
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [_tabBtn('Saved Stories')],
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: _buildStoriesGrid(controller.savedStories),
                            ),
                            SizedBox(height: 30.h),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _tabBtn(String title) => Obx(() {
    final bool selected = controller.selectedTab.value == title;
    return GestureDetector(
      onTap: () => controller.changeTab(title), // ✅ this is the fix
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.textOut : AppColors.MainColor,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 12.sp,
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w700,
          ),
        ),
      ),
    );
  });

  Widget _gridImageItem(BuildContext context, LockerItem item) {
    return GestureDetector(
      onTap: () async {
        // if (item.avatarUrl.isNotEmpty) {
        //   // Minimeupdated পেজে ইমেজ পাঠানো হচ্ছে
        //   final updatedImage = await Get.to<String>(
        //     () => Minimeupdated(imagePath: item.avatarUrl),
        //   );

        //   if (updatedImage != null && updatedImage.isNotEmpty) {
        //     // প্রোফাইল কন্ট্রোলার আপডেট
        //     // MyProfileController.instance.updateAvatarLocal(updatedImage);
        //     Get.find<FriendsProfileController>().updateAvatarLocal(
        //       updatedImage,
        //     );
        //   }
        // } else {
        //   // Get.snackbar(
        //   //   "Error",
        //   //   "Image not available",
        //   //   backgroundColor: Colors.red,
        //   //   colorText: Colors.white,
        //   // );
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.black),
          color: AppColors.bgGradientBottom,
        ),
        child: CachedNetworkImage(
          imageUrl: item.avatarUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const ShimmerPlaceholder(radius: 0),
          errorWidget:
              (context, url, error) =>
                  const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  // ------------------- Modal Bottom Sheet -------------------
  void _showProfileOptions(BuildContext context, int friendId) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: Color(0xff323434),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 2.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Profile Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(color: Colors.black),

                _sheetOption(
                  "Chat Settings",
                  AppColors.bgGradientTop,
                  () async {
                    Get.back(); // close bottom sheet
                    final chatId = await controller.getOrCreateChat(friendId);
                    if (chatId != null && chatId > 0) {
                      final friendModel = controller.buildFriendModel(friendId);
                      Get.toNamed(
                        Routes.conversationOptions,
                        arguments: {'friend': friendModel, 'chatId': chatId},
                      );
                    }
                  },
                ),

                _sheetOption(
                  "Share Profile",
                  AppColors.bgGradientTop,
                  () => controller.shareText(context),
                ),

                _sheetOption(
                  "Block User",
                  Colors.red,
                  () => _confirmBlock(context, friendId),
                ),

                _sheetOption(
                  "Report User",
                  Colors.red,
                  () => _confirmReport(context, friendId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetOption(String title, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          // Full-row tap target (opaque so the whole width responds, not just
          // the text).
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Divider(color: Colors.black),
      ],
    );
  }

  // Display name for the confirmation dialogs (falls back to @username).
  String _friendDisplayName() {
    final name =
        '${controller.friendData['firstName'] ?? ''} ${controller.friendData['lastName'] ?? ''}'
            .trim();
    if (name.isNotEmpty) return name;
    final user = controller.friendData['username'];
    return (user != null && '$user'.isNotEmpty) ? '@$user' : 'this user';
  }

  // Confirm before blocking (matches ConversationOptionsScreen's dialog).
  void _confirmBlock(BuildContext context, int friendId) {
    final name = _friendDisplayName();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Block $name?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "$name will no longer be able to message you, and you won't see "
          "their messages.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close the dialog
              await controller.blockUser(friendId);

              if (Get.isRegistered<FriendListController>()) {
                Get.find<FriendListController>().friends1.removeWhere(
                  (f) => f.id == friendId,
                );
              }
              if (Get.isRegistered<MyProfileController>()) {
                Get.find<MyProfileController>().decrementFriendCount();
              }

              Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 0});
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Color(0xFFDD4141)),
            ),
          ),
        ],
      ),
    );
  }

  // Confirm before reporting (matches ConversationOptionsScreen's dialog).
  void _confirmReport(BuildContext context, int friendId) {
    final name = _friendDisplayName();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Report $name?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This sends this profile to the OutSpot team for review. '
          'They may remove content or take action on this account.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close the dialog
              final ok = await controller.reportFriend(friendId);
              // Close the options sheet on success.
              if (ok && context.mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Color(0xFFF8AC00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesGrid(List stories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: stories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 3,
        mainAxisSpacing: 2,
        childAspectRatio: 0.5,
      ),
      itemBuilder: (context, index) {
        final story = stories[index];
        return GestureDetector(
          onTap:
              () => Get.to(
                () => StoryViewerScreen(url: story.mediaUrl, type: story.type),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: StoryGridThumb(url: story.mediaUrl, type: story.type),
          ),
        );
      },
    );
  }

  // --- রিইউজেবল গ্রিড উইজেট (Locker এর জন্য) ---
  Widget _buildLockerGrid(List items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.lockerItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.5,
      ),
      itemBuilder: (context, index) {
        final imageUrl = controller.lockerItems[index];
        return _gridImageItem(context, imageUrl);
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    double valueFontSize = 22, // smaller for text values like "None"
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 28.h,
          child: Center(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(color: Color(0xff95A4A7), fontSize: 14.sp),
        ),
      ],
    );
  }

  // Vertical Divider Helper
  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 2, color: Color(0xff703A8B));
  }
}
