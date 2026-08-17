import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/community_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Network_Manager/video_cache_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class ExploreController extends GetxController {
  RxList explore = ["All", "Friends", "Communities"].obs;
  final List<String> bars = List.generate(12, (index) => 'Bar Name');
  RxInt selectedIndex = 0.obs;

  // Overscroll tracker so the refresh indicator triggers on a smaller pull
  // than Flutter's default 25% viewport threshold. The GlobalKey itself now
  // lives in the Explore widget's State to avoid GlobalKey-duplication on
  // rebuilds.
  double refreshOverscroll = 0;
  bool refreshFired = false;
  RxMap<int, List<StoryModel>> userStoriesMap = <int, List<StoryModel>>{}.obs;
  RxList<StoryModel> allStories = <StoryModel>[].obs;
  var currentUserId = 0.obs;
  RxString avatarurl = ''.obs;
  RxList minimeList = [].obs;
  // Static category cards — no API call needed for the explore grid
  final List<Map<String, String>> staticCategories = [
    {
      'key': 'rooftop-bars',
      'title': 'Bars',
      'icon': 'assets/Images/rooftop.png',
    },
    {
      'key': 'outdoor-activities',
      'title': 'Outdoors',
      'icon': 'assets/Images/outdoor.png',
    },
     {'key': 'cafes', 'title': 'Cafes', 'icon': 'assets/Images/cafe.png'},
    
    {
      'key': 'popular-restaurants',
      'title': 'Restaurants',
      'icon': 'assets/Images/popular.png',
    },
    {
      'key': 'venue-events',
      'title': 'Venue Events',
      'icon': 'assets/Images/venue.png',
    },
  ];
  final friendsFeed = <StoryModel>[].obs;
  final groupedFriends = <int, List<StoryModel>>{}.obs;
  final communityGroups = <CommunityGroupModel>[].obs;
  final myCommunities = <CommunityModel>[].obs;
  RxBool isLoading = false.obs;

  // Story ids the user has already viewed — persisted in SharedPreferences.
  // Drives the bubble ring colour (red = unseen, grey = seen) and the
  // unseen-first ordering. Kept as a plain Set; [seenStoryVersion] is the
  // reactive trigger (RxSet's read methods aren't reliably tracked by Obx, so
  // bumping an RxInt is what actually rebuilds the row).
  final Set<int> _seenStoryIds = <int>{};
  final RxInt seenStoryVersion = 0.obs;

  Future<void> loadSeenStoryIds() async {
    _seenStoryIds
      ..clear()
      ..addAll(await UserPreference.getSeenStoryIds());
    seenStoryVersion.value++;
  }

  /// A story group (one bubble) is "seen" only when EVERY one of its current
  /// stories has been viewed — so a freshly-posted story re-reds the ring.
  bool isGroupSeen(List<StoryModel> stories) =>
      stories.isNotEmpty && stories.every((s) => _seenStoryIds.contains(s.id));

  /// Mark a group's stories as viewed (call when the viewer is opened). Updates
  /// the in-memory set immediately (instant recolour/reorder) then persists.
  Future<void> markStoriesSeen(List<StoryModel> stories) async {
    final ids = stories.map((s) => s.id).toList();
    final before = _seenStoryIds.length;
    _seenStoryIds.addAll(ids);
    if (_seenStoryIds.length != before) {
      seenStoryVersion.value++; // triggers the row to recolour + reorder
      await UserPreference.addSeenStoryIds(ids);
    }
  }

  /// Remove a single deleted story from the in-memory feed (no network) so the
  /// row updates without a full reload. Drops the owner/community bucket when
  /// it becomes empty. Call ONLY after a successful server delete.
  void removeStoryLocally(int storyId) {
    // Friend / personal buckets
    final emptyOwners = <int>[];
    groupedFriends.forEach((ownerId, stories) {
      stories.removeWhere((s) => s.id == storyId);
      if (stories.isEmpty) emptyOwners.add(ownerId);
    });
    for (final o in emptyOwners) {
      groupedFriends.remove(o);
    }

    // Community buckets
    final emptyGroups = <CommunityGroupModel>[];
    for (final g in communityGroups) {
      g.stories.removeWhere((s) => s.id == storyId);
      if (g.stories.isEmpty) emptyGroups.add(g);
    }
    communityGroups.removeWhere(emptyGroups.contains);

    // Post-feed lists
    _allPostFeedStories.removeWhere((s) => s.id == storyId);
    _allFilteredStories.removeWhere((s) => s.id == storyId);
    displayedPostFeedStories.removeWhere((s) => s.id == storyId);

    groupedFriends.refresh();
    communityGroups.refresh();
  }

  // Friends bucket pagination (horizontal load-more on the friends row)
  int _friendsPage = 1;
  final RxBool friendsHasMore = false.obs;
  final RxBool friendsLoading = false.obs;
  RxList<StoryModel> friendStories = <StoryModel>[].obs;
  RxList<StoryModel> myStories = <StoryModel>[].obs;

  // Post feed (stories-based) with client-side pagination
  TextEditingController postSearchController = TextEditingController();
  List<StoryModel> _allPostFeedStories = [];
  List<StoryModel> _allFilteredStories = [];
  RxList<StoryModel> displayedPostFeedStories = <StoryModel>[].obs;
  RxBool isPostFeedLoading = false.obs;
  RxBool isLoadingMorePosts = false.obs;
  static const int _postsPageSize = 10;
  bool get hasMorePosts =>
      displayedPostFeedStories.length < _allFilteredStories.length;

  RxInt currentTab = 0.obs;
  RxBool postFeedError = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    // Re-fetch posts if switching to Posts tab and data is empty or errored
    if (index == 1 &&
        displayedPostFeedStories.isEmpty &&
        !isPostFeedLoading.value) {
      fetchPostFeed();
    }
  }

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    // Seen-ids first (needed for unseen-first ordering). Then load the profile
    // ALONGSIDE the feeds — not before them. The story feed doesn't depend on
    // the profile (currentUserId only affects display-time "mine-first" sorting,
    // which is reactive), so blocking the feed behind loadUserProfile() only
    // made stories appear on Explore with a delay.
    await loadSeenStoryIds();
    await Future.wait([
      loadUserProfile(),
      fetchFeed('all'),
      fetchPostFeed(),
      getRedDot(),
    ]);
  }

  void selectIndex(int index) {
    // Switching tabs ONLY changes which slice of the already-loaded "all" feed
    // is shown — the story row filters by selectedIndex (all = friends +
    // communities, friends = friends only, communities = communities only).
    // We must NOT re-fetch per tab: the filter-specific endpoints overwrite
    // friendsFeed / communityGroups and were dropping friend-and-community
    // stories from the "all" view on tab switch. "all" is the source of truth.
    selectedIndex.value = index;
  }

  Future<void> fetchFeed(String filter, {bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;

      final res = await ApiService.fetchStoriesFeed(filter: filter);

      if (res.statusCode != 200) {
        AppSnackbar.error('Server error: ${res.statusCode}');
        return;
      }

      final raw = jsonDecode(res.body);
      final json =
          (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (filter == 'all') {
        // friends is now an object { page, hasMore, totalCount, stories }
        // (fall back to a plain list for the old shape).
        final friendsNode = json['friends'];
        final friendsStoriesJson =
            (friendsNode is Map)
                ? (friendsNode['stories'] as List? ?? const [])
                : (friendsNode as List? ?? const []);
        final friends =
            friendsStoriesJson
                .map(
                  (e) =>
                      StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList();
        friendsFeed.assignAll(friends);
        if (friendsNode is Map) {
          _friendsPage =
              (friendsNode['page'] is int) ? friendsNode['page'] : 1;
          friendsHasMore.value = friendsNode['hasMore'] == true;
        } else {
          _friendsPage = 1;
          friendsHasMore.value = false;
        }

        final groups =
            (json['communitiesGrouped'] as List? ?? const [])
                .map(
                  (e) => CommunityGroupModel.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();

        for (final g in groups) {
          g.stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        groups.sort((a, b) {
          final ad = gLatest(a);
          final bd = gLatest(b);
          return bd.compareTo(ad);
        });
        communityGroups.assignAll(groups);

        final mine =
            (json['myCommunities'] as List? ?? const [])
                .map(
                  (e) => CommunityModel.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();
        myCommunities.assignAll(mine);
      } else if (filter == 'friends') {
        // friends filter may return the bucket object or a top-level list.
        final friendsNode = json['friends'];
        final storiesJson =
            (friendsNode is Map)
                ? (friendsNode['stories'] as List? ?? const [])
                : (json['stories'] as List? ?? const []);
        final stories =
            storiesJson
                .map(
                  (e) =>
                      StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList();
        friendsFeed.assignAll(stories);
        final pg = (friendsNode is Map) ? friendsNode : json;
        _friendsPage = (pg['page'] is int) ? pg['page'] : 1;
        friendsHasMore.value = pg['hasMore'] == true;
      } else {
        final groups =
            (json['communitiesGrouped'] as List? ?? const [])
                .map(
                  (e) => CommunityGroupModel.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();
        for (final g in groups) {
          g.stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        groups.sort((a, b) {
          final ad = gLatest(a);
          final bd = gLatest(b);
          return bd.compareTo(ad);
        });
        communityGroups.assignAll(groups);

        final mine =
            (json['myCommunities'] as List? ?? const [])
                .map(
                  (e) => CommunityModel.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();
        myCommunities.assignAll(mine);
      }

      // Rebuild grouped friends from scratch (don't accumulate across fetches)
      _rebuildGroupedFriends();

      // Everyone else's stories are ready now — clear the loader so the row
      // shows immediately. Backfilling MY OWN story can need 1–2 extra network
      // calls (_ensureMyStoriesPresent); holding the whole row on the shimmer
      // for that was the 4–5s delay. It updates groupedFriends reactively, so
      // my own bubble just pops in a beat later instead of blocking everyone.
      isLoading.value = false;

      await _ensureMyStoriesPresent();

      // Smart background video caching after stories load
      VideoCacheService.instance.cacheStoryVideos(friendsFeed);
    } catch (e) {
      AppSnackbar.error('Failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Rebuild the per-user grouped friends map from the flat friendsFeed list.
  void _rebuildGroupedFriends() {
    groupedFriends.clear();
    if (friendsFeed.isNotEmpty) {
      for (final s in friendsFeed) {
        final uid = s.user.id;
        (groupedFriends[uid] ??= <StoryModel>[]).add(s);
      }
      for (final e in groupedFriends.entries) {
        e.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      groupedFriends.refresh();
    }
  }

  /// Horizontal load-more for the friends row.
  Future<void> loadMoreFriends() async {
    if (friendsLoading.value || !friendsHasMore.value) return;
    friendsLoading.value = true;
    try {
      final next = _friendsPage + 1;
      final res = await ApiService.fetchStoriesFeed(
        filter: 'all',
        bucket: 'friends',
        page: next,
        pageSize: 20,
      );
      if (res.statusCode == 200) {
        final j = (jsonDecode(res.body) as Map).cast<String, dynamic>();
        final more =
            (j['stories'] as List? ?? const [])
                .map(
                  (e) =>
                      StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList();
        friendsFeed.addAll(more);
        _friendsPage = (j['page'] is int) ? j['page'] : next;
        friendsHasMore.value = j['hasMore'] == true;
        _rebuildGroupedFriends();
      }
    } catch (e) {
      log('loadMoreFriends error: $e');
    } finally {
      friendsLoading.value = false;
    }
  }

  /// Horizontal load-more for a single community row.
  Future<void> loadMoreCommunity(int communityId) async {
    final idx = communityGroups.indexWhere(
      (g) => g.community.id == communityId,
    );
    if (idx == -1) return;
    final g = communityGroups[idx];
    if (g.loading || !g.hasMore) return;
    g.loading = true;
    communityGroups.refresh();
    try {
      final next = g.page + 1;
      final res = await ApiService.fetchStoriesFeed(
        filter: 'all',
        bucket: 'community',
        communityId: communityId,
        page: next,
        pageSize: 20,
      );
      if (res.statusCode == 200) {
        final j = (jsonDecode(res.body) as Map).cast<String, dynamic>();
        final more =
            (j['stories'] as List? ?? const [])
                .map(
                  (e) =>
                      StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList();
        g.stories.addAll(more);
        g.page = (j['page'] is int) ? j['page'] : next;
        g.hasMore = j['hasMore'] == true;
      }
    } catch (e) {
      log('loadMoreCommunity error: $e');
    } finally {
      g.loading = false;
      communityGroups.refresh();
    }
  }

  // mine-first friend groups
  List<MapEntry<int, List<StoryModel>>> getSortedFriendEntriesMineFirst() {
    final entries = groupedFriends.entries.toList();
    MapEntry<int, List<StoryModel>>? mine;
    final others = <MapEntry<int, List<StoryModel>>>[];

    for (final e in entries) {
      if (e.value.isEmpty) continue;
      if (e.value.first.user.id == currentUserId.value) {
        mine = e;
      } else {
        others.add(e);
      }
    }
    others.sort(
      (a, b) => b.value.first.createdAt.compareTo(a.value.first.createdAt),
    );
    return [if (mine != null) mine, ...others];
  }

  DateTime gLatest(CommunityGroupModel g) =>
      g.stories.isNotEmpty
          ? g.stories.first.createdAt
          : DateTime.fromMillisecondsSinceEpoch(0);

  /// Groups to show on the Communities tab, derived purely from the loaded
  /// "all" feed (no re-fetch). Community-only stories live in [communityGroups];
  /// friend-and-community stories live in the friends bucket ([groupedFriends])
  /// and carry their community in `story.communities` — fold those into their
  /// community here so they surface under Communities too (they show as a
  /// friend bubble with a community overlay only on the All tab).
  List<CommunityGroupModel> get communityTabGroups {
    final byId = <int, CommunityGroupModel>{};
    for (final g in communityGroups) {
      byId[g.community.id] = CommunityGroupModel(
        community: g.community,
        stories: [...g.stories],
        page: g.page,
        hasMore: g.hasMore,
        totalCount: g.totalCount,
      );
    }
    for (final stories in groupedFriends.values) {
      for (final s in stories) {
        if (!s.relation.contains('community')) continue;
        final c = s.primaryCommunity;
        if (c == null) continue;
        final existing = byId[c.id];
        if (existing != null) {
          if (!existing.stories.any((x) => x.id == s.id)) {
            existing.stories.add(s);
          }
        } else {
          byId[c.id] = CommunityGroupModel(
            community: CommunityModel(
              id: c.id,
              name: c.name,
              imageUrl: c.imageUrl,
              membersCount: 0,
              isCreator: false,
              isMember: true,
            ),
            stories: [s],
          );
        }
      }
    }
    final list = byId.values.toList();
    for (final g in list) {
      g.stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    list.sort((a, b) => gLatest(b).compareTo(gLatest(a)));
    return list;
  }
  /// Whether the horizontal stories row has anything to show for the currently
  /// selected filter (0=All, 1=Friends, 2=Communities). Mirrors the item-build
  /// logic in StoriesListSection so the row's reserved space collapses when the
  /// active filter is empty (e.g. Friends selected but only community stories
  /// exist → don't show an empty 80h gap).
  bool get hasStoriesForCurrentFilter {
    switch (selectedIndex.value) {
      case 2: // Communities
        return communityTabGroups.isNotEmpty;
      case 1: // Friends only (excludes my own story)
        return getSortedFriendEntriesMineFirst().any(
          (e) => e.value.first.user.id != currentUserId.value,
        );
      default: // All (friends + communities)
        return getSortedFriendEntriesMineFirst().isNotEmpty ||
            communityGroups.isNotEmpty;
    }
  }

  Future<void> _ensureMyStoriesPresent() async {
    final myId = currentUserId.value;

    final hasMinePersonal =
        groupedFriends.containsKey(myId) &&
        (groupedFriends[myId]?.isNotEmpty ?? false);

    final hasMineInCommunities = communityGroups.any(
      (g) => g.stories.any((s) => s.user.id == myId),
    );

    if (hasMinePersonal || hasMineInCommunities) {
      return;
    }

    List<StoryModel> mine = [];
    try {
      final meRes = await ApiService.fetchUserStories();
      if (meRes.statusCode == 200) {
        final raw = jsonDecode(meRes.body);
        final List list =
            (raw is Map) ? (raw['stories'] as List? ?? const []) : const [];
        mine =
            list
                .map(
                  (e) =>
                      StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList();
      }
    } catch (_) {}

    if (mine.isEmpty) {
      try {
        final resAll = await ApiService.fetchStory();
        if (resAll.statusCode == 200) {
          final raw = jsonDecode(resAll.body);
          final List list =
              (raw is Map) ? (raw['stories'] as List? ?? const []) : const [];
          mine =
              list
                  .map(
                    (e) =>
                        StoryModel.fromJson((e as Map).cast<String, dynamic>()),
                  )
                  .where((s) => s.user.id == myId)
                  .toList();
        }
      } catch (_) {}
    }

    if (mine.isEmpty) return;

    final existing = groupedFriends[myId] ?? <StoryModel>[];
    final existingIds = existing.map((e) => e.id).toSet();
    for (final s in mine) {
      if (!existingIds.contains(s.id)) existing.add(s);
    }
    existing.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    groupedFriends[myId] = existing;
    groupedFriends.refresh();
  }

  Future<void> loadUserProfile() async {
    try {
      final res = await ApiService.fetchUserProfile();
      if (res.statusCode != 200) {
        log("❌ Server error: ${res.statusCode}");
        AppSnackbar.error("Server returned ${res.statusCode}");
        return;
      }

      final root = jsonDecode(res.body);
      final Map<String, dynamic> map =
          (root is Map) ? Map<String, dynamic>.from(root) : <String, dynamic>{};

      final Map<String, dynamic> data =
          (map['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      final Map<String, dynamic>? user =
          (data['user'] as Map?)?.cast<String, dynamic>();

      final dynamic rawId = data['id'] ?? user?['id'] ?? 0;
      currentUserId.value = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

      final List<Map<String, dynamic>> minimes =
          (data['minime'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      minimeList.assignAll(minimes);

      // Set avatar from minime list (previously done in separate loadUserProfileForAvatar call)
      if (minimes.isNotEmpty) {
        avatarurl.value = (minimes.last['avatarUrl'] ?? '').toString();
      }

      log("My userId = ${currentUserId.value}, avatar = ${avatarurl.value}");
    } catch (e) {
      log("❌ Error loading profile: $e");
    }
  }

  ////////////////////////////////NOTIFICATION////////////////////////////

  final _badgeService = Get.find<NotificationBadgeService>();
  RxBool get notificationRedDot => _badgeService.notificationRedDot;
  Future<void> getRedDot() => _badgeService.getRedDot();
  Future<void> clearNotificationDot() => _badgeService.clearNotificationDot();

  Future<void> fetchPostFeed() async {
    try {
      isPostFeedLoading.value = true;
      postFeedError.value = false;

      final res = await ApiService.fetchExplorePosts();

      if (res.statusCode != 200) {
        log("Explore posts error: ${res.statusCode}");
        postFeedError.value = true;
        return;
      }

      final raw = jsonDecode(res.body);
      final json =
          (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      // Data comes pre-sorted from API (friends first, then public)
      _allPostFeedStories =
          (json['posts'] as List? ?? const [])
              .map(
                (e) => StoryModel.fromJson((e as Map).cast<String, dynamic>()),
              )
              .toList();

      _allFilteredStories = List.from(_allPostFeedStories);
      _showFirstPage();
    } catch (e) {
      log("Error fetching post feed: $e");
      postFeedError.value = true;
    } finally {
      isPostFeedLoading.value = false;
    }
  }

  void _showFirstPage() {
    final end =
        _allFilteredStories.length < _postsPageSize
            ? _allFilteredStories.length
            : _postsPageSize;
    displayedPostFeedStories.assignAll(_allFilteredStories.sublist(0, end));
  }

  void loadMorePosts() {
    if (isLoadingMorePosts.value || !hasMorePosts) return;
    isLoadingMorePosts.value = true;
    final current = displayedPostFeedStories.length;
    final end =
        (current + _postsPageSize) > _allFilteredStories.length
            ? _allFilteredStories.length
            : current + _postsPageSize;
    displayedPostFeedStories.addAll(_allFilteredStories.sublist(current, end));
    isLoadingMorePosts.value = false;
  }

  void filterPosts(String query) {
    if (query.isEmpty) {
      _allFilteredStories = List.from(_allPostFeedStories);
    } else {
      final lowerQuery = query.toLowerCase();
      _allFilteredStories =
          _allPostFeedStories.where((story) {
            final username = story.user.username.toLowerCase();
            final firstName = (story.user.firstName ?? '').toLowerCase();
            final lastName = (story.user.lastName ?? '').toLowerCase();
            return username.contains(lowerQuery) ||
                firstName.contains(lowerQuery) ||
                lastName.contains(lowerQuery);
          }).toList();
    }
    _showFirstPage();
  }
}
