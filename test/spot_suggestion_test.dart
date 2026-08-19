import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:outspot/Network_Manager/spot_suggestion_service.dart';

/// The payloads below are verbatim captures from the running backend, so a
/// change to the response shape fails here rather than on someone's phone.
MySuggestions parse(String body) => MySuggestions.fromJson(
  Map<String, dynamic>.from(json.decode(body)['data'] as Map),
);

void main() {
  group('My spot suggestions', () {
    test('nothing sent yet — the button is open', () {
      final m = parse(
        '{"status":true,"message":"Suggestions fetched","data":'
        '{"canSubmitToday":true,"pendingCount":0,"rewardPoints":50,'
        '"expiryDays":21,"suggestions":[]}}',
      );
      expect(m.canSubmitToday, isTrue);
      expect(m.suggestions, isEmpty);
      expect(m.rewardPoints, 50);
      expect(m.expiryDays, 21);
    });

    test('one sent today — the button locks until tomorrow', () {
      final m = parse(
        '{"status":true,"data":{"canSubmitToday":false,"pendingCount":1,'
        '"rewardPoints":50,"expiryDays":21,"suggestions":['
        '{"id":1,"name":"Chotto Cafe","address":"12 Boylston St",'
        '"categoryKey":"cafes","imageUrl":null,"status":"PENDING",'
        '"rejectReason":null,"createdAt":"2026-08-19T14:28:34.403Z",'
        '"reviewedAt":null}]}}',
      );
      expect(m.canSubmitToday, isFalse);
      expect(m.pendingCount, 1);

      final s = m.suggestions.single;
      expect(s.name, 'Chotto Cafe');
      expect(s.isPending, isTrue);
      expect(s.isApproved, isFalse);
      expect(s.imageUrl, isNull);
      expect(s.createdAt, isNotNull);
    });

    test('approved and rejected read back distinctly', () {
      final m = parse(
        '{"status":true,"data":{"canSubmitToday":true,"pendingCount":0,'
        '"rewardPoints":50,"expiryDays":21,"suggestions":['
        '{"id":3,"name":"Rooftop 88","status":"APPROVED","categoryKey":"bars"},'
        '{"id":2,"name":"Vua Jaiga","status":"REJECTED","categoryKey":"bars",'
        '"rejectReason":"This place is already on the map as Blue Bottle."}]}}',
      );
      expect(m.suggestions.length, 2);

      expect(m.suggestions[0].isApproved, isTrue);
      expect(m.suggestions[0].rejectReason, isEmpty);

      // The reason has to survive parsing — it is the only explanation the
      // user gets on screen.
      expect(m.suggestions[1].isRejected, isTrue);
      expect(
        m.suggestions[1].rejectReason,
        'This place is already on the map as Blue Bottle.',
      );
    });

    test('an empty photo url is treated as no photo', () {
      final m = parse(
        '{"data":{"suggestions":[{"id":1,"name":"X","imageUrl":""}]}}',
      );
      expect(m.suggestions.single.imageUrl, isNull);
    });

    test('a garbled payload degrades instead of throwing', () {
      expect(parse('{"data":{}}').suggestions, isEmpty);
      // Missing canSubmitToday must not silently lock the user out.
      expect(parse('{"data":{}}').canSubmitToday, isTrue);
      expect(parse('{"data":{"suggestions":"broken"}}').suggestions, isEmpty);
      expect(parse('{"data":{"suggestions":[{}]}}').suggestions.single.id, 0);
    });
  });

  group('Categories offered on the form', () {
    test('match the six the server accepts', () {
      expect(
        SpotSuggestionService.categories.map((c) => c.key).toList(),
        ['restaurants', 'cafes', 'bars', 'dessert', 'outdoors', 'venue-events'],
      );
    });
  });
}
