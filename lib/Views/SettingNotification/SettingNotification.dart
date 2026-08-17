import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/SettingNotification/SettingNotification_controller.dart';
import 'package:outspot/Views/SettingScreen/setting_controller.dart';
import '../../CommonWidgets/CustomWidgets/customWidget.dart';
import '../../Utils/colors.dart';
import 'package:shimmer/shimmer.dart';

class Settingnotification extends GetView<SettingnotificationController> {
  const Settingnotification({super.key});

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
          title: Text(
            'Notifications',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Text(
                  "Push Notifications",
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 15.h),
                Obx(() {
                  // if (controller.isLoading.value) {
                  //   return Shimmer.fromColors(
                  //     baseColor: Colors.white.withOpacity(0.2),
                  //     highlightColor: Colors.white.withOpacity(0.5),
                  //     child: Container(
                  //       height: 41.h,
                  //       width: 78.w,
                  //       decoration: BoxDecoration(
                  //         color: Colors.white,
                  //         borderRadius: BorderRadius.circular(30.r),
                  //       ),
                  //     ),
                  //   );
                  // }

                  return GestureDetector(
                    onTap: controller.togglePushNotification,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: 78.w,
                      height: 41.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.r),
                        color:
                            controller.isPushNotificationEnabled.value
                                ? const Color(0xff704EF9)
                                : const Color(0xff703A8B),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            left:
                                controller.isPushNotificationEnabled.value
                                    ? 32.w
                                    : 2.w,
                            right:
                                controller.isPushNotificationEnabled.value
                                    ? 2.w
                                    : 32.w,
                            child: Container(
                              width: 34.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Spacer(),

                Obx(() {
                  final enabled = controller.hasChanged.value;
                  final isSaving = controller.isSaving.value;

                  return Opacity(
                    opacity: enabled ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !enabled || isSaving,
                      child: CustomWidgets().CustomButton(
                        text: isSaving ? "Saving..." : "Save",
                        onPressed: () {
                          controller.saveSettings();
                        },
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
