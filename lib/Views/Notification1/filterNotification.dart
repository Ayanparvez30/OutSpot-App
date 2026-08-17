import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';

import 'package:outspot/Views/Notification1/notification_controller.dart';

class Filternotification extends GetView<Notification1Controller> {
  Filternotification({super.key});

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
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          title: Padding(
            padding: EdgeInsets.only(left: 26.w),
            child: Text(
              "Filter Notifications",
              style: GoogleFonts.notoSans(
                fontSize: 17.7.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Padding(
              padding: EdgeInsets.all(12.h),
              child: SvgPicture.asset(
                'assets/svg/icons/back_icon.svg',
                height: 18.h,
                width: 18.w,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 13.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      ...List.generate(controller.notificationOptions.length, (
                        index,
                      ) {
                        return Obx(
                          () => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    height: 40.sp,
                                    width: 40.sp,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      gradient:
                                          controller
                                                      .selectedNotificationIndex
                                                      .value ==
                                                  index
                                              ? LinearGradient(
                                                colors: [
                                                  AppColors.btnGradientLeft,
                                                  AppColors.btnGradientRight,
                                                ],
                                              )
                                              : null,

                                      color:
                                          controller
                                                      .selectedNotificationIndex
                                                      .value ==
                                                  index
                                              ? null
                                              : Color(0xff3E165B),

                                      border: Border.all(
                                        color:
                                            controller
                                                        .selectedNotificationIndex
                                                        .value ==
                                                    index
                                                ? Colors.transparent
                                                : Color(0xff3E165B),
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        controller
                                                    .selectedNotificationIndex
                                                    .value ==
                                                index
                                            ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 24.sp,
                                            )
                                            : null,
                                  ),

                                  title: Text(
                                    controller.notificationOptions[index],
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    controller.selectedNotificationIndex.value =
                                        index;
                                  },
                                ),
                                SizedBox(height: 5.h),
                              ],
                            ),
                          ),
                        );
                      }),

                      Divider(
                        thickness: .6.h,
                        color: Color(0xFF8E21EA),
                        height: 24.h,
                      ),

                      ...List.generate(controller.typeOptions.length, (index) {
                        return Obx(
                          () => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    height: 40.sp,
                                    width: 40.sp,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      gradient:
                                          controller.selectedTypeIndex.value ==
                                                  index
                                              ? LinearGradient(
                                                colors: [
                                                  AppColors.btnGradientLeft,
                                                  AppColors.btnGradientRight,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                              : null,

                                      color:
                                          controller.selectedTypeIndex.value ==
                                                  index
                                              ? null
                                              : Color(0xff3E165B),

                                      border: Border.all(
                                        color:
                                            controller
                                                        .selectedTypeIndex
                                                        .value ==
                                                    index
                                                ? Colors.transparent
                                                : Color(0xff3E165B),
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        controller.selectedTypeIndex.value ==
                                                index
                                            ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 24.sp,
                                            )
                                            : null,
                                  ),

                                  title: Text(
                                    controller.typeOptions[index],
                                    style: GoogleFonts.notoSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onTap: () {
                                    controller.selectedTypeIndex.value = index;
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      Divider(
                        thickness: .6.h,
                        color: Color(0xFF8E21EA),
                        height: 24.h,
                      ),

                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            await controller.clearAllNotifications();
                            Get.back();
                          },

                          child: SizedBox(
                            width: 200.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 13.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Clear All Notifications',
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    // 1. Apply the decoration with Gradient here
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.btnGradientLeft,
                          AppColors.btnGradientRight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // 2. Make the button background and shadow transparent
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: () {
                        controller.loadNotifications();
                        Get.back();
                      },
                      child: Text(
                        'Filter Notifications',
                        style: TextStyle(fontSize: 16.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
