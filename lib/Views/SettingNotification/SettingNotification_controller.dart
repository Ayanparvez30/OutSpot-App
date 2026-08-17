import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_toast.dart';

import '../../CommonWidgets/CustomWidgets/customWidget.dart';
import '../../Utils/routes.dart';

class SettingnotificationController extends GetxController {
  RxBool isPushNotificationEnabled = false.obs;
  RxBool hasChanged = false.obs;

  RxBool isLoading = true.obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotificationSetting();
  }

  void togglePushNotification() {
    isPushNotificationEnabled.value = !isPushNotificationEnabled.value;
    hasChanged.value = true;
  }

  Future<void> fetchNotificationSetting() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getNotificationSetting();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        isPushNotificationEnabled.value = data['notificationEnabled'] ?? false;
        hasChanged.value = false;
      } else {
        log("Failed to fetch settings: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    try {
      final response = await ApiService.updateNotificationSetting(
        isPushNotificationEnabled.value,
      );

      if (response.statusCode == 200) {
        hasChanged.value = false;
        CustomWidgets().showSaveDialogue(
          title: "Settings Saved",
          subtitle: "Your account has been updated.",
          nextRoute: Routes.settingScreen,
        );
      } else {
        AppToast.error("Failed to update settings");
      }
    } catch (e) {
      log("Save settings error: $e");
      AppToast.error("Something went wrong");
    } finally {
      isSaving.value = false;
    }
  }
}
