import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/MyProfile/myProfile.dart';
import 'package:outspot/Views/Notification1/notification2.dart';
import 'package:outspot/Views/Notification1/notification_controller.dart';
import 'package:outspot/Views/Notification1/request2.dart';

class Notification1 extends GetView<Notification1Controller> {
  const Notification1({super.key});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: 12.w,
                        left: 18.w,
                        top: 8.h,
                        bottom: 8.h,
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
                    child: _NotificationTabBar(
                      tabController: controller.tabController,
                    ),
                  ),
                ],
              ),

              // Divider(height: 1.h, color: Colors.grey.shade300),
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [Notification2Screen(), Requests2()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTabBar extends StatefulWidget {
  final TabController tabController;

  const _NotificationTabBar({required this.tabController});

  @override
  State<_NotificationTabBar> createState() => _NotificationTabBarState();
}

class _NotificationTabBarState extends State<_NotificationTabBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.tabController.index;
    widget.tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    final newIndex = widget.tabController.index;
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: widget.tabController,
      onTap: (index) {
        FocusScope.of(context).unfocus();
      },
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.bgGradientTop,
      indicatorWeight: 2.w,
      indicatorSize: TabBarIndicatorSize.tab,
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 220),
                tween: ColorTween(
                  end: _selectedIndex == 0 ? Colors.white : Colors.grey,
                ),
                builder: (context, color, _) => SvgPicture.asset(
                  'assets/svg/icons/notification.svg',
                  height: 14.h,
                  width: 14.w,
                  color: color,
                ),
              ),
              SizedBox(width: 4.w),
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 220),
                tween: ColorTween(
                  end: _selectedIndex == 0 ? Colors.white : Colors.grey,
                ),
                builder: (context, color, _) => Text(
                  'Notifications',
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 220),
                tween: ColorTween(
                  end: _selectedIndex == 1 ? Colors.white : Colors.grey,
                ),
                builder: (context, color, _) => SvgPicture.asset(
                  'assets/svg/icons/request.svg',
                  height: 18.h,
                  color: color,
                ),
              ),
              SizedBox(width: 5.w),
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 220),
                tween: ColorTween(
                  end: _selectedIndex == 1 ? Colors.white : Colors.grey,
                ),
                builder: (context, color, _) => Text(
                  'Requests',
                  style: GoogleFonts.notoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
