import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/UserName/userName_controller.dart';

class Contactus extends GetView<UsernameController> {
  const Contactus({super.key});

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
            'Contact Us',

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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 10.w),
                  CustomWidgets().customTextField(
                    hint: "Your email…",
                    controller: controller.emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Email is required';
                      if (!GetUtils.isEmail(value))
                        return 'Enter a valid email';
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
                  ),
                  SizedBox(height: 15.h),
                  CustomWidgets().customTextField(
                    hint: "Subject…",
                    controller: controller.subjectController,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Subject is required';
                      if (value.length < 3)
                        return 'Subject must be at least 3 characters';
                      return null;
                    },
                  ),

                  SizedBox(height: 15.h),
                  customTextFields(
                    hintText: 'Write description…',
                    maxLines: 7,

                    controller: controller.description,
                  ),
                  Spacer(),
                  CustomWidgets().CustomButton(
                    text: "Submit",
                    onPressed: () {
                      if (controller.formKey.currentState!.validate()) {
                        // Get.snackbar("Success", "Username updated successfully!");

                        final email = controller.emailController.text.trim();
                        final subject =
                            controller.subjectController.text.trim();
                        final description = controller.description.text.trim();

                        controller.sendMessage(email, subject, description);
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

  Widget customTextFields({
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: AppColors.white,
      style: GoogleFonts.notoSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: GoogleFonts.notoSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,

          color: AppColors.inputBorderColor,
        ),
        filled: true,
        fillColor: AppColors.inputFillColor,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
      ),
    );
  }
}
