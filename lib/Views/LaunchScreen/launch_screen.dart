import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/LaunchScreen/launch_controller.dart';

class LaunchScreen extends GetView<LaunchController> {
  const LaunchScreen({super.key});

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
        body: SafeArea(
          top: false,
          child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            children: [
              SizedBox(height: 110.h),
              Image.asset("assets/Images/logoImage.png", scale: 3.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Out",
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.w300,
                      fontSize: 60.sp,
                      color: Color(0xffAB50F6),
                    ),
                  ),
                  customColoredText(context),
                ],
              ),

              SizedBox(height: 20.h),

              Text(
                "Spot and be Spotted in your city’s best\nrestaurants, bars, and clubs. OutSpot rivals,\nrack up points, level up. Be everywhere they aren’t.",
                textAlign: TextAlign.center,

                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                ),
              ),
              Spacer(),

              CustomWidgets().CustomButton(
                text: "Get Started",
                onPressed: () {
                  Get.toNamed(Routes.signUpScreen);
                },
              ),
              SizedBox(height: 10.h),
              CustomButton2(
                text: "Log In",
                onPressed: () {
                  Get.toNamed(Routes.loginScreen);
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget CustomButton2({
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 45.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffFF8364), Color(0xffFFB14D)],
          ),
          borderRadius: BorderRadius.circular(30.r),
          // border: Border.all(color: Color(0xFF66CCFC), width: 2.w),
        ),
        child: Text(
          text,
          style: GoogleFonts.notoSans(
            fontSize: 16.sp,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class SpotTextGradient extends StatelessWidget {
  const SpotTextGradient({super.key});

  final List<Color> _textGradientColors = const [
    Color(0xffAB50F6),
    Color(0xffD972D7),
    Color(0xffE97F9E),
    Color(0xffFB7D6C),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _textGradientColors,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            "Spot",
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w600,
              fontSize: 60.sp,

              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

Widget customColoredText(BuildContext context) {
  final List<Color> textGradientColors = [
    const Color(0xffAB50F6),
    const Color(0xffD972D7),
    const Color(0xffE97F9E),
    const Color(0xffFB7D6C),
  ];

  return Container(
    child: Center(
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: textGradientColors,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
        },
        blendMode: BlendMode.srcIn,
        child: Text(
          "Spot",
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            fontSize: 60.sp,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
