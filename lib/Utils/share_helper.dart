import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Shares plain [text] using the share_plus v11 API.
///
/// On iOS the system share sheet is presented as a *popover* that must be
/// anchored to a source rectangle. Without [ShareParams.sharePositionOrigin]
/// it silently fails to open on iPad (and some iPhone/iOS configurations) —
/// which is why "Share" appeared to do nothing on other iOS devices.
///
/// Passing the tapped widget's [context] lets us derive that anchor rect so the
/// sheet opens reliably everywhere. The arg is optional (Android ignores it).
Future<ShareResult> shareTextWithOrigin(String text, [BuildContext? context]) {
  Rect? origin;
  final box = context?.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  return SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
}
