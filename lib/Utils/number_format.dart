/// Compact number formatting for points / counts shown in the UI.
///
/// Keeps small numbers exact and shortens large ones so a value like 100000
/// renders as "100k" instead of overflowing a row:
///   0      -> "0"
///   999    -> "999"
///   1000   -> "1k"
///   1500   -> "1.5k"
///   12610  -> "12.6k"
///   1000000-> "1m"
///   1e9    -> "1b"
/// Negative values keep their sign (e.g. -50 -> "-50", -1500 -> "-1.5k").
///
/// Use everywhere a points/coins value is displayed (Text widgets, dialogs,
/// snackbars) so the formatting stays consistent across the whole app.
String compactNumber(num? value) {
  final v = value ?? 0;
  final negative = v < 0;
  final n = v.abs();

  String body;
  if (n >= 1000000000) {
    body = '${_trimDecimal(n / 1000000000)}b';
  } else if (n >= 1000000) {
    body = '${_trimDecimal(n / 1000000)}m';
  } else if (n >= 1000) {
    body = '${_trimDecimal(n / 1000)}k';
  } else {
    body = n.toInt().toString();
  }
  return negative ? '-$body' : body;
}

/// One decimal place, but drop a trailing ".0" so 1.0k renders as "1k".
String _trimDecimal(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
