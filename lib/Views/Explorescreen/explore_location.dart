import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';

class ExploreLocation extends GetView<ExploreController> {
  const ExploreLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: SvgPicture.asset(
            "assets/svg/icons/back_icon.svg",
            width: 25.r,
            height: 25.r,
          ),

          padding: EdgeInsets.all(8.w),
          constraints: const BoxConstraints(),
        ),

        title: Text(
          'Rooftop Bars',
          style: GoogleFonts.notoSans(
            color: Color(0xff000000),
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xffFFFFFF),
      ),
      body: ListView.builder(
        itemCount: controller.bars.length,

        itemBuilder: (context, index) {
          return Container(
            color: Color(0xffFFFFFF),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 2.h,
                    horizontal: 16.w,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2.w,
                            color: Color(0xff6677FC),
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage('assets/bar_image.png'),
                          radius: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        controller.bars[index],
                        style: GoogleFonts.notoSans(
                          color: Color(0xff000000),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Container(
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
                          borderRadius: BorderRadius.circular(15.sp),
                        ),
                        child: Row(
                          children: [
                            Image.asset("assets/Images/skcoin.png", scale: 3),
                            SizedBox(width: 2),
                            Text(
                              "4",
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  indent: 18.w,
                  endIndent: 0,
                  thickness: 1,
                  color: Colors.grey[300],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
