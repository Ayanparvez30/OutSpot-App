import 'package:get/get.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExploreController(), fenix: true);
  }
}
