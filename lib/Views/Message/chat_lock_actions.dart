import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/chat_lock_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';

/// Set / change / remove a chat's password lock. Each entry point returns true
/// when the lock state changed, so the caller can refresh its UI.
class ChatLockActions {
  /// Set a new lock, or change an existing one (pass [isChange] = true).
  static Future<bool> setOrChange(
    int chatId, {
    bool isChange = false,
  }) async {
    final ok = await Get.dialog<bool>(
      _SetLockDialog(chatId: chatId, isChange: isChange),
      barrierDismissible: true,
    );
    return ok == true;
  }

  /// Remove an existing lock (requires the current password).
  static Future<bool> remove(int chatId) async {
    final ok = await Get.dialog<bool>(
      _RemoveLockDialog(chatId: chatId),
      barrierDismissible: true,
    );
    return ok == true;
  }
}

const _kFieldFill = Color(0x14FFFFFF);
const _kAccent = Color(0xFFAB50F6);
const _kSheetBg = Color(0xFF2D0731);

InputDecoration _fieldDecoration(String hint, {String? error}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Colors.white38),
  filled: true,
  fillColor: _kFieldFill,
  errorText: error,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
);

class _SetLockDialog extends StatefulWidget {
  final int chatId;
  final bool isChange;
  const _SetLockDialog({required this.chatId, required this.isChange});

  @override
  State<_SetLockDialog> createState() => _SetLockDialogState();
}

class _SetLockDialogState extends State<_SetLockDialog> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _pw = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _saving = false;
  bool _enableBio = false;
  bool _bioSupported = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ChatLockService.to.canUseBiometrics().then((v) {
      if (mounted) setState(() => _bioSupported = v);
    });
  }

  Future<void> _save() async {
    final pw = _pw.text.trim();
    final confirm = _confirm.text.trim();
    if (pw.length < 4) {
      setState(() => _error = 'Use at least 4 characters');
      return;
    }
    if (pw != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (widget.isChange && _current.text.trim().isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.setChatPassword(
        widget.chatId,
        pw,
        currentPassword: widget.isChange ? _current.text.trim() : null,
      );
      // Persist the biometric opt-in for this device.
      await ChatLockService.to.setBiometricEnabled(widget.chatId, _enableBio);
      Get.back(result: true);
      AppSnackbar.success(widget.isChange ? 'Password updated' : 'Chat locked');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSheetBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isChange ? 'Change chat password' : 'Lock this chat',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'You\'ll need this password (or Face ID / fingerprint) to open the chat.',
              style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12.sp),
            ),
            SizedBox(height: 18.h),
            if (widget.isChange) ...[
              TextField(
                controller: _current,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Current password'),
              ),
              SizedBox(height: 10.h),
            ],
            TextField(
              controller: _pw,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('New password'),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('Confirm password', error: _error),
            ),
            if (_bioSupported) ...[
              SizedBox(height: 6.h),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: _kAccent,
                value: _enableBio,
                onChanged: (v) => setState(() => _enableBio = v),
                title: Text(
                  'Unlock with Face ID / fingerprint',
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Get.back(result: false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.notoSans(color: Colors.white54),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            widget.isChange ? 'Update' : 'Lock',
                            style: GoogleFonts.notoSans(color: Colors.white),
                          ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _RemoveLockDialog extends StatefulWidget {
  final int chatId;
  const _RemoveLockDialog({required this.chatId});

  @override
  State<_RemoveLockDialog> createState() => _RemoveLockDialogState();
}

class _RemoveLockDialogState extends State<_RemoveLockDialog> {
  final TextEditingController _pw = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _remove() async {
    final pw = _pw.text.trim();
    if (pw.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.removeChatPassword(widget.chatId, pw);
      await ChatLockService.to.forget(widget.chatId);
      Get.back(result: true);
      AppSnackbar.success('Lock removed');
    } on ChatLockRateLimited catch (e) {
      if (!mounted) return;
      final mins = (e.retryAfterSeconds / 60).ceil();
      setState(() {
        _saving = false;
        _error = e.retryAfterSeconds <= 0
            ? 'Too many attempts. Try again later.'
            : 'Too many attempts. Try again in ${mins <= 1 ? 'a minute' : '$mins min'}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSheetBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove chat lock',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Enter the current password to remove the lock.',
              style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12.sp),
            ),
            SizedBox(height: 18.h),
            TextField(
              controller: _pw,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('Current password', error: _error),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Get.back(result: false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.notoSans(color: Colors.white54),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDD4141),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: _saving ? null : _remove,
                  child:
                      _saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            'Remove',
                            style: GoogleFonts.notoSans(color: Colors.white),
                          ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
