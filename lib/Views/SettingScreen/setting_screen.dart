import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/SettingNotification/SettingNotification_controller.dart';
import 'setting_controller.dart';

class SettingScreen extends GetView<SettingController> {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SettingnotificationController());
    controller.onInit();
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
            'Settings',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 15.h),
                child: ListView(
                  controller: controller.scrollController,
                  children: [
                    customBuildSection(
                      // imagePadding: EdgeInsets.only(left: 14.w),
                      imagePath: "assets/svg/icons/setting_person_icon.svg",
                      title: "My Account",
                      items: ["Password", "My Name", "My Username", "Bio"],
                      showTopDivider: false,
                    ),
                    customBuildSection(
                      imagePath: "assets/svg/icons/visibility_icon.svg",
                      title: "Visibility & Security",
                      items: [
                        "Profile Visibility",
                        // "Map Visibility",
                        // "PIN",
                        // "Face ID",
                        "Blocked Accounts",
                      ],
                    ),
                    customBuildSection(
                      imagePath: "assets/svg/icons/Color_notification_icon.svg",
                      title: "Notifications",
                    ),
                    customBuildSection(
                      imagePath: "assets/svg/icons/support_icon.svg",
                      title: "Support",
                      items: ["Contact Us"],
                    ),
                    customBuildSection(
                      imagePath: "assets/svg/icons/legal_icon.svg",
                      title: "Legal",
                      items: ["Privacy Policy", "Terms & Agreements"],
                    ),
                    customBuildSection(
                      imagePath: "assets/svg/icons/logOut_icon.svg",
                      title: "Log Out",
                      items: ["Delete My Account"],
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),

              Obx(() {
                return controller.showDownArrow.value
                    ? Positioned(
                      bottom: 15.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: controller.scrollDown,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            padding: EdgeInsets.all(8.r),
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.white,
                              size: 25.r,
                            ),
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget customBuildSection({
    required String imagePath,
    String? title,
    List<String> items = const [],
    bool showTopDivider = true,
    EdgeInsets? imagePadding,
    EdgeInsets? contentPadding,
  }) {
    final isLogout = title == "Log Out";
    final isNotification = title == "Notifications";

    Widget imageWidget = SvgPicture.asset(imagePath, width: 24.r, height: 24.r);

    if (imagePadding != null) {
      imageWidget = Padding(padding: imagePadding, child: imageWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTopDivider)
          const Divider(
            height: 24,
            thickness: 0.5,
            color: AppColors.bgGradientTop,
          ),

        InkWell(
          onTap:
              (isLogout || isNotification) && title != null
                  ? () => controller.handleTap(title)
                  : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 3, bottom: 8),
            child: Row(
              children: [
                imageWidget,
                const SizedBox(width: 19),
                if (title != null && title.isNotEmpty)
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                  )
                else
                  const Spacer(),

                if (isLogout || isNotification)
                  UnconstrainedBox(
                    child: SvgPicture.asset(
                      "assets/svg/icons/arrow_forward_icon.svg",
                      width: 22.r,
                      height: 22.r,
                    ),
                  ),
              ],
            ),
          ),
        ),

        ...items.map(
          (item) => ListTile(
            contentPadding:
                contentPadding ?? const EdgeInsets.only(left: 46, right: 16),
            visualDensity: VisualDensity(vertical: -3),
            dense: true,
            minVerticalPadding: 0,
            horizontalTitleGap: 0,

            title: Text(
              item,
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: AppColors.white,
              ),
            ),
            trailing: UnconstrainedBox(
              child: SvgPicture.asset(
                "assets/svg/icons/arrow_forward_icon.svg",
                width: 22.r,
                height: 22.r,
              ),
            ),
            onTap: () {
              controller.handleTap(item);
            },
          ),
        ),
      ],
    );
  }

  void showModalBottomSheetFunctionProfileOptions2(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor:
          Colors.transparent, // transparent bg to show margin space
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            left: 15.w,
            right: 15.w,
            bottom: 15.h,
          ), // space around the sheet
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 2.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Profile Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),

                /// Chat Settings
                GestureDetector(
                  onTap: () async {
                    // Bottom sheet আগে বন্ধ করা
                    Get.back();

                    // তারপর API call
                    await controller.updateProfilePrivacy(true);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "private account",
                        style: TextStyle(
                          color: Color(0xff66CCFC),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
