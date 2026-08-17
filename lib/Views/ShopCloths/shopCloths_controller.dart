import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:outspot/Model/activeMultiplier_model.dart';
import 'package:outspot/Model/bundlePoint_model.dart';
import 'package:outspot/Model/catalog_model.dart';
import 'package:outspot/Model/preview_model.dart';

import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/app_loading.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Utils/share_helper.dart';

import '../../Model/pointMultiplier_model.dart';
import 'package:outspot/Utils/app_snackbar.dart';

/// Outcome of a `/shop/iap/confirm` call for a cosmetic item.
/// - [granted]: item unlocked (HTTP 200/201) — consume the txn.
/// - [alreadyUsed]: receipt already spent server-side (HTTP 409) — consume the
///   txn to clear it, but never re-send the same receipt.
/// - [failed]: transient/other failure — do NOT consume, let the store redeliver
///   so it can be retried.
enum IapItemConfirm { granted, alreadyUsed, failed }

class ShopClothsController extends GetxController
    with SingleGetTickerProviderMixin {
  late TabController tabController;
  var activeMultiplier = Rxn<PointMultiplier>();
  var bundles = <BundleModel>[].obs;
  var pendingPoints = 0.obs;
  var rewardedPoints = 0.obs;
  var pointMultipliers1 = <PointMultiplier>[].obs;
  var activeMultiplier1 = Rxn<ActiveMultiplier>();
  var isLoading = false.obs;
  // Start true so the shop shows the shimmer loader from the very first frame
  // (fetchCatalog runs after gender resolves) instead of flashing
  // "No items available".
  var isCatalogLoading = true.obs;
  var referralCode = "".obs;
  var shareUrl = "".obs;
  var deepLink = "".obs;
  var totalPoints = 0.obs;
  var selectedPath = ''.obs;
  bool _isCurrentlySaving = false; // ডুপ্লিকেট রিকোয়েস্ট আটকানোর জন্য

  //set purchase type
  // 1 =shop
  //2= multiplexer
  //3 = point shop
  int purchaseType = 0;

  //point shop
  final RxSet<String> buying = <String>{}.obs;
  late PointMultiplier pointMultiplierItem;
  late BundleModel bundleModel;

  // True while the App/Play Store purchase bottom sheet is visible. Used to
  // auto-dismiss it once the store finishes the payment.
  bool isPurchaseSheetOpen = false;

  /// Close the purchase bottom sheet if it's still open. Call this AFTER
  /// AppLoading.hide() so we pop the sheet itself and not the loading dialog.
  void closePurchaseSheetIfOpen() {
    if (!isPurchaseSheetOpen) return;
    isPurchaseSheetOpen = false;
    final ctx = Get.context;
    if (ctx != null && Navigator.canPop(ctx)) {
      Navigator.of(ctx).pop();
    }
  }

  // Dynamic catalog from server
  var catalogGrouped = <String, List<CatalogItem>>{}.obs;
  var availableCategories = <String>[].obs;
  final RxString selectedCategory = ''.obs;

  // Owned item IDs from wardrobe
  final RxSet<int> ownedItemIds = <int>{}.obs;

  // Selection tracking by slot
  final selectedBySlot = <String, String>{}.obs;

  // Gender for this session — always fetched from the user profile API
  // so the shop shows the correct items for the currently logged-in user,
  // regardless of navigation arguments or stale caches.
  final RxString _resolvedGender = 'masculine'.obs;
  String get _gender => _resolvedGender.value;

  Future<void> _resolveGender() async {
    try {
      final response = await ApiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'];
        final bodyType = (data?['bodyType'] as String?)?.toLowerCase();
        if (bodyType != null && bodyType.isNotEmpty) {
          _resolvedGender.value = bodyType;
          // Cache for offline/future use
          await UserPreference.cacheProfile(data);
          return;
        }
      }
    } catch (e) {
      log('Profile fetch failed, falling back to cache: $e');
    }

    // Fallback to cached profile if API fails
    try {
      final cached = await UserPreference.getCachedProfile();
      final cachedGender = (cached?['bodyType'] as String?)?.toLowerCase();
      if (cachedGender != null && cachedGender.isNotEmpty) {
        _resolvedGender.value = cachedGender;
      }
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    // Fetch user profile first → resolve gender → then fetch catalog
    // so the shop always shows items for the currently logged-in user.
    _resolveGender().then((_) {
      log("Received Body Type: $_gender");
      fetchCatalog();
      fetchWardrobe();
    });
    fetchPointMultipliers();
    fetchReferralPoints();
    fetchBundles();
    initIapForOutfits();
    fetchUserEmail();
    // Restore the currently active multiplier from the server so the "Current"
    // badge survives an app restart (it was only kept in memory after buying).
    loadActiveMultiplier();
  }

  @override
  void onClose() {
    // Stop listening to purchases when this controller is disposed so a stale
    // instance doesn't keep handling (and double-completing) transactions.
    _purchaseSub?.cancel();
    _purchaseSub = null;
    tabController.dispose();
    super.onClose();
  }

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Collect all unique IAP product IDs dynamically
  Set<String> get _productIds {
    final ids = <String>{};

    // All cosmetics share ONE store product now, so query that single shared
    // SKU instead of a per-item id. Always include it so its price loads even
    // before the catalog does.
    ids.add(sharedCosmeticSku);

    // From bundles
    for (final b in bundles) {
      final pid = Platform.isIOS ? b.appleProductId : b.googleProductId;
      if (pid != null && pid.trim().isNotEmpty) ids.add(pid.trim());
    }

    // From multipliers
    for (final m in pointMultipliers1) {
      final pid = Platform.isIOS ? m.appleProductId : m.googleProductId;
      if (pid != null && pid.trim().isNotEmpty) ids.add(pid.trim());
    }


    return ids;
  }

  Future<void> loadProducts() async {
    log('RONALDO_CR7: ⚽ loadProducts() — second whistle, same pitch.');
    log('RONALDO_CR7: 📱 ${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion}');

    final bool available = await _inAppPurchase.isAvailable();
    log('RONALDO_CR7: 🏟️ isAvailable = $available');
    if (!available) {
      log('RONALDO_CR7: 🟥 Store NOT available — signed-out App Store or '
          'Paid Apps Agreement not Active.');
      AppSnackbar.info('Store is not available', title: 'IAP');
      return;
    }

    final ids = _productIds;
    log('RONALDO_CR7: 🎯 Querying ${ids.length} ids:');
    for (final id in ids) {
      log('RONALDO_CR7:    👕 $id');
    }

    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(ids);
    log('RONALDO_CR7: 📡 Response in. found=${response.productDetails.length}, '
        'notFound=${response.notFoundIDs.length}');

    if (response.notFoundIDs.isNotEmpty) {
      log('RONALDO_CR7: 🚫 NOT FOUND on App Store (don\'t match ASC):');
      for (final nf in response.notFoundIDs) {
        log('RONALDO_CR7:    ❌ $nf');
      }
    }

    if (response.error != null) {
      log('RONALDO_CR7: 🚑 ERROR code=${response.error!.code}, '
          'source=${response.error!.source}, msg="${response.error!.message}"');
      AppSnackbar.error('Failed to load products');
      return;
    }

    if (response.productDetails.isEmpty) {
      log('RONALDO_CR7: 😱 ZERO products. notFound empty too? → blame '
          'Agreement/StoreKit. notFound has your ids? → ID mismatch.');
      AppSnackbar.error('No products found');
      return;
    }

    final List<ProductDetails> productsList = response.productDetails;
    for (var p in productsList) {
      log('RONALDO_CR7: 🐐 GOOOAL ${p.id} — "${p.title}" — ${p.price} '
          '(${p.rawPrice} ${p.currencyCode})');
    }
  }

  final List<String> banners = [
    'assets/Images/Rectangle 442@2x.png',
    'assets/Images/clothbackground.png',
    'assets/Images/clothingbackground1.png',
  ];

  final RxInt currentIndex = 0.obs;
  int get totalCount => banners.length;

  // ─── Catalog Fetch ───────────────────────────────────────────

  Future<void> fetchCatalog() async {
    try {
      isCatalogLoading.value = true;
      final response = await ApiService.fetchCatalog(gender: _gender);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Cache the raw JSON
        await UserPreference.cacheCatalog(response.body);

        if (jsonData['success'] == true) {
          final catalogResponse = CatalogResponse.fromJson(jsonData);
          final grouped = _mergeAccessoryIntoWatch(
            catalogResponse.data.grouped,
          );
          catalogGrouped.value = grouped;
          // Capture the shared cosmetic SKU the server ships (if any) before we
          // query the store for its price.
          _resolveCosmeticSkuFromCatalog();
          availableCategories.value = _filterCategoriesForGender(
            grouped.keys.toSet(),
          );
          if (availableCategories.isNotEmpty &&
              selectedCategory.value.isEmpty) {
            selectedCategory.value = availableCategories.first;
          }
          log(
            "Catalog loaded: ${catalogResponse.data.total} items in ${availableCategories.length} categories",
          );

          // Query StoreKit AFTER the catalog (and bundles/multipliers) are
          // loaded — that's when _productIds is populated — and STORE the
          // result so the price badges actually render. (The onInit call ran
          // with 0 ids and didn't store; loadProducts only logged.)
          initIapForOutfits();
        }
      } else {
        log("Catalog fetch failed: ${response.statusCode}");
        await _loadCatalogFromCache();
      }
    } catch (e) {
      log("Catalog fetch error: $e");
      await _loadCatalogFromCache();
    } finally {
      isCatalogLoading.value = false;
    }
  }

  // Masculine categories order (matching onboarding)
  static const _masculineSlots = ['TOP', 'BOTTOM', 'SHOES', 'GLASSES', 'WATCH'];
  // Feminine categories order (matching onboarding)
  static const _feminineSlots = [
    'TOP',
    'BOTTOM',
    'SHOES',
    'GLASSES',
    'WATCH',
    'MAKEUP',
    'PURSE',
    'ORNAMENT',
  ];

  // Display labels for slot names
  static const Map<String, String> _slotDisplayNames = {
    'TOP': 'Top',
    'BOTTOM': 'Bottom',
    'SHOES': 'Shoes',
    'GLASSES': 'Glasses',
    'WATCH': 'Watch',
    'MAKEUP': 'Makeup',
    'PURSE': 'Purse',
    'ORNAMENT': 'Ornament',
  };

  String get selectedCategoryDisplayName {
    final slot = selectedCategory.value;
    return _slotDisplayNames[slot] ??
        (slot.isNotEmpty
            ? slot[0].toUpperCase() + slot.substring(1).toLowerCase()
            : 'Shop');
  }

  /// Merge legacy ACCESSORY items into WATCH to avoid duplicate sections
  Map<String, List<CatalogItem>> _mergeAccessoryIntoWatch(
    Map<String, List<CatalogItem>> grouped,
  ) {
    final result = Map<String, List<CatalogItem>>.from(
      grouped.map((k, v) => MapEntry(k, List<CatalogItem>.from(v))),
    );
    if (result.containsKey('ACCESSORY')) {
      final accessoryItems = result.remove('ACCESSORY')!;
      result.putIfAbsent('WATCH', () => []);
      result['WATCH']!.addAll(accessoryItems);
      log("Merged ${accessoryItems.length} ACCESSORY items into WATCH");
    }
    return result;
  }

  /// Filter and order categories based on gender
  List<String> _filterCategoriesForGender(Set<String> serverCategories) {
    final genderSlots =
        _gender == 'masculine' ? _masculineSlots : _feminineSlots;
    return genderSlots
        .where((slot) => serverCategories.contains(slot))
        .toList();
  }

  Future<void> _loadCatalogFromCache() async {
    final cached = await UserPreference.getCachedCatalog();
    if (cached != null) {
      try {
        final jsonData = jsonDecode(cached);
        final catalogResponse = CatalogResponse.fromJson(jsonData);
        final grouped = _mergeAccessoryIntoWatch(catalogResponse.data.grouped);
        catalogGrouped.value = grouped;
        _resolveCosmeticSkuFromCatalog();
        availableCategories.value = _filterCategoriesForGender(
          grouped.keys.toSet(),
        );
        if (availableCategories.isNotEmpty && selectedCategory.value.isEmpty) {
          selectedCategory.value = availableCategories.first;
        }
        log("Catalog loaded from cache");
      } catch (e) {
        log("Cache parse error: $e");
      }
    }
  }

  // ─── Wardrobe (owned items) ──────────────────────────────────

  Future<void> fetchWardrobe() async {
    try {
      final items = await ApiService.fetchInventory();
      ownedItemIds.value = items.map((e) => e.itemId).toSet();
      log("Wardrobe loaded: ${ownedItemIds.length} owned items");
    } catch (e) {
      log("Wardrobe fetch error: $e");
    }
  }

  bool isItemOwned(int itemId) => ownedItemIds.contains(itemId);

  /// Get items for the current category grouped by brand (collection)
  Map<String, List<CatalogItem>> get currentCategoryItems {
    final slot = selectedCategory.value;
    final items = catalogGrouped[slot] ?? [];
    final grouped = <String, List<CatalogItem>>{};
    for (final item in items) {
      final key = item.brand;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }
    return grouped;
  }

  /// Get store price for a cosmetic. All cosmetics share one product, so this
  /// reads the shared SKU's localized store price (same for every item).
  String? getStorePrice(CatalogItem item) {
    final product = products.firstWhereOrNull((p) => p.id == sharedCosmeticSku);
    return product?.price;
  }

  // ─── Selection ───────────────────────────────────────────────

  void selectItem(String imageUrl) {
    final slot = selectedCategory.value;
    if (selectedBySlot[slot] == imageUrl) {
      selectedBySlot[slot] = '';
      selectedPath.value = '';
    } else {
      selectedBySlot[slot] = imageUrl;
      selectedPath.value = imageUrl;
    }
    if (selectedPath.value.isEmpty) removePreview();
  }

  String getSelectedForSlot(String slot) => selectedBySlot[slot] ?? '';

  CatalogItem? getSelectedInstantItem() {
    final slot = selectedCategory.value;
    final items = catalogGrouped[slot] ?? [];
    for (var item in items) {
      if (item.imageUrl.isNotEmpty && selectedPath.value == item.imageUrl) {
        return item;
      }
    }
    return null;
  }

  CatalogItem? getSelectedItem() {
    final slot = selectedCategory.value;
    final items = catalogGrouped[slot] ?? [];
    for (var item in items) {
      if (item.imageUrl.isNotEmpty && item.imageUrl == selectedPreview.value) {
        return item;
      }
    }
    return null;
  }

  // ─── Banner / Preview ────────────────────────────────────────

  final List<Map<String, String>> bannerLabels = [
    {"line1": "Summer", "line2": "Looks"},
    {"line1": "Sports", "line2": "Fashion"},
    {"line1": "Luxury", "line2": "Styles"},
  ];
  var selectedPreview = ''.obs;

  void removePreview() {
    minime.value = null;
    selectedPreview.value = '';
  }

  var minime = Rxn<MinimeModel>();
  var selectedLabel = "CUSTOM PREVIEW".obs;

  RxBool isPreviewLoading = false.obs;

  Future<void> applyPreview(Map<String, dynamic> body) async {
    try {
      isPreviewLoading.value = true;

      // আর্গুমেন্ট থেকে বডি টাইপ নেওয়া
      // Use the gender resolved from the user's profile (same source the
      // catalog uses) — NOT Get.arguments['bodyType'], which can be stale/wrong
      // and made the preview generate the opposite gender to the account.
      final String currentBodyType = _gender;

      // অরিজিনাল বডি ম্যাপের সাথে বডি টাইপ যুক্ত করা
      final Map<String, dynamic> requestBody = {
        ...body,
        "bodyType": currentBodyType,
      };

      log("Requesting preview for: $requestBody");

      final response = await ApiService.applyCustomPreview(requestBody);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null && data['data']['minime'] != null) {
          // মডেল আপডেট
          minime.value = MinimeModel.fromJson(data['data']['minime']);

          // UI আপডেট (সার্ভার থেকে আসা নতুন এভারটার লিঙ্ক)
          selectedPreview.value = minime.value?.avatarUrl ?? '';
          selectedLabel.value = "CUSTOM PREVIEW";

          log("Minime Updated for $currentBodyType shape");
        }
      } else {
        log("API Error => ${response.statusCode}");
      }
    } catch (e) {
      log("Exception in applyPreview => $e");
    } finally {
      isPreviewLoading.value = false;
    }
  }
  // ─── IAP ─────────────────────────────────────────────────────

  late InAppPurchase iap;
  final RxBool isIapReady = false.obs;
  final RxSet<String> ownedProductIds = <String>{}.obs;
  final products = <ProductDetails>[].obs;

  // ─── Shared cosmetic SKU ─────────────────────────────────────
  // Every cosmetic (shirts/watches/glasses/…) is backed by ONE shared,
  // consumable store product now — the backend decides which item to unlock
  // from the `itemId` we send on confirm, not from the store product. Prefer
  // the id the server ships in the catalog (so it can change without an app
  // release); fall back to this constant only if the catalog doesn't carry one.
  static const String kSharedCosmeticSkuFallback = 'item_unlock_299';
  final RxString _serverCosmeticSku = ''.obs;
  String get sharedCosmeticSku =>
      _serverCosmeticSku.value.isNotEmpty
          ? _serverCosmeticSku.value
          : kSharedCosmeticSkuFallback;

  // Sticky localized price for the shared cosmetic SKU. Set once the store
  // returns it and never cleared, so the price badge shows a shimmer → price
  // and never flashes a "—" when the SKU id switches (fallback → server id)
  // while its product reloads.
  final RxString cosmeticPrice = ''.obs;

  /// Pull the shared cosmetic SKU from the catalog. The backend sets the same
  /// product id on every cosmetic, so the first non-empty per-platform id is
  /// the shared SKU. No-op (keeps the fallback) if the catalog omits them.
  void _resolveCosmeticSkuFromCatalog() {
    for (final items in catalogGrouped.values) {
      for (final item in items) {
        final pid = Platform.isIOS ? item.appleProductId : item.googleProductId;
        if (pid != null && pid.trim().isNotEmpty) {
          _serverCosmeticSku.value = pid.trim();
          return;
        }
      }
    }
  }

  // Single purchase-stream subscription for this controller. Kept so we can
  // cancel it on dispose and avoid stacking multiple listeners (which would
  // process each purchase more than once and double-complete transactions —
  // an error on iOS).
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// Returns the actual store-priced label for a given platform product id
  /// (e.g. "$1.99"). Falls back to the server's priceUsd ("3.00") or "—".
  String displayPriceFor({
    String? appleProductId,
    String? googleProductId,
    String? fallbackPriceUsd,
  }) {
    final pid = Platform.isIOS ? appleProductId : googleProductId;
    if (pid != null && pid.isNotEmpty) {
      final p = products.firstWhereOrNull((e) => e.id == pid);
      if (p != null && p.price.trim().isNotEmpty) return p.price;
    }
    final fb = fallbackPriceUsd?.trim() ?? '';
    if (fb.isNotEmpty && fb != '0' && fb != '0.00') return '\$$fb';
    return '—';
  }

  int? currentPendingItemId;
  String? currentPendingSlot;

  Future<void> initIapForOutfits() async {
    iap = InAppPurchase.instance;

    // ── 🐐 RONALDO_CR7 IAP DIAGNOSTICS ──────────────────────────────
    log('RONALDO_CR7: ⚽ Kickoff! Warming up StoreKit on the pitch...');
    log('RONALDO_CR7: 📱 Platform=${Platform.operatingSystem}, '
        'version=${Platform.operatingSystemVersion}');

    final available = await iap.isAvailable();
    log('RONALDO_CR7: 🏟️ Store available (isAvailable) = $available');
    if (!available) {
      log('RONALDO_CR7: 🟥 RED CARD — store NOT available. '
          'On a real device this usually means: signed-out App Store, '
          'or Paid Apps Agreement not Active. Game over.');
      AppSnackbar.info('Store unavailable', title: 'IAP');
      isIapReady.value = true; // clear shimmer; fall back to USD price
      return;
    }

    final ids = _productIds;

    // GUARD: never query the store with an empty set. catalog/bundles/multipliers
    // load asynchronously, so the onInit() call (and any call before a source has
    // loaded) runs with zero ids. Android's BillingClient then returns
    // "Product list cannot be empty" — the IAP Error the user saw — and no prices
    // load. Each source re-calls this once it finishes loading (see fetchCatalog/
    // fetchBundles/fetchPointMultipliers), so just bail until there's something
    // to query.
    if (ids.isEmpty) {
      log('RONALDO_CR7: ⏳ No product IDs yet (catalog/bundles/multipliers still '
          'loading) — skipping store query; will retry when a source loads.');
      return;
    }

    log('RONALDO_CR7: 🎯 Querying ${ids.length} product IDs from the App Store.');
    log('RONALDO_CR7: 🧾 The squad list (ids being sent):');
    for (final id in ids) {
      log('RONALDO_CR7:    👕 $id');
    }

    final response = await iap.queryProductDetails(ids);
    log('RONALDO_CR7: 📡 StoreKit responded (whistle blown).');

    if (response.error != null) {
      log('RONALDO_CR7: 🚑 VAR ERROR — code=${response.error!.code}, '
          'source=${response.error!.source}, msg="${response.error!.message}"');
      AppSnackbar.error(response.error!.message, title: 'IAP Error');
      isIapReady.value = true; // clear shimmer; fall back to USD price
      return;
    }

    // notFoundIDs = the IDs the App Store did NOT recognize. If your server
    // ids are all here → they don't match App Store Connect (typos / wrong
    // bundle / not approved). If notFound is empty but found is empty too →
    // agreement / StoreKit issue.
    log('RONALDO_CR7: ✅ FOUND (scored): ${response.productDetails.length} | '
        '❌ NOT FOUND (missed): ${response.notFoundIDs.length}');

    if (response.notFoundIDs.isNotEmpty) {
      log('RONALDO_CR7: 🥅 These IDs were NOT found on the App Store '
          '(SIUUU... they don\'t match ASC):');
      for (final nf in response.notFoundIDs) {
        log('RONALDO_CR7:    🚫 $nf');
      }
    }

    if (response.productDetails.isEmpty) {
      log('RONALDO_CR7: 😱 ZERO goals — no products returned. '
          'If notFound is also empty, blame the Paid Apps Agreement / '
          'StoreKit; otherwise it\'s an ID mismatch.');
    } else {
      for (final p in response.productDetails) {
        log('RONALDO_CR7: 🐐 GOOOAL -> id=${p.id} | title="${p.title}" | '
            'price=${p.price} | rawPrice=${p.rawPrice} ${p.currencyCode}');
      }
    }

    products.value = response.productDetails;
    // Sticky-cache the shared cosmetic price whenever it's present so the price
    // badge never falls back to "—" mid-load. Only set (never clear) so a later
    // query that doesn't include the SKU can't wipe an already-known price.
    final sharedProduct = response.productDetails.firstWhereOrNull(
      (p) => p.id == sharedCosmeticSku,
    );
    if (sharedProduct != null && sharedProduct.price.trim().isNotEmpty) {
      cosmeticPrice.value = sharedProduct.price;
    }
    isIapReady.value = true;

    // Re-subscribe safely: cancel any existing listener first so calling
    // initIapForOutfits() more than once never stacks duplicate listeners.
    _purchaseSub?.cancel();
    _purchaseSub = iap.purchaseStream.listen((purchases) async {
      bool shouldSaveAfterLoop = false;

      log('🛒 Purchase stream fired: ${purchases.length} update(s), purchaseType=$purchaseType');

      for (final purchase in purchases) {
        log(
          '🛒 Update -> product: ${purchase.productID}, status: ${purchase.status}, '
          'txId: ${purchase.purchaseID}, pendingComplete: ${purchase.pendingCompletePurchase}',
        );

        // Surface every non-success status so we can tell WHY points didn't
        // get credited (store failure / cancel / still pending).
        if (purchase.status == PurchaseStatus.pending) {
          log('⏳ Purchase PENDING for ${purchase.productID} — waiting for store to finish.');
          continue;
        }
        if (purchase.status == PurchaseStatus.error) {
          log(
            '❌ Purchase FAILED for ${purchase.productID}: '
            '${purchase.error?.message} (code: ${purchase.error?.code}, source: ${purchase.error?.source})',
          );
          continue;
        }
        if (purchase.status == PurchaseStatus.canceled) {
          log('⚠️ Purchase CANCELED by user for ${purchase.productID}.');
          continue;
        }
        if (purchase.status != PurchaseStatus.purchased &&
            purchase.status != PurchaseStatus.restored) {
          log('⚠️ Unhandled purchase status ${purchase.status} for ${purchase.productID}.');
          continue;
        }

        log('✅ Store reported SUCCESS for ${purchase.productID} (${purchase.status}). Now crediting...');

        final token = await UserPreference.getToken();
        if (token == null || token.isEmpty) {
          log('❌ No token found, skipping purchase ${purchase.productID}');
          continue;
        }

        // Handle bundle purchases
        if (purchaseType == 3) {
          log('ℹ️ Handling ${purchase.productID} as BUNDLE (purchaseType=3).');
          // EasyLoading.show(status: 'Crediting points...');
          AppLoading.show();
          try {
            // Send the store transaction id so the backend can verify the
            // purchase and credit the points. Without this the server has no
            // proof of payment and won't add the points. Prefer the platform
            // transaction id; fall back to the full receipt token.
            final receiptTxId =
                purchase.purchaseID ??
                purchase.verificationData.serverVerificationData;

            // The backend keys bundles by their INTERNAL productId (e.g.
            // "point_4"), not the store id (e.g. "outspot.bundle.50points").
            // Map the store id back to the internal id, else the server returns
            // 404 "Bundle not found".
            final matchedBundle = bundles.firstWhereOrNull(
              (b) =>
                  b.googleProductId == purchase.productID ||
                  b.appleProductId == purchase.productID ||
                  b.productId == purchase.productID,
            );
            final internalProductId =
                matchedBundle?.productId ?? purchase.productID;
            log(
              'Crediting bundle store:${purchase.productID} -> internal:$internalProductId, txId: $receiptTxId',
            );
            await purchaseBundle(
              productId: internalProductId,
              receiptTxId: receiptTxId,
            );
            if (purchase.pendingCompletePurchase) {
              await iap.completePurchase(purchase);
            }
          } catch (e) {
            log('Error during bundle purchase: $e');
          } finally {
            // EasyLoading.dismiss();
            AppLoading.hide();
            // Payment is done — dismiss the store purchase sheet.
            closePurchaseSheetIfOpen();
          }
          continue;
        }

        // Handle multiplier purchases — these were previously skipped, so the
        // store charged the user but the multiplier never activated. Activate
        // it on the server using the real store receipt.
        if (purchaseType == 2) {
          log('ℹ️ Handling ${purchase.productID} as MULTIPLIER (purchaseType=2).');
          AppLoading.show();
          try {
            final platform = Platform.isIOS ? "apple" : "google";
            final receipt = purchase.verificationData.serverVerificationData;
            final transactionId = purchase.purchaseID ?? '';
            // Backend expects our internal product id (as used by saveMultiplier),
            // falling back to the store product id if it isn't set.
            final productId =
                pointMultiplierItem.productId.isNotEmpty
                    ? pointMultiplierItem.productId
                    : purchase.productID;
            log('Activating multiplier -> productId: $productId, platform: $platform');
            final ok = await purchaseMultiplier(
              platform: platform,
              productId: productId,
              receipt: receipt,
              transactionId: transactionId,
            );
            log(
              ok
                  ? '✅ Multiplier ACTIVATED for ${purchase.productID}'
                  : '❌ Multiplier activation FAILED for ${purchase.productID}',
            );
            if (purchase.pendingCompletePurchase) {
              await iap.completePurchase(purchase);
            }
          } catch (e) {
            log('❌ Error during multiplier purchase: $e');
          } finally {
            AppLoading.hide();
            // Payment is done — dismiss the store purchase sheet.
            closePurchaseSheetIfOpen();
          }
          continue;
        }

        if (currentPendingItemId == null || currentPendingSlot == null) {
          log(
            '⚠️ ${purchase.productID} purchased but no pending item/slot set '
            '(purchaseType=$purchaseType). Nothing credited via stream — '
            'multipliers are credited separately. Skipping.',
          );
          continue;
        }

        // EasyLoading.show(status: 'Verifying with Server...');
        log('ℹ️ Handling ${purchase.productID} as ITEM (purchaseType=$purchaseType). Verifying with server...');
        AppLoading.show();

        try {
          final receipt = purchase.verificationData.serverVerificationData;
          // Per-purchase unique id (iOS transaction id / Android token). The
          // backend dedups on this — the iOS app receipt is cumulative and the
          // SKU is shared, so without it every 2nd cosmetic returns 409.
          final transactionId = purchase.purchaseID ?? '';

          final result = await confirmIapItem(
            token: token,
            receipt: receipt,
            transactionId: transactionId,
            itemId: currentPendingItemId!,
            slot: currentPendingSlot!,
            applyNow: true,
          );

          switch (result) {
            case IapItemConfirm.granted:
              log('✅ Server confirmation SUCCESS for item $currentPendingItemId');
              ownedItemIds.add(currentPendingItemId!);
              // Consume the shared consumable so the next cosmetic can be bought.
              if (purchase.pendingCompletePurchase) {
                await iap.completePurchase(purchase);
              }
              shouldSaveAfterLoop = true;
              break;
            case IapItemConfirm.alreadyUsed:
              // Receipt already spent. Finish the txn to clear the stuck
              // consumable, but never re-send it.
              log('⚠️ Receipt already used for item $currentPendingItemId');
              if (purchase.pendingCompletePurchase) {
                await iap.completePurchase(purchase);
              }
              AppSnackbar.error(
                'This purchase was already used.',
                title: 'Purchase',
              );
              break;
            case IapItemConfirm.failed:
              // Transient/other failure — do NOT complete, let the store
              // redeliver so it can retry.
              log('❌ Server did NOT confirm item $currentPendingItemId');
              AppSnackbar.error(
                'Could not verify your purchase. Please try again.',
                title: 'Purchase',
              );
              break;
          }
        } catch (e) {
          log('❌ Error during server verification: $e');
        } finally {
          // EasyLoading.dismiss();
          AppLoading.hide();
          // Payment is done — dismiss the store purchase sheet.
          closePurchaseSheetIfOpen();
        }
      }

      if (shouldSaveAfterLoop && !_isCurrentlySaving) {
        log('Triggering final save to server...');
        await save();
      }
    });
  }

  Future<void> buyOutfitProduct(CatalogItem item) async {
    purchaseType = 1;
    // Remember which catalog item this payment unlocks — the confirm call sends
    // this itemId; the shared store product doesn't identify the item.
    currentPendingItemId = item.id;
    currentPendingSlot = item.slot;

    // Step 1: Ensure IAP initialized
    if (!isIapReady.value) await initIapForOutfits();

    // Step 2: Every cosmetic buys the ONE shared consumable SKU.
    final sku = sharedCosmeticSku;

    // Step 3: Match from loaded products
    final product = products.firstWhereOrNull((p) => p.id == sku);
    log("Shared cosmetic SKU: $sku");
    log("Available Products: ${products.map((e) => e.id).toList()}");

    if (product == null) {
      log('Shared cosmetic product not found for ID: $sku');
      AppSnackbar.info('Product not found', title: 'IAP');
      return;
    }

    // Step 4: Proceed to purchase (consumable — bought once per cosmetic).
    log('Starting purchase for ${product.id}');
    final param = PurchaseParam(productDetails: product);
    iap.buyConsumable(purchaseParam: param);
    log('Purchase initiated for item ID: ${item.id}');
  }

  /// Build the `/shop/iap/confirm` request body for a cosmetic. Pure + static
  /// so it's unit-testable. [transactionId] is the per-purchase unique id
  /// (iOS StoreKit transaction id / Android purchase token) — REQUIRED so the
  /// backend can dedup: the iOS app receipt is cumulative and the SKU is shared,
  /// so receipt/productId alone collide and return 409 on the 2nd cosmetic.
  static Map<String, dynamic> buildItemConfirmBody({
    required String platform,
    required String productId,
    required String receipt,
    required String transactionId,
    required int itemId,
    required String slot,
    required bool applyNow,
  }) => {
        "platform": platform,
        // Always the shared cosmetic SKU — the backend rejects a per-item id.
        "productId": productId,
        "receipt": receipt,
        "transactionId": transactionId,
        "type": "item",
        "slot": slot,
        "itemId": itemId,
        "applyNow": applyNow,
      };

  /// Map the confirm HTTP status to an outcome. Pure + static (testable).
  static IapItemConfirm mapItemConfirmStatus(int statusCode) {
    if (statusCode == 200 || statusCode == 201) return IapItemConfirm.granted;
    if (statusCode == 409) return IapItemConfirm.alreadyUsed;
    return IapItemConfirm.failed;
  }

  Future<IapItemConfirm> confirmIapItem({
    required String token,
    required int itemId,
    required String slot,
    required String receipt,
    required String transactionId,
    bool applyNow = true,
  }) async {
    final url = '${ApiConstants.baseUrl}/shop/iap/confirm';
    final platform = Platform.isIOS ? "apple" : "google";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(
        buildItemConfirmBody(
          platform: platform,
          productId: sharedCosmeticSku,
          receipt: receipt,
          transactionId: transactionId,
          itemId: itemId,
          slot: slot,
          applyNow: applyNow,
        ),
      ),
    );

    final outcome = mapItemConfirmStatus(response.statusCode);
    switch (outcome) {
      case IapItemConfirm.granted:
        log('IAP confirm success: ${response.statusCode}');
        break;
      case IapItemConfirm.alreadyUsed:
        // "This purchase was already used" — receipt already spent. One payment
        // unlocks exactly one item; never re-send this receipt.
        log('IAP confirm 409 (already used): ${response.body}');
        break;
      case IapItemConfirm.failed:
        debugPrint('IAP confirm failed: ${response.body}');
        log('IAP confirm failed: ${response.statusCode}, Body: ${response.body}');
        break;
    }
    return outcome;
  }

  buyMultiplexer(PointMultiplier item) async {
    log("ℹ️ buyMultiplexer -> productId: ${item.productId}, priceUsd: ${item.priceUsd}");

    purchaseType = 2;
    // Remember which multiplier is being bought so the purchase stream can
    // activate it on the server once the store confirms payment.
    pointMultiplierItem = item;

    // Step 1: Ensure IAP initialized
    if (!isIapReady.value) await initIapForOutfits();

    // Step 2: Get platform-specific product ID
    final platformProductId =
        Platform.isIOS ? item.appleProductId : item.googleProductId;

    ProductDetails? product;
    if (platformProductId != null && platformProductId.isNotEmpty) {
      product = products.firstWhereOrNull((p) => p.id == platformProductId);
    }
    // Fallback: match by priceUsd if platform product ID not available
    product ??= products.firstWhereOrNull((p) => p.id.contains(item.priceUsd));

    if (product == null) {
      log('Product not found for ID: ${item.productId}');
      AppSnackbar.info('Product not found', title: 'IAP');
      return;
    }

    // Step 3: Proceed to purchase
    log('Starting purchase for ${product.id}');
    final param = PurchaseParam(productDetails: product);
    iap.buyConsumable(purchaseParam: param);
  }

  buyPoints(BundleModel item) async {
    log("Attempting to buy: ${item.productId}");

    purchaseType = 3;

    if (!isIapReady.value) await initIapForOutfits();

    // Get platform-specific product ID
    final platformProductId =
        Platform.isIOS ? item.appleProductId : item.googleProductId;

    ProductDetails? product;
    if (platformProductId != null && platformProductId.isNotEmpty) {
      product = products.firstWhereOrNull((p) => p.id == platformProductId);
    }
    // Fallback: match by productId
    product ??= products.firstWhereOrNull((p) => p.id == item.productId);

    if (product == null) {
      log('Product not found in Store: ${item.productId}');
      AppSnackbar.error('Product not found in Store');
      return;
    }

    log('Starting purchase for ${product.id}');
    final param = PurchaseParam(productDetails: product);

    iap.buyConsumable(purchaseParam: param);
  }
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////// point_shop_controller.dart///////////////////////////////////////////////////////

  /// Load the user's currently active multiplier from the server so the
  /// "Current" badge persists across app restarts. The value is only set in
  /// memory at purchase time otherwise, so it was lost on relaunch.
  Future<void> loadActiveMultiplier() async {
    try {
      final response = await ApiService.fetchActiveMultiplier();
      log("ℹ️ Active multiplier [${response.statusCode}]: ${response.body}");
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      // May arrive as { success, data: {...} } or { success, data: null }
      // when nothing is active.
      final m = (decoded is Map) ? decoded['data'] : null;

      if (m is Map<String, dynamic> && m['endsAt'] != null) {
        final active = ActiveMultiplier.fromJson(m);
        // Keep the badge only while the window is still open.
        activeMultiplier1.value =
            active.endsAt.isAfter(DateTime.now()) ? active : null;
      } else {
        activeMultiplier1.value = null;
      }
    } catch (e) {
      log("❌ Error loading active multiplier: $e");
    }
  }

  void fetchPointMultipliers() async {
    try {
      final response = await ApiService.getPointMultipliers();
      if (response.statusCode == 200) {
        log("status code${response.statusCode}");
        log("Response body: ${response.body}");
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final List data = jsonData['data'];
          pointMultipliers1.value =
              data.map((e) => PointMultiplier.fromJson(e)).toList();
          // Multiplier product IDs are now available — (re)query the store so
          // their prices load (skips harmlessly if already queried).
          initIapForOutfits();
        }
      } else {
        AppSnackbar.error("Failed to fetch multipliers");
      }
    } catch (e) {
      AppSnackbar.error(e.toString(), title: "Exception");
    }
  }

  /// Multiplier purchase
  Future<bool> purchaseMultiplier({
    required String platform,
    required String productId,
    required String receipt,
    required String transactionId,
  }) async {
    try {
      final body = {
        "platform": platform,
        "productId": productId,
        "receipt": receipt,
        // Per-purchase unique id — backend dedups on this (same reason as items:
        // iOS receipt is cumulative, a re-bought tier reuses productId).
        "transactionId": transactionId,
        "type": "multiplier",
      };

      final response = await ApiService.activateMultiplier(body);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {};
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (data['success'] == true)) {
        log("purchaseMultiplier OK: ${response.statusCode}");
        log("Response body: ${response.body}");

        // UI toast/snackbar
        AppSnackbar.success(data['message'] ?? "Multiplier activated");

        // Update active multiplier state
        activeMultiplier1.value = ActiveMultiplier.fromJson(data['data']);
        return true;
      }

      final msg =
          data['message'] ??
          'Failed to activate multiplier (code ${response.statusCode})';
      AppSnackbar.error(msg);
      return false;
    } catch (e, st) {
      log('purchaseMultiplier exception: $e', stackTrace: st);
      AppSnackbar.error(e.toString(), title: "Exception");
      return false;
    }
  }

  /// Fetch referral link from API
  Future<void> fetchReferralLink() async {
    try {
      isLoading.value = true;

      final res = await ApiService.getReferralLink();
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        log("status code ${res.statusCode}");
        log("Response body: ${res.body}");

        referralCode.value = data["data"]["code"] ?? '';
        shareUrl.value = data["data"]["shareUrl"] ?? '';
        deepLink.value = data["data"]["deepLink"] ?? '';

        log("Referral link fetched: ${shareUrl.value}");
      } else {
        AppSnackbar.error(data["message"] ?? "Failed to fetch referral");
      }
    } catch (e) {
      AppSnackbar.error(e.toString(), title: "Exception");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareReferral(String platform, [BuildContext? context]) async {
    if (shareUrl.value.isEmpty) {
      AppSnackbar.error("Referral link not available");
      return;
    }

    try {
      String code = referralCode.value;

      String message = """
Join me on Outspot!

Use my referral link:
${shareUrl.value}

Use my referral code: $code
""";

      await shareTextWithOrigin(message, context);

      final res = await ApiService.shareReferralReward(platform: platform);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        final message = data["message"] ?? "Reward added successfully!";
        log(message);
        final credited = data["data"]["credited"] ?? 0;
        final total = data["data"]["totalPoints"] ?? 0;
        log(totalPoints.toString());
        log(res.statusCode.toString());

        totalPoints.value = total;

        log("Points credited: $credited, Total: $total");
      } else {
        AppSnackbar.error(data["message"] ?? "Failed to add reward points");
      }
    } catch (e) {
      AppSnackbar.error(e.toString(), title: "Exception");
    }
  }

  // Fetch function
  Future<void> fetchReferralPoints() async {
    try {
      isLoading.value = true;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      final firebaseToken = await user.getIdToken();

      // API call
      final response = await ApiService.checkReferralReward({
        "phone": user.phoneNumber ?? "",
        "firebaseIdToken": firebaseToken,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        log("status code${response.statusCode}");
        log("Response body: ${response.body}");
        pendingPoints.value = data['data']['pending'];
        rewardedPoints.value = data['data']['rewarded'];
        log("Pending Points: ${pendingPoints.value}");
        log("Rewarded Points: ${rewardedPoints.value}");
      } else {
        log("Failed to fetch referral points: ${data['message']}");
      }
    } catch (e) {
      log("Error fetching referral points: $e");
    }
  }

  Future<void> fetchBundles() async {
    try {
      isLoading.value = true;
      final res = await ApiService.getBundles();

      if (res.statusCode == 200) {
        log("status code${res.statusCode}");
        log("Response body: ${res.body}");
        final body = jsonDecode(res.body);
        if (body["success"] == true && body["data"] != null) {
          final list = body["data"] as List;
          bundles.value = list.map((e) => BundleModel.fromJson(e)).toList();
          // Bundle product IDs are now available — (re)query the store so their
          // prices load (skips harmlessly if it was already queried).
          initIapForOutfits();
        }
      } else {
        log("Failed: ${res.body}");
      }
    } catch (e) {
      log("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  var purchasedBundles = <String>[].obs;
  Future<void> purchaseBundle({
    required String productId,
    String receiptTxId = "",
  }) async {
    try {
      isLoading.value = true;

      log("📤 Bundle credit request -> productId: $productId, receiptTxId: $receiptTxId");
      final response = await ApiService.purchaseBundle({
        "productId": productId,
        "receiptTxId": receiptTxId,
      });

      log("📥 Bundle credit response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          if (!purchasedBundles.contains(productId)) {
            purchasedBundles.add(productId);
          }

          // Refresh profile coins with server value
          if (Get.isRegistered<MyProfileController>()) {
            final profileController = Get.find<MyProfileController>();
            final totalPoints = data["data"]?["totalPoints"];
            if (totalPoints != null) {
              profileController.coins.value = totalPoints;
            } else {
              profileController.fetchPoints(profileController.userId);
            }
            log('✅ Bundle CREDITED. New totalPoints: ${totalPoints ?? "(refetching)"}');
          } else {
            log('✅ Bundle credited on server, but MyProfileController not registered to update coins.');
          }

          AppSnackbar.info(
            data["message"] ?? "Bundle purchased successfully",
            title: "Purchase Info",
          );
        } else {
          log('❌ Bundle NOT credited. Server success=false, message: ${data["message"]}');
          AppSnackbar.error(
            data["message"] ?? "Something went wrong",
            title: "Purchase Failed",
          );
        }
      } else {
        log('❌ Bundle credit FAILED. HTTP ${response.statusCode}: ${response.body}');
        AppSnackbar.error(
          "Status code: ${response.statusCode}",
          title: "Server Error",
        );
      }
    } catch (e) {
      log("❌ Error purchasing bundle: $e");
      AppSnackbar.error("Unable to complete purchase");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buySelectedShopItem() async {
    final CatalogItem? selectedItem = getSelectedItem();
    if (selectedItem == null) {
      log('no item select ');
      return;
    }

    try {
      // Remove $ and trim spaces
      String cleanPrice = selectedItem.priceUsd.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );

      final response = await ApiService.purchaseItem(
        slot: selectedCategory.value.toUpperCase(),
        priceUsd: cleanPrice.isNotEmpty ? cleanPrice : '0.0',
        brand: selectedItem.brand.isNotEmpty ? selectedItem.brand : 'Brand',
        equip: true,
        imageUrl: selectedItem.imageUrl,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("status code${response.statusCode}");
        log("Purchase Response: ${response.body}");
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final minimeData = data['data']['minime'];
          minime.value = MinimeModel.fromJson(minimeData);
          AppSnackbar.success(
            'Purchased ${selectedItem.name.isNotEmpty ? selectedItem.name : 'Item'}!',
          );
        } else {
          AppSnackbar.error(data['message'] ?? 'Purchase failed');
        }
      } else {
        AppSnackbar.error('Server error: ${response.statusCode}');
        log("Failed to purchase item: ${response.body}");
      }
    } catch (e) {
      AppSnackbar.error('Something went wrong');
      log("Error purchasing item: $e");
    }
  }

  Future<void> save() async {
    try {
      await ApiService.saveLatestMinime();
    } catch (e, s) {
      // "No draft to save" is expected when the user buys an item without
      // customizing the avatar. It's not a real error — just skip the save
      // and still navigate so the user sees their updated wardrobe.
      final msg = e.toString().toLowerCase();
      if (msg.contains('no draft to save')) {
        log('No minime draft to save — skipping (expected after purchase)');
      } else {
        log('save error', error: e, stackTrace: s);
        AppSnackbar.error(e.toString());
        return;
      }
    }

    // Delete stale profile controller so it re-fetches avatar + locker
    if (Get.isRegistered<MyProfileController>()) {
      Get.delete<MyProfileController>();
    }
    Get.toNamed(Routes.myProfile, arguments: {'fromDeepLink': true});
  }

  Future<void> saveMultiplier() async {
    if (buying.contains(pointMultiplierItem.productId)) return;
    buying.add(pointMultiplierItem.productId);
    try {
      const receipt = "rcp-987"; // TODO: real receipt
      final platform = Platform.isIOS ? "apple" : "google";
      await purchaseMultiplier(
        platform: platform,
        productId: pointMultiplierItem.productId,
        receipt: receipt,
        transactionId: receipt, // stub — this path is unused (fake receipt)
      );

      // success: controller.activeMultiplier1 updated
      final success =
          activeMultiplier1.value?.productId == pointMultiplierItem.productId;
      if (success) {
        Navigator.pop(Get.context!);
      }
    } finally {
      buying.remove(pointMultiplierItem.productId);
    }
  }

  Future<void> saveOutfitPoint() async {
    if (buying.contains(bundleModel.productId)) return;
    buying.add(bundleModel.productId);
    try {
      await purchaseBundle(productId: bundleModel.productId);

      final success = purchasedBundles.contains(bundleModel.productId);
      if (success) {
        Navigator.of(Get.context!).pop();
      }
    } finally {
      buying.remove(bundleModel.productId);
    }
  }

  final RxString email = ''.obs;

  Future<void> fetchUserEmail() async {
    try {
      final response = await ApiService.fetchUserProfile();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // response -> data -> email
        if (jsonData["status"] == true) {
          email.value = jsonData["data"]["email"] ?? 'No email found';
          log("Email Extracted: ${email.value}");
        }
      } else {
        log("Failed to load email. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching email: $e");
    }
  }
}
