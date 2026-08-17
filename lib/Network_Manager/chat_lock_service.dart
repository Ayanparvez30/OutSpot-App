import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

/// Client-side state for the per-chat PASSWORD lock.
///
/// The password itself lives on the backend (server-synced, hashed). This
/// service only tracks the *reveal* state on the device:
///  - which locked chats are currently unlocked for THIS session (in-memory),
///  - which chats the user opted into biometric unlock (persisted, secure),
///  - the biometric (Face ID / fingerprint) prompt itself.
///
/// Session unlocks are cleared when the app is backgrounded, so a locked chat is
/// never left open for whoever picks up the phone next.
class ChatLockService extends GetxService with WidgetsBindingObserver {
  /// Lazily-registered singleton (no need to wire it into main()).
  static ChatLockService get to =>
      Get.isRegistered<ChatLockService>()
          ? Get.find<ChatLockService>()
          : Get.put(ChatLockService(), permanent: true);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  /// Chats unlocked in the current app session. Reactive so tiles/screens
  /// update the moment a chat is (un)locked.
  final RxSet<int> unlockedChatIds = <int>{}.obs;

  static const String _bioKeyPrefix = 'chatlock_bio_';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Session unlock state
  // ---------------------------------------------------------------------------

  bool isUnlocked(int chatId) => unlockedChatIds.contains(chatId);

  void markUnlocked(int chatId) => unlockedChatIds.add(chatId);

  void relock(int chatId) => unlockedChatIds.remove(chatId);

  /// Re-lock everything (called on app background).
  void lockAll() => unlockedChatIds.clear();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      lockAll();
    }
  }

  // ---------------------------------------------------------------------------
  // Per-chat biometric opt-in (persisted in Keychain / Keystore)
  // ---------------------------------------------------------------------------

  Future<bool> isBiometricEnabled(int chatId) async {
    final v = await _storage.read(key: '$_bioKeyPrefix$chatId');
    return v == '1';
  }

  Future<void> setBiometricEnabled(int chatId, bool enabled) async {
    if (enabled) {
      await _storage.write(key: '$_bioKeyPrefix$chatId', value: '1');
    } else {
      await _storage.delete(key: '$_bioKeyPrefix$chatId');
    }
  }

  /// Drop all device state for a chat — call when its lock is removed.
  Future<void> forget(int chatId) async {
    unlockedChatIds.remove(chatId);
    await _storage.delete(key: '$_bioKeyPrefix$chatId');
  }

  // ---------------------------------------------------------------------------
  // Biometrics (Face ID / fingerprint)
  // ---------------------------------------------------------------------------

  /// Whether this device can do a biometric (or device-credential) prompt.
  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (e) {
      log('🔒 canUseBiometrics error: $e');
      return false;
    }
  }

  /// The biometric types actually enrolled on this device (Face ID / face,
  /// fingerprint, iris). Useful to label the unlock button correctly and to
  /// diagnose why a face prompt may not appear.
  ///
  /// NOTE (Android): face unlock on most phones is a "weak" (Class 2)
  /// biometric, which local_auth cannot use — only "strong" (Class 3)
  /// fingerprint works there. On iOS, Face ID works once enrolled and the app
  /// has been granted Face ID permission (NSFaceIDUsageDescription is set).
  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      log('🔒 getAvailableBiometrics error: $e');
      return const [];
    }
  }

  /// Prompt Face ID / fingerprint (falls back to the device passcode). Returns
  /// true on success.
  ///
  /// Errors are logged (not silently swallowed) — a Face ID prompt that seems
  /// to "never appear" is almost always a PlatformException here: permission
  /// denied, not enrolled, or locked out after too many failed attempts.
  Future<bool> authenticate({String reason = 'Unlock this chat'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device passcode fallback
          stickyAuth: true,
          useErrorDialogs: true, // let the OS show its own enroll/permission UI
        ),
      );
    } on PlatformException catch (e) {
      log('🔒 biometric auth failed: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      log('🔒 biometric auth error: $e');
      return false;
    }
  }
}
