import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/communityleaderbord.dart';
import 'package:outspot/Model/global_leaderboard.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/CommonWidgets/community_access.dart';
import 'package:outspot/Views/Leaderboard%20Global1/leaderboaddglobal_controller.dart';

class LeaderboardGlobal extends GetView<LeaderboaddglobalController> {
  const LeaderboardGlobal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header section
                  // Static Container — transparent so the screen's radial
                  // gradient shows through the search UI. No Obx here: the
                  // reactive parts inside have their own Obx, and an Obx that
                  // reads no observable throws "improper use of GetX".
                  Container(
                    color: Colors.transparent,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() {
                            return controller.isSearching.value
                                ? Container(
                                  height: 50.h,
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 80.w),
                                        child: Text(
                                          "Search Leaderboard",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 50.w),
                                        child: GestureDetector(
                                          onTap: () {
                                            controller.searchQuery.value = '';
                                            controller.isSearching.value =
                                                false;
                                            controller.searchcontroller.clear();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 35.sp,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Padding(
                                  padding: EdgeInsets.only(
                                    top: 5.h,
                                    left: 20.w,
                                    right: 15.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomBackButton(
                                        onTap: () {
                                          final args = Get.arguments;
                                          if (args != null &&
                                              args['from'] ==
                                                  'sendSubmitchallange') {
                                            Get.offAllNamed(
                                              Routes.mainscreen,
                                              arguments: {'tab': 2},
                                            );
                                          } else {
                                            Get.back();
                                          }
                                        },
                                      ),
                                      Text(
                                        "Leaderboard",
                                        style: GoogleFonts.notoSans(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(7.w),
                                            decoration: BoxDecoration(
                                              color: AppColors.fillnoti,
                                              shape: BoxShape.circle,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                controller.isSearching.value =
                                                    true;
                                              },
                                              child: SvgPicture.asset(
                                                "assets/svg/leaderboard/search.svg",
                                                width: 16.sp,
                                                height: 16.sp,
                                                colorFilter: ColorFilter.mode(
                                                  AppColors.white,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5.w),
                                          Builder(
                                            builder:
                                                (ctx) => GestureDetector(
                                                  onTap: () {
                                                    final box =
                                                        ctx.findRenderObject()
                                                            as RenderBox?;
                                                    final origin =
                                                        box != null
                                                            ? box.localToGlobal(
                                                                  Offset.zero,
                                                                ) &
                                                                box.size
                                                            : null;
                                                    if (controller
                                                        .isGlobalTab
                                                        .value) {
                                                      final g =
                                                          controller
                                                              .global
                                                              .value;
                                                      final myInfo = g?.myInfo;
                                                      if (myInfo != null &&
                                                          myInfo.userId != 0) {
                                                        controller.shareMyInfo(
                                                          myInfo,
                                                          origin: origin,
                                                        );
                                                      }
                                                    } else {
                                                      final community =
                                                          controller
                                                              .myCreatedCommunity
                                                              .value;
                                                      controller
                                                          .shareMyCommunity(
                                                            community,
                                                            origin: origin,
                                                          );
                                                    }
                                                  },
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding: EdgeInsets.all(
                                                      7.w,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppColors
                                                                  .fillnoti,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Image.asset(
                                                      "assets/Images/skfile.png",
                                                      scale: 2,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                          }),
                          SizedBox(height: 2.h),
                          Obx(() {
                            return controller.isSearching.value
                                ? Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 17.w,
                                    vertical: 8.h,
                                  ),
                                  child: CustomTextField(
                                    controller: controller.searchcontroller,
                                    hintText: "Search",
                                    suffixIcon: IconButton(
                                      icon: SvgPicture.asset(
                                        "assets/svg/leaderboard/search.svg",
                                        width: 18.sp,
                                        height: 18.sp,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.fillnoti,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      onPressed: () {
                                        controller.isSearching.value = false;
                                        controller.searchQuery.value = '';
                                      },
                                    ),
                                    onChanged: (value) {
                                      controller.searchQuery.value = value;
                                    },
                                  ),
                                )
                                : buildToggleTabs();
                          }),
                          SizedBox(height: 5.h),
                        ],
                      ),
                    ),

                  // Content area: placeholder or podium + list
                  Expanded(
                    child: Obx(() {
                      // In search mode the results panel covers this area — hide
                      // the podium/list so the screen's radial gradient shows
                      // behind the search results instead of a flat fill.
                      if (controller.isSearching.value) {
                        return const SizedBox.shrink();
                      }
                      final globalEmpty =
                          controller.isGlobalTab.value &&
                          controller.globalleaderboard.isEmpty &&
                          !controller.loading.value;
                      final communityEmpty =
                          !controller.isGlobalTab.value &&
                          controller.leaderboard.isEmpty &&
                          !controller.loading.value;

                      if (globalEmpty || communityEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.leaderboard_outlined,
                                  size: 48.sp,
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No Activity Yet',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  controller.isGlobalTab.value
                                      ? 'Leaderboard data will appear here once users start earning points.'
                                      : 'Community rankings will appear here once members start earning points.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13.sp,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Podium section — SVG + users locked in one Stack
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;
                              final svgAvailW = w - 16.w;
                              final svgH3 = svgAvailW * 132 / 361;
                              final podiumItemH = 58.w + 6.h + 18.sp + 28.h;
                              final gap = 5.w;
                              final svgPush = 15.h;
                              final totalH =
                                  podiumItemH + svgH3 + gap + svgPush;
                              return SizedBox(
                                height: totalH,
                                child: Obx(() {
                                  final globalSnap = List<UserLeaderboard>.from(
                                    controller.globalleaderboard,
                                  );
                                  final localSnap =
                                      List<CommunityLeaderboard>.from(
                                        controller.leaderboard,
                                      );
                                  globalSnap.sort(
                                    (a, b) => b.points.compareTo(a.points),
                                  );
                                  localSnap.sort(
                                    (a, b) => b.points.compareTo(a.points),
                                  );

                                  final isGlobal = controller.isGlobalTab.value;
                                  // Always render the 3-podium layout regardless
                                  // of user count. Per-slot guards below skip any
                                  // missing 2nd/3rd users. (2-podium branch kept
                                  // below but intentionally unreachable.)
                                  const hasThree = true;
                                  final svgW = w - 16.w;
                                  final svgH =
                                      hasThree
                                          ? svgW * 132 / 361
                                          : svgW * 132 / 246;

                                  return Stack(
                                    children: [
                                      // SVG pedestal — positioned from top
                                      Positioned(
                                        top: podiumItemH + gap + svgPush + 10.h,
                                        left: 8.w,
                                        right: 8.w,
                                        child: IgnorePointer(
                                          child: SvgPicture.asset(
                                            hasThree
                                                ? "assets/svg/leaderboard/ranking.svg"
                                                : "assets/svg/leaderboard/ranking_2.svg",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      // Users — positioned from top
                                      if (isGlobal) ...[
                                        if (hasThree) ...[
                                          if (globalSnap.isNotEmpty)
                                            Positioned(
                                              top: 15.h,
                                              left: w * 0.34,
                                              width: w * 0.32,
                                              child: user(globalSnap[0]),
                                            ),
                                          if (globalSnap.length > 1)
                                            Positioned(
                                              top: 40.h,
                                              left: w * 0.043,
                                              width: w * 0.32,
                                              child: user(globalSnap[1]),
                                            ),
                                          if (globalSnap.length > 2)
                                            Positioned(
                                              top: 55.h,
                                              right: w * 0.036,
                                              width: w * 0.32,
                                              child: user(globalSnap[2]),
                                            ),
                                        ] else ...[
                                          if (globalSnap.isNotEmpty)
                                            Positioned(
                                              top: 10.h,
                                              right: w * 0.15,
                                              width: w * 0.40,
                                              child: user(globalSnap[0]),
                                            ),
                                          if (globalSnap.length > 1)
                                            Positioned(
                                              top: 25.h,
                                              left: w * 0.15,
                                              width: w * 0.40,
                                              child: user(globalSnap[1]),
                                            ),
                                        ],
                                      ] else ...[
                                        if (hasThree) ...[
                                          if (localSnap.isNotEmpty)
                                            Positioned(
                                              top: 15.h,
                                              left: w * 0.34,
                                              width: w * 0.32,
                                              child: buildPodiumItem(
                                                localSnap[0],
                                                topPadding: 0,
                                              ),
                                            ),
                                          if (localSnap.length >= 2)
                                            Positioned(
                                              top: 40.h,
                                              left: w * 0.043,
                                              width: w * 0.32,
                                              child: buildPodiumItem(
                                                localSnap[1],
                                                topPadding: 0,
                                              ),
                                            ),
                                          if (localSnap.length >= 3)
                                            Positioned(
                                              top: 55.h,
                                              right: w * 0.036,
                                              width: w * 0.32,
                                              child: buildPodiumItem(
                                                localSnap[2],
                                                topPadding: 0,
                                              ),
                                            ),
                                        ] else ...[
                                          if (localSnap.isNotEmpty)
                                            Positioned(
                                              top: 10.h,
                                              right: w * 0.16,
                                              width: w * 0.40,
                                              child: buildPodiumItem(
                                                localSnap[0],
                                                topPadding: 0,
                                              ),
                                            ),
                                          if (localSnap.length >= 2)
                                            Positioned(
                                              top: 25.h,
                                              left: w * 0.145,
                                              width: w * 0.40,
                                              child: buildPodiumItem(
                                                localSnap[1],
                                                topPadding: 0,
                                              ),
                                            ),
                                        ],
                                      ],
                                    ],
                                  );
                                }),
                              );
                            },
                          ),

                          // List section (fills space between podium and bottom bar)
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Transform.translate(
                                    offset: Offset(0, 0.h),
                                    child: Obx(
                                      () => Container(
                                        child:
                                            controller.loading.value
                                                ? _buildShimmerList()
                                                : Obx(() {
                                                  // ei line ta dorkar nai, error dibe, এটা মুছে দিন
                                                  // final WindowInfo? window;

                                                  final results = List<
                                                    UserLeaderboard
                                                  >.from(
                                                    controller
                                                        .globalleaderboard,
                                                  );

                                                  // final listToShow =
                                                  //     results.length > 3
                                                  //         ? results.sublist(3)
                                                  //         : <UserLeaderboard>[];
                                                  final listToShow = results;

                                                  final filtered =
                                                      controller
                                                              .searchQuery
                                                              .value
                                                              .isEmpty
                                                          ? listToShow
                                                          : listToShow
                                                              .where(
                                                                (c) => c
                                                                    .username
                                                                    .toLowerCase()
                                                                    .contains(
                                                                      controller
                                                                          .searchQuery
                                                                          .value
                                                                          .toLowerCase(),
                                                                    ),
                                                              )
                                                              .toList();

                                                  return controller
                                                          .isGlobalTab
                                                          .value
                                                      ? Container(
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xff2D0731,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      24.sp,
                                                                    ),
                                                                topRight:
                                                                    Radius.circular(
                                                                      24.sp,
                                                                    ),
                                                              ),
                                                        ),
                                                        child:
                                                            filtered.isEmpty
                                                                ? Center(
                                                                  child: Padding(
                                                                    padding: EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          32.w,
                                                                    ),
                                                                    child: Text(
                                                                      'No leaderboard activity yet.\nData will appear once users start earning points.',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: GoogleFonts.notoSans(
                                                                        fontSize:
                                                                            14.sp,
                                                                        color: Colors.white.withValues(
                                                                          alpha:
                                                                              0.5,
                                                                        ),
                                                                        height:
                                                                            1.5,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                                : ListView.builder(
                                                                  padding:
                                                                      EdgeInsets.symmetric(
                                                                        vertical:
                                                                            8.h,
                                                                      ),
                                                                  itemCount:
                                                                      filtered
                                                                          .length,
                                                                  itemBuilder: (
                                                                    context,
                                                                    ind,
                                                                  ) {
                                                                    final user =
                                                                        filtered[ind];
                                                                    return Padding(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            16.w,
                                                                        vertical:
                                                                            5.h,
                                                                      ),
                                                                      child: Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                24.w,
                                                                            child: Text(
                                                                              "${ind + 1}",
                                                                              style: GoogleFonts.notoSans(
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                                fontSize:
                                                                                    15.sp,
                                                                                color:
                                                                                    AppColors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                12.w,
                                                                          ),
                                                                          GestureDetector(
                                                                            behavior:
                                                                                HitTestBehavior.opaque,
                                                                            onTap:
                                                                                () => _openUserProfile(
                                                                                  user.userId,
                                                                                ),
                                                                            child: _buildListAvatar(
                                                                              user.avatarUrl,
                                                                              name:
                                                                                  user.username,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                12.w,
                                                                          ),
                                                                          Expanded(
                                                                            child: GestureDetector(
                                                                              behavior:
                                                                                  HitTestBehavior.opaque,
                                                                              onTap:
                                                                                  () => _openUserProfile(
                                                                                    user.userId,
                                                                                  ),
                                                                              child: Text(
                                                                                user.fullName,
                                                                                style: GoogleFonts.notoSans(
                                                                                  fontSize:
                                                                                      15.sp,
                                                                                  color:
                                                                                      AppColors.white,
                                                                                  fontWeight:
                                                                                      FontWeight.w600,
                                                                                ),
                                                                                overflow:
                                                                                    TextOverflow.ellipsis,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                8.w,
                                                                          ),
                                                                          if (ind < 3 &&
                                                                              user.prize.isNotEmpty)
                                                                            Padding(
                                                                              padding: EdgeInsets.only(
                                                                                right:
                                                                                    8.w,
                                                                              ),
                                                                              child: _buildPrizeBadge(
                                                                                ind,
                                                                                user.prize,
                                                                              ),
                                                                            ),
                                                                          _buildPoints(
                                                                            user.points,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                      )
                                                      : Container(
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xff2D0731,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      24.sp,
                                                                    ),
                                                                topRight:
                                                                    Radius.circular(
                                                                      24.sp,
                                                                    ),
                                                              ),
                                                        ),
                                                        child: Builder(
                                                          builder: (context) {
                                                            final othercommunity =
                                                                controller
                                                                    .leaderboard;

                                                            final listToShow =
                                                                othercommunity;

                                                            final filtered =
                                                                controller
                                                                        .searchQuery
                                                                        .value
                                                                        .isEmpty
                                                                    ? listToShow
                                                                    : listToShow
                                                                        .where(
                                                                          (
                                                                            c,
                                                                          ) => c
                                                                              .name
                                                                              .toLowerCase()
                                                                              .contains(
                                                                                controller.searchQuery.value.toLowerCase(),
                                                                              ),
                                                                        )
                                                                        .toList();

                                                            if (filtered
                                                                .isEmpty) {
                                                              return Center(
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            32.w,
                                                                      ),
                                                                  child: Text(
                                                                    'No community activity yet.\nData will appear once members start earning points.',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts.notoSans(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.5,
                                                                          ),
                                                                      height:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                            return ListView.builder(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        8.h,
                                                                  ),
                                                              itemCount:
                                                                  filtered
                                                                      .length,
                                                              itemBuilder: (
                                                                context,
                                                                ind,
                                                              ) {
                                                                final i =
                                                                    filtered[ind];

                                                                return Padding(
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16.w,
                                                                    vertical:
                                                                        5.h,
                                                                  ),
                                                                  child: Row(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      SizedBox(
                                                                        width:
                                                                            24.w,
                                                                        child: Text(
                                                                          "${ind + 1}",
                                                                          style: GoogleFonts.notoSans(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize:
                                                                                15.sp,
                                                                            color:
                                                                                AppColors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            12.w,
                                                                      ),
                                                                      GestureDetector(
                                                                        behavior:
                                                                            HitTestBehavior.opaque,
                                                                        onTap:
                                                                            () => openCommunityIfMember(
                                                                              i.communityId,
                                                                              communityName:
                                                                                  i.name,
                                                                            ),
                                                                        child: _buildListAvatar(
                                                                          i.imageUrl,
                                                                          name:
                                                                              i.name,
                                                                          isCommunity:
                                                                              true,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            12.w,
                                                                      ),
                                                                      Expanded(
                                                                        child: GestureDetector(
                                                                          behavior:
                                                                              HitTestBehavior.opaque,
                                                                          onTap:
                                                                              () => openCommunityIfMember(
                                                                                i.communityId,
                                                                                communityName:
                                                                                    i.name,
                                                                              ),
                                                                          child: Text(
                                                                            i.name,
                                                                            style: GoogleFonts.notoSans(
                                                                              fontSize:
                                                                                  15.sp,
                                                                              fontWeight:
                                                                                  FontWeight.w600,
                                                                              color:
                                                                                  AppColors.white,
                                                                            ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8.w,
                                                                      ),
                                                                      _buildPoints(
                                                                        i.points,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      );
                                                }),
                                      ),
                                    ),
                                  ),
                                ),
                                Obx(() {
                                  final community =
                                      controller.myCreatedCommunity.value;
                                  // Fall back to the community the user JOINED
                                  // when they didn't create one.
                                  final joinedCommunity =
                                      controller.myCommunityStanding.value;
                                  final int myCommunityId =
                                      community?.communityId ??
                                      joinedCommunity?.communityId ??
                                      0;
                                  final String? myCommunityName =
                                      community?.name ?? joinedCommunity?.name;
                                  final String? myCommunityImage =
                                      community?.imageUrl ??
                                      joinedCommunity?.imageUrl;
                                  final int myCommunityPoints =
                                      community?.points ??
                                      joinedCommunity?.points ??
                                      0;
                                  final String myCommunityRank =
                                      (community?.rank ?? joinedCommunity?.rank)
                                          ?.toString() ??
                                      '-';
                                  final g = controller.global.value;
                                  final me = g?.myInfo;
                                  final isGlobal = controller.isGlobalTab.value;

                                  // While loading, show a shimmer row instead of
                                  // an "Unknown" placeholder.
                                  if (controller.loading.value) {
                                    return _buildBottomBarShimmer();
                                  }

                                  if (isGlobal) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15.w,
                                      ),
                                      height: 55.h,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 28.w,
                                            child: Text(
                                              me?.rank?.toString() ?? '-',
                                              style: GoogleFonts.notoSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap:
                                                () => _openUserProfile(
                                                  me?.userId ?? 0,
                                                ),
                                            child: _buildListAvatar(
                                              me?.avatarUrl,
                                              name: me?.username,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap:
                                                  () => _openUserProfile(
                                                    me?.userId ?? 0,
                                                  ),
                                              child: Text(
                                                me?.fullName ?? '-',
                                                style: GoogleFonts.notoSans(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          _buildPoints(me?.points ?? 0),
                                        ],
                                      ),
                                    );
                                  } else {
                                    // The user's community isn't on the
                                    // leaderboard (e.g. 0 points) — hide the
                                    // bottom standing bar entirely rather than
                                    // show an empty "- ? — 0" row.
                                    if (community == null &&
                                        joinedCommunity == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15.w,
                                      ),
                                      height: 55.h,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 28.w,
                                            child: Text(
                                              myCommunityRank,
                                              style: GoogleFonts.notoSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap:
                                                () => openCommunityIfMember(
                                                  myCommunityId,
                                                  communityName: myCommunityName,
                                                ),
                                            child: _buildListAvatar(
                                              myCommunityImage,
                                              name: myCommunityName,
                                              isCommunity: true,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap:
                                                  () => openCommunityIfMember(
                                                    myCommunityId,
                                                    communityName:
                                                        myCommunityName,
                                                  ),
                                              child: Text(
                                                myCommunityName ?? '—',
                                                style: GoogleFonts.notoSans(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          _buildPoints(myCommunityPoints),
                                        ],
                                      ),
                                    );
                                  }
                                }),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
              // Search overlay
              Obx(() {
                if (!controller.isSearching.value)
                  return const SizedBox.shrink();

                final isGlobal = controller.isGlobalTab.value;
                final query = controller.searchQuery.value.toLowerCase();

                if (isGlobal) {
                  final results =
                      controller.globalleaderboard
                          .where(
                            (u) =>
                                query.isEmpty ||
                                u.username.toLowerCase().contains(query) ||
                                u.fullName.toLowerCase().contains(query),
                          )
                          .toList();

                  return Positioned(
                    // Fill the area below the search field instead of floating a
                    // separate rounded card — search now reads as the list
                    // filtered in place, not a modal box over the podium.
                    top: 110.h,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      // Transparent so the screen's radial gradient shows behind
                      // the search results (podium is hidden in search mode).
                      color: Colors.transparent,
                      child: ClipRRect(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: results.length,
                          itemBuilder: (context, ind) {
                            final user = results[ind];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 5.h,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24.w,
                                    child: Text(
                                      "${user.rank}",
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openUserProfile(user.userId),
                                    child: _buildListAvatar(
                                      user.avatarUrl,
                                      name: user.username,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap:
                                          () => _openUserProfile(user.userId),
                                      child: Text(
                                        user.fullName,
                                        style: GoogleFonts.notoSans(
                                          fontSize: 15.sp,
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  _buildPoints(user.points),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                } else {
                  final results =
                      controller.leaderboard
                          .where(
                            (c) =>
                                query.isEmpty ||
                                c.name.toLowerCase().contains(query),
                          )
                          .toList();

                  return Positioned(
                    // Fill the area below the search field instead of floating a
                    // separate rounded card — search now reads as the list
                    // filtered in place, not a modal box over the podium.
                    top: 110.h,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      // Transparent so the screen's radial gradient shows behind
                      // the search results (podium is hidden in search mode).
                      color: Colors.transparent,
                      child: ClipRRect(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: results.length,
                          itemBuilder: (context, ind) {
                            final i = results[ind];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 5.h,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24.w,
                                    child: Text(
                                      "${ind + 1}",
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        () => openCommunityIfMember(
                                          i.communityId,
                                          communityName: i.name,
                                        ),
                                    child: _buildListAvatar(
                                      i.imageUrl,
                                      name: i.name,
                                      isCommunity: true,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap:
                                          () => openCommunityIfMember(
                                            i.communityId,
                                            communityName: i.name,
                                          ),
                                      child: Text(
                                        i.name,
                                        style: GoogleFonts.notoSans(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  _buildPoints(i.points),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Open a leaderboard user's profile. Tapping yourself goes to your own
  // profile; friends open the rich friends profile, everyone else the
  // non-private profile — mirrors the friend/non-friend split used elsewhere
  // (e.g. community member list).
  Future<void> _openUserProfile(int userId) async {
    if (userId == 0) return;

    final currentUserId = await UserPreference.getUserId();
    if (currentUserId == userId) {
      Get.toNamed(Routes.myProfile);
      return;
    }

    final friendListCtrl =
        Get.isRegistered<FriendListController>()
            ? Get.find<FriendListController>()
            : Get.put(FriendListController());

    final isFriend = friendListCtrl.friends1.any((f) => f.id == userId);

    Get.toNamed(
      isFriend ? Routes.friendsProfile : Routes.nonPrivateProfile,
      arguments: {'id': userId},
    );
  }

  Widget _buildPrizeBadge(int index, String prize) {
    return _AnimatedPrizeBadge(index: index);
  }

  Widget _buildPoints(int points) => Container(
    padding: EdgeInsets.only(left: 2.w, top: 1.5.h, bottom: 1.5.h, right: 6.w),
    decoration: BoxDecoration(
      border: Border.all(width: 1.0.sp, color: AppColors.yellow),
      borderRadius: BorderRadius.circular(16.sp),
      color: Colors.transparent,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset("assets/Images/skcoin.png", scale: 1.7),
        SizedBox(width: 5.w),
        Text(
          formatPoints(points),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ],
    ),
  );

  Widget buildPodiumItem(
    CommunityLeaderboard item, {
    required double topPadding,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                () => openCommunityIfMember(
                  item.communityId,
                  communityName: item.name,
                ),
            child: _buildPodiumAvatar(item.imageUrl, name: item.name),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            // width: 70.w,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  () => openCommunityIfMember(
                    item.communityId,
                    communityName: item.name,
                  ),
              child: Text(
                item.name,
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/Images/skmembere.png",
                scale: 2,
                color: AppColors.yellow,
              ),
              SizedBox(width: 2.w),
              Text(
                item.membersCount.toString(),
                style: GoogleFonts.notoSans(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          _buildPoints(item.points),
        ],
      ),
    );
  }

  Widget user(
    UserLeaderboard item, {
    double topPadding = 0,
    double leftPadding = 0,
    double rightPadding = 0,
  }) {
    final avatarSize = 58.w;
    final displayName = item.fullName;
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        left: leftPadding,
        right: rightPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openUserProfile(item.userId),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(avatarSize / 2),
              child:
                  (item.avatarUrl != null && (item.avatarUrl ?? '').isNotEmpty)
                      ? CachedNetworkImage(
                        alignment: Alignment.topCenter,
                        imageUrl: item.avatarUrl!,
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) =>
                                ShimmerPlaceholderCircle(size: avatarSize),
                        errorWidget:
                            (_, __, ___) => Container(
                              width: avatarSize,
                              height: avatarSize,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                          .trim()
                                          .characters
                                          .first
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: avatarSize / 2,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      )
                      : Container(
                        width: avatarSize,
                        height: avatarSize,
                        color: AppColors.backgroundColor,
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: avatarSize / 3,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
            ),
          ),
          SizedBox(height: 3.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openUserProfile(item.userId),
            child: Text(
              displayName,
              style: GoogleFonts.notoSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          _buildPoints(item.points),
        ],
      ),
    );
  }

  Widget CustomTextField({
    required String hintText,
    required Widget suffixIcon,
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Widget? prefixImage,
  }) {
    return TextFormField(
      autofocus: true,
      style: TextStyle(color: AppColors.white),
      onChanged: onChanged,
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.notoSans(
          color: AppColors.fillnoti,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon:
            prefixImage != null
                ? Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: prefixImage,
                )
                : null,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: const BorderSide(color: AppColors.fillnoti),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: const BorderSide(color: AppColors.fillnoti),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: const BorderSide(color: AppColors.fillnoti),
        ),
      ),
    );
  }

  // Placeholder shown when an avatar has no image (or fails to load).
  // Communities get a neutral people icon on a soft orange background instead
  // of a name-initial — a community isn't a person, so an initial reads oddly.
  // Users keep the existing name-initial look.
  Widget _avatarFallback({
    required double size,
    required bool isCommunity,
    required String initial,
    required bool isError,
  }) {
    if (isCommunity) {
      return Container(
        width: size,
        height: size,
        color: Colors.orangeAccent.withValues(alpha: 0.2),
        child: Icon(
          Icons.people_outline,
          color: Colors.orangeAccent,
          size: size / 2,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      color: isError ? Colors.grey.shade300 : AppColors.backgroundColor,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: isError ? size / 2 : size / 3,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumAvatar(String? url, {String? name}) {
    // Podium avatars are only rendered on the Communities tab.
    final size = 50.w;
    final hasUrl = (url != null && url.isNotEmpty);
    final initial =
        (name != null && name.isNotEmpty)
            ? name.trim().characters.first.toUpperCase()
            : '?';

    if (!hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: _avatarFallback(
          size: size,
          isCommunity: true,
          initial: initial,
          isError: false,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        alignment: Alignment.topCenter,
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerPlaceholderCircle(size: size),
        errorWidget:
            (_, __, ___) => _avatarFallback(
              size: size,
              isCommunity: true,
              initial: initial,
              isError: true,
            ),
      ),
    );
  }

  Widget _buildListAvatar(String? url, {String? name, bool isCommunity = false}) {
    final size = 42.w;
    final hasUrl = (url != null && url.isNotEmpty);
    final initial =
        (name != null && name.isNotEmpty)
            ? name.trim().characters.first.toUpperCase()
            : '?';

    if (!hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: _avatarFallback(
          size: size,
          isCommunity: isCommunity,
          initial: initial,
          isError: false,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        alignment: Alignment.topCenter,
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerPlaceholderCircle(size: size),
        errorWidget:
            (_, __, ___) => _avatarFallback(
              size: size,
              isCommunity: isCommunity,
              initial: initial,
              isError: true,
            ),
      ),
    );
  }

  Widget buildToggleTabs() {
    return Obx(() {
      final g = controller.global.value;
      final remaining = g?.window?.remaining ?? '';
      return Padding(
        padding: EdgeInsets.only(left: 17.w, right: 17.w, top: 10.h),
        child: Row(
          children: [
            buildTabButton('Global', controller.isGlobalTab.value, () {
              controller.toggleTab(true);
            }),
            const SizedBox(width: 10),
            buildTabButton('Communities', !controller.isGlobalTab.value, () {
              controller.toggleTab(false);
            }),
            const Spacer(),
            if (remaining.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    remaining,
                    style: GoogleFonts.notoSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget buildTabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        decoration: BoxDecoration(
          color:
              selected
                  ? const Color(0xffA855F7)
                  : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSans(
            color: AppColors.white,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  String formatPoints(int points) {
    if (points >= 1000) {
      double val = points / 1000.0;

      // ১. দুই ঘর পর্যন্ত দশমিক ফিক্স করা
      String result = val.toStringAsFixed(2);

      // ২. অপ্রয়োজনীয় শূন্য এবং দশমিক রিমুভ করা (RegExp দিয়ে)
      // উদাহরণ: 1.00 -> 1, 1.20 -> 1.2, 1.03 -> 1.03
      result = result.replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");

      return "${result}k";
    }
    return points.toString();
  }

  Widget _buildBottomBarShimmer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      height: 55.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28.w,
            child: ShimmerPlaceholder(width: 16.w, height: 16.h, radius: 4),
          ),
          SizedBox(width: 10.w),
          ShimmerPlaceholderCircle(size: 42.w),
          SizedBox(width: 10.w),
          Expanded(child: ShimmerPlaceholder(height: 14.h, radius: 4)),
          SizedBox(width: 12.w),
          ShimmerPlaceholder(width: 60.w, height: 24.h, radius: 16),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Container(
      height: 190.h,
      decoration: BoxDecoration(
        color: const Color(0xff2D0731),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.sp),
          topRight: Radius.circular(24.sp),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                ShimmerPlaceholder(width: 20.w, height: 16.h, radius: 4),
                SizedBox(width: 12.w),
                ShimmerPlaceholderCircle(size: 42.w),
                SizedBox(width: 12.w),
                Expanded(child: ShimmerPlaceholder(height: 14.h, radius: 4)),
                SizedBox(width: 12.w),
                ShimmerPlaceholder(width: 60.w, height: 24.h, radius: 16),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedPrizeBadge extends GetView<LeaderboaddglobalController> {
  final int index;
  const _AnimatedPrizeBadge({required this.index});

  static const _bgColors = [
    Color(0xFFF8AC00),
    Color(0xFF95A4A7),
    Color(0xFF8E3B09),
  ];
  static const _medals = ['🥇', '🥈', '🥉'];
  static const _amounts = ['\$500', '\$250', '\$100'];
  static const _shineColors = [
    Color(0xFFFFE082),
    Color(0xFFE0E0E0),
    Color(0xFFD4894A),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[index];
    final anim = controller.prizeShineController;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.only(
            left: 3.w,
            top: 1.h,
            bottom: 1.h,
            right: 6.w,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.sp),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 3.0 * anim.value, 0),
              end: Alignment(-0.5 + 3.0 * anim.value, 0),
              colors: [bg, _shineColors[index].withValues(alpha: 0.6), bg],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.4),
                blurRadius: 6.4,
                offset: const Offset(0, 2.4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 3.2,
                offset: const Offset(0, 0.8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medals[index], style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 2.w),
          Text(
            _amounts[index],
            style: GoogleFonts.notoSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
