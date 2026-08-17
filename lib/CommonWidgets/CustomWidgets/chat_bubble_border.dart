import 'package:flutter/material.dart';

/// WhatsApp-style chat bubble outline: a rounded rectangle with a small "tail"
/// notch at the top corner — top-left for received messages, top-right for the
/// user's own (sent) messages. Used as the `shape` of a [ShapeDecoration] so the
/// fill colour and the thin border both follow the tail.
class ChatBubbleBorder extends ShapeBorder {
  final bool isMine;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final Color borderColor;
  final double borderWidth;

  const ChatBubbleBorder({
    required this.isMine,
    required this.borderColor,
    this.radius = 10,
    this.tailWidth = 7,
    this.tailHeight = 13,
    this.borderWidth = 0.5,
  });

  // Reserve space for the tail on its side so message content never overlaps it.
  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(left: isMine ? 0 : tailWidth, right: isMine ? tailWidth : 0);

  Path _path(Rect rect) {
    final r = Radius.circular(radius);
    // Body rect = full rect minus the tail strip on the tail side.
    final body = isMine
        ? Rect.fromLTRB(rect.left, rect.top, rect.right - tailWidth, rect.bottom)
        : Rect.fromLTRB(rect.left + tailWidth, rect.top, rect.right, rect.bottom);

    // The tail-side top corner is square (0) so the tail attaches flush — like
    // WhatsApp. Other corners use the normal radius.
    final bodyPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        body,
        topLeft: isMine ? r : Radius.zero,
        topRight: isMine ? Radius.zero : r,
        bottomLeft: r,
        bottomRight: r,
      ));

    final tail = Path();
    if (isMine) {
      // Tail at top-right, pointing right.
      tail.moveTo(body.right, body.top);
      tail.lineTo(body.right + tailWidth, body.top);
      tail.lineTo(body.right, body.top + tailHeight);
      tail.close();
    } else {
      // Tail at top-left, pointing left.
      tail.moveTo(body.left, body.top);
      tail.lineTo(body.left - tailWidth, body.top);
      tail.lineTo(body.left, body.top + tailHeight);
      tail.close();
    }

    return Path.combine(PathOperation.union, bodyPath, tail);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (borderWidth <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor;
    canvas.drawPath(_path(rect), paint);
  }

  @override
  ShapeBorder scale(double t) => ChatBubbleBorder(
        isMine: isMine,
        borderColor: borderColor,
        radius: radius * t,
        tailWidth: tailWidth * t,
        tailHeight: tailHeight * t,
        borderWidth: borderWidth * t,
      );
}
