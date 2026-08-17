import 'package:get/get.dart';

import 'friends_profile_controller.dart';


class FriendsProfileBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=>FriendsProfileController());
  }
}