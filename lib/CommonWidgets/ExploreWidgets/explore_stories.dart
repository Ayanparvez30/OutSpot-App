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

/// The redesign frames in Figma are drawn 393pt wide, but ScreenUtil's design
/// size is 360 (see main.dart). Feeding raw Figma px straight into `.w` renders
/// everything ~9% oversized, so convert first: `_fig(74).w` puts 74 Figma px on
/// screen as 74 real px on a 393-wide device, and scales from there.
double _fig(double figmaPx) => figmaPx * (360 / 393);

/// Label under a friend's bubble: their real name, falling back to the username
/// for accounts that never set one (the backend leaves both name fields null).
String _displayName(StoryUser u) {
  final full = '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
  return full.isNotEmpty ? full : u.username;
}

/// Story bubble metrics, straight off the "Stories Container" frame
/// (node 7319:14451) of the App Redesign page.
class _StoryDim {
  /// Dialled down from the redesign's 74px ring on request — full size read too
  /// heavy on a 360-wide phone. Every geometric value goes through this, so the
  /// bubble stays proportionally true to Figma; change this one number to
  /// resize the whole row.
  static const double scale = 0.87;

  static double _s(double figmaPx) => _fig(figmaPx) * scale;

  static final double item = _s(74); // bubble width
  static final double pairHeight = _s(108); // avatar stack, no label
  static final double ring = _s(74); // outer ring diameter
  static final double ringStroke = _s(2.5);
  static final double cover = _s(64); // photo inside the ring
  static final double miniMe = _s(41); // 3D character above the ring
  static final double miniMeVisible = _s(36); // how much of it shows
  static final double miniMeLeft = _s(17);

  /// Minime avatars are full-body 768×1152 renders, but the redesign shows a
  /// head-and-shoulders close-up. Head plus a little breathing room lands in
  /// the top 440px square of that artwork, so the image is drawn 768/440 ≈
  /// 1.75× the frame width and pinned top-centre; the frame crops the body,
  /// and the shoulders run on behind the ring. Drawing the render whole
  /// instead leaves the face about 14px wide — unreadable.
  static const double miniMeZoom = 768 / 440;

  /// Source aspect ratio of the minime renders (768×1152).
  static const double miniMeAspect = 1152 / 768;
  static final double ringTop = _s(34);
  static final double labelGap = _fig(4);
  static final double labelSize = _fig(12);
  static final double labelHeight = _fig(16);
  static final double gap = _fig(16); // between bubbles

  /// Avatar stack + gap + label. The Explore screen reserves exactly this, so
  /// resizing via [scale] can't leave the row's reserved height out of step.
  static double get itemHeight => pairHeight + labelGap + labelHeight;

  /// Unseen ring — #D4456A in the redesign (was #DD4141).
  static const Color ringUnseen = Color(0xffD4456A);

  /// Seen ring keeps the existing recessive dark tone; the redesign only
  /// specifies the unseen state.
  static const Color ringSeen = Color(0xff2A2A2E);
}

class StoriesListSection extends StatefulWidget {
  const StoriesListSection({super.key});

