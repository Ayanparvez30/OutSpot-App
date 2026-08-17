import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class UpdatebioController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final TextEditingController bioControler = TextEditingController();

  // Track original bio so we know when it's actually been changed
  String _originalBio = '';
  final RxBool hasChanged = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final yourBio = args?["bio"] ?? "";

    _originalBio = yourBio;
    bioControler.text = yourBio;

    bioControler.addListener(() {
      hasChanged.value =
          bioControler.text.trim() != _originalBio.trim();
    });

    log("🧾 bio received: $yourBio");
  }

  Future<void> updateBio({required bio}) async {
    try {
      // EasyLoading.show(status: "Updating Bio...");
      AppLoading.show();

      final response = await ApiService.updateBio({'bio': bio});

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Bio update successful';

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

      print(e);
      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }
}
