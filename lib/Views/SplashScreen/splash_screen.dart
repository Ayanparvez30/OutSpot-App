import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/SplashScreen/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // SvgPicture.asset("assets/svg/logo.svg", width: 180.w, height: 180.w),
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
            ],
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
