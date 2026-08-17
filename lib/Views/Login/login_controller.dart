import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';
import '../../Utils/app_toast.dart';

class LoginController extends GetxController {
  var firstname = ''.obs;
  var lastname = ''.obs;
  var bodyType = ''.obs;
  var bodyShapeUrl = ''.obs;
  RxList minimeList = [].obs;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;

  var isEmailTab = true.obs;
  var isPasswordHidden = true.obs;
  var rememberMe = true.obs;
  var selectedCountryCode = '+1'.obs;

  // True when every field for the active tab is filled. Drives the Log In
  // button's enabled (vs greyed) state.
  final isFormFilled = false.obs;

  void _updateFormFilled() {
    final password = passwordController.text.trim();
    isFormFilled.value =
        isEmailTab.value
            ? emailController.text.trim().isNotEmpty && password.isNotEmpty
            : phoneController.text.trim().isNotEmpty && password.isNotEmpty;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  void toggleTab(bool isEmail) {
    isEmailTab.value = isEmail;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    // Keep [isFormFilled] in sync so the Log In button enables only when the
    // active tab's fields are filled.
    for (final c in [emailController, phoneController, passwordController]) {
      c.addListener(_updateFormFilled);
    }
    isEmailTab.listen((_) => _updateFormFilled());
    _updateFormFilled();

    UserPreference.getToken().then((token) {
      log("Token after login: $token");
    });
  }

  Future<void> login(
    String identifier,
    String password, {
    bool forceLogin = false,
  }) async {
    bool hasInternet = await CustomWidgets().checkInternet();
    if (!hasInternet) {
      CustomWidgets().showNoInternetSnackbar();
      log("❌ No internet connection for loadUserProfile");

      return;
    }
    try {
      // EasyLoading.show(status: "Logging in...");
      AppLoading.show();
      final response = await ApiService.login({
        'identifier': identifier,
        'password': password,
        "forceLogin": forceLogin,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        final token = decoded['data']?['token'];
        final user = decoded['data']?['user'];

        if (token != null && token is String) {
          await UserPreference.saveToken(token);
          await UserPreference.saveEmail(user?['email'] ?? '');
          await UserPreference.saveIsLoggedIn(true);
          await UserPreference.saveRememberMe(rememberMe.value);
          if (user != null && user['id'] != null) {
            await UserPreference.saveUserId(user['id']);
          }

          loadUserProfile();

          try {
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              await ApiService.updateFcmToken(fcmToken);
            }
          } catch (fcmError) {
            log('FCM token error (non-fatal): $fcmError');
          }

          AppToast.success("Login Successfully");
        } else {
          throw Exception("Invalid token received.");
        }
      } else if (response.statusCode == 409) {
        showDuplicateLoginDialog(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        final errorMsg =
            decoded['message']?.toString() ?? "Something went wrong";
        AppSnackbar.error(errorMsg, title: "Login Failed");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      print("❌ Login Error: $e");

      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  Future<void> phoneLogin(phone, password, {bool forceLogin = false}) async {
    bool hasInternet = await CustomWidgets().checkInternet();
    if (!hasInternet) {
      CustomWidgets().showNoInternetSnackbar();
      log("❌ No internet connection for loadUserProfile");

      return;
    }
    try {
      // EasyLoading.show(status: "Logging in...");
      AppLoading.show();

      final response = await ApiService.login({
        'identifier': phone,
        'password': password,
        "forceLogin": forceLogin,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        final token = decoded['data']?['token'];
        final user = decoded['data']?['user'];

        if (token != null && token is String) {
          await UserPreference.saveToken(token);
          await UserPreference.saveEmail(user?['email'] ?? '');
          await UserPreference.saveIsLoggedIn(true);
          await UserPreference.saveRememberMe(rememberMe.value);
          loadUserProfile();

          AppToast.success("Login Successfully");
        } else {
          throw Exception("Invalid token received.");
        }
      } else if (response.statusCode == 409) {
        showDuplicateLoginDialog(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        final errorMsg =
            decoded['message']?.toString() ?? "Something went wrong";
        AppSnackbar.error(errorMsg, title: "Login Failed");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();
      print("❌ Login Error: $e");

      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  Future<void> loadUserProfile() async {
    try {
      log("Loading user profile...");
      final response = await ApiService.fetchUserProfile();
      log("Profile response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"] ?? '';
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
            bodyShapeUrl.value.isEmpty) {
          Get.offAllNamed(Routes.createProfile);
        } else if (minimeList.value.isEmpty) {
          Get.offAllNamed(Routes.createProfile);
        } else {
          Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
        }
      } else {
        log("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  void showDuplicateLoginDialog(String identifier, String password) {
    Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: "Duplicate Login",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.5),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10.h),
                Text(
                  "Duplicate Log In",
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xff000000),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  "You are already logged in on another\ndevice. Sign in here instead?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    decoration: TextDecoration.none,
                    fontSize: 15.sp,
                    color: const Color(0xff000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 25.h),

                CustomWidgets().CustomButton(
                  text: "Sign out other device",
                  onPressed: () {
                    Get.back();
                    login(identifier, password, forceLogin: true);
                  },
                ),

                SizedBox(height: 5.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.notoSans(
                      color: Colors.black,
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
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
