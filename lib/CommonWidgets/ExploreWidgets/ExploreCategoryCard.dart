import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/routes.dart';

class ExploreCategoryCard extends StatelessWidget {
  final String categoryKey;
  final String title;
  final String iconPath;

  const ExploreCategoryCard({
    super.key,
    required this.categoryKey,
    required this.title,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.exploreCategory,
          arguments: {'categoryKey': categoryKey, 'categoryTitle': title},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff683381), width: 1.5.sp),
          color: const Color(0xff2D0731),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              // gaplessPlayback → keep the last frame on rebuild instead of
              // flashing blank while the asset re-resolves.
              child: Image.asset(
                iconPath,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
