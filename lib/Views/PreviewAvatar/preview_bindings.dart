import 'package:get/get.dart';
import 'package:outspot/Views/PreviewAvatar/preview_controller.dart';

class PreviewBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PreviewController>(() => PreviewController());
  }
}