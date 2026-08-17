import 'package:get/get.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';

class FriendListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FriendListController>(() => FriendListController());
  }
}
