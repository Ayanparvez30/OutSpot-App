import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/challange_others_user_model.dart';
import 'package:outspot/Model/challenge_card_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Views/Challenges/photoviewer.dart';
import 'package:outspot/Views/Message/camera_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class ChallengeController extends GetxController {
  final RxnString avatarUrl = RxnString();
  // VISIBLE / accumulated "Others who completed this" list. In server-paginated
  // mode this holds every page fetched so far; in client mode it's the window
  // over [_allOtherParticipants].
  final otherParticipantSummaries = <ParticipantSummary>[].obs;
  // CLIENT-MODE fallback only: the full list parsed from a non-paginated
  // response, sorted locally and revealed in pages of [_participantsPageSize].
  final List<ParticipantSummary> _allOtherParticipants = [];
  static const int _participantsPageSize = 20;
  // Newest-first (true) vs oldest-first (false). In server mode this becomes the
  // `sort` query param; in client mode it sorts within each relationship tier.
  final RxBool participantsSortNewest = true.obs;

  // Pagination bookkeeping for the participants list.
  int _participantsPage = 1;
  int _listChallengeId = 0;
  // True once a response carries pagination metadata ⇒ trust the server's
  // paging + ordering. False ⇒ backend not paginated yet ⇒ paginate on client.
  final RxBool _serverPaginated = false.obs;
  final RxBool _serverHasMore = false.obs;
  final RxBool isLoadingMoreParticipants = false.obs;
  final selected = 0.obs;
  var isLoading = false.obs;
  var submissions = <Map<String, dynamic>>[].obs;
  var currentUserId = 0.obs;
  var selectedTab = 0.obs;

  RxString avatarurl = ''.obs;
  RxList minimeList = [].obs;
  RxList explore = ["All", "In Progress", "Completed"].obs;
  RxInt selecteIndex = 0.obs;

  // History tabs (In Progress / Completed) are server-paginated via a separate
  // endpoint; the All tab keeps using the already-loaded `challenges`.
  final historyItems = <ChallengeCardModel>[].obs;
  final RxBool historyHasMore = false.obs;
  final RxBool historyLoadingMore = false.obs;
  int _historyPage = 1;
  String _historyTab = '';
  final ScrollController listScrollController = ScrollController();

  void selectIndex(int i) {
    selected.value = i;
    // Each tab swaps its data source. All → existing cards; the others fetch
    // their full-history endpoint (reset to page 1).
    if (i == 1) {
      fetchHistory('in_progress', reset: true);
    } else if (i == 2) {
      fetchHistory('completed', reset: true);
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    fetchChallengeCards();
    getRedDot();
    // Infinite scroll for the history tabs.
    listScrollController.addListener(() {
      if (!listScrollController.hasClients) return;
      final pos = listScrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        loadMoreHistory();
      }
    });
  }

  @override
  void onClose() {
    listScrollController.dispose();
    super.onClose();
  }

  var challenges = <ChallengeCardModel>[].obs;

  /// Fetch a history tab ('in_progress' | 'completed'). [reset] starts a fresh
  /// page-1 load (shimmer); otherwise appends the next page.
  Future<void> fetchHistory(String tab, {bool reset = false}) async {
    if (!reset && (historyLoadingMore.value || !historyHasMore.value)) return;
    try {
      if (reset) {
        _historyTab = tab;
        _historyPage = 1;
        historyHasMore.value = false;
        historyItems.clear();
        isLoading.value = true;
      } else {
        historyLoadingMore.value = true;
      }

      final data = await ApiService.getChallengeHistory(
        tab: tab,
        page: _historyPage,
      );

      final items =
          (data['items'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (e) =>
                    ChallengeCardModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();

      if (reset) {
        historyItems.assignAll(items);
      } else {
        historyItems.addAll(items);
      }
      historyHasMore.value = data['hasMore'] == true;
    } catch (e) {
      log('❌ history fetch error: $e');
      if (reset) AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      historyLoadingMore.value = false;
    }
  }

  Future<void> loadMoreHistory() async {
    if (selected.value != 1 && selected.value != 2) return;
    if (historyLoadingMore.value || !historyHasMore.value) return;
    _historyPage += 1;
    await fetchHistory(_historyTab, reset: false);
  }

  Future<void> fetchChallengeCards() async {
    try {
      isLoading.value = true;
      // EasyLoading.show();
      final list = await ApiService.getChallengescards();

      challenges.value =
          list.map((e) => ChallengeCardModel.fromJson(e)).toList();

      log("✅ Raw challenges: ${jsonEncode(list)}");

      final ids = challenges.map((c) => c.id).toList();
      if (ids.isNotEmpty) {
        await fetchMySubmissions(ids);
        // await fetchOtherSubmissions(ids);
      }
    } catch (e) {
      log("❌ Exception: $e");
      AppSnackbar.error(e.toString());
    } finally {
      // EasyLoading.dismiss();
      isLoading.value = false;
    }
  }

  Future<void> fetchMySubmissions(List<int> challengeIds) async {
    try {
      isLoading.value = true;

      final uniqueIds = challengeIds.toSet().toList();

      final futures =
          uniqueIds.map((id) async {
            try {
              return await ApiService.getMySubmissionChallenge(id);
            } catch (e) {
              return <Map<String, dynamic>>[];
            }
          }).toList();

      final results = await Future.wait<List<Map<String, dynamic>>>(
        futures,
        eagerError: false,
      );

      final all =
          results.expand((list) {
            list.sort((a, b) {
              final ad =
                  DateTime.tryParse('${a['createdAt'] ?? ''}') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bd =
                  DateTime.tryParse('${b['createdAt'] ?? ''}') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bd.compareTo(ad);
            });
            return list;
          }).toList();

      submissions.value = all;
      log('✅ Submissions fetched: ${submissions.toJson()}');
    } catch (e) {
      log('❌ Exception: $e');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOtherSubmissionsSingle(int challengeId) async {
    try {
      // isLoading.value = true;
      Future.delayed(Duration.zero, () => isLoading.value = true);

      _listChallengeId = challengeId;
      _participantsPage = 1;

      final res = await ApiService.getOthersSubmissions(
        challengeId,
        page: 1,
        pageSize: _participantsPageSize,
        sort: participantsSortNewest.value ? 'newest' : 'oldest',
      );

      final rawList = (res['items'] as List).cast<Map<String, dynamic>>();
      _serverPaginated.value = res['paginated'] == true;

      // Parse, recording each item's API position (used for sort tiebreak /
      // newest-oldest fallback in CLIENT mode).
      final participants = <ParticipantSummary>[];
      for (var i = 0; i < rawList.length; i++) {
        final p = ParticipantSummary.fromJson(rawList[i]);
        p.apiIndex = i;
        participants.add(p);
      }

      if (_serverPaginated.value) {
        // Server orders + paginates — show this page as-is, no client sort.
        _allOtherParticipants.clear();
        otherParticipantSummaries.assignAll(participants);
        _serverHasMore.value = _resolveServerHasMore(
          res,
          received: participants.length,
          totalShown: participants.length,
        );
      } else {
        // Backend not paginated yet → this is the full list. Sort + window it.
        _allOtherParticipants
          ..clear()
          ..addAll(participants);
        _sortAllParticipants();
        _resetParticipantWindow();
        _serverHasMore.value = false;
      }

      log(
        ' others fetched: ${participants.length} '
        '(serverPaginated=${_serverPaginated.value})',
      );
    } catch (e, st) {
      log(' Exception in fetchOtherSubmissionsSingle: $e');
      log(st.toString());
      AppSnackbar.error(e.toString());
    } finally {
      // isLoading.value = false;

      Future.delayed(Duration.zero, () => isLoading.value = false);
    }
  }

  // ── "Others who completed this": pagination (server-paginated, with a
  //    client-side fallback when the backend isn't paginated yet) ────────────

  /// Whether more participants remain to load. Server mode → the server's
  /// hasMore; client mode → unrevealed items in the local full list.
  bool get hasMoreParticipants =>
      _serverPaginated.value
          ? _serverHasMore.value
          : otherParticipantSummaries.length < _allOtherParticipants.length;

  /// Compute hasMore for a server page: prefer explicit `hasMore`, else derive
  /// from `total`, else assume "more" when we got a full page.
  bool _resolveServerHasMore(
    Map<String, dynamic> res, {
    required int received,
    required int totalShown,
  }) {
    final hm = res['hasMore'];
    if (hm is bool) return hm;
    final total = res['total'] as int?;
    if (total != null) return totalShown < total;
    return received >= _participantsPageSize;
  }

  /// Relationship tier: 0 = friend, 1 = shares a community/group with me,
  /// 2 = everyone else. Lower sorts first.
  int _participantRank(ParticipantSummary u) {
    if (u.relationship.isFriend) return 0;
    if (u.relationship.sharedCommunities.isNotEmpty ||
        u.relationship.sharedGroups.isNotEmpty) {
      return 1;
    }
    return 2;
  }

  void _sortAllParticipants() {
    final newest = participantsSortNewest.value;
    _allOtherParticipants.sort((a, b) {
      // 1) relationship tier first (friends → shared → others)
      final r = _participantRank(a).compareTo(_participantRank(b));
      if (r != 0) return r;
      // 2) time within the tier (newest or oldest), when a timestamp exists
      final ta = a.submittedAt;
      final tb = b.submittedAt;
      if (ta != null && tb != null) {
        final c = newest ? tb.compareTo(ta) : ta.compareTo(tb);
        if (c != 0) return c;
      }
      // 3) fallback / stable tiebreak: API order (assumes API is newest-first)
      return newest
          ? a.apiIndex.compareTo(b.apiIndex)
          : b.apiIndex.compareTo(a.apiIndex);
    });
  }

  void _resetParticipantWindow() {
    final end = _participantsPageSize.clamp(0, _allOtherParticipants.length);
    otherParticipantSummaries.assignAll(_allOtherParticipants.sublist(0, end));
  }

  /// Load the next page of participants (infinite scroll).
  Future<void> loadMoreParticipants() async {
    if (!hasMoreParticipants) return;

    if (!_serverPaginated.value) {
      // CLIENT mode: reveal the next slice of the already-fetched full list.
      final current = otherParticipantSummaries.length;
      final end = (current + _participantsPageSize).clamp(
        0,
        _allOtherParticipants.length,
      );
      otherParticipantSummaries.addAll(
        _allOtherParticipants.sublist(current, end),
      );
      return;
    }

    // SERVER mode: fetch the next page from the backend and append it.
    if (isLoadingMoreParticipants.value) return;
    isLoadingMoreParticipants.value = true;
    try {
      final nextPage = _participantsPage + 1;
      final res = await ApiService.getOthersSubmissions(
        _listChallengeId,
        page: nextPage,
        pageSize: _participantsPageSize,
        sort: participantsSortNewest.value ? 'newest' : 'oldest',
      );
      final rawList = (res['items'] as List).cast<Map<String, dynamic>>();

      // Dedupe by userId — also protects against a backend that ignores `page`
      // and returns the same rows (we then simply stop).
      final seen = otherParticipantSummaries.map((e) => e.userId).toSet();
      final fresh = <ParticipantSummary>[];
      for (final m in rawList) {
        final p = ParticipantSummary.fromJson(m);
        if (p.userId != 0 && seen.contains(p.userId)) continue;
        fresh.add(p);
      }

      _participantsPage = nextPage;
      otherParticipantSummaries.addAll(fresh);
      _serverHasMore.value =
          fresh.isEmpty
              ? false
              : _resolveServerHasMore(
                res,
                received: rawList.length,
                totalShown: otherParticipantSummaries.length,
              );
    } catch (e) {
      log('loadMoreParticipants error: $e');
    } finally {
      isLoadingMoreParticipants.value = false;
    }
  }

  /// Switch the newest/oldest filter. Server mode → refetch from page 1 with the
  /// new `sort`; client mode → re-sort the local list and rewind the window.
  void setParticipantsSort(bool newest) {
    if (participantsSortNewest.value == newest) return;
    participantsSortNewest.value = newest;
    if (_serverPaginated.value) {
      fetchOtherSubmissionsSingle(_listChallengeId);
    } else {
      _sortAllParticipants();
      _resetParticipantWindow();
    }
  }

  List<ChallengeCardModel> get filtered {
    switch (selected.value) {
      case 1: // In Progress — server-provided full history
      case 2: // Completed — server-provided full history
        return historyItems;
      default: // All — existing cards, client-sorted: incomplete → in-progress → completed
        return _sortedAll();
    }
  }

  List<ChallengeCardModel> _sortedAll() {
    int rank(ChallengeCardModel c) {
      if (_isCompleted(c)) return 2;
      if (_isInProgress(c)) return 1;
      return 0; // not started / incomplete
    }

    final list = [...challenges];
    list.sort((a, b) => rank(a).compareTo(rank(b)));
    return list;
  }

  bool _isCompleted(ChallengeCardModel c) =>
      (c.status ?? '').trim().toLowerCase() == 'completed';

  bool _isInProgress(ChallengeCardModel c) {
    final uploaded = c.uploadedCount;
    final required = c.requiredCount;
    final started = uploaded > 0;
    final notCompleted = uploaded < required;
    return started && notCompleted;
  }

  /// list of challenges

  RxList imagelist =
      [
        "assets/Images/skcunny.png",
        "assets/Images/skgroupchat.png",
        "assets/Images/skpppp.png",
      ].obs;

  // Completed Users (Demo)

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"];
        minimeList.value = data["minime"] ?? '';
        avatarurl.value = minimeList.last['avatarUrl'] ?? '';
        log("${avatarurl.value}");
      } else {
        log("❌ Server error: ${response.statusCode}");
        AppSnackbar.error("Server returned ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error loading profile: $e");
    }
  }

  String formatTimeRemaining(int? ms) {
    if (ms == null) return '';
    if (ms <= 0) return '0s';

    final totalSec = ms ~/ 1000;
    final days = totalSec ~/ 86400;
    final hours = (totalSec % 86400) ~/ 3600;

    if (days > 0 && hours > 0) return '${days}d ${hours}h';
    if (days > 0) return '${days}d';
    if (hours > 0) return '${hours}h';

    final mins = (totalSec % 3600) ~/ 60;
    if (mins > 0) return '${mins}m';

    final secs = totalSec % 60;
    return '${secs}s';
  }

  void showPhotoViewer(
    BuildContext context,
    List<String> photos,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder:
          (_) => PhotoViewerDialog(photos: photos, initialIndex: initialIndex),
    );
  }

 

  ////////////////////////////////NOTIFICATION////////////////////////////

  final _badgeService = Get.find<NotificationBadgeService>();
  RxBool get notificationRedDot => _badgeService.notificationRedDot;
  Future<void> getRedDot() => _badgeService.getRedDot();
  Future<void> clearNotificationDot() => _badgeService.clearNotificationDot();
}
