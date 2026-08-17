import 'package:get/get.dart';
import 'package:outspot/Views/Groups/groups_controller.dart';

class GroupsBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => GroupsController());
  }
}
