import 'package:get/get.dart';
import 'package:outspot/Views/NonPrivateProfile/non_private_profile_controller.dart';

class NonPrivateProfileBinding extends Bindings {
  @override
  void dependencies() {
    // fenix:true → if the controller is disposed while the screen is still in
    // the stack (e.g. after navigating NonPrivateProfile → FriendsProfile), the
    // next access recreates it instead of crashing with "controller not found".
    Get.lazyPut(() => NonPrivateProfileController(), fenix: true);
  }
}
