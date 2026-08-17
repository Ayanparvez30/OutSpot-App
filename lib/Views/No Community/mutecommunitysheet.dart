// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:outspot/Utils/colors.dart';
// import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';

// class CommunityOptionsSheet {
//   // --- বটম শিট দেখানোর ফাংশন ---
//   static void showOptions({required BuildContext context, required int communityId}) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       builder: (context) => Container(
//         margin: EdgeInsets.all(15.w),
//         decoration: BoxDecoration(
//           color: const Color(0xff323434),
//           borderRadius: BorderRadius.circular(16.r),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(height: 15.h),
//             Text("Community Options", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
//             const Divider(color: Colors.black54),

//             // লিভ বাটন
//             ListTile(
//               title: Center(
//                 child: Text("Leave Community", style: TextStyle(color: const Color(0xffDD4141), fontWeight: FontWeight.bold)),
//               ),
//               onTap: () {
//                 Get.back(); // শিট বন্ধ হবে
//                 showLeaveConfirmDialog(communityId); // কনফার্মেশন ডায়ালগ আসবে
//               },
//             ),
//             SizedBox(height: 10.h),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- কনফার্মেশন ডায়ালগ (সিঙ্গেলটোন স্টাইল) ---
//   static void showLeaveConfirmDialog(int commId) {
//     final controller = Get.find<DirectmassagescreenController>();

//     Get.generalDialog(
//       barrierDismissible: true,
//       barrierLabel: "Leave",
//       pageBuilder: (ctx, anim1, anim2) => Align(
//         alignment: const Alignment(0, -0.5),
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             margin: EdgeInsets.all(25.w),
//             padding: EdgeInsets.all(20.w),
//             decoration: BoxDecoration(
//               color: const Color(0xff2D0731),
//               borderRadius: BorderRadius.circular(15.r),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text("Leave Community?", style: GoogleFonts.notoSans(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
//                 SizedBox(height: 12.h),
//                 Text("Are you sure? You won't see this chat anymore.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
//                 SizedBox(height: 25.h),

//                 // কনফার্ম বাটন
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffDD4141), minimumSize: Size(double.infinity, 45.h)),
//                   onPressed: () {
//                     Get.back(); // ডায়ালগ বন্ধ
//                     controller.leaveCommunityLogic(commId); // কন্ট্রোলারের লজিক কল
//                   },
//                   child: const Text("Yes, Leave Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                 ),

//                 TextButton(
//                   onPressed: () => Get.back(),
//                   child: const Text("Nevermind", style: TextStyle(color: Colors.white54)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';

class CommunityOptionsSheet {
  // --- বটম শিট দেখানোর ফাংশন ---
  static void showOptions({
    required BuildContext context,
    required int communityId,
  }) {
    final controller = Get.find<DirectmassagescreenController>();

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder:
          (context) => Container(
            margin: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: const Color(0xff323434),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 15.h),
                Text(
                  "Community Options",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                const Divider(color: Colors.black54),

                // 🔥 মিউট / আনমিউট বাটন
                Obx(
                  () => ListTile(
                    title: Center(
                      child: Text(
                        controller.isMuted.value ? "Unmute Chat" : "Mute Chat",
                        style: GoogleFonts.notoSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    onTap: () {
                      Get.back(); // শিট বন্ধ হবে
                      controller.toggleMute(
                        communityId,
                      ); // কন্ট্রোলারের মিউট লজিক কল
                    },
                  ),
                ),

                SizedBox(height: 10.h),
              ],
            ),
          ),
    );
  }
}
