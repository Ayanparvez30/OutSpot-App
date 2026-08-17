import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';
import 'package:outspot/Views/No%20Community/searchCommunity.dart';

class Editcommunitypage extends GetView<NocommunityController> {
  const Editcommunitypage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NocommunityController());

    // 📝 Get communityId from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final int communityId = args?["communityId"] ?? 0;

    // API call to load existing data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (communityId != 0) {
        controller.loadExistingCommunity(communityId);
      }
    });

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
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(15.w),
              child: SvgPicture.asset(
                'assets/svg/icons/back_icon.svg',
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            'Edit Community',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        SizedBox(height: 30.h),

                        GestureDetector(
                          onTap: () => controller.pickImage(),
                          child: // Image Picker UI
                              Stack(
                            children: [
                              Obx(() {
                                return Container(
                                  height: 100,
                                  width: 100,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.amberAccent,
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        controller.pickedImage.value != null
                                            ? FileImage(
                                              controller.pickedImage.value!,
                                            )
                                            : (controller
                                                        .existingCommunityImage
                                                        .value
                                                        .isNotEmpty
                                                    ? CachedNetworkImageProvider(
                                                      controller
                                                          .existingCommunityImage
                                                          .value,
                                                    )
                                                    : const AssetImage(
                                                      'assets/Images/Group chat image@2x.png',
                                                    ))
                                                as ImageProvider,
                                  ),
                                );
                              }),

                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    controller.pickImage();
                                  },
                                  child: Container(
                                    height: 40.h,
                                    width: 100.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(45.r),
                                        bottomRight: Radius.circular(45.r),
                                      ),
                                    ),
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/download.svg",
                                      width: 25.sp,
                                      height: 25.sp,
                                      colorFilter: ColorFilter.mode(
                                        AppColors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        /// 📝 Community name
                        CustomWidgets().customTextField(
                          hint: "Community name…",
                          controller: controller.newCommunityController,
                        ),

                        SizedBox(height: 15.h),

                        /// 📝 Community bio (optional)
                        CustomWidgets().customTextField(
                          hint: "Community bio (optional)…",
                          controller: controller.bioController,
                          keyboardType: TextInputType.multiline,
                          minLines: 4,
                          maxLines: 5,
                        ),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
              // Pinned Save button with safe bottom spacing so it never sits
              // flush against the screen edge.
              Padding(
                padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 20.h),
                child: GestureDetector(
                  onTap: () {
                    // Save changes
                    controller.updateCommunityDetails(
                      communityId: communityId,
                      newName: controller.newCommunityController.text.trim(),
                      newImage: controller.pickedImage.value,
                      newBio: controller.bioController.text.trim(),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    alignment: Alignment.center,
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
                    child: Text(
                      "Save",
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 16.sp,
                        color: Color(0xffFFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
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
