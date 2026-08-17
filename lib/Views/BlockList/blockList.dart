import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/BlockList/blockList_controller.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:shimmer/shimmer.dart';

class Blocklist extends GetView<BlocklistController> {
  const Blocklist({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: const [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            color: Colors.white,
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
            'Blocked Users',
            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      child: ListTile(
                        leading: Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.5),
                          child: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        title: Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.5),
                          child: Container(
                            height: 16.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                        trailing: Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.5),
                          child: Container(
                            width: 80.w,
                            height: 35.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index != 7)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Divider(
                          color: const Color(
                            0xffF4F4F4,
                          ).withOpacity(0.2), // Shimmer divider
                          height: 3.h,
                        ),
                      ),
                  ],
                );
              },
            );
          }

          final userList = controller.users;

          if (userList.isEmpty) {
            return Center(
              child: Text(
                "Empty block list",
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    child: ListTile(
                      leading: Builder(
                        builder: (_) {
                          final avatar = (user.avatarUrl ?? '').trim();
                          final initial =
                              user.firstName.isNotEmpty
                                  ? user.firstName[0].toUpperCase()
                                  : '?';

                          if (avatar.isEmpty) {
                            return CircleAvatar(
                              radius: 20.r,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            );
                          }

                          const double zoom = 1.7;

                          return SizedBox(
                            width: 40.r,
                            height: 40.r,
                            child: ClipOval(
                              child: Transform.scale(
                                scale: zoom,
                                alignment: Alignment.topCenter,
                                child: CachedNetworkImage(
                                  imageUrl: avatar,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  filterQuality: FilterQuality.high,
                                  placeholder:
                                      (context, url) =>
                                          const ShimmerPlaceholder(),
                                  errorWidget:
                                      (context, url, error) => CircleAvatar(
                                        radius: 20.r,
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // CircleAvatar(
                      //   radius: 20.r,
                      //   child: Icon(Icons.person, size: 24.sp),
                      // ),
                      title: Text(
                        "${user.firstName} ${user.lastName}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: AppColors.white,
                        ),
                      ),

                      // subtitle: Text("@${user.username}"),
                      trailing: ElevatedButton(
                        onPressed: () {
                          controller.unblockUser(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.4),
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Unblock"),
                      ),
                    ),
                  ),
                  if (index != userList.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Divider(
                        color: const Color(0xffF4F4F4),
                        height: 3.h,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}