  /// Height the Explore screen must reserve for the row. Derived from the same
  /// metrics the bubbles use, so the two can't drift apart.
  static double get rowHeight => _StoryDim.itemHeight.w;

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
                name: g.community.name,
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
              name: _displayName(latest.user),
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
              name: _displayName(latest.user),
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
              name: g.community.name,
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
                      name: it.name,
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
                      name: it.name,
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
    // Mirrors the real bubble's geometry so the row doesn't jump when the
    // stories land.
    return Container(
      margin: EdgeInsets.only(right: _StoryDim.gap.w),
      width: _StoryDim.item.w,
      height: _StoryDim.itemHeight.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _StoryDim.item.w,
            height: _StoryDim.pairHeight.w,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: _StoryDim.ringTop.w,
                  child: Container(
                    width: _StoryDim.ring.w,
                    height: _StoryDim.ring.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: _StoryDim.ringStroke.w,
                      ),
                    ),
                    child: ClipOval(
                      child: ShimmerPlaceholderCircle(size: _StoryDim.ring.w),
                    ),
                  ),
                ),
                Positioned(
                  left: _StoryDim.miniMeLeft.w,
                  top: 0,
                  child: ClipRect(
                    child: SizedBox(
                      width: _StoryDim.miniMe.w,
                      height: _StoryDim.miniMeVisible.w,
                      child: ShimmerPlaceholderCircle(
                        size: _StoryDim.miniMe.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _StoryDim.labelGap.w),
          ShimmerPlaceholderCircle(size: _StoryDim.labelSize.w),
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

  /// Label under the bubble — the friend's username, or the community's name.
  final String name;

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
    this.name = '',
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

  /// Username shown under the bubble (redesign). Empty = no label.
  final String name;

  const _UserBubble({
    required this.cover,
    required this.overlay,
    this.isVideo = false,
    required this.onTap,
    this.communityLogo = '',
    this.isSeen = false,
    this.name = '',
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

  /// The photo inside the ring — video thumbnail, cached network image, or a
  /// themed fallback once the media has expired (404).
  Widget _coverImage() {
    if (_isVideoUrl) {
      if (_thumbLoading) {
        return ShimmerPlaceholderCircle(size: _StoryDim.cover.w);
      }
      if (_thumbPath != null) {
        return Image.file(
          File(_thumbPath!),
          fit: BoxFit.cover,
          width: _StoryDim.cover.w,
          height: _StoryDim.cover.w,
          filterQuality: FilterQuality.high,
        );
      }
      return const Icon(Icons.videocam, color: Colors.white54);
    }
    return CachedNetworkImage(
      imageUrl: widget.cover,
      fit: BoxFit.cover,
      placeholder: (c, _) => ShimmerPlaceholderCircle(size: _StoryDim.cover.w),
      // Story media gone (expired/deleted → 404). Show a clean themed
      // placeholder, not a broken-image glyph.
      errorWidget: (c, _, __) => _coverFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.only(right: _StoryDim.gap.w),
        width: _StoryDim.item.w,
        height: _StoryDim.itemHeight.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _StoryDim.item.w,
              height: _StoryDim.pairHeight.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The user's 3D character peeking out above the ring. Drawn
                  // first so the ring overlaps its lower edge, exactly as the
                  // redesign clips the bottom 5px of the 41px artwork.
                  if (widget.overlay.isNotEmpty)
                    Positioned(
                      left: _StoryDim.miniMeLeft.w,
                      top: 0,
                      child: ClipRect(
                        child: SizedBox(
                          width: _StoryDim.miniMe.w,
                          height: _StoryDim.miniMeVisible.w,
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: SizedBox(
                              // Oversized on purpose, pinned top-centre: the
                              // frame crops everything below the shoulders so
                              // only the face shows, as in the redesign.
                              width: _StoryDim.miniMe.w * _StoryDim.miniMeZoom,
                              height:
                                  _StoryDim.miniMe.w *
                                  _StoryDim.miniMeZoom *
                                  _StoryDim.miniMeAspect,
                              child: CachedNetworkImage(
                                imageUrl: widget.overlay,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                filterQuality: FilterQuality.medium,
                                errorWidget:
                                    (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    top: _StoryDim.ringTop.w,
                    child: Container(
                      width: _StoryDim.ring.w,
                      height: _StoryDim.ring.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // White fill shows as a thin gap between ring and photo.
                        color: Colors.white,
                        // Seen → dark, recessive ring that sits back into the
                        // theme; unseen → the redesign's brand pink.
                        border: Border.all(
                          color:
                              widget.isSeen
                                  ? _StoryDim.ringSeen
                                  : _StoryDim.ringUnseen,
                          width: _StoryDim.ringStroke.w,
                        ),
                      ),
                      child: Center(
                        child: ClipOval(
                          child: SizedBox(
                            width: _StoryDim.cover.w,
                            height: _StoryDim.cover.w,
                            child: _coverImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Friend-and-community stories keep their community badge.
                  // The redesign doesn't specify this case, so rather than drop
                  // the distinction it sits as a small marker on the ring.
                  if (widget.communityLogo.isNotEmpty)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: _fig(24).w,
                        height: _fig(24).w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xff2D0731),
                            width: 1.5,
                          ),
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
                ],
              ),
            ),
            if (widget.name.isNotEmpty) ...[
              SizedBox(height: _StoryDim.labelGap.w),
              SizedBox(
                width: _StoryDim.item.w,
                // Fixed height so a font that renders a hair taller than the
                // 16px line box can't overflow the 128px bubble.
                height: _StoryDim.labelHeight.w,
                child: Center(
                  child: Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _StoryDim.labelSize.sp,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
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

  /// Community name shown under the bubble (redesign).
  final String name;

  const _CommunityBubble({
    required this.cover,
    required this.overlay,
    required this.onTap,
    this.isSeen = false,
    this.name = '',
  });
  @override
  Widget build(BuildContext context) => _UserBubble(
    cover: cover,
    overlay: overlay,
    onTap: onTap,
    isSeen: isSeen,
    name: name,
  );
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
