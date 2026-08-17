import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/UpdateBio/updateBio_controller.dart';
import 'package:outspot/utils/routes.dart';

class Updatebio extends GetView<UpdatebioController> {
  const Updatebio({super.key});

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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            color: Colors.white,
            onPressed: () {
              Get.back();
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
            'Update Bio',

            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  TextField(
                    controller: controller.bioControler,
                    maxLines: 8,
                    cursorColor: AppColors.white,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a bio (optional)...',
                      hintStyle: TextStyle(color: AppColors.inputBorderColor),

                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),

                      filled: true,
                      fillColor: AppColors.inputFillColor,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: AppColors.inputBorderColor,
                        ),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: AppColors.inputBorderColor,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: AppColors.inputBorderColor,
                        ),
                      ),
                    ),
                  ),

                  Spacer(),
                  Obx(() {
                    final enabled = controller.hasChanged.value;
                    return Opacity(
                      opacity: enabled ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !enabled,
                        child: CustomWidgets().CustomButton(
                          text: "Save",
                          onPressed: () {
                            final bio = controller.bioControler.text.trim();
                            controller.updateBio(bio: bio);
                          },
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
