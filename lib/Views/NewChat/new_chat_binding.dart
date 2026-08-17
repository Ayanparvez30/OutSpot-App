import 'package:get/get.dart';
import 'package:outspot/Views/NewChat/new_chat_controller.dart';

class NewChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewChatController>(() => NewChatController());
  }
}
