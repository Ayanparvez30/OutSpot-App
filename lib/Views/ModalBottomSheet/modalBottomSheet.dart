import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Views/FriendsProfile/friends_profile_controller.dart';
import 'package:outspot/Views/ModalBottomSheet/modalBottomSheet_controller.dart';
import 'package:outspot/CommonWidgets/send_to_sheet.dart';

class Modalbottomsheet extends GetView<ModalbottomsheetController> {
  const Modalbottomsheet({super.key});
  void showModalBottomSheetFunctionProfileOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor: Colors.transparent,
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
                /// Title
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

                /// Share Profile
                GestureDetector(
                  onTap: () {
                    // // Close the bottom sheet first
                    // Navigator.pop(context);

                    // // Share logic
                    // final String mediaUrl =
                    //     ""; // friend username or profile URL
                    // Share.share('Check out this profile! $mediaUrl');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Share Profile",
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

                /// Block User
                GestureDetector(
                  onTap: () {
                    // Block logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Block User",
                        style: TextStyle(
                          color: Color(0xffDD4141),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),

                /// Report User
                GestureDetector(
                  onTap: () {
                    // Report logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Report User",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Chat Settings",
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

                /// Share Profile
                GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Share Profile",
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

                /// Block User
                GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Block User",
                        style: TextStyle(
                          color: Color(0xffDD4141),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),

                /// Report User
                GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Report User",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showModalBottomSheetFunctionGroupOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor: Colors.transparent,
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
                    "Group Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),

                /// Edit Group Details
                GestureDetector(
                  onTap: () {
                    // Edit Group Details logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Edit Group Details",
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

                /// Lock Chat
                GestureDetector(
                  onTap: () {
                    // Lock Chat logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Lock Chat",
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

                /// Mute Chat
                GestureDetector(
                  onTap: () {
                    // Mute Chat logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Mute Chat",
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

                /// Leave Group
                GestureDetector(
                  onTap: () {
                    // Leave Group logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Leave Group",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showModalBottomSheetFunctionCommunityOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor: Colors.transparent,
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
                    "Community Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),

                /// Lock Chat
                GestureDetector(
                  onTap: () {
                    // Lock Chat Logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Lock Chat",
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

                /// Unmute Chat
                GestureDetector(
                  onTap: () {
                    // Unmute Chat Logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Unmute Chat",
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

                /// Leave Community
                GestureDetector(
                  onTap: () {
                    // Leave Community Logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Leave Community",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showModalBottomSheetFunctionSavePhoto(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor: Colors.transparent,
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
                    "Save Photo",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h),

                GestureDetector(
                  onTap: () {
                    // Save to Profile logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Save to Profile",
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
                GestureDetector(
                  onTap: () {
                    // Save to Vault logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Save to Vault",
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
                GestureDetector(
                  onTap: () {
                    // Save to Camera Roll logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Save to Camera Roll",
                        style: TextStyle(
                          color: Color(0xff66CCFC),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showModalBottomSheetFunctionPostOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // full height control
      backgroundColor: Colors.transparent,
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
                Text(
                  "Post Options",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(thickness: 0.6.h),

                GestureDetector(
                  onTap: () {
                    // Share logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Share Profile",
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
                GestureDetector(
                  onTap: () {
                    // Save to profile logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Save to Profile",
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
                GestureDetector(
                  onTap: () {
                    // Save to Vault logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Save to Vault",
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
                GestureDetector(
                  onTap: () {
                    // Save to Camera Roll logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Save to Camera Roll",
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
                GestureDetector(
                  onTap: () {
                    // Remove post logic
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Center(
                      child: Text(
                        "Remove Post",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:
                  () => showModalBottomSheetFunctionProfileOptions(context),
              child: Text("Profile Options"),
            ),
            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed:
                  () => showModalBottomSheetFunctionProfileOptions2(context),
              child: Text(" Profile Options 2"),
            ),
            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed:
                  () => showModalBottomSheetFunctionGroupOptions(context),
              child: Text(" Group Options"),
            ),
            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed:
                  () => showModalBottomSheetFunctionCommunityOptions(context),
              child: Text(" Community Options"),
            ),
            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed: () => showModalBottomSheetFunctionSavePhoto(context),
              child: Text(" Photo Options"),
            ),
            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed: () => showModalBottomSheetFunctionPostOptions(context),
              child: Text(" Post Options"),
            ),
          ],
        ),
      ),
    );
  }
}
