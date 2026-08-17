import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_state.dart';

class PixelateEditorPanel extends StatefulWidget {
  final Function(PixelateRegion) onAdd;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const PixelateEditorPanel({
    super.key,
    required this.onAdd,
    required this.onUndo,
    required this.onReset,
    required this.onClose,
  });

  @override
  State<PixelateEditorPanel> createState() => PixelateEditorPanelState();
}

class PixelateEditorPanelState extends State<PixelateEditorPanel> {
  int _blockSize = 10;
  bool _collapsed = false;

  int get blockSize => _blockSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: _collapsed ? 6.h : 12.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pixelate',
                          style: GoogleFonts.notoSans(
                              color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onReset,
                            child: Icon(Icons.undo, color: Colors.white70, size: 24.sp),
                          ),
                          SizedBox(width: 16.w),
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
                ],
              ),
            ),
            if (!_collapsed) ...[
            SizedBox(height: 12.h),
            Text('Draw a rectangle on the image to pixelate that area',
                style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12.sp)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Text('Block size',
                    style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 12.sp)),
                Expanded(
                  child: Slider(
                    value: _blockSize.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    activeColor: const Color(0xFFAB50F6),
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _blockSize = v.round()),
                  ),
                ),
                Text('$_blockSize',
                    style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 12.sp)),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }
}
