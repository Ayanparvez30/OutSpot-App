import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';

class Minimeupdated extends StatelessWidget {
  final String imagePath;
  final int? minimeId;

  const Minimeupdated({super.key, required this.imagePath, this.minimeId});

  Future<void> _saveAndUpdate() async {
    try {
      AppLoading.show();

      String activeAvatarUrl = imagePath;

      if (minimeId != null) {
        final response = await ApiService.setActiveMinime(minimeId!);
        activeAvatarUrl = response['avatarUrl'] ?? imagePath;
      } else {
        await ApiService.uploadAvatar(premadeUrl: imagePath);
      }

      AppLoading.hide();

      // Update profile avatar across all controllers
      if (Get.isRegistered<MyProfileController>()) {
        Get.find<MyProfileController>().avatarurl.value = activeAvatarUrl;
      }
      if (Get.isRegistered<ExploreController>()) {
        Get.find<ExploreController>().avatarurl.value = activeAvatarUrl;
      }

      Get.back(result: activeAvatarUrl);
      AppSnackbar.success("Mini-me updated successfully!");
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();
      log("❌ Error updating mini-me: $e");
      AppSnackbar.error("Failed to update mini-me. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: [0.1, 0.5],
          radius: 1.5,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Container(
              padding: EdgeInsets.all(15.w),
              child: SvgPicture.asset(
                'assets/svg/icons/back_icon.svg',
                color: Colors.white,
                height: 20.h,
              ),
            ),
          ),
          title: Text(
            'Your Mini-Me',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const ShimmerPlaceholder(radius: 0),
                errorWidget:
                    (context, url, error) =>
                        const Icon(Icons.broken_image, size: 50),
              ),
            ),

            SizedBox(height: 20.h),
            GestureDetector(
              onTap: _saveAndUpdate,
              child: Container(
                height: 45.h,
                width: 320.w,
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
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Center(
                  child: Text(
                    "Save & Update",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Text(
                "Discard",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.appBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
