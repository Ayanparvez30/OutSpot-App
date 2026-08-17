import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Camerascreen/camerascreen_controller.dart';

class PhotoSubmitScreen extends GetView<CamerascreenController> {
  const PhotoSubmitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔵 Background (blue image)
          Positioned.fill(
            child: Container(
              color: Color(0xff23A8FA), // এখানে আপনার blue color দিন
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Center(
                  child: Text(
                    "Submitted",
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      color: Color(0xffFFFFFF),
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 🔝 Main Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 17.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.sp),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fireworks image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.sp),
                      child: Image.asset(
                        "assets/Images/sksubmit.png", // top image (fireworks & phone)
                        width: double.infinity,
                        height: 180.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Title
                    Text(
                      "Submission Complete!",
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff000000),
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Subtitle (coin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "You received ",
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff000000),
                            fontSize: 14.sp,
                          ),
                        ),
                        Image.asset(
                          "assets/Images/skcoin.png",
                          width: 18,
                          height: 18,
                        ),
                        SizedBox(width: 3),
                        Text(
                          "4",
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff000000),
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // View Challenge button
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.sp),
                        color: Color(0xffF8AC00),
                      ),
                      width: double.infinity,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () {
                          // Handle tap
                        },
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20.w),
                              child: Image.asset(
                                "assets/Images/aodssk.png",
                                scale: 2.5,
                              ),
                            ),
                            SizedBox(width: 10),
                            Padding(
                              padding: EdgeInsets.only(left: 65.w),
                              child: Text(
                                "View Challenge",
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffFFFFFF),
                                  fontSize: 14.sp, // .sp চাইলে ব্যবহার করুন
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    // View Leaderboard button
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.sp),
                        color: Color(0xff66CCFC),
                      ),
                      width: double.infinity,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () {
                          // Handle tap
                        },
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20.w),
                              child: Image.asset(
                                "assets/Images/sktaole.png",
                                scale: 2.5,
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(left: 65.w),
                              child: Text(
                                "View Leaderboard",
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffFFFFFF),
                                  fontSize: 14.sp, // .sp চাইলে ব্যবহার করুন
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),
                    // Back to Camera link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.back();
                          },
                          child: Icon(Icons.arrow_back_ios, size: 17.sp),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.offAllNamed(
                              Routes.mainscreen,
                              arguments: {"tab": 2},
                            );
                          },
                          child: Text(
                            "Back to Camera",
                            style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.w800,
                              color: Color(0xff000000),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
