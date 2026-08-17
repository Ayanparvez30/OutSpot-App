import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact gradient pill that stands in for a photo/video message in a chat
/// bubble. Instead of rendering the full-size media inline (which looks bad for
/// tall screenshots), the message shows a small "Photo" / "Video" pill; tapping
/// it opens the media fullscreen. No opened / saved state is shown.
class MediaMessagePill extends StatelessWidget {
  final bool isVideo;
  final bool uploading;
  final bool failed;
  final VoidCallback? onTap;

  const MediaMessagePill({
    super.key,
    required this.isVideo,
    this.uploading = false,
    this.failed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String label =
        failed
            ? 'Failed'
            : uploading
            ? 'Sending…'
            : (isVideo ? 'Video' : 'Photo');
    final IconData icon =
        isVideo ? Icons.play_circle_fill_rounded : Icons.photo_rounded;

    return GestureDetector(
      onTap: (uploading || failed) ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient:
              failed
                  ? null
                  : const LinearGradient(
                    colors: [Color(0xffAB50F6), Color(0xffFB7D6C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
          color: failed ? const Color(0xffDD4141) : null,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (uploading)
              SizedBox(
                width: 15.sp,
                height: 15.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, size: 17.sp, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: Colors.white,
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
