import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Camerascreen/camerascreen_controller.dart';
import 'package:outspot/Views/Explore_Category/explore_category_controller.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

class Postscreen extends GetView<CamerascreenController> {
  Postscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // Just viewing a story no longer triggers a full Explore reload (slow and
      // pointless). Seen-state is tracked locally (grey ring) and a delete
      // removes the story from the feed locally — see removeCurrentStory.
      onPopInvoked: (bool didPop) {},
      child: Scaffold(
        backgroundColor: Color(0xffFFFFFF),
        body: Stack(
          children: [
            Obx(() {
              if (controller.userStories.isEmpty)
                return const SizedBox.shrink();
              final currentStory =
                  controller.userStories[controller.currentIndex.value];
              final isVideo = currentStory.type.toLowerCase() == "video";

              if (isVideo) {
                final mkCtrl = controller.mkVideoController;
                if (controller.isVideoInitialized.value && mkCtrl != null) {
                  return SizedBox.expand(
                    key: ValueKey(controller.videoGeneration.value),
                    child: mkv.Video(
                      controller: mkCtrl,
                      controls: mkv.NoVideoControls,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
              } else {
                return CachedNetworkImage(
                  imageUrl: currentStory.mediaUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerPlaceholder(),
                  errorWidget:
                      (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                );
              }
            }),

            Positioned.fill(
              child: Obx(() {
                final canGoPrev = controller.currentIndex.value > 0;
                final canGoNext =
                    controller.currentIndex.value < controller.storyCount - 1;

                return Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  canGoPrev
                                      ? () {
                                        log("prev tapped");
                                        controller.previousStory();
                                      }
                                      : null,
                            ),
                          ),
                          if (canGoPrev)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                ),
                                onPressed: controller.previousStory,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // RIGHT half (Next)
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  canGoNext
                                      ? () {
                                        log("Next tapped");
                                        controller.nextStory();
                                      }
                                      : null,
                            ),
                          ),
                          if (canGoNext)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                ),
                                onPressed: controller.nextStory,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),

            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

            // Image.file(
            //   File(imagePath),
            //   fit: BoxFit.cover,
            //   width: double.infinity,
            //   height: double.infinity,
            // ),
            Positioned(
              top: 50.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () {
                  final story =
                      controller.userStories[controller.currentIndex.value];
                  final isMine = controller.isMyCurrentStory;

                  if (isMine) {
                    Get.toNamed(Routes.myProfile);
                  } else {
                    final friendFromList = controller.findFriendById(
                      story.user.id,
                    );

                    final friend =
                        friendFromList ??
                        controller.buildFriendFromStoryUser(story.user);

                    Get.toNamed(Routes.friendsProfile, arguments: friend);
                  }
                },

                child: Obx(() {
                  if (controller.userStories.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child:
                              controller.currentAvatar != null
                                  ? CachedNetworkImage(
                                    imageUrl: controller.currentAvatar!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.fitWidth,
                                    alignment: Alignment.topCenter,
                                    placeholder:
                                        (context, url) =>
                                            const ShimmerPlaceholder(),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.person,
                                            size: 24,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, size: 24),
                                  ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${controller.currentFirstName} ${controller.currentLastName}"
                                .trim(),
                            style: GoogleFonts.notoSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            timeago.format(controller.currentCreatedAt),
                            style: GoogleFonts.notoSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),

            Obx(() {
              final total = controller.storyCount;
              if (total == 0) return SizedBox();
              final current = controller.currentIndex.value;

              return Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 37.h),
                child: Row(
                  children: List.generate(total, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        height: 4.h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child:
                              index < current
                                  ? Container(color: Colors.white)
                                  : index > current
                                  ? Container(
                                    color: Colors.white.withOpacity(0.3),
                                  )
                                  : AnimatedBuilder(
                                    animation:
                                        controller.storyProgressController,
                                    builder: (context, child) {
                                      return LinearProgressIndicator(
                                        value:
                                            controller
                                                .storyProgressController
                                                .value,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.3),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        minHeight: 4.h,
                                      );
                                    },
                                  ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),

            Positioned(
              top: 50.h,
              // left: 16,
              right: 16,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: UnconstrainedBox(
                      child: SvgPicture.asset(
                        "assets/svg/icons/close_icon.svg",
                        // height: 22,
                        // width: 22,

                        // fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      showPostOptionsSheet();
                    },
                    child: UnconstrainedBox(
                      child: SvgPicture.asset(
                        "assets/svg/icons/moreButton_icon.svg",
                        // height: 22,
                        // width: 22,

                        // fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      controller.shareText();
                    },
                    child: Container(
                      height: 40.w,
                      width: 40.w,
                      // decoration: BoxDecoration(
                      //   color: Color(0xff024B0840),
                      //   shape: BoxShape.circle,
                      // ),
                      child: UnconstrainedBox(
                        child: SvgPicture.asset(
                          "assets/svg/icons/saveOption_icon.svg",
                          // height: 22,
                          // width: 22,

                          // fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showPostOptionsSheet() {
    final bool isMyPost = controller.isMyCurrentStory;

    final List<Map<String, dynamic>> options =
        isMyPost
            ? [
              {
                'label': 'Send To',
                'color': Color(0xffC574F7),
                'onTap': controller.sharePost,
              },
              {
                'label': 'Save to Profile',
                'color': Color(0xffC574F7),
                'onTap': controller.saveToProfile,
              },
              {
                'label': 'Save to Vault',
                'color': Color(0xffC574F7),
                'onTap': controller.saveToVault,
              },
              {
                'label': 'Save to Camera Roll',
                'color': Color(0xffC574F7),
                'onTap': controller.saveToCameraRoll,
              },
              {
                'label': 'Remove Post',
                'color': Colors.red,
                'onTap': controller.removePost,
              },
            ]
            : [
              {
                'label': 'Send To',
                'color': Color(0xffC574F7),
                'onTap': controller.sharePost,
              },
              {
                'label': 'Save to Camera Roll',
                'color': Color(0xffC574F7),
                'onTap': controller.saveToCameraRoll,
              },
            ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: const BoxDecoration(
          color: Color(0xff0202122),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Post Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.6, color: Colors.black),

            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(
                      item['label'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        color: item['color'],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: item['onTap'],
                  ),
                  if (index != options.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Colors.black,
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void showFriendPostOptionsSheet() {
    final List<Map<String, dynamic>> options = [
      {
        'label': 'Send To',
        'color': Color(0xffC574F7),
        'onTap': controller.sharePost,
      },

      {
        'label': 'Save to Camera Roll',
        'color': Color(0xffC574F7),
        'onTap': controller.saveToCameraRoll,
      },
    ];

    Get.bottomSheet(
      Container(
        height: 270.h, // Set height for scrollability
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: const BoxDecoration(
          color: Color(0xff0202122),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Text(
              'Post Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.6, color: Colors.black),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options[index];
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                        title: Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSans(
                            color: item['color'],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: item['onTap'],
                      ),
                      if (index != options.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Colors.black,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
