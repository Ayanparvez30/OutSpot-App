import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';
import 'package:outspot/Views/Create_Mini_Me/create_mini_me_controller.dart';

class TakeSelfie extends GetView<CreateMiniMeController> {
  const TakeSelfie({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        controller.pickimages.value = '';
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        // backgroundColor: Color(0xffFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(12.sp),
            child: GestureDetector(
              onTap: () {
                Get.back();
                controller.pickimages.value = '';
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset("assets/svg/icons/back_icon.svg"),
              ),
            ),
          ),
          title: Text(
            "Take a Selfie",
            style: GoogleFonts.notoSans(
              // fontSize: 18.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
              stops: [0.2, 0.6],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 70.h),
                  Text(
                    "Snap a photo to generate an avatar that looks like you!",
                    style: GoogleFonts.notoSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Align your face to the center.",
                    style: GoogleFonts.notoSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40.h),
                  GestureDetector(
                    onTap: () {
                      // controller.pickImagecamera();
                    },
                    child: Obx(() {
                      if (controller.pickimages.value.isEmpty) {
                        // No image picked yet — show placeholder
                        return Container(
                          width: double.infinity,
                          height: 280.h,
                          decoration: BoxDecoration(
                            color: AppColors.inputFillColor,
                            border: Border.all(
                              color: Colors.amber,
                              width: 1.5.w,
                            ),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/Images/blockCamera.png",
                                  color: Colors.white,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "Allow access to your\ndevice’s camera.",
                                  style: GoogleFonts.notoSans(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Image picked — show the image
                        return Container(
                          width: double.infinity,
                          height: 280.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.amber, width: 2.w),
                            borderRadius: BorderRadius.circular(15.r),
                            image: DecorationImage(
                              image: FileImage(
                                File(controller.pickimages.value),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }
                    }),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 45.h,
                    // বাটনটিকে একটি কন্টেইনারে মুড়িয়ে গ্রেডিয়েন্ট দেওয়া হলো
                    child: Container(
                      decoration: BoxDecoration(
                        // image_5.png এর মতো কমলা গ্রেডিয়েন্ট
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF7E5F), // বাম পাশের গাঢ় কমলা
                            Color(0xFFFEB47B), // ডান পাশের হালকা কমলা
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (controller.pickimages.value.isEmpty) {
                            controller.pickImagecamera();
                          } else {
                            await controller.uploadAvatarToServeres();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        child: Obx(() {
                          return controller.pickimages.value.isEmpty
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/Images/Page-1.png",
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    "Capture",
                                    style: GoogleFonts.notoSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                              : Text(
                                "Next",
                                style: GoogleFonts.notoSans(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              );
                        }),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
