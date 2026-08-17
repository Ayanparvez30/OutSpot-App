import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/OtpScreen/otp_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class OtpScreen extends GetView<OtpController> {
  const OtpScreen({super.key});

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
            "Enter Code",

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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "We sent a code to",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),

                            SizedBox(width: 1.7.w),
                            Flexible(
                              child: Text(
                                controller.isEmailTab.value
                                    ? "${_maskEmail(controller.gettingArgs)}."
                                    : "${_maskEmail(controller.phoneNumber)}.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),
                        Text(
                          "Please allow up to 3 minutes for it to arrive,\nthen enter it below.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        PinCodeTextField(
                          keyboardType: TextInputType.phone,
                          controller: controller.otpController,
                          appContext: context,
                          length: controller.email.isNotEmpty ? 5 : 6,
                          obscureText: false,
                          hintStyle: TextStyle(color: AppColors.white),
                          textStyle: TextStyle(
                            color: AppColors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.circle,
                            borderRadius: BorderRadius.circular(12.sp),
                            fieldHeight: 50.h,
                            fieldWidth: 50.w,
                            selectedFillColor: AppColors.inputFillColor,
                            activeFillColor: AppColors.inputFillColor,
                            inactiveFillColor: AppColors.inputFillColor,
                            inactiveColor: AppColors.inputBorderColor,
                            activeColor: Colors.green,
                            selectedColor: AppColors.inputBorderColor,
                            borderWidth: 0.5,
                          ),

                          enableActiveFill: true,
                        ),

                        SizedBox(height: 10.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn’t receive a code?",
                              style: GoogleFonts.notoSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Obx(() {
                              if (controller.canResendOtp.value) {
                                return GestureDetector(
                                  onTap: () {
                                    // // controller.resendOtpToEmail(context);
                                    // controller.resendOTPFunction(controller.gettingArgs);
                                    // controller.resendOtpToEmail(context);
                                    final email = controller.gettingArgs;
                                    // final forgotController = Get.put(
                                    //   ForgotpasswordController(),
                                    // );
                                    if (Get.previousRoute ==
                                        Routes.forgotScreen) {
                                      if (controller.isEmailTab.value) {
                                        log("Tap this");
                                        controller.resendForgotPassword(
                                          email: email,
                                        );
                                      } else {
                                        log("Tap this phone");
                                        controller.resendPhoneOtp(
                                          phone: controller.phoneNumber,
                                        );
                                      }
                                    } else {
                                      if (controller.isEmailTab.value) {
                                        controller.resendOTPFunction(email);
                                      } else {
                                        controller.resendPhoneOtp(
                                          phone: controller.phoneNumber,
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    "Send another",
                                    style: GoogleFonts.notoSans(
                                      color: const Color(0xff704EF9),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              } else {
                                return Text(
                                  "Resend in ${controller.countdown.value}s",
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xff704EF9),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                );
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                CustomWidgets().CustomButton(
                  text: "Next",
                  onPressed: () {
                    if (controller.otpController.text.trim().isNotEmpty) {
                      if (Get.previousRoute == Routes.forgotScreen) {
                        String otp = controller.otpController.text.trim();
                        String verificationId = controller.verificationId;
                        String phoneNumber = controller.phoneNumber;
                        String resendToken = controller.phoneNumber;
                        Get.toNamed(
                          Routes.createPassword,
                          arguments: {
                            'otp': otp,
                            "email": controller.gettingArgs,
                            "phoneNumber": phoneNumber,
                            "verificationId": verificationId,
                            "resendToken": resendToken,
                          },
                        );
                      } else {
                        final email = controller.gettingArgs;
                        final code = controller.otpController.text.trim();
                        if (controller.isEmailTab.value) {
                          controller.verifyCode(email, code);
                        } else {
                          // controller.phoneVerifyCode(email, code);

                          final smsCode = controller.otpController.text.trim();
                          final verificationId = controller.verificationId;
                          final phone = controller.phoneNumber;

                          controller.verifyOtpAndSaveUser(
                            verificationId: verificationId,
                            smsCode: smsCode,

                            phone: phone,
                          );
                        }
                      }
                    } else {
                      AppSnackbar.error('Please enter the OTP');
                    }
                  },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final index = email.indexOf('@');
    if (index > 4) {
      return email.substring(0, 4) + '****' + email.substring(index);
    } else if (index > 0) {
      // jodi email er 4 character er kom thake @ er age
      return email[0] + '****' + email.substring(index);
    }
    return email;
  }
}
