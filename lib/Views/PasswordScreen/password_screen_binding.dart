
import 'package:get/get.dart';
import 'package:outspot/Views/PasswordScreen/password_screen_controller.dart';

class PasswordScreenBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=>PasswordScreenController());
  }

}