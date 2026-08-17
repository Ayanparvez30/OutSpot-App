import 'package:get/get.dart';
import 'package:outspot/Views/Create_Mini_Me/create_mini_me_controller.dart';

class CreateMiniMeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateMiniMeController>(
      () => CreateMiniMeController(),
    );
  }
}
