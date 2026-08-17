import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_state.dart';

class DrawEditorPanel extends StatefulWidget {
  final List<DrawPath> paths;
  final Function(DrawPath) onAddPath;
  final VoidCallback onUndo;
  final VoidCallback onClose;
  final VoidCallback? onClearAll;

  const DrawEditorPanel({
    super.key,
    required this.paths,
    required this.onAddPath,
    required this.onUndo,
    required this.onClose,
    this.onClearAll,
  });

  @override
  State<DrawEditorPanel> createState() => DrawEditorPanelState();
}

class DrawEditorPanelState extends State<DrawEditorPanel>
    with SingleTickerProviderStateMixin {
  double _strokeWidth = 4.0;
  double _opacity = 1.0;
  Color _selectedColor = Colors.white;
  BrushType _brushType = BrushType.pen;
  bool _collapsed = false;

  static const List<Color> _colors = [
    Colors.white,
    Colors.black,
    Color(0xFFFF0000),
    Color(0xFFFF6600),
    Color(0xFFFFDD00),
    Color(0xFF00CC44),
    Color(0xFF0088FF),
    Color(0xFF8844FF),
    Color(0xFFFF44AA),
    Color(0xFF00DDDD),
    Color(0xFFFF8888),
    Color(0xFF88FF88),
    Color(0xFF8888FF),
    Color(0xFFFFAA00),
  ];

  Color get currentColor => _selectedColor.withOpacity(_opacity);
  double get currentStrokeWidth => _strokeWidth;
  double get currentOpacity => _opacity;
  BrushType get currentBrushType => _brushType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: _collapsed ? 6.h : 10.h),
      decoration: BoxDecoration(
        color: const Color(0xF0111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tap to collapse/expand
            GestureDetector(
              onTap: () => setState(() => _collapsed = !_collapsed),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Center(
                    child: Icon(
                      _collapsed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38,
                      size: 22.sp,
                    ),
                  ),
                  // Header: title + Undo/Clear + Done
                  Row(
                    children: [
                      Text('Draw',
                          style: GoogleFonts.notoSans(
                              color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onUndo,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.undo_rounded, color: Colors.white70, size: 20.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: widget.onClearAll,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 20.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Text('Done',
                            style: GoogleFonts.notoSans(
                                color: const Color(0xFFAB50F6), fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Collapsible tools section
            if (!_collapsed) ...[
              SizedBox(height: 12.h),

              // Brush type selector
              _buildBrushTypeSelector(),
              SizedBox(height: 14.h),

              // Brush preview
              _buildBrushPreview(),
              SizedBox(height: 14.h),

              // Size slider
              _buildSliderRow(
                icon: Icons.line_weight_rounded,
                label: '${_strokeWidth.round()}',
                value: _strokeWidth,
                min: 1,
                max: 40,
                onChanged: (v) => setState(() => _strokeWidth = v),
              ),
              SizedBox(height: 6.h),

              // Opacity slider
              _buildSliderRow(
                icon: Icons.opacity_rounded,
                label: '${(_opacity * 100).round()}%',
                value: _opacity,
                min: 0.05,
                max: 1.0,
                onChanged: (v) => setState(() => _opacity = v),
              ),
              SizedBox(height: 12.h),

              // Color picker
              _buildColorPicker(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrushTypeSelector() {
    return SizedBox(
      height: 56.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: BrushType.values.map((type) {
          final selected = type == _brushType;
          return GestureDetector(
            onTap: () => setState(() => _brushType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFAB50F6).withOpacity(0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: selected ? const Color(0xFFAB50F6) : Colors.white12,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _brushIcon(type),
                    color: selected ? const Color(0xFFAB50F6) : Colors.white54,
                    size: 20.sp,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _brushLabel(type),
                    style: GoogleFonts.notoSans(
                      color: selected ? const Color(0xFFAB50F6) : Colors.white54,
                      fontSize: 9.sp,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBrushPreview() {
    return Container(
      height: 50.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: CustomPaint(
        painter: _BrushPreviewPainter(
          color: _selectedColor,
          strokeWidth: _strokeWidth,
          opacity: _opacity,
          brushType: _brushType,
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
              activeTrackColor: const Color(0xFFAB50F6),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 38.w,
          child: Text(label,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 11.sp)),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, __) => SizedBox(width: 7.w),
        itemBuilder: (_, i) {
          final c = _colors[i];
          final selected = c.value == _selectedColor.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: selected ? 34.r : 30.r,
              height: selected ? 34.r : 30.r,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: _contrastColor(c),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Color _contrastColor(Color c) {
    return c.computeLuminance() > 0.5 ? Colors.black54 : Colors.white;
  }

  IconData _brushIcon(BrushType type) {
    switch (type) {
      case BrushType.pen:
        return Icons.edit_rounded;
      case BrushType.marker:
        return Icons.brush_rounded;
      case BrushType.neon:
        return Icons.auto_awesome;
      case BrushType.highlighter:
        return Icons.highlight_rounded;
      case BrushType.eraser:
        return Icons.auto_fix_normal_rounded;
    }
  }

  String _brushLabel(BrushType type) {
    switch (type) {
      case BrushType.pen:
        return 'Pen';
      case BrushType.marker:
        return 'Marker';
      case BrushType.neon:
        return 'Neon';
      case BrushType.highlighter:
        return 'Highlight';
      case BrushType.eraser:
        return 'Eraser';
    }
  }
}

// Preview painter showing a sample stroke
class _BrushPreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double opacity;
  final BrushType brushType;

  _BrushPreviewPainter({
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.brushType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _buildPaint(color.withOpacity(opacity), strokeWidth, brushType);

    // Draw a smooth wave preview
    final path = Path();
    final midY = size.height / 2;
    final startX = 20.0;
    final endX = size.width - 20;
    final amplitude = size.height * 0.25;

    path.moveTo(startX, midY);
    for (double x = startX; x <= endX; x += 1) {
      final t = (x - startX) / (endX - startX);
      final y = midY + sin(t * pi * 3) * amplitude * (0.3 + t * 0.7);
      path.lineTo(x, y);
    }

    if (brushType == BrushType.neon) {
      // Glow layer
      final glowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.3)
        ..strokeWidth = strokeWidth * 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BrushPreviewPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.opacity != opacity ||
      old.brushType != brushType;
}

// Main drawing painter — used on the canvas
class DrawingPainter extends CustomPainter {
  final List<DrawPath> paths;
  final List<Offset>? currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final double currentOpacity;
  final BrushType currentBrushType;

  DrawingPainter({
    required this.paths,
    this.currentPoints,
    this.currentColor = Colors.white,
    this.currentStrokeWidth = 4.0,
    this.currentOpacity = 1.0,
    this.currentBrushType = BrushType.pen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Wrap everything in a single saveLayer so eraser (BlendMode.clear)
    // can erase strokes drawn earlier in the same layer.
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw completed paths
    for (final dp in paths) {
      if (dp.points.length < 2) continue;
      final double safeOpacity = (dp.opacity as double?) ?? 1.0;
      final BrushType safeBrush = (dp.brushType as BrushType?) ?? BrushType.pen;
      _drawStroke(canvas, dp.points, dp.color.withValues(alpha: safeOpacity),
          dp.strokeWidth, safeBrush);
    }

    // Draw current path
    if (currentPoints != null && currentPoints!.length >= 2) {
      _drawStroke(canvas, currentPoints!, currentColor.withValues(alpha: currentOpacity),
          currentStrokeWidth, currentBrushType);
    }

    canvas.restore();
  }

  void _drawStroke(
      Canvas canvas, List<Offset> points, Color color, double width, BrushType type) {
    final path = _buildSmoothPath(points);

    if (type == BrushType.eraser) {
      final paint = Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.clear;
      canvas.drawPath(path, paint);
      return;
    }

    if (type == BrushType.neon) {
      // Outer glow
      final glowPaint = Paint()
        ..color = color.withOpacity((color.opacity * 0.25).clamp(0.0, 1.0))
        ..strokeWidth = width * 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, glowPaint);

      // Inner glow
      final innerGlow = Paint()
        ..color = color.withOpacity((color.opacity * 0.5).clamp(0.0, 1.0))
        ..strokeWidth = width * 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, innerGlow);
    }

    final paint = _buildPaint(color, width, type);
    canvas.drawPath(path, paint);
  }

  // Smooth Bezier path from points
  Path _buildSmoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 1) return path;
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Catmull-Rom to Bezier for smooth curves
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

Paint _buildPaint(Color color, double width, BrushType type) {
  final paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  switch (type) {
    case BrushType.pen:
      paint
        ..color = color
        ..strokeWidth = width;
      break;
    case BrushType.marker:
      paint
        ..color = color
        ..strokeWidth = width * 1.5
        ..strokeCap = StrokeCap.square;
      break;
    case BrushType.neon:
      paint
        ..color = Color.fromRGBO(
          color.red, color.green, color.blue,
          (color.opacity * 0.9).clamp(0.0, 1.0),
        )
        ..strokeWidth = width;
      break;
    case BrushType.highlighter:
      paint
        ..color = color.withOpacity((color.opacity * 0.4).clamp(0.0, 1.0))
        ..strokeWidth = width * 2.5
        ..strokeCap = StrokeCap.butt;
      break;
    case BrushType.eraser:
      paint
        ..color = Colors.transparent
        ..strokeWidth = width * 2
        ..blendMode = BlendMode.clear;
      break;
  }

  return paint;
}
