import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';

class MasculineBody extends GetView<CreateprofileController> {
  const MasculineBody({super.key});

  // --- Color Palette ---
  final Color _bgGradientTop = const Color(0xff2E0248);
  final Color _bgGradientBottom = const Color(0xff5A2D85);
  final Color _sliderTrackColor = const Color(0xff4A1C60);
  final Color _sliderThumbColor = const Color(0xffFF9D2B);
  final Color _btnGradientStart = const Color(0xffDA5EF3);
  final Color _btnGradientEnd = const Color(0xffFF8D7E);

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
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Obx(() {
                          return SizedBox(
                            height: 300.h,
                            child: Image.asset(
                              controller.currentImage,
                              fit: BoxFit.contain,
                            ),
                          );
                        }),
                        SizedBox(height: 30.h),
                        _buildSlider(
                          label: "What's your height?",
                          value: controller.height,
                          max: 3,
                          labels: const ["Short", "Medium", "Tall"],
                        ),
                        SizedBox(height: 25.h),
                        _buildSlider(
                          label: "What's your weight?",
                          value: controller.weight,
                          max: 4,
                          labels: const ["M1", "M2", "M3", "M4"],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 45.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_btnGradientStart, _btnGradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveBodyTypeOnServer();
                      controller.submitBodySelection();
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

  Widget _buildSlider({
    required String label,
    required RxDouble value,
    required double max,
    required List<String> labels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10.h),
        Obx(() {
          return SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              activeTrackColor: _sliderTrackColor,
              inactiveTrackColor: _sliderTrackColor.withOpacity(0.5),
              trackHeight: 6.0.h,
              thumbColor: Colors.transparent,
              overlayColor: _sliderThumbColor.withOpacity(0.2),
              activeTickMarkColor: _sliderTrackColor,
              inactiveTickMarkColor: _sliderTrackColor,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
            ),
            child: Slider(
              value: value.value,
              min: 1,
              max: max,
              divisions: (max - 1).toInt(),
              thumbColor: _sliderThumbColor,
              onChanged: (val) => value.value = val,
            ),
          );
        }),
      ],
    );
  }
}
