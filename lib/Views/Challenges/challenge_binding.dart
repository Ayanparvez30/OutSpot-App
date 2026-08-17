import 'package:get/get.dart';
import 'package:outspot/Views/Challenges/challenge_controller.dart';

class ChallengeBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<ChallengeController>(() => ChallengeController());
  }
}
