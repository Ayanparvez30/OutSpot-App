import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class UsernameController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController description = TextEditingController();

  // Track the original username so we know when the user actually changed it
  String _originalUsername = '';
  final RxBool hasChanged = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final userName = args?["username"] ?? "";

    _originalUsername = userName;
    userNameController.text = userName;

    // Listen for changes and toggle hasChanged
    userNameController.addListener(() {
      final current = userNameController.text.trim();
      hasChanged.value =
          current.isNotEmpty && current != _originalUsername.trim();
    });

    log("🧾 Username received: $userName");
  }

  Future<void> sendMessage(
    String email,
    String subject,
    String description,
  ) async {
    try {
      // EasyLoading.show(status: "Sending...");
      AppLoading.show();

      final response = await ApiService.sendContactMessage({
        "email": email,
        "subject": subject,
        "description": description,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        print("message sent successfully");
        CustomWidgets().showSaveDialogue(
          title: "Message Sent",
          subtitle:
              "Thank you for your feedback. Our\nteam will respond via email soon.",
          nextRoute: Routes.settingScreen,
        );
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['message']?.toString() ?? "Something went wrong";

        AppSnackbar.error(errorMsg, title: "Failed");
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }

  Future<void> updateUsername({required username}) async {
    try {
      // EasyLoading.show(status: "Updating Username...");
      AppLoading.show();

      final response = await ApiService.updateUsername({'username': username});

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Username update successful';

        CustomWidgets().showSaveDialogue(
          title: "Settings Saved",
          subtitle: "Your account has been updated.",
          nextRoute: Routes.settingScreen,
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
}
