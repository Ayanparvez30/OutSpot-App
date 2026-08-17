import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/custom_back_button.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Views/CreateProfile/createProfile_controller.dart';
import '../../Utils/colors.dart';

class OutfitScreen extends GetView<CreateprofileController> {
  const OutfitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.initOutfit();
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 140.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 20.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: SvgPicture.asset(
                  "assets/svg/icons/back_icon.svg",
                  width: 25.r,
                  height: 25.r,
                ),
              ),
              SizedBox(width: 15.w),
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
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 15.w),
            child: GestureDetector(
              onTap: () {
                controller.finishOutfitSelection();
              },
              child: Container(
                height: 30.h,
                width: 100.w,
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
                        color: Color(0xffFFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        title: Text(
          "Outfit",
          style: GoogleFonts.notoSans(
            color: Colors.white,
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
          // Run content to the bottom edge (like Explore) so there's no empty
          // "dead space" strip at the bottom.
          bottom: false,
          child: Obx(() {
            if (controller.isLoadingItems.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xffDA5EF3)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10.h),
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
    );
  }

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
                  String itemImage = '';
                  String label = '';
                  switch (cat) {
                    case OutfitCategory.top:
                      itemImage = controller.selectedTop.value;
                      label = "Top";
                      break;
                    case OutfitCategory.bottom:
                      itemImage = controller.selectedBottom.value;
                      label = "Bottom";
                      break;
                    case OutfitCategory.shoes:
                      itemImage = controller.selectedShoe.value;
                      label = "Shoes";
                      break;
                    case OutfitCategory.glasses:
                      itemImage = controller.selectedGlasses.value;
                      label = "Glasses";
                      break;
                    case OutfitCategory.watches:
                      itemImage = controller.selectedWatches.value;
                      label = "Watches";
                      break;
                    case OutfitCategory.makeup:
                      itemImage = controller.selectedMakeup.value;
                      label = "Makeup";
                      break;
                    case OutfitCategory.purse:
                      itemImage = controller.selectedPurse.value;
                      label = "Purse";
                      break;
                    case OutfitCategory.ornament:
                      itemImage = controller.selectedOrnament.value;
                      label = "Ornament";
                      break;
                  }

                  bool isActive = cat == selected;

                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
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
                            child: _buildPreviewImage(itemImage, cat),
                          ),
                        ),
                        if (label.isNotEmpty)
                          Positioned(
                            bottom: 5.h,
                            left: 0,
                            right: 0,
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
                  );
                }).toList(),
          ),
        ),
      );
    });
  }

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
                  final iconPath = categoryIcons[cat];
                  if (iconPath == null) return const SizedBox.shrink();
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
                          iconPath,
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

  Widget _buildItemGrid() {
    return Obx(() {
      final category = controller.selectedCategory.value;
      final items = controller.outfitItems[category] ?? [];
      String selectedItem = '';
      switch (category) {
        case OutfitCategory.top:
          selectedItem = controller.selectedTop.value;
          break;
        case OutfitCategory.bottom:
          selectedItem = controller.selectedBottom.value;
          break;
        case OutfitCategory.shoes:
          selectedItem = controller.selectedShoe.value;
          break;
        case OutfitCategory.glasses:
          selectedItem = controller.selectedGlasses.value;
          break;
        case OutfitCategory.watches:
          selectedItem = controller.selectedWatches.value;
          break;
        case OutfitCategory.makeup:
          selectedItem = controller.selectedMakeup.value;
          break;
        case OutfitCategory.purse:
          selectedItem = controller.selectedPurse.value;
          break;
        case OutfitCategory.ornament:
          selectedItem = controller.selectedOrnament.value;
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
              final imageUrl = item['imageUrl']?.toString() ?? '';
              final isNone = imageUrl == CreateprofileController.noItemUrl;
              final isSelected = imageUrl == selectedItem;
              final gradientColors = [
                const Color(0xffDA5EF3),
                const Color(0xffFF8D7E),
              ];

              return GestureDetector(
                onTap: () => controller.selectItem(imageUrl),
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
                          child:
                              isNone
                                  ? Image.asset(
                                    'assets/Images/without.png',
                                    fit: BoxFit.contain,
                                  )
                                  : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    placeholder:
                                        (context, url) =>
                                            const ShimmerPlaceholder(),
                                    errorWidget:
                                        (c, url, error) => Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white54,
                                          size: 30.sp,
                                        ),
                                  ),
                        ),
                      ),
                    ),
                    // if (isSelected)
                    //   Positioned(
                    //     top: 8.h,
                    //     left: 8.w,
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         shape: BoxShape.circle,
                    //         gradient: LinearGradient(
                    //           colors: gradientColors,
                    //           begin: Alignment.topLeft,
                    //           end: Alignment.bottomRight,
                    //         ),
                    //       ),
                    //       child: Image.asset(
                    //         "assets/Images/selection.png",
                    //         fit: BoxFit.fill,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  static const _catIcons = {
    OutfitCategory.top: 'assets/svg/level/Vector.svg',
    OutfitCategory.bottom: 'assets/svg/level/Layer 2.svg',
    OutfitCategory.shoes: 'assets/svg/level/Vector (1).svg',
    OutfitCategory.glasses: 'assets/svg/level/Vector (2).svg',
    OutfitCategory.watches: 'assets/svg/level/Vector (3).svg',
    OutfitCategory.makeup: 'assets/svg/level/Vector (4).svg',
    OutfitCategory.purse: 'assets/svg/purse.svg',
    OutfitCategory.ornament: 'assets/svg/necklace.svg',
  };

  Widget _buildPreviewImage(String itemImage, OutfitCategory cat) {
    if (itemImage.isEmpty || itemImage == CreateprofileController.noItemUrl) {
      return Center(
        child: SvgPicture.asset(
          _catIcons[cat]!,
          width: 32.w,
          height: 32.w,
          colorFilter: const ColorFilter.mode(Colors.white24, BlendMode.srcIn),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: CachedNetworkImage(
        imageUrl: itemImage,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholder: (context, url) => const ShimmerPlaceholder(),
        errorWidget:
            (c, url, error) => Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 30.sp,
            ),
      ),
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
