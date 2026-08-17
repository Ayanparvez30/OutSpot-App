import 'package:get/get.dart';
import 'package:outspot/Views/Notification1/notification_controller.dart';

class Notification1Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Notification1Controller>(() => Notification1Controller());
  }
}