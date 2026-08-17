import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Utils/routes.dart';

/// Shows a user's friend list. Each row carries the VIEWER's relation to that
/// person (friendshipStatus) so the right badge/action shows, and tapping a row
/// opens that person's profile via a fresh getUserProfile call (routing decided
/// by the response, not by this cached status).
class FriendFriends extends StatefulWidget {
  const FriendFriends({super.key});

  @override
  State<FriendFriends> createState() => _FriendFriendsState();
}

class _FriendFriendsState extends State<FriendFriends> {
  // Local, mutable copy so per-row buttons can update their status instantly.
  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxSet<int> _busyIds = <int>{}.obs; // ids with an in-flight action

  // Search + client-side pagination (the full list arrives in-memory, so we
  // filter/page locally — keeps the list smooth even with thousands of friends).
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final RxString _query = ''.obs;
  static const int _pageSize = 20;
  final RxInt _visibleCount = 20.obs;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    List raw = const [];
    if (args is Map && args['friends'] is List) {
      raw = args['friends'] as List;
    } else if (args is List) {
      raw = args;
    }
    friends.assignAll(
      raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'] != null)
          .toList(),
    );

    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Friends matching the current search query (by name or username).
  List<Map<String, dynamic>> _filteredFriends() {
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return friends;
    return friends.where((f) {
      final name =
          "${f['firstName'] ?? ''} ${f['lastName'] ?? ''}".toLowerCase();
      final uname = (f['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || uname.contains(q);
    }).toList();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      final total = _filteredFriends().length;
      if (_visibleCount.value < total) {
        _visibleCount.value = (_visibleCount.value + _pageSize).clamp(0, total);
      }
    }
  }

  void _onSearchChanged(String value) {
    _query.value = value;
    _visibleCount.value = _pageSize; // reset paging for the new query
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  String _statusOf(Map<String, dynamic> f) =>
      (f['friendshipStatus']?.toString() ?? 'NONE').toUpperCase();

  void _setStatus(int id, String status) {
    final idx = friends.indexWhere((f) => f['id'] == id);
    if (idx != -1) {
      friends[idx] = {...friends[idx], 'friendshipStatus': status};
      friends.refresh();
    }
  }

  Future<void> _sendRequest(int id) async {
    if (_busyIds.contains(id)) return;
    _busyIds.add(id);
    _setStatus(id, 'PENDING_SENT'); // optimistic
    try {
      final res = await ApiService.sendFriendRequest(id);
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppSnackbar.success('Friend request sent.');
      } else {
        _setStatus(id, 'NONE');
        AppSnackbar.error('Failed to send request');
      }
    } catch (e) {
      _setStatus(id, 'NONE');
      AppSnackbar.error(e.toString());
    } finally {
      _busyIds.remove(id);
    }
  }

  Future<void> _acceptRequest(int id) async {
    if (_busyIds.contains(id)) return;
    _busyIds.add(id);
    try {
      final res = await ApiService.acceptFriendRequest(id);
      if (res.statusCode == 200) {
        _setStatus(id, 'ACCEPTED');
        AppSnackbar.success('Friend request accepted.');
      } else {
        AppSnackbar.error('Failed to accept request');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      _busyIds.remove(id);
    }
  }

  Future<void> _declineRequest(int id) async {
    if (_busyIds.contains(id)) return;
    _busyIds.add(id);
    try {
      final res = await ApiService.declineFriendRequest(id);
      if (res.statusCode == 200 || res.statusCode == 204) {
        _setStatus(id, 'NONE');
        AppSnackbar.success('Friend request declined.');
      } else {
        AppSnackbar.error('Failed to decline request');
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      _busyIds.remove(id);
    }
  }

  /// Tap a row → open that user's profile with a FRESH lookup.
  /// If it's the current user, go to MyProfile.
  /// If it's a friend, go to FriendsProfile.
  /// Otherwise, go to NonPrivateProfile.
  void _openProfile(int id) async {
    final currentUserId = await UserPreference.getUserId();

    if (currentUserId != null && currentUserId == id) {
      Get.toNamed(Routes.myProfile);
      return;
    }

    final friendListCtrl =
        Get.isRegistered<FriendListController>()
            ? Get.find<FriendListController>()
            : Get.put(FriendListController());

    final isFriend = friendListCtrl.friends1.any((f) => f.id == id);

    // Await navigation, then re-sync this user's status — the relationship may
    // have changed on the profile screen (sent/accepted/declined a request).
    if (isFriend) {
      await Get.toNamed(Routes.friendsProfile, arguments: {'id': id});
    } else {
      await Get.toNamed(Routes.nonPrivateProfile, arguments: {'id': id});
    }
    _refreshStatus(id);
  }

  /// Re-fetch a single user's friendship status and update their row (used after
  /// returning from their profile, where the status may have changed).
  Future<void> _refreshStatus(int id) async {
    try {
      final data = await ApiService.getanyUserProfile(id);
      final status =
          (data['friendshipStatus']?.toString() ?? 'NONE').toUpperCase();
      _setStatus(id, status);
    } catch (e) {
      // Non-fatal — keep the existing status if the refresh fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: [0.1, 0.5],
          radius: 1.5,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'Friends',
            style: GoogleFonts.firaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: SvgPicture.asset(
              "assets/svg/icons/back_icon.svg",
              width: 25.r,
              height: 25.r,
            ),
            padding: EdgeInsets.all(8.w),
            constraints: const BoxConstraints(),
          ),
        ),
        body: Column(
          children: [
            // ---------------- Search ----------------
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Search users…",
                  hintStyle: TextStyle(color: AppColors.fillnoti),
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/svg/icons/searchImage.svg',
                      height: 16.h,
                      width: 16.w,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 5.h,
                    horizontal: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: AppColors.fillnoti),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: AppColors.fillnoti),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.fillnoti),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
            // ---------------- List ----------------
            Expanded(
              child: Obx(() {
                if (friends.isEmpty) {
                  return const Center(
                    child: Text(
                      "No friends found",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                final all = _filteredFriends();
                if (all.isEmpty) {
                  return const Center(
                    child: Text(
                      "No matching friends",
                      style: TextStyle(fontSize: 16, color: Colors.white54),
                    ),
                  );
                }

                final count =
                    _visibleCount.value < all.length
                        ? _visibleCount.value
                        : all.length;
                final hasMore = count < all.length;

                return ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: count + (hasMore ? 1 : 0),
                  separatorBuilder:
                      (_, __) => const Divider(
                        color: AppColors.bgGradientTop,
                        thickness: 1,
                      ),
                  itemBuilder: (context, index) {
                    if (index >= count) {
                      // loading footer while more local items are revealed
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    final friend = all[index];
                    final int id = friend['id'] is int ? friend['id'] : 0;
                    final status = _statusOf(friend);
                    final fullName =
                        "${friend['firstName'] ?? ''} ${friend['lastName'] ?? ''}"
                            .trim();
                    final avatarUrl = (friend['avatarUrl'] ?? '').toString();
                    final totalPoints = friend['totalPoints'] ?? 0;
                    final thisWeekPoints = friend['thisWeekPoints'] ?? 0;

                    final bool canOpen = id > 0;

                    return GestureDetector(
                      onTap: canOpen ? () => _openProfile(id) : null,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child:
                                  avatarUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                        imageUrl: avatarUrl,
                                        width: 70.w,
                                        height: 35.h,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        placeholder:
                                            (context, url) =>
                                                ShimmerPlaceholder(
                                                  width: 70.w,
                                                  height: 35.h,
                                                ),
                                      )
                                      : Container(
                                        width: 48.w,
                                        height: 48.h,
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.person,
                                          size: 24,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName.isEmpty ? 'No name' : fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        // Overall points → blue coin (matches
                                        // the rest of the app).
                                        "assets/svg/level/coinshape1.svg",
                                        height: 14.h,
                                        width: 14.w,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        compactNumber(totalPoints),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Container(
                                        height: 10.h,
                                        width: 1.5.w,
                                        color: AppColors.bgGradientTop,
                                      ),
                                      SizedBox(width: 8.w),
                                      SvgPicture.asset(
                                        // This Week points → yellow coin
                                        // (matches the rest of the app).
                                        "assets/svg/level/coinshape2.svg",
                                        height: 14.h,
                                        width: 14.w,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        compactNumber(thisWeekPoints),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _buildAction(id, status),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Per-row badge/button based on the VIEWER's relation to this person.
  Widget _buildAction(int id, String status) {
    final busy = _busyIds.contains(id);
    switch (status) {
      case 'SELF':
        return const SizedBox.shrink();

      case 'ACCEPTED':
        return _chip("Friends", const Color(0xff42D880), filled: false);

      case 'PENDING_SENT':
        return _chip("Requested", Colors.grey, filled: false);

      case 'PENDING_RECEIVED':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: busy ? null : () => _acceptRequest(id),
              child: _chip("Accept", const Color(0xff704EF9), filled: true),
            ),
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: busy ? null : () => _declineRequest(id),
              child: _chip("Decline", Colors.redAccent, filled: false),
            ),
          ],
        );

      case 'NONE':
      default:
        return GestureDetector(
          onTap: busy ? null : () => _sendRequest(id),
          child: _chip("Add Friend", const Color(0xff704EF9), filled: true),
        );
    }
  }

  Widget _chip(String text, Color color, {required bool filled}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          color: filled ? Colors.white : color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
