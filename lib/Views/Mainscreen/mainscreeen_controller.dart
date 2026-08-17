import 'dart:developer';

import 'package:get/get.dart';
import 'package:outspot/Model/achievement_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

class MainscreeenController extends GetxController {
  Rx<int> selectedTabIndex = 0.obs;
  RxInt tabIndex = 0.obs;
  Map<String, dynamic>? pendingRouteTo;
  @override
  void onInit() {
    super.onInit();

    final initialTab = Get.arguments?['tab'] ?? 0;
    log("initialTab: $initialTab");
    tabIndex.value = initialTab;
    pendingRouteTo = Get.arguments?['routeTo'];
    fetchAchievements();
  }

  void changeTab(int index) {
    // When leaving the Map tab (index 1), close any open map bottom sheets
    // so the map is in a fresh state when the user returns.
    if (tabIndex.value == 1 && index != 1) {
      if (Get.isRegistered<MapController>()) {
        final mapCtrl = Get.find<MapController>();
        mapCtrl.selectedRestaurant.value = null;
        mapCtrl.showCategoryList.value = false;
        mapCtrl.searchMarker.clear();
        mapCtrl.searchController.clear();
        mapCtrl.isSearching.value = false;
      }
    }
    tabIndex.value = index;
  }

  // Tier / points based (backend now returns points, not levels).
  final achievementpoints = 0.obs; // totalPoints
  final pointnextlevel = 0.obs; // pointsToNext (points left to reach next tier)
  final progress = 0.0.obs; // 0..1 within the current tier
  final achievementTitle = ''.obs; // current tier name
  final nextTitle = ''.obs; // next tier name ("" at the top tier)
  final currentMin = 0.obs; // current tier's start points
  final nextAt = 0.obs; // points at which the next tier unlocks

  void setFromAchievement(Achievement a) {
    achievementpoints.value = a.totalPoints;
    pointnextlevel.value = a.pointsToNext;
    progress.value = a.progress;
    achievementTitle.value = a.title;
    nextTitle.value = a.nextTitle;
    currentMin.value = a.currentMin;
    nextAt.value = a.nextAt;
  }

  /// At the highest tier there is no next tier to climb to.
  bool get isMaxLevel => nextTitle.value.trim().isEmpty;

  /// Points total at which the next tier unlocks (right end of the bar).
  int get nextLevelAtPoints => nextAt.value;

  /// Points required to reach the tier named [name], from the loaded tiers.
  /// Returns null when the tier isn't found.
  int? pointsForTier(String name) {
    final tiers = myAchievements.value?.tiers ?? const <AchievementTier>[];
    for (final t in tiers) {
      if (t.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return t.pointsRequired;
      }
    }
    return null;
  }

  RxList achivmentlist = RxList([
    "assets/Images/sklegency.png",
    "assets/Images/sksniper.png",
    "assets/Images/skcamera.png",
    "assets/Images/skfootprint.png",
  ]);
  String getTitleIcon(int level) {
    if (level >= 20) return "assets/Images/sklegency.png";
    if (level >= 10) return "assets/Images/sksniper.png";
    if (level >= 5) return "assets/Images/skcamera.png";
    return "assets/Images/skfootprint.png";
  }

  final myAchievements = Rxn<Achievement>();
  final isLoadingAchievements = false.obs;
  Future<void> fetchAchievements() async {
    try {
      isLoadingAchievements.value = true;
      final data = await ApiService.getMyAchievements();
      log("Achievement API response: $data");
      myAchievements.value = Achievement.fromJson(data);
      log("Achievement: title=${myAchievements.value!.title}, progress=${myAchievements.value!.progress}, pointsToNext=${myAchievements.value!.pointsToNext}, nextAt=${myAchievements.value!.nextAt}");

      setFromAchievement(myAchievements.value!);
    } catch (e) {
      log(' ');
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoadingAchievements.value = false;
    }
  }
}
