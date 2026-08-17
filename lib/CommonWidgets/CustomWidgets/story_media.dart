import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// True when the media is a video (by story type or file extension).
bool isVideoMedia(String url, [String? type]) {
  if ((type ?? '').toUpperCase() == 'VIDEO') return true;
  final u = url.toLowerCase().split('?').first;
  return u.endsWith('.mp4') ||
      u.endsWith('.mov') ||
      u.endsWith('.webm') ||
      u.endsWith('.mkv') ||
      u.endsWith('.avi') ||
      u.endsWith('.m4v');
}

/// Grid thumbnail for a saved story. Images load via CachedNetworkImage; videos
/// show a dark cell with a play icon (so a video URL never renders as a broken
/// image). Falls back to a neutral box if an image fails to load.
class StoryGridThumb extends StatelessWidget {
  final String url;
  final String? type;
  const StoryGridThumb({super.key, required this.url, this.type});

  @override
  Widget build(BuildContext context) {
    final video = isVideoMedia(url, type);
    final isNetwork = Uri.tryParse(url)?.isAbsolute ?? false;

    if (video) {
      return _VideoGridThumb(url: url);
    }

    if (!isNetwork) {
      return Container(color: Colors.black26);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.black26),
      errorWidget: (_, __, ___) => Container(color: Colors.black26),
    );
  }
}

/// Grid cell for a VIDEO story: generates a real frame thumbnail (cached in
/// memory + on disk) instead of a blank black box. Shows a play overlay on top.
class _VideoGridThumb extends StatefulWidget {
  final String url;
  const _VideoGridThumb({required this.url});

  @override
  State<_VideoGridThumb> createState() => _VideoGridThumbState();
}

class _VideoGridThumbState extends State<_VideoGridThumb> {
  String? _thumbPath;
  bool _loading = true;

  // Shared across all grid cells for the app's lifetime so a thumbnail is only
  // generated once per video url.
  static final Map<String, String> _cache = {};
  static Directory? _cacheDir;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  @override
  void didUpdateWidget(covariant _VideoGridThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _thumbPath = null;
      _loading = true;
      _loadThumb();
    }
  }

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= Directory(
      '${(await getTemporaryDirectory()).path}/story_grid_thumbs',
    );
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<void> _loadThumb() async {
    final url = widget.url;
    if (url.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Memory cache
    final cached = _cache[url];
    if (cached != null && await File(cached).exists()) {
      if (mounted) {
        setState(() {
          _thumbPath = cached;
          _loading = false;
        });
      }
      return;
    }
    _cache.remove(url);

    // Disk cache (predictable name so it survives app restarts)
    final dir = await _getCacheDir();
    final hash = url.hashCode.toRadixString(16);
    final file = File('${dir.path}/$hash.jpg');
    if (await file.exists()) {
      _cache[url] = file.path;
      if (mounted) {
        setState(() {
          _thumbPath = file.path;
          _loading = false;
        });
      }
      return;
    }

    // Generate
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: url,
        thumbnailPath: file.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );
      if (path != null && await File(path).exists()) {
        _cache[url] = path;
        if (mounted) {
          setState(() {
            _thumbPath = path;
            _loading = false;
          });
        }
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_thumbPath != null)
          Image.file(File(_thumbPath!), fit: BoxFit.cover)
        else
          Container(color: Colors.black),
        if (_loading && _thumbPath == null)
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
          )
        else
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 30,
            ),
          ),
      ],
    );
  }
}

/// Full-screen viewer for a saved story — plays videos, shows images.
/// Pass [onDelete] to add a delete action in the app bar.
class StoryViewerScreen extends StatefulWidget {
  final String url;
  final String? type;
  final VoidCallback? onDelete;
  const StoryViewerScreen({
    super.key,
    required this.url,
    this.type,
    this.onDelete,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  VideoPlayerController? _video;
  bool _videoReady = false;

  bool get _isVideo => isVideoMedia(widget.url, widget.type);

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
          _video
            ?..setLooping(true)
            ..play();
        });
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          color: Colors.white,
          onPressed: () => Get.back(),
          icon: SvgPicture.asset(
            "assets/svg/icons/back_icon.svg",
            width: 25.r,
            height: 25.r,
          ),
          padding: EdgeInsets.all(8.w),
          constraints: const BoxConstraints(),
        ),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: widget.onDelete,
            ),
        ],
      ),
      body: Center(
        child:
            _isVideo
                ? (_videoReady && _video != null
                    ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _video!.value.isPlaying
                              ? _video!.pause()
                              : _video!.play();
                        });
                      },
                      child: AspectRatio(
                        aspectRatio: _video!.value.aspectRatio,
                        child: VideoPlayer(_video!),
                      ),
                    )
                    : const CircularProgressIndicator(color: Colors.white))
                : InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: widget.url,
                    fit: BoxFit.contain,
                    placeholder:
                        (_, __) => const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                    errorWidget:
                        (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 50,
                        ),
                  ),
                ),
      ),
    );
  }
}
