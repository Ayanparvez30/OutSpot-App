import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Create_Mini_Me/create_mini_me_controller.dart';

class CreateMiniMe extends GetView<CreateMiniMeController> {
  const CreateMiniMe({super.key});

  // --- Colors & Gradients ---
  final Color _cardBgColor = const Color(0xff390A3E);
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
          child:
              //  const Icon(Icons.arrow_back_ios, color: Colors.white),
              CustomBackButton(),
        ),
        title: Text(
          "Create Your Mini-Me",
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30.h),

                // --- Take a Selfie Button ---
                _buildGradientBorderButton(
                  iconPath: "assets/svg/icons/Icon-Solid-Camera.svg",
                  iconData: Icons.camera_alt_outlined,
                  text: "Take a Selfie",
                  onTap: () {
                    // controller.pickImagecamera();
                    Get.toNamed(Routes.takeSelfie);
                  },
                ),

                SizedBox(height: 15.h),
                buildGradientBorderButton(
                  iconPath: "assets/svg/icons/Icon-Outline-Upload.svg",
                  iconData: Icons.upload_file,
                  text: "Upload from gallery",
                  onTap: () {
                    controller.pickImage();
                  },
                ),

                SizedBox(height: 30.h),

                Text(
                  "Or customize a premade avatar:",
                  style: GoogleFonts.notoSans(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 15.h),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingPremades.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff390A3E),
                        ),
                      );
                    }
                    if (controller.premades.isEmpty) {
                      return Center(
                        child: Text(
                          "No avatars available",
                          style: GoogleFonts.notoSans(
                            color: Colors.white54,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 15.w,
                          runSpacing: 15.h,
                          children: List.generate(controller.premades.length, (
                            index,
                          ) {
                            final premade = controller.premades[index];
                            final imageUrl =
                                premade['imageUrl']?.toString() ?? '';

                            double itemWidth =
                                (Get.width - 40.w - (15.w * 2)) / 3;
                            double itemHeight = itemWidth / 0.92;

                            return SizedBox(
                              width: itemWidth,
                              height: itemHeight,
                              child: Obx(() {
                                final isSelected =
                                    controller.selectedAvatarIndex.value ==
                                    index;
                                return GestureDetector(
                                  onTap: () {
                                    controller.selectedAvatarIndex.value =
                                        index;
                                    controller.pickimages.value = '';
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: _cardBgColor,
                                          borderRadius: BorderRadius.circular(
                                            15.r,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: _btnGradientStart,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            15.r,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(0.sp),
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (context, url) =>
                                                      const ShimmerPlaceholder(),
                                              errorWidget:
                                                  (c, url, error) => Icon(
                                                    Icons.person,
                                                    color: Colors.white54,
                                                    size: 40.sp,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // if (isSelected)
                                      //   Positioned(
                                      //     top: 8.h,
                                      //     right: 8.w,
                                      //     child: Container(
                                      //       padding: EdgeInsets.all(4.sp),
                                      //       decoration: BoxDecoration(
                                      //         shape: BoxShape.circle,
                                      //         gradient: LinearGradient(
                                      //           colors: [
                                      //             _btnGradientStart,
                                      //             _btnGradientEnd,
                                      //           ],
                                      //         ),
                                      //       ),
                                      //       child: Icon(
                                      //         Icons.check,
                                      //         size: 12.sp,
                                      //         color: Colors.white,
                                      //       ),
                                      //     ),
                                      //   ),
                                    ],
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                      ),
                    );
                  }),
                ),
                // --- Continue Button ---
                SizedBox(
                  width: double.infinity,
                  height: 45.h,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_btnGradientStart, _btnGradientEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        controller.proceedWithPremade();
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
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGradientBorderButton({
    required String iconPath,
    required IconData iconData,
    required String text,
    required VoidCallback onTap,
  }) {
    final Color gradientStarts = const Color(0xFFD946EF);
    final Color gradientEnds = const Color(0xFFFFB300);
    final Color innerBackgrounds = const Color(0xFF1A0B2E);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          width: double.infinity,
          height: 45.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStarts, gradientEnds],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: EdgeInsets.all(1.5.w),
          child: Container(
            decoration: BoxDecoration(
              color: innerBackgrounds,
              borderRadius: BorderRadius.circular(29.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(iconPath),
                SizedBox(width: 12.w),
                Text(
                  text,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBorderButton({
    required String iconPath,
    required IconData iconData,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
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
          padding: EdgeInsets.all(1.5.w),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff1A0B2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(29.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(iconPath),
                SizedBox(width: 12.w),
                Text(
                  text,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
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
