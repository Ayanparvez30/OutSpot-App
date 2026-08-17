import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/NewChat/new_chat_controller.dart';

class NewChatScreen extends GetView<NewChatController> {
  const NewChatScreen({super.key});

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
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {},
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Get.back();
              },
              icon: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 25.r,
                height: 25.r,
              ),
              padding: EdgeInsets.all(8.w),
              constraints: const BoxConstraints(),
            ),
            title: Text(
              "New Chat",
              style: GoogleFonts.notoSans(
                color: AppColors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          style: GoogleFonts.notoSans(color: AppColors.white),
                          onChanged: (value) => controller.query.value = value,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                            hintText: "Search friends or groups...",
                            hintStyle: GoogleFonts.notoSans(
                              color: AppColors.fillnoti,
                            ),
                            suffixIcon: Icon(
                              Icons.search,
                              color: AppColors.white,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: BorderSide(color: AppColors.fillnoti),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: BorderSide(color: AppColors.fillnoti),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: BorderSide(color: AppColors.fillnoti),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // New Group button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () {
                      controller.searchController.clear();
                      controller.query.value = "";
                      FocusManager.instance.primaryFocus?.unfocus();
                      Get.toNamed(Routes.newGroupScreen);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.circlegradient,
                            AppColors.circlegradient1,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_add,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "New Group",
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Scrollable content: Groups + Friends
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return ListView.builder(
                        itemCount: 8,
                        itemBuilder:
                            (_, __) => Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Row(
                                children: [
                                  ShimmerPlaceholder(width: 44.w, height: 44.w),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ShimmerPlaceholder(
                                          width: 120.w,
                                          height: 14.h,
                                        ),
                                        SizedBox(height: 4.h),
                                        ShimmerPlaceholder(
                                          width: 80.w,
                                          height: 12.h,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      );
                    }

                    final allGroups = controller.filteredGroups;
                    final allFriends = controller.filteredFriends;
                    final groups = controller.visibleGroups;
                    final friends = controller.visibleFriends;
                    final hasMoreFriends = controller.hasMoreFriends;
                    final hasMoreGroups = allGroups.length > groups.length;

                    if (allGroups.isEmpty && allFriends.isEmpty) {
                      return Center(
                        child: Text(
                          controller.query.value.isEmpty
                              ? "No friends yet"
                              : "No results found",
                          style: GoogleFonts.notoSans(
                            color: AppColors.readUnread,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (scroll) {
                        if (scroll.metrics.pixels >=
                                scroll.metrics.maxScrollExtent - 200 &&
                            hasMoreFriends) {
                          controller.loadMoreFriends();
                        }
                        return false;
                      },
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Groups section
                          if (groups.isNotEmpty) ...[
                            _sectionHeader("Groups", count: allGroups.length),
                            ...groups.map((group) => _groupTile(group)),
                            if (hasMoreGroups)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: controller.toggleShowAllGroups,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xff704EF9,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xff704EF9),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'See All (${allGroups.length})',
                                        style: GoogleFonts.notoSans(
                                          color: const Color(0xff704EF9),
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 8.h),
                            Divider(
                              indent: 16.w,
                              endIndent: 16.w,
                              height: 0.5,
                              color: AppColors.fillnoti,
                            ),
                            SizedBox(height: 8.h),
                          ],

                          // Friends section
                          if (friends.isNotEmpty) ...[
                            _sectionHeader("Friends", count: allFriends.length),
                            ...friends.asMap().entries.map((entry) {
                              final index = entry.key;
                              final friend = entry.value;
                              return Column(
                                children: [
                                  _friendTile(friend),
                                  if (index != friends.length - 1)
                                    Divider(
                                      indent: 72.w,
                                      height: 0.5,
                                      color: AppColors.fillnoti,
                                    ),
                                ],
                              );
                            }),
                            if (hasMoreFriends)
                              Padding(
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
                              ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {int? count}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: AppColors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.bgGradientTop,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.notoSans(
                  color: AppColors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupTile(ChatModel group) {
    final hasImage = group.imageUrl != null && group.imageUrl!.isNotEmpty;
    final memberCount = group.users.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          // Group avatar
          GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Get.toNamed(
                Routes.groupMembersPage,
                arguments: {'groupId': group.id},
              );
            },
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.circlegradient, AppColors.circlegradient1],
                ),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child:
                    hasImage
                        ? CachedNetworkImage(
                          imageUrl: group.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerPlaceholder(),
                          errorWidget:
                              (_, __, ___) => Icon(
                                Icons.group,
                                color: AppColors.white,
                                size: 22.sp,
                              ),
                        )
                        : Center(
                          child: Icon(
                            Icons.group,
                            color: AppColors.white,
                            size: 22.sp,
                          ),
                        ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Group name + member count
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Get.toNamed(
                  Routes.directMessageScreen,
                  arguments: {
                    "username": group.name ?? "Group",
                    "groupId": group.id,
                    "Id": null,
                    "existingChatId": group.id,
                  },
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name ?? "Group",
                          style: GoogleFonts.notoSans(
                            color: AppColors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "$memberCount member${memberCount != 1 ? 's' : ''}",
                          style: GoogleFonts.notoSans(
                            color: AppColors.readUnread,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.fillnoti,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendTile(FriendsModel friend) {
    final hasAvatar = friend.avatarUrl.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        int? existingChatId;
        if (Get.isRegistered<MessagesScreenController>()) {
          final msgCtrl = Get.find<MessagesScreenController>();
          final myId = msgCtrl.currentUserId.value;
          for (final chat in msgCtrl.chatss) {
            if (chat.isGroup || chat.isCommunity) continue;
            final hasMe = chat.users.any((u) => u.id == myId);
            final hasFriend = chat.users.any((u) => u.id == friend.id);
            if (hasMe && hasFriend) {
              existingChatId = chat.id;
              break;
            }
          }
        }
        Get.offNamed(
          Routes.directMessageScreen,
          arguments: {
            "Id": friend.id,
            if (existingChatId != null) "existingChatId": existingChatId,
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child:
                    hasAvatar
                        ? CachedNetworkImage(
                          imageUrl: friend.avatarUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          placeholder: (_, __) => const ShimmerPlaceholder(),
                          errorWidget:
                              (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.white,
                                size: 24.sp,
                              ),
                        )
                        : Center(
                          child: Text(
                            _initialsOf(friend.fullName),
                            style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.w400,
                              color: AppColors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
              ),
            ),

            SizedBox(width: 12.w),

            // Name + username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.fullName,
                    style: GoogleFonts.notoSans(
                      color: AppColors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '@${friend.username}',
                    style: GoogleFonts.notoSans(
                      color: AppColors.readUnread,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: AppColors.fillnoti, size: 22.sp),
          ],
        ),
      ),
    );
  }

  String _initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
