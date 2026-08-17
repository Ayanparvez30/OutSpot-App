import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Message/chat_lock_section.dart';

class ConversationOptionsScreen extends StatefulWidget {
  const ConversationOptionsScreen({super.key});

  @override
  State<ConversationOptionsScreen> createState() =>
      _ConversationOptionsScreenState();
}

class _ConversationOptionsScreenState extends State<ConversationOptionsScreen> {
  late final FriendsModel friend;
  late final int chatId;

  int _selectedSeconds = 0;
  bool _alertsEnabled = true;
  bool _isLoading = true;

  static const List<_DisappearOption> _options = [
    _DisappearOption(label: 'Disappear immediately', seconds: 1),
    _DisappearOption(label: '5 minutes', seconds: 300),
    _DisappearOption(label: '15 minutes', seconds: 900),
    _DisappearOption(label: '30 minutes', seconds: 1800),
    _DisappearOption(label: '1 hour', seconds: 3600),
    _DisappearOption(label: '3 hours', seconds: 10800),
    _DisappearOption(label: '6 hours', seconds: 21600),
    _DisappearOption(label: 'Forever', seconds: 0),
  ];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    friend = args['friend'] as FriendsModel;
    chatId = args['chatId'] as int;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        ApiService.getDisappearingSeconds(chatId),
        ApiService.getMuteStatus(chatId),
      ]);
      if (mounted) {
        setState(() {
          _selectedSeconds = results[0] as int;
          _alertsEnabled = !(results[1] as bool);
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading conversation settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSelectDisappearing(int seconds) async {
    final prev = _selectedSeconds;
    setState(() => _selectedSeconds = seconds);
    final ok = await ApiService.setDisappearingSeconds(chatId, seconds);
    if (!ok && mounted) {
      setState(() => _selectedSeconds = prev);
    }
  }

  Future<void> _onToggleAlerts(bool value) async {
    final prev = _alertsEnabled;
    setState(() => _alertsEnabled = value);
    try {
      if (value) {
        await ApiService.unmuteChatNotifications(chatId);
      } else {
        await ApiService.muteChatNotifications(chatId);
      }
    } catch (e) {
      log('Error toggling alerts: $e');
      if (mounted) setState(() => _alertsEnabled = prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: const [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: SvgPicture.asset(
              "assets/svg/icons/back_icon.svg",
              width: 25.r,
              height: 25.r,
            ),

            padding: EdgeInsets.all(8.w),
            constraints: const BoxConstraints(),
          ),

          centerTitle: true,
          title: Text(
            'Conversation Options',
            style: GoogleFonts.notoSans(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFAB50F6)),
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      _buildProfileSection(),
                      SizedBox(height: 24.h),
                      _buildDisappearingSection(),
                      SizedBox(height: 8.h),
                      _buildAlertsSection(),
                      SizedBox(height: 8.h),
                      ChatLockSection(
                        chatId: chatId,
                        chatName:
                            friend.firstName.trim().isNotEmpty
                                ? friend.firstName.trim()
                                : (friend.username.trim().isNotEmpty
                                    ? friend.username.trim()
                                    : 'this chat'),
                      ),
                      SizedBox(height: 8.h),
                      _buildSafetySection(),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
      ),
    );
  }

  // 🔥 size প্যারামিটার যোগ করা হলো, ডিফল্ট ভ্যালু 36.w রাখা হলো
  Widget _buildAvatar(String? url, {double? size}) {
    final avatarSize = size ?? 36.w;
    final hasUrl = (url != null && url.isNotEmpty);

    if (!hasUrl) {
      return ClipOval(
        // 👈 পারফেক্ট গোল করার জন্য ClipOval
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Icon(Icons.person, size: avatarSize * 0.6, color: Colors.grey),
        ),
      );
    }

    return ClipOval(
      // 👈 পারফেক্ট গোল করার জন্য ClipOval
      child: CachedNetworkImage(
        alignment: Alignment.topCenter,
        imageUrl: url,
        width: avatarSize,
        height: avatarSize,
        fit: BoxFit.cover, // 👈 পুরো কন্টেইনার কভার করবে
        placeholder: (_, __) => ShimmerPlaceholderCircle(size: avatarSize),
        errorWidget:
            (_, __, ___) => SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: Icon(
                Icons.person,
                size: avatarSize * 0.6,
                color: Colors.grey,
              ),
            ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Avatar
        Center(
          child: Container(
            alignment: Alignment.center,
            width: 130.r,
            height: 130.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFAB50F6).withOpacity(0.3),
                  const Color(0xFFFB7D6C).withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            // child: ClipOval(
            //   child:
            //       friend.avatarUrl.isNotEmpty
            //           ? CachedNetworkImage(
            //             imageUrl: friend.avatarUrl,
            //             width: 130.r,
            //             height: 130.r,
            //             fit: BoxFit.cover,
            //             placeholder:
            //                 (_, __) => Icon(
            //                   Icons.person,
            //                   size: 50.sp,
            //                   color: Colors.grey,
            //                 ),
            //             errorWidget:
            //                 (_, __, ___) => Icon(
            //                   Icons.person,
            //                   size: 50.sp,
            //                   color: Colors.grey,
            //                 ),
            //           )
            //           : Icon(Icons.person, size: 50.sp, color: Colors.grey),
            // ),
            child: _buildAvatar(friend.avatarUrl, size: 130.r),
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          friend.fullName,
          style: GoogleFonts.notoSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '@${friend.username}',
          style: GoogleFonts.notoSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: 20.h),
        // Divider
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1),
        ),
        SizedBox(height: 16.h),
        // Points
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'Overall',
                  style: GoogleFonts.notoSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    SvgPicture.asset("assets/svg/level/coinshape1.svg"),
                    SizedBox(width: 6.w),
                    Text(
                      _formatPoints(friend.totalPoints),
                      style: GoogleFonts.notoSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(width: 30.w),
            Container(
              height: 45.h,
              width: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            SizedBox(width: 30.w),
            Column(
              children: [
                Text(
                  'This Week',
                  style: GoogleFonts.notoSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    SvgPicture.asset("assets/svg/level/coinshape2.svg"),
                    SizedBox(width: 6.w),
                    Text(
                      _formatPoints(friend.thisWeekPoints),
                      style: GoogleFonts.notoSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 28.h),
        // View Profile button
        GestureDetector(
          onTap: () => Get.toNamed(Routes.friendsProfile, arguments: friend),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              gradient: const LinearGradient(
                colors: [Color(0xFFAB50F6), Color(0xFFFB7D6C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Text(
              'View Profile',
              style: GoogleFonts.notoSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisappearingSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
          SizedBox(height: 16.h),
          Text(
            'Messages',
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'How long should messages last before\ndisappearing?',
            style: GoogleFonts.notoSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 16.h),
          ..._options.map((opt) => _buildRadioTile(opt)),
        ],
      ),
    );
  }

  Widget _buildRadioTile(_DisappearOption opt) {
    final isSelected = _selectedSeconds == opt.seconds;
    return GestureDetector(
      onTap: () => _onSelectDisappearing(opt.seconds),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    isSelected
                        ? const LinearGradient(
                          colors: [Color(0xFFAB50F6), Color(0xFFFB7D6C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                border:
                    isSelected
                        ? null
                        : Border.all(color: Colors.grey.shade600, width: 1.5),
              ),
              child:
                  isSelected
                      ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                      : null,
            ),
            SizedBox(width: 14.w),
            Text(
              opt.label,
              style: GoogleFonts.notoSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
          SizedBox(height: 16.h),
          Text(
            'Alerts',
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Get notified for new messages',
            style: GoogleFonts.notoSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 12.h),
          Switch(
            value: _alertsEnabled,
            onChanged: _onToggleAlerts,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFAB50F6),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }

  // Safety controls (block / report). Workaround until per-message report +
  // chat-level moderation lands on the backend: these use the existing
  // user-level endpoints (block /block/:id, report /report {reportedId}) so a
  // user can act on an abusive chat partner — required for store policy.
  Widget _buildSafetySection() {
    final name =
        friend.firstName.trim().isNotEmpty
            ? friend.firstName.trim()
            : (friend.username.trim().isNotEmpty
                ? friend.username.trim()
                : 'this user');
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
          SizedBox(height: 16.h),
          Text(
            'Safety',
            style: GoogleFonts.notoSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 12.h),
          _buildSafetyTile(
            icon: Icons.flag_outlined,
            label: 'Report $name',
            color: const Color(0xFFF8AC00),
            onTap: () => _confirmReport(name),
          ),
          SizedBox(height: 4.h),
          _buildSafetyTile(
            icon: Icons.block,
            label: 'Block $name',
            color: const Color(0xFFDD4141),
            onTap: () => _confirmBlock(name),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
    );
  }

  void _confirmReport(String name) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Report $name?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This sends the conversation to the OutSpot team for review. '
          'They may remove content or take action on this account.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ok = await ApiService.reportFriend(friend.id)
                  .then((r) => r.statusCode >= 200 && r.statusCode < 300)
                  .catchError((_) => false);
              if (ok) {
                AppSnackbar.success('Reported. Our team will review it.');
              } else {
                AppSnackbar.error('Could not report. Try again.');
              }
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Color(0xFFF8AC00)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBlock(String name) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff2D0731),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Block $name?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '$name will no longer be able to message you, and you won\'t see '
          'their messages.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ok = await ApiService.blockUser(friend.id)
                  .then((r) => r.statusCode >= 200 && r.statusCode < 300)
                  .catchError((_) => false);
              if (ok) {
                AppSnackbar.success('$name blocked.');
                // Close this options screen; the user lands back on the chat.
                // if (Get.key.currentState?.canPop() == true) Get.back();
                Get.until((route) => route.settings.name == Routes.mainscreen);
                if (Get.isRegistered<MainscreeenController>()) {
                  Get.find<MainscreeenController>().changeTab(0);
                }
              } else {
                AppSnackbar.error('Could not block. Try again.');
              }
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Color(0xFFDD4141)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000) {
      final k = points / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return '$points';
  }
}

class _DisappearOption {
  final String label;
  final int seconds;
  const _DisappearOption({required this.label, required this.seconds});
}
