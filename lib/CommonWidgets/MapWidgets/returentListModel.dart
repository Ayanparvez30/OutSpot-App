// restaurant_list_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:outspot/Model/resturant_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';
import 'package:outspot/Utils/shared_location.dart';
import 'package:outspot/CommonWidgets/MapWidgets/image_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantListSheet extends StatefulWidget {
  final List<RestaurantModel> restaurants;

  const RestaurantListSheet({super.key, required this.restaurants});

  @override
  State<RestaurantListSheet> createState() => _RestaurantListSheetState();
}

class _RestaurantListSheetState extends State<RestaurantListSheet>
    with SingleTickerProviderStateMixin {
  final MapController controller = Get.find();

  late AnimationController _animController;
  final ScrollController _scrollController = ScrollController();
  double _dragOffset = 0;

  // Sorted view of the loaded restaurants (reflects the active sort filter).
  // Reading this inside an Obx keeps the list reactive to sort + data changes.
  List<RestaurantModel> get restaurants => controller.displayedRestaurants;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      controller.loadMoreRestaurantsByCategory();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 600);
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
      _animController.addListener(_dismissListener);
      _animController.forward(from: 0);
    } else {
      _animController.addListener(_snapBackListener);
      _animController.forward(from: 0);
    }
  }

  void _dismissListener() {
    setState(() {
      _dragOffset = _dragOffset + (600 - _dragOffset) * _animController.value;
    });
    if (_animController.isCompleted) {
      _animController.removeListener(_dismissListener);
      controller.showCategoryList.value = false;
    }
  }

  void _snapBackListener() {
    setState(() {
      _dragOffset = _dragOffset * (1 - _animController.value);
    });
    if (_animController.isCompleted) {
      _animController.removeListener(_snapBackListener);
      _animController.reset();
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // iOS only dials when the tel: URL is bare digits with an optional leading
    // "+". Spaces / parentheses / dashes get percent-encoded and iOS silently
    // refuses to open the dialer — so strip everything except digits and a
    // leading plus.
    var cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.contains('+')) {
      final hadLeadingPlus = cleaned.startsWith('+');
      cleaned = cleaned.replaceAll('+', '');
      if (hadLeadingPlus) cleaned = '+$cleaned';
    }
    if (cleaned.isEmpty) return;

    final Uri launchUri = Uri(scheme: 'tel', path: cleaned);
    try {
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Error launching phone: $e");
    }
  }

  Future<void> _launchWebsite(String url) async {
    if (url.isEmpty) return;

    String finalUrl = url;
    if (!finalUrl.startsWith("http")) {
      finalUrl = "https://$finalUrl";
    }

    final Uri launchUri = Uri.parse(finalUrl);
    try {
      // iOS তে canLaunchUrl সবসময় সঠিক কাজ করে না, তাই সরাসরি launch করি
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(launchUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Error launching website: $e");
    }
  }

  void _openImageViewer(List<String> images, int initialIndex) {
    Get.to(
      () => ImageViewerScreen(images: images, initialIndex: initialIndex),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Container(
          height: 500.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgGradientBottom,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
          ),
          child: Column(
            children: [
              SizedBox(height: 15.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedCategory.value.capitalizeFirst!,
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sort / filter — gold dot marks a non-default sort.
                        Obx(
                          () => GestureDetector(
                            onTap: _showSortSheet,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xff703A8B),
                              ),
                              alignment: Alignment.center,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: Colors.white,
                                    size: 22.r,
                                  ),
                                  if (controller.restaurantSort.value !=
                                      RestaurantSort.none)
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
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () => controller.closeRestaurantListSheet(),
                          child: Container(
                            height: 40,
                            width: 40,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xff703A8B),
                            ),
                            alignment: Alignment.center,
                            // The animation has built-in transparent padding, so
                            // it looks tiny at its natural size. Scale it up and
                            // let the circular container clip the overflow.
                            child: Transform.scale(
                              scale: 1.7,
                              child: Lottie.asset(
                                'assets/Images/mapIcon.json',
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // লিস্ট ভিউ
              Expanded(
                child: Obx(() {
                  final hasMore = controller.hasMoreRestaurants.value;
                  final loadingMore = controller.isLoadingMoreRestaurants.value;
                  final showLoader = hasMore || loadingMore;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      bottom: 110.h,
                    ),
                    itemCount: restaurants.length + (showLoader ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= restaurants.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffC574F7),
                              ),
                            ),
                          ),
                        );
                      }
                      final rest = restaurants[index];
                      return GestureDetector(
                        onTap: () => controller.onRestaurantSelected(rest),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xff2D0731),
                            borderRadius: BorderRadius.circular(16.r),
                            border: const Border(
                              top: BorderSide(
                                color: Color(0xff683381),
                                width: 1.5,
                              ), // উপরের বর্ডার
                              left: BorderSide(
                                color: Color(0xff683381),
                                width: 1.5,
                              ), // বামের বর্ডার
                              right: BorderSide(
                                color: Color(0xff683381),
                                width: 1.5,
                              ), // ডানের বর্ডার
                              bottom: BorderSide(
                                color: Color(0xff683381),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Recommended",
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      List<String> allImages = [
                                        rest.image,
                                        ...rest.photos,
                                      ];
                                      _openImageViewer(allImages, 0);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          50.r,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: rest.image,
                                          height: 60.h,
                                          width: 60.h,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (c, u) =>
                                                  Container(color: Colors.grey),
                                          errorWidget:
                                              (c, u, e) => Icon(
                                                Icons.restaurant,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rest.name,
                                          style: GoogleFonts.notoSans(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.visible,
                                          softWrap: true,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          "${rest.priceRange} | ${rest.category}",
                                          style: GoogleFonts.notoSans(
                                            color: Colors.white70,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (!rest.status
                                                .toLowerCase()
                                                .contains("unknown"))
                                              Text(
                                                rest.status,
                                                style: GoogleFonts.notoSans(
                                                  color:
                                                      rest.status
                                                              .toLowerCase()
                                                              .contains("open")
                                                          ? Colors.greenAccent
                                                          : Colors.redAccent,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            if (!rest.status
                                                .toLowerCase()
                                                .contains("unknown"))
                                              Text(
                                                "| ",
                                                style: GoogleFonts.notoSans(
                                                  color: Colors.yellow,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            Text(
                                              "${rest.rating.toString()}",
                                              style: GoogleFonts.notoSans(
                                                color: Colors.yellow,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: EdgeInsets.only(top: 30),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.5.w,
                                          color: Color(0xffFAC139),
                                        ),
                                        // color: Color(0xffFEEFD5),
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
                                          SizedBox(width: 2),
                                          Text(
                                            compactNumber(rest.points),
                                            style: GoogleFonts.notoSans(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              if (rest.photos.isNotEmpty)
                                SizedBox(
                                  height: 100.h,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            List<String> allImages = [
                                              rest.image,
                                              ...rest.photos,
                                            ];
                                            _openImageViewer(allImages, 1);
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: rest.photos[0],
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (c, u) => Container(
                                                    color: Colors.black12,
                                                  ),
                                              errorWidget:
                                                  (c, u, e) => const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  List<String> allImages = [
                                                    rest.image,
                                                    ...rest.photos,
                                                  ];
                                                  _openImageViewer(
                                                    allImages,
                                                    2,
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        rest.photos.length > 1
                                                            ? rest.photos[1]
                                                            : rest.image,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (c, u) => Container(
                                                          color: Colors.black12,
                                                        ),
                                                    errorWidget:
                                                        (c, u, e) => const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  List<String> allImages = [
                                                    rest.image,
                                                    ...rest.photos,
                                                  ];
                                                  _openImageViewer(
                                                    allImages,
                                                    3,
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        rest.photos.length > 2
                                                            ? rest.photos[2]
                                                            : rest.image,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (c, u) => Container(
                                                          color: Colors.black12,
                                                        ),
                                                    errorWidget:
                                                        (c, u, e) => const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox.shrink(),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => _makePhoneCall(rest.phone),
                                      icon: Icon(
                                        Icons.call,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        "Call",
                                        style: GoogleFonts.notoSans(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffFF6B6B),

                                        padding: EdgeInsets.symmetric(
                                          vertical: 14.h,
                                        ),
                                        shape: StadiumBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 15.w),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          30.r,
                                        ),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xffA060FA),
                                            Color(0xffFF8E8E),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => _launchWebsite(rest.website),
                                        icon: const Icon(
                                          Icons.language,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          "Website",
                                          style: GoogleFonts.notoSans(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 14.h,
                                          ),
                                          shape: const StadiumBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final display =
                                        '${rest.name}\n${rest.address}\n${rest.rating} stars - ${rest.category}';
                                    // Embed the place so the recipient can tap
                                    // the message to reopen it on the map.
                                    final msg = SharedLocation.encode(
                                      displayText: display,
                                      placeId: rest.id,
                                      lat: rest.lat,
                                      lng: rest.lng,
                                      name: rest.name,
                                    );
                                    showSendToSheet(msg);
                                  },
                                  icon: Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    "Send To",
                                    style: GoogleFonts.notoSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff703A8B),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet() {
    const options = <(String, IconData, RestaurantSort)>[
      ('Nearest first', Icons.near_me, RestaurantSort.nearest),
      ('Farthest first', Icons.social_distance, RestaurantSort.farthest),
      ('Trending (Google)', Icons.trending_up, RestaurantSort.trending),
      ('Points: High to Low', Icons.arrow_downward, RestaurantSort.pointsHigh),
      ('Points: Low to High', Icons.arrow_upward, RestaurantSort.pointsLow),
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
                final selected = controller.restaurantSort.value == o.$3;
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
                    controller.setRestaurantSort(o.$3);
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

  Widget _buildPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (c, u) => Container(color: Colors.black12),
        errorWidget:
            (c, u, e) =>
                Container(color: Colors.grey, child: Icon(Icons.broken_image)),
      ),
    );
  }
}
