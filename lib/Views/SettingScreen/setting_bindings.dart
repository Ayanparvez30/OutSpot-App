import 'package:get/get.dart';
import 'package:outspot/Views/SettingScreen/setting_controller.dart';

class SettingBindings extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => SettingController());
  }
}
