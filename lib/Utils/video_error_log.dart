import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Reports a video playback/transcode failure to Crashlytics as a NON-FATAL
/// error, with context, so we can debug device-specific issues (e.g. video not
/// playing on iPhone 14) remotely — Crashlytics auto-attaches the device model
/// and OS version, so failures from any tester show up in the console.
Future<void> logVideoError(
  String where,
  Object error, {
  String? url,
  StackTrace? stack,
}) async {
  log('🎥❌ [$where] video error: $error  url=$url');
  try {
    final c = FirebaseCrashlytics.instance;
    await c.setCustomKey('video_context', where);
    if (url != null) await c.setCustomKey('video_url', url);
    await c.recordError(
      error,
      stack,
      reason: 'Video failed: $where',
      fatal: false,
    );
  } catch (_) {
    // Never let logging crash the app.
  }
}
