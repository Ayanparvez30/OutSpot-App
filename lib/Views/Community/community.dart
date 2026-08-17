import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Shimmer প্যাকেজ ইমপোর্ট নিশ্চিত করুন
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Community/community_controller.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Views/No%20Community/editCommunityPage.dart';
import 'package:outspot/Views/No%20Community/searchCommunity.dart';

class CommunityScreen extends GetView<CommunityController> {
  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>;
    final int communityId = arguments["id"];

    if (!controller.isLoaded.value) {
      controller.fetchCommunityDetails(communityId);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: const [0, 0.3],
          radius: 1.5,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Obx(
            () =>
                controller.isLoading.value
                    ? _buildTextShimmer(100.w)
                    : Text(
                      controller.communityName.value,
                      style: GoogleFonts.notoSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
          ),
          centerTitle: true,
          leading: Container(
            padding: EdgeInsets.all(7),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/svg/icons/back_icon.svg',

                color: Colors.white,
              ),
              onPressed: () => Get.back(),
            ),
          ),
          actions: [
            Obx(() {
              if (controller.isLoading.value) return const SizedBox.shrink();
              if (!controller.hasJoined.value && !controller.isCreator.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(right: 20.w),
                child: GestureDetector(
                  onTap: () {
                    if (controller.isCreator.value) {
                      showCommunityOptionsBottomSheet(
                        context,
                        onEdit: () {
                          Get.back();
                          Get.to(
                            () => Editcommunitypage(),
                            arguments: {"communityId": communityId},
                          );
                        },
                        onDelete: () {
                          Get.back();
                          showDeleteDialog(communityId);
                        },
                      );
                    } else {
                      _showLeaveSheet(context, communityId);
                    }
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
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerEffect();
          }
          return Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Community Info Card
                Row(
                  children: [
                    _buildCommunityCard(
                      controller.communityName.value,
                      controller.communityImage.value,
                    ),
                    SizedBox(width: 15.w),
                    Column(
                      children: [
                        Container(
                          height: 30.h,
                          width: 140.w,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: AppColors.PrimaryColor,
                            border: Border.all(
                              width: 0.5,
                              color: AppColors.BorderColor,
                            ),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Members",
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              SvgPicture.asset(
                                "assets/svg/icons/friends1.svg",
                                height: 10.h,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                "${controller.membersList.length}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: 140.w,
                          child: TextField(
                            onChanged:
                                (value) => controller.filterMembers(value),
                            decoration: InputDecoration(
                              hintText: "Search...",
                              hintStyle: TextStyle(
                                color: AppColors.fillnoti,
                                fontSize: 12.sp,
                              ),
                              suffixIcon: Padding(
                                padding: EdgeInsets.all(10.r),
                                child: SvgPicture.asset(
                                  'assets/svg/icons/searchImage.svg',
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.r),
                                borderSide: BorderSide(
                                  color: AppColors.fillnoti,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.r),
                                borderSide: BorderSide(
                                  color: AppColors.fillnoti,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                /// Community bio — styled to match the cards above. Hidden when
                /// empty.
                Obx(() {
                  final bio = controller.communityBio.value.trim();
                  if (bio.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 14.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.BorderColor),
                      borderRadius: BorderRadius.circular(15.r),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "About",
                          style: GoogleFonts.firaSans(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          bio,
                          style: GoogleFonts.notoSans(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 20.h),

                /// Members List
                Expanded(
                  child: () {
                    final membersToShow =
                        controller.searchQuery.value.isEmpty
                            ? controller.membersList
                            : controller.filteredMembers;

                    if (membersToShow.isEmpty) {
                      return const Center(
                        child: Text(
                          "No members found",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: membersToShow.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            thickness: 0.5,
                            color: AppColors.bgGradientTop,
                          ),
                      itemBuilder: (context, index) {
                        final member = membersToShow[index];
                        final bool isAdmin =
                            member['id'] == controller.creatorId.value;

                        return ListTile(
                          onTap: () async {
                            final currentUserId =
                                await UserPreference.getUserId();

                            if (currentUserId == member['id']) {
                              Get.toNamed(Routes.myProfile);
                              return;
                            }

                            final friendListCtrl =
                                Get.isRegistered<FriendListController>()
                                    ? Get.find<FriendListController>()
                                    : Get.put(FriendListController());

                            final isFriend = friendListCtrl.friends1.any(
                              (f) => f.id == member['id'],
                            );

                            if (isFriend) {
                              Get.toNamed(
                                Routes.friendsProfile,
                                arguments: {'id': member['id']},
                              );
                            } else {
                              Get.toNamed(
                                Routes.nonPrivateProfile,
                                arguments: {'id': member['id']},
                              );
                            }
                          },
                          leading: ClipOval(
                            child:
                                (member['avatarUrl'] != null &&
                                        member['avatarUrl'].isNotEmpty)
                                    ? CachedNetworkImage(
                                      imageUrl: member['avatarUrl'],
                                      width: 50.w,
                                      height: 35.h,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      placeholder:
                                          (context, url) => ShimmerPlaceholder(
                                            width: 50.w,
                                            height: 35.h,
                                          ),
                                    )
                                    : Container(
                                      width: 50.w,
                                      height: 35.h,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        size: 20,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                "${member['firstName']} ${member['lastName'] ?? ''}",
                                style: GoogleFonts.notoSans(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (isAdmin) ...[
                                const Spacer(),
                                _buildAdminBadge(),
                              ],
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              SvgPicture.asset(
                                "assets/svg/level/coinshape1.svg",
                                height: 12.h,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                compactNumber(member['totalPoints'] ?? 0),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                height: 10.h,
                                width: 1.w,
                                color: AppColors.MainColor,
                              ),
                              SizedBox(width: 12.w),
                              SvgPicture.asset(
                                "assets/svg/level/coinshape2.svg",
                                height: 12.h,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                compactNumber(member['thisWeekPoints'] ?? 0),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                          trailing:
                              (controller.isCreator.value && !isAdmin)
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      _showRemoveMemberDialog(
                                        context,
                                        member['id'],
                                        "${member['firstName']} ${member['lastName'] ?? ''}",
                                        communityId,
                                      );
                                    },
                                  )
                                  : null,
                        );
                      },
                    );
                  }(),
                ),

                Obx(() {
                  if (controller.hasJoined.value ||
                      controller.isCreator.value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 10.w,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed(
                              Routes.directMessageScreen,
                              arguments: {"communityId": communityId},
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff42D880),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "Chat with Community",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 10.w,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.userHasExistingCommunity.value) {
                              _showAlreadyJoinedSnackbar();
                            } else {
                              await controller.joinCommunity(communityId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff704EF9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: Text(
                            "Join This Community",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Shimmer Effect for Loading State
  Widget _buildShimmerEffect() {
    return Padding(
      padding: EdgeInsets.all(10.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRectangleShimmer(175.w, 75.h, 15.r),
              SizedBox(width: 15.w),
              Column(
                children: [
                  _buildRectangleShimmer(140.w, 30.h, 25.r),
                  SizedBox(height: 8.h),
                  _buildRectangleShimmer(140.w, 35.h, 25.r),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: ListView.separated(
              itemCount: 8,
              separatorBuilder:
                  (_, __) => Divider(thickness: 0.5, color: Colors.white10),
              itemBuilder:
                  (_, __) => ListTile(
                    leading: Shimmer.fromColors(
                      baseColor: Colors.white10,
                      highlightColor: Colors.white24,
                      child: Container(
                        width: 45.w,
                        height: 45.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    title: _buildTextShimmer(120.w),
                    subtitle: _buildTextShimmer(80.w),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRectangleShimmer(double w, double h, double r) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      ),
    );
  }

  Widget _buildTextShimmer(double w) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        width: w,
        height: 12.h,
        // color: Colors.white,
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xff704EF9).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xff704EF9), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            size: 10.sp,
            color: const Color(0xff704EF9),
          ),
          SizedBox(width: 4.w),
          Text(
            "ADMIN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAlreadyJoinedSnackbar() {
    Get.snackbar(
      "Action Required",
      "You are already a member of a community. Please leave your current community first.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xff2D0731),
      colorText: Colors.white,
      margin: EdgeInsets.all(15.r),
      borderRadius: 15.r,
      icon: const Icon(Icons.info_outline, color: Color(0xff704EF9)),
      duration: const Duration(seconds: 3),
    );
  }

  Widget _buildCommunityCard(String communityName, String? imageUrl) {
    return Container(
      height: 75.h,
      width: 175.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.BorderColor),
        borderRadius: BorderRadius.circular(15.r),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Community",
            style: GoogleFonts.firaSans(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                backgroundImage:
                    (imageUrl != null && imageUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(imageUrl)
                        : null,
                // No admin-set community icon → same placeholder as the profile
                // "community" stat (people icon), not the CYNY avatar.
                child:
                    (imageUrl == null || imageUrl.isEmpty)
                        ? Icon(
                          Icons.people_outline,
                          color: Colors.orangeAccent,
                          size: 18.r,
                        )
                        : null,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  communityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Bottom Sheets & Dialogs (Keep existing implementations) ---
  void showCommunityOptionsBottomSheet(
    BuildContext context, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            margin: EdgeInsets.all(15.r),
            decoration: BoxDecoration(
              color: const Color(0xff323434),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const Text(
                    "Options",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.black),
                ListTile(
                  title: const Center(
                    child: Text(
                      "Edit Details",
                      style: TextStyle(color: AppColors.bgGradientTop),
                    ),
                  ),
                  onTap: onEdit,
                ),
                const Divider(color: Colors.black),
                ListTile(
                  title: const Center(
                    child: Text(
                      "Delete Community",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  onTap: onDelete,
                ),
              ],
            ),
          ),
    );
  }

  void showDeleteDialog(int communityId) {
    Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: "Delete Community?",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.5),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Color(0xff2D0731),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 15.h),
                Text(
                  "Delete Community?",
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 14.h),
                Text(
                  "If you delete this community it will disband and lose all members.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 25.h),

                GestureDetector(
                  onTap: () async {
                    // close the dialog first
                    await controller.deleteCommunity(communityId);

                    // Instant remove from local lists
                    controller.communities.removeWhere(
                      (c) => c["id"] == communityId,
                    );
                    controller.filteredCommunities.removeWhere(
                      (c) => c["id"] == communityId,
                    );

                    // Navigate to SearchCommunity screen
                    Get.offAll(() => const SearchCommunity());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xFFDD4141),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      "Delete Community",
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 16.sp,
                        color: Color(0xffFFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 5.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Nevermind',
                    style: GoogleFonts.notoSans(
                      color: Color(0xff704EF9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // from right
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _showLeaveSheet(BuildContext context, int communityId) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: const Color(0xff323434),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Community Options",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.black54),
                ListTile(
                  title: Center(
                    child: Text(
                      "Leave Community",
                      style: TextStyle(
                        color: const Color(0xffDD4141),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  onTap: () {
                    Get.back();

                    controller.leaveCommunityFunc(communityId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    int memberId,
    String memberName,
    int communityId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff2D0731),
          title: const Text(
            "Remove Member",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to remove $memberName from this community?",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.removeMember(memberId, communityId);
                controller.fetchCommunityDetails(communityId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
