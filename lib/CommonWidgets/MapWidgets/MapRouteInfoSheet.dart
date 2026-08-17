import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class MapRouteInfoSheet extends StatefulWidget {
  final MapController controller;
  const MapRouteInfoSheet({super.key, required this.controller});

  @override
  State<MapRouteInfoSheet> createState() => _MapRouteInfoSheetState();
}

class _MapRouteInfoSheetState extends State<MapRouteInfoSheet> {
  MapController get controller => widget.controller;

  // The sheet is drag-collapsible: drag down to collapse to a small bar (it
  // never fully closes — the route stays), drag up / tap to expand again.
  bool _expanded = true;

  void _onDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v > 100 && _expanded) {
      setState(() => _expanded = false); // swipe down → collapse
    } else if (v < -100 && !_expanded) {
      setState(() => _expanded = true); // swipe up → expand
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.currentRouteInfo.value == null) {
        return const SizedBox.shrink();
      }

      final info = controller.currentRouteInfo.value!;
      final String mode = info['mode'];
      final String distance = info['distance'];
      final String duration = info['duration'];
      final String eta = _calculateETA(duration);

      final double bottomPad = MediaQuery.of(context).padding.bottom + 16.h;

      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onVerticalDragEnd: _onDragEnd,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 10.h,
              bottom: bottomPad,
            ),
            decoration: const BoxDecoration(
              color: Color(0xff2D0731),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.bottomCenter,
              child:
                  _expanded
                      ? _expandedContent(mode, distance, duration, eta)
                      : _collapsedContent(mode, distance, duration),
            ),
          ),
        ),
      );
    });
  }

  // Drag handle — tap toggles expand/collapse too.
  Widget _dragHandle() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Container(
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _expandedContent(
    String mode,
    String distance,
    String duration,
    String eta,
  ) {
    return Column(
      key: const ValueKey('expanded'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _dragHandle(),
        SizedBox(height: 12.h),

        // Transport mode selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModeButton('walking', Icons.directions_walk, mode),
            _buildModeButton('driving', Icons.directions_car, mode),
            _buildModeButton('bicycling', Icons.directions_bike, mode),
            _buildModeButton('transit', Icons.directions_transit, mode),
            GestureDetector(
              onTap: () => controller.clearRoute(),
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.redAccent, size: 20.sp),
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),

        // Route info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRouteInfoItem("Distance", distance, Icons.straighten),
            Container(width: 1, height: 40.h, color: Colors.white24),
            _buildRouteInfoItem("Duration", duration, Icons.timer),
            Container(width: 1, height: 40.h, color: Colors.white24),
            _buildRouteInfoItem("ETA", eta, Icons.access_time_filled),
          ],
        ),

        SizedBox(height: 16.h),

        // Open turn-by-turn directions to this place in Google Maps.
        GestureDetector(
          onTap: () => _openInGoogleMaps(mode),
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              gradient: const LinearGradient(
                colors: [Color(0xff704EF9), Color(0xffBD5AD7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation_rounded, color: Colors.white, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  "Navigate with Google Maps",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Collapsed: a compact bar with a summary + quick actions. Tap (or swipe up)
  // re-expands the full sheet.
  Widget _collapsedContent(String mode, String distance, String duration) {
    return Column(
      key: const ValueKey('collapsed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _dragHandle(),
        SizedBox(height: 8.h),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = true),
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 22.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  "$distance  ·  $duration",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Quick navigate
              GestureDetector(
                onTap: () => _openInGoogleMaps(mode),
                child: Container(
                  padding: EdgeInsets.all(9.r),
                  decoration: const BoxDecoration(
                    color: Color(0xff704EF9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Close / clear route
              GestureDetector(
                onTap: () => controller.clearRoute(),
                child: Container(
                  padding: EdgeInsets.all(9.r),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.redAccent, size: 18.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(String modeValue, IconData icon, String activeMode) {
    final bool isActive = modeValue == activeMode;
    return GestureDetector(
      onTap: () {
        if (!isActive && controller.selectedDestination.value != null) {
          controller.drawRouteToDestinationForDifferrent(
            controller.selectedDestination.value!,
            mode: modeValue,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color:
              isActive ? const Color(0xff704EF9) : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: isActive ? null : Border.all(color: Colors.white24),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildRouteInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16.sp),
        SizedBox(height: 5.h),
        Text(
          value,
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12.sp),
        ),
      ],
    );
  }

  /// Open Google Maps with turn-by-turn directions to the selected destination.
  Future<void> _openInGoogleMaps(String mode) async {
    final dest = controller.selectedDestination.value;
    if (dest == null) {
      AppSnackbar.error("No destination selected");
      return;
    }
    // Google Maps travel modes: driving | walking | bicycling | transit.
    final travelMode =
        (mode == 'bicycling' || mode == 'walking' || mode == 'transit')
            ? mode
            : 'driving';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${dest.latitude},${dest.longitude}'
      '&travelmode=$travelMode',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) AppSnackbar.error("Couldn't open Google Maps");
    } catch (e) {
      AppSnackbar.error("Couldn't open Google Maps");
    }
  }

  /// Parse duration string and calculate arrival time
  String _calculateETA(String duration) {
    int totalMinutes = 0;

    final hourMatch = RegExp(r'(\d+)\s*hour').firstMatch(duration);
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(duration);

    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }

    final arrival = DateTime.now().add(Duration(minutes: totalMinutes));
    final hour =
        arrival.hour > 12
            ? arrival.hour - 12
            : (arrival.hour == 0 ? 12 : arrival.hour);
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'PM' : 'AM';

    return "$hour:$minute $period";
  }
}
