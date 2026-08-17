import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/SignUpScreen/signUp_controller.dart';

import '../../Utils/app_loading.dart';

class OtpController extends GetxController {
  TextEditingController otpController = TextEditingController();
  var canResendOtp = true.obs;
  var countdown = 30.obs;

  Timer? _timer;
  String email = '';
  int? resendToken;
  late String verificationId;
  late String phoneNumber;
  late String username;
  var pendingTokenFromSignup = ''.obs;
  String gettingArgs = '';
  var isLoading = false.obs;
  var isEmailTab = true.obs;

  @override
  void onInit() {
    super.onInit();

    // Clear previous OTP input
    otpController.clear();

    // Reset timer state
    _timer?.cancel();
    canResendOtp.value = true;
    countdown.value = 30;

    final args = Get.arguments;
    if (args != null) {
      gettingArgs = args['email'] ?? '';
      verificationId = args['verificationId'] ?? '';
      phoneNumber = args['phoneNumber'] ?? '';

      isEmailTab.value = args['isEmailTab'] ?? true;
      if (args['pendingSignupToken'] != null) {
        pendingTokenFromSignup.value = args['pendingSignupToken'].toString();
      }
      log("Pending Token: ${pendingTokenFromSignup.value}");
    }

    log(phoneNumber);
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  void resendOtpToEmail(BuildContext context) async {
    if (!canResendOtp.value) return;

    canResendOtp.value = false;
    startCountdown();
  }

  void startCountdown() {
    countdown.value = 30;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      countdown.value--;
      if (countdown.value <= 0) {
        timer.cancel();
        canResendOtp.value = true;
      }
    });
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      // EasyLoading.show(status: "Verifying...");
      AppLoading.show();

      final response = await ApiService.verifyOtp({
        'email': email,
        'otp': code,
        if (pendingTokenFromSignup.value.isNotEmpty)
          'pendingSignupToken': pendingTokenFromSignup.value,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        // final userModel = Usermodel.fromRawJson(response.body);
        final Map<String, dynamic> decoded = jsonDecode(response.body);

        final token = decoded['data']?['token'];

        await UserPreference.saveToken(token);
        // await UserPreference.saveEmail(userModel.data.email);
        await UserPreference.saveIsLoggedIn(true);
        await UserPreference.saveRememberMe(true);

        // FCM token - wrapped in try-catch to handle iOS APNS issues
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await ApiService.updateFcmToken(fcmToken);
          }
        } catch (fcmError) {
          log('FCM token error (non-fatal): $fcmError');
        }
        log(token);

        AppSnackbar.success('Verification complete!');
        // final signupcontroller = Get.find<SignupController>();
        // signupcontroller.signupEmailControler.clear();
        // signupcontroller.passwordController.clear();
        // signupcontroller.rePasswordController.clear();

