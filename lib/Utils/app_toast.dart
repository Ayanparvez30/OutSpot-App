import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppToast {
  AppToast._();

  static void success(String message) {
    _show(
      message: message,
      icon: Icons.check_circle_rounded,
      accentColor: const Color(0xff42D880),
    );
  }

  static void error(String message) {
    _show(
      message: message,
      icon: Icons.error_rounded,
      accentColor: const Color(0xffDD4141),
    );
  }

  static void info(String message) {
    _show(
      message: message,
      icon: Icons.info_rounded,
      accentColor: const Color(0xffC574F7),
    );
  }

  static void warning(String message) {
    _show(
      message: message,
      icon: Icons.warning_rounded,
      accentColor: const Color(0xffF8AC00),
    );
  }

  static void _show({
    required String message,
    required IconData icon,
    required Color accentColor,
  }) {
    final context = Get.context;
    if (context == null) return;

    FToast fToast = FToast();
    fToast.init(context);

    fToast.removeCustomToast();

    Widget toast = Container(
      margin: EdgeInsets.only(bottom: 35.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E0C47).withOpacity(0.95),
            const Color(0xFF1C011F).withOpacity(0.95),
          ],
        ),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 20.r),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
    );
  }
}
