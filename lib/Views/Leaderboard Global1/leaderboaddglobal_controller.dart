import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/communityleaderbord.dart';

import 'package:outspot/Model/global_leaderboard.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';

class LeaderboaddglobalController extends GetxController
    with GetTickerProviderStateMixin {
  TextEditingController searchcontroller = TextEditingController();
  late AnimationController prizeShineController;

  RxBool isSearching = false.obs;
  RxBool listExpanded = false.obs;
  var isGlobalTab = true.obs;
  final globalleaderboard = <UserLeaderboard>[].obs;
  final global = Rxn<GlobalLeaderboard>();
  var myCreatedCommunity = Rxn<MyTopCreatedCommunity>();
  // The community the current user has JOINED (is a member of), resolved from
  // the leaderboard standings. Used for the bottom "my standing" bar when the
  // user didn't create a community — myTopCreatedCommunity is null in that case.
  final myCommunityStanding = Rxn<CommunityLeaderboard>();

  var leaderboard = <CommunityLeaderboard>[].obs;
  final loading = false.obs;
  final _globalLoading = false.obs;
  final _communityLoading = false.obs;
  final error = ''.obs;
  RxString searchQuery = ''.obs;
  RxString searchText = ''.obs;

  void _updateLoading() {
    loading.value = _globalLoading.value || _communityLoading.value;
  }

  @override
  void onInit() {
    super.onInit();
    prizeShineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    loadWeeklyLeaderboard();
    loadWeeklyGlobalLeaderboard();
  }

  @override
  void onClose() {
    prizeShineController.dispose();
    super.onClose();
  }

  void toggleTab(bool isGlobal) {
    isGlobalTab.value = isGlobal;
  }

  Future<void> loadWeeklyGlobalLeaderboard() async {
    try {
      _globalLoading.value = true;
      _updateLoading();
      error.value = '';

      final raw = await ApiService.getWeeklyGlobalLeaderboard();
      print(raw);
      final parsed = GlobalLeaderboard.fromMap(raw);

      global.value = parsed;

      globalleaderboard.assignAll(parsed.leaderboard);
    } catch (e) {
      error.value = e.toString();
      print("ERROR: $e");
    } finally {
      _globalLoading.value = false;
      _updateLoading();
    }
  }

  Future<void> loadWeeklyLeaderboard() async {
    try {
      _communityLoading.value = true;
      _updateLoading();
      error.value = '';

      final raw = await ApiService.getWeeklyCommunityLeaderboard();

      final communityData = CommunityData.fromMap(
        Map<String, dynamic>.from(raw),
      );

      leaderboard.assignAll(communityData.leaderboard);

      myCreatedCommunity.value = communityData.myTopCreatedCommunity;

      await _resolveMyJoinedCommunity();
    } catch (e, s) {
      error.value = e.toString();
      print("❌ Error in loadWeeklyLeaderboard: $e");
      print(s);
    } finally {
      _communityLoading.value = false;
      _updateLoading();
    }
  }

  /// Resolve the community the user has JOINED so the bottom "my standing" bar
  /// isn't empty for members who didn't create a community.
  ///
  /// If the user created a community, [myCreatedCommunity] already drives the
  /// bar, so we skip. Otherwise we look up the user's member community id
  /// (from [MyProfileController]) inside the leaderboard standings to get its
  /// rank/points/name/image.
  Future<void> _resolveMyJoinedCommunity() async {
    try {
      // Creator path already covered by myCreatedCommunity.
      if (myCreatedCommunity.value != null) {
        myCommunityStanding.value = null;
        return;
      }

      final mp = MyProfileController.instance;
      var id = mp.myCommunityId.value;
      if (id == 0) {
        // Profile may not have loaded the joined community yet on first open.
        await mp.loadMostRecentCommunityImage();
        id = mp.myCommunityId.value;
      }

      if (id == 0) {
        myCommunityStanding.value = null;
        return;
      }

      CommunityLeaderboard? match;
      for (final c in leaderboard) {
        if (c.communityId == id) {
          match = c;
          break;
        }
      }
      myCommunityStanding.value = match;
    } catch (e) {
      print("⚠️ resolveMyJoinedCommunity failed: $e");
    }
  }

  List<UserLeaderboard> get filteredUsers {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return globalleaderboard;
    return globalleaderboard
        .where(
          (u) =>
              u.username.toLowerCase().contains(q) ||
              u.prize.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> shareMyInfo(UserLeaderboard me, {Rect? origin}) async {
    final g = global.value;
    final window = g?.window;

    final buf = StringBuffer();
    buf.writeln("OutSpot Weekly Leaderboard");
    if (window != null) {
      buf.writeln("${window.label} (${window.remaining} remaining)");
    }
    buf.writeln("");

    // My standings
    buf.writeln("My Standings:");
    buf.writeln("  #${me.rank} ${me.fullName}");
    buf.writeln("  Points: ${me.points}");
    if (me.prize.isNotEmpty) buf.writeln("  Prize: ${me.prize}");
    buf.writeln("");

    // Top 3 leaderboard
    if (globalleaderboard.isNotEmpty) {
      buf.writeln("Top Players:");
      final top = globalleaderboard.take(3).toList();
      for (final u in top) {
        buf.writeln("  #${u.rank} ${u.fullName} — ${u.points} pts");
      }
      buf.writeln("");
    }

    buf.writeln("Join me on OutSpot!");

    showSendToSheet(buf.toString());
  }

  Future<void> shareMyCommunity(MyTopCreatedCommunity? c, {Rect? origin}) async {
    final g = global.value;
    final window = g?.window;

    final buf = StringBuffer();
    buf.writeln("OutSpot Community Leaderboard");
    if (window != null) {
      buf.writeln("${window.label} (${window.remaining} remaining)");
    }
    buf.writeln("");

    // My community standings
    if (c != null) {
      buf.writeln("My Community:");
      buf.writeln("  #${c.rank} ${c.name}");
      buf.writeln("  Points: ${c.points}");
      buf.writeln("  Members: ${c.membersCount}");
      if (c.prize.isNotEmpty) buf.writeln("  Prize: ${c.prize}");
      buf.writeln("");
    }

    // Top 3 communities
    if (leaderboard.isNotEmpty) {
      buf.writeln("Top Communities:");
      final top = leaderboard.take(3).toList();
      for (final comm in top) {
        buf.writeln("  #${comm.rank} ${comm.name} — ${comm.points} pts (${comm.membersCount} members)");
      }
      buf.writeln("");
    }

    buf.writeln("Join us on OutSpot!");

    showSendToSheet(buf.toString());
  }
}
