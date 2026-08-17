import 'package:get/get.dart';
import 'package:outspot/Views/ForgotScreen/forgot_controller.dart';

class ForgotBindings extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies

    Get.lazyPut(() => ForgotController());
  }
}
