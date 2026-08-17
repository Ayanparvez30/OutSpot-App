import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/ShopCloths/clothingShop.dart';
import 'package:outspot/Views/ShopCloths/pointShop.dart';
import 'package:outspot/Views/ShopCloths/shopCloths_controller.dart';

class ShopCloths extends GetView<ShopClothsController> {
  const ShopCloths({super.key});

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

        body: SafeArea(
          // Run content to the bottom edge (like Explore) so there's no empty
          // "dead space" strip at the bottom.
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 8.h,
                      ),
                      child: SvgPicture.asset(
                        'assets/svg/icons/back_icon.svg',
                        height: 20.h,
                        width: 20.w,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Expanded(
                    child: AnimatedBuilder(
                      animation: controller.tabController,
                      builder: (context, _) {
                        final selectedIndex = controller.tabController.index;
                        return TabBar(
                          controller: controller.tabController,
                          onTap: (index) {
                            FocusScope.of(context).unfocus();
                          },
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color.fromARGB(
                            255,
                            136,
                            135,
                            135,
                          ),
                          indicatorColor: AppColors.bgGradientTop,
                          indicatorWeight: 2.w,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.grey,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svg/icons/wordrobe.svg',
                                    height: 10.h,
                                    width: 10.w,
                                    color:
                                        controller.tabController.index == 0
                                            ? Colors.white
                                            : Colors.grey,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Clothing Shop',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      // color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svg/level/coinshape2.svg',
                                    height: 18.h,
                                    color:
                                        controller.tabController.index == 1
                                            ? Colors.white
                                            : Colors.grey,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    'Point Shop',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      // color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Divider(height: 1.h, color: Colors.grey.shade300),
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [Clothingshop(), PointShop()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
