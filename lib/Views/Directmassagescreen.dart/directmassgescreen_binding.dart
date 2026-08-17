import 'package:get/get.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';

class DirectmassgescreenBinding extends Bindings {
  @override
  void dependencies() {
    // Delete old instance if exists so fresh data loads for each chat
    if (Get.isRegistered<DirectmassagescreenController>()) {
      Get.delete<DirectmassagescreenController>(force: true);
    }
    // fenix: true so the controller is auto-recreated if it gets disposed
    // while navigating between DM ↔ Community ↔ DM, preventing
    // "DirectmassagescreenController not found" crashes on back navigation.
    Get.lazyPut(() => DirectmassagescreenController(), fenix: true);
  }
}
