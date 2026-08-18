import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Network_Manager/video_cache_service.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/CommonWidgets/ReviewWidgets/review_sheet.dart';
import 'package:outspot/Network_Manager/app_review_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Views/Challenges/ChallengeManager.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Utils/app_loading.dart';

class SettingController extends GetxController {
  Map<String, dynamic>? userData;
  var isPrivate = false.obs;

  final ScrollController scrollController = ScrollController();
  var showDownArrow = false.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _loadCachedPrivacy();
    loadUserProfile();
    scrollController.addListener(_scrollListener);
  }

  /// The toggle's source of truth for the user's own privacy is the locally
  /// saved value — the server's stats/profile isPrivate is viewer-relative
  /// (false for your own view), so it can't be trusted to show your setting.
  Future<void> _loadCachedPrivacy() async {
    final cached = await UserPreference.getProfilePrivacy();
    if (cached != null) isPrivate.value = cached;
  }

  @override
  void onReady() {
    super.onReady();

    _checkIfScrollable();
  }

  void _checkIfScrollable() {
    if (scrollController.hasClients) {
      showDownArrow.value =
          scrollController.position.maxScrollExtent > 0 &&
          scrollController.position.pixels <
              scrollController.position.maxScrollExtent;
    }
  }

  void _scrollListener() {
    if (scrollController.hasClients) {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 10) {
        showDownArrow.value = false;
      } else {
        showDownArrow.value = true;
      }
    }
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      final double currentPosition = scrollController.position.pixels;
      final double maxPosition = scrollController.position.maxScrollExtent;
      final double nextPosition = (currentPosition + 200).clamp(
        0.0,
        maxPosition,
      );

      scrollController.animateTo(
        nextPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void handleTap(String item) {
    if (item == "Password") {
      Get.toNamed(Routes.passwordScreen);
    } else if (item == "My Name") {
      Get.toNamed(
        Routes.updateScreen,
        arguments: {
          "firstName": userData?["firstName"] ?? "",
          "lastName": userData?["lastName"] ?? "",
        },
      )?.then((_) => loadUserProfile());
    } else if (item == "My Username") {
      Get.toNamed(
        Routes.userName,
        arguments: {"username": userData?["username"] ?? ""},
      )?.then((_) => loadUserProfile());
    } else if (item == "Bio") {
      Get.toNamed(
        Routes.updateBio,
        arguments: {"bio": userData?["bio"] ?? ""},
      )?.then((_) => loadUserProfile());
    } else if (item == "Profile Visibility") {
      showModalBottomSheetFunctionProfileOptions2(Get.context!);
    } else if (item == "Blocked Accounts") {
      Get.toNamed(Routes.blockList);
      // Get.toNamed(Routes.mainscreen);
    } else if (item == "Contact Us") {
      Get.toNamed(Routes.contactUs);
    } else if (item == "Rate OutSpot") {
      openReviewSheet();
    } else if (item == "Privacy Policy") {
      openUrl("https://outspot.app/privacy-policy/");
    } else if (item == "Terms & Agreements") {
      openUrl("https://outspot.app/terms-and-conditions/");
    } else if (item == "Delete My Account") {
      showDeleteDialog();
      // Get.toNamed(Routes.myProfile);
    } else if (item == "Log Out") {
      showLogOutDialog();
    } else if (item == "Notifications") {
      Get.toNamed(Routes.settingnotification);
      // openAppSettings();
    }
  }

  /// Opens the review sheet, pre-filled with whatever this user wrote before
  /// so "Rate OutSpot" doubles as "edit my review". No "Later" button here —
  /// they came looking for it, so swiping the sheet away is enough.
  Future<void> openReviewSheet() async {
    final existing = await AppReviewService.fetchMyReview();
    await ReviewSheet.show(existing: existing);
  }

  Future<void> updateProfilePrivacy(bool newValue) async {
    try {
      final response = await ApiService.setProfilePrivacy(newValue);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['isProfilePrivate'] is bool) {
          // Raw lock state — the correct value to reflect in the toggle.
          isPrivate.value = data['isProfilePrivate'];
        } else {
          // Old server: don't read isPrivate (viewer-relative = false on /me).
          // The value we just sent IS the new lock state.
          isPrivate.value = newValue;
        }

        // Persist so the toggle reflects the user's own setting on next open
        // (server endpoints report isPrivate relative to the viewer).
        await UserPreference.saveProfilePrivacy(isPrivate.value);

        log("✅ Privacy updated locally to ${isPrivate.value}");
        log("✅ Server message: ${data['message'] ?? 'No message'}");
      } else {
        log("❌ Failed: ${response.statusCode}");
        throw Exception("Failed to update privacy");
      }
    } catch (e) {
      log("⚠️ Error updating privacy: $e");
      rethrow;
    }
  }

  Future<bool> togglePrivacy() async {
    final newValue = !isPrivate.value;
    try {
      await updateProfilePrivacy(newValue);
      return true;
    } catch (_) {
      return false;
    }
  }

  void openUrl(String urlStr) async {
    final url = Uri.parse(urlStr);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        AppSnackbar.error("Could not open url");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> logoutUser() async {
    try {
      AppLoading.show();
      // Try API logout, but clean up regardless of result
      try {
        await ApiService.logout();
      } catch (_) {}
      AppLoading.hide();
    } catch (_) {
      AppLoading.hide();
    }

    // Clear auth first, navigate, then cleanup
    await UserPreference.logout();
    await UserPreference.saveIsLoggedIn(false);

    await Future.delayed(const Duration(milliseconds: 500), () async {
      await cleanupAllSessionData();
      Get.offAllNamed(Routes.launchScreen);
    });
  }

  /// Clears ALL user data, caches, controllers, and local storage on logout.
  /// Called from logout, delete account, and 401 handler.
  /// Every step is wrapped in try-catch so one failure doesn't block the rest.
  static Future<void> cleanupAllSessionData() async {
    log('🧹 Session cleanup starting...');

    // ── 1. NETWORK: Stop all active network activity ──
    // Stop background video caching immediately
    try {
      VideoCacheService.instance.pause();
    } catch (_) {}

    // Disconnect socket (messaging)
    try {
      if (Get.isRegistered<MessagesScreenController>()) {
        Get.find<MessagesScreenController>().clearData();
      }
    } catch (_) {}

    // ── 2. AUTH: Clear all authentication state ──
    // Clear FCM token on server (stop push notifications for this device)
    try {
      await FirebaseMessaging.instance.deleteToken();
      log('🔑 FCM token deleted');
    } catch (_) {}

    // Sign out Firebase Auth
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    // ── 3. STORAGE: Clear all persisted data ──
    // SharedPreferences — ALL keys (token, profile, userId, cache, etc.)
    try {
      await UserPreference.clearAll();
    } catch (_) {}

    // DefaultCacheManager — cached videos and network files
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}

    // Flutter image cache — in-memory decoded images
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    // Temp directory — edited videos, exported images, processing files
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final f in tempDir.listSync()) {
          try {
            f.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}

    // App cache directory — CachedNetworkImage disk cache
    try {
      final cacheDir = await getTemporaryDirectory();
      final imgCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (imgCacheDir.existsSync()) {
        imgCacheDir.deleteSync(recursive: true);
      }
    } catch (_) {}

    // ── 4. SINGLETONS: Reset non-GetX singletons ──
    try {
      ChallengeManager.instance.clear();
    } catch (_) {}

    // ── 5. CONTROLLERS: Delete ALL GetX controllers ──
    // This disposes every controller (permanent or not), which triggers
    // each controller's onClose() — cleaning up streams, timers, etc.
    try {
      Get.deleteAll(force: true);
    } catch (_) {}

    // ── 6. RE-REGISTER essential app-wide services ──
    // These are needed before any screen loads after login
    try {
      Get.put(NotificationBadgeService());
    } catch (_) {}

    log('✅ Session cleanup complete — all user data cleared');
  }

  Future<void> deleteUserAccount() async {
    try {
      // EasyLoading.show(status: 'Deleting account...');
      AppLoading.show();

      final response = await ApiService.deleteAccount();

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        // Clear token and login state first to prevent any API calls
        await UserPreference.logout();
        await UserPreference.saveIsLoggedIn(false);

        // Navigate first, then cleanup controllers
        // This prevents blank screen from destroyed controllers
        Get.offAllNamed(Routes.launchScreen);

        // Cleanup after navigation is complete
        Future.delayed(const Duration(milliseconds: 500), () async {
          await cleanupAllSessionData();
        });
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? "Deletion failed";

        AppSnackbar.error(message);
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong: $e");
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];

        userData = {
          "username": data["username"],
          "firstName": data["firstName"],
          "lastName": data["lastName"],
          "bio": data["bio"],
        };

        // isProfilePrivate = the RAW lock state (true even for your own view),
        // so it's the real source of truth for the settings toggle. Trust it
        // directly and cache it.
        if (data["isProfilePrivate"] is bool) {
          isPrivate.value = data["isProfilePrivate"];
          await UserPreference.saveProfilePrivacy(isPrivate.value);
        } else if (data["isPrivate"] is bool) {
          // Backward-compat: old server without isProfilePrivate. isPrivate is
          // viewer-relative (false for self), so only seed when we have no
          // locally-saved value yet — else the local toggle is source of truth.
          final cached = await UserPreference.getProfilePrivacy();
          if (cached == null) {
            isPrivate.value = data["isPrivate"];
          }
        }

        log("✅ userData: $userData, isPrivate: ${isPrivate.value}");
      } else {
        log("❌ Server error: ${response.statusCode}");
        AppSnackbar.error("Server returned ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  void showLogOutDialog() {
    Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "LogOut",
      // transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.1),

          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),

            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10.h),
                Text(
                  "Log Out",
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  "Would you like to log out?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 15.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 25.h),

                CustomWidgets().CustomButton(
                  text: "Log Out",
                  onPressed: () {
                    Get.back();
                    logoutUser();
                  },
                ),

                SizedBox(height: 5.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Nevermind',
                    style: GoogleFonts.notoSans(
                      color: Color(0xff704EF9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        );
      },
      // transitionBuilder: (context, animation, secondaryAnimation, child) {
      //   final offsetAnimation = Tween<Offset>(
      //     begin: const Offset(1.0, 0.0), // from right
      //     end: Offset.zero,
      //   ).animate(animation);

      //   return SlideTransition(position: offsetAnimation, child: child);
      // },
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
  }

  void showDeleteDialog() {
    Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "Delete Account",

      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 15.h),
                Text(
                  "Delete Account",
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 14.h),
                Text(
                  // No hard-coded \n line breaks — they made the lines fixed
                  // length, so the block didn't stay centered across phone
                  // sizes. Let it soft-wrap; textAlign.center keeps every line
                  // centered on every screen.
                  "Are you sure you want to delete your account? Once you do this, it cannot be reversed!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 15.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 25.h),

                GestureDetector(
                  onTap: () {
                    Get.back();
                    deleteUserAccount();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xFFDD4141),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      "Delete Account",
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 16.sp,
                        color: Color(0xffFFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 5.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Nevermind',
                    style: GoogleFonts.notoSans(
                      color: Color(0xff704EF9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        );
      },
      // transitionBuilder: (context, animation, secondaryAnimation, child) {
      //   final offsetAnimation = Tween<Offset>(
      //     begin: const Offset(1.0, 0.0), // from right
      //     end: Offset.zero,
      //   ).animate(animation);

      //   return SlideTransition(position: offsetAnimation, child: child);
      // },
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
  }

  void showModalBottomSheetFunctionProfileOptions2(BuildContext context) {
    final controller = Get.find<SettingController>();

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: Color(0xff202122),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 2.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Profile Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h, color: Colors.black),

                Obx(
                  () => GestureDetector(
                    onTap: () async {
                      Get.back();

                      final success = await controller.togglePrivacy();

                      if (success) {
                        final isPrivate = controller.isPrivate.value;
                        AppSnackbar.info(
                          isPrivate
                              ? "Profile is now Private 🔒"
                              : "Profile is now Public 🌐",
                          title: "Privacy Updated",
                        );
                      } else {
                        AppSnackbar.error("Failed to update privacy");
                      }
                    },

                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 7.h),
                      child: Center(
                        child: Text(
                          controller.isPrivate.value
                              ? "Make Account Public"
                              : "Make Account Private",
                          style: TextStyle(
                            color: Color(0xffC574F7),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Divider(thickness: 0.6.h, color: Colors.black),
              ],
            ),
          ),
        );
      },
    );
  }
}
