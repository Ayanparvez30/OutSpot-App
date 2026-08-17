import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_svg/svg.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/point_submit_Dialog.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_or_submid_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class SendSubmitchallange extends StatelessWidget {
  SendSubmitchallange({super.key});
  final controller = Get.put(SendorSubmidController());

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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            color: Colors.white,
            onPressed: () {
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

          title: GestureDetector(
            onTap: () {
              Get.toNamed(Routes.selectChallenge);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 17.w),
              height: 35.h,
              width: 260.w,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(25.sp),
              ),

              child: Row(
                children: [
                  // Image.asset(
                  //   "assets/Images/skaidss.png",
                  //   height: 20.h,
                  //   width: 20.w,
                  // ),
                  SvgPicture.asset(
                    "assets/svg/award.svg",
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    "Select a Challenge",
                    style: GoogleFonts.notoSans(
                      fontSize: 16.sp,
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 25.w),
                  SvgPicture.asset(
                    "assets/svg/icons/arrow_forward_icon.svg",
                    width: 16,
                    height: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Obx(() {
                final c = controller.selectedChallenges.value;
                if (c == null) {
                  return GestureDetector(
                    onTap: () => Get.toNamed(Routes.selectChallenge),
                    child: Container(
                      height: 24.h,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.fillcolor),
                      child: Text(
                        "No challenge selected!",
                        style: GoogleFonts.notoSans(
                          fontSize: 12.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.all(15.w),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        bottom: BorderSide(color: Color(0xffF4F4F4), width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    c.frequency.toUpperCase() == "DAILY"
                                        ? AppColors.SecondaryColor
                                        : AppColors.skyblue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c.frequency.toUpperCase() == "DAILY"
                                    ? "Daily Challenge"
                                    : "Weekly Challenge",
                                // "${c.frequency} Challenge",
                                style: GoogleFonts.notoSans(
                                  color: AppColors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            Spacer(),

                            SvgPicture.asset(
                              "assets/svg/Time.svg",
                              width: 10,
                              height: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              controller.formatTimeRemaining(c.timeRemainingMs),
                              style: GoogleFonts.notoSans(
                                color: AppColors.timeColor,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(width: 6),
                          ],
                        ),

                        SizedBox(height: 7.h),

                        Text(
                          c.title,
                          style: GoogleFonts.notoSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),

                        SizedBox(height: 3.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.preview,
                                    style: GoogleFonts.notoSans(
                                      fontSize: 14.sp,
                                      color: AppColors.tex,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "${c.uploadedCount}/${c.requiredCount}",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                controller.selectchallengeId(c);
                              },
                              child: Obx(() {
                                return Container(
                                  height: 35.w,
                                  width: 35.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        controller.selectindex1.value
                                            ? AppColors.skyblue
                                            : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          controller.selectindex1.value
                                              ? Colors.transparent
                                              : AppColors.fillnoti,
                                      width: 1.2.w,
                                    ),
                                  ),
                                  child:
                                      controller.selectindex1.value
                                          ? Icon(
                                            Icons.check,
                                            color: AppColors.white,
                                            size: 17.sp,
                                          )
                                          : null,
                                );
                              }),
                            ),
                          ],
                        ),

                        SizedBox(height: 5.h),

                        /// Status & Reward
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.fillcolor,
                                border: Border.all(
                                  color: AppColors.fillnoti,
                                  width: 1.4.w,
                                ),
                                borderRadius: BorderRadius.circular(14.sp),
                              ),
                              child: Text(
                                c.status.toLowerCase() == "completed"
                                    ? "Completed"
                                    : "Incomplete",
                                style: GoogleFonts.notoSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            c.status.toLowerCase() == "completed"
                                ? Text(
                                  "Reward Received",
                                  style: GoogleFonts.notoSans(
                                    color: AppColors.grey,
                                    fontSize: 13.sp,
                                  ),
                                )
                                : Text(
                                  "Complete to get",
                                  style: GoogleFonts.notoSans(
                                    color: AppColors.grey,
                                    fontSize: 13.sp,
                                  ),
                                ),
                            SizedBox(width: 4),
                            // if (c.status!.toLowerCase() == "incomplete")
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: AppColors.yellow,
                                  width: 1.2.w,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/svg/Icon-Outline-Coin-P.svg",
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    compactNumber(c.points),
                                    style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              }),

              // Show "Submit for Points" ONLY when a place was checked in from
              // Explore. A plain/direct camera capture has no place to earn
              // points for, so the whole option is hidden in that case.
              Obx(() {
                if (controller.targetPlace.value == null ||
                    controller.targetCategoryKey.value == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  // Right padding so the toggle / "Try again in mm:ss" countdown
                  // doesn't sit flush against the screen edge.
                  padding: EdgeInsets.only(left: 15.w, right: 16.w, top: 8.h),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/Images/submitPointLebel.png",
                        scale: 21,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        "Submit for Points",
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: AppColors.white,
                        ),
                      ),
                      const Spacer(),
                      // On cooldown → show a live "Try again in mm:ss" countdown
                      // instead of the toggle (and don't allow selecting it).
                      if (!controller.canSubmitPoints.value)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Try again in ",
                              style: GoogleFonts.notoSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            // Monospace timer — fixed-width digits, no jitter.
                            Text(
                              controller.submitCooldownLabel,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            controller.selectindex.value =
                                !controller.selectindex.value;
                          },
                          child: Container(
                            height: 35.w,
                            width: 35.w,
                            decoration: BoxDecoration(
                              color:
                                  controller.selectindex.value
                                      ? AppColors.skyblue
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    controller.selectindex.value
                                        ? Colors.transparent
                                        : AppColors.fillnoti,
                                width: 1.7.w,
                              ),
                            ),
                            child:
                                controller.selectindex.value
                                    ? Icon(
                                      Icons.check,
                                      color: AppColors.white,
                                      size: 17.sp,
                                    )
                                    : null,
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // ... বাকি কোড ...
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.only(left: 18.w),
                child: Divider(thickness: 1.h, color: AppColors.fillnoti),
              ),
              SizedBox(height: 5.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: CustomTextField(
                  hintText: "Search chats…",
                  controller: controller.searchController,
                  onChanged: (value) {
                    controller.searchText.value = value;
                    controller.filterChats(value);
                  },
                  suffixIcon: UnconstrainedBox(
                    child: SvgPicture.asset(
                      "assets/svg/Icon-Outline-Search.svg",
                      width: 18.w,
                      height: 19.w,
                      // fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (controller.isLoadingChats.value) {
                    return ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 16.w),

                              Expanded(
                                child: Container(
                                  height: 14.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 30.w),

                              Container(
                                height: 30.w,
                                width: 30.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  final chats = controller.filteredChatss;

                  return ListView.builder(
                    itemCount: chats.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Row(
                                children: [
                                  _buildAvatar(controller.avatarUrl.value),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Text(
                                      "My Story",
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (controller.selectedIndexes.contains(
                                        -1,
                                      )) {
                                        controller.selectedIndexes.remove(-1);
                                        controller.postToStory.value = false;
                                      } else {
                                        controller.selectedIndexes.add(-1);
                                        controller.postToStory.value = true;
                                      }
                                    },
                                    child: Obx(() {
                                      bool isSelected = controller
                                          .selectedIndexes
                                          .contains(-1);
                                      return Container(
                                        height: 35.w,
                                        width: 35.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isSelected
                                                  ? AppColors.skyblue
                                                  : AppColors.fillcolor,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.transparent
                                                    : AppColors.fillnoti,
                                            width: 1.2.w,
                                          ),
                                        ),
                                        child:
                                            isSelected
                                                ? Icon(
                                                  Icons.check,
                                                  color: AppColors.white,
                                                  size: 17.sp,
                                                )
                                                : null,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Divider(
                              height: 1.h,
                              thickness: 1.h,
                              color: AppColors.fillnoti,
                              indent: 18.w,
                              endIndent: 16,
                            ),
                          ],
                        );
                      }

                      final chatIndex = index - 1;
                      final chat = chats[chatIndex];
                      final bool isLocked = chat.isLocked;

                      final bool isGroup = chat.isGroup;
                      final bool isCommunity = chat.isCommunity;
                      final String displayName =
                          (isGroup || isCommunity)
                              ? (chat.name?.trim().isNotEmpty == true
                                  ? chat.name!.trim()
                                  : 'Unknown')
                              : controller.getUserName(chat);

                      final String? avatarUrl = controller.getChatAvatar(
                        chat,
                        controller.currentUserId.value,
                      );

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            child: Row(
                              children: [
                                _buildAvatar(
                                  avatarUrl,
                                  isGroup: chat.isGroup,
                                  isCommunity: chat.isCommunity,
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        ellipsizeByCharsname(displayName),
                                        style: GoogleFonts.notoSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.sp,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      if (isGroup || isCommunity) ...[
                                        SizedBox(width: 6.w),
                                        SvgPicture.asset(
                                          "assets/svg/Icon-Solid-User.svg",
                                          width: 12.w,
                                          height: 11.w,
                                          // fit: BoxFit.scaleDown,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "${chat.users.length}",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.yellow,
                                          ),
                                        ),
                                        if (chat.isGroup && chat.isLocked)
                                          Padding(
                                            padding: EdgeInsets.only(left: 6.w),
                                            child: Icon(
                                              Icons.lock,
                                              size: 14.sp,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // if (controller.selectedChatIds.contains(
                                    //   chat.id,
                                    // )) {
                                    //   controller.selectedChatIds.remove(
                                    //     chat.id,
                                    //   );
                                    // } else {
                                    //   controller.selectedChatIds.add(chat.id);
                                    // }
                                    if (isLocked) {
                                      AppSnackbar.info(
                                        "This chat is locked. You cannot send media here.",
                                        title: "Chat Locked",
                                      );
                                    } else {
                                      if (controller.selectedChatIds.contains(
                                        chat.id,
                                      )) {
                                        controller.selectedChatIds.remove(
                                          chat.id,
                                        );
                                      } else {
                                        controller.selectedChatIds.add(chat.id);
                                      }
                                    }
                                  },
                                  child: Obx(() {
                                    bool isSel = controller.selectedChatIds
                                        .contains(chat.id);
                                    return Container(
                                      height: 35.w,
                                      width: 35.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isSel
                                                ? AppColors.skyblue
                                                : AppColors.fillcolor,
                                        border: Border.all(
                                          color:
                                              isSel
                                                  ? AppColors.fillcolor
                                                  : AppColors.fillnoti,
                                          width: 1.2.w,
                                        ),
                                      ),
                                      child:
                                          isSel
                                              ? Icon(
                                                Icons.check,
                                                color: AppColors.white,
                                                size: 17.sp,
                                              )
                                              : null,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1.h,
                            thickness: 1.h,
                            color: AppColors.fillnoti,
                            indent: 18.w,
                            endIndent: 16,
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: GestureDetector(
                  onTap: () async {
                    if (controller.issending.value) return;
                    controller.issending.value = true;
                    // EasyLoading.show(status: 'Sending...', dismissOnTap: false);
                    try {
                      final hasIndex = controller.selectindex.value;
                      final hasOtherSelection =
                          controller.selectedIndexes.isNotEmpty ||
                          controller.selectedChatIds.isNotEmpty ||
                          controller.postToStory.value;
                      final hasChallenge = controller.challengeId.value > 0;

                      // Challenge checkbox is checked but no challenge selected
                      if (controller.selectindex1.value && !hasChallenge) {
                        PointSubmitDialog.showFailed(
                          title: "No Challenge Selected",
                          message:
                              "Please select a challenge first before submitting. Tap 'Select a Challenge' at the top to pick one.",
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orangeAccent,
                          actionText: "Select Challenge",
                          onAction: () {
                            Get.toNamed(Routes.selectChallenge);
                          },
                        );
                        controller.issending.value = false;
                        return;
                      }

                      // ✅ Case 1: Only challenge
                      if (hasChallenge && !hasIndex && !hasOtherSelection) {
                        await controller.submitChallenge(
                          context,
                          controller.challengeId.value,
                        );
                        controller.issending.value = false;
                        return;
                      }
                      // ✅ Case 2: Only index (points)
                      else if (hasIndex &&
                          !hasChallenge &&
                          !hasOtherSelection) {
                        await controller.visitRecorded(
                          controller.targetPlace.value!,
                        );
                        // EasyLoading.dismiss();
                        controller.issending.value = false;
                        return;
                      }
                      // ✅ Case 3: Mixed selections
                      else if (hasIndex || hasOtherSelection || hasChallenge) {
                        // 1) Do the points / challenge submission FIRST. When
                        //    friends/story are ALSO selected, capture any error
                        //    silently (silentError) so it can be shown inside the
                        //    single combined "send to others?" dialog instead of
                        //    as a separate popup.
                        bool ok = true;
                        // Both challenge AND points selected → their two success
                        // dialogs would otherwise stack (the cause of the
                        // errors). Suppress the dialogs whenever we'll show a
                        // snackbar instead: when recipients are selected, OR when
                        // both submits happen together.
                        final bool bothSubmit = hasChallenge && hasIndex;
                        final bool suppressDialogs =
                            hasOtherSelection || bothSubmit;
                        if (hasChallenge) {
                          ok = await controller.submitChallenge(
                            context,
                            controller.challengeId.value,
                            silentError: hasOtherSelection,
                            suppressSuccessDialog: suppressDialogs,
                          );
                        }
                        if (ok && hasIndex) {
                          ok = await controller.visitRecorded(
                            controller.targetPlace.value!,
                            silentError: hasOtherSelection,
                            suppressSuccessDialog: suppressDialogs,
                          );
                        }

                        // 2) Then handle the friends/story selection.
                        if (hasOtherSelection) {
                          // If the points/challenge failed, ask whether to still
                          // send the capture to the selected friends/story.
                          final bool sendOthers =
                              ok ? true : await controller.confirmSendToOthers();
                          if (sendOthers) {
                            await controller.uploadCapturedFile(
                              chatIds:
                                  controller.selectedChatIds.isNotEmpty
                                      ? controller.selectedChatIds
                                      : null,
                              postToStoryFlag: controller.postToStory.value,
                              onSuccessNavigation: () async {
                                if (controller.selectedChatIds.isNotEmpty) {
                                  try {
                                    if (Get.isRegistered<
                                      MessagesScreenController
                                    >()) {
                                      Get.find<MessagesScreenController>()
                                          .fetchChats();
                                    }
                                  } catch (_) {}
                                }
                                // Custom snackbar instead of the full-screen
                                // success dialog, then go to Messages (where the
                                // snap was sent). NOTE: tab 5 is out of range and
                                // fell through to Explore — that was the bug.
                                final submitted =
                                    (hasChallenge || hasIndex) && ok;
                                AppSnackbar.success(
                                  submitted
                                      ? "Points submitted & shared with your selections."
                                      : "Shared with your selections.",
                                );
                                Get.offAllNamed(
                                  Routes.mainscreen,
                                  arguments: {'tab': 0},
                                );
                              },
                            );
                          }
                          // else: stay on screen (nothing sent)
                        } else if (ok) {
                          // Points + challenge both submitted, no recipients.
                          // Don't stack two success dialogs — just a snackbar,
                          // and go to Challenges (NOT Explore; tab 5 was out of
                          // range and fell through to Explore).
                          AppSnackbar.success(
                            "Points & challenge both submitted!",
                          );
                          Get.offAllNamed(
                            Routes.mainscreen,
                            arguments: {'tab': 3},
                          );
                        }
                        return;
                      } else {
                        AppToast.warning("Please select one");
                        // EasyLoading.dismiss();
                      }
                    } catch (e) {
                      log("❌ onTap error: $e");
                      // EasyLoading.dismiss();
                      AppSnackbar.error("Something went wrong");
                    } finally {
                      if (Get.currentRoute != Routes.mainscreen) {
                        controller.issending.value = false;
                      }
                    }
                  },

                  child: Container(
                    height: 46.h,
                    width: double.infinity,
                    // alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.btnGradientLeft,
                          AppColors.btnGradientRight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25.sp),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 140.w),
                          child: Text(
                            "Send",
                            style: GoogleFonts.notoSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 20.w),

                          child: SvgPicture.asset(
                            "assets/svg/icons/send_icon.svg",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 21.h),
            ],
          ),
        ),
      ),
    );
  }

  String ellipsizeByCharsname(String s, {int max = 14}) {
    final chars = s.characters;
    if (chars.length <= max) return s;
    return chars.take(max).toString() + '…'; // or '...'
  }

  Widget CustomTextField({
    required String hintText,
    required Widget suffixIcon,
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    EdgeInsets suffixPadding = const EdgeInsets.only(right: 5),
  }) {
    return TextFormField(
      style: TextStyle(color: AppColors.white),
      onChanged: onChanged,
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.notoSans(
          color: AppColors.fillnoti,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
        ),

        suffixIcon: Padding(padding: suffixPadding, child: suffixIcon),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: BorderSide(color: AppColors.fillnoti),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: BorderSide(color: AppColors.fillnoti),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.sp),
          borderSide: BorderSide(color: AppColors.fillnoti),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    String? url, {
    bool isGroup = false,
    bool isCommunity = false,
  }) {
    final size = 36.w;
    final hasUrl = (url != null && url.isNotEmpty);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.fillcolor,
      ),
      child:
          hasUrl
              ? ClipOval(
                child: CachedNetworkImage(
                  alignment: Alignment.topCenter,
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerPlaceholder(),
                  errorWidget:
                      (_, __, ___) => _fallbackIcon(isGroup, isCommunity),
                ),
              )
              : _fallbackIcon(isGroup, isCommunity),
    );
  }

  Widget _fallbackIcon(bool isGroup, bool isCommunity) {
    return Center(
      child:
          isCommunity
              ? Image.asset("assets/Images/skcunny.png", width: 36.w)
              : isGroup
              ? Image.asset("assets/Images/newGroup.png", width: 36.w)
              : Icon(Icons.person, color: Colors.grey, size: 25.sp),
    );
  }
}
