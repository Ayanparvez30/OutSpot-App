// file: map_floating_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class MapFloatingButtons extends StatelessWidget {
  final MapController controller;
  const MapFloatingButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 110.h,
      right: 16.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "btn_direction",
            mini: true,
            backgroundColor: Color(0xff703A8B),
            elevation: 4,
            child: const Icon(Icons.directions, color: Colors.white),
            onPressed: () {
              if (controller.selectedDestination.value != null) {
                _showTravelModeSheet(context);
              } else {
                AppSnackbar.info("Please select a friend or location on the map first.", title: "Select Destination");
              }
            },
          ),

          SizedBox(height: 10.h),

          // My Location Button
          FloatingActionButton(
            heroTag: "btn_location",
            mini: true,
            backgroundColor: Color(0xff703A8B),
            elevation: 4,
            child: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () async {
              Position? pos = controller.currentPos.value;
              if (pos == null) {
                await controller.getPreciseLocation();
                pos = controller.currentPos.value;
              }
              if (pos != null && controller.googleMapController != null) {
                controller.googleMapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(pos.latitude, pos.longitude),
                      zoom: 17.0,
                      tilt: 50.0,
                      bearing: 0.0,
                    ),
                  ),
                );
              } else {
                AppSnackbar.info("Location not available, please try again.", title: "Location");
              }
            },
          ),
        ],
      ),
    );
  }

  // MapFloatingButtons ক্লাসের ভেতরে

  void _showTravelModeSheet(BuildContext context) {
    final RxString selectedMode = 'driving'.obs;
    final List<Map<String, dynamic>> travelModes = [
      {'label': 'Car', 'value': 'driving', 'icon': Icons.directions_car},
      {'label': 'Walk', 'value': 'walking', 'icon': Icons.directions_walk},
      {'label': 'Bike', 'value': 'bicycling', 'icon': Icons.directions_bike},
      {'label': 'Train', 'value': 'transit', 'icon': Icons.directions_transit},
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 20.w),
        decoration: const BoxDecoration(
          color: Color(0xff2D0731),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Text(
              "Select Commute Type",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),

            // 2. The Dropdown System
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: Colors.white24),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMode.value,
                    isExpanded: true,
                    dropdownColor: const Color(0xff4A148C),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    items:
                        travelModes.map((mode) {
                          return DropdownMenuItem<String>(
                            value: mode['value'],
                            child: Row(
                              children: [
                                Icon(
                                  mode['icon'],
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 15.w),
                                Text(
                                  mode['label'],
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        selectedMode.value = newValue;
                      }
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: 30.h),

            // 3. Start Navigation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff704EF9),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  Get.back();
                  controller.drawRouteToDestinationForDifferrent(
                    controller.selectedDestination.value!,
                    mode: selectedMode.value,
                  );
                },
                child: Text(
                  "Get Directions",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  // Widget _buildModeOption(IconData icon, String title, String apiMode) {
  //   return ListTile(
  //     leading: Container(
  //       padding: EdgeInsets.all(8.r),
  //       decoration: BoxDecoration(
  //         color: Colors.white.withOpacity(0.1),
  //         shape: BoxShape.circle,
  //       ),
  //       child: Icon(icon, color: Colors.white),
  //     ),
  //     title: Text(
  //       title,
  //       style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16.sp),
  //     ),
  //     onTap: () {
  //       Get.back();
  //       controller.drawRouteToDestinationForDifferrent(
  //         controller.selectedDestination.value!,
  //         mode: apiMode,
  //       );
  //     },
  //   );
  // }
}
