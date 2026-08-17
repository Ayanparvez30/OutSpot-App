import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/SignUpScreen/signUp_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

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
          scrolledUnderElevation: 0,
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
            'Create an Account',

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
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          buildToggleTabs(),

                          SizedBox(height: 20),

                          Obx(() {
                            return controller.isEmailTab.value
                                ? CustomWidgets().customTextField(
                                  keyboardType: TextInputType.emailAddress,
                                  hint: "Email",
                                  controller: controller.emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    );
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },

                                  suffixIcon: Padding(
                                    padding: EdgeInsets.only(right: 5),
                                    child: UnconstrainedBox(
                                      child: SvgPicture.asset(
                                        "assets/svg/icons/email_Icon.svg",
                                        width: 17.r,
                                        height: 17.r,
                                        // fit: BoxFit.scaleDown,
                                      ),
                                    ),
                                  ),
                                )
                                : Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showCountryPicker(
                                          context: context,

                                          showPhoneCode: true,

                                          countryListTheme:
                                              CountryListThemeData(
                                                bottomSheetHeight:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.74,

                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        20,
                                                      ),
                                                      topRight: Radius.circular(
                                                        20,
                                                      ),
                                                    ),
                                              ),

                                          onSelect: (Country country) {
                                            controller
                                                    .selectedCountryCode
                                                    .value =
                                                '+${country.phoneCode}';
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 11.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.inputFillColor,
                                          border: Border.all(
                                            color: AppColors.inputBorderColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.r,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Obx(
                                              () => Text(
                                                controller
                                                    .selectedCountryCode
                                                    .value,
                                                style: GoogleFonts.notoSans(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 40.w),
                                            UnconstrainedBox(
                                              child: SvgPicture.asset(
                                                "assets/svg/icons/dropDown_icon.svg",
                                                width: 17.r,
                                                height: 17.r,
                                                // fit: BoxFit.scaleDown,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15.w),

                                    Expanded(
                                      child: CustomWidgets().customTextField(
                                        keyboardType: TextInputType.phone,
                                        controller: controller.phoneController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Phone number is required';
                                          }
                                          final phoneRegex = RegExp(
                                            r'^\+?[0-9-]{1,50}$',
                                          );

                                          if (!phoneRegex.hasMatch(value)) {
                                            return 'Enter a valid phone number';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(
                                            RegExp(r'\s'),
                                          ),
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9-]'),
                                          ),
                                        ],
                                        hint: "Phone Number",
                                        suffixIcon: Padding(
                                          padding: EdgeInsets.only(right: 5),
                                          child: UnconstrainedBox(
                                            child: SvgPicture.asset(
                                              "assets/svg/icons/phone_icon.svg",
                                              width: 17.r,
                                              height: 17.r,
                                              // fit: BoxFit.scaleDown,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                          }),

                          SizedBox(height: 20),
                          CustomWidgets().customTextField(
                            hint: "Username",
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9._-]'),
                              ),
                            ],
                            controller: controller.usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Username is required';
                              if (value.length < 3)
                                return 'Username must be at least 3 characters';
                              return null;
                            },
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: UnconstrainedBox(
                                child: SvgPicture.asset(
                                  "assets/svg/icons/person_icon.svg",
                                  width: 22.r,
                                  height: 22.r,
                                  // fit: BoxFit.scaleDown,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Obx(
                            () => CustomWidgets().customTextField(
                              controller: controller.passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Password is required';
                                if (value.length < 8)
                                  return 'Password must be at least 8 characters';
                                return null;
                              },
                              hint: "Password",
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

                                              colorFilter: const ColorFilter.mode(
                                                Color(
                                                  0xFF703A8B,
                                                ), // #703A8B এর ফ্লাটার ফরম্যাট
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ),
                              ),
                              obscureText: controller.isPasswordHidden.value,
                            ),
                          ),

                          SizedBox(height: 20),

                          Obx(
                            () => CustomWidgets().customTextField(
                              controller: controller.repeatPassController,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Repeat Password is required';
                                if (value != controller.passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                              hint: "Repeat Password",
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

                          SizedBox(height: 40.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => controller.ageChecked.toggle(),
                                child: Obx(
                                  () => Container(
                                    height: 18.h,
                                    width: 22.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color:
                                            controller.ageChecked.value
                                                ? const Color(0xff704EF9)
                                                : AppColors.inputBorderColor,
                                        width: 1,
                                      ),
                                      color:
                                          controller.ageChecked.value
                                              ? const Color(0xff704EF9)
                                              : Colors.transparent,
                                    ),
                                    child:
                                        controller.ageChecked.value
                                            ? Icon(
                                              Icons.check,
                                              size: 16.sp,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  "I am at least 13 years of age",
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14.sp,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          // Apple 1.2: must agree to Terms of Use (EULA) +
                          // Privacy Policy before registering.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => controller.termsChecked.toggle(),
                                child: Obx(
                                  () => Container(
                                    height: 18.h,
                                    width: 22.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color:
                                            controller.termsChecked.value
                                                ? const Color(0xff704EF9)
                                                : AppColors.inputBorderColor,
                                        width: 1,
                                      ),
                                      color:
                                          controller.termsChecked.value
                                              ? const Color(0xff704EF9)
                                              : Colors.transparent,
                                    ),
                                    child:
                                        controller.termsChecked.value
                                            ? Icon(
                                              Icons.check,
                                              size: 20.sp,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.notoSans(
                                      fontSize: 13.sp,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      const TextSpan(text: "I agree to the "),
                                      TextSpan(
                                        text: "Terms of Use",
                                        style: const TextStyle(
                                          color: Color(0xff704EF9),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () => _openUrl(
                                                "https://outspot.app/terms-and-conditions/",
                                              ),
                                      ),
                                      const TextSpan(text: " and "),
                                      TextSpan(
                                        text: "Privacy Policy",
                                        style: const TextStyle(
                                          color: Color(0xff704EF9),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () => _openUrl(
                                                "https://outspot.app/privacy-policy/",
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
                  // Stays greyed out & untappable until every field for the
                  // active tab is filled AND both checkboxes are ticked.
                  Obx(() {
                    final enabled =
                        controller.isFormFilled.value &&
                        controller.ageChecked.value &&
                        controller.termsChecked.value;
                    return Opacity(
                      opacity: enabled ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !enabled,
                        child: CustomWidgets().CustomButton(
                          text: "Get Started",
                          onPressed: () {
                            if (controller.formKey.currentState?.validate() ??
                                false) {
                              controller.referralDialog();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 15.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackbar.error("Couldn't open the link.");
    }
  }

  Widget buildToggleTabs() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildTabButton('Email', controller.isEmailTab.value, () {
            // controller.phoneController.clear();
            controller.toggleTab(true);
          }),
          const SizedBox(width: 10),
          buildTabButton('Phone Number', !controller.isEmailTab.value, () {
            // controller.emailController.clear();
            controller.toggleTab(false);
          }),
        ],
      ),
    );
  }

  Widget buildTabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.inputBorderColor : AppColors.inputFillColor,
          // border: Border.all(color: Color(0xffE8EAEB)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSans(
            color: selected ? Colors.white : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
