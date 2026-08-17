import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreTabItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isActive;
  final VoidCallback onTap;

  const ExploreTabItem({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            children: [
              imageUrl.endsWith('.svg')
                  ? SvgPicture.asset(
                    imageUrl,
                    height: 20.h,
                    width: 20.w,
                    colorFilter: ColorFilter.mode(
                      isActive ? Colors.white : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  )
                  : Image.asset(
                    imageUrl,
                    scale: 1.2,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            height: 3.h,
            width: 100.w,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xffB166DE) : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5.r),
                topRight: Radius.circular(5.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
