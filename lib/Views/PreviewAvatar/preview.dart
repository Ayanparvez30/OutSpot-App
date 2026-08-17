import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/PreviewAvatar/preview_controller.dart';

class PreviewMinime extends GetView<PreviewController> {
  const PreviewMinime({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {
            Get.until((route) => Get.currentRoute == Routes.outfitScreen);
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
          "Your Mini-Me",
          style: GoogleFonts.notoSans(
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
          child: Column(
            children: [
              SizedBox(height: 30.h),
              // Avatar preview
              Obx(() {
                if (controller.loading.value) {
                  return Center(
                    child: Lottie.asset(
                      'assets/Images/vertopal.com_Animation - 1746656287165.json',
                      height: 200.h,
                      width: 200.w,
                    ),
                  );
                }
                final url = controller.avatarUrl.value;
                return url.isEmpty
                    ? Image.asset('assets/Images/BKL.png', scale: 1.2)
                    : CachedNetworkImage(
                      imageUrl: url,
                      height: 400.h,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) => SizedBox(
                            height: 200.h,
                            width: 200.w,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xffC574F7),
                              ),
                            ),
                          ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    );
              }),
              Spacer(),
              // Save & Continue button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Container(
                  width: double.infinity,
                  height: 45.h,

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.btnGradientLeft,
                        AppColors.btnGradientRight,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: save avatar & navigate
                      controller.save();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      'Save & Continue',
                      style: GoogleFonts.notoSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Regenerate link
              TextButton(
                onPressed: () {
                  Get.offNamed(Routes.generate, arguments: controller.lastOutfitArgs);
                },
                child: Text(
                  'Regenerate',
                  style: GoogleFonts.notoSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ),
              SizedBox(height: 15.h),
            ],
          ),
        ),
      ),
    );
  }
}
