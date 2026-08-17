import 'dart:developer';

import 'package:get/get.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class PreviewController extends GetxController {
final RxString avatarUrl = ''.obs;
  final RxBool   loading   = true.obs;
   Map<String, dynamic> _lastOutfit = {};
  Map<String, dynamic> get lastOutfitArgs => _lastOutfit;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?; 
    if (args != null) {
      avatarUrl.value = args['avatarUrl'] ?? '';
      _lastOutfit     = Map<String, dynamic>.from(args['outfit'] ?? {});
      loading.value   = false;
    }
    else {
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
      AppSnackbar.error(e.toString());
    } finally {
      loading.value = false;
    }
  }

    Future<void> save() async {
    try {
      loading.value = true;
      await ApiService.saveLatestMinime();
      AppSnackbar.success('Mini‑Me saved ✅');
       Get.offAllNamed(Routes.mainscreen,arguments: {"tab": 5});
    } catch (e, s) {
      log('❌ save error', error: e, stackTrace: s);
      AppSnackbar.error(e.toString());
    } finally {
      loading.value = false;
    }
  }

  // Future<void> _fetchLocker() async {
  //   try {
  //     loading.value = true;
  //     final locker = await ApiService.getMinimeLocker();  
  //     if (locker.isNotEmpty && locker.first['avatarUrl'] != null) {
  //       avatarUrl.value = locker.first['avatarUrl'] as String;
  //     }
  //   } catch (e, s) {
  //     log('❌ locker fetch error', error: e, stackTrace: s);
  //     Get.snackbar('Error', e.toString());
  //   } finally {
  //     loading.value = false;
  //   }
  // }

}