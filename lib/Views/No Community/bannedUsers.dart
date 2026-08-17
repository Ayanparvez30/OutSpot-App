import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/colors.dart';

/// Admin/creator-only: list a community's banned members and unban them.
/// Reached from the community's ⋮ (Community Options) → "Banned Users".
class BannedUsersScreen extends StatefulWidget {
  final int communityId;
  const BannedUsersScreen({super.key, required this.communityId});

  @override
  State<BannedUsersScreen> createState() => _BannedUsersScreenState();
}

class _BannedUsersScreenState extends State<BannedUsersScreen> {
  bool _loading = true;
  final List<Map<String, dynamic>> _banned = [];
  final Set<int> _working = {}; // ids currently being unbanned

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.fetchBannedCommunityMembers(
        widget.communityId,
      );
      final list = <Map<String, dynamic>>[];
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final raw =
            (data is Map)
                ? (data['data'] ?? data['banned'] ?? data['members'] ?? [])
                : data;
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      } else {
        log('fetchBanned failed: ${res.statusCode} ${res.body}');
      }
      if (mounted) {
        setState(() {
          _banned
            ..clear()
            ..addAll(list);
          _loading = false;
        });
      }
    } catch (e) {
      log('fetchBanned error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unban(int userId, String name) async {
    if (_working.contains(userId)) return;
    setState(() => _working.add(userId));
    try {
      final res = await ApiService.unbanCommunityMember(
        widget.communityId,
        userId,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() {
          _banned.removeWhere(
            (m) => '${m['id']}' == '$userId',
          );
        });
        AppSnackbar.success('$name unbanned. They can rejoin now.');
      } else {
        String msg = 'Failed to unban';
        try {
          final d = jsonDecode(res.body);
          if (d is Map && d['message'] is String) msg = d['message'];
        } catch (_) {}
        AppSnackbar.error(msg);
      }
    } catch (e) {
      AppSnackbar.error('Something went wrong');
    } finally {
      if (mounted) setState(() => _working.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.1, 0.5],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Banned Users',
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xffC574F7)),
                )
                : _banned.isEmpty
                ? Center(
                  child: Text(
                    'No banned users',
                    style: GoogleFonts.notoSans(
                      color: Colors.white60,
                      fontSize: 15.sp,
                    ),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: _banned.length,
                    separatorBuilder:
                        (_, __) =>
                            Divider(color: Colors.white12, thickness: 1),
                    itemBuilder: (context, i) {
                      final m = _banned[i];
                      final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
                      final name =
                          "${m['firstName'] ?? ''} ${m['lastName'] ?? ''}"
                                  .trim()
                                  .isEmpty
                              ? (m['username'] ?? 'Unknown').toString()
                              : "${m['firstName'] ?? ''} ${m['lastName'] ?? ''}"
                                  .trim();
                      final avatar = (m['avatarUrl'] ?? '').toString();
                      final busy = _working.contains(id);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22.r,
                          backgroundColor: const Color(0xff703A8B),
                          child:
                              avatar.isNotEmpty
                                  ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: avatar,
                                      width: 44.r,
                                      height: 44.r,
                                      fit: BoxFit.cover,
                                      errorWidget:
                                          (_, __, ___) => const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle:
                            (m['username'] != null)
                                ? Text(
                                  '@${m['username']}',
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white54,
                                    fontSize: 12.sp,
                                  ),
                                )
                                : null,
                        trailing: TextButton(
                          onPressed: id > 0 ? () => _unban(id, name) : null,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xff42D880),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                          ),
                          child:
                              busy
                                  ? SizedBox(
                                    width: 16.r,
                                    height: 16.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'Unban',
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
