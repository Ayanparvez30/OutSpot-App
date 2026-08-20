import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';
import 'package:outspot/Network_Manager/connectivity_service.dart';
import 'package:outspot/Utils/colors.dart';

/// What the user sees instead of a dead screen when the connection drops.
///
/// Raised over whatever they were on, from anywhere in the app, and taken away
/// again the moment the server answers — see [OfflineGate]. Nothing is
/// navigated, so their place in the app is exactly where they left it.
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<ConnectivityService>();

    return Container(
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
          // Scrolls rather than overflows: this has to hold up on a short
          // screen and in landscape, where the column is taller than the space.
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: figPx(32).w,
                    vertical: figPx(24).w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: figPx(88).w,
                        height: figPx(88).w,
                        decoration: BoxDecoration(
                          color: ExploreColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: ExploreColors.border),
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: figPx(38).w,
                          color: ExploreColors.closedNow,
                        ),
                      ),
                      SizedBox(height: figPx(24).w),

                      Text(
                        'No connection',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: figPx(22).sp,
                          fontWeight: FontWeight.w600,
                          color: ExploreColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: figPx(10).w),
                      Text(
                        'Check your internet connection and try again. '
                        'You\'ll be right back where you left off.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: figPx(13).sp,
                          height: 1.6,
                          color: ExploreColors.textMuted,
                        ),
                      ),
                      SizedBox(height: figPx(28).w),

                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: figPx(50).w,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.btnGradientLeft,
                                  AppColors.btnGradientRight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(figPx(28).w),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  figPx(28).w,
                                ),
                                // Disabled while a probe runs, so an impatient
                                // double-tap can't stack requests.
                                onTap:
                                    service.isChecking.value
                                        ? null
                                        : service.verify,
                                child: Center(
                                  child:
                                      service.isChecking.value
                                          ? SizedBox(
                                            width: figPx(20).w,
                                            height: figPx(20).w,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color:
                                                      ExploreColors.textPrimary,
                                                ),
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.refresh_rounded,
                                                size: figPx(18).w,
                                                color:
                                                    ExploreColors.textPrimary,
                                              ),
                                              SizedBox(width: figPx(8).w),
                                              Text(
                                                'Retry',
                                                style: GoogleFonts.notoSans(
                                                  fontSize: figPx(15).sp,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      ExploreColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: figPx(14).w),
                      Text(
                        'We check on our own too — this closes by itself once '
                        'you\'re back.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: figPx(11).sp,
                          color: ExploreColors.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the whole app and puts [OfflineScreen] over it whenever the server
/// can't be reached.
///
/// Sits in `GetMaterialApp.builder`, above the navigator, so every screen is
/// covered without any of them knowing about it — and because it's an overlay
/// rather than a route, nothing is pushed or popped and the back stack survives
/// the outage untouched.
class OfflineGate extends StatelessWidget {
  const OfflineGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Registered in main() before runApp; the guard keeps a hot reload or a
    // test that skips that step from crashing the whole tree.
    if (!Get.isRegistered<ConnectivityService>()) return child;
    final service = Get.find<ConnectivityService>();

    return Obx(
      () => Stack(
        children: [
          child,
          if (!service.isOnline.value)
            const Positioned.fill(child: OfflineScreen()),
        ],
      ),
    );
  }
}
