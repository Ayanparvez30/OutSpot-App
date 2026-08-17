import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Login/login_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class CreatepasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPassController = TextEditingController();
  final logController = Get.put(LoginController());

  var isPasswordHidden = true.obs;
  var isRepPasswordHidden = true.obs;

  String gettingEmail = '';
  String gettingOtp = '';

  late String verificationId;
  late String phoneNumber;
  late String username;
  late String password;
  late String repeatPassword;
  late String countryCode;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments ?? {};

    gettingEmail = args['email'] ?? '';
    gettingOtp = args['otp'] ?? '';
    verificationId = args['verificationId'] ?? '';
    phoneNumber = args['phoneNumber'] ?? '';
    username = args['username'] ?? '';
    password = args['password'] ?? '';
    repeatPassword = args['repeatPassword'] ?? '';
    countryCode = args['countryCode'] ?? '';

    log(verificationId.length);
    log(phoneNumber.length);
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleRepPasswordVisibility() {
    isRepPasswordHidden.value = !isRepPasswordHidden.value;
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String repeatPassword,
  }) async {
    try {
      // EasyLoading.show(status: "Resetting password...");
      AppLoading.show();

      final response = await ApiService.resetPassword({
        'email': email,
        'otp': otp,
        'password': password,
        'repeatPassword': repeatPassword,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Password reset successful';

        CustomWidgets().showSaveDialogue(
          title: "Password Updated!",
          subtitle: "Update complete, please log in using\nyour new password.",
          nextRoute: Routes.loginScreen,
        );
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg = decoded['message'] ?? 'Reset failed';

        AppSnackbar.error(errorMsg, title: "Failed");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  Future<void> resetPasswordWithOtp({
    required String phone,
    required String otp,
    required String newPassword,
    required String repeatPassword,
    required String verificationId,
  }) async {
    try {
      // EasyLoading.show(status: "Verifying OTP...");
      AppLoading.show();

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // EasyLoading.show(status: "Updating password...");
      AppLoading.show();

      final response = await ApiService.resetPassword({
        "otp": otp,
        "phone": phone,
        "password": newPassword,
        "repeatPassword": repeatPassword,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? "Password reset successful";

        CustomWidgets().showSaveDialogue(
          title: "Password Updated!",
          subtitle: "$message\nPlease log in using your new password.",
          nextRoute: Routes.loginScreen,
        );
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg = decoded['message'] ?? "Reset failed";

        AppSnackbar.error(errorMsg, title: "Failed");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong: $e");
    }
  }
}
