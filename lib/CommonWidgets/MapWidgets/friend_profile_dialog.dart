import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Model/friendLocation.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/utils/routes.dart';

class FriendProfileDialog extends StatelessWidget {
  final FriendLocation friend;

  const FriendProfileDialog({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    // Big avatar dimensions
    final double bigAvatarSize = 170.w;
    // How much the card is pushed down so the big avatar overlaps its top.
    final double cardTopBase = bigAvatarSize / 2.5;
    // Big avatar sits a bit above the card's top edge.
    final double bigAvatarTop = -90.h;

    // Sits in the lower part of the screen (above the bottom nav), not centered.
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: 15.w,
            right: 15.w,
            top: bigAvatarSize, // room for the avatar overflowing the card top
            bottom: MediaQuery.of(context).padding.bottom + 60.h,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Card content
              Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.only(top: cardTopBase),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xff2D0731),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small circular avatar inside card
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: friend.avatarUrl,
                          alignment: Alignment.topCenter,
                          width: 70.w,
                          height: 65.h,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const ShimmerPlaceholder(),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    // Name
                    Text(
                      "${friend.firstName} ${friend.lastName}",
                      style: GoogleFonts.notoSans(
                        fontSize: 23.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Username
                    Text(
                      "@${friend.username}",
                      style: GoogleFonts.notoSans(
                        fontSize: 15.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Divider(thickness: 0.7, color: Colors.grey),
                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            "Overall",
                            compactNumber(friend.totalPoints),
                            "assets/svg/level/coinshape1.svg",
                          ),
                          _buildStatColumn(
                            "This Week",
                            compactNumber(friend.thisWeekPoints),
                            "assets/svg/level/coinshape2.svg",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    _buildActionButtons(context),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              // Big avatar on top
              Positioned(
                top: bigAvatarTop,
                child: CachedNetworkImage(
                  imageUrl: friend.avatarUrl,
                  width: bigAvatarSize,
                  height: bigAvatarSize,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder:
                      (context, url) => ShimmerPlaceholder(
                        width: bigAvatarSize,
                        height: bigAvatarSize,
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        width: bigAvatarSize,
                        height: bigAvatarSize,
                        color: Colors.grey,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                ),
              ),
              // X close button — top-right corner of the card.
              Positioned(
                top: cardTopBase + 20,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    "assets/svg/icons/cross_withOverlay.svg",
                    height: 30,
                    width: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, String coinImage) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(coinImage, height: 20.h),
            SizedBox(width: 5),
            Text(
              " $value",
              style: GoogleFonts.notoSans(
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () {
              final FriendsModel friendData = _toFriendsModel(friend);
              // Close the dialog first so it doesn't reappear when returning
              // from the profile screen to the map.
              Navigator.of(context).pop();
              Get.toNamed(Routes.friendsProfile, arguments: friendData);
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff704EF9),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 23.w, vertical: 12.h),
              child: Text(
                "View Profile",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 15.w),
        // Chat Button
        GestureDetector(
          onTap: () {
            // Close the dialog first so it doesn't reappear on return.
            Navigator.of(context).pop();
            Get.toNamed(
              Routes.directMessageScreen,
              arguments: {"Id": friend.userId},
            );
          },
          child: _roundIcon(
            'assets/svg/icons/Icon-Outline-Chat.svg',
            const Color(0xffFF5555),
          ),
        ),
        SizedBox(width: 10.w),
        // Camera Button
        GestureDetector(
          onTap: () {
            Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 2});
          },
          child: _roundIcon(
            'assets/svg/icons/Icon-Outline-Camera.svg',
            const Color(0xffF8AC00),
          ),
        ),
      ],
    );
  }

  Widget _roundIcon(String image, Color bg) => Container(
    padding: EdgeInsets.all(15.r),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: SvgPicture.asset(
      image,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
  );

  FriendsModel _toFriendsModel(FriendLocation friend) {
    return FriendsModel(
      id: friend.userId,
      username: friend.username,
      firstName: friend.firstName,
      lastName: friend.lastName,
      avatarUrl: friend.avatarUrl,
      totalPoints: friend.totalPoints,
      thisWeekPoints: friend.thisWeekPoints,
      profileUrl: friend.profileUrl,
    );
  }
}
