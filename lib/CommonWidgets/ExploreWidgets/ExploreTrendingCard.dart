import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreTrendingCard extends StatelessWidget {
  final VoidCallback onTap;

  const ExploreTrendingCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 140.h,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff683381), width: 1.5.sp),
          color: const Color(0xff2D0731),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: Row(
          children: [
            SizedBox(width: 15.w),
            Image.asset(
              "assets/Images/tending.png",
              height: 100.h,
              width: 100.w,
              // Keep the last frame on rebuild → no blank flicker.
              gaplessPlayback: true,
            ),
            SizedBox(width: 10.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Trending",
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Image.asset(
                      "assets/Images/trending_icon.png",
                      gaplessPlayback: true,
                    ),
                  ],
                ),
                Text(
                  "Best of the week",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
