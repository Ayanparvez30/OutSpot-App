import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';
import 'package:outspot/Views/SettingScreen/setting_controller.dart';
import '../../Utils/routes.dart';

class Createprofile extends GetView<CreateprofileController> {
  const Createprofile({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final settingController = Get.put(SettingController());
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            settingController.showLogOutDialog();
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
          "Create Your Profile",
          style: GoogleFonts.notoSans(
            // fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: [0.2, 0.6],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 30.h),
                          _buildInputField(
                            "First Name",
                            controller.firstNameController,
                          ),
                          SizedBox(height: 15.h),
                          _buildInputField(
                            "Last Name",
                            controller.lastNameController,
                          ),
                          SizedBox(height: 15.h),

                          // Bio Input Field
                          TextFormField(
                            controller: controller.bioController,
                            maxLines: 7,
                            style: GoogleFonts.notoSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 25.w,
                                vertical: 20.h,
                              ),
                              hintText: "Write a bio (optional)...",
                              hintStyle: GoogleFonts.notoSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.hintTextColor,
                              ),
                              border: _outlineInputBorder(),
                              enabledBorder: _outlineInputBorder(),
                              focusedBorder: _outlineInputBorder(
                                isFocused: true,
                              ),
                              filled: true,
                              fillColor: AppColors.inputFillColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Container(
                      width: double.infinity,
                      height: 45.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.btnGradientLeft,
                            AppColors.btnGradientRight,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (formKey.currentState!.validate()) {
                            controller.setBasicInfo(
                              fName: controller.firstNameController.text,
                              lName: controller.lastNameController.text,
                              userBio: controller.bioController.text,
                            );
                            await controller.saveNameOnServer();
                            Get.toNamed(Routes.chooseBody);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.notoSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ইনপুট ফিল্ড বিল্ডার ফাংশন
  Widget _buildInputField(String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.notoSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "This field is required";
        }
        return null;
      },
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.hintTextColor,
        ),
        border: _outlineInputBorder(),
        enabledBorder: _outlineInputBorder(),
        focusedBorder: _outlineInputBorder(isFocused: true),
        filled: true,
        fillColor: AppColors.inputFillColor,
      ),
    );
  }

  OutlineInputBorder _outlineInputBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.r),
      borderSide: BorderSide(
        color: AppColors.inputBorderColor,
        width: isFocused ? 2.0.w : 1.5.w,
      ),
    );
  }
}
