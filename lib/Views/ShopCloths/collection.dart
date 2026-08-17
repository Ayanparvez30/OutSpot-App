import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/ShopCloths/shopCloths_controller.dart';

class Collection extends GetView<ShopClothsController> {
  const Collection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /* ───────── top bar back-arrow ───────── */
      body: Column(
        children: [
          SizedBox(
            height: 260.h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                /* beach background */
                Image.asset(
                  'assets/Images/Rectangle 2503.png', // <- your bg
                  fit: BoxFit.cover,
                ),

                /* back arrow */
                Positioned(
                  top: 16.h,
                  left: 12.w,
                  child: GestureDetector(
                    onTap: Get.back,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                /* avatar in the middle */
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.h),
                    child: Image.asset(
                      'assets/Images/Screenshot 2025-05-05 at 2.03.53 PM.png', // <- your avatar
                      height: 250.h,
                    ),
                  ),
                ),

                /* red label on beach floor */
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
                        'SUMMER LOOKS COLLECTION',
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
          ),

          /* blank area – put specs / description here if needed */
          Expanded(child: Container()),

          /* ───────── bottom buy bar ───────── */
          Container(
            height: 56.h,
            margin: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
              top: 8.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: const Color(0xffF2F2F2),
            ),
            child: Row(
              children: [
                /* BUY BUTTON – purple */
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
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
                              const Icon(
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
                          Text(
                            '\$3.00 | Blue Hawaiian Shirt',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSans(
                              fontSize: 10.sp,
                              color: Colors.white.withOpacity(.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /* trash icon – red */
                GestureDetector(
                  onTap: () {},
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
          ),
        ],
      ),
    );
  }
}
