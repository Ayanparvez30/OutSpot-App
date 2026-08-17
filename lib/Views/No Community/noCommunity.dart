import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/No%20Community/allCommunities.dart';
import 'package:outspot/Views/No%20Community/newCommunity.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';
import 'package:outspot/Views/No%20Community/searchCommunity.dart';

class Nocommunity extends GetView<NocommunityController> {
  const Nocommunity({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NocommunityController>()) {
      Get.put(NocommunityController());
    }

    // Refresh community lists every time the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMyCommunities();
    });

    return WillPopScope(
      onWillPop: () async {
        if (Get.previousRoute == Routes.allStats) {
          Get.back();
          return false;
        }
        Get.toNamed(Routes.myProfile, arguments: {'fromDeepLink': true});
        return false;
      },
      child: Container(
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
            leading: IconButton(
              icon: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 25.r,
                height: 25.r,
              ),

              padding: EdgeInsets.all(8.w),
              constraints: const BoxConstraints(),
              // onPressed: () => Get.back(),
              onPressed: () {
                if (Get.previousRoute == Routes.allStats) {
                  Get.back();
                  return;
                }

                // Get.until((route) => route.settings.name == Routes.myProfile);
                Get.toNamed(
                  Routes.myProfile,
                  arguments: {'fromDeepLink': true},
                );
              },
            ),

            title: Text(
              'Communities',
              style: GoogleFonts.notoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          // Fully responsive, NO scroll. The image + texts live in a flexible
          // top region that fills whatever space is left after the fixed action
          // buttons, so the layout keeps the same proportions on every screen
          // size and never overflows / never scrolls.
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Flexible hero region (image + title + subtitle) ----
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image takes the leftover vertical space and scales
                        // down via BoxFit.contain on short screens — never
                        // forces an overflow.
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              'assets/Images/noCommunity.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Join a Community',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'When you join a community, you get to view '
                          'and post to the community story and help '
                          'your community score points on the leaderboard!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSans(
                            fontSize: 14.sp,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---- Fixed action area ----
                  SizedBox(height: 20.h),
                  _gradientButton(
                    label: 'My Communities',
                    onTap:
                        () => Get.to(
                          Allcommunities(),
                          transition: Transition.fadeIn,
                          duration: 200.milliseconds,
                        ),
                  ),
                  SizedBox(height: 14.h),
                  _gradientButton(
                    label: 'View Communities',
                    onTap:
                        () => Get.to(
                          SearchCommunity(),
                          transition: Transition.fadeIn,
                          duration: 200.milliseconds,
                        ),
                  ),
                  SizedBox(height: 18.h),
                  InkWell(
                    onTap: () {
                      if (controller.joinedCommunities.isNotEmpty ||
                          controller.createdCommunities.isNotEmpty) {
                        _showAlreadyInCommunityDialog();
                      } else {
                        Get.to(
                          () => const NewCommunity(),
                          transition: Transition.fadeIn,
                          duration: 200.milliseconds,
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/svg/plus1.svg'),
                        SizedBox(width: 10.w),
                        Text(
                          'Create a New Community',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.MainColor,
                AppColors.btnGradientLeft,
                AppColors.btnGradientRight,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAlreadyInCommunityDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: const Color(0xff1A041D),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xff704EF9).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xff704EF9).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: const Color(0xff704EF9),
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Limit Reached',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'You are already a member of a community. Please leave or delete your current community first to create a new one.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xff704EF9),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
