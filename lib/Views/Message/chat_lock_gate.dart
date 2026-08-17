import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/chat_lock_service.dart';
import 'package:outspot/Utils/colors.dart';

/// Full-screen gate shown when opening a password-locked chat. Resolves to
/// `true` once the chat is unlocked for this session.
class ChatLockGate extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatLockGate({super.key, required this.chatId, required this.chatName});

  /// Present the gate. Returns true only when unlocked.
  static Future<bool> open(int chatId, String chatName) async {
    final result = await Get.to<bool>(
      () => ChatLockGate(chatId: chatId, chatName: chatName),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
    );
    return result == true;
  }

  @override
  State<ChatLockGate> createState() => _ChatLockGateState();
}

class _ChatLockGateState extends State<ChatLockGate> {
  final ChatLockService _lock = ChatLockService.to;
  final TextEditingController _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _verifying = false;
  bool _bioAvailable = false;
  // Accurate button label based on what's actually enrolled (Face ID vs
  // fingerprint) — defaults to the generic label until we know.
  String _bioLabel = 'Use Face ID / Fingerprint';
  String? _error;

  @override
  void initState() {
    super.initState();
    _maybeBiometric();
  }

  Future<void> _maybeBiometric() async {
    final enabled = await _lock.isBiometricEnabled(widget.chatId);
    final can = enabled && await _lock.canUseBiometrics();
    // Pick a label that matches the device's real biometric type.
    final types =
        can ? await _lock.availableBiometrics() : <BiometricType>[];
    if (!mounted) return;
    setState(() {
      _bioAvailable = can;
      _bioLabel = _labelFor(types);
    });
    if (can) _tryBiometric(); // auto-prompt on open
  }

  /// Label the unlock button by the strongest enrolled biometric. Face =
  /// Face ID (iOS) or face unlock (Android); fingerprint = Touch ID / sensor.
  String _labelFor(List<BiometricType> types) {
    final hasFace = types.contains(BiometricType.face);
    final hasFingerprint =
        types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong);
    if (hasFace && hasFingerprint) return 'Use Face ID / Fingerprint';
    if (hasFace) return 'Use Face ID';
    if (hasFingerprint) return 'Use Fingerprint';
    return 'Use Face ID / Fingerprint';
  }

  Future<void> _tryBiometric() async {
    final ok = await _lock.authenticate(
      reason: 'Unlock chat with ${widget.chatName}',
    );
    if (ok) _unlockSuccess();
  }

  Future<void> _submitPassword() async {
    final pw = _pwCtrl.text.trim();
    if (pw.isEmpty) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final ok = await ApiService.verifyChatPassword(widget.chatId, pw);
      if (!mounted) return;
      if (ok) {
        _unlockSuccess();
      } else {
        setState(() {
          _verifying = false;
          _error = 'Incorrect password';
        });
      }
    } on ChatLockRateLimited catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = _rateLimitMessage(e.retryAfterSeconds);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Could not verify. Try again.';
      });
    }
  }

  String _rateLimitMessage(int retryAfterSeconds) {
    if (retryAfterSeconds <= 0) {
      return 'Too many attempts. Try again later.';
    }
    final minutes = (retryAfterSeconds / 60).ceil();
    return minutes <= 1
        ? 'Too many attempts. Try again in a minute.'
        : 'Too many attempts. Try again in $minutes min.';
  }

  void _unlockSuccess() {
    // Dismiss the password keyboard before popping — otherwise it can linger
    // onto the chat screen (e.g. after a biometric unlock) and push its layout
    // up into an overflow.
    FocusManager.instance.primaryFocus?.unfocus();
    _lock.markUnlocked(widget.chatId);
    Get.back(result: true);
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: const [0.2, 0.6],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(result: false),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: const Color(0xFFAB50F6),
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Locked chat',
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Enter the password to open your chat with ${widget.chatName}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    color: Colors.white60,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 28.h),
                TextField(
                  controller: _pwCtrl,
                  obscureText: _obscure,
                  autofocus: !_bioAvailable,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _submitPassword(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    errorText: _error,
                    prefixIcon: const Icon(Icons.key, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB50F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: _verifying ? null : _submitPassword,
                    child:
                        _verifying
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              'Unlock',
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
                if (_bioAvailable) ...[
                  SizedBox(height: 16.h),
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint, color: Colors.white70),
                    label: Text(
                      _bioLabel,
                      style: GoogleFonts.notoSans(color: Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
