import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Network_Manager/app_version_service.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// The wall a user on an out-of-date build hits instead of the app.
///
/// Shown via `Get.offAll(...)` so there is no route left underneath, and
/// wrapped in a `PopScope(canPop: false)` so the Android back gesture can't
/// get around it either. The only ways out are updating or closing the app —
/// which is the whole point of a force update.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.status});

  final AppVersionStatus status;

  Future<void> _openStore() async {
    final uri = Uri.tryParse(status.storeUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      log('❌ Could not open store link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final message =
        status.message.trim().isNotEmpty
            ? status.message.trim()
            : 'A new version of OutSpot is available. Please update to '
                'continue using the app.';

    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: [0.0, 0.6],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/Images/logoImage.png', scale: 4.5),
                  SizedBox(height: 28.h),
                  Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 14.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.btnGradientLeft,
                            AppColors.btnGradientRight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30.r),
                          onTap: _openStore,
                          child: Center(
                            child: Text(
                              'Update Now',
                              style: GoogleFonts.notoSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    // The store takes a while to show a freshly published
                    // build, so give people a way out that isn't force-killing
                    // the app from the task switcher.
                    onPressed: () => SystemNavigator.pop(),
                    child: Text(
                      'Close App',
                      style: GoogleFonts.notoSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withValues(alpha: 0.6),
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
}
