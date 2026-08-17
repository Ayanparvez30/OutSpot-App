import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(String message, {String title = 'Success'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      accentColor: const Color(0xff42D880),
    );
  }

  static void error(String message, {String title = 'Error'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.error_rounded,
      accentColor: const Color(0xffDD4141),
    );
  }

  static void info(String message, {String title = 'Info'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.info_rounded,
      accentColor: const Color(0xff42D880),
    );
  }

  static void warning(String message, {String title = 'Warning'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.warning_rounded,
      accentColor: const Color(0xffF8AC00),
    );
  }

  static void _show({
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      icon: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 22.r),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1C011F).withValues(alpha: 0.92),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2E0C47).withValues(alpha: 0.95),
          const Color(0xFF1C011F).withValues(alpha: 0.95),
        ],
      ),
      borderColor: accentColor.withValues(alpha: 0.3),
      borderWidth: 1,
      borderRadius: 16.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      boxShadows: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
