import 'package:get/get.dart';
import 'package:outspot/Views/Login/login_controller.dart';

class LoginBindings extends Bindings {
  @override
  void dependencies() {
    // fenix: true so the controller survives session-expiry cleanup. The 401
    // handler runs cleanupAllSessionData() → Get.deleteAll(force: true), and a
    // burst of concurrent 401s can fire that cleanup again right after we land
    // on the login screen — deleting a freshly-created LoginController. fenix
    // keeps the builder alive so GetView re-creates it on next access instead
    // of throwing "LoginController not found".
    Get.lazyPut(() => LoginController(), fenix: true);
  }
}
