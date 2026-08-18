import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:outspot/Network_Manager/app_version_service.dart';

/// The bodies below are verbatim captures from the backend running the
/// `AppVersionSetting` policy — not hand-written approximations. Each one is a
/// scenario the admin panel can actually produce.
AppVersionStatus parse(String body) =>
    AppVersionStatus.fromJson(json.decode(body) as Map<String, dynamic>);

void main() {
  group('Force update — what the app does with the server\'s answer', () {
    test('no policy configured → app opens normally', () {
      final s = parse(
        '{"success":true,"configured":false,"updateRequired":false,'
        '"forceUpdate":false}',
      );
      expect(s.updateRequired, isFalse);
    });

    test('force on, Android link set, build below minimum → blocked', () {
      final s = parse(
        '{"success":true,"configured":true,"minBuild":17,"latestBuild":17,'
        '"updateRequired":true,"updateAvailable":true,"forceUpdate":true,'
        '"message":"New Explore design is here.",'
        '"storeUrl":"https://play.google.com/store/apps/details?id=com.outspot.app"}',
      );
      expect(s.updateRequired, isTrue);
      expect(s.storeUrl, isNotEmpty);
      expect(s.message, 'New Explore design is here.');
    });

    test('same policy on iOS, where the store link is blank → not blocked', () {
      // The safety valve: forcing an update with nowhere to send the user
      // would brick the app for that platform.
      final s = parse(
        '{"success":true,"configured":true,"minBuild":17,"latestBuild":17,'
        '"updateRequired":false,"updateAvailable":true,"forceUpdate":false,'
        '"message":"New Explore design is here.","storeUrl":""}',
      );
      expect(s.updateRequired, isFalse);
    });

    test('build equals the minimum → not blocked', () {
      final s = parse(
        '{"success":true,"configured":true,"minBuild":16,"latestBuild":18,'
        '"updateRequired":false,"updateAvailable":true,"forceUpdate":true,'
        '"message":"",'
        '"storeUrl":"https://play.google.com/store/apps/details?id=com.outspot.app"}',
      );
      expect(s.updateRequired, isFalse);
      // A newer build exists, but nothing forces it today.
      expect(s.updateAvailable, isTrue);
    });

    test('force on with no store link at all → not blocked', () {
      final s = parse(
        '{"success":true,"configured":true,"minBuild":17,"latestBuild":17,'
        '"updateRequired":false,"updateAvailable":true,"forceUpdate":false,'
        '"message":"","storeUrl":""}',
      );
      expect(s.updateRequired, isFalse);
    });

    test('a server that contradicts itself cannot trap the user', () {
      // Defence in depth: even if updateRequired ever arrived true with an
      // empty link, the update button would go nowhere — so we refuse.
      final s = parse(
        '{"success":true,"configured":true,"updateRequired":true,'
        '"forceUpdate":true,"storeUrl":""}',
      );
      expect(s.updateRequired, isFalse);
    });

    test('a broken/garbage payload never blocks', () {
      expect(parse('{}').updateRequired, isFalse);
      expect(parse('{"updateRequired":"yes"}').updateRequired, isFalse);
      expect(parse('{"updateRequired":null}').updateRequired, isFalse);
    });

    test('the fallback used on every network failure allows the app', () {
      expect(AppVersionStatus.allowed.updateRequired, isFalse);
      expect(AppVersionStatus.allowed.storeUrl, isEmpty);
    });
  });
}
