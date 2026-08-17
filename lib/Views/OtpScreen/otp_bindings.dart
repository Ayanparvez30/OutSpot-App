import 'package:get/get.dart';
import 'package:outspot/Views/OtpScreen/otp_controller.dart';

class OtpBindings extends Bindings {
  @override
  void dependencies() {
    // Delete existing controller if any, to ensure fresh state on each visit
    if (Get.isRegistered<OtpController>()) {
      Get.delete<OtpController>();
    }
    Get.put(OtpController());
  }
}
