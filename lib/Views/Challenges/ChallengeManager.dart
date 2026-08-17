import 'package:get/get.dart';
import 'package:outspot/Model/challenge_card_model.dart';

class ChallengeManager {
  ChallengeManager._privateConstructor();

  static final ChallengeManager instance =
      ChallengeManager._privateConstructor();
  var selectedChallenge = Rxn<ChallengeCardModel>();
  void saveChallenge(ChallengeCardModel? model) {
    selectedChallenge.value = model;
  }

  void clear() {
    selectedChallenge.value = null;
  }
}
