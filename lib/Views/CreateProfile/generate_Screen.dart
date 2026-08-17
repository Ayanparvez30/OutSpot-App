import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';
import 'package:outspot/Views/waredrop/waredrop_controller.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late Timer _timer;
  int _seconds = 0;
  late final Map<String, dynamic>? _args =
      Get.arguments as Map<String, dynamic>?;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    try {
      dynamic controller;

      if (Get.isRegistered<WaredropController>()) {
        controller = Get.find<WaredropController>();
      } else {
        controller = Get.find<CreateprofileController>();
      }

      final arguments = await controller.processAndSaveOutfit();
      Get.offNamed(Routes.previewMinime, arguments: arguments);
      // Get.snackbar('Success', 'Mini‑Me outfit saved ✅');
    } catch (e) {
      AppToast.error('Bad request:500');
      Get.back();
    }
  }

  // Future<void> _startGeneration() async {
  //   try {
  //     final controller = Get.find<CreateprofileController>();
  //     final arguments = await controller.processAndSaveOutfit();
  //     Get.offNamed(Routes.previewMinime, arguments: arguments);
  //     Get.snackbar('Success', 'Mini‑Me outfit saved ✅');

  //   } catch (e) {

  //     Get.snackbar('Error', e.toString());
  //     Get.back();
  //   }
  // }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animation
                Lottie.asset(
                  'assets/Images/vertopal.com_Animation - 1746656287165.json',
                  height: 200.h,
                  width: 200.w,
                ),
                SizedBox(height: 20.h),

                Text(
                  'Generating',
                  style: GoogleFonts.notoSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    'Please wait a moment while we create your unique Mini‑Me.This may take 1-2 Minutes',
                    style: GoogleFonts.notoSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 25.h),

                // Timer Text
                Text(
                  _formatTime(_seconds),
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // String _formatTime(int sec) {
  //   final m = (sec ~/ 60).toString().padLeft(2, '0');
  //   final s = (sec % 60).toString().padLeft(2, '0');
  //   return '$m:$s';
  // }
}
