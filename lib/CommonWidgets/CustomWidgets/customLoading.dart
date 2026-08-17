import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomLoading {
  // লোডার দেখানোর ফাংশন
  static void show({String message = "Loading..."}) {
    // যদি আগে থেকেই কোনো ডায়লগ ওপেন থাকে, তাহলে নতুন করে আর ওপেন হবে না
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xff2D0731), // আপনার থিমের ডার্ক পার্পল
              borderRadius: BorderRadius.circular(20),
              // border: Border.all(color: const Color(0xff42D880), width: 1.5), // থিমের গ্রিন বর্ডার
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xff42D880), // গ্রিন লোডার
                  strokeWidth: 3.5,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false, // ইউজার বাইরে ক্লিক করে কাটতে পারবে না
    );
  }

  // লোডার বন্ধ করার ফাংশন
  static void dismiss() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
