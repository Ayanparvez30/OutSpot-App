import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Views/Challenges/challenge_controller.dart';
import 'package:outspot/Views/Challenges/challenge_screen.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';
import 'package:outspot/Views/Message/camera_controller.dart';
import 'package:outspot/Views/Message/camera_screen.dart';
import 'package:outspot/Views/Explorescreen/explore.dart';
import 'package:outspot/Views/Mapscreen/map_screen.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/Message/messages_screen.dart';

class MainScreen extends GetView<MainscreeenController> {
  MainScreen({super.key});
  final Color _bgGradientTop = const Color(0xff2E0248);
  final Color _bgGradientBottom = const Color(0xff1A0B2E);
  final Color _navBarColor = const Color(0xff181818);
  final Gradient _activeGradient = const LinearGradient(
    colors: [Color(0xffAB50F6), Color(0xffFB7D6C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  final Color _inactiveIconColor = Colors.grey;

  Widget _tabBody(int index) {
    switch (index) {
      case 0:
        return GetBuilder<MessagesScreenController>(
          builder: (_) => MessagesScreen(),
        );
      case 1:
        return MapScreen();
      case 2:
        return const CameraScreen();
      case 3:
        return LazyBuilder<ChallengeController>(
          init: () => ChallengeController(),
          builder: () => const ChallengeScreen(),
        );
      case 4:
      default:
        return GetBuilder<ExploreController>(
          init: ExploreController(),
          builder: (_) => Explore(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure MessagesScreenController is always alive for unread indicator
    if (!Get.isRegistered<MessagesScreenController>()) {
      Get.put(MessagesScreenController(), permanent: true);
    }
    return Obx(
      () => Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgGradientTop, _bgGradientBottom],
            ),
          ),
          child: Stack(
            children: [
              _tabBody(controller.tabIndex.value),
              // Hide the bottom nav while a map route is active (the route-info
              // sheet takes over the bottom of the screen).
              Positioned(
                // Lift the floating nav bar above the system navigation bar
                // (3-button / gesture inset) so it never overlaps it.
                bottom: 25.h,
                left: 10.w,
                right: 10.w,
                child:
                    Get.isRegistered<MapController>()
                        ? Obx(
                          () =>
                              Get.find<MapController>()
                                          .currentRouteInfo
                                          .value !=
                                      null
                                  ? const SizedBox.shrink()
                                  : _buildCustomBottomNavBar(),
                        )
                        : _buildCustomBottomNavBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.r),
      child: Container(
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: _navBarColor,
          borderRadius: BorderRadius.circular(40.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
              _buildNavItem(
                imagePath: 'assets/svg/icons/chats_icon.svg',
                label: 'Chat',
                index: 0,
                // imagePath: 'assets/Images/skchatt.png',
              ),
              _buildNavItem(
                imagePath: 'assets/svg/icons/camera_icon.svg',
                label: 'Camera',
                index: 2,
                // imagePath: 'assets/Images/skcameraa.png',
              ),

              // 3. Center Button (Explore/Community) - Index 4
              // এটি মাঝখানের বড় পিংক বাটন
              _buildCenterButton(index: 4),

              // 4. Map (Index 1) - ইমেজে এটি ডান পাশে
              _buildNavItem(
                imagePath: 'assets/svg/icons/mapTab_icon.svg',
                label: 'Map',
                index: 1,
                // imagePath: 'assets/Images/skmap.png',
              ),

              // 5. Challenges (Index 3)
              _buildNavItem(
                imagePath:
                    'assets/svg/icons/challengeTab_icon.svg', // অথবা star/trophy
                label: 'Challenges',
                index: 3,
                // imagePath: 'assets/Images/skaidss.png',
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    IconData? iconData,
    String? imagePath,
    double scale = 1.0,
  }) {
    final isSelected = controller.tabIndex.value == index;

    // ১. আইকন উইজেট তৈরি
    Widget iconWidget =
        imagePath != null
            ? SvgPicture.asset(
              imagePath,
              height: 22.h,
              width: 22.w,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : _inactiveIconColor,
                BlendMode.srcIn,
              ),
            )
            : Icon(
              iconData,
              size: 26.sp,
              color: isSelected ? Colors.white : _inactiveIconColor,
            );
    Widget textWidget = Text(
      label,
      style: GoogleFonts.notoSans(
        fontSize: 10.sp,

        color: isSelected ? Colors.white : _inactiveIconColor,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
      ),
    );

    Widget finalIconWidget =
        isSelected
            ? ShaderMask(
              shaderCallback: (Rect bounds) {
                return _activeGradient.createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: iconWidget,
            )
            : iconWidget;

    // Add unread indicator for Chat tab (index 0)
    if (index == 0 && Get.isRegistered<MessagesScreenController>()) {
      final msgCtrl = Get.find<MessagesScreenController>();
      final baseIcon = finalIconWidget; // capture before reassigning
      finalIconWidget = Obx(
        () => Stack(
          clipBehavior: Clip.none,
          children: [
            baseIcon,
            if (msgCtrl.hasUnread.value)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 10.w,
                  height: 10.h,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleTabChange(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          finalIconWidget,

          SizedBox(height: 4.h),

          isSelected
              ? ShaderMask(
                shaderCallback: (Rect bounds) {
                  return _activeGradient.createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: textWidget,
              )
              : textWidget,
        ],
      ),
    );
  }

  Widget _buildCenterButton({required int index}) {
    final isSelected = controller.tabIndex.value == index;
    return GestureDetector(
      onTap: () => _handleTabChange(index),
      child: Container(
        height: 50.h,
        width: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xffAB50F6), Color(0xffFB7D6C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffDA5EF3).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border:
              isSelected ? Border.all(color: Colors.redAccent, width: 2) : null,
        ),
        // child: Icon(Icons.groups_rounded, color: Colors.white, size: 28.sp),
        child: UnconstrainedBox(
          child: SvgPicture.asset(
            "assets/svg/icons/exploreTab_icon.svg",
            width: 25.r,
            height: 25.r,
            // fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }

  void _handleTabChange(int i) {
    final prev = controller.tabIndex.value;
    controller.changeTab(i);
  if (i == 3 && Get.isRegistered<ChallengeController>()) {
    Get.find<ChallengeController>().fetchChallengeCards();
  }
    if (prev == 2 && i != 2 && Get.isRegistered<CameraControllers>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final cam = Get.find<CameraControllers>();
        await cam.safeRelease();
      });
    }
  }
}

class LazyBuilder<T extends GetxController> extends StatelessWidget {
  final Widget Function() builder;
  final T Function()? init;

  const LazyBuilder({super.key, required this.builder, this.init});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<T>() && init != null) {
      Get.lazyPut<T>(() => init!());
    }
    return builder();
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:outspot/Views/Challenges/challenge_controller.dart';
// import 'package:outspot/Views/Challenges/challenge_screen.dart';
// import 'package:outspot/Views/Explorescreen/explore_controller.dart';
// import 'package:outspot/Views/Message/camera_controller.dart';
// import 'package:outspot/Views/Message/camera_screen.dart';
// import 'package:outspot/Views/Explorescreen/explore.dart';
// import 'package:outspot/Views/Mapscreen/map_screen.dart';
// import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
// import 'package:outspot/Views/Message/messages_screen_controller.dart';
// import 'package:outspot/Views/Message/messages_screen.dart';

// class MainScreen extends GetView<MainscreeenController> {
//   MainScreen({super.key});

//   Widget _tabBody(int index) {
//     switch (index) {
//       case 0:
//         return GetBuilder<MessagesScreenController>(
//           init: MessagesScreenController(),
//           builder: (_) => MessagesScreen(),
//         );

//       case 1:
//         return MapScreen();
//       case 2:
//         return GetBuilder<CameraControllers>(
//           init: CameraControllers(),
//           autoRemove: true,
//           builder: (_) => const CameraScreen(),
//         );
//       // case 3:
//       //   return GetBuilder<ChallengeController>(
//       //     init: ChallengeController(),
//       //     builder: (_) => ChallengeScreen(),
//       //   );
//       case 3:
//         return LazyBuilder<ChallengeController>(
//           init: () => ChallengeController(),
//           builder: () => const ChallengeScreen(),
//         );

//       case 4:
//       default:
//         return GetBuilder<ExploreController>(
//           init: ExploreController(),
//           builder: (_) => Explore(),
//         );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(
//       () => Scaffold(
//         body: _tabBody(controller.tabIndex.value),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: controller.tabIndex.value,
//           onTap: (i) async {
//             final prev = controller.tabIndex.value;

//             controller.changeTab(i);

//             if (prev == 2 && i != 2 && Get.isRegistered<CameraControllers>()) {
//               WidgetsBinding.instance.addPostFrameCallback((_) async {
//                 final cam = Get.find<CameraControllers>();
//                 await cam.safeRelease();
//               });
//             }
//           },
//           selectedItemColor: _getSelectedColor(controller.tabIndex.value),
//           unselectedItemColor: const Color(0xff000000),
//           selectedLabelStyle: TextStyle(
//             color: _getSelectedColor(controller.tabIndex.value),
//             shadows: const [
//               Shadow(
//                 color: Color(0xffFFFFFF),
//                 blurRadius: 4,
//                 offset: Offset(4, 4),
//               ),
//             ],
//           ),
//           type: BottomNavigationBarType.fixed,
//           items: [
//             _buildNavItem(
//               'assets/Images/skchatt.png',
//               'Chat',
//               0,
//               controller.tabIndex.value,
//             ),
//             _buildNavItem(
//               'assets/Images/skmap.png',
//               'Map',
//               1,
//               controller.tabIndex.value,
//             ),
//             _buildNavItem(
//               'assets/Images/skcameraa.png',
//               'Camera',
//               2,
//               controller.tabIndex.value,
//             ),
//             _buildNavItem(
//               'assets/Images/skaidss.png',
//               'Challenges',
//               3,
//               controller.tabIndex.value,
//             ),
//             _buildNavItem(
//               'assets/Images/skexpolor.png',
//               'Explore',
//               4,
//               controller.tabIndex.value,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   BottomNavigationBarItem _buildNavItem(
//     String assetPath,
//     String label,
//     int index,
//     int currentIndex,
//   ) {
//     final isSelected = index == currentIndex;
//     return BottomNavigationBarItem(
//       icon: ColorFiltered(
//         colorFilter: ColorFilter.mode(
//           isSelected ? _getSelectedColor(index) : Color(0xff000000),
//           BlendMode.srcIn,
//         ),
//         child: Image.asset(assetPath, height: 35.h, width: 20.w),
//       ),
//       label: label,
//     );
//   }

//   Color _getSelectedColor(int index) {
//     switch (index) {
//       case 0:
//         return Color(0xffDD4141); // Chat
//       case 1:
//         return Color(0xff6677FC); // Map
//       case 2:
//         return Color(0xff66CCFC); // Camera
//       case 3:
//         return Color(0xffF8AC00);
//       default:
//         return Color(0xff42D880);
//     }
//   }
// }

// class LazyBuilder<T extends GetxController> extends StatelessWidget {
//   final Widget Function() builder;
//   final T Function()? init;

//   const LazyBuilder({super.key, required this.builder, this.init});

//   @override
//   Widget build(BuildContext context) {
//     if (!Get.isRegistered<T>() && init != null) {
//       Get.lazyPut<T>(() => init!());
//     }
//     return builder();
//   }
// }
