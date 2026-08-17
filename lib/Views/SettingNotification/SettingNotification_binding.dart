import 'package:get/get.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:outspot/Views/SettingNotification/SettingNotification_controller.dart';

class SettingnotificationBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => SettingnotificationController());
  }
}
