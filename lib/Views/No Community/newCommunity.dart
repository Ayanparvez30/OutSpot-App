import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/No%20Community/noCommunity_controller.dart';

class NewCommunity extends StatelessWidget {
  const NewCommunity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<NocommunityController>()
            ? Get.find<NocommunityController>()
            : Get.put(NocommunityController());

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
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: SvgPicture.asset(
              "assets/svg/icons/back_icon.svg",
              width: 25.r,
              height: 25.r,
            ),

            padding: EdgeInsets.all(8.w),
            constraints: const BoxConstraints(),
            // onPressed: () => Get.back(),
            onPressed: () => Get.back(),
          ),

          title: Text(
            'New Community',
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
                  // এলিমেন্ট কনফ্লিক্ট দূর করতে ইউনিক কী
                  key: const ValueKey('new_community_scroll_view'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Column(
                      children: [
                        SizedBox(height: 30.h),

                        // ইমেজ সিলেকশন সেকশন
                        Stack(
                          children: [
                            Obx(() {
                              return Container(
                                height: 100,
                                width: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage:
                                      controller.pickedImage.value != null
                                          ? FileImage(
                                            controller.pickedImage.value!,
                                          )
                                          : const AssetImage(
                                            'assets/Images/communityImage.png',
                                          ),
                                  backgroundColor: Colors.transparent,
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
                                    color: Colors.black.withValues(alpha: 0.6),
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
                        SizedBox(height: 30.h),

                        CustomWidgets().customTextField(
                          hint: "Community name…",
                          controller: controller.newCommunityController,
                        ),

                        SizedBox(height: 15.h),

                        // Optional community bio
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
              // Pinned action button with safe bottom spacing so it never sits
              // flush against the screen edge.
              Padding(
                padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 20.h),
                child: CustomWidgets().CustomButton(
                  text: "Next",
                  onPressed: () {
                    controller.createCommunity();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
