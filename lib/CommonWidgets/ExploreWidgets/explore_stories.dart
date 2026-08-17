import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/community_model.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class StoriesListSection extends StatefulWidget {
  const StoriesListSection({super.key});

  @override
  State<StoriesListSection> createState() => _StoriesListSectionState();
}

class _StoriesListSectionState extends State<StoriesListSection> {
  final ScrollController _scrollController = ScrollController();
  late final ExploreController controller;

  @override
  void initState() {
    super.initState();
    controller =
        Get.isRegistered<ExploreController>()
            ? Get.find<ExploreController>()
            : Get.put(ExploreController());
    // Scroll right → near the end → load the next page of friends.
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 200) {
        if (controller.selectedIndex.value != 2) {
          controller.loadMoreFriends();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obx ব্যবহার করছি যাতে selectedIndex (Filter) চেঞ্জ হলে লিস্ট অটো আপডেট হয়
    return Obx(() {
      // Subscribe to seen-state changes so bubbles recolour (red→grey) and
      // reorder (seen → end) the instant a story is viewed.
      controller.seenStoryVersion.value;

      if (controller.isLoading.value) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          itemBuilder: (_, i) => const _ShimmerBubble(),
        );
      }

      final tab = controller.selectedIndex.value;

      // ::::: 1. Communities Tab Logic :::::
      if (tab == 2) {
        // Includes friend-and-community stories grouped under their community
        // (they live in the friends bucket of the "all" feed).
        final groups = controller.communityTabGroups;
        if (groups.isEmpty) return const SizedBox();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: groups.length,
          itemBuilder: (_, i) {
            final g = groups[i];
            final cover =
                (g.stories.isNotEmpty ? (g.stories.first.mediaUrl ?? '') : '')
                        .isNotEmpty
                    ? g.stories.first.mediaUrl!
                    : (g.community.imageUrl ?? '');
            final overlay = g.community.imageUrl ?? '';

            // 🌟 অ্যানিমেশন ক্লাসে র‍্যাপ করা হলো
            return AnimatedStoryBubble(
              index: i,
              child: _CommunityBubble(
                cover: cover,
                overlay: overlay,
                isSeen: controller.isGroupSeen(g.stories),
                onTap: () async {
                  controller.markStoriesSeen(g.stories);
                  await Get.toNamed(
                    Routes.postscreen,
                    arguments: {
                      "stories": g.stories,
                      "startIndex": 0,
                      "currentUserId": controller.currentUserId.value,
                      "community": g.community,
                      "communityId": g.community.id,
                      "communityHasMore": g.hasMore,
                      "communityPage": g.page,
                    },
                  );
                  controller.seenStoryVersion.refresh();
                },
              ),
            );
          },
        );
      }
      // ::::: 2. Friends & All Logic :::::

      List<_BubbleItem> items = [];
      final friendEntries = controller.getSortedFriendEntriesMineFirst();

      if (tab == 1) {
        // Friends Only filter

        final filtered =
            friendEntries
                .where(
                  (e) =>
                      e.value.first.user.id != controller.currentUserId.value,
                )
                .toList();

        for (final e in filtered) {
          final stories = e.value;
          final latest = stories.first;
          items.add(
            _BubbleItem(
              isCommunity: false,
              isVideo: latest.type.toLowerCase() == 'video',
              ownerId: latest.user.id,
              latest: latest.createdAt,
              cover: latest.mediaUrl ?? '',
              overlay: latest.user.avatarUrl ?? '',
              stories: stories,
              // Friends tab shows just the friend — the community overlay
              // (dual avatar) belongs only on the All tab.
              communityLogo: '',
            ),
          );
        }
      } else {
        // All (Friends + Communities)
        for (final e in friendEntries) {
          final stories = e.value;
          final latest = stories.first;

          // 🔥 FIXED: Check if it's my story. If yes, use the latest avatarurl from controller
          final isMine = latest.user.id == controller.currentUserId.value;
          final avatarToUse =
              isMine && controller.avatarurl.value.isNotEmpty
                  ? controller.avatarurl.value
                  : (latest.user.avatarUrl ?? '');

          items.add(
            _BubbleItem(
              isCommunity: false,
              isVideo: latest.type.toLowerCase() == 'video',
              ownerId: latest.user.id,
              latest: latest.createdAt,
              cover: latest.mediaUrl ?? '',
              overlay: avatarToUse,
              stories: stories,
              communityLogo:
                  latest.relation == 'friend-and-community'
                      ? (latest.primaryCommunity?.imageUrl ?? '')
                      : '',
            ),
          );
        }
        for (final g in controller.communityGroups) {
          final cover =
              (g.stories.isNotEmpty ? (g.stories.first.mediaUrl ?? '') : '')
                      .isNotEmpty
                  ? g.stories.first.mediaUrl!
                  : (g.community.imageUrl ?? '');

          items.add(
            _BubbleItem(
              isCommunity: true,
              ownerId: g.community.id,
              latest: controller.gLatest(g),
              cover: cover,
              overlay: g.community.imageUrl ?? '',
              stories: g.stories,
              community: g.community,
              communityHasMore: g.hasMore,
              communityPage: g.page,
            ),
          );
        }
      }

      if (items.isEmpty) return const SizedBox();

      // Sorting: My story first; then UNSEEN before SEEN (so already-viewed
      // bubbles fall to the end of the loaded list); newest-first within each
      // group. Reads seenStoryIds so the row re-orders reactively after viewing.
      final myId = controller.currentUserId.value;
      final iMine = items.indexWhere(
        (it) => !it.isCommunity && it.ownerId == myId,
      );
      _BubbleItem? mine;
      if (iMine != -1) mine = items.removeAt(iMine);

      items.sort((a, b) {
        final sa = controller.isGroupSeen(a.stories) ? 1 : 0;
        final sb = controller.isGroupSeen(b.stories) ? 1 : 0;
        if (sa != sb) return sa - sb; // unseen (0) first, seen (1) last
        return b.latest.compareTo(a.latest);
      });
      if (mine != null) items.insert(0, mine);

      return ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: items.length + (controller.friendsLoading.value ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= items.length) return const _ShimmerBubble();
          final it = items[i];

          final seen = controller.isGroupSeen(it.stories);

          return AnimatedStoryBubble(
            index: i,
            child:
                it.isCommunity
                    ? _CommunityBubble(
                      cover: it.cover,
                      overlay: it.overlay,
                      isSeen: seen,
                      onTap: () async {
                        controller.markStoriesSeen(it.stories);
                        await Get.toNamed(
                          Routes.postscreen,
                          arguments: {
                            "stories": it.stories,
                            "startIndex": 0,
                            "currentUserId": controller.currentUserId.value,
                            "community": it.community,
                            "communityId": it.community?.id,
                            "communityHasMore": it.communityHasMore,
                            "communityPage": it.communityPage,
                          },
                        );
                        // Guarantee the row reflects seen-state on return.
                        controller.seenStoryVersion.refresh();
                      },
                    )
                    : _UserBubble(
                      cover: it.cover,
                      overlay: it.overlay,
                      isVideo: it.isVideo,
                      communityLogo: it.communityLogo,
                      isSeen: seen,
                      onTap: () async {
                        controller.markStoriesSeen(it.stories);
                        await Get.toNamed(
                          Routes.postscreen,
                          arguments: {
                            "stories": it.stories,
                            "startIndex": 0,
                            "currentUserId": controller.currentUserId.value,
                          },
                        );
                        // Guarantee the row reflects seen-state on return.
                        controller.seenStoryVersion.refresh();
                      },
                    ),
          );
        },
      );
    });
  }
}

