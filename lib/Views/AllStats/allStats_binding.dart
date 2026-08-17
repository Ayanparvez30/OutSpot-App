import 'package:get/get.dart';

import 'package:outspot/Views/AllStats/allStats_controller.dart';

class AllStatsBinding extends Bindings {
  @override
  void dependencies() {
    // One stable, permanent instance (no fenix churn, no scattered Get.put).
    // Each screen explicitly loads its own target (own AllStats / FriendsStats).
    AllStatsController.instance;
  }
}
