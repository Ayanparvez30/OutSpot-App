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

class UpdateScreenController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  var isLoading = false.obs;

  // Track original values so we know when the user has changed anything
  String _originalFirstName = '';
  String _originalLastName = '';
  final RxBool hasChanged = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;

    final firstName = args?["firstName"] ?? "";
    final lastName = args?["lastName"] ?? "";

    _originalFirstName = firstName;
    _originalLastName = lastName;
    firstNameController.text = firstName;
    lastNameController.text = lastName;

    void _recalcChanged() {
      final fn = firstNameController.text.trim();
      final ln = lastNameController.text.trim();
      hasChanged.value = fn.isNotEmpty &&
          ln.isNotEmpty &&
          (fn != _originalFirstName.trim() ||
              ln != _originalLastName.trim());
    }

    firstNameController.addListener(_recalcChanged);
    lastNameController.addListener(_recalcChanged);

    log("🧾 Received firstName: $firstName");
    log("🧾 Received lastName: $lastName");
  }

  Future<void> updateName({required firstName, required lastName}) async {
    try {
      // EasyLoading.show(status: "Updating Name...");
      AppLoading.show();

      final response = await ApiService.updateName({
        'firstName': firstName,
        'lastName': lastName,
      });

      AppLoading.hide();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Name update successful';

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
      AppLoading.hide();
      AppSnackbar.error("Something went wrong. Please try again.");
    }
  }
}
