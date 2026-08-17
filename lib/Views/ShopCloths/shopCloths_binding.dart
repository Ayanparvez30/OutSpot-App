import 'package:get/get.dart';
import 'package:outspot/Views/ShopCloths/shopCloths_controller.dart';

class ShopClothsBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<ShopClothsController>(() => ShopClothsController());
  }
}