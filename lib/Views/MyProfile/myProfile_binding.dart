import 'package:get/get.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';

class MyProfileBindings extends Bindings {
  @override
  void dependencies() {
    // fenix:true → if the controller is disposed (e.g. a duplicate MyProfile
    // route pops), the next access recreates it instead of crashing with
    // "controller not found". Lets us use a normal Get.back() for navigation.
    Get.lazyPut<MyProfileController>(
      () => MyProfileController(),
      fenix: true,
    );
  }
}
