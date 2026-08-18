import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'api_constains.dart';

/// The server's answer to "is this build still allowed to run?".
class AppVersionStatus {
  /// The one field the app acts on: block the user until they update.
  final bool updateRequired;

  /// A newer build exists but the user isn't forced onto it. Kept for a
  /// future soft prompt — nothing blocks on this today.
  final bool updateAvailable;

  /// What to show the user, straight from the admin panel. May be empty.
  final String message;

  /// Where "Update Now" sends them. Guaranteed non-empty whenever
  /// [updateRequired] is true, because the server refuses to force an update
  /// for a platform whose store link is blank.
  final String storeUrl;

  const AppVersionStatus({
    this.updateRequired = false,
    this.updateAvailable = false,
    this.message = '',
    this.storeUrl = '',
  });

  /// The answer used whenever we can't get a real one — never blocks.
  static const AppVersionStatus allowed = AppVersionStatus();

  factory AppVersionStatus.fromJson(Map<String, dynamic> json) {
    final url = (json['storeUrl'] ?? '').toString().trim();
    final required = json['updateRequired'] == true;
    return AppVersionStatus(
      // Belt and braces: even if the server ever said "required" with no
      // link, we refuse to trap the user on a screen with a dead button.
      updateRequired: required && url.isNotEmpty,
      updateAvailable: json['updateAvailable'] == true,
      message: (json['message'] ?? '').toString(),
      storeUrl: url,
    );
  }
}

/// Force-update check.
///
/// Compares the build number baked into this binary (the `+16` of
/// `version: 1.0.0+16`) against the minimum the admin panel has published.
/// The endpoint is public — it has to answer before the user logs in, since a
/// blocked user may never reach a screen where they could authenticate.
class AppVersionService {
  /// Every failure mode — offline, timeout, 500, unparseable body — resolves
  /// to [AppVersionStatus.allowed]. A version check must never be the reason
  /// the app won't open.
  static Future<AppVersionStatus> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber);
      if (build == null) {
        log('⚠️ Version check: unreadable build "${info.buildNumber}"');
        return AppVersionStatus.allowed;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.appVersion}',
      ).replace(queryParameters: {'platform': platform, 'build': '$build'});

      // Short timeout on purpose: this sits in front of the splash screen, so
      // a slow server should cost the user a few seconds, not the launch.
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        log('⚠️ Version check: HTTP ${response.statusCode}');
        return AppVersionStatus.allowed;
      }

      final body = json.decode(response.body);
      if (body is! Map<String, dynamic>) return AppVersionStatus.allowed;

      final status = AppVersionStatus.fromJson(body);
      log(
        'ℹ️ Version check: build $build on $platform → '
        'updateRequired=${status.updateRequired}',
      );
      return status;
    } catch (e) {
      log('⚠️ Version check failed (allowing app to open): $e');
      return AppVersionStatus.allowed;
    }
  }
}
