import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/chat_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/chat_lock_service.dart';
import 'package:outspot/Views/Message/chat_lock_gate.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/text_safe.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/CommonWidgets/MapWidgets/mapsearch.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:shimmer/shimmer.dart';

class MessagesScreen extends StatefulWidget {
  MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late MessagesScreenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MessagesScreenController>();
    // ✅ Screen open হলেই loadUserProfile call হবে
    controller.refreshAvatarOnly();
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
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {},
        child: Scaffold(
          // backgroundColor: Color(0xffFFFFFF),
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60.h),
            child: Obx(() {
              if (controller.isSearching.value) {
                return AppBar(
                  scrolledUnderElevation: 0,

                  // backgroundColor: Color(0xffFFFFFF),
                  backgroundColor: Colors.transparent,
                  title: Text(
                    "Search Chats",
                    style: GoogleFonts.notoSans(
                      fontSize: 19.sp,
                      color: AppColors.white,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 18.w),
                      child: GestureDetector(
                        onTap: () {
                          controller.resetListState();
                          controller.searchController.clear();
                          controller.isSearching.value = false;
                        },
                        child: Icon(
                          Icons.close,
                          size: 38.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return AppBar(
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.transparent,
                 
                  leading: Padding(
                    padding: EdgeInsets.only(left: 18.w),
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed(Routes.myProfile);
                      },
                      child: Obx(() {
                        // Read the LIVE avatar from MyProfileController (updated via
                        // updateAvatarLocal whenever the profile pic changes), so this
                        // header avatar refreshes immediately — like the explore page.
                        // Falls back to the challenge controller's value if not loaded.

                        final imageUrl = () {
                          if (Get.isRegistered<MyProfileController>()) {
                            final mp = Get.find<MyProfileController>();
                            if (mp.avatarurl.value.isNotEmpty)
                              return mp.avatarurl.value;
                          }
                          return controller.avatarUrl.value;
                        }();

                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl ?? '',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              width: 40.w,
                              height: 30.h,

                              placeholder:
                                  (context, url) => const ShimmerPlaceholder(),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  centerTitle: true,
                  title: GestureDetector(
                    onTap: () {
                      Get.toNamed(Routes.viewAchievements);
                    },
                    child: Obx(() {
                      final accontroller = Get.find<MainscreeenController>();
                      final ttl = accontroller.myAchievements.value?.title;

                      double iconHeight = 30.h;

                      String imagePath;
                      if (ttl == "Urban Explorer") {
                        imagePath = "assets/svg/level/urbar_explorer.svg";
                      } else if (ttl == "Legendary Explorer") {
                        imagePath = "assets/svg/level/legendary_explorer.svg";
                      } else if (ttl == "City Sniper") {
                        imagePath = "assets/svg/level/city_snipper.svg";
                      } else if (ttl == "New Explorer") {
                        imagePath = "assets/svg/level/new_explorer.svg";
                      } else {
                        imagePath = "assets/svg/level/new_explorer.svg";
                      }

                      return SvgPicture.asset(
                        imagePath,
                        height: iconHeight,
                        fit: BoxFit.contain,
                      );
                    }),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () {
                        controller.isSearching.value = true;
                      },
                      child: Container(
                        width: 34.w,
                        height: 34.w,
                        padding: EdgeInsets.all(5.sp),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.fillnoti,
                          // border: Border.all(color: AppColors.yellow),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/svg/leaderboard/search.svg",
                            height: 18.sp,
                            width: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () {
                        controller.clearNotificationDot();
                        Get.toNamed(Routes.notification1);
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Notification icon container
                          Container(
                            margin: EdgeInsets.only(right: 10.w),
                            width: 34.w,
                            height: 34.w,
                            padding: EdgeInsets.all(5.sp),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.fillnoti,
                              // border: Border.all(color: AppColors.yellow),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                "assets/svg/icons/notification_icon.svg",
                                height: 18.sp,
                                width: 18.sp,
                              ),
                            ),
                          ),

                          // 🔴 Red dot (reactive)
                          Obx(() {
                            return controller.notificationRedDot.value
                                ? Positioned(
                                  right: 10,
                                  top: 1,
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
                  ],
                );
              }
            }),
          ),

          body: SafeArea(
            // Let content run to the bottom edge (like Explore) — otherwise the
            // bottom safe-area strip renders as an empty "dead space".
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: Column(
                children: [
                  // SizedBox(height: 7.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Column(
                      children: [
                        Obx(() {
                          if (controller.isSearching.value) {
                            return CustomTextField(
                              hintText: 'Search…',
                              autofocus: true,
                              controller: controller.searchController,
                              suffixIcon: UnconstrainedBox(
                                child: SvgPicture.asset(
                                  "assets/svg/icons/search_Icons.svg",
                                  width: 18.w,
                                  height: 18.w,
                                  // fit: BoxFit.scaleDown,
                                ),
                              ),
                              onChanged: (query) {
                                controller.filterChats(query);
                              },
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(
                                    controller.texts.length,
                                    (int index) {
                                      return GestureDetector(
                                        onTap: () {
                                          controller.selectedTabIndex.value =
                                              index;
                                          controller.filterChatTab();
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(right: 10.w),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                controller
                                                            .selectedTabIndex
                                                            .value ==
                                                        index
                                                    ? AppColors.backgroundColor
                                                    : AppColors.fillnoti,
                                            borderRadius: BorderRadius.circular(
                                              20.sp,
                                            ),
                                          ),
                                          child: Text(
                                            controller.texts[index],
                                            style: GoogleFonts.notoSans(
                                              fontSize: 12.sp,
                                              color:
                                                  controller
                                                              .selectedTabIndex
                                                              .value ==
                                                          index
                                                      ? AppColors.white
                                                      : AppColors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () {
                                    Get.toNamed(Routes.newChat);
                                  },
                                  child: SvgPicture.asset(
                                    "assets/svg/plus.svg",
                                    width: 28,
                                    height: 28,
                                  ),
                                ),
                              ],
                            );
                          }
                        }),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Obx(() {
                      final displayChats = controller.sortedFilteredChats;
                      final globalChat = controller.globalChatInfo.value;
                      final hasGlobalChat = globalChat != null;
                      final bool showGlobal =
                          (globalChat != null) &&
                          (controller.selectedTabIndex.value != 2 &&
                              controller.selectedTabIndex.value != 1) &&
                          (!controller.isSearching.value);
                      if (controller.isLoading.value) {
                        return ListView.builder(
                          itemCount: 8,
                          itemBuilder: (_, __) => _buildShimmerChatTile(),
                        );
                      }
                      if (controller.searchController.text.isNotEmpty &&
                          displayChats.isEmpty &&
                          !showGlobal) {
                        return Center(
                          child: Text(
                            "No chats found",
                            style: GoogleFonts.notoSans(
                              color: AppColors.readUnread,
                            ),
                          ),
                        );
                      }

                      final hasMore = controller.hasMoreChats;
                      final totalCount =
                          displayChats.length +
                          (showGlobal ? 1 : 0) +
                          (hasMore ? 1 : 0);

                      return RefreshIndicator(
                        color: const Color(0xffC574F7),
                        backgroundColor: const Color(0xff2D0731),
                        onRefresh: () async {
                          controller.resetPagination();
                          await controller.fetchChats();
                        },
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scroll) {
                            if (scroll.metrics.pixels >=
                                    scroll.metrics.maxScrollExtent - 200 &&
                                controller.hasMoreChats) {
                              controller.loadMoreChats();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            // Clear the floating bottom nav bar + the device
                            // safe-area (home indicator). The nav bar is lifted
                            // by viewPadding.bottom, so the list must be too —
                            // otherwise items peek in the gap below it on iOS.
                            padding: EdgeInsets.only(
                              bottom:
                                  110.h +
                                  MediaQuery.of(context).viewPadding.bottom,
                            ),
                            itemCount: totalCount,
                            itemBuilder: (_, index) {
                              // 🔥 GLOBAL CHAT ITEM (INDEX 0)
                              if (showGlobal && index == 0) {
                                return GestureDetector(
                                  onTap: () {
                                    Get.toNamed(
                                      Routes.directMessageScreen,
                                      arguments: {
                                        "username": globalChat.name,
                                        "chatId": globalChat.chatId,
                                      },
                                    );
                                  },

                                  child: Obx(() {
                                    final lastMsg =
                                        controller.globalLastMessage.value;
                                    String messageText =
                                        "Join the global conversation!";
                                    String timeText = "";
                                    bool isPhoto = false;

                                    if (lastMsg != null) {
                                      if (lastMsg.imageUrl == 'image' ||
                                          (lastMsg.imageUrl != null &&
                                              lastMsg.imageUrl!.isNotEmpty)) {
                                        messageText = "📷 Sent a photo";
                                        isPhoto = true;
                                      } else {
                                        messageText = lastMsg.content ?? "";
                                      }
                                      timeText = getTimeAgo(
                                        lastMsg.createdAt ?? "",
                                      );
                                    }

                                    return Container(
                                      color: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 8.h,
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 43.w,
                                            height: 43.h,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.backgroundColor,
                                            ),
                                            child: Center(
                                              child: Image.asset(
                                                "assets/Images/global.png",
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 14.w),

                                          // Name & Message
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Global Chat',
                                                      style:
                                                          GoogleFonts.notoSans(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 17.sp,
                                                            color:
                                                                AppColors.white,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(width: 7.w),
                                                    SvgPicture.asset(
                                                      "assets/svg/Icon-Solid-User.svg",
                                                      width: 9.h,
                                                      height: 12.w,
                                                      color: AppColors.yellow,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      "${globalChat.memberCount}",
                                                      style:
                                                          GoogleFonts.notoSans(
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors
                                                                    .yellow,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 2.h),
                                                Row(
                                                  children: [
                                                    Text(
                                                      ellipsizeByChars(
                                                        messageText,
                                                      ),
                                                      style: GoogleFonts.notoSans(
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            isPhoto
                                                                ? FontWeight
                                                                    .w400
                                                                : FontWeight
                                                                    .w400,
                                                        color:
                                                            lastMsg == null
                                                                ? AppColors
                                                                    .readUnread
                                                                : AppColors
                                                                    .readUnread,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (timeText.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 8.w,
                                                            ),
                                                        child: Text(
                                                          timeText,
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors
                                                                    .timeColor,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Time
                                        ],
                                      ),
                                    );
                                  }),
                                );
                              }
                              final actualIndex = index - (showGlobal ? 1 : 0);

                              // Load more indicator at the end
                              if (actualIndex >= displayChats.length) {
                                if (hasMore) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20.h,
                                    ),
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
                                return const SizedBox.shrink();
                              }

                              if (actualIndex < 0) {
                                return const SizedBox.shrink();
                              }
                              final chat = displayChats[actualIndex];

                              final name = _sanitize(
                                controller.getDisplayName(chat),
                              );
                              final avatarUrl = controller.getChatAvatar(
                                chat,
                                controller.currentUserId.value,
                              );

                              // Preview MUST come from latestMessage (server's
                              // source of truth). The server clears latestMessage
                              // to null for disappearing chats while the messages
                              // array still holds the old row — reading
                              // messages.last showed that stale "ghost" preview.
                              final lastMessage = _sanitize(
                                chat.latestMessage == null
                                    ? 'Message Now'
                                    : (() {
                                      final m = chat.latestMessage!;
                                      // Server scrubs previews from blocked users
                                      // to the literal "[blocked]" — show a
                                      // friendly label instead of the raw token.
                                      if ((m.content?.trim() ?? '') ==
                                          '[blocked]') {
                                        return '🚫 Message hidden';
                                      }
                                      final imageUrl = m.imageUrl?.trim() ?? '';
                                      final hasImage = imageUrl.isNotEmpty;
                                      final hasText =
                                          (m.content?.trim().isNotEmpty ??
                                              false);

                                      if (!hasImage && !hasText) return '9090';

                                      if (hasImage) {
                                        final lowerUrl = imageUrl.toLowerCase();
                                        final isPhoto =
                                            lowerUrl.endsWith('.jpg') ||
                                            lowerUrl.endsWith('.jpeg') ||
                                            lowerUrl.endsWith('.png') ||
                                            lowerUrl.endsWith('.gif') ||
                                            lowerUrl.endsWith('.webp');
                                        final isVideo =
                                            lowerUrl.endsWith('.mp4') ||
                                            lowerUrl.endsWith('.mov') ||
                                            lowerUrl.endsWith('.avi') ||
                                            lowerUrl.endsWith('.mkv') ||
                                            lowerUrl.endsWith('.webm');

                                        if (isPhoto) {
                                          return hasText
                                              ? '📷 ${m.content!.trim()}'
                                              : 'Sent a photo';
                                        } else if (isVideo) {
                                          return hasText
                                              ? '📹 ${m.content!.trim()}'
                                              : 'Sent a video';
                                        } else {
                                          return hasText
                                              ? m.content!.trim()
                                              : 'Sent a file';
                                        }
                                      }

                                      return m.content!.trim();
                                    })(),
                              );

                              final time = _sanitize(
                                chat.latestMessage != null
                                    ? getTimeAgo(chat.latestMessage!.createdAt)
                                    : '',
                              );

                              final isUnread = controller.isChatUnreadForMe(
                                chat,
                                controller.currentUserId.value,
                              );

                              return Column(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onLongPress: () async {
                                      showdeleteDialog(context, chat);
                                    },
                                    onTap: () async {
                                      // Password-locked chat → gate on open.
                                      // Skip the prompt if already unlocked this
                                      // session.
                                      final lock = ChatLockService.to;
                                      if (chat.isPasswordLocked &&
                                          !lock.isUnlocked(chat.id)) {
                                        final ok = await ChatLockGate.open(
                                          chat.id,
                                          name,
                                        );
                                        if (!ok) return;
                                      }
                                      controller.setSelectedChat(
                                        chat,
                                        controller.currentUserId.value,
                                      );
                                      Get.toNamed(
                                        Routes.directMessageScreen,
                                        arguments: {
                                          "username":
                                              controller.selectedUserName.value,
                                          "Id": controller.selectedUserId.value,
                                          "groupId":
                                              chat.isGroup ? chat.id : null,
                                          "communityId":
                                              chat.isCommunity
                                                  ? chat.communityId
                                                  : null,
                                          "existingChatId":
                                              (!chat.isGroup &&
                                                      !chat.isCommunity)
                                                  ? chat.id
                                                  : null,
                                        },
                                      );
                                      log("Chat tapped: ${chat.name}");
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15.w,
                                        vertical: 8.h,
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              controller.openFriendProfile(
                                                chat,
                                              );
                                            },

                                            child: _buildAvatar(
                                              (avatarUrl != null &&
                                                      avatarUrl.startsWith(
                                                        'http',
                                                      ))
                                                  ? avatarUrl
                                                  : null,
                                              name,
                                            ),
                                          ),
                                          SizedBox(width: 14.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            ellipsizeByCharsname(
                                                              name,
                                                            ),
                                                            style:
                                                                GoogleFonts.notoSans(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      17.sp,
                                                                  color:
                                                                      AppColors
                                                                          .white,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (chat.isGroup ||
                                                              chat.isCommunity)
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 8.w,
                                                                ),

                                                                SvgPicture.asset(
                                                                  "assets/svg/Icon-Solid-User.svg",
                                                                  width: 9.h,
                                                                  height: 12.w,
                                                                  color:
                                                                      AppColors
                                                                          .yellow,
                                                                ),
                                                                SizedBox(
                                                                  width: 4.w,
                                                                ),
                                                                Text(
                                                                  "${chat.users.length}",
                                                                  style: GoogleFonts.notoSans(
                                                                    fontSize:
                                                                        16.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        AppColors
                                                                            .yellow,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          if (chat.isGroup &&
                                                              chat.isLocked)
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    left: 6.w,
                                                                  ),
                                                              child: Icon(
                                                                Icons.lock,
                                                                size: 14.sp,
                                                                color:
                                                                    Colors
                                                                        .redAccent,
                                                              ),
                                                            ),
                                                          // Per-chat PASSWORD
                                                          // lock (privacy).
                                                          if (chat
                                                              .isPasswordLocked)
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    left: 6.w,
                                                                  ),
                                                              child: Icon(
                                                                Icons
                                                                    .lock_outline_rounded,
                                                                size: 15.sp,
                                                                color: const Color(
                                                                  0xFFAB50F6,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 2.h),
                                                Row(
                                                  children: [
                                                    if (!chat.isPasswordLocked &&
                                                        chat.latestMessage !=
                                                            null &&
                                                        chat
                                                                .latestMessage!
                                                                .senderId ==
                                                            controller
                                                                .currentUserId
                                                                .value)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              right: 4.w,
                                                            ),
                                                        child:
                                                            _buildChatListTick(
                                                              chat,
                                                              controller
                                                                  .currentUserId
                                                                  .value,
                                                            ),
                                                      ),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            ellipsizeByChars(
                                                              chat.isPasswordLocked
                                                                  ? '🔒 Locked chat'
                                                                  : lastMessage,
                                                            ),
                                                            style: GoogleFonts.notoSans(
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  isUnread
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .w400,
                                                              color:
                                                                  isUnread
                                                                      ? AppColors
                                                                          .white
                                                                      : AppColors
                                                                          .readUnread,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          SizedBox(width: 8.w),
                                                          Text(
                                                            time,
                                                            style: GoogleFonts.notoSans(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  isUnread
                                                                      ? const Color(
                                                                        0xffC574F7,
                                                                      )
                                                                      : AppColors
                                                                          .timeColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    if (isUnread)
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                          left: 8.w,
                                                        ),
                                                        width: 10.w,
                                                        height: 10.h,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Color(
                                                                0xffC574F7,
                                                              ),
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                    // SizedBox(width: 8.w),
                                                    // Text(
                                                    //   time,
                                                    //   style: GoogleFonts.notoSans(
                                                    //     fontSize: 12.sp,
                                                    //     color:
                                                    //         isUnread
                                                    //             ? const Color(
                                                    //               0xffC574F7,
                                                    //             )
                                                    //             : AppColors.timeColor,
                                                    //     fontWeight: FontWeight.w700,
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    final size = 47.w; // আপনার আগের কোডের সাইজ অনুযায়ী 44.w দেওয়া হলো
    final hasUrl = (url != null && url.isNotEmpty);

    if (!hasUrl) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.black,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            controller.initialsOf(name), // নামের প্রথম অক্ষরগুলো
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
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
            (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  controller.initialsOf(
                    name,
                  ), // ছবি ফেইল করলে নামের অক্ষর দেখাবে
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildChatListTick(ChatModel chat, int myId) {
    final msg = chat.latestMessage;
    if (msg == null) return const SizedBox.shrink();

    final otherReadCount = msg.readBy.where((id) => id != myId).length;
    final otherMembers = chat.users.length - 1;

    if (otherMembers > 0 && otherReadCount >= otherMembers) {
      // All others have read — blue double tick
      return Icon(Icons.done_all, size: 14.sp, color: const Color(0xff56B4FF));
    } else if (otherReadCount > 0) {
      // At least one other has read — blue double tick
      return Icon(Icons.done_all, size: 14.sp, color: const Color(0xff56B4FF));
    } else {
      // Not read — single grey tick (sent)
      // Don't trust deliveredTo from API as server marks offline users as delivered
      return Icon(Icons.done, size: 14.sp, color: AppColors.readUnread);
    }
  }

  bool isChatUnreadForMes(ChatModel chat, int myId) {
    if (myId <= 0) return false;
    if (chat.messages.isEmpty) return false;

    final m = chat.messages.last;

    if (m.senderId == myId) return false;

    bool seenByMe(dynamic readBy, int id) {
      if (readBy is List) {
        for (final e in readBy) {
          final v = int.tryParse('$e');
          if (v != null && v == id) return true;
        }
      }
      return false;
    }

    return !seenByMe(m.readBy, myId);
  }

  /// Sanitize string to remove invalid UTF-16 surrogates
  String _sanitize(String s) => s.sanitizeUtf16();

  String ellipsizeByChars(String s, {int max = 18}) {
    final safe = _sanitize(s);
    final chars = safe.characters;
    if (chars.length <= max) return safe;
    return chars.take(max).toString() + '…';
  }

  String ellipsizeByCharsname(String s, {int max = 18}) {
    final safe = _sanitize(s);
    final chars = safe.characters;
    if (chars.length <= max) return safe;
    return chars.take(max).toString() + '…';
  }

  String getTimeAgo(String dateTimeStr) {
    final DateTime messageTime = DateTime.parse(dateTimeStr);
    final DateTime now = DateTime.now();

    final difference = now.difference(messageTime);

    if (difference.inDays >= 365) {
      final int years = (difference.inDays / 365).floor();
      return '${years}y';
    } else if (difference.inDays >= 30) {
      final int months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else if (difference.inDays >= 7) {
      final int weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}hr';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Just now';
    }
  }

  void showMuteDialog(BuildContext context, int chatId) async {
    await controller.fetchMuteStatus(chatId);

    Get.defaultDialog(
      title: controller.isMuted.value ? 'Unmute Chat?' : 'Mute Chat?',
      middleText:
          controller.isMuted.value
              ? 'Do you want to unmute this chat?'
              : 'Do you want to mute this chat?',
      textCancel: 'Cancel',
      textConfirm: controller.isMuted.value ? 'Unmute' : 'Mute',
      onConfirm: () async {
        await controller.toggleMute(chatId);
        Get.back();
      },
    );
  }

  // void showdeleteDialog(BuildContext context, ChatModel c) async {
  //   Get.defaultDialog(
  //     backgroundColor: AppColors.black,
  //     middleText: 'Do you want to delete this chat?',
  //     textCancel: 'Cancel',
  //     cancelTextColor: AppColors.white,
  //     middleTextStyle: GoogleFonts.notoSans(color: AppColors.white),
  //     titleStyle: GoogleFonts.notoSans(color: AppColors.white),

  //     onConfirm: () async {
  //       try {
  //         Get.back();
  //         AppLoading.show();
  //         final response = await ApiService.deleteChats([c.id]);
  //         if (response["processedChatIds"].contains(c.id)) {
  //           controller.removeChat(c.id);
  //         }
  //       } catch (e) {
  //         print(" Delete failed: $e");
  //       } finally {
  //         AppLoading.hide();
  //       }
  //     },
  //   );
  // }
  void showdeleteDialog(BuildContext context, ChatModel c) async {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Color(0xffFF5555), size: 40),
              SizedBox(height: 14.h),
              Text(
                "Delete Chat",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Do you want to delete this chat? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.white70),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  // ✅ Cancel button — same as "Keep"
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.MainColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // ✅ Delete button — same as "Cancel request"
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF5555),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () async {
                        try {
                          Get.back();
                          AppLoading.show();
                          final response = await ApiService.deleteChats([c.id]);
                          if (response["processedChatIds"].contains(c.id)) {
                            controller.removeChat(c.id);
                          }
                        } catch (e) {
                          print("Delete failed: $e");
                        } finally {
                          AppLoading.hide();
                        }
                      },
                      child: Text("Delete", style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget CustomTextField({
    required String hintText,
    required Widget suffixIcon,
    bool obscureText = false,
    bool autofocus = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Widget? prefixImage,
  }) {
    return TextFormField(
      style: TextStyle(color: AppColors.white),
      onChanged: onChanged,
      controller: controller,
      obscureText: obscureText,
      autofocus: autofocus,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.notoSans(
          color: AppColors.hint,
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
        fillColor: AppColors.fillcolor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: const BorderSide(color: AppColors.green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: const BorderSide(color: AppColors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: const BorderSide(color: AppColors.green),
        ),
      ),
    );
  }

  Widget _buildShimmerChatTile() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Row(
          children: [
            CircleAvatar(radius: 25.r, backgroundColor: Colors.white),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 200.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.r),
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

  Widget _buildGlobalChatItem(GlobalChatInfo info) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundColor,
            ),
            child: Image.asset("assets/Images/global.png"),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name, // "Global Chat"
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: AppColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Join the global conversation',
                  style: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    color: AppColors.readUnread,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
