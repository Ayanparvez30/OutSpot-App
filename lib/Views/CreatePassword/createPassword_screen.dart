import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/CreatePassword/createPassword_controller.dart';

class CreatepasswordScreen extends GetView<CreatepasswordController> {
  const CreatepasswordScreen({super.key});

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
              FocusManager.instance.primaryFocus?.unfocus();
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
            'Create Password',

            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              "Please enter the new password for your\nOutspot account.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),

                          SizedBox(height: 20.h),

                          Obx(
                            () => CustomWidgets().customTextField(
                              hint: "Password",
                              controller: controller.passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Password is required';
                                if (value.length < 8)
                                  return 'Password must be at least 8 characters';
                                return null;
                              },
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  controller.isPasswordHidden.value =
                                      !controller.isPasswordHidden.value;
                                },
                                child:
                                    controller.isPasswordHidden.value
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

                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Color(0xFF703A8B),
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
                                        ),
                              ),
                              obscureText: controller.isPasswordHidden.value,
                            ),
                          ),

                          SizedBox(height: 20.h),
                          Obx(
                            () => CustomWidgets().customTextField(
                              hint: "Repeat Password",
                              controller: controller.repeatPassController,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please repeat your password';
                                if (value != controller.passwordController.text)
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

                                              colorFilter:
                                                  const ColorFilter.mode(
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
                        ],
                      ),
                    ),
                  ),
                  CustomWidgets().CustomButton(
                    text: "Submit",
                    onPressed: () {
                      // if (controller.formKey.currentState!.validate()) {
                      //   // Get.snackbar("Success", "Password created successfully!");
                      //   CustomWidgets().showSaveDialogue(
                      //     title: "Password Updated!",
                      //     subtitle:
                      //         "Update complete, please log in using\nyour new password.",
                      //     nextRoute: Routes.loginScreen,
                      //   );
                      // }

                      if (controller.formKey.currentState?.validate() ??
                          false) {
                        // final email =
                        //     Get.find<ForgotpasswordController>()
                        //         .forgetEmailControler
                        //         .text
                        //         .trim();
                        String email = controller.gettingEmail;

                        final otp = controller.gettingOtp;
                        final password =
                            controller.passwordController.text.trim();
                        final repeatPassword =
                            controller.repeatPassController.text.trim();
                        final phone = controller.phoneNumber;
                        final verificationId = controller.verificationId;

                        print(email);
                        print(otp);
                        if (controller.logController.isEmailTab.value == true) {
                          controller.resetPassword(
                            email: email,
                            otp: otp,
                            password: password,
                            repeatPassword: repeatPassword,
                          );

                          log(email);
                          log(otp);
                          log(password);
                        } else {
                          controller.resetPasswordWithOtp(
                            phone: phone,
                            otp: otp,
                            newPassword: password,
                            repeatPassword: repeatPassword,
                            verificationId: verificationId,
                          );
                          log(otp);
                          log(phone);
                          log(password);
                          log(repeatPassword);
                        }
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
