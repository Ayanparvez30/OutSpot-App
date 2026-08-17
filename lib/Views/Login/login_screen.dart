import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Login/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

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
            'Log In',

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
                          SizedBox(height: 20),
                          buildToggleTabs(),

                          SizedBox(height: 20),

                          Obx(() {
                            return controller.isEmailTab.value
                                ? CustomWidgets().customTextField(
                                  hint: "Email",
                                  keyboardType: TextInputType.emailAddress,
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
                                        controller: controller.phoneController,
                                        keyboardType: TextInputType.phone,
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
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => controller.rememberMe.toggle(),
                                child: Obx(
                                  () => Container(
                                    height: 22.h,
                                    width: 22.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            controller.rememberMe.value
                                                ? const Color(0xff704EF9)
                                                : AppColors.inputBorderColor,
                                        width: 2,
                                      ),
                                      color:
                                          controller.rememberMe.value
                                              ? const Color(0xff704EF9)
                                              : Colors.transparent,
                                    ),
                                    child:
                                        controller.rememberMe.value
                                            ? Icon(
                                              Icons.check,
                                              size: 18.sp,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "Remember Me",
                                style: GoogleFonts.notoSans(
                                  fontSize: 14.sp,
                                  // color: const Color(0xff000000),
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Get.toNamed(
                                    Routes.forgotScreen,
                                    arguments: {
                                      "value":
                                          controller.isEmailTab.value
                                              ? controller.emailController.text
                                                  .trim()
                                              : controller.phoneController.text
                                                  .trim(),
                                      "type":
                                          controller.isEmailTab.value
                                              ? "email"
                                              : "phone",
                                    },
                                  );
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14.sp,
                                    color: const Color(0xff704EF9),

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Stays greyed out & untappable until the active tab's fields
                  // (email/phone + password) are filled.
                  Obx(() {
                    final enabled = controller.isFormFilled.value;
                    return Opacity(
                      opacity: enabled ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !enabled,
                        child: CustomWidgets().CustomButton(
                          text: "Log In",
                          onPressed: () {
                            final identifier =
                                controller.emailController.text.trim();
                      final password =
                          controller.passwordController.text.trim();
                      final phoneText = controller.phoneController.text.trim();
                      final phone =
                          controller.selectedCountryCode + phoneText;

                      // Try formKey validation first; if formKey state is null
                      // (happens after logout/recreate on iOS), fall back to manual
                      final formValid =
                          controller.formKey.currentState?.validate();
                      if (formValid == false) return;

                      // Manual validation as a safety net
                      if (controller.isEmailTab.value) {
                        if (identifier.isEmpty) {
                          AppToast.error('Please enter your email');
                          return;
                        }
                        if (password.isEmpty) {
                          AppToast.error('Please enter your password');
                          return;
                        }
                        controller.login(identifier, password);
                      } else {
                        if (phoneText.isEmpty) {
                          AppToast.error('Please enter your phone number');
                          return;
                        }
                        if (password.isEmpty) {
                          AppToast.error('Please enter your password');
                          return;
                        }
                        controller.phoneLogin(phone, password);
                      }
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

  void showDuplicateLoginDialog(BuildContext context) {
    Get.dialog(
      Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30.h),
              Text(
                "Duplicate Log In",
                style: GoogleFonts.notoSans(
                  decoration: TextDecoration.none,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff000000),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                "You are already logged in on another\ndevice. Sign in here instead?",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  decoration: TextDecoration.none,
                  fontSize: 15.sp,
                  color: Color(0xff000000),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 25.h),

              CustomWidgets().CustomButton(
                text: "Sign out other device",
                onPressed: () {},
              ),

              SizedBox(height: 5.h),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.notoSans(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}
