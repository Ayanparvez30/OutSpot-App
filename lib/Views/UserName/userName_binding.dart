import 'package:get/get.dart';
import 'package:outspot/Views/UserName/userName_controller.dart';

class UsernameBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => UsernameController());
  }
}
