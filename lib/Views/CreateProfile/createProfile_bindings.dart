import 'package:get/get.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';

class CreateprofileBindings extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=>CreateprofileController());
  }

}