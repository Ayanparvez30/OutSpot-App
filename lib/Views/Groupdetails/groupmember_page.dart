import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/groupmember_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Views/Groupdetails/group_edit_OptionsSheet.dart';
import 'package:outspot/Views/Groupdetails/groupdetails_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/Groups/groups_controller.dart';

class GroupMembersPage extends GetView<GroupdetailsController> {
  /// Open a member's profile, choosing the right screen up front so we never
  /// flash the friend profile before redirecting non-friends to the public one.
  void _openMemberProfile(FriendsModel member) async {
    final myId = await UserPreference.getUserId();
    if (myId != null && myId == member.id) {
      Get.toNamed(Routes.myProfile);
      return;
    }

    final flc =
        Get.isRegistered<FriendListController>()
            ? Get.find<FriendListController>()
            : Get.put(FriendListController());
    final isFriend = flc.friends1.any((f) => f.id == member.id);

    Get.toNamed(
      isFriend ? Routes.friendsProfile : Routes.nonPrivateProfile,
      arguments: member,
    );
  }

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
      child: WillPopScope(
        onWillPop: () async {
          Get.back();
          return false;
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: AppBar(
              automaticallyImplyLeading: false,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              leading: GestureDetector(
                onTap: () {
                  Get.back();
                  // if (Get.previousRoute.isNotEmpty) {
                  //   Get.back(); // পেজ থাকলে নরমালি ব্যাক করবে
                  // } else {
                  //   // ২. যদি স্ট্যাক খালি হয়ে যায়, তবে সরাসরি Group বা Main স্ক্রিনে চলে যাবে
                  //   Get.offAllNamed(Routes.group);
                  //   // 💡 (বিঃদ্রঃ আপনার মূল পেজ যদি Routes.mainscreen হয়, তবে সেটি দিবেন)
                  // }
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 5.w),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      "assets/svg/icons/close_icon.svg",
                      width: 20.w,
                      height: 20.w,
                    ),
                  ),
                ),
              ),
              actions: [
                /// Dots (menu) button
                Padding(
                  padding: EdgeInsets.only(right: 9.w),
                  child: GestureDetector(
                    // onTap: () {
                    //   showModalBottomSheetFunctionGroupOptions(context);
                    // },
                    onTap: () {
                      GroupeditOptionsSheet.show(
                        isGroup: true,
                        context: context,
                        groupId: controller.groupId.value,
                        groupName: controller.group.value,
                        isAdmin: controller.isAdmin,
                        isLocked: controller.isLocked,
                        isMuted: controller.isMuted,
                        onLockToggle:
                            () =>
                                controller.isLocked.value
                                    ? controller.unlockChat(
                                      controller.groupId.value,
                                    )
                                    : controller.lockChat(
                                      controller.groupId.value,
                                    ),
                        onMuteToggle:
                            () =>
                                controller.toggleMute(controller.groupId.value),
                        onLeave: () => controller.leaveGroup(),
                      );
                    },
                    child: SvgPicture.asset(
                      "assets/svg/3dot.svg",
                      width: 32.w,
                      height: 32.w,
                    ),
                  ),
                ),
              ],
              elevation: 0,
              title:
              /// Group name
              Center(
                child: Obx(
                  () => Text(
                    controller.group.value,
                    style: GoogleFonts.notoSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Members",
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingMembers.value) {
                      return ListView.builder(
                        itemCount: 8,
                        itemBuilder:
                            (_, index) => Column(
                              children: [
                                ListTile(
                                  leading: ShimmerPlaceholderCircle(size: 36.w),
                                  title: ShimmerPlaceholder(
                                    width: 120.w,
                                    height: 14.h,
                                    radius: 6.r,
                                  ),
                                  subtitle: Padding(
                                    padding: EdgeInsets.only(top: 6.h),
                                    child: Row(
                                      children: [
                                        ShimmerPlaceholderCircle(size: 14.w),
                                        SizedBox(width: 6.w),
                                        ShimmerPlaceholder(
                                          width: 40.w,
                                          height: 12.h,
                                          radius: 4.r,
                                        ),
                                        SizedBox(width: 14.w),
                                        ShimmerPlaceholderCircle(size: 14.w),
                                        SizedBox(width: 5.w),
                                        ShimmerPlaceholder(
                                          width: 40.w,
                                          height: 12.h,
                                          radius: 4.r,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (index < 7)
                                  Divider(
                                    indent: 16.w,
                                    color: AppColors.fillnoti,
                                    thickness: 2,
                                  ),
                              ],
                            ),
                      );
                    }

                    // Show all members: current user first with "You" label, then others
                    final sortedMembers = <dynamic>[];
                    final me = controller.groupUsers.firstWhereOrNull(
                      (user) => user.id == controller.Id.value,
                    );
                    if (me != null) sortedMembers.add(me);
                    sortedMembers.addAll(
                      controller.groupUsers.where(
                        (user) => user.id != controller.Id.value,
                      ),
                    );

                    // Client-side pagination — only show first N members
                    final visibleCount = controller.visibleMemberCount.value
                        .clamp(0, sortedMembers.length);
                    final otherMembers = sortedMembers.sublist(0, visibleCount);
                    final hasMore = visibleCount < sortedMembers.length;

                    // ২. যদি আপনি ছাড়া আর কেউ না থাকে
                    if (otherMembers.isEmpty) {
                      return Center(
                        child: Text(
                          "No members found",
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scroll) {
                        if (scroll.metrics.pixels >=
                                scroll.metrics.maxScrollExtent - 200 &&
                            hasMore) {
                          controller.loadMoreMembers();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: otherMembers.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= otherMembers.length) {
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
                          // final user = controller.groupUsers[index];
                          // final userPoints = user.points;
                          // final userThisWeekPoints = user.thisWeekPoints;
                          // final isLastItem =
                          //     index == controller.groupUsers.length - 1;
                          final user =
                              otherMembers[index]; // ৪. ফিল্টার করা লিস্ট থেকে ইউজার নেওয়া
                          final userPoints = user.points;
                          final userThisWeekPoints = user.thisWeekPoints;
                          final isLastItem = index == otherMembers.length - 1;
                          final bool isMe = user.id == controller.Id.value;

                          return GestureDetector(
                            onTap: () {
                              if (isMe) {
                                Get.toNamed(Routes.myProfile);
                                return;
                              }
                              // _showFriendDialog(
                              //   GroupMember(
                              //     id: user.id,
                              //     username: user.name,
                              //     firstName: user.firstName,
                              //     lastName: user.lastName,
                              //     name: user.name,
                              //     profileUrl: user.profileUrl,
                              //     role: user.role,
                              //     joinedAt: user.joinedAt,
                              //     avatar: user.avatar,
                              //     points: user.points,
                              //     thisWeekPoints: userThisWeekPoints,
                              //   ),
                              // );
                              final friendModel = FriendsModel(
                                id: user.id,
                                username: user.username,
                                firstName: user.firstName,
                                lastName: user.lastName,
                                avatarUrl: user.avatar ?? '',
                                totalPoints: user.points,
                                thisWeekPoints: user.thisWeekPoints,
                                profileUrl: user.profileUrl ?? '',
                              );

                              _openMemberProfile(friendModel);
                            },
                            child: Column(
                              children: [
                                ListTile(
                                  leading: _buildAvatar(user.avatar),
                                  trailing:
                                      user.role.toUpperCase() == 'ADMIN'
                                          ? Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xffFFB300,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color: const Color(0xffFFB300),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Admin',
                                              style: GoogleFonts.notoSans(
                                                color: const Color(0xffFFB300),
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                          : (controller.isAdmin.value && !isMe)
                                              ? IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () =>
                                                    _showRemoveMemberDialog(
                                                      context,
                                                      user.id,
                                                      isMe ? 'You' : user.name,
                                                    ),
                                              )
                                              : null,
                                  title: Text(
                                    isMe ? "You" : user.name,
                                    style: GoogleFonts.notoSans(
                                      color: AppColors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      SizedBox(height: 4.h),
                                      UnconstrainedBox(
                                        child: SvgPicture.asset(
                                          "assets/svg/bluepoint.svg",
                                          height: 14.w,
                                          width: 13.w,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '$userPoints',
                                        style: GoogleFonts.notoSans(
                                          color: AppColors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 7.w),
                                      Text(
                                        '|',
                                        style: GoogleFonts.notoSans(
                                          color: AppColors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 7.w),
                                      UnconstrainedBox(
                                        child: SvgPicture.asset(
                                          "assets/svg/Icon-Outline-Coin-P.svg",
                                          height: 14.w,
                                          width: 13.w,
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        "$userThisWeekPoints",
                                        style: GoogleFonts.notoSans(
                                          color: AppColors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLastItem)
                                  Divider(
                                    indent: 16.w,
                                    color: AppColors.fillnoti,
                                    thickness: 2,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),

                // Add Members button
                Obx(
                  () =>
                      controller.isAdmin.value
                          ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 20.h,
                            ),
                            child: GestureDetector(
                              onTap:
                                  () => Get.toNamed(
                                    Routes.addscreen,
                                    arguments: {
                                      "groupId": controller.groupId.value,
                                      "groupName": controller.group.value,
                                    },
                                  ),
                              child: Container(
                                width: double.infinity,
                                height: 44.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25.r),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.btnGradientLeft,
                                      AppColors.btnGradientRight,
                                    ],
                                  ),
                                ),

                                child: Text(
                                  'Add Members',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    int memberId,
    String memberName,
  ) {
    final controller = Get.find<GroupdetailsController>();
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xff2D0731),
          title: const Text(
            "Remove Member",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to remove $memberName from this group?",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await controller.removeMember(memberId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.white),
              ),
            ),
            // Ban is stronger than remove — the server blocks re-joining.
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await controller.banMember(memberId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffDD4141),
              ),
              child: const Text(
                "Ban",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _scoreColumn({
    required String icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            UnconstrainedBox(
              child: SvgPicture.asset(icon, height: 14.w, width: 13.w),
            ),
            SizedBox(width: 6.w),
            Text(
              value,
              style: GoogleFonts.notoSans(
                fontSize: 15.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roundIcon(String image, Color bg) => Container(
    padding: EdgeInsets.all(10.r),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: SvgPicture.asset(image),
  );

  void _showFriendDialog(GroupMember friend) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 26.sp,
                      color: AppColors.white,
                    ),
                    onPressed: Get.back,
                  ),
                ),

                _buildAvatars(friend.avatar),
                SizedBox(height: 15.h),

                /* name & username */
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      friend.name,
                      style: GoogleFonts.notoSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(width: 2.w),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  '@${friend.username}',
                  style: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),

                SizedBox(height: 8.h),
                Divider(color: AppColors.fillnoti),
                SizedBox(height: 15.h),

                /* scores */
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _scoreColumn(
                        title: 'Overall',
                        icon: "assets/svg/Icon-Outline-Coin-P.svg",
                        value: compactNumber(friend.points),
                      ),
                      Container(
                        width: 1,
                        height: 15.h,
                        color: AppColors.fillnoti,
                      ),
                      _scoreColumn(
                        title: 'This Week',
                        icon: "assets/svg/bluepoint.svg",
                        value: compactNumber(friend.thisWeekPoints),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                /* view profile button */
                Row(
                  children: [
                    SizedBox(
                      width: 140.w,
                      height: 45.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.skyblue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),

                        onPressed: () {
                          Get.back();
                          final friendModel = FriendsModel(
                            id: friend.id,
                            username: friend.username,
                            firstName: friend.firstName,
                            lastName: friend.lastName,
                            avatarUrl: friend.avatar ?? '',
                            totalPoints: friend.points,
                            thisWeekPoints: friend.thisWeekPoints,
                            profileUrl: friend.profileUrl ?? '',
                          );

                          _openMemberProfile(friendModel);
                        },

                        child: Text(
                          'View Profile',
                          style: GoogleFonts.notoSans(
                            fontSize: 14.sp,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 25.w),

                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.toNamed(
                          Routes.directMessageScreen,
                          arguments: {
                            "Id":
                                friend
                                    .id, // Use `.value` to access the Rx value
                          },
                        );
                      },
                      child: _roundIcon(
                        'assets/svg/icons/massegeIcon.svg',
                        AppColors.SecondaryColor,
                      ),
                    ),
                    SizedBox(width: 24.w),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.offAllNamed(
                          Routes.mainscreen,
                          arguments: {"tab": 2},
                        );
                      },
                      child: _roundIcon(
                        'assets/svg/icons/camera1.svg',
                        AppColors.yellow,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    final size = 36.w;
    final hasUrl = (url != null && url.isNotEmpty);
    if (!hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.person),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: CachedNetworkImage(
        alignment: Alignment.topCenter,
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerPlaceholderCircle(size: size),
        errorWidget:
            (_, __, ___) => SizedBox(
              width: size,
              height: size,
              child: const Icon(Icons.person),
            ),
      ),
    );
  }

  Widget _buildAvatars(String? url) {
    final size = 90.w;
    final hasUrl = (url != null && url.isNotEmpty);
    if (!hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.person),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: CachedNetworkImage(
        alignment: Alignment.topCenter,
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerPlaceholderCircle(size: size),
        errorWidget:
            (_, __, ___) => SizedBox(
              width: size,
              height: size,
              child: const Icon(Icons.person),
            ),
      ),
    );
  }

  void showModalBottomSheetFunctionGroupOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            left: 15.w,
            right: 15.w,
            bottom: 15.h,
          ), // space around the sheet
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent, width: 1.w),
            color: AppColors.black,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 0.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Group Options",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      color: AppColors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Divider(),

                /// Edit Group Details
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    " ${controller.isAdmin.value}";
                    // optional: prevent early taps while loading
                    if (controller.isLoadingMembers.value) {
                      AppSnackbar.info(
                        'Loading group info...',
                        title: 'Please wait',
                      );
                      return;
                    }

                    if (controller.isAdmin.value) {
                      Get.toNamed(
                        Routes.newGroupScreen,
                        arguments: {
                          "isedit": true,
                          "groupId": controller.groupId.value,
                          "groupName": controller.group.value,
                        },
                      );
                    } else {
                      AppSnackbar.info(
                        "You can't edit group",
                        title: "You are not admin",
                      );
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Center(
                      child: Text(
                        "Edit Group Details",
                        style: GoogleFonts.notoSans(
                          color: AppColors.backgroundColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Divider(),

                /// Lock Chat
                GestureDetector(
                  onTap: () {
                    Get.back();
                    log("${controller.groupId.value}");
                    controller.isLocked.value
                        ? controller.unlockChat(controller.groupId.value)
                        : controller.lockChat(controller.groupId.value);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Center(
                      child: Obx(
                        () => Text(
                          controller.isLocked.value
                              ? "Unlock Chat"
                              : "Lock Chat",
                          style: GoogleFonts.notoSans(
                            color: AppColors.backgroundColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Divider(),

                /// Mute Chat
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        controller.toggleMute(controller.groupId.value);
                      },
                      child: Obx(
                        () => Text(
                          controller.isMuted.value
                              ? "Unmute Chat"
                              : "Mute Chat",
                          style: GoogleFonts.notoSans(
                            color: AppColors.backgroundColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Divider(),

                /// Leave Group
                GestureDetector(
                  onTap: () {
                    Get.back();

                    controller.leaveGroup();
                    // Leave Group logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Center(
                      child: Text(
                        "Leave Group",
                        style: GoogleFonts.notoSans(
                          color: AppColors.darkred,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
