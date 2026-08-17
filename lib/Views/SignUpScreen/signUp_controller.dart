import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import '../../Utils/app_loading.dart';
import '../../Utils/colors.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class SignupController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPassController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController referralController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  var tempToken = ''.obs;
  var isEmailTab = true.obs;
  var isPasswordHidden = true.obs;
  var isRepPasswordHidden = true.obs;
  var ageChecked = false.obs;
  // Apple 1.2: user must agree to Terms of Use (EULA) + Privacy Policy before
  // they can register.
  var termsChecked = false.obs;
  var selectedCountryCode = '+1'.obs;
  var tempSignupResponseData = {}.obs;
  var referralState = 'INPUT'.obs;
  var isLoading = false.obs;

  // True when every field for the active tab is filled. Drives the Get Started
  // button's enabled (vs greyed) state, alongside the two checkboxes.
  final isFormFilled = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Recompute whenever any field changes so the button reacts to typing.
    for (final c in [
      usernameController,
      emailController,
      phoneController,
      passwordController,
      repeatPassController,
    ]) {
      c.addListener(_updateFormFilled);
    }
    // Switching tabs changes which field (email vs phone) is required.
    isEmailTab.listen((_) => _updateFormFilled());
    _updateFormFilled();
  }

  void _updateFormFilled() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final repeat = repeatPassController.text.trim();
    final common =
        username.isNotEmpty && password.isNotEmpty && repeat.isNotEmpty;
    isFormFilled.value =
        isEmailTab.value
            ? common && emailController.text.trim().isNotEmpty
            : common && phoneController.text.trim().isNotEmpty;
  }

  void toggleRememberMe(bool? value) {
    ageChecked.value = value ?? false;
  }

  void toggleTab(bool isEmail) {
    isEmailTab.value = isEmail;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleRepPasswordVisibility() {
    isRepPasswordHidden.value = !isRepPasswordHidden.value;
  }

  Future<void> signUp(email, username, password, repeatPassword) async {
    bool hasInternet = await CustomWidgets().checkInternet();
    if (!hasInternet) {
      CustomWidgets().showNoInternetSnackbar();
      log("❌ No internet connection for loadUserProfile");

      return;
    }
    try {
      isLoading.value = true;
      // EasyLoading.show(status: 'Signing up...');
      AppLoading.show();

      final body = {
        'email': email,
        'username': username,
        'password': password,
        'repeatPassword': repeatPassword,
        'referralCode': referralController.text.trim(),
      };
      log('Signup body: $body');

      final response = await ApiService.signUp(body);
      log('Signup response: ${response.statusCode} - ${response.body}');

      isLoading.value = false;
      // EasyLoading.dismiss();
      AppLoading.hide();

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final String message = responseJson['message']?.toString() ?? '';
      final Map<String, dynamic>? data = responseJson['data'];
      final Map<String, dynamic>? user = data?['user'];

      if (response.statusCode == 200 && responseJson['status'] == true) {
        if (data != null && data['pendingSignupToken'] != null) {
          tempToken.value = data['pendingSignupToken'].toString();
        }

        final bool isNewUser = data?['isNewUser'] ?? false;
        final bool isVerified = user?['isVerified'] ?? false;

        if (!isNewUser && isVerified) {
          AppSnackbar.error(
            'User already exists. Please login now.',
            title: 'Signup Failed',
          );
          return;
        }

        Get.toNamed(
          Routes.otpScreen,
          arguments: {
            'email': email, 
            'isEmailTab': isEmailTab.value,
            'pendingSignupToken': tempToken.value,
          },
        );

        AppSnackbar.info(
          isNewUser
              ? 'A verification code has been sent to your email.'
              : 'OTP resent to your email. Please verify.',
          title: 'Verification Sent',
        );
      } else {
        // Server responded but with error status
        AppSnackbar.error(
          message.isNotEmpty ? message : 'Signup failed. Please try again.',
          title: 'Signup Failed',
        );
      }
    } catch (e) {
      isLoading.value = false;
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error('Something went wrong: $e');
      log('Signup error: $e');
    }
  }

  Future<void> phoneSignUpWithFirebase({
    required String username,
    required String phone,
    required String countryCode,
    required String password,
    required String repeatPassword,
  }) async {
    final fullPhone = '$countryCode$phone';
    if (phone.trim().isEmpty) {
      AppSnackbar.error('Please enter a phone number.');
      return;
    }
    bool hasInternet = await CustomWidgets().checkInternet();
    if (!hasInternet) {
      CustomWidgets().showNoInternetSnackbar();
      log("❌ No internet connection");

      return;
    }

    try {
      isLoading.value = true;
      // EasyLoading.show(status: 'Signing up...');
      AppLoading.show();

      final res = await ApiService.signUp({
        'username': username,
        'phone': phone,
        'countryCode': countryCode,
        'password': password,
        'repeatPassword': repeatPassword,
        'referralCode': referralController.text.trim(),
      });

      final raw = jsonDecode(res.body);
      final Map<String, dynamic> resp =
          (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final Map<String, dynamic> data =
          (resp['data'] as Map?)?.cast<String, dynamic>() ?? {};
      final Map<String, dynamic> user =
          (data['user'] as Map?)?.cast<String, dynamic>() ?? {};

      if (res.statusCode != 200 || resp['status'] != true) {
        // EasyLoading.dismiss();
        AppLoading.hide();

        AppSnackbar.error(
          resp['message']?.toString() ?? 'Signup failed',
          title: 'Signup Failed',
        );
        return;
      }

      if (data['pendingSignupToken'] != null) {
        tempToken.value = data['pendingSignupToken'].toString();
        log("Temp Token Saved: ${tempToken.value}");
      }

      final bool isNewUser = data['isNewUser'] == true;
      final bool isVerified = user['isVerified'] == true;
      if (!isNewUser && isVerified) {
        // EasyLoading.dismiss();
        AppLoading.hide();

        AppSnackbar.error(
          'User already exists. Please login now.',
          title: 'Signup Failed',
        );
        return;
      }

      // EasyLoading.show(status: 'Sending OTP...');
      AppLoading.show();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,

        verificationCompleted: (PhoneAuthCredential credential) {
          log(
            'Auto verification credential received; will verify on OTP screen.',
          );
        },

        verificationFailed: (FirebaseAuthException e) {
          // EasyLoading.dismiss();
          AppLoading.hide();

          AppSnackbar.error(
            e.message ?? 'Phone signUp failed',
            title: 'Signup Failed',
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          // EasyLoading.dismiss();
          AppLoading.hide();

          AppSnackbar.info(
            'OTP sent to $fullPhone',
            title: 'Verification Sent',
          );

          Get.toNamed(
            Routes.otpScreen,
            arguments: {
              'verificationId': verificationId,
              'resendToken': resendToken,
              'phoneNumber': fullPhone,
              'isEmailTab': false,
              'pendingSignupToken': tempToken.value,
            },
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error('Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyReferralCode(String code) async {
    try {
      referralState.value = 'LOADING';

      Map<String, dynamic> body = {};

      if (isEmailTab.value) {
        body = {
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'password': passwordController.text.trim(),
          'repeatPassword': repeatPassController.text.trim(),
          'referralCode': code,
        };
        log(body.toString());
      } else {
        body = {
          'username': usernameController.text.trim(),
          'phone': phoneController.text.trim(),
          'countryCode': selectedCountryCode.value,
          'password': passwordController.text.trim(),
          'repeatPassword': repeatPassController.text.trim(),
          'referralCode': code,
        };
        log(body.toString());
      }

      final response = await ApiService.signUp(body);
      final jsonResponse = jsonDecode(response.body);

      log("Signup Check Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        tempSignupResponseData.value = jsonResponse;

        final data = jsonResponse['data'];
        if (data != null && data['pendingSignupToken'] != null) {
          tempToken.value = data['pendingSignupToken'].toString();
          log("Referral Flow -> Pending Token Saved: ${tempToken.value}");
        }
        tempSignupResponseData.value = jsonResponse;
        referralState.value = 'SUCCESS';
      } else {
        String msg = jsonResponse['message']?.toString() ?? '';

        if (response.statusCode == 400 &&
            msg.toLowerCase().contains("referral")) {
          referralState.value = 'ERROR';
        } else {
          Get.back();
          AppSnackbar.error(msg, title: "Signup Failed");
          referralState.value = 'INPUT';
        }
      }
    } catch (e) {
      log("Verification Error: $e");
      referralState.value = 'ERROR';
    }
  }

  void proceedToOtpFromDialog() async {
    final data = tempSignupResponseData['data'];

    if (isEmailTab.value) {
      Get.toNamed(
        Routes.otpScreen,
        arguments: {
          'email': emailController.text.trim(), 
          'isEmailTab': true,
          'pendingSignupToken': tempToken.value,
        },
      );
    } else {
      final String fullPhone =
          selectedCountryCode.value + phoneController.text.trim();
      if (phoneController.text.trim().isEmpty) {
        AppSnackbar.error('Please enter a phone number.');
        return;
      }

      // EasyLoading.show(status: 'Sending OTP...');
      AppLoading.show();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,

        verificationCompleted: (PhoneAuthCredential credential) {
          log('Auto verification completed inside dialog flow');
        },

        verificationFailed: (FirebaseAuthException e) {
          // EasyLoading.dismiss();
          AppLoading.hide();

          AppSnackbar.error(
            e.message ?? 'Phone verification failed',
            title: 'Verification Failed',
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          // EasyLoading.dismiss();
          AppLoading.hide();

          AppSnackbar.info('Code sent to $fullPhone', title: 'OTP Sent');

          Get.toNamed(
            Routes.otpScreen,
            arguments: {
              'verificationId': verificationId,
              'resendToken': resendToken,
              'phoneNumber': fullPhone,
              'isEmailTab': false,
              'pendingSignupToken': tempToken.value,
            },
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }
  }

  void referralDialog() {
    Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "Referral Code",

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
                  "Referral Code",
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
                  "Do you have a referral code of your\nfriend?",
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
                    referralDialogs();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.btnGradientLeft,
                          AppColors.btnGradientRight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      "Yes, I have code",
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
                  onPressed: () {
                    Get.back();
                    referralController.clear();
                    if (isEmailTab.value == true) {
                      signUp(
                        emailController.text.trim(),
                        usernameController.text.trim(),
                        passwordController.text.trim(),
                        repeatPassController.text.trim(),
                      );
                    } else {
                      phoneSignUpWithFirebase(
                        username: usernameController.text.trim(),
                        phone: phoneController.text.trim(),
                        countryCode: selectedCountryCode.value,
                        password: passwordController.text.trim(),
                        repeatPassword: repeatPassController.text.trim(),
                      );
                    }
                  },
                  child: Text(
                    "No, I don't have code",
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

      transitionDuration: const Duration(milliseconds: 400),

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        final scaleAnimation = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(curved);

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }

  void referralDialogs() {
    referralState.value = 'INPUT';
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "Referral Logic",
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Obx(() {
              if (referralState.value == 'LOADING') {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Lottie.asset(
                          'assets/Images/loadingAnimation.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "Verifying...",
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 14.sp,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 50.h),
                  ],
                );
              } else if (referralState.value == 'ERROR') {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30.h),
                    UnconstrainedBox(
                      child: SvgPicture.asset(
                        "assets/svg/warnin.svg",

                        // fit: BoxFit.scaleDown,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      "No Spot Found",
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Looks like this user hasn’t made their\nmark yet.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        decoration: TextDecoration.none,
                        fontSize: 14.sp,
                        color: AppColors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 25.h),
                    GestureDetector(
                      onTap: () {
                        referralState.value = 'INPUT';
                      },
                      child: Container(
                        width: double.infinity,
                        height: 45.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color(0xffF8AC00),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          "Try Again",
                          style: GoogleFonts.notoSans(
                            decoration: TextDecoration.none,
                            fontSize: 16.sp,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                );
              } else if (referralState.value == 'SUCCESS') {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30.h),
                    UnconstrainedBox(
                      child: SvgPicture.asset(
                        "assets/svg/Check_Circle.svg",
                        // fit: BoxFit.scaleDown,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      "Spot Confirmed",
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
                      "Your friend’s username is registered in\nour app. Tap Continue to proceed.",
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

                        proceedToOtpFromDialog();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 45.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.btnGradientLeft,
                              AppColors.btnGradientRight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          "Continue",
                          style: GoogleFonts.notoSans(
                            decoration: TextDecoration.none,
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                );
              } else {
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 15.h),
                      Text(
                        "Referral Code",
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
                        "Enter the username of your friend\nthat referred you.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          decoration: TextDecoration.none,
                          fontSize: 15.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 25.h),
                      TextFormField(
                        controller: referralController,
                        cursorColor: AppColors.white,
                        style: GoogleFonts.notoSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        validator:
                            (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Referral code is required'
                                    : null,
                        decoration: InputDecoration(
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: UnconstrainedBox(
                              child: SvgPicture.asset(
                                "assets/svg/icons/person_icon.svg",
                                width: 22.r,
                                height: 22.r,
                                // fit: BoxFit.scaleDown,
                              ),
                            ),
                          ),
                          hintText: "e.g. juandelacruz123",
                          hintStyle: GoogleFonts.notoSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inputBorderColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: BorderSide(
                              color: AppColors.inputBorderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: BorderSide(
                              color: AppColors.inputBorderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: BorderSide(
                              color: AppColors.inputBorderColor,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          filled: true,
                          fillColor: AppColors.inputFillColor,
                        ),
                      ),
                      SizedBox(height: 25.h),

                      GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (formKey.currentState!.validate()) {
                            verifyReferralCode(referralController.text.trim());
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 45.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.btnGradientLeft,
                                AppColors.btnGradientRight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            "Continue",
                            style: GoogleFonts.notoSans(
                              decoration: TextDecoration.none,
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5.h),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          referralController.clear();

                          // if (isEmailTab.value == true) {
                          //   signUp(
                          //     emailController.text.trim(),
                          //     usernameController.text.trim(),
                          //     passwordController.text.trim(),
                          //     repeatPassController.text.trim(),
                          //   );
                          // } else {
                          //   phoneSignUpWithFirebase(
                          //     username: usernameController.text.trim(),
                          //     phone: phoneController.text.trim(),
                          //     countryCode: selectedCountryCode.value,
                          //     password: passwordController.text.trim(),
                          //     repeatPassword: repeatPassController.text.trim(),
                          //   );
                          // }
                        },
                        child: Text(
                          "Go Back",
                          style: GoogleFonts.notoSans(
                            color: const Color(0xff704EF9),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                );
              }
            }),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scaleAnimation = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }
}
