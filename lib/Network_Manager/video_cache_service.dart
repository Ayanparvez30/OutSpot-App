import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:outspot/Model/story_model.dart';

/// Smart video caching service.
///
/// Strategy:
/// 1. After stories load on explore page, wait 3s (let APIs finish first)
/// 2. Check network — only cache on WiFi, or on cellular limit to 3
/// 3. Cache one video at a time with 1s gap (don't saturate network)
/// 4. Skip already-cached videos
/// 5. Pause when user opens story viewer
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._();
  static VideoCacheService get instance => _instance;
  VideoCacheService._();

  bool _isCaching = false;
  bool _shouldStop = false;
  Timer? _delayTimer;

  /// Call after stories load. Extracts video URLs and caches them.
  void cacheStoryVideos(List<StoryModel> stories) {
    // Cancel any pending delayed start
    _delayTimer?.cancel();

    // Extract video URLs now (before delay, in case list changes)
    final videoUrls = <String>[];
    for (final s in stories) {
      if (s.type.toLowerCase() == 'video' &&
          s.mediaUrl.isNotEmpty &&
          !videoUrls.contains(s.mediaUrl)) {
        videoUrls.add(s.mediaUrl);
      }
    }

    if (videoUrls.isEmpty) {
      log('[VideoCache] No videos to cache');
      return;
    }

    log('[VideoCache] Found ${videoUrls.length} videos, starting in 3s...');

    _shouldStop = false;

    // Delay to let other API calls finish
    _delayTimer = Timer(const Duration(seconds: 3), () {
      if (_shouldStop) {
        log('[VideoCache] Cancelled before start');
        return;
      }
      _startCaching(videoUrls);
    });
  }

  /// Pause caching (call when user opens story viewer)
  void pause() {
    _shouldStop = true;
    _delayTimer?.cancel();
    log('[VideoCache] Paused');
  }

  /// Check if a URL is cached. Returns local path or null.
  Future<String?> getCachedPath(String url) async {
    final info = await DefaultCacheManager().getFileFromCache(url);
    return info?.file.path;
  }

  Future<void> _startCaching(List<String> urls) async {
    if (_isCaching) {
      log('[VideoCache] Already caching, skipping');
      return;
    }
    _isCaching = true;

    // Check network
    final connectivity = await Connectivity().checkConnectivity();
    final isWifi = connectivity.contains(ConnectivityResult.wifi);
    final isCellular = connectivity.contains(ConnectivityResult.mobile);

    if (!isWifi && !isCellular) {
      log('[VideoCache] No network');
      _isCaching = false;
      return;
    }

    final limit = isWifi ? urls.length : 3;
    log('[VideoCache] ${isWifi ? "WiFi" : "Cellular"} — caching up to $limit');

    int cached = 0;
    for (int i = 0; i < urls.length && i < limit; i++) {
      if (_shouldStop) {
        log('[VideoCache] Stopped at $i');
        break;
      }

      final url = urls[i];

      // Skip if already cached
      final existing = await DefaultCacheManager().getFileFromCache(url);
      if (existing != null) {
        log('[VideoCache] ${i + 1}/$limit already cached');
        continue;
      }

      try {
        log('[VideoCache] Downloading ${i + 1}/$limit...');
        await DefaultCacheManager().getSingleFile(url);
        cached++;
        log('[VideoCache] Done ${i + 1}/$limit ($cached downloaded)');

        // 1s gap between downloads
        if (!_shouldStop && i < limit - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        log('[VideoCache] Failed ${i + 1}: $e');
      }
    }

    _isCaching = false;
    log('[VideoCache] Finished. Downloaded $cached new videos.');
  }
}
