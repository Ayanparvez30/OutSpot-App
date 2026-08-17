import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/colors.dart';

class CustomWidgets {
  Future<bool> checkInternet() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  void showNoInternetSnackbar() {
    AppSnackbar.warning(
      "Please check your internet connection and try again.",
      title: "No Internet Connection",
    );
  }

  Widget customTextField({
    List<TextInputFormatter>? inputFormatters,
    required String hint,
    Widget? suffixIcon,
    Widget? prefix,
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    int maxLines = 1,
    int? minLines,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      validator: validator,
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      cursorColor: AppColors.white,
      style: GoogleFonts.notoSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),

      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        prefix: prefix,

        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.inputBorderColor,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.r),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.r),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.r),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),

        filled: true,
        fillColor: AppColors.inputFillColor,
      ),
    );
  }

  Widget CustomButton({required String text, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();

        onPressed();
      },
      child: Container(
        width: double.infinity,
        height: 45.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.btnGradientLeft, AppColors.btnGradientRight],
          ),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          text,
          style: GoogleFonts.notoSans(
            decoration: TextDecoration.none,
            fontSize: 16.sp,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void showSaveDialogue({
    required String title,
    required String subtitle,
    String? nextRoute,
  }) {
    Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "Save Dialog",

      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie.asset(
                //   'assets/Images/StLVUMuJmA.json',
                //   height: 170.h,
                //   width: 170.w,
                // ),
                SizedBox(height: 30.h),
                UnconstrainedBox(
                  child: SvgPicture.asset(
                    "assets/svg/Check_Circle.svg",
                    // fit: BoxFit.scaleDown,
                  ),
                ),
                SizedBox(height: 40.h),

                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    // color: const Color(0xff000000),
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 15.sp,
                    // color: const Color(0xff000000),
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      },

      transitionDuration: const Duration(milliseconds: 600),

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.6),
          end: Offset.zero,
        ).animate(curved);

        final scaleAnimation = Tween<double>(
          begin: 0.96,
          end: 1.0,
        ).animate(curved);

        return SlideTransition(
          position: offsetAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (nextRoute != null) {
        Get.until((route) => route.settings.name == nextRoute);
      } else {
        Get.back();
      }
    });
  }
}
