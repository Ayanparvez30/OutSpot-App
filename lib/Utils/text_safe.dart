import 'package:characters/characters.dart';

/// Helpers to keep strings safe for Flutter's text engine.
///
/// Flutter's paragraph builder throws
/// `Invalid argument(s): string is not well-formed UTF-16`
/// when a String contains an **unpaired UTF-16 surrogate**. This happens when:
///   * `substring()` cuts a string in the middle of an emoji (splits a
///     surrogate pair), or
///   * the backend stored a truncated/broken emoji.
///
/// Use [sanitizeUtf16] before handing dynamic/server text to a `Text` widget,
/// and [truncateSafe] instead of `substring(0, n)` when shortening display text.
extension SafeText on String {
  /// Drop any unpaired surrogate code units so the text engine never crashes.
  String sanitizeUtf16() {
    // Fast path: pure BMP + valid pairs is the norm — only build a new string
    // when something is actually wrong.
    var needsFix = false;
    for (var i = 0; i < length; i++) {
      final u = codeUnitAt(i);
      if (u >= 0xD800 && u <= 0xDFFF) {
        needsFix = true;
        break;
      }
    }
    if (!needsFix) return this;

    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      final u = codeUnitAt(i);
      if (u >= 0xD800 && u <= 0xDBFF) {
        // High surrogate — keep only if followed by a valid low surrogate.
        if (i + 1 < length) {
          final n = codeUnitAt(i + 1);
          if (n >= 0xDC00 && n <= 0xDFFF) {
            buf.writeCharCode(u);
            buf.writeCharCode(n);
            i++;
            continue;
          }
        }
        continue; // unpaired high → drop
      } else if (u >= 0xDC00 && u <= 0xDFFF) {
        continue; // unpaired low → drop
      }
      buf.writeCharCode(u);
    }
    return buf.toString();
  }

  /// Truncate by grapheme cluster (never splits an emoji / surrogate pair).
  /// Returns a sanitized string with [ellipsis] appended when shortened.
  String truncateSafe(int max, {String ellipsis = '…'}) {
    final safe = sanitizeUtf16();
    final chars = safe.characters;
    if (chars.length <= max) return safe;
    return '${chars.take(max)}$ellipsis';
  }
}
