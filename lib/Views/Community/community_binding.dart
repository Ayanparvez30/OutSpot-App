import 'package:get/get.dart';
import 'package:outspot/Views/Community/community_controller.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => CommunityController());
  }
}
