import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/MyProfile/miniMeUpdated.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/waredrop/waredrop_controller.dart';

/// Mini-Me picker opened from the wardrobe. Shows the user's locker (all their
/// created/bought avatars) and lets them switch the active one — the same flow
/// as MyProfile → My Locker, so behaviour stays identical.
class MinimeLockerScreen extends StatelessWidget {
  MinimeLockerScreen({super.key});

  // Reuse the profile controller — it owns the locker list and the avatar-apply
  // logic that Minimeupdated talks to.
  final MyProfileController controller =
      Get.isRegistered<MyProfileController>()
          ? Get.find<MyProfileController>()
          : Get.put(MyProfileController());

  @override
  Widget build(BuildContext context) {
    // Refresh the locker each time the picker opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchLockerItems();
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: EdgeInsets.all(15.w),
            child: SvgPicture.asset(
              'assets/svg/icons/back_icon.svg',
              color: Colors.white,
              height: 20.h,
            ),
          ),
        ),
        title: Text(
          "Choose Mini-Me",
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
            stops: const [0.2, 0.6],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xffBE5BD5)),
              );
            }
            if (controller.lockerItems.isEmpty) {
              return Center(
                child: Text(
                  "Your Locker is empty",
                  style: GoogleFonts.notoSans(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              );
            }
            return GridView.builder(
              padding: EdgeInsets.all(8.w),
              itemCount: controller.lockerItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                childAspectRatio: 0.5,
              ),
              itemBuilder: (context, index) {
                final item = controller.lockerItems[index];
                return _lockerItem(
                  item['avatarUrl'] ?? '',
                  minimeId: item['id'] as int?,
                  // First item = most-recently-used (active) avatar.
                  isRecent: index == 0,
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _lockerItem(String imageUrl, {int? minimeId, bool isRecent = false}) {
    const recentGreen = Color(0xff42D880);
    return GestureDetector(
      onTap: () async {
        if (imageUrl.isEmpty) return;
        final updatedImage = await Get.to<String>(
          () => Minimeupdated(imagePath: imageUrl, minimeId: minimeId),
        );
        if (updatedImage != null && updatedImage.isNotEmpty) {
          controller.updateAvatarLocal(updatedImage);
          controller.fetchLockerItems();
          // Refresh the wardrobe preview so the newly-selected base avatar
          // shows there too.
          if (Get.isRegistered<WaredropController>()) {
            Get.find<WaredropController>().loadUserProfile();
          }
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              // border: Border.all(color: AppColors.black, width: 1),
              color:Colors.transparent,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => const ShimmerPlaceholder(radius: 0),
              errorWidget:
                  (context, url, error) =>
                      const Center(child: Icon(Icons.broken_image)),
            ),
          ),
          if (isRecent)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: recentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
