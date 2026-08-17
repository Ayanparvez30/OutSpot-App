// point_shop_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/bundlePoint_model.dart';
import 'package:outspot/Model/pointMultiplier_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:path/path.dart' as p; // alias to avoid `context` clash

import 'shopCloths_controller.dart';

class PointShop extends StatelessWidget {
  PointShop({super.key});

  // Reuse the existing controller (the shop binding already registers one via
  // Get.lazyPut) instead of Get.put-ing a fresh instance on every build. A new
  // instance would register a second IAP purchase-stream listener, causing each
  // purchase to be processed twice and transactions to be double-completed
  // (an error on iOS).
  final controller =
      Get.isRegistered<ShopClothsController>()
          ? Get.find<ShopClothsController>()
          : Get.put(ShopClothsController());

  // debounce/loading guard per productId
  //final RxSet<String> buying = <String>{}.obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: [0.1, 0.5],

          radius: 1.5,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10.h),

              /* ────── Point Multiplier Section ────── */
              _sectionBar('Point Multipliers'),

              Obx(() {
                if (controller.pointMultipliers1.isEmpty) {
                  return const Center(child: Text("No multipliers found"));
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.pointMultipliers1.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                  ),
                  itemBuilder: (ctx, i) {
                    final item = controller.pointMultipliers1[i];
                    return _multiplierCard(
                      ctx,
                      item: item,
                    ); // pass BuildContext
                  },
                );
              }),

              /* ────── Point Bundle Section ────── */
              _sectionBar('Point Bundles'),
              Obx(() {
                if (controller.bundles.isEmpty) {
                  return const Center(child: Text("No bundles found"));
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.bundles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                  ),
                  itemBuilder: (ctx, i) {
                    final bundle = controller.bundles[i];
                    return _bundleCard(
                      ctx,
                      bundle,
                      controller,
                    ); // ctx + bundle + controller
                  },
                );
              }),

              /* ────── Invite Banner ────── */
              SizedBox(height: 10.h),
              _inviteBanner(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  /* ════════════ section bar ════════════ */
  Widget _sectionBar(String text) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    color: const Color(0xffC574F7),
    child: Text(
      text,
      style: GoogleFonts.notoSans(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  /* ═══════════ multiplier card ═══════════ */
  Widget _multiplierCard(
    BuildContext context, {
    required PointMultiplier item,
  }) {
    return Container(
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.BorderColor),
        color: Colors.black,
      ),
      child: Column(
        children: [
          Text(
            "x${item.factor} for ${item.hours}h",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 70.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/Images/Rectangle 2508.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/level/coinshape2.svg',
                          height: 16.h,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'x${item.factor}',
                          style: GoogleFonts.notoSans(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: -12.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/icons/Time.svg",
                          color: Colors.white,
                          height: 8.h,
                        ),
                        Text(
                          "${item.hours}h",
                          style: GoogleFonts.notoSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          Obx(() {
            final isActive =
                controller.activeMultiplier1.value?.productId == item.productId;

            return GestureDetector(
              onTap: () {
                if (isActive) return;
                showPurchaseSheet(context, item: item);
                controller.pointMultiplierItem = item;
              },
              child: Obx(() {
                final loading = controller.buying.contains(item.productId);
                return Container(
                  height: 27.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isActive ? Colors.green : Color(0xffF8AC00),
                      width: 0.5,
                    ),
                  ),
                  child:
                      loading
                          ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            isActive
                                ? "Current"
                                : controller.displayPriceFor(
                                  appleProductId: item.appleProductId,
                                  googleProductId: item.googleProductId,
                                  fallbackPriceUsd: item.priceUsd,
                                ),
                            style: GoogleFonts.notoSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : Colors.white,
                            ),
                          ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  /* ═══════════ bundle card ═══════════ */
  Widget _bundleCard(
    BuildContext context,
    BundleModel item,
    ShopClothsController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.BorderColor),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${compactNumber(item.points)} Points",
            style: GoogleFonts.notoSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 70.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/Images/rectengle2.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/level/coinshape2.svg',
                          height: 16.h,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          compactNumber(item.points),
                          style: GoogleFonts.notoSans(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          GestureDetector(
            onTap: () {
              showPurchaseBundle(context, item: item);
            },
            child: Container(
              height: 28.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFFFB74D), width: 0.5),
              ),
              child: Text(
                controller.displayPriceFor(
                  appleProductId: item.appleProductId,
                  googleProductId: item.googleProductId,
                  fallbackPriceUsd: item.priceUsd,
                ),
                style: GoogleFonts.notoSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ═══════════ invite banner ═══════════ */
  Widget _inviteBanner() => Container(
    margin: EdgeInsets.symmetric(horizontal: 15.w),
    height: 160.h,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r)),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Image.asset(
            'assets/Images/inviteBackground.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        // Content on top
        Container(
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.black.withOpacity(0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              Text(
                'Get More Points',
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Invite friends to climb the leaderboard',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/level/coinshape2.svg',
                    height: 16.h,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '50',
                    style: GoogleFonts.notoSans(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '  Each new signup',
                    style: GoogleFonts.notoSans(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: 110.w,
                height: 20.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    await controller.fetchReferralLink();
                    controller.shareReferral('', Get.context);
                  },
                  child: Text(
                    'Invite Friends',
                    style: GoogleFonts.notoSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /* ═══════════ App Store–style modal bottom sheet (Multiplier) ═══════════ */
  void showPurchaseSheet(
    BuildContext context, {
    required PointMultiplier item,
  }) {
    controller.isPurchaseSheetOpen = true;
    showModalBottomSheet(
      // isScrollControlled: true,
      // backgroundColor: Colors.transparent,
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
                                    'Points',
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
                        // const Divider(height: 1, color: Color(0xFFE6E6EA)),
                        // SizedBox(height: 10.h),
                        Text(
                          controller.displayPriceFor(
                            appleProductId: item.appleProductId,
                            googleProductId: item.googleProductId,
                            fallbackPriceUsd: item.priceUsd,
                          ),
                          style: GoogleFonts.notoSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // const Divider(height: 1, color: Color(0xFFE6E6EA)),
                        // SizedBox(height: 8.h),
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

                // Purchase button (Container version) — uses _buying & activeMultiplier1
                Obx(() {
                  final loading = controller.buying.contains(item.productId);
                  return GestureDetector(
                    onTap:
                        loading
                            ? null
                            : () async {
                              controller.buyMultiplexer(item);
                            },
                    child: Container(
                      width: 150.w,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child:
                          loading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Purchase',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  );
                }),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => controller.isPurchaseSheetOpen = false);
  }

  /* ═══════════ App Store–style modal bottom sheet (Bundle) ═══════════ */
  void showPurchaseBundle(BuildContext context, {required BundleModel item}) {
    controller.bundleModel = item;
    controller.isPurchaseSheetOpen = true;
    showModalBottomSheet(
      // isScrollControlled: true,
      // backgroundColor: Colors.transparent,
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
                            color: AppColors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
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
                                    '${compactNumber(item.points)} Points',
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
                        // const Divider(height: 1, color: Color(0xFFE6E6EA)),
                        // SizedBox(height: 10.h),
                        Text(
                          controller.displayPriceFor(
                            appleProductId: item.appleProductId,
                            googleProductId: item.googleProductId,
                            fallbackPriceUsd: item.priceUsd,
                          ),
                          style: GoogleFonts.notoSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // const Divider(height: 1, color: Color(0xFFE6E6EA)),
                        // SizedBox(height: 8.h),
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
                              // 'Johndoe@email.com',
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

                // Purchase button — uses _buying & purchasedBundles
                Obx(() {
                  final loading = controller.buying.contains(item.productId);
                  return GestureDetector(
                    onTap:
                        loading
                            ? null
                            : () async {
                              controller.buyPoints(item);
                            },
                    child: Container(
                      width: 150.w,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child:
                          loading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Purchase',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  );
                }),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => controller.isPurchaseSheetOpen = false);
  }
}
