import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';

/// Open [communityId] only if the current user is a member of it (i.e. it is
/// their own community). Otherwise show a soft popup — opening a community you
/// aren't part of would be a dead-end with no feedback. Used when tapping a
/// community from someone else's stats / profile.
Future<void> openCommunityIfMember(
  int communityId, {
  String? communityName,
}) async {
  if (communityId == 0) {
    _showNotMemberPopup(communityName);
    return;
  }

  final mp = MyProfileController.instance;

  // Fast path: our cached community id already matches.
  if (communityId == mp.myCommunityId.value) {
    Get.toNamed(Routes.community, arguments: {"id": communityId});
    return;
  }

  // Cached value may not be loaded yet (e.g. we just arrived from another
  // screen, so MyProfileController hasn't fetched our community). Refresh it
  // once and re-check — this fixes the wrong "not a member" popup on the first
  // tap that then worked on the second.
  AppLoading.show();
  try {
    await mp.loadMostRecentCommunityImage();
  } catch (_) {}
  AppLoading.hide();

  if (communityId == mp.myCommunityId.value) {
    Get.toNamed(Routes.community, arguments: {"id": communityId});
  } else {
    _showNotMemberPopup(communityName);
  }
}

void _showNotMemberPopup(String? communityName) {
  final name =
      (communityName != null && communityName.trim().isNotEmpty)
          ? '"${communityName.trim()}"'
          : 'this community';

  Get.dialog(
    Dialog(
      backgroundColor: const Color(0xff2D0731),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: const Color(0xff704EF9).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: const Color(0xffC574F7),
                size: 28.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              "Members only",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "You're not a member of $name. Join the community first to view it.",
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                color: Colors.white70,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff704EF9),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  "Got it",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
