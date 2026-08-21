import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:outspot/Model/redesign/spot_card_model.dart';

/// Builds a card the way the server actually sends one.
SpotCardModel card({
  required bool youVisited,
  required List<String> friends,
  String? yourAvatar = 'https://s3/me.png',
}) {
  return SpotCardModel.fromJson(
    json.decode(
      json.encode({
        'placeId': 'p1',
        'name': 'Blank Street',
        'points': 10,
        'youVisited': youVisited,
        'yourAvatar': yourAvatar,
        'friendsCount': friends.length,
        'friendsPreview': [
          for (final f in friends) {'id': 1, 'username': f, 'name': f},
        ],
      }),
    ) as Map<String, dynamic>,
  );
}

void main() {
  group('Who has been here', () {
    test('nobody — the invitation still reads as before', () {
      expect(
        card(youVisited: false, friends: []).friendsLabel,
        'Be the first of your friends to be spotted here!',
      );
    });

    test('only me — this is the case that was wrong', () {
      // The bug: the server counts friends only, so a place this person had
      // checked into ten times still told them to be the first.
      expect(
        card(youVisited: true, friends: []).friendsLabel,
        'You visited here',
      );
    });

    test('me and one friend — I lead', () {
      expect(
        card(youVisited: true, friends: ['SamR7']).friendsLabel,
        'You and SamR7 were spotted here',
      );
    });

    test('me and several friends — the count excludes me', () {
      // friendsCount is friends only, so "You and 3 others" with three friends
      // is right; adding one would double-count the reader.
      expect(
        card(youVisited: true, friends: ['SamR7', 'Mikeyy23', 'Lola']).friendsLabel,
        'You and 3 others were spotted here',
      );
    });

    test('friends only — unchanged from before', () {
      expect(
        card(youVisited: false, friends: ['SamR7']).friendsLabel,
        'SamR7 was spotted here',
      );
      expect(
        card(youVisited: false, friends: ['SamR7', 'Mikeyy23']).friendsLabel,
        'SamR7 and 1 other were spotted here',
      );
      expect(
        card(youVisited: false, friends: ['SamR7', 'Mikeyy23', 'Lola']).friendsLabel,
        'SamR7 and 2 others were spotted here',
      );
    });

    test('my own face leads the avatar row when I have been here', () {
      final c = card(youVisited: true, friends: ['SamR7', 'Mikeyy23']);
      // What the card actually draws: mine first, then friends in order.
      final row = <String?>[
        if (c.youVisited) c.yourAvatar,
        ...c.friends.map((f) => f.avatar),
      ];
      expect(row.first, 'https://s3/me.png');
      expect(row.length, 3);
    });

    test('no face of mine on a place I have not been to', () {
      final c = card(youVisited: false, friends: ['SamR7']);
      final row = <String?>[
        if (c.youVisited) c.yourAvatar,
        ...c.friends.map((f) => f.avatar),
      ];
      expect(row.length, 1, reason: 'friends only');
    });

    test('an older server that sends no youVisited behaves as before', () {
      final legacy = SpotCardModel.fromJson({
        'placeId': 'p1',
        'name': 'Blank Street',
        'friendsCount': 0,
        'friendsPreview': const [],
      });
      expect(legacy.youVisited, isFalse);
      expect(
        legacy.friendsLabel,
        'Be the first of your friends to be spotted here!',
      );
    });
  });
}
