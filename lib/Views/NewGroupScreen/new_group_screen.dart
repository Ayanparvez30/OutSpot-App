import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/textField.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/NewGroupScreen/add_screen.dart';
import 'package:outspot/Views/NewGroupScreen/new_group_screen_controller.dart';

class NewGroupScreen extends GetView<NewGroupScreenController> {
  const NewGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<NewGroupScreenController>()) {
      Get.delete<NewGroupScreenController>(force: true);
    }
    Get.put(NewGroupScreenController());
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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Padding(
              padding: EdgeInsets.all(13),
              child: SvgPicture.asset(
                "assets/svg/icons/back_icon.svg",
                width: 22.r,
                height: 22.r,
              ),
            ),
          ),
          title: Obx(() => Text(
            controller.isEdit.value ? 'Edit Group' : 'New Group',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          )),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                SizedBox(height: 30.h),

                Stack(
                  children: [
                    Obx(() {
                      final file = controller.pickedImage.value;
                      final groupUrl = controller.groupImage.value;

                      final hasFile = file != null;
                      final hasGroupImage = groupUrl.isNotEmpty;

                      ImageProvider? bgImage;
                      bool showAssetWithPadding = false;

                      if (hasFile) {
                        bgImage = FileImage(file!);
                      } else if (hasGroupImage) {
                        bgImage = CachedNetworkImageProvider(groupUrl);
                      } else {
                        showAssetWithPadding = true;
                      }

                      return SizedBox(
                        height: 100,
                        width: 100,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.amberAccent,
                          backgroundImage: bgImage,
                          child:
                              showAssetWithPadding
                                  ? Padding(
                                    padding: EdgeInsets.all(16),
                                    child: ClipOval(
                                      child: SvgPicture.asset(
                                        "assets/svg/icons/groups.svg",
                                        colorFilter: ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        width: 60.sp,
                                        height: 60.sp,
                                      ),
                                    ),
                                  )
                                  : null,
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

                SizedBox(height: 20.h),
                CustomTextField(
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      "assets/svg/icons/exploreTab_icon.svg",
                      width: 20.sp,
                      height: 20.sp,
                      colorFilter: ColorFilter.mode(
                        AppColors.backgroundColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  hint: "Group Name",
                  controller: controller.newGroupController,
                ),

                Spacer(),

                Obx(() => CustomWidgets().CustomButton(
                  text: controller.isEdit.value ? "Save" : "Next",
                  onPressed: () {
                    if (controller.isEdit.value) {
                      controller.updateGroupChat();
                    } else {
                      Get.to(AddScreen());
                    }
                  },
                )),
                SizedBox(height: 35.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
