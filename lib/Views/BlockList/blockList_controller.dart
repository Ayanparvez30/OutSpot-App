import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/blockUser_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';

import '../../Utils/app_loading.dart';

class BlocklistController extends GetxController {
  RxList<BlockedUser> users = <BlockedUser>[].obs;

  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadBlockProfile();
  }

  Future<void> loadBlockProfile() async {
    try {
      isLoading.value = true;

      final response = await ApiService.fetchBlockList();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final model = BlockedUserResponse.fromJson(decoded);
        users.value = model.data;
      } else {
        log("❌ Server error: ${response.statusCode}");
        AppSnackbar.error("Server returned ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading blocklist: $e");
      AppSnackbar.error("Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void unblockUser(int index) async {
    final user = users[index];

    try {
      // EasyLoading.show(status: "Unblocking...");
      AppLoading.show();

      final response = await ApiService.unblockUser(user.id);

      // EasyLoading.dismiss();
      AppLoading.hide();

      if (response.statusCode == 200) {
        users.removeAt(index);

        AppSnackbar.success("User has been unblocked");
      } else {
        log("❌ Failed to unblock: ${response.statusCode}");
        AppSnackbar.error(
          "Failed to unblock user (Code: ${response.statusCode})",
        );
      }
    } catch (e) {
      // EasyLoading.dismiss();
      AppLoading.hide();

      log("❌ Exception during unblock: $e");
      AppSnackbar.error("Something went wrong while unblocking.");
    }
  }
}
