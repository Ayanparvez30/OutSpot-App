import 'package:get/get.dart';
import 'package:outspot/Views/CreatePassword/createPassword_controller.dart';

class CreatepasswordBindings extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => CreatepasswordController());
  }
}
