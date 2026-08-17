import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outspot/CommonWidgets/MapWidgets/MapBottomSheetHandler.dart';
import 'package:outspot/CommonWidgets/MapWidgets/MapFloatingButtons.dart';
import 'package:outspot/CommonWidgets/MapWidgets/MapRouteInfoSheet.dart';
import 'package:outspot/CommonWidgets/MapWidgets/MapUserInfoPill.dart';
import 'package:outspot/CommonWidgets/MapWidgets/mapCenterLoader.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/CommonWidgets/MapWidgets/custom_map_appbar.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';

class MapScreen extends StatelessWidget {
  MapScreen({super.key});
  final controller = Get.put(MapController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CustomMapAppBar(controller: controller),
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
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Obx(() {
                      final initPos = controller.currentPos.value;
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target:
                              initPos == null
                                  ? const LatLng(35.2271, -80.8431)
                                  : LatLng(initPos.latitude, initPos.longitude),
                          zoom: 16.0,
                        ),
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        polylines: controller.routePolyline.value,
                        mapType: MapType.normal,
                        markers: {
                          ...controller.userMarker.value,
                          ...controller.searchMarker.value,
                          ...controller.friendPosition.value,
                          ...controller.storiesMarkers.value,
                          if (controller.selectedCategory.value.isNotEmpty)
                            ...controller.restaurantMarkers.value,
                        },
                        onTap: controller.onMapTapped,
                        onMapCreated: controller.onMapCreated,
                      );
                    }),
                  ),
                ],
              ),
              // 2. Custom Overlays & Buttons
              MapCategoryList(controller: controller),
              MapUserInfoPill(controller: controller),
              MapRefreshButton(controller: controller),

              // 🔥 নতুন যোগ করা লোডার (মাঝখানে দেখানোর জন্য)
              MapCenterLoader(controller: controller),

              // 3. Floating Buttons (Location, Route, Clear)
              MapFloatingButtons(controller: controller),

              // 4. Bottom Sheets
              MapBottomSheetHandler(controller: controller),
              MapRouteInfoSheet(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
