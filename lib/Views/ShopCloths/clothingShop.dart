import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/catalog_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'shopCloths_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';

class Clothingshop extends GetView<ShopClothsController> {
  Clothingshop({super.key});

  static const Map<String, String> _slotIcons = {
    'TOP': 'assets/svg/level/Vector.svg',
    'BOTTOM': 'assets/svg/level/Layer 2.svg',
    'SHOES': 'assets/svg/level/Vector (1).svg',
    'GLASSES': 'assets/svg/level/Vector (2).svg',
    'WATCH': 'assets/svg/level/Vector (3).svg',
    'MAKEUP': 'assets/svg/level/Vector (4).svg',
    'PURSE': 'assets/svg/purse.svg',
    'ORNAMENT': 'assets/svg/necklace.svg',
  };

  static const String _defaultSlotIcon = 'assets/Images/ss.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 4.h),

            Obx(() {
              if (controller.isPreviewLoading.value) {
                return Container(
                  height: 170.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xff1A0A2E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Lottie.asset(
                          'assets/Images/vertopal.com_Animation - 1746656287165.json',
                          height: 140.h,
                          width: 140.w,
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Generating preview...it can take up to 1 to 2 minutes',
                          style: GoogleFonts.notoSans(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (controller.selectedPreview.value.isEmpty) {
                //demo slider
                return CarouselSlider.builder(
                  itemCount: controller.banners.length,
                  itemBuilder: (context, idx, realIdx) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            controller.banners[idx],
                            fit: BoxFit.fill,
                          ),
                        ],
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 140.h,
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    onPageChanged:
                        (idx, _) => controller.currentIndex.value = idx,
                  ),
                );
              } else {
                //generated preview
                return SizedBox(
                  height: 180.h,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/Images/Rectangle 2503.png',
                        fit: BoxFit.cover,
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Obx(() {
                          if (controller.minime.value != null) {
                            return SizedBox(
                              height: 150.h,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (controller.minime.value!.avatarUrl !=
                                      null)
                                    _buildPreviewImage(
                                      controller.minime.value!.avatarUrl ?? '',
                                    ),
                                ],
                              ),
                            );
                          } else {
                            return Container(
                              child: Center(
                                child: Text(
                                  'No preview available',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                        }),
                      ),
                      Positioned(
                        bottom: 12.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffE84545),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'CUSTOM PREVIEW',
                              style: GoogleFonts.notoSans(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),

            SizedBox(height: 10.h),
            Obx(() {
              if (controller.selectedPreview.value.isNotEmpty) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  controller.totalCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: 6.h,
                    width: controller.currentIndex.value == i ? 6.w : 6.w,
                    decoration: BoxDecoration(
                      color:
                          controller.currentIndex.value == i
                              ? AppColors.bgGradientTop
                              : Colors.black,
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                ),
              );
            }),

            SizedBox(height: 8.h),
            Container(
              height: 27.h,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 20.w),
              color: const Color(0xff66CCFC),
              child: Obx(() {
                final displayLabel = controller.selectedCategoryDisplayName;
                return Text(
                  'Shop for $displayLabel',
                  style: GoogleFonts.notoSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }),
            ),
            SizedBox(height: 10.h),
            _buildCategorySelector(),

            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 0),
                    child: _buildItemGrid(),
                  ),
                  Obx(() {
                    final CatalogItem? selectedItem =
                        controller.getSelectedInstantItem();
                    // Only show Buy Item bar when custom preview avatar is visible
                    if (controller.selectedPreview.value.isEmpty ||
                        selectedItem == null)
                      return const SizedBox.shrink();
                    return Positioned(
                      bottom: 16.h,
                      left: 16.w,
                      right: 16.w,
                      child: _buildBottomBar(selectedItem),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        height: 70.h,
        fit: BoxFit.contain,
        placeholder: (context, url) => const ShimmerPlaceholder(height: 70),
        errorWidget: (context, url, error) => Icon(Icons.error),
      );
    }
    return Image.asset(path, height: 50.h, fit: BoxFit.fill);
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Obx(() {
        if (controller.availableCategories.isEmpty) {
          return const SizedBox.shrink();
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                controller.availableCategories.map((slot) {
                  final bool sel = controller.selectedCategory.value == slot;
                  final iconPath =
                      _slotIcons[slot.toUpperCase()] ?? _defaultSlotIcon;
                  return GestureDetector(
                    onTap: () => controller.selectedCategory.value = slot,
                    child: Container(
                      height: 40.h,
                      width: 45.w,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color:
                            sel ? const Color(0xffBE5BD5) : Color(0xff703A8B),
                        borderRadius: BorderRadius.circular(7.sp),
                      ),
                      child: SvgPicture.asset(
                        iconPath,
                        color: Colors.white,
                        height: 20.h,
                        width: 20.w,
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      }),
    );
  }

  // Shimmer placeholder mimicking the section + 3-col item grid layout.
  Widget _buildShimmerGrid() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 80.h),
      itemCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ShimmerPlaceholder(width: 90, height: 12),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
              ),
              itemBuilder: (_, __) => const ShimmerPlaceholder(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemGrid() {
    return Obx(() {
      // Observe IAP product state so the price badges re-render once StoreKit
      // prices arrive (products load AFTER the catalog).
      controller.isIapReady.value;
      controller.products.length;

      // Keep shimmer until BOTH catalog AND IAP prices are ready — otherwise
      // items flash with a "—" placeholder price, then prices pop in (bad UX).
      final bool catalogLoading =
          controller.isCatalogLoading.value && controller.catalogGrouped.isEmpty;
      if (catalogLoading || !controller.isIapReady.value) {
        return _buildShimmerGrid();
      }

      final collections = controller.currentCategoryItems;

      if (collections.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: 60.h),
            child: Text(
              "No items available.",
              style: GoogleFonts.notoSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        // Bottom padding (for the action bar) lives on the list, not after every
        // section — otherwise each section had a huge 75px trailing gap.
        padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 80.h),
        itemCount: collections.length,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (_, secIdx) {
          final String title = collections.keys.elementAt(secIdx);
          final List<CatalogItem> items = collections[title]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Color(0xffF8AC00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemBuilder: (_, idx) {
                  final item = items[idx];
                  final sel = item.imageUrl == controller.selectedPath.value;
                  final owned = controller.isItemOwned(item.id);

                  return GestureDetector(
                    onTap: () {
                      if (item.imageUrl.isNotEmpty) {
                        controller.selectItem(item.imageUrl);
                        final slot = controller.selectedCategory.value;
                        log("category selected in grid item: $slot");
                        controller.selectedCategory.refresh();

                        final body = {
                          "slot": slot.toUpperCase(),
                          "imageUrl": item.imageUrl,
                          "payload": item.payload,
                        };
                        controller.applyPreview(body);
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xff2A1635),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color:
                                  sel
                                      ? const Color(0xff42D880)
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.all(5.w),
                              child: _buildItemImage(item.imageUrl),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 6.h,
                          left: 6.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color:
                                    owned
                                        ? const Color(0xff42D880)
                                        : Colors.white24,
                                width: 0.5,
                              ),
                            ),
                            child:
                                owned
                                    ? Text(
                                      'owned',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff42D880),
                                      ),
                                    )
                                    : controller.cosmeticPrice.value.isNotEmpty
                                    ? Text(
                                      controller.cosmeticPrice.value,
                                      style: GoogleFonts.notoSans(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    )
                                    // Price not resolved yet → tiny shimmer,
                                    // never a bare "—".
                                    : const ShimmerPlaceholder(
                                      width: 22,
                                      height: 8,
                                    ),
                          ),
                        ),

                        if (sel)
                          Positioned(
                            top: 6.h,
                            right: 6.w,
                            child: Image.asset(
                              'assets/Images/imageSelection.png',
                              height: 14.h,
                              width: 14.w,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildItemImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => FadeShimmer(
              height: 80.h,
              width: 80.w,
              radius: 8,
              fadeTheme: FadeTheme.dark,
              highlightColor: Colors.grey.shade700,
              baseColor: Colors.grey.shade900,
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey.shade800,
              child: Icon(Icons.broken_image, color: Colors.white54, size: 24),
            ),
      );
    }
    return Image.asset(path, fit: BoxFit.cover);
  }

  Widget _buildBottomBar(CatalogItem selectedItem) {
    final owned = controller.isItemOwned(selectedItem.id);
    final displayPrice =
        controller.cosmeticPrice.value.isNotEmpty
            ? controller.cosmeticPrice.value
            : (controller.getStorePrice(selectedItem) ??
                '\$${selectedItem.priceUsd}');
    final name = selectedItem.name;

    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (owned) {
                  AppSnackbar.info('You already own this item');
                  return;
                }
                showPurchaseCloth(Get.context!, selectedItem);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff704EF9),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(30.r),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Buy Item',
                          style: GoogleFonts.notoSans(
                            fontSize: 13.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // if (!owned)
                    Row(
                      children: [
                        Text(
                          displayPrice,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSans(
                            fontSize: 10.sp,
                            color: Colors.white.withOpacity(.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(height: 10.h, color: Colors.white),
                        SizedBox(width: 5.w),
                        Text(
                          // displayPrice,
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSans(
                            fontSize: 10.sp,
                            color: Colors.white.withOpacity(.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 3.w, height: 40.h, color: Colors.white),
          GestureDetector(
            onTap: () => controller.removePreview(),
            child: Container(
              width: 56.h,
              height: 60.h,
              decoration: BoxDecoration(
                color: const Color(0xffE84545),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(30.r),
                ),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ═══════════ App Store–style modal bottom sheet (Bundle) ═══════════ */
  void showPurchaseCloth(BuildContext context, CatalogItem selectedItem) {
    final displayPrice =
        controller.getStorePrice(selectedItem) ?? '\$${selectedItem.priceUsd}';

    controller.isPurchaseSheetOpen = true;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xff323434),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Platform.isIOS ? 'App Store' : 'Play Store',
                        style: GoogleFonts.notoSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 28.w,
                          width: 28.w,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 10.h,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              "assets/Images/cleanLogo.png",
                              height: 40.w,
                              width: 40.w,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mini-Me Clothing',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Outspot\nIn-App Purchase',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 12.sp,
                                      color: Colors.grey,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          controller.displayPriceFor(
                            appleProductId: controller.sharedCosmeticSku,
                            googleProductId: controller.sharedCosmeticSku,
                            fallbackPriceUsd: selectedItem.priceUsd,
                          ),
                          style: GoogleFonts.notoSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account:  ',
                              style: GoogleFonts.notoSans(
                                fontSize: 12.sp,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              controller.email.value.isEmpty
                                  ? 'Loading...'
                                  : controller.email.value,
                              style: GoogleFonts.notoSans(
                                fontSize: 11.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                GestureDetector(
                  onTap: () async {
                    await controller.buyOutfitProduct(selectedItem);
                  },
                  child: Container(
                    width: 150.w,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Text(
                      'Purchase',
                      style: GoogleFonts.notoSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => controller.isPurchaseSheetOpen = false);
  }
}
