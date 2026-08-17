import 'dart:convert';

/// In-app "shared map location" chat message encoding.
///
/// A location shared into chat is sent as normal, human-readable text (name /
/// address / rating) with a hidden, machine-readable token appended. The chat
/// UI detects the token, hides it from the visible bubble, and lets the user
/// tap the message to reopen the place on the map.
///
/// The token is base64 so it never collides with the human text and introduces
/// no stray newlines. It always sits at the very end of the message.
class SharedLocation {
  final String placeId;
  final double lat;
  final double lng;
  final String name;

  const SharedLocation({
    required this.placeId,
    required this.lat,
    required this.lng,
    required this.name,
  });

  // Sentinel separating the visible text from the hidden payload.
  static const String _marker = '\n\nOSLOC::';

  /// Builds a chat message: [displayText] followed by the hidden location token.
  static String encode({
    required String displayText,
    required String placeId,
    required double lat,
    required double lng,
    required String name,
  }) {
    final payload = base64Url.encode(
      utf8.encode(
        jsonEncode({'id': placeId, 'lat': lat, 'lng': lng, 'name': name}),
      ),
    );
    return '$displayText$_marker$payload';
  }

  /// Returns the embedded location if [content] carries a token, else null.
  static SharedLocation? tryParse(String content) {
    final idx = content.indexOf(_marker);
    if (idx < 0) return null;
    try {
      final payload = content.substring(idx + _marker.length).trim();
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (decoded is! Map) return null;
      final lat = (decoded['lat'] as num?)?.toDouble();
      final lng = (decoded['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return SharedLocation(
        placeId: decoded['id']?.toString() ?? '',
        lat: lat,
        lng: lng,
        name: decoded['name']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// The visible text with the hidden token removed.
  static String stripDisplay(String content) {
    final idx = content.indexOf(_marker);
    return idx < 0 ? content : content.substring(0, idx).trimRight();
  }
}
