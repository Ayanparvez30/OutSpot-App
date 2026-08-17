import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/No%20Community/noCommunity.dart';
import 'package:shimmer/shimmer.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';
import 'package:intl/intl.dart';

class Allcommunities extends GetView<NocommunityController> {
  Allcommunities({super.key});

  final RxString searchQuery = ''.obs;
  final RxString filterAction = 'all'.obs;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NocommunityController>()) {
      Get.put(NocommunityController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMyCommunities();
      controller.getMyCommunities();
    });

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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              "assets/svg/icons/back_icon.svg",
              width: 25.r,
              height: 25.r,
            ),

            padding: EdgeInsets.all(8.w),
            constraints: const BoxConstraints(),
            // onPressed: () => Get.back(),
            onPressed: () {
              Get.to(
                () => const Nocommunity(),
                transition: Transition.fadeIn,
                duration: 200.milliseconds,
              );
            },
          ),
          title: Text(
            "My Communities",
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => searchQuery.value = value,
                cursorColor: AppColors.white,
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ...',
                  hintStyle: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputBorderColor,
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/svg/icons/searchImage.svg',
                      height: 16.h,
                      width: 16.w,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
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
              Expanded(
                child: Obx(() {
                  // Show shimmer until history endpoint has loaded at least once
                  if (!controller.historyLoaded.value ||
                      (controller.historyLoading.value &&
                          controller.communityHistory.isEmpty)) {
                    return _buildShimmerEffect();
                  }

                  final query = searchQuery.value.toLowerCase().trim();
                  final allHistory = controller.communityHistory.toList();

                  // Dedupe by communityId — keep only the most recent entry per community
                  // (show each community once regardless of join/leave history)
                  final seen = <int>{};
                  final dedupedList = <Map<String, dynamic>>[];
                  for (final item in allHistory) {
                    final cid = item['communityId'] ?? 0;
                    if (!seen.contains(cid)) {
                      seen.add(cid);
                      dedupedList.add(item);
                    }
                  }

                  // Track which communities were left/deleted (for "Currently joined" badge)
                  final leftIds = <int>{};
                  for (final item in allHistory) {
                    final action = item['action'] ?? '';
                    final cid = item['communityId'] ?? 0;
                    if (action == 'left' || action == 'deleted') {
                      leftIds.add(cid);
                    }
                  }
                  // But if the user re-joined after leaving, they're NOT left
                  for (final item in allHistory) {
                    final action = item['action'] ?? '';
                    final cid = item['communityId'] ?? 0;
                    if ((action == 'joined' || action == 'created') &&
                        leftIds.contains(cid)) {
                      // Check if this join came AFTER the last left
                      // Since list is sorted newest-first, if we encounter join before left, it's active
                      leftIds.remove(cid);
                      break;
                    }
                  }

                  // Apply search filter
                  final filtered =
                      query.isEmpty
                          ? dedupedList
                          : dedupedList.where((item) {
                            final name =
                                (item['communityName'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            return name.contains(query);
                          }).toList();

                  // Apply pagination
                  final visibleCount = controller.visibleHistoryCount.value
                      .clamp(0, filtered.length);
                  final historyItems = filtered.sublist(0, visibleCount);
                  final hasMore = visibleCount < filtered.length;

                  if (historyItems.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? "No community activity yet"
                            : "No matching communities",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    );
                  }

                  // Find the most recent community the user is still part of
                  int? currentCommunityId;
                  for (final item in historyItems) {
                    final action = item['action'] ?? '';
                    final cid = item['communityId'] ?? 0;
                    if ((action == 'joined' || action == 'created') &&
                        !leftIds.contains(cid)) {
                      currentCommunityId = cid;
                      break;
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await controller.getMyCommunities();
                    },
                    color: const Color(0xffB190FF),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scroll) {
                        if (scroll.metrics.pixels >=
                                scroll.metrics.maxScrollExtent - 200 &&
                            hasMore) {
                          controller.loadMoreHistory();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: historyItems.length + (hasMore ? 1 : 0),
                        separatorBuilder:
                            (context, index) => Divider(
                              color: Colors.white.withOpacity(0.1),
                              thickness: 1,
                              // indent: 20.w,
                              // endIndent: 20.w,
                              height: 1,
                            ),
                        itemBuilder: (context, index) {
                          // Load-more indicator at the bottom
                          if (index >= historyItems.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
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
                          final item = historyItems[index];
                          final String name =
                              item['communityName'] ?? 'Unknown';
                          final String? imageUrl = item['communityImage'];
                          final String action = item['action'] ?? '';
                          final int communityId = item['communityId'] ?? 0;
                          final String dateStr = item['date'] ?? '';

                          String formattedDate = '';
                          if (dateStr.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(dateStr);
                              formattedDate = DateFormat(
                                'MMM d, yyyy • h:mm a',
                              ).format(dt);
                            } catch (_) {}
                          }

                          // Fetch member count on-demand (cached in controller)
                          if (!controller.memberCounts.containsKey(
                            communityId,
                          )) {
                            controller.fetchMemberCount(communityId);
                          }
                          final int membersCount =
                              controller.memberCounts[communityId] ?? 0;
                          final bool isCurrent =
                              communityId == currentCommunityId;
                          final bool wasLeft = leftIds.contains(communityId);

                          String subtitleText = '';
                          if (isCurrent) {
                            subtitleText = 'Currently joined';
                          } else if (dateStr.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(dateStr);
                              final monthYear = DateFormat(
                                'MMMM yyyy',
                              ).format(dt);
                              if (wasLeft) {
                                subtitleText = 'Left $monthYear';
                              } else {
                                subtitleText =
                                    '${action == 'created' ? 'Created' : 'Joined'} $monthYear';
                              }
                            } catch (_) {
                              subtitleText =
                                  wasLeft
                                      ? 'Left'
                                      : (action == 'created'
                                          ? 'Created'
                                          : 'Joined');
                            }
                          }
                          // unused — silence warning
                          // ignore: unused_local_variable
                          final _fd = formattedDate;

                          return ListTile(
                            onTap:
                                () => Get.toNamed(
                                  Routes.community,
                                  arguments: {"id": communityId},
                                ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 0.w,
                              vertical: 4.h,
                            ),
                            leading: Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xff0047BA),
                              ),
                              child: ClipOval(
                                child:
                                    (imageUrl != null && imageUrl.isNotEmpty)
                                        ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) =>
                                                  _buildImageShimmer(),
                                          errorWidget:
                                              (context, url, error) =>
                                                  _buildPlaceholder(name),
                                        )
                                        : _buildPlaceholder(name),
                              ),
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: TextStyle(
                                color:
                                    isCurrent
                                        ? const Color(0xffC574F7)
                                        : Colors.white54,
                                fontSize: 12.sp,
                                fontWeight:
                                    isCurrent
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                            // trailing: Row(
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: [
                            //     SvgPicture.asset(
                            //       'assets/svg/icons/friends1.svg',
                            //       width: 14.sp,
                            //       color: const Color(0xffC574F7),
                            //     ),
                            //     SizedBox(width: 6.w),
                            //     Text(
                            //       "$membersCount",
                            //       style: TextStyle(
                            //         color: Colors.white,
                            //         fontSize: 14.sp,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //     ),
                            //   ],
                            // ),
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
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
    );
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 6,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                CircleAvatar(radius: 25.r, backgroundColor: Colors.white),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120.w,
                        height: 14.h,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8.h),
                      Container(width: 80.w, height: 10.h, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 40.w, height: 14.h, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
