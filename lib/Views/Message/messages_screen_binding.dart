import 'package:get/get.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';

class MessagesScreenBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => MessagesScreenController());
  }
}
