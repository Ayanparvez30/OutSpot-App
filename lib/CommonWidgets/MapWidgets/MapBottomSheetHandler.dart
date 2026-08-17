// file: map_bottom_sheet_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/MapWidgets/resturant_sheet.dart';
import 'package:outspot/CommonWidgets/MapWidgets/returentListModel.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

class MapBottomSheetHandler extends StatelessWidget {
  final MapController controller;
  const MapBottomSheetHandler({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedRestaurant.value != null) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: RestaurantBottomSheet(
            restaurant: controller.selectedRestaurant.value!,
          ),
        );
      } else if (controller.showCategoryList.value) {
        // Only show the restaurant list when data is available
        // The center loader (MapCenterLoader) handles the loading UI
        if (controller.filteredRestaurants.isNotEmpty) {
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RestaurantListSheet(
              restaurants: controller.filteredRestaurants,
            ),
          );
        }
      } else if (controller.canReopenRestaurantList) {
        // List was closed but data is still loaded — floating button to reopen.
        return _buildReopenButton();
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildReopenButton() {
    final category = controller.selectedCategory.value.capitalizeFirst ?? '';
    final label = category.isEmpty ? 'Show list' : category;
    return Positioned(
      bottom: 110.h,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30.r),
            onTap: () => controller.reopenRestaurantListSheet(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xff703A8B),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, color: Colors.white, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
