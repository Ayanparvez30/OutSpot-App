import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';

class GroupeditOptionsSheet {
  static void show({
    required BuildContext context,
    required int groupId,
    required String groupName,
    required RxBool isAdmin,
    required RxBool isLocked,
    required RxBool isMuted,
    required Function() onLockToggle,
    required Function() onMuteToggle,
    required Function() onLeave,
    required bool isGroup,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Group Options",
                    style: GoogleFonts.notoSans(
                      color: AppColors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                const Divider(color: Colors.white10, height: 1),
                if (isGroup)
                  Obx(
                    () =>
                        isAdmin.value
                            ? _buildItem(
                              text: "Edit Group Details",
                              color: AppColors.backgroundColor,
                              onTap: () {
                                Get.back();
                                Get.toNamed(
                                  Routes.newGroupScreen,
                                  arguments: {
                                    "isedit": true,
                                    "groupId": groupId,
                                    "groupName": groupName,
                                  },
                                );
                              },
                            )
                            : const SizedBox.shrink(),
                  ),

                Obx(
                  () =>
                      isAdmin.value
                          ? _buildItem(
                            text: isLocked.value ? "Unlock Chat" : "Lock Chat",
                            color: AppColors.backgroundColor,
                            onTap: () {
                              Get.back();
                              onLockToggle();
                            },
                          )
                          : const SizedBox.shrink(),
                ),

                /// Mute / Unmute Chat
                Obx(
                  () => _buildItem(
                    text: isMuted.value ? "Unmute Chat" : "Mute Chat",
                    color: AppColors.backgroundColor,
                    onTap: () {
                      Get.back();
                      onMuteToggle();
                    },
                  ),
                ),

                /// Leave Group
                 if (isGroup)
                _buildItem(
                  text: "Leave Group",
                  color: AppColors.darkred,
                  onTap: () {
                    Get.back();
                    onLeave();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildItem({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.notoSans(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
