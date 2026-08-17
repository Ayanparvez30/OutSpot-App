import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/ExplorePostCard.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';

class ExplorePostsView extends StatelessWidget {
  const ExplorePostsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ExploreController>()) {
      Get.put(ExploreController());
    }
    final controller = Get.find<ExploreController>();

    return Column(
      children: [
        // 1. Search Bar
        TextField(
          controller: controller.postSearchController,
          onChanged: controller.filterPosts,
          style: GoogleFonts.notoSans(
            fontSize: 17.sp,
            fontWeight: FontWeight.w300,
            color: const Color(0xff793D94),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 25.w,
              vertical: 10.h,
            ),
            hintText: "Search stories...",
            hintStyle: GoogleFonts.notoSans(
              fontSize: 17.sp,
              fontWeight: FontWeight.w300,
              color: const Color(0xff793D94),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.all(13.sp),
              child: SvgPicture.asset(
                "assets/svg/leaderboard/search.svg",
                height: 18.sp,
                width: 18.sp,
              ),
            ),
            border: _outlineInputBorder(),
            enabledBorder: _outlineInputBorder(),
            focusedBorder: _outlineInputBorder(isFocused: true),
            filled: true,
            fillColor: const Color(0xff2D0731),
          ),
        ),

        SizedBox(height: 20.h),

        // 2. Post List
        Obx(() {
          if (controller.isPostFeedLoading.value) {
            return Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xffC574F7)),
              ),
            );
          }

          if (controller.displayedPostFeedStories.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      controller.postFeedError.value
                          ? "Failed to load stories"
                          : "No stories yet",
                      style: GoogleFonts.notoSans(
                        color: Colors.grey,
                        fontSize: 15.sp,
                      ),
                    ),
                    if (controller.postFeedError.value)
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: GestureDetector(
                          onTap: () => controller.fetchPostFeed(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: const Color(0xffC574F7),
                              ),
                            ),
                            child: Text(
                              "Tap to retry",
                              style: GoogleFonts.notoSans(
                                color: const Color(0xffC574F7),
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.displayedPostFeedStories.length,
                itemBuilder: (context, index) {
                  final story = controller.displayedPostFeedStories[index];
                  return ExplorePostCard(story: story);
                },
              ),
              if (controller.hasMorePosts)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Obx(
                    () =>
                        controller.isLoadingMorePosts.value
                            ? const CircularProgressIndicator(
                              color: Color(0xffC574F7),
                            )
                            : const SizedBox.shrink(),
                  ),
                ),
            ],
          );
        }),

        SizedBox(height: 80.h),
      ],
    );
  }

  OutlineInputBorder _outlineInputBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.r),
      borderSide: BorderSide(
        color: const Color(0xff703A8B),
        width: isFocused ? 2.0.w : 1.w,
      ),
    );
  }
}
