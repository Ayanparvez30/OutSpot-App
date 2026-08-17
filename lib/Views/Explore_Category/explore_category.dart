import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/Explore_Category/explore_category_controller.dart';
import 'package:outspot/Views/Explore_Category/placeDetailsScreen.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:shimmer/shimmer.dart';

class ExploreCategory extends GetView<ExploreCategoryController> {
  const ExploreCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: SvgPicture.asset(
            "assets/svg/icons/back_icon.svg",
            width: 25.r,
            height: 25.r,
          ),

          padding: EdgeInsets.all(8.w),
          constraints: const BoxConstraints(),
        ),

        title: Obx(
          () => Text(
            controller.categoryTitle.value,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          // Sort / filter — a small dot marks when a non-default sort is active.
          Obx(
            () => IconButton(
              onPressed: () => _showSortSheet(context),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              constraints: const BoxConstraints(),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.tune, color: Colors.white, size: 24.r),
                  if (controller.sortOption.value != PlaceSort.none)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xffFAC139),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: const [0.2, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- 1. Search Bar ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: TextField(
                  autofocus: false,
                  controller: controller.searchController,
                  onChanged: (val) {
                    controller.onSearchChanged(val);
                  },
                  style: GoogleFonts.notoSans(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search places... (min 2 chars)",
                    hintStyle: GoogleFonts.notoSans(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0.h),
                  ),
                ),
              ),

              // --- 2. List View with Shimmer & Lazy Loading ---
              Expanded(
                child: Obx(() {
                  // 🔥 ১. Initial Loading OR Active Search → Shimmer
                  if (controller.isInitialLoading.value ||
                      controller.isSearching.value) {
                    return ListView.builder(
                      itemCount: 8, // ডামি ৮টি আইটেম দেখাবে
                      itemBuilder: (context, index) {
                        return Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.05),
                          highlightColor: Colors.white.withOpacity(0.15),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.h,
                              horizontal: 16.w,
                            ),
                            child: Row(
                              children: [
                                // Circular Image Skeleton
                                Container(
                                  width: 50.sp,
                                  height: 50.sp,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 15.w),
                                // Text Skeleton
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 14.h,
                                        width: double.infinity,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 8.h),
                                      Container(
                                        height: 14.h,
                                        width: 100.w,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // 🔥 ২. Empty State (যদি ডাটা না থাকে)
                  if (controller.places.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            color: Colors.white.withOpacity(0.3),
                            size: 60.sp,
                          ),
                          SizedBox(height: 15.h),
                          Text(
                            "No places found",
                            style: GoogleFonts.notoSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 🔥 ৩. Main List (sorted by the active filter)
                  final items = controller.displayedPlaces;
                  return ListView.builder(
                    controller: controller.scrollController,
                    itemCount:
                        items.length +
                        (controller.hasMoreData.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      // একদম শেষে লোডিং ইন্ডিকেটর (Lazy Loading)
                      if (index == items.length) {
                        return Padding(
                          padding: EdgeInsets.all(20.h),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final place = items[index];
                      return Container(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 2.h,
                                horizontal: 16.w,
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Get.to(
                                    () => PlaceDetailsScreen(
                                      place: place,
                                      categoryKey: controller.categoryKey.value,
                                      userLat: controller.userLat,
                                      userLng: controller.userLng,
                                    ),
                                    // Named so the "Too Far" dialog can pop back
                                    // to this exact place screen.
                                    routeName: Routes.placeDetails,
                                  );
                                  // Get.offAllNamed(
                                  //   Routes.mainscreen,
                                  //   arguments: {
                                  //     "tab": 2,
                                  //     'place': place,
                                  //     'categoryKey': controller.categoryKey.value,
                                  //   },
                                  // );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          width: 2.w,
                                          color: const Color(0xffDD4141),
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: place.photoUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: place.photoUrl,
                                                width: 44.sp,
                                                height: 44.sp,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) =>
                                                        const ShimmerPlaceholder(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(
                                                          Icons.error,
                                                          color: Colors.grey,
                                                        ),
                                              )
                                            : Icon(
                                                Icons.place,
                                                color: Colors.grey,
                                                size: 44.sp,
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        place.name,
                                        style: GoogleFonts.notoSans(
                                          color: Colors.white,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.5.w,
                                          color: const Color(0xffFAC139),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          15.sp,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            "assets/Images/skcoin.png",
                                            scale: 3,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            compactNumber(place.points),
                                            style: GoogleFonts.notoSans(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              indent: 18.w,
                              endIndent: 0,
                              thickness: 0.5,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    const options = <(String, IconData, PlaceSort)>[
      ('Nearest first', Icons.near_me, PlaceSort.nearest),
      ('Farthest first', Icons.social_distance, PlaceSort.farthest),
      ('Trending (Google)', Icons.trending_up, PlaceSort.trending),
      ('Points: High to Low', Icons.arrow_downward, PlaceSort.pointsHigh),
      ('Points: Low to High', Icons.arrow_upward, PlaceSort.pointsLow),
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xff1A0420),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: const Color(0xff683381), width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sort by",
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              ...options.map((o) {
                final selected = controller.sortOption.value == o.$3;
                final color =
                    selected ? const Color(0xffC574F7) : Colors.white;
                return ListTile(
                  dense: true,
                  leading: Icon(o.$2, color: color, size: 22.sp),
                  title: Text(
                    o.$1,
                    style: GoogleFonts.notoSans(
                      color: color,
                      fontSize: 14.sp,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w400,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xffC574F7))
                      : null,
                  onTap: () {
                    controller.setSort(o.$3);
                    Get.back();
                  },
                );
              }),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
