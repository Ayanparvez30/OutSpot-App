import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';

class ChallengesCompletedScreen extends GetView<AllStatsController> {
  const ChallengesCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: const [0.1, 0.5],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              child: SvgPicture.asset('assets/svg/icons/back_icon.svg'),
            ),
          ),
          title: Text(
            'Challenges Completed',
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (controller.completedChallenges.isEmpty) {
              return Center(
                child: Text(
                  "No challenges completed yet",
                  style: GoogleFonts.notoSans(
                    color: Colors.white54,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.completedChallenges.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          color: AppColors.MainColor.withOpacity(0.3),
                          thickness: 1,
                        ),
                    itemBuilder: (context, index) {
                      final item = controller.completedChallenges[index];
                      return _buildChallengeItem(item);
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildChallengeItem(dynamic item) {
    final challengeData = item['challenge'];

    String title =
        challengeData != null ? challengeData['title'] : 'Unknown Challenge';

    String points = compactNumber(num.tryParse('${item['pointsAwarded'] ?? 0}') ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE54D4D),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: SvgPicture.asset(
                'assets/svg/icons/challenges.svg',
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16.w),

          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSans(color: Colors.white, fontSize: 15.sp),
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/svg/level/coinshape2.svg',
                  height: 14.h,
                ),
                SizedBox(width: 5.w),
                Text(
                  points,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
