import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_state.dart';

class TuneEditorPanel extends StatefulWidget {
  final TuneData tuneData;
  final Function(TuneData) onChanged;
  final VoidCallback onClose;

  const TuneEditorPanel({
    super.key,
    required this.tuneData,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<TuneEditorPanel> createState() => _TuneEditorPanelState();
}

class _TuneEditorPanelState extends State<TuneEditorPanel>
    with SingleTickerProviderStateMixin {
  late double _brightness;
  late double _contrast;
  late double _saturation;
  bool _collapsed = false;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _brightness = widget.tuneData.brightness;
    _contrast = widget.tuneData.contrast;
    _saturation = widget.tuneData.saturation;

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(TuneData(
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE6100018), Color(0xFF0A000E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Collapse toggle + Header
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tune',
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFDA5EF3),
                                      Color(0xFFAB50F6),
                                      Color(0xFF7B2FD4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFAB50F6).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Done',
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (!_collapsed) ...[
                SizedBox(height: 6.h),

                // Reset button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _brightness = 0;
                          _contrast = 0;
                          _saturation = 0;
                        });
                        widget.onChanged(TuneData());
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.notoSans(
                            color: Colors.white38,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                _buildSlider('Brightness', Icons.brightness_6, _brightness, (v) {
                  setState(() => _brightness = v);
                  _update();
                }),
                SizedBox(height: 8.h),
                _buildSlider('Contrast', Icons.contrast, _contrast, (v) {
                  setState(() => _contrast = v);
                  _update();
                }),
                SizedBox(height: 8.h),
                _buildSlider('Saturation', Icons.color_lens_outlined, _saturation, (v) {
                  setState(() => _saturation = v);
                  _update();
                }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, IconData icon, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16.sp),
          SizedBox(width: 6.w),
          SizedBox(
            width: 70.w,
            child: Text(label,
                style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 11.sp)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: const Color(0xFFDA5EF3),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                min: -1.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 35.w,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }
}
