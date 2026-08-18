import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_constains.dart';
import 'api_provider.dart';

/// In-app reviews: when to ask, and talking to the server about it.
///
/// The *when* is entirely local — counting launches and remembering a "Later"
/// tap is per-install UI state that the server has no reason to carry. The one
/// thing only the server knows is whether this account already reviewed from
/// some other phone or a previous install, and that is asked exactly once, and
/// only after every cheap local check has already passed.
class AppReviewService {
  /// Ask on the third launch — early enough to still matter, late enough that
  /// the person has actually seen the app.
  static const int _opensBeforeAsking = 3;

  /// "Later" buys two days of quiet.
  static const int _snoozeDays = 2;

  static const String _kOpenCount = 'app_review_open_count';
  static const String _kSnoozeUntil = 'app_review_snooze_until';
  static const String _kDone = 'app_review_done';

  /// Guards against a second prompt in the same run. The Explore controller is
  /// registered with `fenix: true`, so switching tabs disposes and recreates
  /// it — without this, coming back to Explore would ask again.
  static bool _askedThisSession = false;

  /// Counts one app launch. Called from the splash screen, which runs exactly
  /// once per cold start — counting inside Explore would tick on every tab
  /// switch instead.
  static Future<void> registerAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kDone) == true) return; // no point counting further
      final count = (prefs.getInt(_kOpenCount) ?? 0) + 1;
      await prefs.setInt(_kOpenCount, count);
    } catch (e) {
      log('⚠️ Could not count app open for review prompt: $e');
    }
  }

  /// Whether Explore should raise the review sheet right now.
  ///
  /// Every failure resolves to false. Not asking is a missed review; asking
  /// wrongly is a person being pestered after they already reviewed.
  static Future<bool> shouldPrompt() async {
    try {
      if (_askedThisSession) return false;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kDone) == true) return false;

      if ((prefs.getInt(_kOpenCount) ?? 0) < _opensBeforeAsking) return false;

      final snoozeUntil = prefs.getInt(_kSnoozeUntil) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < snoozeUntil) return false;

      // Only now is the network worth spending: this account may have reviewed
      // from another device, in which case we must never ask again.
      final existing = await fetchMyReview();
      if (existing == null) return false; // couldn't tell → stay quiet
      if (existing.hasReviewed) {
        await prefs.setBool(_kDone, true);
        return false;
      }

      _askedThisSession = true;
      return true;
    } catch (e) {
      log('⚠️ Review prompt check failed: $e');
      return false;
    }
  }

  /// Marks the prompt as handled for this run, whichever way it was dismissed.
  static void markAskedThisSession() => _askedThisSession = true;

  /// "Later" — go quiet for [_snoozeDays], then ask once more.
  static Future<void> snooze() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = DateTime.now().add(const Duration(days: _snoozeDays));
      await prefs.setInt(_kSnoozeUntil, until.millisecondsSinceEpoch);
      // Restart the count so the next ask is spaced by opens as well as days.
      await prefs.setInt(_kOpenCount, 0);
    } catch (e) {
      log('⚠️ Could not snooze the review prompt: $e');
    }
  }

  /// Reads this user's review, or null when the server couldn't be reached.
  ///
  /// Null means "don't know" and is deliberately distinct from a review of
  /// null inside a successful response, which means "hasn't reviewed yet".
  static Future<MyReview?> fetchMyReview() async {
    try {
      final response = await ApiProvider.authGet(
        endpoint: ApiConstants.myReview,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final body = json.decode(response.body);
      if (body is! Map || body['status'] != true) return null;

      final data = body['data'];
      if (data is! Map) return null;
      return MyReview.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      log('⚠️ Could not fetch review status: $e');
      return null;
    }
  }

  /// Saves (or edits) the review. Returns true when the server accepted it.
  static Future<bool> submit({required int rating, String comment = ''}) async {
    try {
      final response = await ApiProvider.authPost(
        endpoint: ApiConstants.submitReview,
        body: {'rating': rating, 'comment': comment},
      ).timeout(const Duration(seconds: 15));

      final body = json.decode(response.body);
      final ok = response.statusCode == 200 && body is Map && body['status'] == true;
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kDone, true);
      }
      return ok;
    } catch (e) {
      log('❌ Could not submit review: $e');
      return false;
    }
  }
}

/// This user's own review, as the server sees it.
class MyReview {
  final bool hasReviewed;
  final int rating;
  final String comment;

  const MyReview({
    required this.hasReviewed,
    this.rating = 0,
    this.comment = '',
  });

  factory MyReview.fromJson(Map<String, dynamic> json) {
    final review = json['review'];
    return MyReview(
      hasReviewed: json['hasReviewed'] == true,
      rating: review is Map ? (int.tryParse('${review['rating']}') ?? 0) : 0,
      comment: review is Map ? (review['comment'] ?? '').toString() : '',
    );
  }
}
