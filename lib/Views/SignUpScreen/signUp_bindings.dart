import 'package:get/get.dart';
import 'package:outspot/Views/SignUpScreen/signUp_controller.dart';

class SignupBindings extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => SignupController());
  }
}