class AnimatedStoryBubble extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedStoryBubble({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedStoryBubble> createState() => _AnimatedStoryBubbleState();
}

class _AnimatedStoryBubbleState extends State<AnimatedStoryBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class _ShimmerBubble extends StatelessWidget {
  const _ShimmerBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 65.w,
      height: 65.w,
      child: Stack(
        children: [
          Container(
            width: 65.w,
            height: 65.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(child: const ShimmerPlaceholderCircle(size: 65)),
          ),

          Positioned(
            bottom: 20.h,
            right: -1.5.w,
            child: Container(
              width: 30.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: const ShimmerPlaceholderCircle(size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ::::: Helper Classes (Private to this file) :::::

class _BubbleItem {
  final bool isCommunity;
  final bool isVideo;
  final int ownerId;
  final DateTime latest;
  final String cover, overlay;
  final List<StoryModel> stories;
  final CommunityModel? community;

  /// Community logo to overlay on a friend bubble when the story is
  /// friend-and-community (empty = no overlay).
  final String communityLogo;

  // Community pagination passthrough (for community items → story viewer).
  final bool communityHasMore;
  final int communityPage;

  _BubbleItem({
    required this.isCommunity,
    this.isVideo = false,
    required this.ownerId,
    required this.latest,
    required this.cover,
    required this.overlay,
    required this.stories,
    this.community,
    this.communityLogo = '',
    this.communityHasMore = false,
    this.communityPage = 1,
  });
}

class _UserBubble extends StatefulWidget {
  final String cover, overlay;
  final bool isVideo;
  final VoidCallback onTap;

  /// Community logo overlay for friend-and-community stories (empty = none).
  final String communityLogo;

  /// Already-viewed → grey ring; unseen → red ring.
  final bool isSeen;

  const _UserBubble({
    required this.cover,
    required this.overlay,
    this.isVideo = false,
    required this.onTap,
    this.communityLogo = '',
    this.isSeen = false,
  });

  @override
  State<_UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends State<_UserBubble> {
  String? _thumbPath;
  bool _thumbLoading = true;

  bool get _isVideoUrl {
    if (widget.isVideo) return true;
    final lower = widget.cover.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    if (_isVideoUrl && widget.cover.isNotEmpty) {
      _loadCachedThumbnail();
    } else {
      _thumbLoading = false;
    }
  }

  Future<void> _loadCachedThumbnail() async {
    final path = await _StoryThumbCache.instance.getThumbnail(widget.cover);
    if (mounted) {
      setState(() {
        _thumbPath = path;
        _thumbLoading = false;
      });
    }
  }

  // Clean themed placeholder for a story whose media is gone (404).
  Widget _coverFallback() {
    return Container(
      width: 65.w,
      height: 65.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2D0731), Color(0xff1A0420)],
        ),
      ),
      child: Icon(Icons.photo_outlined, color: Colors.white24, size: 26.w),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 65.w,
        height: 65.w,
        child: Stack(
          children: [
            Container(
              width: 65.w,
              height: 65.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Seen → dark, recessive ring that sits back into the theme;
                // unseen → brand red. Seen ring is a touch thicker so it still
                // reads as a ring rather than a faint hairline.
                border: Border.all(
                  color:
                      widget.isSeen
                          ? const Color(0xff2A2A2E)
                          : const Color(0xffDD4141),
                  width: widget.isSeen ? 2.5 : 2,
                ),
              ),
              child: ClipOval(
                child:
                    _isVideoUrl
                        ? (_thumbLoading
                            ? const ShimmerPlaceholderCircle(size: 60)
                            : _thumbPath != null
                            ? Image.file(
                              File(_thumbPath!),
                              fit: BoxFit.cover,
                              width: 65.w,
                              height: 65.w,
                              filterQuality: FilterQuality.high,
                            )
                            : const Icon(Icons.videocam, color: Colors.white54))
                        : CachedNetworkImage(
                          imageUrl: widget.cover,
                          fit: BoxFit.cover,
                          placeholder:
                              (c, _) =>
                                  const ShimmerPlaceholderCircle(size: 60),
                          // Story media gone (expired/deleted → 404). Show a
                          // clean themed placeholder, not a broken-image glyph.
                          errorWidget: (c, _, __) => _coverFallback(),
                        ),
              ),
            ),
            // Bottom-right badge: the user's avatar in FRONT, with the community
            // avatar stacked BEHIND it (back-stack look) for friend-and-community
            // stories. The community no longer sits on top of the story cover.
            if (widget.overlay.isNotEmpty)
              Positioned(
                bottom: 18.h,
                right: -1.5.w,
                child: SizedBox(
                  // Narrow box → the user avatar covers most of the community
                  // one, leaving only a small sliver peeking behind it.
                  width: widget.communityLogo.isNotEmpty ? 33.w : 28.w,
                  height: 28.w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // BACK: community avatar peeking out from behind-left.
                      if (widget.communityLogo.isNotEmpty)
                        Positioned(
                          left: 0,
                          top: 2.h,
                          child: Container(
                            width: 25.w,
                            height: 25.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // border: Border.all(
                              //   color: const Color(0xff2D0731),
                              //   width: 1.5,
                              // ),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.communityLogo,
                                fit: BoxFit.cover,
                                errorWidget:
                                    (_, __, ___) => const Icon(
                                      Icons.groups,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      // FRONT: the user's avatar.
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // border: Border.all(
                            //   color: const Color(0xff2D0731),
                            //   width: 1.5,
                            // ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.overlay,
                              alignment: Alignment.topCenter,
                              fit: BoxFit.cover,
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBubble extends StatelessWidget {
  final String cover, overlay;
  final VoidCallback onTap;
  final bool isSeen;
  const _CommunityBubble({
    required this.cover,
    required this.overlay,
    required this.onTap,
    this.isSeen = false,
  });
  @override
  Widget build(BuildContext context) =>
      _UserBubble(cover: cover, overlay: overlay, onTap: onTap, isSeen: isSeen);
}

/// Cached video thumbnail for story bubbles
class _StoryThumbCache {
  static final _StoryThumbCache instance = _StoryThumbCache._();
  _StoryThumbCache._();

  Directory? _cacheDir;
  final Map<String, String> _memCache = {};

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= Directory(
      '${(await getTemporaryDirectory()).path}/story_thumbs',
    );
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _urlToFileName(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    return '$hash.jpg';
  }

  Future<String?> getThumbnail(String videoUrl) async {
    // Memory cache
    if (_memCache.containsKey(videoUrl)) {
      final path = _memCache[videoUrl]!;
      if (await File(path).exists()) return path;
      _memCache.remove(videoUrl);
    }

    // Disk cache
    final dir = await _getCacheDir();
    final file = File('${dir.path}/${_urlToFileName(videoUrl)}');
    if (await file.exists()) {
      _memCache[videoUrl] = file.path;
      return file.path;
    }

    // Generate
    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 80,
      );
      if (thumbPath != null && await File(thumbPath).exists()) {
        _memCache[videoUrl] = thumbPath;
        return thumbPath;
      }
    } catch (e) {
      debugPrint('Story thumb error: $e');
    }
    return null;
  }
}
