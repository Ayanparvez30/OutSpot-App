import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

class MapCenterLoader extends StatelessWidget {
  final MapController controller;
  const MapCenterLoader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isMapInitLoading.value ||
          controller.isCategoryLoading.value ||
          controller.isRouteLoading.value) {
        String loadingText = controller.isMapInitLoading.value
            ? "Loading Map..."
            : controller.isRouteLoading.value
                ? "Calculating Route..."
                : "Loading ${controller.selectedCategory.value}...";

        return Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xff2D0731).withOpacity(0.9),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      color: Color(0xff42D880),
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Text(
                    loadingText,
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}