import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';

import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Views/FriendList/friends.dart';
import 'package:outspot/Views/FriendList/requests.dart';
import 'package:outspot/Views/FriendList/searchUser.dart';
import 'package:outspot/Views/MyProfile/myProfile.dart';

class FriendListScreen extends StatelessWidget {
  final FriendListController controller = Get.put(FriendListController());

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: [0, 0.4],

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
                      if (Get.previousRoute == "/nonPrivateProfile") {
                        Get.toNamed(Routes.myProfile);
                      } else {
                        Get.back();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      child: Container(
                        height: 20.h,
                        width: 20.w,
                        // color: Colors.amber,
                        child: SvgPicture.asset(
                          'assets/svg/icons/back_icon.svg',
                          height: 20.h,
                          width: 20.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: _FriendListTabBar(
                      tabController: controller.tabController,
                    ),
                  ),
                ],
              ),

              // Divider(height: 1.h, color: AppColors.bgGradientTop),

              /// ---- Shared search + Add Friend header ----
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => controller.query.value = value,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                          ),
                          hintText: "Search...",
                          hintStyle: TextStyle(color: AppColors.fillnoti),
                          suffixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/svg/icons/searchImage.svg',
                              height: 16.h,
                              width: 16.w,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide(color: AppColors.fillnoti),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide(color: AppColors.fillnoti),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.fillnoti),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () {
                        Get.to(SearchUser());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.MainColor,
                              AppColors.btnGradientLeft,
                              AppColors.btnGradientRight,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Add Friend",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            SvgPicture.asset(
                              "assets/svg/icons/plus.svg",
                              height: 18,
                              width: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// ---- TabBarView ----
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [Friends(), Requests()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendListTabBar extends StatefulWidget {
  final TabController tabController;

  const _FriendListTabBar({required this.tabController});

  @override
  State<_FriendListTabBar> createState() => _FriendListTabBarState();
}

class _FriendListTabBarState extends State<_FriendListTabBar> {
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
      dividerColor: Colors.grey,
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
                  'assets/svg/icons/friends1.svg',
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
                  'Friends',
                  style: GoogleFonts.notoSans(
                    fontSize: 18.sp,
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
