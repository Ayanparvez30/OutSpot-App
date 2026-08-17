import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/ForgotScreen/forgot_controller.dart';
import 'package:outspot/Views/Login/login_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class ForgotScreen extends GetView<ForgotController> {
  const ForgotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: const [0.0, 0.6],
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
            'Forgot Password',
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
                              "Please enter the email or phone number\nassociated with your account.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          CustomWidgets().customTextField(
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: UnconstrainedBox(
                                child: SvgPicture.asset(
                                  "assets/svg/icons/person_icon.svg",
                                  width: 22.r,
                                  height: 22.r,
                                ),
                              ),
                            ),
                            hint: "Email or phone number",
                            controller: controller.emailController,

                            onChanged: (value) {
                              final regex = RegExp(r'^[\+0-9]*$');
                              if (value.isNotEmpty && regex.hasMatch(value)) {
                                controller.isInputPhone.value = true;
                              } else {
                                controller.isInputPhone.value = false;
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email or phone number';
                              }

                              final phoneRegex = RegExp(r'^[\+0-9]*$');

                              if (phoneRegex.hasMatch(value.trim())) {
                                if (!value.trim().startsWith('+')) {
                                  return 'must be typed with country code (e.g. +1)';
                                }
                              } else {
                                final emailRegex = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomWidgets().CustomButton(
                    text: "Send Code",
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();

                      if (controller.formKey.currentState?.validate() ??
                          false) {
                      
                        final inputData =
                            controller.emailController.text.trim();

                        if (controller.isInputPhone.value) {
                          controller.phoneForgotPassword(phone: inputData);
                        } else {
                          controller.forgotPassword(email: inputData);
                        }
                      } else {
                        AppSnackbar.error('Please complete the form');
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
