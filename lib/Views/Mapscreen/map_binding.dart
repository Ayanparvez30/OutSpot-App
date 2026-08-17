import 'package:get/get.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

class MapScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapController>(() => MapController(), fenix: true);
    Get.lazyPut(() => MainscreeenController());
  }
}
