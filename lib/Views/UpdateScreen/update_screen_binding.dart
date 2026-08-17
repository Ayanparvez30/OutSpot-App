import 'package:get/get.dart';
import 'package:outspot/Views/UpdateScreen/update_screen_controller.dart';

class UpdateScreenBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=>UpdateScreenController());
  }

}