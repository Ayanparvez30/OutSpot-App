import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class Choosebodytype extends GetView<CreateprofileController> {
  const Choosebodytype({super.key});

  // --- Color Palette based on Image 2 ---
  final Color _bgGradientTop = const Color(0xff2E0248);
  final Color _bgGradientBottom = const Color(0xff5A2D85);
  final Color _containerBg = const Color(0xff1A0B2E);
  final Color _unselectedBorder = const Color(0xff4A255F);
  final Color _textColorPrimary = Colors.white;
  final Color _textColorSecondary = const Color(0xffD0C0D8);
  final Color _gradientStart = const Color(0xffDA5EF3);
  final Color _gradientEnd = const Color(0xffFF8D7E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(12.sp),
          child: CustomBackButton(),
        ),
        title: Text(
          "Choose Your Body Type",
          style: GoogleFonts.notoSans(
            color: _textColorPrimary,
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
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 50.h),
                        Obx(
                          () => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _genderButton(
                                imagePath:
                                    "assets/svg/icons/Icon-Outline-Male.svg",
                                label: "Masculine",
                                isSelected:
                                    controller.selectedGender.value ==
                                    "Masculine",
                                onTap: () => controller.setGender('Masculine'),
                              ),
                              SizedBox(height: 20.h),
                              _genderButton(
                                imagePath:
                                    "assets/svg/icons/Icon-Outline-Female.svg",
                                label: "Feminine",
                                isSelected:
                                    controller.selectedGender.value ==
                                    "Feminine",
                                onTap: () => controller.setGender('Feminine'),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                        // --- Info Container ---
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 30.h,
                            horizontal: 25.w,
                          ),
                          decoration: BoxDecoration(
                            color: _containerBg,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.sp),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.question_mark,
                                  size: 24.sp,
                                  color: _containerBg,
                                ),
                              ),
                              SizedBox(height: 15.h),
                              Text(
                                "Why do we ask this?",
                                style: GoogleFonts.notoSans(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _textColorPrimary, // সাদা
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "Outspot users chat and explore the world with their unique avatars called Mini-Mes.\n\nSpecifying your body type helps us create a Mini-Me that resembled you!",
                                style: GoogleFonts.notoSans(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: _textColorSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30.h),

                // --- Gradient Continue Button ---
                Container(
                  width: double.infinity,
                  height: 45.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradientStart, _gradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.selectedGender.value.isNotEmpty) {
                        controller.submitBodyType();

                        // Ensure body shapes are loaded before navigating
                        await controller.fetchBodyShapes();

                        final gender = controller.selectedGender.value;
                        if (gender == 'Masculine') {
                          Get.toNamed(Routes.masculineBody);
                        } else if (gender == 'Feminine') {
                          Get.toNamed(Routes.feminineBody);
                        }
                      } else {
                        AppSnackbar.info(
                          "Please select a body type to continue.",
                          title: "Selection Needed",
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.notoSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderButton({
    required String imagePath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [_gradientStart, _gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30.r),
    );
    final normalDecoration = BoxDecoration(
      color: _containerBg,
      border: Border.all(color: _unselectedBorder, width: 1.5.w),
      borderRadius: BorderRadius.circular(30.r),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180.w,
        height: 45.h,
        decoration: isSelected ? gradientDecoration : normalDecoration,
        padding: EdgeInsets.all(isSelected ? 2.w : 0),
        child: Container(
          decoration: BoxDecoration(
            color: _containerBg,
            borderRadius: BorderRadius.circular(28.r),
          ),
          child: Center(
            child:
                isSelected
                    ? ShaderMask(
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [_gradientStart, _gradientEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                      child: _buildButtonContent(
                        imagePath,
                        label,
                        Colors.white,
                      ),
                    )
                    : _buildButtonContent(imagePath, label, _textColorPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(imagePath, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          imagePath,
          width: 20.w,
          height: 20.h,
          // colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        SizedBox(width: 10.w),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
