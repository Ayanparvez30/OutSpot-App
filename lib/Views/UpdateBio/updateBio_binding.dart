import 'package:get/get.dart';
import 'package:outspot/Views/UpdateBio/updateBio_controller.dart';

class UpdatebioBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => UpdatebioController());
  }
}
