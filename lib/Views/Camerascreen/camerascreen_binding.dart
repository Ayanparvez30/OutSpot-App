import 'package:get/get_instance/get_instance.dart';
import 'package:get/state_manager.dart';
import 'package:outspot/Views/Camerascreen/camerascreen_controller.dart';

class CamerascreenBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => CamerascreenController());
  }
}
