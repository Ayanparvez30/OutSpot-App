import 'dart:developer';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class WaredropPreviewController extends GetxController {
  final RxString avatarUrl = ''.obs;
  final RxBool loading = true.obs;
  // Kept as dynamic: the outfit payload also carries non-String values like
  // premadeId (int), so a Map<String, String> cast would throw.
  Map<String, dynamic> _lastOutfit = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      avatarUrl.value = args['avatarUrl'] ?? '';
      _lastOutfit = Map<String, dynamic>.from(args['outfit'] ?? {});
      loading.value = false;
    } else {
      log('❌ No avatar URL provided in route arguments');
    }
  }

  Future<void> regenerate() async {
    if (_lastOutfit.isEmpty) {
      AppSnackbar.error('No outfit found to regenerate');
      return;
    }
    try {
      loading.value = true;
      final res = await ApiService.regenerateMinime(_lastOutfit);
      avatarUrl.value = res['data']['avatarUrl'] as String;
    } catch (e, s) {
      log('❌ regenerate error', error: e, stackTrace: s);
      // Get.snackbar('Error', e.toString());
      EasyLoading.showError(e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> save() async {
    try {
      loading.value = true;
      await ApiService.saveLatestMinime();
      // 🔥 থিম অনুযায়ী কাস্টমাইজড টোস্ট মেসেজ
      AppToast.success("Mini-Me saved successfully! ✅");
      // Push the freshly-saved avatar into any live controllers that display it
      // and trigger a reload. These are fenix/singleton controllers reused
      // across this navigation, so without this they keep showing the old
      // avatar until the next tab switch re-creates them.
      final newAvatar = avatarUrl.value;
      if (Get.isRegistered<MyProfileController>()) {
        final mp = Get.find<MyProfileController>();
        if (newAvatar.isNotEmpty) mp.updateAvatarLocal(newAvatar);
        mp.refreshProfileData();
      }
      if (Get.isRegistered<ExploreController>()) {
        final ex = Get.find<ExploreController>();
        if (newAvatar.isNotEmpty) ex.avatarurl.value = newAvatar;
        ex.loadUserProfile();
      }

      Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
    } catch (e, s) {
      log('❌ save error', error: e, stackTrace: s);
      // Get.snackbar('Error', e.toString());
      EasyLoading.showError(e.toString());
    } finally {
      loading.value = false;
    }
  }
}
