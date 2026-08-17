import 'package:get/get_instance/get_instance.dart';
import 'package:get/route_manager.dart';
import 'package:outspot/Views/BlockList/blockList_controller.dart';

class BlocklistBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => BlocklistController());
  }
}
