import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/routes.dart';

enum OutfitCategory {
  top,
  bottom,
  shoes,
  glasses,
  watches,
  makeup,
  purse,
  ornament,
}

class CreateprofileController extends GetxController {
  static const String noItemUrl = '__none__';
  static const Map<String, dynamic> _noneItem = {
    'id': -1,
    'imageUrl': noItemUrl,
  };

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final bioController = TextEditingController();
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString bio = ''.obs;
  final RxString selectedGender = ''.obs;
  final RxDouble weight = 1.0.obs;
  final RxDouble height = 1.0.obs;
  final RxDouble fweight = 1.0.obs;
  final RxDouble fheight = 1.0.obs;
  final Rx<OutfitCategory> selectedCategory = OutfitCategory.top.obs;
  final List<MapEntry<OutfitCategory, String>> _undoStack = [];
  final RxList<OutfitCategory> availableCategories = <OutfitCategory>[].obs;
  final ScrollController previewScrollController = ScrollController();

  // Selected outfit imageUrls (from server)
  final RxString selectedTop = ''.obs;
  final RxString selectedBottom = ''.obs;
  final RxString selectedShoe = ''.obs;
  final RxString selectedGlasses = ''.obs;
  final RxString selectedWatches = ''.obs;
  final RxString selectedMakeup = ''.obs;
  final RxString selectedPurse = ''.obs;
  final RxString selectedOrnament = ''.obs;

  // Server-fetched outfit items grouped by category
  final RxMap<OutfitCategory, List<Map<String, dynamic>>> outfitItems =
      <OutfitCategory, List<Map<String, dynamic>>>{}.obs;
  final RxBool isLoadingItems = true.obs;

  // Body shapes from server
  final RxList<Map<String, dynamic>> bodyShapes = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingBodyShapes = false.obs;

  // Passed from CreateMiniMe screen
  int? premadeId;
  // 'selfie' or 'premade' — tells the backend which face to use. Null falls
  // back to the backend's legacy behavior (selfie if one exists, else premade).
  String? faceSource;

  bool _outfitInitialized = false;

  @override
  void onInit() {
    super.onInit();
    availableCategories.value = [
      OutfitCategory.top,
      OutfitCategory.bottom,
      OutfitCategory.shoes,
      OutfitCategory.glasses,
      OutfitCategory.watches,
    ];
    selectedCategory.value = OutfitCategory.top;
    _loadExistingProfile();
  }

  /// Pre-fill fields from server if user has partial profile data.
  Future<void> _loadExistingProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'];
        if (data == null) return;

        // Persist our own user id. Phone/OTP signup doesn't save it at auth
        // time, so without this getUserId() stays null and the app treats the
        // user's own profile as someone else's (opens NonPrivateProfile).
        final rawId = data['id'];
        final uid = rawId is int ? rawId : int.tryParse('${rawId ?? ''}');
        if (uid != null && uid != 0) {
          await UserPreference.saveUserId(uid);
        }

        final fName = (data['firstName'] ?? '').toString();
        final lName = (data['lastName'] ?? '').toString();
        final userBio = (data['bio'] ?? '').toString();
        final bType = (data['bodyType'] ?? '').toString();

        // Pre-fill text controllers
        if (fName.isNotEmpty) {
          firstNameController.text = fName;
          firstName.value = fName;
        }
        if (lName.isNotEmpty) {
          lastNameController.text = lName;
          lastName.value = lName;
        }
        if (userBio.isNotEmpty) {
          bioController.text = userBio;
          bio.value = userBio;
        }

        // Pre-fill gender if already chosen
        if (bType.isNotEmpty) {
          final gender = bType[0].toUpperCase() + bType.substring(1);
          selectedGender.value = gender;
          setCategoriesForGender(gender);
        }

