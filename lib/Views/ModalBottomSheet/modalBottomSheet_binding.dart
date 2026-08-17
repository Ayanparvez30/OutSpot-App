import 'package:get/get.dart';
import 'package:outspot/Views/ModalBottomSheet/modalBottomSheet_controller.dart';

class ModalbottomsheetBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => ModalbottomsheetController());
  }
}
