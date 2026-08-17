import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class ForgotController extends GetxController {
  final formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  RxBool isInputPhone = false.obs;
  late String value;
  late String type;
  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      emailController.text = args["value"] ?? "";
      type = args["type"] ?? "";
    } else {
      emailController.text = "";
      type = "";
      debugPrint("! ForgotScreen: No valid arguments passed.");
    }
  }

  Future<void> forgotPassword({required email}) async {
    try {
      // EasyLoading.show(status: "Sending OTP...");
      AppLoading.show();

      final response = await ApiService.forgotPassword({'email': email});

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'OTP sent to your email';

        // final OTPController = Get.find<OtpController>();
        // OTPController.resendOtpToEmail(Get.context!);

        AppSnackbar.info(message, title: 'Send');
        Get.toNamed(
          Routes.otpScreen,
          arguments: {'email': email, 'isEmailTab': type == 'email'},
        );
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

  Future<void> phoneForgotPassword({required String phone}) async {
    if (phone.trim().isEmpty) {
      AppSnackbar.error('Please enter a phone number.');
      return;
    }
    try {
      // EasyLoading.show(status: "Sending OTP...");
      AppLoading.show();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,

        verificationCompleted: (_) {},

        verificationFailed: (FirebaseAuthException e) {
          // EasyLoading.dismiss();
          AppLoading.hide();

          AppSnackbar.error(
            e.message ?? "Phone verification failed",
            title: "Failed",
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          // EasyLoading.dismiss();
          AppLoading.hide();

          AppSnackbar.info("OTP sent to $phone", title: "OTP Sent");

          Get.toNamed(
            Routes.otpScreen,
            arguments: {
              "verificationId": verificationId,
              "phoneNumber": phone,
              "isEmailTab": false,
            },
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong: $e");
    }
  }
}
