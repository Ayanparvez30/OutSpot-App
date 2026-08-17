import 'package:get/get.dart';
import 'package:outspot/Views/waredrop_preview/waredrop_preview_controller.dart';

class WaredropPreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WaredropPreviewController>(
        () => WaredropPreviewController());
  }
}