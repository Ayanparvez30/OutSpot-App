import 'package:cached_network_image/cached_network_image.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/Model/inventory_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/waredrop/waredrop_controller.dart';
import 'package:outspot/Views/waredrop/minime_locker_screen.dart';

class Waredrop extends GetView<WaredropController> {
  const Waredrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leadingWidth: 140.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  padding: EdgeInsets.all(15.w),
                  child: SvgPicture.asset(
                    'assets/svg/icons/back_icon.svg',
                    color: Colors.white,
                    height: 20.h,
                  ),
                ),
              ),

              // SizedBox(width: 15.w),
            ],
          ),
        ),
        actions: [
          // "My Locker" + "Change Minime" moved out of the app bar into pills
          // below (they were cramping the title). Only Finish stays here.
          Obx(() {
            if (controller.outfitItems.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(right: 15.w),
              child: GestureDetector(
                onTap: () {
                  controller.finishOutfitSelection();
                },
                child: Container(
                  height: 30.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: const Color(0xffBD5AD7),
                    borderRadius: BorderRadius.circular(30.sp),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/icons/Icon-Outline-Check-Circle2.svg",
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        "Finish",
                        style: GoogleFonts.notoSans(
                          fontSize: 11.sp,
                          color: const Color(0xffFFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        // No spacing around the title so the short "Outfit" label gets the full
        // gap between the (wide) leading + Undo and the switch/Finish actions —
        // otherwise it's squeezed to "O…" on every category sub-screen.
        titleSpacing: 0,
        title: Text(
          "Outfit",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
            stops: [0.2, 0.6],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xffBD5AD7),
            backgroundColor: Colors.black,
            onRefresh: () async {
              await Future.wait([
                controller.loadUserProfile(),
                controller.loadInventory(),
              ]);
            },
            child: Obx(() {
              // While the first load runs (profile → free items → inventory)
              // show a shimmer skeleton instead of a blank top section.
              if (controller.isLoading.value) {
                return _buildLoadingSkeleton();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar actions — moved out of the cramped app bar into two
                  // right-aligned pills in the space above the preview.
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 12.w, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            controller.undo();
                          },
                          child: Container(
                            height: 30.h,
                            width: 75.w,
                            decoration: BoxDecoration(
                              color: const Color(0xff7A4099),
                              borderRadius: BorderRadius.circular(30.sp),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/icons/Icon-Outline-Undo.svg",
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  "Undo",
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        _actionPill(
                          // icon: Icons.folder_open_rounded,
                          label: 'My Locker',
                          onTap: () => Get.to(() => MinimeLockerScreen()),
                        ),
                        SizedBox(width: 4.w),
                        _actionPill(
                          // icon: Icons.add_a_photo_rounded,
                          label: 'Change Minime',
                          onTap:
                              () => Get.toNamed(
                                Routes.createMiniMe,
                                arguments: {'returnTo': 'waredrop'},
                              ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height: 6.h),
                  _buildTopPreview(),
                  Obx(() {
                    final selected = controller.selectedCategory.value;
                    String categoryLabel;
                    switch (selected) {
                      case OutfitCategory.top:
                        categoryLabel = "Top";
                        break;
                      case OutfitCategory.bottom:
                        categoryLabel = "Bottom";
                        break;
                      case OutfitCategory.shoes:
                        categoryLabel = "Shoes";
                        break;
                      case OutfitCategory.glasses:
                        categoryLabel = "Glasses";
                        break;
                      case OutfitCategory.watches:
                        categoryLabel = "Watches";
                        break;
                      case OutfitCategory.makeup:
                        categoryLabel = "Makeup";
                        break;
                      case OutfitCategory.purse:
                        categoryLabel = "Purse";
                        break;
                      case OutfitCategory.ornament:
                        categoryLabel = "Ornament";
                        break;
                    }

                    return Container(
                      height: 27.h,
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xffDA5EF3), Color(0xffFF8D7E)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      padding: EdgeInsets.only(left: 20.w),
                      child: Text(
                        "Select $categoryLabel",
                        style: GoogleFonts.notoSans(
                          fontSize: 14.sp,
                          color: Color(0xffFFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 10.h),
                  _buildCategorySelector(),
                  _buildItemGrid(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A rounded pill action (My Locker / Change Minime) shown above the preview.
  Widget _actionPill({
    // required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: const Color(0xff7A4099),
          borderRadius: BorderRadius.circular(30.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(icon, color: Colors.white, size: 15.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top preview row — shows selected item per category
  // ---------------------------------------------------------------------------
  Widget _buildTopPreview() {
    return Obx(() {
      final selected = controller.selectedCategory.value;

      return SizedBox(
        height: 180.h,
        child: SingleChildScrollView(
          controller: controller.previewScrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children:
                controller.availableCategories.map((cat) {
                  final ItemDetail? item = controller.selectedFor(cat);

                  const catIcons = {
                    OutfitCategory.top: 'assets/svg/level/Vector.svg',
                    OutfitCategory.bottom: 'assets/svg/level/Layer 2.svg',
                    OutfitCategory.shoes: 'assets/svg/level/Vector (1).svg',
                    OutfitCategory.glasses: 'assets/svg/level/Vector (2).svg',
                    OutfitCategory.watches: 'assets/svg/level/Vector (3).svg',
                    OutfitCategory.makeup: 'assets/svg/level/Vector (4).svg',
                    OutfitCategory.purse: 'assets/svg/purse.svg',
                    OutfitCategory.ornament: 'assets/svg/necklace.svg',
                  };

                  String label;
                  switch (cat) {
                    case OutfitCategory.top:
                      label = "Top";
                      break;
                    case OutfitCategory.bottom:
                      label = "Bottom";
                      break;
                    case OutfitCategory.shoes:
                      label = "Shoes";
                      break;
                    case OutfitCategory.glasses:
                      label = "Glasses";
                      break;
                    case OutfitCategory.watches:
                      label = "Watches";
                      break;
                    case OutfitCategory.makeup:
                      label = "Accessory";
                      break;
                    case OutfitCategory.purse:
                      label = "Accessory";
                      break;
                    case OutfitCategory.ornament:
                      label = "Accessory";
                      break;
                  }

                  bool isActive = cat == selected;

                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: GestureDetector(
                      onTap: () {
                        controller.selectedCategory.value = cat;
                        scrollToPreview(cat);
                      },
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isActive ? 130.w : 100.w,
                            height: isActive ? 130.h : 100.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              gradient:
                                  isActive
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xffDA5EF3),
                                          Color(0xffFF8D7E),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : null,
                              color: isActive ? null : const Color(0xffE8EAEB),
                            ),
                            padding: EdgeInsets.all(2.w),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff1A0B2E),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child:
                                  item != null && item.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Center(
                                                child: FadeShimmer(
                                                  height:
                                                      isActive ? 130.h : 100.h,
                                                  width:
                                                      isActive ? 130.w : 100.w,
                                                  radius: 10.r,
                                                  baseColor: const Color(
                                                    0xff2D0731,
                                                  ),
                                                  highlightColor: const Color(
                                                    0xff4A1060,
                                                  ),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white38,
                                                  ),
                                        ),
                                      )
                                      : Center(
                                        child: SvgPicture.asset(
                                          catIcons[cat]!,
                                          width: 32.w,
                                          height: 32.w,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.white24,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                          if (label.isNotEmpty)
                            Positioned(
                              bottom: 5.h,
                              left: 10.w,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28.r),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xffDA5EF3),
                                        Color(0xffFF8D7E),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Category selector — keeps local asset icons (UI chrome)
  // ---------------------------------------------------------------------------
  Widget _buildCategorySelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Obx(() {
        final selected = controller.selectedCategory.value;

        final Map<OutfitCategory, String> categoryIcons = {
          OutfitCategory.top: 'assets/svg/level/Vector.svg',
          OutfitCategory.bottom: 'assets/svg/level/Layer 2.svg',
          OutfitCategory.shoes: 'assets/svg/level/Vector (1).svg',
          OutfitCategory.glasses: 'assets/svg/level/Vector (2).svg',
          OutfitCategory.watches: 'assets/svg/level/Vector (3).svg',
          OutfitCategory.makeup: 'assets/svg/level/Vector (4).svg',
          OutfitCategory.purse: 'assets/svg/purse.svg',
          OutfitCategory.ornament: 'assets/svg/necklace.svg',
        };

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                controller.availableCategories.map((cat) {
                  final isSelected = cat == selected;

                  return GestureDetector(
                    onTap: () {
                      controller.selectedCategory.value = cat;
                      scrollToPreview(cat);
                    },
                    child: Container(
                      height: 40.h,
                      width: 45.w,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xffBE5BD5)
                                : Color(0xff703A8B),
                        borderRadius: BorderRadius.circular(7.sp),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: SvgPicture.asset(
                          categoryIcons[cat]!,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Item grid — network images via CachedNetworkImage
  // ---------------------------------------------------------------------------
  Widget _buildItemGrid() {
    return Obx(() {
      // Loading state
      if (controller.isLoading.value) {
        return Expanded(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xffBE5BD5)),
          ),
        );
      }

      final category = controller.selectedCategory.value;
      final List<ItemDetail> items = controller.outfitItems[category] ?? [];
      final ItemDetail? selectedItem = controller.selectedFor(category);

      // Empty state
      if (items.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white38,
                  size: 48.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  "No items yet",
                  style: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.shopCloths),
                  child: Text(
                    "Buy items from store",
                    style: GoogleFonts.notoSans(
                      fontSize: 14.sp,
                      color: const Color(0xffBD5AD7),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xffBD5AD7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
          child: GridView.builder(
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected =
                  selectedItem != null && selectedItem.id == item.id;
              final gradientColors = [
                const Color(0xffDA5EF3),
                const Color(0xffFF8D7E),
              ];

              return GestureDetector(
                onTap: () => controller.selectItem(item),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        border:
                            isSelected
                                ? null
                                : Border.all(color: Colors.transparent),
                      ),
                      padding: EdgeInsets.all(2.w),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xff2D0731),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => FadeShimmer(
                                  height: double.infinity,
                                  width: double.infinity,
                                  radius: 10.r,
                                  baseColor: const Color(0xff2D0731),
                                  highlightColor: const Color(0xff4A1060),
                                ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.white38,
                                ),
                          ),
                        ),
                      ),
                    ),
                    // Selection is shown by the gradient border only (no tick).
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Loading skeleton — shimmer placeholders shown while the wardrobe's first
  // load runs, so the screen never flashes a blank top section.
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton() {
    // Softer, more visible shimmer that reads cleanly over the dark purple
    // background — a subtle lift from the base to a lighter theme purple.
    Widget shimmer({double? h, double? w, double radius = 12}) => FadeShimmer(
      height: h ?? double.infinity,
      width: w ?? double.infinity,
      radius: radius,
      baseColor: const Color(0xff351248),
      highlightColor: const Color(0xff5E2A85),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14.h),
        // Top preview cards — mirror the real row: a larger "active" card first,
        // then smaller ones, vertically centred like the live preview.
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            itemCount: 4,
            itemBuilder: (_, i) {
              final bool active = i == 0;
              return Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Center(
                  child: shimmer(
                    h: active ? 130.h : 100.h,
                    w: active ? 130.w : 100.w,
                    radius: 14,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 18.h),
        // Section label placeholder — a small rounded bar, not a full-width slab.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: shimmer(h: 16.h, w: 120.w, radius: 8),
        ),
        SizedBox(height: 14.h),
        // Category selector chips
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: List.generate(
              5,
              (_) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: shimmer(h: 44.h, w: 44.w, radius: 12),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Item grid
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 4.h),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, __) => shimmer(radius: 14),
            ),
          ),
        ),
      ],
    );
  }

  void scrollToPreview(OutfitCategory cat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.previewScrollController.hasClients) {
        final index = controller.availableCategories.indexOf(cat);
        final itemWidth = 110.w;
        try {
          controller.previewScrollController.animateTo(
            index * itemWidth,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          debugPrint("Scroll Error skipped: $e");
        }
      }
    });
  }
}
