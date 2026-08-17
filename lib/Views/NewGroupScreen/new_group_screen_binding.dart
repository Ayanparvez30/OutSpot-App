import 'package:get/get.dart';
import 'package:outspot/Views/NewGroupScreen/new_group_screen_controller.dart';

class NewGroupScreenBinding  extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=>NewGroupScreenController);
  }

} 