import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:outspot/Model/inventory_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
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

class WaredropController extends GetxController {
  // Represents "no item / without" for optional accessories
  static const ItemDetail? noneItem = null;
  final List<MapEntry<OutfitCategory, ItemDetail?>> _undoStack = [];
  final Rx<OutfitCategory> selectedCategory = OutfitCategory.top.obs;
  final RxList<OutfitCategory> availableCategories = <OutfitCategory>[].obs;
  final ScrollController previewScrollController = ScrollController();
  var selectedGender = ''.obs;
  var bodyShapeUrl = ''.obs;

  // Selected Items — now hold full ItemDetail objects (null = none / "without")
  final Rxn<ItemDetail> selectedTop = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedBottom = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedShoe = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedGlasses = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedMakeup = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedPurse = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedWatches = Rxn<ItemDetail>();
  final Rxn<ItemDetail> selectedOrnament = Rxn<ItemDetail>();

  var myInventory = <InventoryModel>[].obs;
  RxBool isLoading = false.obs;

  // Face chosen via "Change Minime" (create-mini-me flow). Null means the user
  // didn't change their face this session → we omit faceSource so the backend
  // keeps whatever face they already have. 'premade' requires [_pendingPremadeId].
  String? _pendingFaceSource;
  int? _pendingPremadeId;

  /// Called by CreateMiniMeController after the user picks a new face, so the
  /// next generate tells the backend exactly which face to use.
  void setFaceSource(String faceSource, {int? premadeId}) {
    _pendingFaceSource = faceSource;
    _pendingPremadeId = premadeId;
  }

