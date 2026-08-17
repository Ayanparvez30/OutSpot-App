import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';
import 'package:outspot/Views/FriendsProfile/friends_profile_controller.dart';
import 'package:outspot/Views/NonPrivateProfile/non_private_profile_controller.dart';

/// FriendsProfile and NonPrivateProfile use singleton GetX controllers, so when
/// you navigate friend → friend-of-friend the same controller is reused. The
/// forward case is handled by an id-check in each screen's build, but a build
/// does NOT re-run when a route is revealed by popping the one above it. This
/// observer fixes back-navigation: when a profile route becomes visible again,
/// it reloads its controller for that route's own id if it drifted.
class ProfileReloadObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _reloadIfProfile(previousRoute);
  }

  void _reloadIfProfile(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name;

    // Own stats screen revealed → reload MY stats if the shared controller was
    // last showing a friend (build doesn't re-run on pop, so its postFrame
    // reload never fires — this fixes the infinite shimmer on back-nav).
    if (name == Routes.allStats &&
        Get.isRegistered<AllStatsController>()) {
      final c = Get.find<AllStatsController>();
      if (c.ownUserId == null || c.currentStatsUserId != c.ownUserId) {
        c.loadInitialData();
      }
      return;
    }

    final id = _extractId(route.settings.arguments);
    if (id <= 0) return;

    if (name == Routes.friendsProfile &&
        Get.isRegistered<FriendsProfileController>()) {
      final c = Get.find<FriendsProfileController>();
      if (c.currentUserId != id) c.loadProfile(id);
    } else if (name == Routes.nonPrivateProfile &&
        Get.isRegistered<NonPrivateProfileController>()) {
      final c = Get.find<NonPrivateProfileController>();
      if (c.friendRx.value?.id != id) c.loadForId(id);
    }
  }

  int _extractId(Object? args) {
    if (args is FriendsModel) return args.id;
    if (args is int) return args;
    if (args is Map && args['id'] != null) {
      final v = args['id'];
      return v is int ? v : int.tryParse('$v') ?? 0;
    }
    return 0;
  }
}
