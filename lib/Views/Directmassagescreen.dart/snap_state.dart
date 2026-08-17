import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local state for chat media ("snaps"):
///  - which snaps have been OPENED (so the pill shows "Open" vs "Opened"),
///  - which messages the user chose to SAVE (green "Saved" pill).
///
/// Everything is keyed by the message's DB id and persisted in
/// shared_preferences, so it survives app restarts but stays on this device
/// (per the "device-local for now" decision).
class SnapState extends GetxService {
  static SnapState get to =>
      Get.isRegistered<SnapState>()
          ? Get.find<SnapState>()
          : Get.put(SnapState(), permanent: true);

  static const String _openedKey = 'snap_opened_ids';
  static const String _savedKey = 'snap_saved_ids';

  /// Reactive so bubbles rebuild the instant a snap is opened / saved.
  final RxSet<int> openedIds = <int>{}.obs;
  final RxSet<int> savedIds = <int>{}.obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    openedIds.addAll(_readIds(_openedKey));
    savedIds.addAll(_readIds(_savedKey));
  }

  Set<int> _readIds(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  void _persist(String key, Set<int> ids) {
    _prefs?.setString(key, jsonEncode(ids.toList()));
  }

  // ---- Opened ----

  bool isOpened(int messageId) => openedIds.contains(messageId);

  void markOpened(int messageId) {
    if (messageId <= 0 || openedIds.contains(messageId)) return;
    openedIds.add(messageId);
    _persist(_openedKey, openedIds);
  }

  // ---- Saved ----

  bool isSaved(int messageId) => savedIds.contains(messageId);

  void setSaved(int messageId, bool saved) {
    if (messageId <= 0) return;
    if (saved) {
      savedIds.add(messageId);
    } else {
      savedIds.remove(messageId);
    }
    _persist(_savedKey, savedIds);
  }
}
