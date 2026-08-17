import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customLoading.dart';
import 'package:outspot/Views/Create_Mini_Me/front_camera_screen.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Create_Mini_Me/take_selfie.dart';
import 'package:outspot/Views/waredrop/waredrop_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateMiniMeController extends GetxController {
  final RxString pickimages = ''.obs;
  final RxInt selectedAvatarIndex = (-1).obs;

  final RxList<Map<String, dynamic>> premades = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingPremades = true.obs;

  /// Where to go once a new face is uploaded/selected. Onboarding leaves this
  /// null → the flow continues to the onboarding OutfitScreen. When opened from
  /// the wardrobe ("change avatar") it's 'waredrop' → we pop straight back to
  /// the wardrobe instead, so onboarding is untouched.
  String? returnRoute;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['returnTo'] != null) {
      returnRoute = args['returnTo'].toString();
    }
    fetchPremades();
  }

  /// After a face is ready, route to the right place and carry the chosen
  /// [faceSource] ('selfie' or 'premade') so the next generate call tells the
  /// backend exactly which face to use — otherwise a stale selfie can override
  /// a freshly-picked premade. For 'premade', [premadeId] is required.
  ///
  /// Wardrobe ("change avatar") pops straight back and hands the selection to
  /// the live WaredropController; onboarding forwards it to the OutfitScreen.
  void _proceedAfterFace({required String faceSource, int? premadeId}) {
    if (returnRoute == 'waredrop') {
      if (Get.isRegistered<WaredropController>()) {
        Get.find<WaredropController>().setFaceSource(
          faceSource,
          premadeId: premadeId,
        );
      }
      Get.until((route) => Get.currentRoute == Routes.waredrop);
    } else {
      Get.toNamed(
        Routes.outfitScreen,
        arguments: {
          'faceSource': faceSource,
          if (premadeId != null) 'premadeId': premadeId,
        },
      );
    }
  }

  Future<void> fetchPremades() async {
    try {
      isLoadingPremades.value = true;
      final data = await ApiService.getPremades();
      premades.value = data;
    } catch (e) {
      log('Failed to fetch premades: $e');
    } finally {
      isLoadingPremades.value = false;
    }
  }

  Future<void> pickImage() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        pickimages.value = image.path;
        await Get.to(() => const TakeSelfie());
      }
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> pickImagecamera() async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      // Open custom front camera screen
      final String? imagePath = await Navigator.push<String>(
        Get.context!,
        MaterialPageRoute(builder: (_) => const FrontCameraScreen()),
      );
      if (imagePath != null) {
        // Validate face is present in the image
        final hasFace = await _detectFace(imagePath);
        if (hasFace) {
          pickimages.value = imagePath;
        } else {
          AppToast.error(
            'No face detected. Please align your face to the center and try again.',
          );
        }
      }
    } else if (cameraStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<bool> _detectFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    try {
      final faces = await faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      log('Face detection error: $e');
      return true; // Allow on error so user isn't blocked
    } finally {
      faceDetector.close();
    }
  }

  /// Selfie flow: upload file first, then navigate to outfit screen.
  Future<void> uploadAvatarToServer() async {
    try {
      CustomLoading.show(message: "Uploading your snap...");

      if (pickimages.value.isNotEmpty) {
        await ApiService.uploadAvatar(selfieFile: File(pickimages.value));
        log('Uploaded selfie');
      } else {
        AppToast.warning('Please select a selfie');
        return;
      }

      CustomLoading.dismiss();
      _proceedAfterFace(faceSource: 'selfie');
    } catch (e) {
      CustomLoading.dismiss();
      AppToast.error('Upload failed: ${e.toString()}');
    }
  }

  /// Called from selfie screen (TakeSelfie) — same as uploadAvatarToServer.
  Future<void> uploadAvatarToServeres() async {
    try {
      CustomLoading.show(message: "Uploading your snap...");

      if (pickimages.value.isNotEmpty) {
        await ApiService.uploadAvatar(selfieFile: File(pickimages.value));
        log('Uploaded selfie');
      } else {
        AppToast.warning('Please select a selfie');
        return;
      }

      CustomLoading.dismiss();
      _proceedAfterFace(faceSource: 'selfie');
    } catch (e) {
      CustomLoading.dismiss();
      AppToast.warning('Upload failed: ${e.toString()}');
    }
  }

  /// Premade flow: no upload needed — pass premadeId to outfit screen.
  void proceedWithPremade() {
    if (selectedAvatarIndex.value >= 0 &&
        selectedAvatarIndex.value < premades.length) {
      final premade = premades[selectedAvatarIndex.value];
      final premadeId = premade['id'] as int;
      log('Selected premade id: $premadeId (${premade['label']})');
      _proceedAfterFace(faceSource: 'premade', premadeId: premadeId);
    } else {
      AppToast.warning('Please select an avatar');
    }
  }
}
