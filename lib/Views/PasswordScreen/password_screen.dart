import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/PasswordScreen/password_screen_controller.dart';

class PasswordScreen extends GetView<PasswordScreenController> {
  const PasswordScreen({super.key});

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
            'Update Password',

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
            padding: EdgeInsets.symmetric(horizontal: 15.h),
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Obx(
                    () => CustomWidgets().customTextField(
                      hint: "Current Password",
                      controller: controller.currentPasswardController,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Password is required';
                      },
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.isCurrentPasswordHidden.value =
                              !controller.isCurrentPasswordHidden.value;
                        },
                        child:
                            controller.isCurrentPasswordHidden.value
                                ? Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/obsecure_icon.svg",
                                      width: 20.r,
                                      height: 20.r,
                                      // fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                )
                                : Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/obsecure_off_icon.svg",
                                      width: 17.r,
                                      height: 17.r,

                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF703A8B),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                      obscureText: controller.isCurrentPasswordHidden.value,
                    ),
                  ),

                  SizedBox(height: 20.h),
                  Obx(
                    () => CustomWidgets().customTextField(
                      hint: "New Password",
                      controller: controller.newPasswardController,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Password is required';
                        if (value.length < 8)
                          return 'Password must be at least 8 characters';
                        return null;
                      },
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.isNewPasswordHidden.value =
                              !controller.isNewPasswordHidden.value;
                        },
                        child:
                            controller.isNewPasswordHidden.value
                                ? Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/obsecure_icon.svg",
                                      width: 20.r,
                                      height: 20.r,
                                      // fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                )
                                : Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/obsecure_off_icon.svg",
                                      width: 17.r,
                                      height: 17.r,

                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF703A8B),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                      obscureText: controller.isNewPasswordHidden.value,
                    ),
                  ),

                  SizedBox(height: 20.h),
                  Obx(
                    () => CustomWidgets().customTextField(
                      hint: "Repeat Password",
                      controller: controller.repeatPasswardController,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please repeat your password';
                        if (value != controller.newPasswardController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.isRepPasswordHidden.value =
                              !controller.isRepPasswordHidden.value;
                        },
                        child:
                            controller.isRepPasswordHidden.value
                                ? Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/obsecure_icon.svg",
                                      width: 20.r,
                                      height: 20.r,
                                      // fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                )
                                : Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: SvgPicture.asset(
                                      "assets/svg/icons/obsecure_off_icon.svg",
                                      width: 17.r,
                                      height: 17.r,

                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF703A8B),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                      obscureText: controller.isRepPasswordHidden.value,
                    ),
                  ),

                  Spacer(),
                  CustomWidgets().CustomButton(
                    text: "Save",
                    onPressed: () {
                      if (controller.formKey.currentState!.validate()) {
                        // Get.snackbar("Success", "Password change successfully!");
                        final currentPassword =
                            controller.currentPasswardController.text.trim();
                        final newPassword =
                            controller.newPasswardController.text.trim();
                        final repeatPassword =
                            controller.repeatPasswardController.text.trim();
                        controller.changePassword(
                          currentPassword,
                          newPassword,
                          repeatPassword,
                        );
                      }
                    },
                  ),
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
