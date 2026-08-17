import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/UserName/userName_controller.dart';

class Username extends GetView<UsernameController> {
  const Username({super.key});

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
            'Update Username',

            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    CustomWidgets().customTextField(
                      hint: "User Name",
                      // prefix: Icon(
                      //   Icons.alternate_email,
                      //   size: 15.sp,
                      //   color: Color(0xff66CCFC),
                      // ),
                      controller: controller.userNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9._-]'),
                        ),
                      ],
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
                    SizedBox(height: 20.h),

                    Container(
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(
                        // color: const Color(0xffF4F4F4),
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.badge,
                            size: 32.sp,
                            color: AppColors.white,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Usernames are Unique",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "In order to update your username you\nneed to enter one that is not being used\nby anyone else.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              // color: const Color(0xff95A4A7),
                              color: AppColors.borders,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Obx(() {
                      final enabled = controller.hasChanged.value;
                      return Opacity(
                        opacity: enabled ? 1.0 : 0.5,
                        child: IgnorePointer(
                          ignoring: !enabled,
                          child: CustomWidgets().CustomButton(
                            text: "Save",
                            onPressed: () {
                              if (controller.formKey.currentState!.validate()) {
                                final username =
                                    controller.userNameController.text.trim();
                                controller.updateUsername(username: username);
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
      ),
    );
  }
}
