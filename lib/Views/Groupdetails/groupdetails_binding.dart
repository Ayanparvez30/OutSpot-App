import 'package:get/get.dart';
import 'package:outspot/Views/Groupdetails/groupdetails_controller.dart';

class GroupdetailsBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => GroupdetailsController());
  }
}
