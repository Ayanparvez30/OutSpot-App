import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:outspot/CommonWidgets/CustomWidgets/chat_bubble_border.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/text_safe.dart';
import 'package:outspot/Utils/shared_location.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';
import 'package:outspot/Views/Directmassagescreen.dart/media_message_pill.dart';
import 'package:outspot/Views/Groupdetails/group_edit_OptionsSheet.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/No%20Community/mutecommunitysheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:outspot/Network_Manager/video_cache_service.dart';
import 'package:outspot/Utils/video_error_log.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class DirectMessageScreen extends GetView<DirectmassagescreenController> {
  DirectMessageScreen({super.key});
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ২. ডিসপ্লে করার জন্য টেক্সট জেনারেট করার ফাংশন
  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (_isSameDay(checkDate, today)) {
      return "Today";
    } else if (_isSameDay(checkDate, yesterday)) {
      return "Yesterday";
    } else {
      // অন্য দিনের জন্য Date Month ফরম্যাট (যেমন: 12 July)
      return DateFormat('dd MMMM').format(date);
    }
  }

  // ৩. ডেট হেডারের ডিজাইন উইজেট
  Widget _buildReadTick(Map<String, dynamic> msg) {
    final readBy = (msg['readBy'] as List?) ?? [];
    final deliveredTo = (msg['deliveredTo'] as List?) ?? [];
    final senderId = controller.senderId.value;
    final isRead = readBy.any((id) => id != senderId);
    final isDelivered = deliveredTo.any((id) => id != senderId);
    final uploading = msg['uploading'] ?? false;

    if (uploading) {
      // Sending state — clock icon
      return Icon(Icons.access_time, size: 14.sp, color: AppColors.readUnread);
    }

    if (isRead) {
      // Colored filled double tick — read
      return Icon(Icons.done_all, size: 16.sp, color: const Color(0xff56B4FF));
    }

    if (isDelivered) {
      // Grey double tick — delivered but not read
      return Icon(Icons.done_all, size: 16.sp, color: AppColors.readUnread);
    }

    // Single grey tick — sent but not delivered
    return Icon(Icons.done, size: 16.sp, color: AppColors.readUnread);
  }

  // Reopen a shared location on the map: switch to the Map tab and focus the
  // place (drops a marker, animates the camera, opens its detail sheet).
  void _openSharedLocation(SharedLocation loc) {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.offAllNamed(
      Routes.mainscreen,
      arguments: {
        'tab': 1,
        'sharedLocation': {
          'placeId': loc.placeId,
          'lat': loc.lat,
          'lng': loc.lng,
          'name': loc.name,
        },
      },
    );
  }

  Widget _buildDateHeader(String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15.h),
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Color(
            0xff703A8B,
          ).withOpacity(0.8), // ইমেজের মতো কালচে ব্যাকগ্রাউন্ড
          borderRadius: BorderRadius.circular(16.sp),
        ),
        child: Text(
          text,
          style: GoogleFonts.notoSans(
            color: AppColors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            color: Colors.grey.shade400,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
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
      child: PopScope(
        canPop: true,
        // Dismiss keyboard on iOS swipe-back / Android system back so it
        // doesn't linger and re-attach to the chat list's search field.
        onPopInvoked: (didPop) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 25.r,
                height: 25.r,
              ),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Get.back();
              },
            ),
            title:
                controller.isGlobalChat.value
                    ? Row(
                      children: [
                        SizedBox(width: 8.w),
                        // 1. Globe Icon
                        Image.asset(
                          "assets/Images/global.png",
                          width: 40.w,
                          height: 40.h,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Global Chat',
                                style: GoogleFonts.notoSans(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Obx(
                                () => Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/svg/location.svg",
                                      width: 14.h,
                                      height: 14.w,
                                    ),
                                    SizedBox(width: 3.w),
                                    Flexible(
                                      child: Text(
                                        controller
                                                .globalChatName
                                                .value
                                                .isNotEmpty
                                            ? controller.globalChatName.value
                                            : 'All USA',
                                        style: GoogleFonts.notoSans(
                                          fontSize: 12.sp,
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5.w,
                                      ),
                                      child: Text(
                                        "|",
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      "assets/svg/Icon-Solid-User.svg",
                                      width: 9.h,
                                      height: 10.w,
                                      color: AppColors.yellow,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "${controller.globalChatInfo.value?.memberCount ?? ""}",
                                      style: GoogleFonts.notoSans(
                                        fontSize: 11.sp,
                                        color: const Color(0xFFE8A838),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    Spacer(),
                                    GestureDetector(
                                      onTap:
                                          () => showCombinedRoomSheet(context),
                                      child: Container(
                                        child: Icon(
                                          Icons.filter_list,
                                          size: 22.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        GestureDetector(
                          onTap: () => controller.onTapHeaderAvatar(),
                          child: Obx(
                            () => CircleAvatar(
                              radius: 20.sp,
                              backgroundColor: Colors.transparent,
                              child: _buildAvatarImage(controller),
                            ),
                          ),
                        ),

                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.onTapHeaderAvatar(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  child: Obx(() {
                                    String displayName = "";

                                    if (controller
                                        .friendName
                                        .value
                                        .isNotEmpty) {
                                      displayName = controller.friendName.value;
                                    } else if (controller
                                        .communityName
                                        .value
                                        .isNotEmpty) {
                                      displayName =
                                          controller.communityName.value;
                                    } else if (controller
                                        .groupname
                                        .value
                                        .isNotEmpty) {
                                      displayName = controller.groupname.value;
                                    }

                                    return Text(
                                      displayName,
                                      style: GoogleFonts.notoSans(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    );
                                  }),
                                ),
                                SizedBox(height: 6.w),

                                Obx(() {
                                  final isDirect =
                                      controller.groupid.value == 0 &&
                                      controller.communityId.value == 0;
                                  final isGroup =
                                      controller.groupid.value != 0 &&
                                      controller.communityId.value == 0;
                                  final isCommunity =
                                      controller.communityId.value != 0;

                                  if (isDirect) {
                                    return Row(
                                      children: [
                                        // Image.asset(
                                        //   "assets/Images/cayncoin.png",
                                        //   scale: .8,
                                        // ),
                                        SvgPicture.asset(
                                          "assets/svg/bluepoint.svg",
                                        ),

                                        Text(
                                          "  ${controller.usertotalpoints.value}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),
                                        Text(
                                          "|",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.fillnoti,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),

                                        SvgPicture.asset(
                                          "assets/svg/Icon-Outline-Coin-P.svg",
                                          height: 13.h,
                                        ),

                                        Text(
                                          "  ${controller.userweekpoints.value}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else if (isGroup) {
                                    // 🔹 Group Chat
                                    return Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/svg/bluepoint.svg",
                                        ),

                                        Text(
                                          "  ${controller.grouptotalpopint.value}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),
                                        Text(
                                          "|",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.fillnoti,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),
                                        SvgPicture.asset(
                                          "assets/svg/Icon-Outline-Coin-P.svg",
                                          height: 13.h,
                                        ),
                                        Text(
                                          "  ${controller.groupweeklypopint.value}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else if (isCommunity) {
                                    // 🔹 Community Chat
                                    return Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/svg/bluepoint.svg",
                                        ),
                                        Text(
                                          "  ${controller.communitytotalpoints.value}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),
                                        Text(
                                          "|",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.fillnoti,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),
                                        SvgPicture.asset(
                                          "assets/svg/Icon-Outline-Coin-P.svg",
                                          height: 13.h,
                                        ),
                                        Text(
                                          "  ${controller.communityweekpoints.value}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14.sp,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                              ],
                            ),
                          ),
                        ),

                        // Obx(() {
                        //   final bool isGroup = controller.groupid.value != 0;
                        //   final bool isCommunity =
                        //       controller.communityId.value != 0;

                        //   return GestureDetector(
                        //     onTap: () {
                        //       if (isCommunity) {
                        //         CommunityOptionsSheet.showOptions(
                        //           context: context,
                        //           communityId: controller.communityId.value,
                        //         );
                        //       } else if (isGroup) {
                        //         GroupeditOptionsSheet.show(
                        //           context: context,
                        //           groupId: controller.groupid.value,
                        //           groupName: controller.groupname.value,
                        //           isAdmin: controller.isAdmin,
                        //           isLocked: controller.isLocked,
                        //           isMuted: controller.isMuted,
                        //           onLockToggle:
                        //               () =>
                        //                   controller.isLocked.value
                        //                       ? controller.unlockChat(
                        //                         controller.groupid.value,
                        //                       )
                        //                       : controller.lockChat(
                        //                         controller.groupid.value,
                        //                       ),
                        //           onMuteToggle:
                        //               () => controller.toggleMute(
                        //                 controller.groupid.value,
                        //               ),
                        //           onLeave: () => controller.leaveGroup(),
                        //         );
                        //       }
                        //       // 🔥 ৩. যদি এটি সাধারণ পার্সোনাল চ্যাট হয়
                        //       else {
                        //         final model =
                        //             controller.buildFriendModelForHeader();
                        //         if (model != null) {
                        //           Get.toNamed(
                        //             Routes.conversationOptions,
                        //             arguments: {
                        //               'friend': model,
                        //               'chatId': controller.chatId.value,
                        //             },
                        //           );
                        //         } else {
                        //           log(
                        //             "Friend model is null, cannot navigate to options.",
                        //           );
                        //         }
                        //       }
                        //     },
                        //     child: Padding(
                        //       padding: EdgeInsets.only(
                        //         left: 8.w,
                        //         right: 4.w,
                        //       ), // একটু সাইড প্যাডিং দিলাম
                        //       child: SvgPicture.asset(
                        //         "assets/svg/3dot.svg",
                        //         fit: BoxFit.cover,
                        //       ),
                        //     ),
                        //   );
                        // }),
                        Obx(() {
                          final bool isGroup = controller.groupid.value != 0;
                          final bool isCommunity =
                              controller.communityId.value != 0;

                          // 🔥 ১. যদি কমিউনিটি হয়, তবে ৩-ডট আইকনটি দেখাবেই না
                          if (isCommunity) {
                            return const SizedBox.shrink();
                          }

                          // ২. গ্রুপ বা পার্সোনাল চ্যাট হলে নিচের বাটনটি দেখাবে
                          return GestureDetector(
                            onTap: () {
                              if (isGroup) {
                                GroupeditOptionsSheet.show(
                                  isGroup: false,
                                  context: context,
                                  groupId: controller.groupid.value,
                                  groupName: controller.groupname.value,
                                  isAdmin: controller.isAdmin,
                                  isLocked: controller.isLocked,
                                  isMuted: controller.isMuted,
                                  onLockToggle:
                                      () =>
                                          controller.isLocked.value
                                              ? controller.unlockChat(
                                                controller.groupid.value,
                                              )
                                              : controller.lockChat(
                                                controller.groupid.value,
                                              ),
                                  onMuteToggle:
                                      () => controller.toggleMute(
                                        controller.groupid.value,
                                      ),
                                  onLeave: () => controller.leaveGroup(),
                                );
                              }
                              // ৩. সাধারণ পার্সোনাল চ্যাট
                              else {
                                final model =
                                    controller.buildFriendModelForHeader();
                                if (model != null) {
                                  Get.toNamed(
                                    Routes.conversationOptions,
                                    arguments: {
                                      'friend': model,
                                      'chatId': controller.chatId.value,
                                    },
                                  );
                                } else {
                                  log(
                                    "Friend model is null, cannot navigate to options.",
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.w, right: 4.w),
                              child: SvgPicture.asset(
                                "assets/svg/3dot.svg",
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
          ),
          body: SafeArea(
            // Symmetric, tight horizontal padding so the message list isn't
            // shifted right (the old `left: 15` with no right padding caused the
            // extra empty space on the left). WhatsApp-style: small even gutter,
            // bubbles hug their own edge.
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                children: [
                  Divider(color: AppColors.fillnoti, thickness: 1.5),

                  Expanded(
                    child: Stack(
                      children: [
                        Obx(() {
                          // Shimmer until: (a) the fetch finishes, AND (b) for an
                          // empty direct chat, the friend's name has loaded — so
                          // the empty state shows "Say hi to Bappi" directly,
                          // never a generic flash first. Once shimmer ends,
                          // messages are present or the chat is genuinely empty.
                          if (controller.isLoading.value ||
                              (controller.item.isEmpty &&
                                  !controller.isChatHeaderReady)) {
                            return ListView.builder(
                              itemCount: 10,
                              itemBuilder:
                                  (context, index) =>
                                      _buildShimmerMessage(index % 2 == 0),
                            );
                          }
                          // No messages yet → show an inviting empty state so the
                          // screen never looks blank/broken (load error vs empty
                          // vs no-net is otherwise indistinguishable to the user).
                          if (controller.item.isEmpty) {
                            return _buildEmptyConversation();
                          }
                          return Stack(
                            children: [
                              ListView.builder(
                                controller: controller.scrollController,
                                // reverse:true → the list is naturally pinned to
                                // the bottom (offset 0 = newest message). No
                                // jump-to-bottom hack on load, and async image
                                // heights never cause a flicker/bounce.
                                reverse: true,
                                itemCount: controller.item.length,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemBuilder: (context, index) {
                                  // Map the reversed visual index back to the
                                  // chronological list (oldest..newest).
                                  final realIndex =
                                      controller.item.length - 1 - index;
                                  final msg = controller.item[realIndex];
                                  final isMine = msg['isMine'] ?? false;

                                  final mediaUrl =
                                      msg['imageUrl'] ?? msg['mediaUrl'];
                                  final localPath =
                                      msg['localPath']; // image upload preview
                                  final localVideoPath =
                                      msg['localVideoPath']; // video upload preview
                                  final uploading = msg['uploading'] ?? false;
                                  final failed = msg['failed'] ?? false;

                                  String? caption =
                                      msg['text'] ?? msg['caption'];
                                  caption ??=
                                      (msg['content'] is String &&
                                              !(msg['content'] as String)
                                                  .startsWith('http'))
                                          ? msg['content']
                                          : null;

                                  // Shared map location: pull the hidden token
                                  // out, strip it from the visible text, and
                                  // remember it so the bubble can open the map
                                  // on tap. A 📍 pin marks it as tappable.
                                  final SharedLocation? sharedLocation =
                                      caption is String
                                          ? SharedLocation.tryParse(caption)
                                          : null;
                                  if (sharedLocation != null &&
                                      caption is String) {
                                    final stripped =
                                        SharedLocation.stripDisplay(caption);
                                    caption =
                                        stripped.isEmpty
                                            ? '📍 View on map'
                                            : '📍 $stripped';
                                  }

                                  // A shared story/post embeds its media URL in
                                  // the text (e.g. "Check out this post!
                                  // https://...amazonaws.com/.../x.jpg"). The
                                  // image is already rendered from that URL, so
                                  // strip the raw media link(s) from the caption —
                                  // a bare AWS/media URL in the bubble looks broken.
                                  // Normal links are left intact (linkified).
                                  if (caption is String && caption.isNotEmpty) {
                                    var c = caption;
                                    if (mediaUrl is String &&
                                        mediaUrl.isNotEmpty) {
                                      c = c.replaceAll(mediaUrl, '');
                                    }
                                    c = c.replaceAll(
                                      RegExp(
                                        r'https?://\S*amazonaws\.com/\S+',
                                        caseSensitive: false,
                                      ),
                                      '',
                                    );
                                    c = c.replaceAll(
                                      RegExp(
                                        r'https?://\S+\.(?:jpg|jpeg|png|webp|gif|mp4|mov|webm|m4v)\b',
                                        caseSensitive: false,
                                      ),
                                      '',
                                    );
                                    c = c.trim();
                                    caption = c.isEmpty ? null : c;
                                  }

                                  final hasRemote =
                                      mediaUrl != null && mediaUrl.isNotEmpty;
                                  final hasLocalImage = localPath != null;
                                  final hasLocalVideo = localVideoPath != null;

                                  bool _isVideoUrlOrPath(String? s) {
                                    if (s == null) return false;
                                    final p = s.toLowerCase();
                                    return p.endsWith('.mp4') ||
                                        p.endsWith('.mov') ||
                                        p.endsWith('.mkv') ||
                                        p.endsWith('.avi') ||
                                        p.endsWith('.webm') ||
                                        p.endsWith('.m4v');
                                  }

                                  final looksVideo =
                                      hasLocalVideo ||
                                      _isVideoUrlOrPath(mediaUrl);

                                  // A pure media message (media, no caption/reply/
                                  // forward) renders as just the pill — drop the
                                  // dark bubble box behind it.
                                  final bool isMediaOnly =
                                      (hasRemote ||
                                          hasLocalImage ||
                                          hasLocalVideo) &&
                                      (caption == null || caption.isEmpty) &&
                                      msg['replyTo'] == null &&
                                      msg['forwarded'] != true;

                                  final senderName =
                                      msg['sender']?['firstName'] ??
                                      'Unknown Sender';
                                  final sender = msg['sender'] ?? {};
                                  final avatarUrl = sender['avatarUrl'] ?? '';
                                  // Sender's user id (for tapping the name → open
                                  // their profile). NonPrivateProfile adapts to
                                  // friend vs non-friend internally.
                                  final rawSenderId =
                                      msg['senderId'] ?? sender['id'] ?? 0;
                                  final int msgSenderId =
                                      rawSenderId is int
                                          ? rawSenderId
                                          : int.tryParse('$rawSenderId') ?? 0;
                                  // This message's own id (for reply-jump key).
                                  final int msgRowId =
                                      msg['id'] is int
                                          ? msg['id'] as int
                                          : int.tryParse('${msg['id'] ?? 0}') ??
                                              0;

                                  ///hrader দেখানোর লজিক: প্রথম মেসেজের জন্য সব সময় হেডার দেখাবে, তারপর প্রতিটি মেসেজের জন্য আগের মেসেজের সাথে তার createdAt এর দিন তুলনা করবে। যদি দিন আলাদা হয়, তবে হেডার দেখাবে।
                                  bool showDateHeader = false;
                                  final DateTime currentMsgDate = controller
                                      .parseDT(msg['createdAt']);

                                  if (realIndex == 0) {
                                    // প্রথম মেসেজের জন্য সব সময় হেডার দেখাবে
                                    showDateHeader = true;
                                  } else {
                                    // আগের মেসেজের সাথে তুলনা
                                    final previousMsg =
                                        controller.item[realIndex - 1];
                                    final DateTime prevMsgDate = controller
                                        .parseDT(previousMsg['createdAt']);

                                    // যদি দিন আলাদা হয়, তবে হেডার দেখাবে
                                    if (!_isSameDay(
                                      currentMsgDate,
                                      prevMsgDate,
                                    )) {
                                      showDateHeader = true;
                                    }
                                  }
                                  // হেডার টেক্সট জেনারেট করা

                                  // System messages (e.g. disappearing messages changed)
                                  final isSystem = msg['isSystem'] ?? false;
                                  if (isSystem) {
                                    return Column(
                                      children: [
                                        if (showDateHeader)
                                          _buildDateHeader(
                                            _getDateHeader(currentMsgDate),
                                          ),
                                        _buildSystemMessage(
                                          msg['text'] ?? msg['content'] ?? '',
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      // ১. যদি হেডার দেখানোর শর্ত মিলে যায়
                                      if (showDateHeader)
                                        _buildDateHeader(
                                          _getDateHeader(currentMsgDate),
                                        ),
                                      _SwipeToReply(
                                        key:
                                            msgRowId > 0
                                                ? controller.keyForMessage(
                                                  msgRowId,
                                                )
                                                : null,
                                        onReply:
                                            () => controller.startReply(msg),
                                        child: Align(
                                          alignment:
                                              isMine
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            // Top-align the avatar with the bubble so
                                            // the top-left tail sits right next to it.
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Sender avatar on every received
                                              // message (all chat types). Only the
                                              // user's own sent messages have no
                                              // avatar. A small top nudge lines its
                                              // centre up with the bubble's tail.
                                              if (!isMine)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                        right: 1.0,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Tap avatar → same as tapping
                                                      // the name: open the sender's
                                                      // profile (all chat types).
                                                      GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          if (msgSenderId > 0) {
                                                            Get.toNamed(
                                                              Routes
                                                                  .nonPrivateProfile,
                                                              arguments: {
                                                                'id':
                                                                    msgSenderId,
                                                              },
                                                            );
                                                          }
                                                        },
                                                        child: _buildAvatar(
                                                          avatarUrl,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                              Flexible(
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  // Tap a shared location to
                                                  // reopen it on the map.
                                                  onTap:
                                                      sharedLocation != null
                                                          ? () =>
                                                              _openSharedLocation(
                                                                sharedLocation,
                                                              )
                                                          : null,
                                                  onLongPress:
                                                      () => _showMessageActions(
                                                        context,
                                                        msg,
                                                        isMine,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        isMediaOnly
                                                            ? EdgeInsets.zero
                                                            : EdgeInsets.symmetric(
                                                              vertical: 8.h,
                                                              horizontal: 10.w,
                                                            ),
                                                    margin: EdgeInsets.only(
                                                      top: 2.h,
                                                      bottom: 2.h,
                                                    ),
                                                    // WhatsApp-style bubble: moderate
                                                    // rounding + a real "tail" notch at
                                                    // the top corner (top-left for
                                                    // received, top-right for sent).
                                                    decoration: ShapeDecoration(
                                                      color:
                                                          isMediaOnly
                                                              ? Colors.transparent
                                                              : isMine
                                                              ? const Color(
                                                                0xFF3A1155,
                                                              )
                                                              : const Color(
                                                                0xFF1E0E2E,
                                                              ),
                                                      shape: ChatBubbleBorder(
                                                        isMine: isMine,
                                                        radius: 10,
                                                        borderColor:
                                                            isMediaOnly
                                                                ? Colors
                                                                    .transparent
                                                                : isMine
                                                                ? AppColors
                                                                    .fillnoti
                                                                : const Color(
                                                                  0xFF2A1740,
                                                                ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          isMine
                                                              ? CrossAxisAlignment
                                                                  .end
                                                              : CrossAxisAlignment
                                                                  .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Sender name (WhatsApp-style)
                                                        // at the top, inside the bubble.
                                                        // Tap → open that user's profile
                                                        // (friend vs non-friend handled
                                                        // by NonPrivateProfile). Not on
                                                        // your own sent messages.
                                                        if (!isMine &&
                                                            senderName
                                                                .toString()
                                                                .trim()
                                                                .isNotEmpty)
                                                          GestureDetector(
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            onTap: () {
                                                              if (msgSenderId >
                                                                  0) {
                                                                Get.toNamed(
                                                                  Routes
                                                                      .nonPrivateProfile,
                                                                  arguments: {
                                                                    'id':
                                                                        msgSenderId,
                                                                  },
                                                                );
                                                              }
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    bottom: 4.h,
                                                                  ),
                                                              child: Text(
                                                                senderName
                                                                    .toString(),
                                                                style: GoogleFonts.notoSans(
                                                                  color: const Color(
                                                                    0xffC574F7,
                                                                  ),
                                                                  fontSize:
                                                                      13.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        // "Forwarded" label
                                                        if (msg['forwarded'] ==
                                                            true)
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  bottom: 4.h,
                                                                ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons.forward,
                                                                  size: 12.sp,
                                                                  color:
                                                                      Colors
                                                                          .white54,
                                                                ),
                                                                SizedBox(
                                                                  width: 4.w,
                                                                ),
                                                                Text(
                                                                  'Forwarded',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white54,
                                                                    fontSize:
                                                                        11.sp,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        // Reply quote chip
                                                        if (msg['replyTo'] !=
                                                            null)
                                                          _buildReplyQuote(
                                                            msg['replyTo']
                                                                as Map,
                                                          ),
                                                        // Photo/video messages show
                                                        // a compact "Photo"/"Video"
                                                        // pill (tap to open
                                                        // fullscreen) instead of the
                                                        // full-size media inline.
                                                        if (hasLocalImage ||
                                                            hasRemote ||
                                                            hasLocalVideo)
                                                          MediaMessagePill(
                                                            isVideo: looksVideo,
                                                            uploading: uploading,
                                                            failed: failed,
                                                            onTap:
                                                                hasRemote
                                                                    ? () async {
                                                                      FocusManager
                                                                          .instance
                                                                          .primaryFocus
                                                                          ?.unfocus();
                                                                      await Future.delayed(
                                                                        const Duration(
                                                                          milliseconds:
                                                                              300,
                                                                        ),
                                                                      );
                                                                      if (looksVideo) {
                                                                        Get.to(
                                                                          () => FullscreenVideoView(
                                                                            videoUrl:
                                                                                mediaUrl,
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        Get.to(
                                                                          () => FullscreenImageView(
                                                                            imageUrl:
                                                                                mediaUrl!,
                                                                          ),
                                                                          transition:
                                                                              Transition.fadeIn,
                                                                          opaque:
                                                                              false,
                                                                        );
                                                                      }
                                                                    }
                                                                    : null,
                                                          ),

                                                        if (caption != null &&
                                                            caption
                                                                .isNotEmpty) ...[
                                                          if (hasLocalImage ||
                                                              hasRemote ||
                                                              hasLocalVideo)
                                                            SizedBox(
                                                              height: 6.h,
                                                            ),
                                                          // Caption sits below the
                                                          // media. When there's an
                                                          // attachment, lock the
                                                          // caption to the SAME width
                                                          // as the 220.w image so a
                                                          // long caption wraps to
                                                          // multiple lines flush with
                                                          // the image edges instead of
                                                          // ballooning the bubble
                                                          // wider than the image.
                                                          ConstrainedBox(
                                                            constraints:
                                                                (hasLocalImage ||
                                                                        hasRemote ||
                                                                        hasLocalVideo)
                                                                    ? BoxConstraints(
                                                                      maxWidth:
                                                                          220.w,
                                                                    )
                                                                    : const BoxConstraints(),
                                                            // WhatsApp-style: text + timestamp inline
                                                            child: Wrap(
                                                              alignment:
                                                                  WrapAlignment
                                                                      .end,
                                                              crossAxisAlignment:
                                                                  WrapCrossAlignment
                                                                      .end,
                                                              spacing: 6.w,
                                                              children: [
                                                                buildLinkifiedText(
                                                                  caption,
                                                                ),
                                                                if (msg['createdAt'] !=
                                                                        null &&
                                                                    msg['createdAt']
                                                                        .isNotEmpty)
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets.only(
                                                                          top:
                                                                              2.h,
                                                                        ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Text(
                                                                          formatTimestamp(
                                                                            msg['createdAt'],
                                                                          ),
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                11.sp,
                                                                            color:
                                                                                AppColors.readUnread,
                                                                          ),
                                                                        ),
                                                                        if (isMine) ...[
                                                                          SizedBox(
                                                                            width:
                                                                                3.w,
                                                                          ),
                                                                          _buildReadTick(
                                                                            msg,
                                                                          ),
                                                                        ],
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                        // Timestamp row for media-only messages (no caption)
                                                        if ((caption == null ||
                                                                caption
                                                                    .isEmpty) &&
                                                            msg['createdAt'] !=
                                                                null &&
                                                            msg['createdAt']
                                                                .isNotEmpty)
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  top: 4.h,
                                                                ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  formatTimestamp(
                                                                    msg['createdAt'],
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        11.sp,
                                                                    color:
                                                                        AppColors
                                                                            .readUnread,
                                                                  ),
                                                                ),
                                                                if (isMine) ...[
                                                                  SizedBox(
                                                                    width: 3.w,
                                                                  ),
                                                                  _buildReadTick(
                                                                    msg,
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
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
                              // Shimmer overlay while scroll positions to bottom
                              if (controller.initialScrollPending.value)
                                Positioned.fill(
                                  child: Container(
                                    color: const Color(0xff0F0114),
                                    child: ListView.builder(
                                      itemCount: 10,
                                      itemBuilder:
                                          (context, index) =>
                                              _buildShimmerMessage(
                                                index % 2 == 0,
                                              ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                        // Scroll-to-bottom arrow
                        Obx(
                          () =>
                              controller.showScrollDownArrow.value
                                  ? Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap:
                                          () => controller.scrollToBottom(
                                            animated: true,
                                          ),
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xff704EF9,
                                          ).withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.white,
                                          size: 24.sp,
                                        ),
                                      ),
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  Obx(() {
                    final img = controller.pendingImage.value;
                    final vid = controller.pendingVideo.value;

                    if (img == null && vid == null)
                      return const SizedBox.shrink();

                    final bool isVideo = vid != null;
                    return Container(
                      margin: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 4.h),
                      padding: EdgeInsets.fromLTRB(10.w, 10.h, 14.w, 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.inputBorderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail + overlaid red remove badge.
                          SizedBox(
                            // Extra room (top + right) so the badge overhang
                            // isn't clipped at the thumbnail corner.
                            width: 64,
                            height: 64,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child:
                                          isVideo
                                              ? Stack(
                                                fit: StackFit.expand,
                                                children: const [
                                                  ColoredBox(
                                                    color: Colors.black26,
                                                  ),
                                                  Center(
                                                    child: Icon(
                                                      Icons.play_circle_fill,
                                                      size: 28,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : Image.file(
                                                File(img!.path),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      controller.pendingImage.value = null;
                                      controller.pendingVideo.value = null;
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffDD4141),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Label so the user knows what's attached.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isVideo
                                          ? Icons.videocam_rounded
                                          : Icons.image_rounded,
                                      size: 16.sp,
                                      color: AppColors.textOut,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      isVideo
                                          ? "Video attachment"
                                          : "Photo attachment",
                                      style: GoogleFonts.notoSans(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  isVideo
                                      ? "Say something about this video…"
                                      : "Say something about this photo…",
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white60,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Reply preview banner — shows the quoted message above the
                  // input while composing a reply.
                  Obx(() {
                    final reply = controller.replyingTo.value;
                    if (reply == null) return const SizedBox.shrink();
                    final name = (reply['senderName'] ?? '').toString().trim();
                    final content = (reply['content'] ?? '').toString().trim();
                    final hasImg =
                        (reply['imageUrl'] ?? '').toString().isNotEmpty;
                    final preview =
                        content.isNotEmpty
                            ? content
                            : (hasImg ? '📷 Photo' : 'Message');
                    return Container(
                      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xffC574F7),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name.isNotEmpty
                                      ? 'Replying to $name'
                                      : 'Replying',
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xffC574F7),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.cancelReply,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Icon(
                                Icons.close,
                                size: 18.sp,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  Obx(() {
                    final bool isLocked = controller.isLocked.value;

                    if (isLocked) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        alignment: Alignment.center,
                        child: Text(
                          "This chat is locked.",
                          style: GoogleFonts.notoSans(
                            color: Colors.grey.shade500,
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.w,
                        vertical: 10.h,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: CustomTextFiel(
                          controller: controller.messageController,
                          focusNode: controller.messageFocusNode,
                          prefixImage:
                              controller.isGlobalChat.value
                                  ? null
                                  : GestureDetector(
                                    onTap:
                                        () =>
                                            _showCameraOrGallerySheet(context),
                                    child: UnconstrainedBox(
                                      child: SvgPicture.asset(
                                        "assets/svg/camera.svg",
                                        height: 18.h,
                                        width: 18.w,
                                        color: AppColors.fillnoti,
                                      ),
                                    ),
                                  ),
                          hintText: "Start typing...",
                          suffixIcon: GestureDetector(
                            onTap: () async {
                              await controller.onSend();
                            },
                            child: UnconstrainedBox(
                              child: SvgPicture.asset(
                                "assets/svg/send-alt-1-svgrepo-com.svg",
                                height: 18.h,
                                width: 18.w,
                                color: AppColors.fillnoti,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showRegionBottomSheet(BuildContext context) {
    final regions = [
      {'name': 'Alabama (AL)', 'code': 'AL'},
      {'name': 'Alaska (AK)', 'code': 'AK'},
      {'name': 'Arizona (AZ)', 'code': 'AZ'},
      {'name': 'Arkansas (AR)', 'code': 'AR'},
      {'name': 'California (CA)', 'code': 'CA'},
      {'name': 'Alaska (AK)', 'code': 'AK'},
      {'name': 'Arizona (AZ)', 'code': 'AZ'},
      {'name': 'Arkansas (AR)', 'code': 'AR'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: Get.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF180C24),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.sp),
              topRight: Radius.circular(20.sp),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Region",
                      style: GoogleFonts.notoSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.fillnoti,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1F38),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: AppColors.fillnoti),
                  ),
                  child: TextField(
                    style: TextStyle(color: AppColors.fillnoti),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "Search region...",
                      hintStyle: TextStyle(
                        color: AppColors.fillnoti,
                        fontSize: 14.sp,
                      ),

                      suffixIcon: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.sp,
                          vertical: 4.sp,
                        ),
                        child: Image.asset(
                          "assets/Images/realsteicserch.png",
                          scale: 1.sp,
                          color: AppColors.fillnoti,
                        ),
                      ),

                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,

                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.h,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Expanded(
                child: ListView.separated(
                  itemCount: regions.length,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),

                  separatorBuilder:
                      (_, __) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Divider(
                          color: AppColors.fillnoti,
                          thickness: 1,
                          height: 1,
                        ),
                      ),

                  itemBuilder: (context, index) {
                    final region = regions[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              "assets/Images/sklocatiomicon.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            region['name']!,
                            style: GoogleFonts.notoSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),

                          const Spacer(),

                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.fillnoti,
                                width: 1.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // messages_screen.dart ফাইলের নিচে বা ক্লাসের বাইরে

  void showCitySearchBottomSheet(BuildContext context) {
    // কন্ট্রোলার খুঁজে নেওয়া
    final controller = Get.find<DirectmassagescreenController>();

    // আগের সার্চ ক্লিয়ার করা
    controller.citySearchController.clear();
    controller.placePredictions.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: Get.height * 0.85, // স্ক্রিনের ৮৫% জুড়ে থাকবে
          decoration: BoxDecoration(
            color: const Color(0xFF180C24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // 🏷️ হেডার
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Region",
                      style: GoogleFonts.notoSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppColors.fillnoti,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔍 সার্চ বক্স
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1F38),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: AppColors.fillnoti),
                  ),
                  child: TextField(
                    controller: controller.citySearchController,
                    style: const TextStyle(color: Colors.white),

                    // 🔥 টাইপ করার সাথে সাথে সার্চ হবে
                    onChanged: (val) {
                      controller.searchCities(val);
                    },

                    decoration: InputDecoration(
                      hintText: "Search region...",
                      hintStyle: TextStyle(
                        color: AppColors.fillnoti,
                        fontSize: 14.sp,
                      ),
                      suffixIcon: Image.asset(
                        "assets/Images/realsteicserch.png",
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              Expanded(
                child: Obx(() {
                  if (controller.citySearchController.text.isNotEmpty &&
                      controller.placePredictions.isEmpty) {
                    return Center(
                      child: Text(
                        "Searching...",
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                      ),
                    );
                  }

                  if (controller.placePredictions.isEmpty) {
                    return Center(
                      child: Text(
                        "Type to find a city",
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.placePredictions.length,
                    separatorBuilder:
                        (_, __) => Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final place = controller.placePredictions[index];

                      final description = place['description'] ?? "";

                      return GestureDetector(
                        onTap: () {
                          controller.joinGlobalChatByCity(description);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.w,
                                  padding: EdgeInsets.all(8.w),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF2D1F38),
                                  ),
                                  child: Image.asset(
                                    "assets/Images/sklocatiomicon.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Text(
                                    description,
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.fillnoti,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyConversation() {
    // Resolve a friendly name for the chat (direct / group / community / global).
    String name = controller.friendName.value;
    if (name.isEmpty) name = controller.communityName.value;
    if (name.isEmpty) name = controller.groupname.value;
    if (name.isEmpty) name = controller.globalChatName.value;

    final bool isDirect =
        controller.groupid.value == 0 &&
        controller.communityId.value == 0 &&
        !controller.isGlobalChat.value;

    final String title =
        isDirect && name.isNotEmpty ? "Say hi to $name 👋" : "No messages yet";
    final String subtitle =
        isDirect
            ? "Break the ice — send the first message\nand start the conversation."
            : "Be the first to say something here\nand get the conversation going.";

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Looping Lottie illustration — far friendlier than a static
            // blank screen, and reads as "empty", not "broken/loading".
            Lottie.asset(
              'assets/Images/empty_chat.json',
              width: 160.w,
              height: 160.w,
              repeat: true,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: Colors.grey.shade400,
              ),
            ),
            // Global chat: note that messages auto-expire. Smaller, dimmer grey.
            if (controller.isGlobalChat.value) ...[
              SizedBox(height: 6.h),
              Text(
                "(messages disappear every 12 hours)",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerMessage(bool isLeft) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isLeft)
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: CircleAvatar(radius: 18.r, backgroundColor: Colors.white),
            ),
          if (isLeft) SizedBox(width: 8.w),
          Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white24,
            child: Container(
              width: isLeft ? 160.w : 120.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegionConfirmDialog(
    BuildContext context,
    String regionName,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (ctx) => Dialog(
            backgroundColor: const Color(0xFF1E1230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 36.h, 20.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure with the region\nyou want to select?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.r),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAB50F6), Color(0xFFFB7D6C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Yes, Continue',
                          style: GoogleFonts.notoSans(
                            fontSize: 15.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      'Nevermind',
                      style: GoogleFonts.notoSans(
                        fontSize: 13.sp,
                        color: const Color(0xFF6A5ACD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void showCombinedRoomSheet(BuildContext context) {
    controller.citySearchController.clear();
    controller.placePredictions.clear();
    controller.fetchGlobalRooms();
    controller.isCitySearching.value = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: Get.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF180C24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // ... Header & Search Bar (Same as before) ...
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Region",
                      style: GoogleFonts.notoSans(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppColors.fillnoti,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1F38),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: AppColors.fillnoti),
                  ),
                  child: TextField(
                    controller: controller.citySearchController,
                    style: const TextStyle(color: Colors.white),
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) {
                      controller.searchCities(val);
                    },
                    decoration: InputDecoration(
                      hintText: "Search region...",
                      hintStyle: TextStyle(
                        color: AppColors.fillnoti,
                        fontSize: 14.sp,
                      ),
                      isDense: true,
                      suffixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child:
                        //  Image.asset(
                        //   "assets/Images/realsteicserch.png",
                        //   color: AppColors.fillnoti,
                        //   height: 20.h,
                        //   width: 20.w,
                        // ),
                        UnconstrainedBox(
                          child: SvgPicture.asset(
                            "assets/svg/Icon-Outline-Search.svg",
                            height: 18.h,
                            width: 18.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // 📋 List Section
              Expanded(
                child: Obx(() {
                  bool isSearching = controller.isCitySearching.value;

                  // A. Search Mode
                  if (isSearching) {
                    // ... (Search Logic Same as before) ...
                    if (controller.placePredictions.isEmpty) {
                      return Center(
                        child: Text(
                          "Searching...",
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: controller.placePredictions.length,
                      separatorBuilder:
                          (_, __) => Divider(color: Colors.white10, height: 1),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemBuilder: (context, index) {
                        final place = controller.placePredictions[index];
                        final description = place['description'] ?? "";
                        return GestureDetector(
                          onTap: () {
                            Get.back();
                            controller.joinGlobalChatByCity(description);
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Row(
                              children: [
                                UnconstrainedBox(
                                  child: SvgPicture.asset(
                                    "assets/svg/location.svg",
                                    height: 25.h,
                                    width: 24.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Text(
                                    description,
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.fillnoti,
                                      width: 1.5,
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
                  // B. Default Global Rooms Mode
                  else {
                    if (controller.isGlobalLoading.value) {
                      return const Center(
                        child: ShimmerPlaceholder(
                          width: 200,
                          height: 200,
                          radius: 20,
                        ),
                      );
                    }
                    if (controller.globalRooms.isEmpty) {
                      return Center(
                        child: Text(
                          "No global rooms available",
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      );
                    }

                    final currentChatId =
                        controller.globalChatInfo.value?.chatId;

                    return ListView.separated(
                      itemCount: controller.globalRooms.length,
                      separatorBuilder:
                          (_, __) => Divider(color: Colors.white10, height: 1),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemBuilder: (context, index) {
                        final room = controller.globalRooms[index];

                        final bool isSelected = (currentChatId == room.chatId);
                        final displayName =
                            room.name
                                .replaceAll(RegExp(r'^Global Chat - '), '')
                                .trim();
                        return GestureDetector(
                          onTap: () {
                            if (isSelected) return;
                            _showRegionConfirmDialog(context, displayName, () {
                              Get.back(); // close dialog
                              Get.back(); // close bottom sheet
                              controller.joinGlobalChatByCity(room.name);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: isSelected ? 0.w : 0,
                            ),
                            decoration: BoxDecoration(),
                            child: Row(
                              children: [
                                UnconstrainedBox(
                                  child: SvgPicture.asset(
                                    "assets/svg/location.svg",
                                    height: 25.h,
                                    width: 24.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: GoogleFonts.notoSans(
                                          color:
                                              isSelected
                                                  ? AppColors.yellow
                                                  : Colors.white, // কালার চেঞ্জ
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.fillnoti,
                                      width: 1.5,
                                    ),
                                  ),
                                  child:
                                      isSelected
                                          ? Icon(
                                            Icons.check,
                                            color: AppColors.fillnoti,
                                            size: 20.sp,
                                          )
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // String formatTimestamp(String timestamp) {
  //   // parse -> local
  //   final DateTime messageLocal = DateTime.parse(timestamp).toLocal();
  //   final DateTime nowLocal = DateTime.now();

  //   final msgDate = DateTime(
  //     messageLocal.year,
  //     messageLocal.month,
  //     messageLocal.day,
  //   );
  //   final nowDate = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  //   final dayDiff = nowDate.difference(msgDate).inDays;

  //   if (dayDiff == 0) {
  //     return DateFormat('hh:mm a').format(messageLocal);
  //   } else if (dayDiff == 1) {
  //     return 'Yesterday';
  //   } else {
  //     return DateFormat('dd-MM').format(messageLocal);
  //   }
  // }
  String formatTimestamp(String timestamp) {
    // স্ট্রিং থেকে ডেটটাইম পার্স করে লোকাল টাইমে কনভার্ট করা
    final DateTime messageLocal = DateTime.parse(timestamp).toLocal();

    // কোনো কন্ডিশন ছাড়াই সব সময় শুধু সময় (যেমন: 10:30 AM) রিটার্ন করবে
    return DateFormat('hh:mm a').format(messageLocal);
  }

  Widget CustomTextFiel({
    required String hintText,
    required Widget suffixIcon,
    bool obscureText = false,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,

    Widget? prefixImage,
  }) {
    return TextFormField(
      style: TextStyle(color: AppColors.white),
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.notoSans(
          color: AppColors.fillnoti,
          fontSize: 17.sp,
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10,
        ),
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

  Widget _buildAvatar(String? url) {
    final size = 30.w;
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

  // Quoted-reply chip rendered above a reply message's content.
  Widget _buildReplyQuote(Map replyTo) {
    final name = (replyTo['senderName'] ?? '').toString().trim();
    final content = (replyTo['content'] ?? '').toString().trim();
    final hasImg = (replyTo['imageUrl'] ?? '').toString().isNotEmpty;
    final preview =
        content.isNotEmpty ? content : (hasImg ? '📷 Photo' : 'Message');
    final int? originalId = int.tryParse('${replyTo['id'] ?? ''}');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          originalId != null
              ? () => controller.jumpToMessage(originalId)
              : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border(
            left: BorderSide(color: const Color(0xffC574F7), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name.isNotEmpty)
              Text(
                name,
                style: GoogleFonts.notoSans(
                  color: const Color(0xffC574F7),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSans(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message long-press actions (delete own / report) ──────────────────────
  int _msgId(Map msg) {
    final raw = msg['id'];
    return raw is int ? raw : int.tryParse('${raw ?? 0}') ?? 0;
  }

  void _showMessageActions(BuildContext context, Map msg, bool isMine) {
    final int id = _msgId(msg);
    if (id <= 0) return;

    Widget tile(IconData icon, String label, Color color, VoidCallback onTap) {
      return ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: GoogleFonts.notoSans(
            color: color,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xff1A0520),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Reply — available on every message.
            tile(Icons.reply, 'Reply', Colors.white, () {
              Get.back();
              controller.startReply(msg);
            }),
            // Forward — available on every message.
            tile(Icons.forward, 'Forward', Colors.white, () {
              Get.back();
              _forwardMessage(msg);
            }),
            if (isMine)
              tile(
                Icons.delete_outline,
                'Delete for everyone',
                const Color(0xffDD4141),
                () {
                  Get.back();
                  _confirmDeleteMessage(id);
                },
              )
            else ...[
              tile(
                Icons.flag_outlined,
                'Report message',
                const Color(0xffF8AC00),
                () {
                  Get.back();
                  _showReportSheet(id);
                },
              ),
              // Group admin / community creator can delete anyone's message.
              if (controller.isAdmin.value)
                tile(
                  Icons.delete_sweep_outlined,
                  'Delete (admin)',
                  const Color(0xffDD4141),
                  () {
                    Get.back();
                    _confirmAdminDelete(id);
                  },
                ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  // Forward a message to other chats via the "Send To" sheet, flagged as
  // forwarded (receiver shows a "Forwarded" label). Media URL is reused — no
  // re-upload.
  void _forwardMessage(Map msg) {
    final String content =
        (msg['text'] ?? msg['caption'] ?? msg['content'] ?? '')
            .toString()
            .trim();
    final dynamic media = msg['imageUrl'] ?? msg['mediaUrl'];
    final String? imageUrl =
        (media is String && media.isNotEmpty) ? media : null;
    if (content.isEmpty && imageUrl == null) return;

    // Attribute the original author in the forwarded text:
    // "Forwarded From: Full Name(@username): <original text>"
    final sender = (msg['sender'] as Map?) ?? const {};
    final first = (sender['firstName'] ?? '').toString().trim();
    final last = (sender['lastName'] ?? '').toString().trim();
    // Socket-delivered messages already store the full name in firstName, so
    // only append lastName when it isn't already part of it (avoids "Bappi
    // Khan Khan"). Fetched messages have first/last split → join normally.
    String fullName = first;
    if (last.isNotEmpty && !first.contains(last)) {
      fullName = '$first $last'.trim();
    }
    final username = (sender['username'] ?? '').toString().trim();

    String author = fullName;
    if (username.isNotEmpty) {
      author = author.isNotEmpty ? '$author(@$username)' : '@$username';
    }

    final String forwardedText =
        author.isEmpty
            ? content
            : 'Forwarded From: $author:${content.isNotEmpty ? ' $content' : ''}';

    showSendToSheet(forwardedText, imageUrl: imageUrl, forwarded: true);
  }

  void _confirmDeleteMessage(int id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text(
          'Delete message?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This removes the message for everyone in the chat.',
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
            onPressed: () {
              Get.back();
              controller.deleteMyMessages([id]);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xffDD4141)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAdminDelete(int id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text(
          'Delete this message?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'As an admin you can remove this message for everyone in the chat.',
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
              Get.back();
              final ok = await controller.adminDeleteMessage(id);
              if (!ok) AppSnackbar.error('Could not delete. Try again.');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xffDD4141)),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(int messageId) {
    const reasons = <String>[
      'spam',
      'harassment',
      'nudity',
      'violence',
      'other',
    ];
    final selected = 'spam'.obs;
    final noteCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xff1A0520),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Report message',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tell us what\'s wrong. Our team will review it.',
              style: GoogleFonts.notoSans(
                color: Colors.white54,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Obx(
              () => Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children:
                    reasons.map((r) {
                      final isSel = selected.value == r;
                      return GestureDetector(
                        onTap: () => selected.value = r,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSel
                                    ? const Color(0xffAB50F6)
                                    : Colors.white10,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            r[0].toUpperCase() + r.substring(1),
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: GoogleFonts.notoSans(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: GoogleFonts.notoSans(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7B51F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                onPressed: () async {
                  Get.back();
                  final ok = await controller.reportMessage(
                    messageId: messageId,
                    reason: selected.value,
                    note: noteCtrl.text.trim(),
                  );
                  if (ok) {
                    AppSnackbar.success('Thanks — our team will review it.');
                  } else {
                    AppSnackbar.error('Could not report. Try again.');
                  }
                },
                child: Text(
                  'Submit report',
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showCameraOrGallerySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 25.h),
          decoration: BoxDecoration(
            color: const Color(0xff1A0520),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetOption(
                  icon: Icons.camera_alt,
                  label: "Take a Snap",
                  color: const Color(0xff66CCFC),
                  onTap: () {
                    Get.back();
                    controller.openAppCameraForSnap();
                  },
                ),
                Divider(height: 1, color: Colors.white12),
                _sheetOption(
                  icon: Icons.photo_library,
                  label: "Choose from Camera Roll",
                  color: const Color(0xffC574F7),
                  onTap: () {
                    Get.back();
                    controller.pickMediaOnly();
                  },
                ),
                Divider(height: 1, color: Colors.white12),
                _sheetOption(
                  icon: Icons.close,
                  label: "Cancel",
                  color: Colors.grey,
                  onTap: () => Get.back(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22.sp),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class FullscreenImageView extends StatelessWidget {
//   final String imageUrl;

//   FullscreenImageView({required this.imageUrl});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: GestureDetector(
//           onTap: () {
//             Get.back();
//           },

//           child: Container(
//             height: 100,
//             width: 100,
//             child: Container(
//               height: 100,
//               width: 100,
//               child: UnconstrainedBox(
//                 child: SvgPicture.asset(
//                   "assets/svg/icons/back_icon.svg",
//                   width: 25.r,
//                   height: 25.r,
//                   // fit: BoxFit.scaleDown,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Center(
//         child: GestureDetector(
//           onTap: () {
//             // Close the fullscreen view on tapping the image
//             Get.back();
//           },
//           child: InteractiveViewer(
//             panEnabled: true, // Allow panning
//             boundaryMargin: EdgeInsets.all(50),
//             minScale: 0.1,
//             maxScale: 4.0,
//             child: CachedNetworkImage(
//               imageUrl: imageUrl, // Load image from URL
//               fit: BoxFit.contain,
//               placeholder:
//                   (context, url) => const ShimmerPlaceholder(radius: 0),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class FullscreenImageView extends StatefulWidget {
  final String imageUrl;

  const FullscreenImageView({super.key, required this.imageUrl});

  @override
  State<FullscreenImageView> createState() => _FullscreenImageViewState();
}

class _FullscreenImageViewState extends State<FullscreenImageView> {
  @override
  Widget build(BuildContext context) {
    // 🔥 ১. URL এ 'http' না থাকলে Base URL যোগ করে দেওয়া (যাতে ছবি ব্ল্যাংক না আসে)
    String finalUrl = widget.imageUrl;
    if (finalUrl.isNotEmpty && !finalUrl.startsWith('http')) {
      finalUrl =
          ApiConstants.host +
          (finalUrl.startsWith('/') ? finalUrl : "/$finalUrl");
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // True full-screen image — extend behind the transparent app bar so the
      // photo fills the screen instead of sitting boxed with black margins.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            height: 100,
            width: 100,
            child: UnconstrainedBox(
              child: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 25.r,
                height: 25.r,
              ),
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _saveImageToGallery(finalUrl),
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
        ],
      ),
      body: SizedBox.expand(
        // Fill the whole screen so the image renders at max size; it used to
        // take its small intrinsic size inside a Center, leaving big margins.
        child: InteractiveViewer(
          // No boundary margin — keeps the image locked in place
          // until the user pinch-zooms in.
          boundaryMargin: EdgeInsets.zero,
          minScale: 1.0,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: finalUrl,
            // fitWidth → image spans the full screen width (no left/right black
            // padding); height scales proportionally, top/bottom letterbox is
            // fine. Pinch-zoom still works via InteractiveViewer.
            fit: BoxFit.fitWidth,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder:
                (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            errorWidget:
                (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 64,
                ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImageToGallery(String url) async {
    try {
      Get.snackbar(
        'Downloading...',
        'Saving image to gallery',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.fillnoti,
        colorText: Colors.white,
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'outspot_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        await PhotoManager.editor.saveImageWithPath(file.path, title: fileName);

        Get.snackbar(
          'Saved',
          'Image saved to gallery',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.green.withOpacity(0.4),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}

Widget _buildAvatarImage(DirectmassagescreenController controller) {
  // কোনটা দেখাবে সেটা নির্ধারণ করো
  String imageUrl = "";

  if (controller.frienduserId.value != 0 &&
      controller.avatarurl.value.isNotEmpty) {
    imageUrl = controller.avatarurl.value;
  } else if (controller.communityId.value != 0 &&
      controller.communityImage.value.isNotEmpty) {
    imageUrl = controller.communityImage.value;
  } else if (controller.groupimageurl.value.isNotEmpty) {
    imageUrl = controller.groupimageurl.value;
  }

  // এখন URL আছে কিনা দেখো
  if (imageUrl.isEmpty) {
    // ফাঁকা হলে আইকন দেখাও
    IconData icon;
    if (controller.frienduserId.value != 0) {
      icon = Icons.person;
    } else if (controller.communityId.value != 0) {
      icon = Icons.groups;
    } else {
      icon = Icons.group;
    }

    return Icon(icon, color: Colors.grey);
  }

  // নাহলে CachedNetworkImage দেখাও
  return ClipOval(
    child: CachedNetworkImage(
      alignment: Alignment.topCenter,
      imageUrl: imageUrl,
      width: 40.sp,
      height: 40.sp,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            width: 40.sp,
            height: 40.sp,
            color: Colors.transparent,
            child: Icon(Icons.image, color: Colors.grey),
          ),
      errorWidget:
          (context, url, error) => Container(
            width: 40.sp,
            height: 40.sp,
            color: Colors.transparent,
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
    ),
  );
}

class FullscreenVideoView extends StatefulWidget {
  final String videoUrl;

  const FullscreenVideoView({super.key, required this.videoUrl});

  @override
  _FullscreenVideoViewState createState() => _FullscreenVideoViewState();
}

class _FullscreenVideoViewState extends State<FullscreenVideoView> {
  // media_kit (libmpv) — same engine that works for story videos. IMPORTANT:
  // play a LOCAL cached file, not the network URL directly. Streaming the URL
  // rendered a BLACK frame (audio only) on iOS; the cached local file renders.
  final mk.Player _player = mk.Player();
  late final mkv.VideoController _videoController = mkv.VideoController(
    _player,
  );
  bool _ready = false;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _errorSub = _player.stream.error.listen((e) {
      logVideoError('chat_fullscreen', e, url: widget.videoUrl);
    });
    _open();
  }

  Future<void> _open() async {
    // Cache to a local file first (story-proven path) — fixes the black video.
    String playPath = widget.videoUrl;
    try {
      final cached = await VideoCacheService.instance.getCachedPath(
        widget.videoUrl,
      );
      if (cached != null) {
        playPath = cached;
      } else {
        final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
        playPath = file.path;
      }
    } catch (_) {
      playPath = widget.videoUrl; // stream as a last resort
    }
    try {
      await _player.setPlaylistMode(mk.PlaylistMode.loop);
      await _player.open(mk.Media(playPath), play: true);
      await _player.play();
      // media_kit iOS quirk: the FIRST frame can stay black until the video
      // texture gets nudged (dragging the seek bar / the loop restart fixes it).
      // Once the video has real dimensions, a tiny seek forces it to paint.
      _nudgeFirstFrame();
    } catch (e, st) {
      logVideoError('chat_fullscreen_open', e, url: widget.videoUrl, stack: st);
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _nudgeFirstFrame() async {
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      final w = _player.state.width ?? 0;
      if (w > 0) {
        // Video is decoded → seek a hair forward then back to force a repaint.
        final pos = _player.state.position;
        await _player.seek(pos + const Duration(milliseconds: 1));
        await _player.play();
        return;
      }
    }
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_player.state.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${two(d.inHours)}:$m:$s' : '$m:$s';
  }

  // Bottom control bar — driven by the media_kit player (in-sync), kept inside
  // SafeArea so it never goes off-screen (the default controls did).
  Widget _buildControls() {
    return StreamBuilder<Duration>(
      stream: _player.stream.position,
      builder: (context, snap) {
        final pos = snap.data ?? _player.state.position;
        final dur = _player.state.duration;
        final maxMs = dur.inMilliseconds <= 0 ? 1 : dur.inMilliseconds;
        final val = (pos.inMilliseconds / maxMs).clamp(0.0, 1.0);
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Row(
            children: [
              StreamBuilder<bool>(
                stream: _player.stream.playing,
                builder: (context, s) {
                  final playing = s.data ?? _player.state.playing;
                  return GestureDetector(
                    onTap: _togglePlay,
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  );
                },
              ),
              SizedBox(width: 8.w),
              Text(
                _fmt(pos),
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                    activeTrackColor: const Color(0xFFAB50F6),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: val,
                    onChanged: (v) {
                      _player.seek(Duration(milliseconds: (v * maxMs).round()));
                    },
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                _fmt(dur),
                style: GoogleFonts.notoSans(
                  color: Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Keep the media_kit Video widget mounted from the START so its
            // texture is attached before the player produces frames — otherwise
            // the first frame rendered into an unmounted texture and stayed
            // black until a seek/loop. The loader is just an overlay on top.
            Positioned.fill(
              child: GestureDetector(
                onTap: _ready ? _togglePlay : null,
                child: mkv.Video(
                  controller: _videoController,
                  fit: BoxFit.contain,
                  controls: mkv.NoVideoControls,
                ),
              ),
            ),
            if (!_ready)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Get.back();
                },
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    "assets/svg/icons/back_icon.svg",
                    width: 22.r,
                    height: 22.r,
                  ),
                ),
              ),
            ),
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16.h,
                child: _buildControls(),
              ),
          ],
        ),
      ),
    );
  }
}

final Map<String, Uint8List> _videoThumbCache = {};

class YoutubeStyleVideoThumb extends StatefulWidget {
  final String url; // remote video url
  final double width;
  final double height;
  final BorderRadius? radius;

  const YoutubeStyleVideoThumb({
    super.key,
    required this.url,
    this.width = 220,
    this.height = 220,
    this.radius,
  });

  @override
  State<YoutubeStyleVideoThumb> createState() => _YoutubeStyleVideoThumbState();
}

class _YoutubeStyleVideoThumbState extends State<YoutubeStyleVideoThumb> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> _thumbCacheFile(String url) async {
    final dir = await getTemporaryDirectory();
    final hash = url.hashCode.toRadixString(16);
    return File('${dir.path}/chat_vthumb_$hash.jpg');
  }

  /// Generate a thumbnail straight from the remote URL. On iOS video_thumbnail
  /// uses AVURLAsset, which STREAMS only the bytes it needs (range requests) —
  /// so the whole video is NOT downloaded. (The earlier blank result was from
  /// timeMs:0; a small non-zero time works.)
  Future<Uint8List?> _captureFirstFrame(String url) async {
    try {
      final data = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: 70,
        maxWidth: widget.width.toInt(),
        timeMs: 1000,
      );
      log('🖼️ thumb url: bytes=${data?.length ?? 0}');
      if (data != null && data.isNotEmpty) return data;

      // Some videos return null at 1s (very short clips) — retry at the start.
      final data0 = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: 70,
        maxWidth: widget.width.toInt(),
        timeMs: 100,
      );
      log('🖼️ thumb url@100: bytes=${data0?.length ?? 0}');
      return data0;
    } catch (e) {
      logVideoError('chat_thumb_capture', e, url: url);
      return null;
    }
  }

  Future<void> _load() async {
    try {
      // 1) In-memory cache.
      if (_videoThumbCache.containsKey(widget.url)) {
        setState(() {
          _bytes = _videoThumbCache[widget.url];
          _loading = false;
        });
        return;
      }

      // 2) Disk cache (survives app restarts — no regeneration).
      final cacheFile = await _thumbCacheFile(widget.url);
      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        _videoThumbCache[widget.url] = bytes;
        if (!mounted) return;
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
        return;
      }

      // 3) Capture the FIRST FRAME via media_kit. libmpv STREAMS the URL —
      // it fetches only enough to decode one frame, NOT the whole video like
      // video_thumbnail (which needs the full local file on iOS). The result is
      // disk-cached (step 2) so every later view is instant.
      final data = await _captureFirstFrame(widget.url);

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _error = true;
          _loading = false;
        });
        return;
      }

      _videoThumbCache[widget.url] = data;
      // Persist to disk for next time (fire-and-forget).
      cacheFile.writeAsBytes(data, flush: true).catchError((_) => cacheFile);

      setState(() {
        _bytes = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? BorderRadius.circular(10);
    if (_loading) {
      return ClipRRect(
        borderRadius: radius,
        child: ShimmerPlaceholder(width: widget.width, height: widget.height),
      );
    }
    if (_error || _bytes == null) {
      // fallback grey with play icon
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: Colors.black12,
          child: const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 64,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_bytes!, fit: BoxFit.cover),
          // top/bottom dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black38],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ---- URL detection & linkified text (top-level helpers) ----

final _chatUrlRegex = RegExp(r'https?://[^\s<>\"]+', caseSensitive: false);

const _appMediaHost = 'myoutspotbucket.s3';

bool _isAppMediaUrl(String url) => url.contains(_appMediaHost);

bool _looksLikeImageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp');
}

bool _looksLikeVideoUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.webm');
}

void _handleChatUrlTap(String url) {
  if (_isAppMediaUrl(url)) {
    if (_looksLikeImageUrl(url)) {
      Get.to(() => FullscreenImageView(imageUrl: url));
    } else if (_looksLikeVideoUrl(url)) {
      Get.to(() => FullscreenVideoView(videoUrl: url));
    } else {
      Get.to(() => FullscreenImageView(imageUrl: url));
    }
  } else {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff1A0520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Open External Link',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This link will open outside the app:',
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              url.length > 80 ? '${url.substring(0, 80)}...' : url,
              style: TextStyle(color: const Color(0xff56B4FF), fontSize: 12.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: Text(
              'Open',
              style: TextStyle(
                color: const Color(0xff56B4FF),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildLinkifiedText(String text) {
  // Strip any unpaired UTF-16 surrogates (broken/truncated emoji from the
  // backend) — they crash Flutter's text engine with
  // "string is not well-formed UTF-16".
  text = text.sanitizeUtf16();
  final matches = _chatUrlRegex.allMatches(text).toList();

  if (matches.isEmpty) {
    return Text(
      text,
      softWrap: true,
      style: GoogleFonts.notoSans(color: AppColors.white, fontSize: 14.sp),
    );
  }

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  for (final match in matches) {
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.notoSans(color: AppColors.white, fontSize: 14.sp),
        ),
      );
    }

    final url = match.group(0)!;
    spans.add(
      TextSpan(
        text: url,
        style: GoogleFonts.notoSans(
          color: const Color(0xff56B4FF),
          fontSize: 14.sp,
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xff56B4FF),
        ),
        recognizer:
            (TapGestureRecognizer()..onTap = () => _handleChatUrlTap(url)),
      ),
    );

    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.notoSans(color: AppColors.white, fontSize: 14.sp),
      ),
    );
  }

  final mediaUrls =
      matches
          .map((m) => m.group(0)!)
          .where((u) => _looksLikeImageUrl(u) || _looksLikeVideoUrl(u))
          .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(TextSpan(children: spans), softWrap: true),
      for (final url in mediaUrls)
        Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: GestureDetector(
            onTap: () => _handleChatUrlTap(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 220.w,
                height: 160.h,
                child:
                    _looksLikeImageUrl(url)
                        ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerPlaceholder(),
                          errorWidget:
                              (_, __, ___) => Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                        )
                        : Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.black54),
                            Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 48.sp,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              left: 8,
                              child: Text(
                                'Video',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// Swipe a chat bubble to the right to reply (WhatsApp-style). The bubble
/// follows the finger, a reply icon fades in, and on release past the trigger
/// it fires [onReply] and elastically snaps back to its original position.
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  const _SwipeToReply({super.key, required this.child, required this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;
  bool _fired = false;
  static const double _max = 64;
  static const double _trigger = 48;

  void _onUpdate(DragUpdateDetails d) {
    // Left swipe → negative offset.
    setState(() => _dx = (_dx + d.delta.dx).clamp(-_max, 0.0));
    if (!_fired && _dx <= -_trigger) {
      _fired = true;
      HapticFeedback.selectionClick();
    }
  }

  void _onEnd(DragEndDetails d) {
    if (_fired) widget.onReply();
    _fired = false;
    setState(() => _dx = 0); // snap back (animated below)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned(
            right: 16,
            child: Opacity(
              opacity: (_dx.abs() / _trigger).clamp(0.0, 1.0),
              child: const Icon(
                Icons.reply,
                color: Color(0xffC574F7),
                size: 22,
              ),
            ),
          ),
          AnimatedContainer(
            // Follow the finger instantly while dragging; smooth elastic
            // snap-back when released (_dx == 0).
            duration:
                _dx == 0 ? const Duration(milliseconds: 180) : Duration.zero,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
