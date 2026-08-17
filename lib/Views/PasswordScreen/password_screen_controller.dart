import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class PasswordScreenController extends GetxController {
  final formKey = GlobalKey<FormState>();
  TextEditingController currentPasswardController = TextEditingController();
  TextEditingController newPasswardController = TextEditingController();
  TextEditingController repeatPasswardController = TextEditingController();

  var isCurrentPasswordHidden = true.obs;
  var isNewPasswordHidden = true.obs;
  var isRepPasswordHidden = true.obs;

  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordHidden.value = !isCurrentPasswordHidden.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordHidden.value = !isNewPasswordHidden.value;
  }

  void toggleRepPasswordVisibility() {
    isRepPasswordHidden.value = !isRepPasswordHidden.value;
  }

  RxBool isLoading = false.obs;

  void startLoading() {
    isLoading.value = true;
  }

  void stopLoading() {
    isLoading.value = false;
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String repeatPassword,
  ) async {
    try {
      // EasyLoading.show(status: 'Updating password...');
      AppLoading.show();

      final response = await ApiService.updatePassword({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'repeatPassword': repeatPassword,
      });

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        CustomWidgets().showSaveDialogue(
          title: "Password Updated",
          subtitle: "You may now log in using your new\npassword",
          nextRoute: Routes.settingScreen,
        );
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? "Password change failed";

        AppSnackbar.error(message);
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      AppSnackbar.error("Something went wrong: $e");
    }
  }
}