        Get.offAllNamed(Routes.createProfile);
      } else {
        final json = jsonDecode(response.body);
        final message = json['message'] ?? 'Invalid OTP. Please try again.';
        AppSnackbar.error(message, title: 'Verification Failed');

        final lowerMsg = message.toString().toLowerCase();
        if (lowerMsg.contains('expired') ||
            lowerMsg.contains('invalid or expired pendingsignuptoken')) {
          Get.offAllNamed(Routes.signUpScreen);
        }
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error('An error occurred: $e');
      log('OTP verification error: $e');
      print(e);
    }
  }

  Future<void> verifyOtpAndSaveUser({
    required String smsCode,
    required String verificationId,
    required String phone,
  }) async {
    try {
      isLoading.value = true;
      // EasyLoading.show(status: 'Verifying OTP...');
      AppLoading.show();

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCred.user;
      if (user == null) throw Exception("Firebase user not found");

      final firebaseIdToken = await user.getIdToken(true);
      log('Firebase ID Token: $firebaseIdToken');

      await FirebaseAuth.instance.signOut();
      log('Signed out from Firebase locally.');
      final response = await ApiService.phoneOtp({
        'phone': phone,
        'firebaseIdToken': firebaseIdToken,
        "pendingSignupToken": pendingTokenFromSignup.value,
      });

      final raw = jsonDecode(response.body);
      final Map<String, dynamic> responseJson =
          (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200 && (responseJson['status'] == true)) {
        final serverToken =
            (responseJson['data']?['token'] ?? firebaseIdToken).toString();

        await UserPreference.saveToken(serverToken);
        await UserPreference.saveIsLoggedIn(true);
        await UserPreference.saveRememberMe(true);

        log('Token saved: $serverToken');

        AppSnackbar.success('Phone verified & user created successfully');

        Get.offAllNamed(Routes.createProfile);
      } else {
        final msg = responseJson['message']?.toString() ?? 'Signup failed';
        throw Exception(msg);
      }
    } on FirebaseAuthException catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      String errorMessage = 'OTP verification failed. Please try again.';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP. Please enter the correct code.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP session expired. Please request a new code.';
      } else if ((e.message ?? '').isNotEmpty) {
        errorMessage = e.message!;
      }
      AppSnackbar.error(errorMessage);
      log(errorMessage);
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error(e.toString().replaceAll('Exception: ', ''));
      log(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOTPFunction(String email) async {
    try {
      isLoading.value = true;
      // EasyLoading.show(status: 'Sending OTP...');
      AppLoading.show();

      dynamic response;
      if (pendingTokenFromSignup.value.isNotEmpty &&
          Get.isRegistered<SignupController>()) {
        final signupController = Get.find<SignupController>();
        final body = {
          'email': email,
          'username': signupController.usernameController.text.trim(),
          'password': signupController.passwordController.text.trim(),
          'repeatPassword': signupController.repeatPassController.text.trim(),
          'referralCode': signupController.referralController.text.trim(),
        };
        response = await ApiService.signUp(body);

        try {
          final responseJson = jsonDecode(response.body);
          if (response.statusCode == 200 && responseJson['status'] == true) {
            final data = responseJson['data'];
            if (data != null && data['pendingSignupToken'] != null) {
              pendingTokenFromSignup.value =
                  data['pendingSignupToken'].toString();
              signupController.tempToken.value = pendingTokenFromSignup.value;
            }
          }
        } catch (e) {}
      } else {
        response = await ApiService.resendOtp({'email': email});
      }

      isLoading.value = false;
      // EasyLoading.dismiss();
      AppLoading.hide();

      Map<String, dynamic> responseJson = {};
      try {
        responseJson = jsonDecode(response.body);
      } catch (e) {}

      final String message =
          responseJson['message']?.toString() ?? 'Something went wrong.';

      if (response.statusCode == 200) {
        resendOtpToEmail(Get.context!);

        AppSnackbar.info(
          'A new OTP has been sent to your email.',
          title: 'Send',
        );
      } else {
        AppSnackbar.error(message, title: 'Resend Failed');
      }
    } catch (e) {
      isLoading.value = false;
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error('Something went wrong: $e');
    }
  }

  Future<void> resendForgotPassword({required String email}) async {
    try {
      // EasyLoading.show(status: "Sending OTP...");
      AppLoading.show();

      final response = await ApiService.forgotPassword({'email': email});

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'OTP sent to your email';
        resendOtpToEmail(Get.context!);
        AppSnackbar.info(message, title: 'Send');
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg = decoded['message'] ?? 'Failed to send OTP';

        AppSnackbar.error(errorMsg, title: "Failed");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  Future<void> resendPhoneOtp({required String phone}) async {
    final fullPhone = phone.trim();
    if (fullPhone.isEmpty) {
      log('❌ resendPhoneOtp called with an empty phone number');
      return;
    }

    try {
      isLoading.value = true;
      // EasyLoading.show(status: 'Resending OTP...');
      AppLoading.show();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          AppSnackbar.error(
            e.message ?? 'Phone verification failed',
            title: 'Resend Failed',
          );
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          verificationId = newVerificationId;
          resendToken = newResendToken;
          resendOtpToEmail(Get.context!);
          AppSnackbar.info(
            'A new OTP has been sent to $fullPhone',
            title: 'OTP Sent',
          );
        },
        codeAutoRetrievalTimeout: (String newVerificationId) {
          verificationId = newVerificationId;
        },
      );
    } catch (e) {
      AppSnackbar.error('Something went wrong: $e');
      log('Phone OTP resend error: $e');
    } finally {
      isLoading.value = false;
      // EasyLoading.dismiss();
      AppLoading.hide();
    }
  }
}
