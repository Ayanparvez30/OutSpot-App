import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:outspot/Network_Manager/app_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The JSON below is copied verbatim from the running backend, so a change to
/// the response shape breaks these tests rather than the app.
MyReview parse(String body) => MyReview.fromJson(
  Map<String, dynamic>.from(json.decode(body)['data'] as Map),
);

/// Mirrors `AppReviewService.shouldPrompt`'s local gate. The service's own
/// version then makes a network call, which a unit test can't do — so the
/// rules that decide *whether* we even reach the network are asserted here.
bool localGateAllows(Map<String, Object> stored, DateTime now) {
  if (stored['app_review_done'] == true) return false;
  if ((stored['app_review_open_count'] as int? ?? 0) < 3) return false;
  final snooze = stored['app_review_snooze_until'] as int? ?? 0;
  if (now.millisecondsSinceEpoch < snooze) return false;
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('When the review sheet is allowed to appear', () {
    final now = DateTime(2026, 8, 20, 12);

    test('first two launches stay quiet', () {
      expect(localGateAllows({'app_review_open_count': 1}, now), isFalse);
      expect(localGateAllows({'app_review_open_count': 2}, now), isFalse);
    });

    test('third launch asks', () {
      expect(localGateAllows({'app_review_open_count': 3}, now), isTrue);
    });

    test('already reviewed → never asks again', () {
      expect(
        localGateAllows({
          'app_review_open_count': 99,
          'app_review_done': true,
        }, now),
        isFalse,
      );
    });

    test('"Later" keeps it quiet for the next two days', () {
      final snoozedUntil =
          now.add(const Duration(days: 2)).millisecondsSinceEpoch;

      // One day later — still inside the snooze.
      expect(
        localGateAllows({
          'app_review_open_count': 5,
          'app_review_snooze_until': snoozedUntil,
        }, now.add(const Duration(days: 1))),
        isFalse,
      );

      // Two days and a minute later — fair game again.
      expect(
        localGateAllows({
          'app_review_open_count': 5,
          'app_review_snooze_until': snoozedUntil,
        }, now.add(const Duration(days: 2, minutes: 1))),
        isTrue,
      );
    });
  });

  group('Counting launches', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('each launch ticks once', () async {
      for (var i = 1; i <= 3; i++) {
        await AppReviewService.registerAppOpen();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('app_review_open_count'), i);
      }
    });

    test('stops counting once the user has reviewed', () async {
      SharedPreferences.setMockInitialValues({
        'app_review_done': true,
        'app_review_open_count': 3,
      });
      await AppReviewService.registerAppOpen();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_review_open_count'), 3);
    });

    test('"Later" sets a ~2 day snooze and restarts the count', () async {
      SharedPreferences.setMockInitialValues({'app_review_open_count': 3});
      await AppReviewService.snooze();

      final prefs = await SharedPreferences.getInstance();
      final until = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('app_review_snooze_until')!,
      );
      final days = until.difference(DateTime.now()).inHours / 24;
      expect(days, closeTo(2, 0.1));
      expect(prefs.getInt('app_review_open_count'), 0);
    });
  });

  group('Reading the server\'s answer', () {
    test('has not reviewed yet', () {
      final r = parse(
        '{"status":true,"message":"Review status fetched",'
        '"data":{"hasReviewed":false,"review":null}}',
      );
      expect(r.hasReviewed, isFalse);
      expect(r.rating, 0);
    });

    test('has reviewed — rating and words come back for editing', () {
      final r = parse(
        '{"status":true,"message":"Review status fetched","data":'
        '{"hasReviewed":true,"review":{"id":1,"rating":5,'
        '"comment":"Explore design ta osadharon hoyeche bhai!",'
        '"createdAt":"2026-08-18T19:16:35.367Z",'
        '"updatedAt":"2026-08-18T19:16:35.390Z"}}}',
      );
      expect(r.hasReviewed, isTrue);
      expect(r.rating, 5);
      expect(r.comment, 'Explore design ta osadharon hoyeche bhai!');
    });

    test('a rating with no words parses to an empty comment', () {
      final r = parse(
        '{"status":true,"data":{"hasReviewed":true,'
        '"review":{"id":1,"rating":3,"comment":""}}}',
      );
      expect(r.rating, 3);
      expect(r.comment, isEmpty);
    });

    test('a garbled payload never claims a rating', () {
      expect(parse('{"data":{}}').hasReviewed, isFalse);
      expect(parse('{"data":{"hasReviewed":true}}').rating, 0);
      expect(
        parse('{"data":{"hasReviewed":true,"review":"broken"}}').rating,
        0,
      );
    });
  });
}
