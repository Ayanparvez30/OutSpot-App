import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class AppLoading {
  static bool _isShowing = false;
  static BuildContext? _dialogContext;

  static void show({bool closeSnackbars = true}) {
    if (_isShowing) return;

    if (closeSnackbars && Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    _isShowing = true;

    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _dialogContext = context;
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Lottie.asset(
                'assets/Images/loadingAnimation.json',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide() {
    if (_isShowing) {
      _isShowing = false;
      if (_dialogContext != null) {
        Navigator.of(_dialogContext!).pop();
        _dialogContext = null;
      }
    }
  }
}
