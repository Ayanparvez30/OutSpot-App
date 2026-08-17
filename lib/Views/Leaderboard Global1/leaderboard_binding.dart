import 'package:get/get.dart';
import 'package:outspot/Views/Leaderboard%20Global1/leaderboaddglobal_controller.dart';

class LeaderboardBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => LeaderboaddglobalController());
  }
}
