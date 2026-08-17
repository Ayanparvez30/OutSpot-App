import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/No%20Community/allCommunities.dart';
import 'package:outspot/Views/No%20Community/bannedUsers.dart';
import 'package:outspot/Views/No%20Community/editCommunityPage.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';
import 'package:outspot/Views/No%20Community/searchCommunity.dart';

class MembersPage extends GetView<NocommunityController> {
  final int communityId;

  MembersPage({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    Get.put(MyProfileController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchCommunityDetails(communityId);
    });

    return Container(
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Obx(
            () => Text(
              controller.communityName.value.isEmpty
                  ? "Community"
                  : controller.communityName.value,
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () {
              // Get.to(SearchCommunity());
              Get.back();
            },
            child: Padding(
              padding: EdgeInsets.only(left: 10.w, top: 15.h, bottom: 10),
              child: SvgPicture.asset(
                'assets/svg/icons/Cross.svg',
                color: Colors.white,
                height: 10,
                width: 10,
              ),
            ),
          ),
          actions: [
            Obx(() {
              final bool isOwner = controller.isUserCreator(communityId);
              final bool isMember = controller.isUserMember(communityId);

              // ❌ Not joined & not owner => hide
              if (!isOwner && !isMember) {
                return const SizedBox.shrink();
              }

              // ✅ Owner or Member => show menu button
              return GestureDetector(
                onTap: () {
                  showCommunityOptionsBottomSheet(
                    context,
                    isOwner: isOwner,
                    onEdit: () {
                      Get.back();
                      Get.to(
                        () => Editcommunitypage(),
                        arguments: {"communityId": communityId},
                      );
                    },
                    onDelete: () async {
                      Get.back();
                      showDeleteDialog(communityId);
                    },
                    onLeave: () async {
                      Get.back();
                      showLeaveDialog(communityId);
                    },
                  );
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
              );
            }),
            SizedBox(width: 8.w),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Community bio — styled container, hidden when empty.
              Obx(() {
                final bio = controller.communityBio.value.trim();
                if (bio.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 14.h),
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
              Obx(
                () => Text(
                  "Members (${controller.membersList.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              /// Members List
              Expanded(
                child: Obx(() {
                  if (controller.membersList.isEmpty) {
                    return const Center(
                      child: Text(
                        "No members yet",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: controller.membersList.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          color: AppColors.bgGradientTop,
                          thickness: 1,
                        ),
                    itemBuilder: (context, index) {
                      final member = controller.membersList[index];

                      final String fullName =
                          "${member['firstName'] ?? ''} ${member['lastName'] ?? ''}"
                                  .trim()
                                  .isEmpty
                              ? (member['username'] ?? "Unknown")
                              : "${member['firstName'] ?? ''} ${member['lastName'] ?? ''}";

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () {
                          // Creator-only: long-press a member to ban (not self).
                          final memberId =
                              int.tryParse('${member['id']}') ?? 0;
                          final isSelf =
                              '${member['id']}' ==
                              controller.currentUserId.value;
                          if (controller.isUserCreator(communityId) &&
                              !isSelf &&
                              memberId > 0) {
                            _showBanDialog(context, memberId, fullName);
                          }
                        },
                        child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child:
                                  (member['avatarUrl'] != null &&
                                          (member['avatarUrl'] as String)
                                              .isNotEmpty)
                                      ? CachedNetworkImage(
                                        imageUrl: member['avatarUrl'],
                                        width: 70.w,
                                        height: 40.h,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        placeholder:
                                            (context, url) =>
                                                ShimmerPlaceholder(
                                                  width: 70.w,
                                                  height: 40.h,
                                                ),
                                      )
                                      : Container(
                                        width: 48.w,
                                        height: 48.h,
                                        color: AppColors.MainColor,
                                        child: Icon(
                                          Icons.person,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),

                            SizedBox(width: 12.w),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fullName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16.sp,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      if (member['isAdmin'] == true) ...[
                                        SizedBox(width: 6.w),
                                        Material(
                                          elevation: 3,
                                          shadowColor: Colors.orange
                                              .withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),

                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.shade400,
                                                  Colors.orange.shade700,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),

                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.admin_panel_settings,
                                                  color: Colors.white,
                                                  size: 12.sp,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  "ADMIN",
                                                  style: TextStyle(
                                                    fontSize: 10.sp,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  SizedBox(height: 4.h),

                                  /// 🔥 Points Row
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/svg/level/coinshape1.svg",
                                        height: 14.h,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        compactNumber(member['totalPoints'] ?? 0),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Container(
                                        height: 10.h,
                                        width: 1.5.w,
                                        color: AppColors.bgGradientTop,
                                      ),
                                      SizedBox(width: 8.w),
                                      SvgPicture.asset(
                                        "assets/svg/level/coinshape2.svg",
                                        height: 14.h,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        compactNumber(member['thisWeekPoints'] ?? 0),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Admin/creator-only: clear Ban button per member
                            // (not on yourself). More discoverable than long-press.
                            if (controller.isUserCreator(communityId) &&
                                '${member['id']}' !=
                                    controller.currentUserId.value)
                              IconButton(
                                tooltip: 'Ban from community',
                                onPressed: () {
                                  final memberId =
                                      int.tryParse('${member['id']}') ?? 0;
                                  if (memberId > 0) {
                                    _showBanDialog(
                                      context,
                                      memberId,
                                      fullName,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.block,
                                  color: Color(0xffDD4141),
                                ),
                              ),
                          ],
                        ),
                        ),
                      );
                    },
                  );
                }),
              ),

              Obx(() {
                final bool isCreator = controller.isUserCreator(communityId);
                final bool isMember = controller.isUserMember(communityId);

                // Hide join button if creator or already member
                if (isCreator || isMember) {
                  return const SizedBox.shrink();
                }

                // Show join button
                return Padding(
                  padding: EdgeInsets.all(15.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero, // important
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      onPressed: () async {
                        await controller.joinCommunity(communityId);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.MainColor,
                              AppColors.btnGradientLeft,
                              AppColors.btnGradientRight,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Join Community",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void showCommunityOptionsBottomSheet(
    BuildContext context, {
    required bool isOwner, // 👈 owner check
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onLeave,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: Color(0xff323434),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Community Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(color: Colors.black),

                if (isOwner) ...[
                  GestureDetector(
                    onTap: () {
                      Get.back();

                      Get.to(
                        () => Editcommunitypage(),
                        arguments: {"communityId": communityId},
                      );
                    },

                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Center(
                        child: Text(
                          "Edit Details",
                          style: TextStyle(
                            color: Color(0xffC574F7),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Colors.black),

                  GestureDetector(
                    onTap: () {
                      Get.back();
                      Get.to(
                        () => BannedUsersScreen(communityId: communityId),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Center(
                        child: Text(
                          "Banned Users",
                          style: TextStyle(
                            color: Color(0xffC574F7),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Colors.black),

                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Center(
                        child: Text(
                          "Delete Community",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: onLeave,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Center(
                        child: Text(
                          "Leave Community",
                          style: TextStyle(
                            color: Color(0xffDD4141),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Creator-only: confirm + ban a member from this community.
  void _showBanDialog(BuildContext context, int memberId, String memberName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xff2D0731),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text(
            "Ban member",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Ban $memberName from this community? They'll be removed and won't be able to re-join.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                controller.banMember(communityId, memberId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffDD4141),
              ),
              child: const Text("Ban", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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

  void showLeaveDialog(int communityId) {
    // Compute these inside the function
    final bool isOwner = controller.isUserCreator(communityId);
    final bool isMember = controller.isUserMember(communityId);

    Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: "Leave Community?",
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
                  "Leave Community?",
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
                  "You will no longer be a member of this community or see its posts.",
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
                    // Close dialog first
                    Get.back();

                    if (isMember && !isOwner) {
                      await controller.leaveCommunityFunc(communityId);
                    }

                    // Instant remove from local lists
                    controller.communities.removeWhere(
                      (c) => c["id"] == communityId,
                    );
                    controller.filteredCommunities.removeWhere(
                      (c) => c["id"] == communityId,
                    );

                    // Navigate to SearchCommunity screen
                    // Get.offAll(() => const SearchCommunity());
                    // Get.to(() => const SearchCommunity());
                    Get.back();
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
                      "Leave Community",
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
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
