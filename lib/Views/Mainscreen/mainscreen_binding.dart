import 'package:get/get.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';

class MainscreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainscreeenController());
  }
}