  // Items grouped by category — values are full ItemDetail objects from server
  var outfitItems = <OutfitCategory, List<ItemDetail>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Show the loading skeleton from the very first frame. isLoading was only
    // flipped inside loadInventory before, so the initial profile + free-items
    // fetch left the top of the screen blank instead of showing a shimmer.
    isLoading.value = true;
    // Load profile first so we know gender, then load free items + inventory.
    loadUserProfile().then((_) {
      loadFreeAndInventory();
    });
  }

  /// Loads free items + paid inventory and merges them into outfitItems.
  Future<void> loadFreeAndInventory() async {
    // Free items are seeded first so they sit at the top of each category
    // list. Inventory items are merged after. Auto-select picks the first
    // item per category — i.e. the free default — for the initial preview.
    await loadFreeItems();
    await loadInventory();
    _autoSelectAll();
  }

  // ---------------------------------------------------------------------------
  // Inventory (Server-driven)
  // ---------------------------------------------------------------------------

  Future<void> loadInventory() async {
    try {
      isLoading.value = true;
      final items = await ApiService.fetchInventory();
      myInventory.assignAll(items);

      // Track which inventory items are equipped per category so we can
      // auto-select them later in loadFreeAndInventory.
      _equippedFromInventory.clear();

      // Merge inventory items into outfitItems (which may already contain
      // free items from loadFreeItems). Skip duplicates by id.
      final Map<OutfitCategory, List<ItemDetail>> merged = Map.fromEntries(
        outfitItems.entries.map(
          (e) => MapEntry(e.key, List<ItemDetail>.from(e.value)),
        ),
      );

      for (var inventory in items) {
        final detail = inventory.item;
        final cat = _slotToCategory(detail.slot);
        if (cat == null) {
          log("Unknown slot: ${detail.slot}");
          continue;
        }
        merged.putIfAbsent(cat, () => []);
        if (!merged[cat]!.any((e) => e.id == detail.id)) {
          merged[cat]!.add(detail);
        }
        if (inventory.equipped) {
          _equippedFromInventory[cat] = detail;
        }
      }

      outfitItems.value = merged;
      outfitItems.refresh();

      log(
        "Inventory loaded — categories: ${outfitItems.keys.map((c) => c.name).join(', ')}",
      );
    } catch (e) {
      log("Error loading inventory: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Tracked across loadFreeItems + loadInventory so _autoSelectAll can prefer
  // the user's equipped inventory items over free defaults.
  final Map<OutfitCategory, ItemDetail> _equippedFromInventory = {};

  /// Fetches the free (default) items for the user's gender and seeds
  /// outfitItems so the wardrobe shows them alongside purchased inventory.
  Future<void> loadFreeItems() async {
    try {
      final gender = selectedGender.value.toLowerCase();
      if (gender.isEmpty) {
        log('loadFreeItems skipped — gender unknown');
        return;
      }
      final grouped = await ApiService.getFreeItems(gender: gender);
      log('Free items server keys: ${grouped.keys.toList()}');

      final Map<OutfitCategory, List<ItemDetail>> mapped = {};

      void addCategory(OutfitCategory cat, dynamic raw) {
        if (raw is List) {
          mapped[cat] =
              raw
                  .map(
                    (e) => ItemDetail.fromJson(
                      e is Map<String, dynamic>
                          ? e
                          : Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList();
        }
      }

      addCategory(OutfitCategory.top, grouped['TOP']);
      addCategory(OutfitCategory.bottom, grouped['BOTTOM']);
      addCategory(OutfitCategory.shoes, grouped['SHOES']);
      addCategory(OutfitCategory.glasses, grouped['GLASSES']);
      addCategory(OutfitCategory.watches, grouped['WATCH']);
      addCategory(
        OutfitCategory.makeup,
        grouped['MAKEUP'] ?? grouped['LIPSTICK'],
      );
      addCategory(OutfitCategory.purse, grouped['PURSE'] ?? grouped['BAG']);
      addCategory(
        OutfitCategory.ornament,
        grouped['ORNAMENT'] ?? grouped['NECKLACE'] ?? grouped['JEWELRY'],
      );

      // Seed outfitItems with free items. loadInventory will merge purchased
      // items into these lists afterward.
      outfitItems.value = mapped;
      outfitItems.refresh();
    } catch (e) {
      log('loadFreeItems error: $e');
    }
  }

  OutfitCategory? _slotToCategory(String slot) {
    switch (slot.toUpperCase()) {
      case 'TOP':
        return OutfitCategory.top;
      case 'BOTTOM':
        return OutfitCategory.bottom;
      case 'SHOES':
        return OutfitCategory.shoes;
      case 'GLASSES':
        return OutfitCategory.glasses;
      case 'WATCH':
        return OutfitCategory.watches;
      case 'MAKEUP':
        return OutfitCategory.makeup;
      case 'PURSE':
        return OutfitCategory.purse;
      case 'ORNAMENT':
        return OutfitCategory.ornament;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Gender-based categories
  // ---------------------------------------------------------------------------

  void setCategoriesForGender(String gender) {
    final previous = selectedCategory.value;
    if (gender == 'masculine') {
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
    // Preserve the section the user is currently on (e.g. after a pull-to-
    // refresh); only fall back to the first when the previous one is no longer
    // available.
    selectedCategory.value =
        availableCategories.contains(previous)
            ? previous
            : availableCategories.first;
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void selectItem(ItemDetail item) {
    switch (selectedCategory.value) {
      case OutfitCategory.top:
        _pushUndo(OutfitCategory.top, selectedTop.value);
        selectedTop.value = selectedTop.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.bottom:
        _pushUndo(OutfitCategory.bottom, selectedBottom.value);
        selectedBottom.value =
            selectedBottom.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.shoes:
        _pushUndo(OutfitCategory.shoes, selectedShoe.value);
        selectedShoe.value = selectedShoe.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.glasses:
        _pushUndo(OutfitCategory.glasses, selectedGlasses.value);
        selectedGlasses.value =
            selectedGlasses.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.watches:
        _pushUndo(OutfitCategory.watches, selectedWatches.value);
        selectedWatches.value =
            selectedWatches.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.makeup:
        _pushUndo(OutfitCategory.makeup, selectedMakeup.value);
        selectedMakeup.value =
            selectedMakeup.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.purse:
        _pushUndo(OutfitCategory.purse, selectedPurse.value);
        selectedPurse.value = selectedPurse.value?.id == item.id ? null : item;
        break;
      case OutfitCategory.ornament:
        _pushUndo(OutfitCategory.ornament, selectedOrnament.value);
        selectedOrnament.value =
            selectedOrnament.value?.id == item.id ? null : item;
        break;
    }
  }

  void _pushUndo(OutfitCategory cat, ItemDetail? oldValue) {
    _undoStack.add(MapEntry(cat, oldValue));
  }

  void _autoSelectAll([Map<OutfitCategory, ItemDetail>? equippedMap]) {
    for (final cat in OutfitCategory.values) {
      final equipped = equippedMap?[cat];

      // No auto-default selection. Previously top/bottom/shoes auto-picked the
      // first available item; now nothing is pre-selected for any category —
      // only an actually-equipped item (if provided) is restored. The user
      // chooses, and the selection is shown via the item border only.
      final ItemDetail? pick = equipped;

      switch (cat) {
        case OutfitCategory.top:
          selectedTop.value = pick;
          break;
        case OutfitCategory.bottom:
          selectedBottom.value = pick;
          break;
        case OutfitCategory.shoes:
          selectedShoe.value = pick;
          break;
        case OutfitCategory.glasses:
          selectedGlasses.value = pick;
          break;
        case OutfitCategory.watches:
          selectedWatches.value = pick;
          break;
        case OutfitCategory.makeup:
          selectedMakeup.value = pick;
          break;
        case OutfitCategory.purse:
          selectedPurse.value = pick;
          break;
        case OutfitCategory.ornament:
          selectedOrnament.value = pick;
          break;
      }
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

  /// Helper: get the selected ItemDetail for a given category.
  ItemDetail? selectedFor(OutfitCategory cat) {
    switch (cat) {
      case OutfitCategory.top:
        return selectedTop.value;
      case OutfitCategory.bottom:
        return selectedBottom.value;
      case OutfitCategory.shoes:
        return selectedShoe.value;
      case OutfitCategory.glasses:
        return selectedGlasses.value;
      case OutfitCategory.watches:
        return selectedWatches.value;
      case OutfitCategory.makeup:
        return selectedMakeup.value;
      case OutfitCategory.purse:
        return selectedPurse.value;
      case OutfitCategory.ornament:
        return selectedOrnament.value;
    }
  }

  // ---------------------------------------------------------------------------
  // Outfit generation payload
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> processAndSaveOutfit() async {
    final Map<String, dynamic> payload = {};

    // Face source, only when the user changed their face this session. When
    // 'premade', the backend requires premadeId alongside it.
    if (_pendingFaceSource != null) {
      payload['faceSource'] = _pendingFaceSource;
      if (_pendingFaceSource == 'premade' && _pendingPremadeId != null) {
        payload['premadeId'] = _pendingPremadeId;
      }
    }

    // Body shape data for generation
    if (selectedGender.value.isNotEmpty) {
      payload['bodyType'] = selectedGender.value;
    }
    if (bodyShapeUrl.value.isNotEmpty) {
      payload['bodyShapeUrl'] = bodyShapeUrl.value;
    }

    // Common categories
    if (selectedTop.value != null) {
      payload['shirt'] = selectedTop.value!.imageUrl;
    }
    if (selectedBottom.value != null) {
      payload['pant'] = selectedBottom.value!.imageUrl;
    }
    if (selectedShoe.value != null) {
      payload['shoes'] = selectedShoe.value!.imageUrl;
    }
    if (selectedGlasses.value != null) {
      payload['glasses'] = selectedGlasses.value!.imageUrl;
    }
    if (selectedWatches.value != null) {
      payload['watch'] = selectedWatches.value!.imageUrl;
    }

    // Gender-specific
    if (selectedGender.value != 'Masculine') {
      if (selectedMakeup.value != null) {
        payload['lipstick'] = selectedMakeup.value!.imageUrl;
      }
      if (selectedPurse.value != null) {
        payload['bag'] = selectedPurse.value!.imageUrl;
      }
      if (selectedOrnament.value != null) {
        payload['jewelry'] = selectedOrnament.value!.imageUrl;
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
    Get.toNamed(Routes.waredropgenerate);
  }

  // ---------------------------------------------------------------------------
  // User profile
  // ---------------------------------------------------------------------------

  Future<void> loadUserProfile() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final data = jsonData["data"] ?? '';
        selectedGender.value = data["bodyType"] ?? '';
        bodyShapeUrl.value = data["bodyShapeUrl"] ?? '';
        setCategoriesForGender(selectedGender.value);
        log(data.toString());
      } else {
        log("Server error: ${response.statusCode}");
      }
    } catch (e) {
      log("Error loading profile: $e");
    }
  }
}
