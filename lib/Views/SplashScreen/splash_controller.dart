import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/app_version_service.dart';
import 'package:outspot/Network_Manager/app_review_service.dart';
import 'package:outspot/Views/SplashScreen/force_update_screen.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/main.dart' show initNotification, getFcmToken;
import 'package:outspot/Utils/app_snackbar.dart';

class SplashController extends GetxController {
  var firstname = ''.obs;
  var lastname = ''.obs;
  var bodyType = ''.obs;
  var bodyShapeUrl = ''.obs;
  RxList minimeList = [].obs;

  @override
  void onInit() {
    super.onInit();
    _startSplash();
  }

  Future<void> _startSplash() async {
    // Runs before anything else, including the login check: a blocked build
    // must not reach the main screen by any route. The check fails open, so
    // an unreachable server just falls through to the normal flow.
    final version = await AppVersionService.check();
    if (version.updateRequired) {
      log("🚫 Build is below the minimum — blocking on the update screen");
      Get.offAll(() => ForceUpdateScreen(status: version));
      return;
    }

    // One launch = one tick towards the review prompt. Counted here because
    // splash runs exactly once per cold start; counting inside Explore would
    // tick on every tab switch instead.
    AppReviewService.registerAppOpen();

    final destination = await _resolveDestination();
    Get.offAllNamed(destination.route, arguments: destination.arguments);
    _initializeNotifications();

    if (destination.snackbar != null) {
      destination.snackbar!();
    }
  }

  /// Determines where to navigate without actually navigating
  Future<_NavDestination> _resolveDestination() async {
    bool isLogged = await UserPreference.isLoggedIn();
    bool stayLogin = await UserPreference.getRememberMe();

    if (!isLogged || !stayLogin) {
      await UserPreference.saveIsLoggedIn(false);
      return _NavDestination(Routes.launchScreen);
    }

    bool hasInternet = await CustomWidgets().checkInternet();
    if (!hasInternet) {
      CustomWidgets().showNoInternetSnackbar();
      log("❌ No internet connection");
      return _NavDestination(Routes.launchScreen);
    }

    try {
      // Time-box the profile fetch so a hung/slow request can't trap the user
      // on the splash forever (it used to await with no timeout).
      final response = await ApiService.fetchUserProfile().timeout(
        const Duration(seconds: 12),
      );

      if (response.statusCode == 409) {
        await UserPreference.saveIsLoggedIn(false);
        return _NavDestination(
          Routes.launchScreen,
          snackbar:
              () => AppSnackbar.info(
                "Because Your account is logged in on another device.",
                title: "Logged Out",
              ),
        );
      } else if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"] ?? '';

        // Persist our own user id every launch (covers phone/OTP signups that
        // don't save it at auth time) so "is this me?" checks work correctly.
        if (data is Map) {
          final rawId = data["id"];
          final uid = rawId is int ? rawId : int.tryParse('${rawId ?? ''}');
          if (uid != null && uid != 0) {
            await UserPreference.saveUserId(uid);
          }
        }

        firstname.value = data["firstName"] ?? '';
        lastname.value = data["lastName"] ?? '';
        bodyType.value = data["bodyType"] ?? '';
        bodyShapeUrl.value = data["bodyShapeUrl"] ?? '';
        minimeList.value = data["minime"] ?? [];
        log("firstname:${firstname.value}");
        log("minime:${minimeList}");
        log(data.toString());

        if (firstname.value.isEmpty ||
            lastname.value.isEmpty ||
            bodyType.value.isEmpty ||
            bodyShapeUrl.value.isEmpty ||
            minimeList.isEmpty) {
          return _NavDestination(Routes.createProfile);
        } else {
          return _NavDestination(Routes.mainscreen, arguments: {"tab": 5});
        }
      } else {
        log("❌ Server error: ${response.statusCode}");
        return _NavDestination(Routes.launchScreen);
      }
    } on TimeoutException catch (_) {
      // Profile fetch timed out, but the user is already logged in (checked
      // above) — don't strand them on splash or bounce to login; go to main.
      log("⏱️ Profile fetch timed out — proceeding to main");
      return _NavDestination(Routes.mainscreen, arguments: {"tab": 5});
    } catch (e) {
      log("❌ Splash check error: $e");
      return _NavDestination(Routes.launchScreen);
    }
  }

  /// Initialize notifications and FCM token after UI is loaded
  Future<void> _initializeNotifications() async {
    try {
      await initNotification();
      await getFcmToken();
      log("✅ Notifications initialized successfully");
    } catch (e) {
      log("❌ Error initializing notifications: $e");
    }
  }
}

class _NavDestination {
  final String route;
  final Map<String, dynamic>? arguments;
  final VoidCallback? snackbar;

  _NavDestination(this.route, {this.arguments, this.snackbar});
}
