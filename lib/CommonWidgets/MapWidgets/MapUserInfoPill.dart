// file: map_top_overlays.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

// 1. User Location & Weather Pill
class MapUserInfoPill extends StatelessWidget {
  final MapController controller;
  const MapUserInfoPill({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 42.h,
      left: 20.w,
      child: Obx(() {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xff4A148C).withOpacity(0.9),
            borderRadius: BorderRadius.circular(50.r),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 35.h,
                width: 35.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://loremflickr.com/200/200/${controller.currentCityName.value},city",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerPlaceholder(),
                    errorWidget:
                        (context, url, error) => const Icon(
                          Icons.location_city,
                          color: Colors.white,
                          size: 15,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${controller.currentCityName.value}, ${controller.currentZipCode.value}",
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${controller.currentTime.value} | ${controller.currentTemperature.value}",
                    style: GoogleFonts.notoSans(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10.w),
            ],
          ),
        );
      }),
    );
  }
}

// 2. Category List Selector
class MapCategoryList extends StatelessWidget {
  final MapController controller;
  const MapCategoryList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4.h,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 34.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final cat = controller.categories[index];
            return Obx(() {
              bool isSelected = controller.selectedCategory.value == cat;
              return GestureDetector(
                onTap: () => controller.filterRestaurantsByCategory(cat),
                child: Container(
                  margin: EdgeInsets.only(right: 12.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xff8E44AD)
                            : const Color(0xff703A8B).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30.r),
                    border:
                        isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xff8E44AD).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      cat.capitalizeFirst!,
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

// 3. Refresh Button
class MapRefreshButton extends StatelessWidget {
  final MapController controller;
  const MapRefreshButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40.h,
      right: 16.w,
      child: FloatingActionButton(
        heroTag: "btn_refresh",
        mini: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () => controller.refreshMapData(),
      ),
    );
  }
}
