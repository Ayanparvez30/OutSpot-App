import 'package:get/get.dart';
import 'package:outspot/Views/Explore_Category/explore_category_controller.dart';

class ExploreCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExploreCategoryController>(() => ExploreCategoryController());
  }
}