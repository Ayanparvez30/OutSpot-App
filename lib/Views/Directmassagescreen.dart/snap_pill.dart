import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Snapchat-style tap-to-open pill for a photo/video message.
///  - not opened → gradient fill + white "Open" / "Play"
///  - opened     → purple outline + "Opened"
class SnapPill extends StatelessWidget {
  final bool opened;
  final bool isVideo;
  final VoidCallback onTap;

  const SnapPill({
    super.key,
    required this.opened,
    required this.isVideo,
    required this.onTap,
  });

  static const Color _accent = Color(0xFFAB50F6);

  @override
  Widget build(BuildContext context) {
    final String label = opened ? 'Opened' : (isVideo ? 'Play' : 'Open');
    final IconData icon =
        isVideo ? Icons.play_circle_outline : Icons.photo_camera_outlined;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient:
              opened
                  ? null
                  : const LinearGradient(
                    colors: [Color(0xffAB50F6), Color(0xffFB7D6C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
          color: opened ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(30.r),
          border: opened ? Border.all(color: _accent, width: 1.4) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: opened ? _accent : Colors.white),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: opened ? _accent : Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green "Saved" pill shown under a message the user kept permanently.
class SavedPill extends StatelessWidget {
  const SavedPill({super.key});

  static const Color _green = Color(0xff42D880);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: _green, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_outline, size: 13.sp, color: _green),
          SizedBox(width: 5.w),
          Text(
            'Saved',
            style: GoogleFonts.notoSans(
              color: _green,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
