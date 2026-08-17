import 'package:get/get.dart';
import 'package:outspot/Views/waredrop/waredrop_controller.dart';

class WaredropBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => WaredropController());
  }
}