        log(
          'Pre-filled profile: firstName=$fName, lastName=$lName, bodyType=$bType',
        );
      }
    } catch (e) {
      log('Failed to load existing profile: $e');
    }
  }

  // ─── Body Shapes ───────────────────────────────────────────

  Future<void> fetchBodyShapes() async {
    if (bodyShapes.isNotEmpty) return; // already cached
    try {
      isLoadingBodyShapes.value = true;
      final shapes = await ApiService.getBodyShapes();
      bodyShapes.assignAll(shapes);
      log('Body shapes loaded: ${shapes.length} shapes');
    } catch (e) {
      log('Failed to fetch body shapes: $e');
    } finally {
      isLoadingBodyShapes.value = false;
    }
  }

  /// Looks up the server imageUrl for the given gender + weight + height.
  /// Falls back to local asset if shapes haven't loaded yet.
  String _getBodyShapeUrl({
    required String genderApi,
    required int w,
    required int h,
  }) {
    final String heightLabel =
        h == 1
            ? "S"
            : h == 2
            ? "M"
            : "L";

    for (final shape in bodyShapes) {
      final sGender = shape['gender']?.toString();
      final sHeight = shape['height']?.toString();
      final sWeight = shape['weight'];
      // weight from JSON can be int or num — compare as int
      if (sGender == genderApi &&
          sHeight == heightLabel &&
          (sWeight is num && sWeight.toInt() == w)) {
        final url = shape['imageUrl'];
        if (url != null && url.toString().isNotEmpty) {
          return url.toString();
        }
      }
    }

    // Fallback to local asset while loading
    log(
      '_getBodyShapeUrl: no server match for $genderApi w=$w h=$heightLabel (cached: ${bodyShapes.length} shapes)',
    );
    final prefix = genderApi == 'masculine' ? 'M' : 'F';
    return "assets/Images/$prefix$w$heightLabel.png";
  }

  /// Local asset path for display (no network loading / no shimmer).
  String _getBodyShapeAsset({
    required String gender,
    required int w,
    required int h,
  }) {
    final prefix = gender == 'masculine' ? 'M' : 'F';
    final heightLabel =
        h == 1
            ? 'S'
            : h == 2
            ? 'M'
            : 'L';
    return 'assets/Images/$prefix$w$heightLabel.png';
  }

  String get currentImage {
    return _getBodyShapeAsset(
      gender: 'masculine',
      w: weight.value.round(),
      h: height.value.round(),
    );
  }

  String get fcurrentImage {
    return _getBodyShapeAsset(
      gender: 'feminine',
      w: fweight.value.round(),
      h: fheight.value.round(),
    );
  }

  /// Server URL for saving to backend — resolves from fetched body shapes.
  String get bodyShapeUrl {
    if (selectedGender.value == 'Masculine') {
      return _getBodyShapeUrl(
        genderApi: 'masculine',
        w: weight.value.round(),
        h: height.value.round(),
      );
    } else {
      return _getBodyShapeUrl(
        genderApi: 'feminine',
        w: fweight.value.round(),
        h: fheight.value.round(),
      );
    }
  }

  // ─── Profile Save (partial updates) ────────────────────────

  /// Save name + bio from the Name Screen.
  Future<void> saveNameOnServer() async {
    final payload = <String, dynamic>{};
    if (firstName.value.isNotEmpty) payload["firstName"] = firstName.value;
    if (lastName.value.isNotEmpty) payload["lastName"] = lastName.value;
    if (bio.value.isNotEmpty) payload["bio"] = bio.value;

    if (payload.isEmpty) return;

    try {
      await ApiService.saveProfile(body: payload);
    } catch (e) {
      log('Failed to save name: $e');
      AppToast.error('Failed to save profile info');
    }
  }

  /// Save bodyType + bodyShapeUrl from the Body Screen.
  Future<void> saveBodyTypeOnServer() async {
    // Ensure body shapes are loaded so we send a server URL, not a local asset
    await fetchBodyShapes();

    final url = bodyShapeUrl;
    log(
      'saveBodyTypeOnServer: bodyShapeUrl=$url (shapes cached: ${bodyShapes.length})',
    );

    final payload = <String, dynamic>{
      "bodyType": selectedGender.value.toLowerCase(),
      "bodyShapeUrl": url,
    };
    try {
      await ApiService.saveProfile(body: payload);
    } catch (e) {
      log('Failed to save body type: $e');
      AppToast.error('Failed to save body type');
    }
  }

  // ─── Navigation ────────────────────────────────────────────

  void submitBodyType() {
    log("Selected Gender: ${selectedGender.value}");
  }

  void submitBodySelection() {
    log("Selected Image: $currentImage");
    Get.toNamed(Routes.createMiniMe);
  }

  void femalSubmitBodySelection() {
    log("Selected Image: $fcurrentImage");
    Get.toNamed(Routes.createMiniMe);
  }

  // ─── Outfit Selection ──────────────────────────────────────

  /// Call this when the Outfit screen is shown.
  void initOutfit() {
    if (_outfitInitialized) return;
    _outfitInitialized = true;

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      premadeId = args['premadeId'] as int?;
      faceSource = args['faceSource'] as String?;
    }
    log('initOutfit: premadeId=$premadeId faceSource=$faceSource');
    fetchFreeItems();
  }

  Future<void> fetchFreeItems() async {
    try {
      isLoadingItems.value = true;
      final gender = selectedGender.value.toLowerCase();
      final grouped = await ApiService.getFreeItems(
        gender: gender.isNotEmpty ? gender : 'masculine',
      );

      log('Free items server keys: ${grouped.keys.toList()}');

      final Map<OutfitCategory, List<Map<String, dynamic>>> mapped = {};

      if (grouped['TOP'] is List) {
        mapped[OutfitCategory.top] = List<Map<String, dynamic>>.from(
          grouped['TOP'],
        );
      }
      if (grouped['BOTTOM'] is List) {
        mapped[OutfitCategory.bottom] = List<Map<String, dynamic>>.from(
          grouped['BOTTOM'],
        );
      }
      if (grouped['SHOES'] is List) {
        mapped[OutfitCategory.shoes] = List<Map<String, dynamic>>.from(
          grouped['SHOES'],
        );
      }
      if (grouped['GLASSES'] is List) {
        mapped[OutfitCategory.glasses] = [
          _noneItem,
          ...List<Map<String, dynamic>>.from(grouped['GLASSES']),
        ];
      } else {
        mapped[OutfitCategory.glasses] = [_noneItem];
      }
      if (grouped['WATCH'] is List) {
        mapped[OutfitCategory.watches] = [
          _noneItem,
          ...List<Map<String, dynamic>>.from(grouped['WATCH']),
        ];
      } else {
        mapped[OutfitCategory.watches] = [_noneItem];
      }
      // Server may return MAKEUP or LIPSTICK
      final makeupItems = grouped['MAKEUP'] ?? grouped['LIPSTICK'];
      if (makeupItems is List) {
        mapped[OutfitCategory.makeup] = [
          _noneItem,
          ...List<Map<String, dynamic>>.from(makeupItems),
        ];
      } else {
        mapped[OutfitCategory.makeup] = [_noneItem];
      }
      // Server may return PURSE or BAG
      final purseItems = grouped['PURSE'] ?? grouped['BAG'];
      if (purseItems is List) {
        mapped[OutfitCategory.purse] = [
          _noneItem,
          ...List<Map<String, dynamic>>.from(purseItems),
        ];
      } else {
        mapped[OutfitCategory.purse] = [_noneItem];
      }
      // Server may return ORNAMENT, NECKLACE, or JEWELRY
      final ornamentItems =
          grouped['ORNAMENT'] ?? grouped['NECKLACE'] ?? grouped['JEWELRY'];
      if (ornamentItems is List) {
        mapped[OutfitCategory.ornament] = [
          _noneItem,
          ...List<Map<String, dynamic>>.from(ornamentItems),
        ];
      } else {
        mapped[OutfitCategory.ornament] = [_noneItem];
      }

      outfitItems.value = mapped;
      _autoSelectDefaults();
    } catch (e) {
      log('Failed to fetch free items: $e');
    } finally {
      isLoadingItems.value = false;
    }
  }

  void _autoSelectDefaults() {
    final tops = outfitItems[OutfitCategory.top];
    if (tops != null && tops.isNotEmpty) {
      selectedTop.value = tops.first['imageUrl']?.toString() ?? '';
    }
    final bottoms = outfitItems[OutfitCategory.bottom];
    if (bottoms != null && bottoms.isNotEmpty) {
      selectedBottom.value = bottoms.first['imageUrl']?.toString() ?? '';
    }
    final shoes = outfitItems[OutfitCategory.shoes];
    if (shoes != null && shoes.isNotEmpty) {
      selectedShoe.value = shoes.first['imageUrl']?.toString() ?? '';
    }
    selectedGlasses.value = noItemUrl;
    selectedWatches.value = noItemUrl;
    selectedMakeup.value = noItemUrl;
    selectedPurse.value = noItemUrl;
    selectedOrnament.value = noItemUrl;
  }

  void selectItem(String imageUrl) {
    switch (selectedCategory.value) {
      case OutfitCategory.top:
        _pushUndo(OutfitCategory.top, selectedTop.value);
        selectedTop.value = imageUrl;
        break;
      case OutfitCategory.bottom:
        _pushUndo(OutfitCategory.bottom, selectedBottom.value);
        selectedBottom.value = imageUrl;
        break;
      case OutfitCategory.shoes:
        _pushUndo(OutfitCategory.shoes, selectedShoe.value);
        selectedShoe.value = imageUrl;
        break;
      case OutfitCategory.glasses:
        _pushUndo(OutfitCategory.glasses, selectedGlasses.value);
        selectedGlasses.value = imageUrl;
        break;
      case OutfitCategory.watches:
        _pushUndo(OutfitCategory.watches, selectedWatches.value);
        selectedWatches.value = imageUrl;
        break;
      case OutfitCategory.makeup:
        _pushUndo(OutfitCategory.makeup, selectedMakeup.value);
        selectedMakeup.value = imageUrl;
        break;
      case OutfitCategory.purse:
        _pushUndo(OutfitCategory.purse, selectedPurse.value);
        selectedPurse.value = imageUrl;
        break;
      case OutfitCategory.ornament:
        _pushUndo(OutfitCategory.ornament, selectedOrnament.value);
        selectedOrnament.value = imageUrl;
        break;
    }
  }

  void _pushUndo(OutfitCategory cat, String oldValue) {
    if (oldValue.isNotEmpty) {
      _undoStack.add(MapEntry(cat, oldValue));
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final last = _undoStack.removeLast();
    switch (last.key) {
      case OutfitCategory.top:
        selectedTop.value = last.value;
        break;
      case OutfitCategory.bottom:
        selectedBottom.value = last.value;
        break;
      case OutfitCategory.shoes:
        selectedShoe.value = last.value;
        break;
      case OutfitCategory.glasses:
        selectedGlasses.value = last.value;
        break;
      case OutfitCategory.watches:
        selectedWatches.value = last.value;
        break;
      case OutfitCategory.makeup:
        selectedMakeup.value = last.value;
        break;
      case OutfitCategory.purse:
        selectedPurse.value = last.value;
        break;
      case OutfitCategory.ornament:
        selectedOrnament.value = last.value;
        break;
    }
  }

  bool get hasUndo => _undoStack.isNotEmpty;

  void setCategoriesForGender(String gender) {
    if (gender == 'Masculine') {
      availableCategories.value = [
        OutfitCategory.top,
        OutfitCategory.bottom,
        OutfitCategory.shoes,
        OutfitCategory.glasses,
        OutfitCategory.watches,
      ];
    } else {
      availableCategories.value = [
        OutfitCategory.top,
        OutfitCategory.bottom,
        OutfitCategory.shoes,
        OutfitCategory.glasses,
        OutfitCategory.watches,
        OutfitCategory.makeup,
        OutfitCategory.purse,
        OutfitCategory.ornament,
      ];
    }
    selectedCategory.value = availableCategories.first;
  }

  void setBasicInfo({
    required String fName,
    required String lName,
    String? userBio,
  }) {
    firstName.value = fName.trim();
    lastName.value = lName.trim();
    bio.value = (userBio ?? '').trim();
  }

  void setGender(String gender) {
    final changed = selectedGender.value != gender;
    selectedGender.value = gender;
    setCategoriesForGender(gender);
    fetchBodyShapes(); // preload body shapes from server

    // If gender changed, reset outfit items and refetch for the new gender
    if (changed) {
      _outfitInitialized = false;
      outfitItems.clear();
    }
  }

  // ─── Generate ──────────────────────────────────────────────

  Future<Map<String, dynamic>> processAndSaveOutfit() async {
    final Map<String, dynamic> payload = {};

    // Tell the backend which face to use. 'premade' must carry premadeId.
    if (faceSource != null) {
      payload['faceSource'] = faceSource;
    }
    if (premadeId != null) {
      payload['premadeId'] = premadeId;
    }

    // Body shape data for generation
    payload['bodyType'] = selectedGender.value.toLowerCase();
    payload['bodyShapeUrl'] = bodyShapeUrl;

    // Outfit items — imageUrls directly from server
    if (selectedTop.isNotEmpty) payload['shirt'] = selectedTop.value;
    if (selectedBottom.isNotEmpty) payload['pant'] = selectedBottom.value;
    if (selectedShoe.isNotEmpty) payload['shoes'] = selectedShoe.value;
    if (selectedGlasses.isNotEmpty && selectedGlasses.value != noItemUrl) {
      payload['glasses'] = selectedGlasses.value;
    }
    // Gender-specific categories
    if (selectedGender.value == 'Masculine') {
      if (selectedWatches.isNotEmpty && selectedWatches.value != noItemUrl) {
        payload['watch'] = selectedWatches.value;
      }
    } else {
      if (selectedMakeup.isNotEmpty && selectedMakeup.value != noItemUrl) {
        payload['lipstick'] = selectedMakeup.value;
      }
      if (selectedPurse.isNotEmpty && selectedPurse.value != noItemUrl) {
        payload['bag'] = selectedPurse.value;
      }
      if (selectedOrnament.isNotEmpty && selectedOrnament.value != noItemUrl) {
        payload['jewelry'] = selectedOrnament.value;
      }
    }

    try {
      final res = await ApiService.saveMinimeOptions(payload);
      final String? avatarUrl = (res['data']?['avatarUrl'] as String?)?.trim();
      return {'avatarUrl': avatarUrl, 'outfit': payload};
    } catch (e) {
      rethrow;
    }
  }

  void finishOutfitSelection() {
    Get.toNamed(Routes.generate);
  }
}
