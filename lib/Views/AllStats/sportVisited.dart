import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Shimmer import
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/AllStats/allStats.dart';
import 'package:outspot/Views/AllStats/allStats_controller.dart';

class SpotsVisitedScreen extends GetView<AllStatsController> {
  const SpotsVisitedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the single shared controller (already holds the correct user's
    // spots — own or a friend's). Never reloads/overwrites here.
    AllStatsController.instance;
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
              // Plain back — going to the previous screen. (The old
              // previousRoute==myProfile → toNamed(myProfile) pushed a NEW
              // screen instead of popping, causing the back-loop.)
              if (Get.key.currentState?.canPop() == true) {
                Get.back();
              } else {
                Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 5});
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset('assets/svg/icons/back_icon.svg'),
            ),
          ),
          title: Text(
            'Spots Visited',
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isSpotsLoading.value) {
            return _buildShimmerLoading();
          }

          if (controller.visitedSpotsList.isEmpty) {
            return Center(
              child: Text(
                "No visited spots found",
                style: GoogleFonts.notoSans(
                  color: Colors.white54,
                  fontSize: 16.sp,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: controller.visitedSpotsList.length,
            separatorBuilder:
                (_, __) => Divider(
                  color: AppColors.MainColor.withOpacity(0.3),
                  thickness: 1,
                ),
            itemBuilder: (context, index) {
              final item = controller.visitedSpotsList[index];
              return _buildSpotItem(item);
            },
          );
        }),
      ),
    );
  }

  // Shimmer Loading Widget
  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(radius: 27.w, backgroundColor: Colors.white),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120.w,
                        height: 12.h,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(width: 80.w, height: 10.h, color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  width: 50.w,
                  height: 25.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotItem(dynamic item) {
    String name = item['placeName'] ?? 'Unknown Spot';
    String points = compactNumber(num.tryParse('${item['totalPoints'] ?? 0}') ?? 0);
    String? imageUrl = item['mediaUrl'];
    String visitCount = item['visitCount']?.toString() ?? '1';
    String placeId = item['placeId'] ?? "";

    return GestureDetector(
      onTap: () async {
        if (placeId.isNotEmpty) {
          final restaurantModel = await ApiService.placeFetched(placeId);
          if (restaurantModel != null) {
            Get.offAllNamed(
              Routes.mainscreen,
              arguments: {"model": restaurantModel, "tab": 1},
            );
          } else {
            Get.snackbar(
              "Error",
              "Could not load details",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _SpotAvatar(mediaUrl: imageUrl ?? "", placeId: placeId),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Visited $visitCount times",
                    style: GoogleFonts.notoSans(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/svg/level/coinshape2.svg',
                    height: 14.h,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    points,
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular thumbnail for a visited spot. Prefers the user's check-in evidence
/// photo ([mediaUrl]); when that's missing or broken, falls back to the place's
/// own Google photo (fetched via the shared controller, cached), and finally to
/// a location pin. This is why "every place shows a picture" without any backend
/// change — the fallback is resolved client-side.
class _SpotAvatar extends StatefulWidget {
  final String mediaUrl;
  final String placeId;

  const _SpotAvatar({required this.mediaUrl, required this.placeId});

  @override
  State<_SpotAvatar> createState() => _SpotAvatarState();
}

class _SpotAvatarState extends State<_SpotAvatar> {
  String _url = '';
  bool _triedPlace = false;

  @override
  void initState() {
    super.initState();
    _url = widget.mediaUrl.trim();
    // No check-in photo → go straight to the place's own photo.
    if (_url.isEmpty) _fetchPlacePhoto();
  }

  Future<void> _fetchPlacePhoto() async {
    if (_triedPlace) return;
    _triedPlace = true;
    if (widget.placeId.isEmpty) return;
    final url = await AllStatsController.instance.resolvePlacePhoto(
      widget.placeId,
    );
    if (mounted && url.isNotEmpty && url != _url) {
      setState(() => _url = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55.w,
      height: 55.w,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.redAccent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child:
            _url.isEmpty
                ? _pin()
                : CachedNetworkImage(
                  imageUrl: _url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: Colors.white10,
                        highlightColor: Colors.white24,
                        child: Container(color: Colors.white),
                      ),
                  errorWidget: (context, url, error) {
                    // Check-in photo URL is dead — try the place photo once.
                    if (!_triedPlace) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _fetchPlacePhoto(),
                      );
                    }
                    return _pin();
                  },
                ),
      ),
    );
  }

  Widget _pin() =>
      const Center(child: Icon(Icons.location_on, color: Colors.redAccent));
}
