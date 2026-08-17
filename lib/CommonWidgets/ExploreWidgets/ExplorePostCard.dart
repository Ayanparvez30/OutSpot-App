import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Model/story_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class ExplorePostCard extends StatelessWidget {
  final StoryModel story;

  const ExplorePostCard({super.key, required this.story});

  String get _displayName {
    final first = story.user.firstName ?? '';
    final last = story.user.lastName ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : story.user.username;
  }

  bool get _isMyStory {
    try {
      final controller = Get.find<ExploreController>();
      return story.user.id == controller.currentUserId.value;
    } catch (_) {
      return false;
    }
  }

  String? get _avatarUrl {
    // For own stories, use the avatar from the profile (more reliable)
    if (_isMyStory) {
      try {
        final controller = Get.find<ExploreController>();
        if (controller.avatarurl.value.isNotEmpty) {
          return controller.avatarurl.value;
        }
      } catch (_) {}
    }
    return story.user.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.toNamed(
          Routes.postscreen,
          arguments: {
            "stories": [story],
            "startIndex": 0,
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xff2D0731),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Avatar, Name ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.transparent,
                  child:
                      _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _avatarUrl!,
                              width: 40.r,
                              height: 40.r,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              placeholder:
                                  (context, url) => const ShimmerPlaceholder(),
                              errorWidget:
                                  (context, url, error) => Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                            ),
                          )
                          : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _displayName,
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            "• @${story.user.username}",
                            style: GoogleFonts.notoSans(
                              color: Colors.grey,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeago.format(story.createdAt),
                        style: GoogleFonts.notoSans(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // --- 3 Dots Menu ---
                GestureDetector(
                  onTap: () => _showPostOptionsSheet(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xff703A8B),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/Images/more_horiz.png",
                      scale: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // --- Post Image / Video ---
            ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child:
                  story.type.toLowerCase() == 'video'
                      ? _VideoThumbnailWidget(
                        videoUrl: story.mediaUrl,
                        height: 250.h,
                      )
                      : CachedNetworkImage(
                        imageUrl: story.mediaUrl,
                        height: 250.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const ShimmerPlaceholder(),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.error),
                      ),
            ),

            SizedBox(height: 12.h),

            // --- Action Buttons (Share) ---
            // Like & comment are temporarily hidden — re-enable by restoring
            // the two _buildActionIcon rows below.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // _buildActionIcon("assets/Images/like_icon.png", "0"),
                // SizedBox(width: 20.w),
                // _buildActionIcon("assets/Images/Icon-Outline-Comment.png", "0"),
                // SizedBox(width: 20.w),
                _buildActionSvgIcon("assets/svg/icons/download.svg", ""),
              ],
            ),

            SizedBox(height: 10.h),

            // --- Time ---
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionIcon(String imageUrl, String count) {
    return Row(
      children: [
        Image.asset(imageUrl, scale: 1.3),
        if (count.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Text(
            count,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionSvgIcon(String svgPath, String count) {
    return Row(
      children: [
        SvgPicture.asset(svgPath, height: 17.sp, width: 17.sp),
        if (count.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Text(
            count,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ],
      ],
    );
  }

  void _refreshProfileData() {
    try {
      final profileCtrl = Get.find<MyProfileController>();
      profileCtrl.getSavedStories();
      profileCtrl.fetchVaultStories(profileCtrl.userId);
    } catch (_) {}
  }

  void _showPostOptionsSheet() {
    final bool isMyPost = _isMyStory;

    final List<Map<String, dynamic>> options =
        isMyPost
            ? [
              {
                'label': 'Send To',
                'color': const Color(0xffC574F7),
                'onTap': () {
                  Get.back();
                  showSendToSheet(
                    "Check out my latest story on OutSpot!",
                    imageUrl: story.mediaUrl,
                  );
                },
              },
              {
                'label': 'Save to Profile',
                'color': const Color(0xffC574F7),
                'onTap': () async {
                  Get.back();
                  try {
                    final res = await ApiService.storieSaveProfile({
                      "storyId": story.id,
                    });
                    if (res.statusCode == 200) {
                      AppToast.success("Saved to Profile");
                      _refreshProfileData();
                    } else if (res.statusCode == 400) {
                      AppToast.error("Already Saved");
                    } else {
                      AppSnackbar.error("Failed: ${res.statusCode}");
                    }
                  } catch (e) {
                    AppSnackbar.error("Something went wrong: $e");
                  }
                },
              },
              {
                'label': 'Save to Vault',
                'color': const Color(0xffC574F7),
                'onTap': () async {
                  Get.back();
                  try {
                    final res = await ApiService.storieSaveVault({
                      "storyId": story.id,
                    });
                    if (res.statusCode == 200) {
                      AppToast.success("Saved to Vault");
                      _refreshProfileData();
                    } else if (res.statusCode == 400) {
                      AppToast.error("Already Saved");
                    } else {
                      AppSnackbar.error("Failed: ${res.statusCode}");
                    }
                  } catch (e) {
                    AppSnackbar.error("Something went wrong: $e");
                  }
                },
              },
              {
                'label': 'Remove Post',
                'color': Colors.red,
                'onTap': () async {
                  Get.back();
                  try {
                    final res = await ApiService.storiesRemove(story.id);
                    if (res.statusCode == 200) {
                      AppToast.success("Story Removed");
                      // Refresh feed
                      try {
                        Get.find<ExploreController>().fetchPostFeed();
                      } catch (_) {}
                    } else {
                      AppSnackbar.error("Failed: ${res.statusCode}");
                    }
                  } catch (e) {
                    AppSnackbar.error("Something went wrong: $e");
                  }
                },
              },
            ]
            : [
              {
                'label': 'Send To',
                'color': const Color(0xffC574F7),
                'onTap': () {
                  Get.back();
                  showSendToSheet(
                    "Check out $_displayName(@${story.user.username})'s story on OutSpot!",
                    imageUrl: story.mediaUrl,
                  );
                },
              },
            ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: const BoxDecoration(
          color: Color(0xff202122),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Post Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.6, color: Colors.black),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(
                      item['label'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        color: item['color'],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: item['onTap'],
                  ),
                  if (index != options.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Colors.black,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Cached video thumbnail service — generates once, caches to disk
class _ThumbnailCache {
  static final _ThumbnailCache instance = _ThumbnailCache._();
  _ThumbnailCache._();

  Directory? _cacheDir;
  final Map<String, String> _memCache = {};

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= Directory(
      '${(await getTemporaryDirectory()).path}/video_thumbs',
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
    // Check memory cache
    if (_memCache.containsKey(videoUrl)) {
      final path = _memCache[videoUrl]!;
      if (await File(path).exists()) return path;
      _memCache.remove(videoUrl);
    }

    // Check disk cache
    final dir = await _getCacheDir();
    final file = File('${dir.path}/${_urlToFileName(videoUrl)}');
    if (await file.exists()) {
      _memCache[videoUrl] = file.path;
      return file.path;
    }

    // Generate thumbnail
    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 500,
        quality: 85,
      );
      if (thumbPath != null && await File(thumbPath).exists()) {
        _memCache[videoUrl] = thumbPath;
        return thumbPath;
      }
    } catch (e) {
      debugPrint('Thumbnail error: $e');
    }
    return null;
  }

  /// Remove cached thumbnail for a specific video
  Future<void> remove(String videoUrl) async {
    _memCache.remove(videoUrl);
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/${_urlToFileName(videoUrl)}');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class _VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double height;

  const _VideoThumbnailWidget({required this.videoUrl, required this.height});

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  String? _thumbPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final path = await _ThumbnailCache.instance.getThumbnail(widget.videoUrl);
    if (mounted) {
      setState(() {
        _thumbPath = path;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black,
          child:
              _loading
                  ? const ShimmerPlaceholder()
                  : _thumbPath != null
                  ? Image.file(
                    File(_thumbPath!),
                    height: widget.height,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  )
                  : Icon(Icons.videocam, color: Colors.white54, size: 48.sp),
        ),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: const BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow, color: Colors.white, size: 32.sp),
        ),
      ],
    );
  }
}
