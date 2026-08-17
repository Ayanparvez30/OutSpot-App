import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';
import 'package:outspot/Views/AllStats/sportVisited.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/MyProfile/miniMeUpdated.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/story_media.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MyProfile extends GetView<MyProfileController> {
  MyProfile({super.key});

  // Per-widget scroll controller + tab key. These MUST live on the widget (not
  // the singleton controller) — otherwise two stacked MyProfile routes (e.g.
  // opening your own profile from a community/friend list while one is already
  // open) would share one ScrollController/GlobalKey and crash with
  // "ScrollController attached to multiple scroll views" / "Multiple widgets
  // used the same GlobalKey".
  final ScrollController _scrollCtrl = ScrollController(
    initialScrollOffset: Get.height - 200,
  );
  final GlobalKey _tabSectionKey = GlobalKey();

  /// Scroll the tab/gallery section just below the collapsed app bar so the
  /// freshly-selected tab's content is visible. Runs after two frames (so the
  /// new tab's grid is laid out) and falls back to the bottom if the precise
  /// offset can't be computed.
  void _scrollTabsIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        final max = _scrollCtrl.position.maxScrollExtent;
        double target = max;
        try {
          final ctx = _tabSectionKey.currentContext;
          if (ctx != null) {
            final box = ctx.findRenderObject();
            if (box is RenderBox) {
              final viewport = RenderAbstractViewport.of(box);
              final reveal = viewport.getOffsetToReveal(box, 0.0).offset;
              target = reveal - 200.h;
            }
          }
        } catch (_) {
          target = max;
        }
        target = target.clamp(0.0, max);
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  /// Land on the top of the profile on (re)entry so back-navigation never keeps
  /// a stale deep offset that shows a blank area.
  void _resetScrollToBaseline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final baseline = (Get.height - 200.h).clamp(
        0.0,
        _scrollCtrl.position.maxScrollExtent,
      );
      _scrollCtrl.jumpTo(baseline);
    });
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MyProfileController());
    Get.put(MainscreeenController());

    // Refresh stats every time screen rebuilds (e.g., returning from another screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUserProfile();
      controller.loadInitialData();
      controller.loadMostRecentCommunityImage();
      // Land on the top of the profile on (re)entry so back-navigation never
      // keeps a stale deep offset that shows a blank area instead of content.
      _resetScrollToBaseline();
    });

    return Scaffold(
      backgroundColor: AppColors.bgGradientBottom,
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height,
            collapsedHeight: 200.h,
            toolbarHeight: 56.h,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xff2D0731),
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              color: Colors.white,
              onPressed: () {
                // Navigate to main screen if:
                //  - the previous route is one of the deep-link screens
                //  - OR the caller passed `fromDeepLink: true` as an argument
                final args = Get.arguments;
                final fromDeepLink =
                    args is Map && args['fromDeepLink'] == true;

                final prev = Get.previousRoute;
                final prevMatches =
                    prev == Routes.shopCloths ||
                    prev == Routes.allStats ||
                    prev == Routes.noCommunity;

                if (fromDeepLink || prevMatches) {
                  // offAllNamed clears the stack so we don't end up with
                  // duplicate MainScreens piled on top.
                  Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
                } else if (Get.key.currentState?.canPop() == true) {
                  Get.back();
                } else {
                  // Nothing to pop back to — fall back to main screen
                  Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
                }
              },
              icon: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 25.r,
                height: 25.r,
              ),

              padding: EdgeInsets.all(8.w),
              constraints: const BoxConstraints(),
            ),

            actions: [
              _actionCircle('assets/svg/icons/download.svg', () {
                controller.shareText(context);
              }),
              SizedBox(width: 15.w),
              _actionCircle(
                'assets/svg/icons/settings.svg',
                () => Get.toNamed(Routes.settingScreen),
              ),
              SizedBox(width: 15.w),
              GestureDetector(
                onTap: () {
                  controller.clearNotificationDot();
                  Get.toNamed(Routes.notification1);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgGradientBottom,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/svg/icons/notification.svg',
                          width: 20.w,
                          height: 20.h,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Obx(() {
                      return controller.notificationRedDot.value
                          ? Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
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
              SizedBox(width: 15.w),
              // Obx(() {
              //   if (controller.stories.isEmpty) {
              //     return GestureDetector(
              //       onTap: () {
              //         Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 2});
              //       },
              //       child: const CircleAvatar(
              //         radius: 17,
              //         backgroundColor: AppColors.MainColor,
              //       ),
              //     );
              //   }
              //   final lastStory = controller.stories.last;
              //   final mediaUrl = lastStory.mediaUrl ?? '';
              //   final user = lastStory.user;
              //   final userAvatarUrl = user.avatarUrl ?? '';

              //   return GestureDetector(
              //     onTap: () {
              //       Get.toNamed(
              //         Routes.postscreen,
              //         arguments: {
              //           "stories": controller.stories,
              //           "startIndex": 0,
              //         },
              //       );
              //     },
              //     child: Container(
              //       width: 34.w,
              //       height: 34.h,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         border: Border.all(
              //           color: const Color(0xff6677FC),
              //           width: 2,
              //         ),
              //         image:
              //             userAvatarUrl.isNotEmpty
              //                 ? DecorationImage(
              //                   image: NetworkImage(mediaUrl),
              //                   fit: BoxFit.cover,
              //                 )
              //                 : null,
              //       ),
              //     ),
              //   );
              // }),
              Obx(() {
                if (controller.stories.isEmpty) {
                  return const SizedBox.shrink();
                }

                final lastStory = controller.stories.last;
                final mediaUrl = lastStory.mediaUrl ?? '';
                final isVideo = lastStory.type.toLowerCase() == 'video';
                return GestureDetector(
                  onTap: () async {
                    await Get.toNamed(
                      Routes.postscreen,
                      arguments: {
                        "stories": controller.stories,
                        "startIndex": 0,
                      },
                    );
                    controller.refreshProfileData();
                  },
                  child:
                      isVideo
                          ? _VideoStoryCircle(
                            videoUrl: mediaUrl,
                            size: 36,
                            borderColor: const Color(0xff6677FC),
                          )
                          : Container(
                            width: 36.w,
                            height: 36.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xff6677FC),
                                width: 2,
                              ),
                              image:
                                  mediaUrl.isNotEmpty
                                      ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          mediaUrl,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                          ),
                );
              }),
              SizedBox(width: 10.w),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final topPadding = MediaQuery.of(context).padding.top;
                final gradientBg = BoxDecoration(
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
                    if (controller.avatarurl.isEmpty) {
                      return const ShimmerPlaceholder(radius: 0);
                    }
                    return CachedNetworkImage(
                      imageUrl: controller.avatarurl.value,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder:
                          (context, url) => const ShimmerPlaceholder(radius: 0),
                      errorWidget:
                          (context, url, error) => Container(
                            decoration: gradientBg,
                            padding: EdgeInsets.only(top: topPadding),
                            child: Image.asset(
                              'assets/Images/Image 203@2x.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                      imageBuilder:
                          (context, imageProvider) => Container(
                            decoration: gradientBg,
                            padding: EdgeInsets.only(top: topPadding),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                    );
                  }),
                );
              },
            ),
          ),

          /* ░░░ Scrollable Card ░░░ */
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: const BoxDecoration(
                color: AppColors.bgGradientBottom,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  /* --- Profile Header --- */
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => Text(
                          controller.firstname.value,
                          style: GoogleFonts.notoSans(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Obx(
                        () => Text(
                          controller.lastname.value,
                          style: GoogleFonts.notoSans(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(
                    () => Text(
                      "@${controller.username.value}",
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  /* --- Wallet Row --- */
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image.asset('assets/Images/coinshape1.png'),
                        Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          preferBelow: false,
                          showDuration: const Duration(milliseconds: 800),
                          decoration: BoxDecoration(
                            color: AppColors.inputFillColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.inputBorderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                          margin: EdgeInsets.only(bottom: 2.h),

                          richMessage: TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: SvgPicture.asset(
                                    'assets/svg/level/coinshape1.svg',
                                    height: 14.h,
                                    width: 14.w,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: 'Overall',
                                style: GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/level/coinshape1.svg',
                                height: 16.h,
                                width: 16.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                compactNumber(controller.coins.value),
                                style: GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 8.w),
                        Container(
                          height: 10.h,
                          width: 1.w,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.w),

                        Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          preferBelow: false,
                          showDuration: const Duration(milliseconds: 800),
                          decoration: BoxDecoration(
                            color: AppColors.inputFillColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.inputBorderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                          margin: EdgeInsets.only(bottom: 2.h),

                          richMessage: TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: SvgPicture.asset(
                                    'assets/svg/level/coinshape2.svg',
                                    height: 14.h,
                                    width: 14.w,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: 'This Week',
                                style: GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/level/coinshape2.svg',
                                height: 16.h,
                                width: 16.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                compactNumber(controller.diamonds.value),
                                style: GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  /* --- Bio (shown right below the points) --- */
                  Obx(() {
                    if (controller.bio.value.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Text(
                        controller.bio.value,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    );
                  }),

                  /* --- Private-account indicator (only when locked) --- */
                  Obx(() {
                    if (!controller.isPrivate.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 15.sp,
                            color: Colors.white54,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'You have locked your account',
                            style: GoogleFonts.notoSans(
                              color: Colors.white54,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 16.h),

                  /* --- Friends / Community --- */
                  // Row(
                  //   children: [
                  //     GestureDetector(
                  //       onTap: () => Get.toNamed(Routes.friendlist),
                  //       child: Container(
                  //         height: 86.h,
                  //         width: 150.w,
                  //         padding: EdgeInsets.all(15.w),
                  //         decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.circular(12.r),
                  //           border: Border.all(color: AppColors.BorderColor),
                  //           color: AppColors.bgGradientBottom,
                  //         ),
                  //         child: Column(
                  //           children: [
                  //             Text(
                  //               "Friends",
                  //               style: TextStyle(
                  //                 fontSize: 18.sp,
                  //                 fontWeight: FontWeight.w900,
                  //                 color: Colors.white,
                  //               ),
                  //             ),
                  //             SizedBox(height: 8.h),
                  //             Row(
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               children: [
                  //                 Image.asset(
                  //                   'assets/Images/user-svgrepo-com (3).png',
                  //                   height: 16.h,
                  //                   width: 16.w,
                  //                   color: Colors.white,
                  //                 ),
                  //                 SizedBox(width: 5.w),
                  //                 Obx(
                  //                   () => Text(
                  //                     controller.friendCount.value == 0
                  //                         ? "0"
                  //                         : controller.friendCount.value
                  //                             .toString(),
                  //                     style: TextStyle(color: Colors.white),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //     SizedBox(width: 18.w),
                  //     Obx(() {
                  //       final imageUrl = controller.lastCommunityImage.value;

                  //       return GestureDetector(
                  //         onTap: () => Get.toNamed(Routes.noCommunity),
                  //         child: Container(
                  //           height: 86.h,
                  //           width: 150.w,
                  //           padding: EdgeInsets.all(15.w),
                  //           decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.circular(12.r),
                  //             border: Border.all(
                  //               color: AppColors.BorderColor,
                  //             ),
                  //             color: AppColors.bgGradientBottom,
                  //           ),
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Text(
                  //                 "Community",
                  //                 style: TextStyle(
                  //                   fontSize: 18.sp,
                  //                   fontWeight: FontWeight.w900,
                  //                   color: Colors.white,
                  //                 ),
                  //               ),
                  //               SizedBox(height: 2.h),
                  //               Container(
                  //                 width: 25.w,
                  //                 height: 25.h,
                  //                 decoration: BoxDecoration(
                  //                   shape: BoxShape.circle,
                  //                   color: Colors.white,

                  //                   image:
                  //                       imageUrl.isNotEmpty
                  //                           ? DecorationImage(
                  //                             image: NetworkImage(imageUrl),
                  //                             fit: BoxFit.cover,
                  //                           )
                  //                           : null, // null দিলে child Icon দেখানো যাবে
                  //                 ),
                  //                 child:
                  //                     imageUrl.isEmpty
                  //                         ? Image.asset(
                  //                           "assets/Images/communitynone.png",
                  //                           color: AppColors.MainColor,
                  //                         )
                  //                         : null,
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       );
                  //     }),
                  //   ],
                  // ),
                  Container(
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
                          child: Obx(() {
                            String formatCount(int count) {
                              if (count >= 1000) {
                                return (count / 1000)
                                        .toStringAsFixed(1)
                                        .replaceAll(RegExp(r'\.0$'), '') +
                                    'k';
                              }
                              return count.toString();
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.location_on_outlined,
                                    value: formatCount(
                                      controller.spotsVisited.value,
                                    ),
                                    label: "Spots Visited",
                                    iconColor: Colors.deepPurpleAccent,
                                    onTap: () {
                                      // Prime the shared stats controller with
                                      // MY visited spots first — the screen
                                      // itself never loads, so opening it
                                      // straight from the profile would show an
                                      // empty list otherwise.
                                      AllStatsController.instance
                                          .ensureOwnSpotsLoaded();
                                      Get.to(() => const SpotsVisitedScreen());
                                    },
                                  ),
                                ),
                                _buildVerticalDivider(),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.person_outline,
                                    value: formatCount(
                                      controller.friends.value,
                                    ),
                                    label: "Friends",
                                    iconColor: Colors.pinkAccent,
                                    onTap: () {
                                      Get.toNamed(Routes.friendlist);
                                    },
                                  ),
                                ),
                                _buildVerticalDivider(),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.people_outline,
                                    value:
                                        (controller.myCommunityId.value == 0 ||
                                                controller
                                                    .lastCommunityName
                                                    .value
                                                    .isEmpty)
                                            ? "None"
                                            : controller
                                                .lastCommunityName
                                                .value,
                                    label: "Community",
                                    iconColor: Colors.orangeAccent,
                                    imageUrl:
                                        controller.lastCommunityImage.value,
                                    onTap: () {
                                      if (controller.myCommunityId.value != 0) {
                                        Get.toNamed(
                                          Routes.community,
                                          arguments: {
                                            "id":
                                                controller.myCommunityId.value,
                                          },
                                        )?.then(
                                          (_) => controller.refreshStats(),
                                        );
                                      } else {
                                        Get.toNamed(Routes.noCommunity);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),

                        // Bottom Section: Show All Stats Button
                        GestureDetector(
                          onTap: () {
                            Get.toNamed(Routes.allStats);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color(0xffC574F7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(() {
                    final accontroller = Get.find<MainscreeenController>();
                    final ttl = accontroller.myAchievements.value?.title ?? '';

                    // --- asset & style select ---
                    String assetPath = "assets/Images/newlevel.png";
                    double? height;
                    double? width;
                    double? scale;

                    if (ttl == "Urban Explorer") {
                      assetPath = "assets/svg/level/urbar_explorer.svg";
                      height = 70.h;
                      width = 210.w;
                    } else if (ttl == "Legendary Explorer") {
                      assetPath = "assets/svg/level/legendary_explorer.svg";
                      height = 70.h;
                      width = 210.w;
                    } else if (ttl == "City Sniper") {
                      assetPath = "assets/svg/level/city_snipper.svg";
                      height = 70.h;
                      width = 210.w;
                    } else if (ttl == "New Explorer") {
                      assetPath = "assets/svg/level/new_explorer.svg";
                      height = 70.h;
                      width = 210.w;
                    } else {
                      // default
                      assetPath = "assets/svg/level/new_explorer.svg";
                      height = 70.h;
                      width = 210.w;
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Get.toNamed(Routes.viewAchievements),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 60.w,
                          vertical: 20.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(color: Color(0xff703A8B)),

                          // color: Color(0xff703A8B),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Achievment Badges',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            // Badge image only — the surrounding purple container
                            // was removed per design; just show the badge SVG.
                            SvgPicture.asset(
                              assetPath,
                              height: height,
                              width: width,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: 15.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // _pillButton(
                      //   label: 'Store',
                      //   icon: 'assets/Images/store.png',
                      //   color: const Color(0xff66CCFC),
                      //   onTap: () => Get.toNamed(Routes.shopCloths),
                      // ),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(
                            Routes.shopCloths,
                            arguments: {"bodyType": controller.bodyType.value},
                          );
                        },
                        child: Container(
                          height: 50.h,
                          width: 150.w,
                          // padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            gradient: LinearGradient(
                              colors: [Color(0xffAB50F6), Color(0xffFB7D6C)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/icons/store.svg',
                                height: 18.h,
                                width: 18.w,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Store',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      //   _pillButton(
                      //     label: 'Wardrobe',
                      //     icon: 'assets/Images/wordrobe.png',
                      //     color: Color(0xff42D880),
                      //     onTap: () => Get.toNamed(Routes.waredrop),
                      //   ),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.waredrop),
                        child: Container(
                          height: 50.h,
                          width: 150.w,
                          // padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            gradient: LinearGradient(
                              colors: [Color(0xffFF8364), Color(0xffFFB14D)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/icons/wordrobe.svg',
                                height: 18.h,
                                width: 18.w,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Wardrobe',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 25.h),

                  /* --- Tabs & Gallery --- */
                  Obx(() {
                    final selected = controller.selectedTab.value;

                    // final items = controller.images[selected] ?? [];

                    return Column(
                      key: _tabSectionKey,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _tabBtn('My Photos'),
                              SizedBox(width: 10.w),
                              _tabBtn('Vault'),
                              // _tabBtn('My Locker'),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        /* grid + optional overlay */
                        Stack(
                          children: [
                            // My Locker Grid
                            if (selected == 'My Locker')
                              Obx(() {
                                if (controller.isLoading.value) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (controller.lockerItems.isEmpty) {
                                  return _emptyState(
                                    "Your Locker is empty",
                                    "Avatars (mini-mes) you create or buy are stored here for you to switch between.",
                                  );
                                }

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                  ),
                                  itemCount: controller.lockerItems.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 3,
                                        mainAxisSpacing: 3,
                                        childAspectRatio: 0.5,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = controller.lockerItems[index];
                                    return _gridImageItem(
                                      context,
                                      item['avatarUrl'] ?? '',
                                      minimeId: item['id'] as int?,
                                      // The first locker item is always the most
                                      // recently used avatar — flag it so users
                                      // can tell which one is active.
                                      isRecent: index == 0,
                                    );
                                  },
                                );
                              }),

                            // My Photos Grid
                            if (selected == 'My Photos')
                              Obx(() {
                                if (controller.isStoriesLoading.value) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (controller.savedStories.isEmpty) {
                                  return _emptyState(
                                    "No photos yet",
                                    "Photos and stories you save will show up here for quick access.",
                                  );
                                }
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                  ),
                                  itemCount: controller.savedStories.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 3,
                                        mainAxisSpacing: 3,
                                        childAspectRatio: 0.5,
                                      ),
                                  itemBuilder: (context, index) {
                                    final story =
                                        controller.savedStories[index];
                                    return GestureDetector(
                                      onLongPress:
                                          () => _confirmDeleteStory(story.id),
                                      onTap:
                                          () => Get.to(
                                            () => StoryViewerScreen(
                                              url: story.mediaUrl,
                                              type: story.type,
                                              onDelete:
                                                  () => _confirmDeleteStory(
                                                    story.id,
                                                    onDeleted: () => Get.back(),
                                                  ),
                                            ),
                                          ),
                                      child: StoryGridThumb(
                                        url: story.mediaUrl,
                                        type: story.type,
                                      ),
                                    );
                                  },
                                );
                              }),

                            if (selected == 'Vault')
                              Obx(() {
                                if (controller.isVaultLoading.value) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (controller.vaultStories.isEmpty) {
                                  return _emptyState(
                                    "Your Vault is empty",
                                    "The Vault keeps your private stories — saved here after they expire, visible only to you.",
                                  );
                                }

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                  ),
                                  itemCount: controller.vaultStories.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 3,
                                        mainAxisSpacing: 3,
                                        childAspectRatio: 0.5,
                                      ),
                                  itemBuilder: (context, index) {
                                    final story =
                                        controller.vaultStories[index];
                                    return GestureDetector(
                                      onLongPress:
                                          () => _confirmDeleteStory(story.id),
                                      onTap:
                                          () => Get.to(
                                            () => StoryViewerScreen(
                                              url: story.mediaUrl,
                                              type: story.type,
                                              onDelete:
                                                  () => _confirmDeleteStory(
                                                    story.id,
                                                    onDeleted: () => Get.back(),
                                                  ),
                                            ),
                                          ),
                                      child: StoryGridThumb(
                                        url: story.mediaUrl,
                                        type: story.type,
                                      ),
                                    );
                                  },
                                );
                              }),
                          ],
                        ),
                      ],
                    );
                  }),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ═══ Helper Widgets ═══ */

  /// Confirm + delete a saved story by its clone id. [onDeleted] runs after a
  /// successful delete (e.g. to pop the full-screen viewer).
  void _confirmDeleteStory(int storyId, {VoidCallback? onDeleted}) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text(
          "Delete photo?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          "This will permanently remove it from your photos.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close confirm dialog
              final ok = await controller.deleteSavedStory(storyId);
              if (ok) {
                // Pop the viewer FIRST, then show the snackbar — otherwise the
                // viewer's Get.back() pops the snackbar route instead of the page.
                onDeleted?.call();
                AppSnackbar.success("Story removed successfully.");
              } else {
                AppSnackbar.error("Failed to remove story");
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCircle(String asset, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34.w,
      height: 34.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgGradientBottom,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset,
        height: 20.h,
        width: 20.w,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    ),
  );
  // Widget _statsBox({
  //   required String title,
  //   required RxString value, // <-- Reactive string
  //   required String icon,
  //   double imgSize = 16,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       height: 80.h,
  //       width: 150.w,
  //       padding: EdgeInsets.all(15.w),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(12.r),
  //         border: Border.all(color: const Color(0xFFE8EAEB)),
  //         color: Colors.white,
  //       ),
  //       child: Column(
  //         children: [
  //           Text(
  //             title,
  //             style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
  //           ),
  //           const SizedBox(height: 4),
  //           Obx(() => Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Image.asset(icon, height: imgSize.h, width: imgSize.w),
  //                   if (value.value > 0) ...[
  //                     SizedBox(width: 5.w),
  //                     Text(value.value.toString()),
  //                   ],
  //                 ],
  //               )),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _pillButton({
    required String label,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50.h,
      width: 150.w,
      // padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        color: color,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, height: 18.h, width: 18.w),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  /// Friendly empty-state: a looping Lottie illustration with a title and a
  /// purpose line, instead of a bare "nothing here" message.
  Widget _emptyState(String title, String subtitle) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 1.h),
    child: Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/Images/blank.json',
            width: 150.w,
            height: 150.w,
            repeat: true,
            fit: BoxFit.contain,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              color: Colors.white70,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tabBtn(String title) => Obx(() {
    final bool selected = controller.selectedTab.value == title;
    return GestureDetector(
      onTap: () {
        controller.selectedTab.value = title;
        _scrollTabsIntoView();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.textOut : AppColors.MainColor,
          borderRadius: BorderRadius.circular(20.r),
          // border: Border.all(
          //   color: selected ? Colors.black : Colors.grey.shade400,
          // ),
        ),
        child: Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 12.sp,
            // color: selected ? Colors.white : Colors.black,
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w700,
          ),
        ),
      ),
    );
  });

  /// Grid item widget for Locker images. [isRecent] marks the currently-used
  /// (most recent) avatar with a green border + check badge so users know which
  /// one is active.
  Widget _gridImageItem(
    BuildContext context,
    String imageUrl, {
    int? minimeId,
    bool isRecent = false,
  }) {
    const recentGreen = Color(0xff42D880);
    return GestureDetector(
      onTap: () async {
        if (imageUrl.isNotEmpty) {
          final updatedImage = await Get.to<String>(
            () => Minimeupdated(imagePath: imageUrl, minimeId: minimeId),
          );

          if (updatedImage != null && updatedImage.isNotEmpty) {
            MyProfileController.instance.updateAvatarLocal(updatedImage);
            // Refresh the locker so the just-used avatar jumps to the front
            // immediately (previously it only reordered after leaving and
            // re-entering the screen).
            controller.fetchLockerItems();

            // Get.snackbar(
            //   "Success",
            //   "Mini-me updated!",
            //   backgroundColor: Colors.green,
            //   colorText: Colors.white,
            //   snackPosition: SnackPosition.TOP,
            // );
          }
        } else {
          AppSnackbar.error("Image not available");
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.black, width: 1),
              color: AppColors.bgGradientBottom,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => const ShimmerPlaceholder(radius: 0),
              errorWidget:
                  (context, url, error) =>
                      const Center(child: Icon(Icons.broken_image)),
            ),
          ),
          if (isRecent)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: recentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // Single Stat Item Helper with onTap required
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required VoidCallback onTap, // Added this parameter
    String? imageUrl,
    double valueFontSize = 22,
  }) {
    // Auto-shrink the font for longer values (e.g. community names) so short
    // values stay big like the numbers, long ones step down instead of being
    // cut or shrunk to an unreadable single line.
    final int len = value.length;
    double autoFontSize = valueFontSize;
    if (len > 14) {
      autoFontSize = 17;
    } else if (len > 10) {
      autoFontSize = 17;
    } else if (len > 6) {
      autoFontSize = 18;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Ensures the entire area is clickable
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withOpacity(0.2),
            backgroundImage:
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(imageUrl) as ImageProvider
                    : null,
            child:
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? null
                    : Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          // Fixed-height, centered value so short numbers and long community
          // names all share the same baseline (keeps labels aligned in a row).
          SizedBox(
            height: 28.h,
            child:
                value.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: autoFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xff95A4A7), fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  // Vertical Divider Helper
  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 2, color: Color(0xff703A8B));
  }
}

class _VideoStoryCircle extends StatefulWidget {
  final String videoUrl;
  final double size;
  final Color borderColor;

  const _VideoStoryCircle({
    required this.videoUrl,
    required this.size,
    required this.borderColor,
  });

  @override
  State<_VideoStoryCircle> createState() => _VideoStoryCircleState();
}

class _VideoStoryCircleState extends State<_VideoStoryCircle> {
  String? _thumbPath;
  bool _loading = true;

  static final Map<String, String> _cache = {};
  static Directory? _cacheDir;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= Directory(
      '${(await getTemporaryDirectory()).path}/profile_thumbs',
    );
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<void> _loadThumb() async {
    if (widget.videoUrl.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Memory cache
    if (_cache.containsKey(widget.videoUrl)) {
      final path = _cache[widget.videoUrl]!;
      if (await File(path).exists()) {
        if (mounted)
          setState(() {
            _thumbPath = path;
            _loading = false;
          });
        return;
      }
      _cache.remove(widget.videoUrl);
    }

    // Disk cache
    final dir = await _getCacheDir();
    final hash = widget.videoUrl.hashCode.toRadixString(16);
    final file = File('${dir.path}/$hash.jpg');
    if (await file.exists()) {
      _cache[widget.videoUrl] = file.path;
      if (mounted)
        setState(() {
          _thumbPath = file.path;
          _loading = false;
        });
      return;
    }

    // Generate
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 80,
      );
      if (path != null && await File(path).exists()) {
        _cache[widget.videoUrl] = path;
        if (mounted)
          setState(() {
            _thumbPath = path;
            _loading = false;
          });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size.w,
      height: widget.size.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.borderColor, width: 2),
        image:
            _thumbPath != null
                ? DecorationImage(
                  image: FileImage(File(_thumbPath!)),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          _loading
              ? ClipOval(
                child: SizedBox(
                  width: widget.size.w,
                  height: widget.size.h,
                  child: const ShimmerPlaceholder(),
                ),
              )
              : _thumbPath == null
              ? ClipOval(
                child: Container(
                  color: Colors.black,
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              )
              : null,
    );
  }
}
