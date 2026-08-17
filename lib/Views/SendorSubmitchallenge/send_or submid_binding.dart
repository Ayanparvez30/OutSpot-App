import 'package:get/get.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_or_submid_controller.dart';

class SendorsubmidBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => SendorSubmidController());
  }
}
