import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_icons.dart';

import 'api_constains.dart';
import 'user_preference.dart';

/// One spot a user has sent in, as the server tells it back to them.
class SpotSuggestion {
  final int id;
  final String name;
  final String address;
  final String categoryKey;
  final String? imageUrl;

  /// PENDING | APPROVED | REJECTED
  final String status;

  /// Why an admin turned it down. Only set when [status] is REJECTED.
  final String rejectReason;
  final DateTime? createdAt;

  const SpotSuggestion({
    required this.id,
    required this.name,
    this.address = '',
    this.categoryKey = '',
    this.imageUrl,
    this.status = 'PENDING',
    this.rejectReason = '',
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory SpotSuggestion.fromJson(Map<String, dynamic> json) {
    return SpotSuggestion(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      categoryKey: (json['categoryKey'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString().isEmpty
          ? null
          : json['imageUrl'].toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      rejectReason: (json['rejectReason'] ?? '').toString(),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }
}

/// Everything the "my suggestions" screen shows at once.
class MySuggestions {
  final bool canSubmitToday;
  final int pendingCount;
  final int rewardPoints;
  final int expiryDays;
  final List<SpotSuggestion> suggestions;

  const MySuggestions({
    this.canSubmitToday = true,
    this.pendingCount = 0,
    this.rewardPoints = 50,
    this.expiryDays = 21,
    this.suggestions = const [],
  });

  factory MySuggestions.fromJson(Map<String, dynamic> json) {
    final list = json['suggestions'];
    return MySuggestions(
      canSubmitToday: json['canSubmitToday'] != false,
      pendingCount: int.tryParse('${json['pendingCount']}') ?? 0,
      rewardPoints: int.tryParse('${json['rewardPoints']}') ?? 50,
      expiryDays: int.tryParse('${json['expiryDays']}') ?? 21,
      suggestions: list is List
          ? list
              .whereType<Map>()
              .map((e) => SpotSuggestion.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// The result of trying to send a spot in — the message is written for the
/// user, so it can be shown as-is either way.
class SubmitResult {
  final bool ok;
  final String message;
  const SubmitResult(this.ok, this.message);
}

/// Suggesting a place OutSpot doesn't know about.
///
/// The user has to be standing at it: the coordinates are read from the device
/// at the moment they submit and sent alongside, and the server refuses a spot
/// pinned far from where the phone says the person is.
class SpotSuggestionService {
  /// What the categories are called on the submit form, with the same Figma
  /// glyph Explore's own filter pills use — so a category reads the same
  /// wherever the user meets it. Keys must match the server's
  /// `VALID_CATEGORIES`.
  static const List<({String key, String label, String icon})> categories = [
    (key: 'restaurants', label: 'Restaurants', icon: ExploreIcons.pillRestaurants),
    (key: 'cafes', label: 'Cafes', icon: ExploreIcons.pillCafes),
    (key: 'bars', label: 'Bars', icon: ExploreIcons.pillBars),
    (key: 'dessert', label: 'Dessert', icon: ExploreIcons.pillDessert),
    (key: 'outdoors', label: 'Outdoors', icon: ExploreIcons.pillOutdoors),
    (key: 'venue-events', label: 'Venue Events', icon: ExploreIcons.pillVenueEvents),
  ];

  static Future<Map<String, String>> _headers() async {
    final token = (await UserPreference.getToken())?.trim();
    return {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  /// Sends a spot in. [imageFile] is optional — a submission without a photo is
  /// still worth having, and the admin can judge it from the rest.
  static Future<SubmitResult> submit({
    required String name,
    required String categoryKey,
    required double latitude,
    required double longitude,
    String address = '',
    String note = '',
    File? imageFile,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.suggestSpot}',
      );
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(await _headers())
        ..fields['name'] = name
        ..fields['categoryKey'] = categoryKey
        ..fields['latitude'] = '$latitude'
        ..fields['longitude'] = '$longitude'
        // Sent so the server can check the pin is near the phone. Same values
        // here because the pin *is* where the phone is — a future "adjust the
        // pin" step would make them differ.
        ..fields['userLatitude'] = '$latitude'
        ..fields['userLongitude'] = '$longitude';

      if (address.trim().isNotEmpty) request.fields['address'] = address.trim();
      if (note.trim().isNotEmpty) request.fields['note'] = note.trim();

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      // Generous: a photo upload over a phone connection is the slow part.
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final body = json.decode(response.body);

      if (body is Map && body['status'] == true) {
        return SubmitResult(
          true,
          (body['message'] ?? 'Thanks! We\'ll review your spot soon.').toString(),
        );
      }
      return SubmitResult(
        false,
        (body is Map ? body['message'] : null)?.toString() ??
            'Could not send your spot. Please try again.',
      );
    } catch (e) {
      log('❌ Spot suggestion submit failed: $e');
      return const SubmitResult(
        false,
        'Could not send your spot. Check your connection and try again.',
      );
    }
  }

  /// This user's own submissions, newest first. Null when the server couldn't
  /// be reached — distinct from an empty list, which means "none yet".
  static Future<MySuggestions?> fetchMine() async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.mySpotSuggestions}',
      );
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final body = json.decode(response.body);
      if (body is! Map || body['status'] != true) return null;
      final data = body['data'];
      if (data is! Map) return null;
      return MySuggestions.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      log('⚠️ Could not load my spot suggestions: $e');
      return null;
    }
  }
}
