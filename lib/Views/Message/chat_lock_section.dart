import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/Message/chat_lock_actions.dart';

/// "Chat lock" settings block for the conversation options screen: set a
/// password, change it, or remove it. Fetches the current lock status itself.
class ChatLockSection extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatLockSection({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatLockSection> createState() => _ChatLockSectionState();
}

class _ChatLockSectionState extends State<ChatLockSection> {
  bool? _locked; // null = still loading

  static const Color _accent = Color(0xFFAB50F6);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final locked = await ApiService.getChatLockStatus(widget.chatId);
      if (mounted) setState(() => _locked = locked);
    } catch (_) {
      if (mounted) setState(() => _locked = false);
    }
  }

  Future<void> _setOrChange() async {
    final changed = await ChatLockActions.setOrChange(
      widget.chatId,
      isChange: _locked == true,
    );
    if (changed) _load();
  }

  Future<void> _remove() async {
    final removed = await ChatLockActions.remove(widget.chatId);
    if (removed) _load();
  }

  @override
  Widget build(BuildContext context) {
    final locked = _locked;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
          SizedBox(height: 16.h),
          Text(
            'Chat lock',
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            locked == null
                ? 'Checking…'
                : locked
                    ? 'This chat is locked. You need the password or Face ID / '
                        'fingerprint to open it.'
                    : 'Require a password (or Face ID / fingerprint) to open '
                        'this chat.',
            style: GoogleFonts.notoSans(
              fontSize: 12.sp,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 10.h),
          _tile(
            icon: locked == true
                ? Icons.lock_rounded
                : Icons.lock_outline_rounded,
            label: locked == true ? 'Change password' : 'Lock this chat',
            color: _accent,
            onTap: locked == null ? null : _setOrChange,
          ),
          if (locked == true) ...[
            SizedBox(height: 4.h),
            _tile(
              icon: Icons.lock_open_rounded,
              label: 'Remove lock',
              color: const Color(0xFFDD4141),
              onTap: _remove,
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22.sp),
              SizedBox(width: 14.w),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
