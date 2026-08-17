import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_toast.dart';
import 'package:outspot/Utils/routes.dart';

/// Shows the "Send To" bottom sheet for in-app sharing via messaging.
///
/// [content] is the text/caption sent to selected friends. [imageUrl], when
/// provided (e.g. sharing a story/post), is sent as a real image attachment so
/// the message renders an inline image — not a raw URL pasted into the text.
void showSendToSheet(String content, {String? imageUrl, bool forwarded = false}) {
  Get.bottomSheet(
    SendToSheet(content: content, imageUrl: imageUrl, forwarded: forwarded),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class SendToSheet extends StatefulWidget {
  final String content;
  final String? imageUrl;
  final bool forwarded;
  const SendToSheet({
    super.key,
    required this.content,
    this.imageUrl,
    this.forwarded = false,
  });

  @override
  State<SendToSheet> createState() => _SendToSheetState();
}

class _SendToSheetState extends State<SendToSheet> {
  List<FriendsModel> _friends = [];
  List<FriendsModel> _filtered = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final response = await ApiService.fetchFriendList();
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          final List<dynamic> data = jsonData['data'];
          final list = data
              .map((e) => FriendsModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted) {
            setState(() {
              _friends = list;
              _filtered = list;
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      log('SendToSheet: error loading friends: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _friends;
      } else {
        _filtered = _friends.where((f) {
          return f.fullName.toLowerCase().contains(q) ||
              f.username.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _send() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isSending = true);

    int successCount = 0;
    int? lastChatId;
    int? lastFriendId;

    for (final friendId in _selectedIds) {
      try {
        final chat = await ApiService.createChat(
          userIds: [friendId],
          isGroup: false,
        );
        final chatId = chat['chatId'] ?? chat['id'] ?? 0;
        if (chatId == 0) continue;

        await ApiService.sendGlobalChatMessage(
          chatId: chatId,
          content: widget.content,
          imageUrl: widget.imageUrl,
          forwarded: widget.forwarded,
        );
        successCount++;
        lastChatId = chatId;
        lastFriendId = friendId;
      } catch (e) {
        log('SendToSheet: error sending to $friendId: $e');
      }
    }

    if (mounted) setState(() => _isSending = false);

    Get.back(); // close the sheet

    if (successCount > 0) {
      if (successCount == 1 && lastChatId != null && lastFriendId != null) {
        // Single recipient — open the conversation directly
        Get.toNamed(
          Routes.directMessageScreen,
          arguments: {
            'Id': lastFriendId,
            'existingChatId': lastChatId,
          },
        );
      } else {
        AppToast.success('Sent to $successCount friends');
      }
    } else {
      AppToast.error('Failed to send');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      decoration: const BoxDecoration(
        color: Color(0xff1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Text(
              'Send To',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: Colors.white12),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: GoogleFonts.notoSans(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: GoogleFonts.notoSans(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0.h),
              ),
            ),
          ),

          // Friends list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: Color(0xffC574F7)),
                    ),
                  )
                : _friends.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'No friends yet',
                            style: GoogleFonts.notoSans(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'No matches found',
                                style: GoogleFonts.notoSans(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final friend = _filtered[index];
                              final isSelected =
                                  _selectedIds.contains(friend.id);
                              return ListTile(
                                onTap: () => _toggleSelect(friend.id),
                                leading: CircleAvatar(
                                  radius: 22.r,
                                  backgroundColor: const Color(0xff703A8B),
                                  child: friend.avatarUrl.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: friend.avatarUrl,
                                            width: 44.r,
                                            height: 44.r,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) => Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20.sp,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                ),
                                title: Text(
                                  friend.fullName,
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${friend.username}',
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white54,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                trailing: Container(
                                  width: 24.r,
                                  height: 24.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xff42D880)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xff42D880)
                                          : Colors.white38,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16.r,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
          ),

          // Send button
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed:
                    (_selectedIds.isEmpty || _isSending) ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7B51F3),
                  disabledBackgroundColor: const Color(0xff3A2570),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: _isSending
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedIds.isEmpty
                            ? 'Select friends to send'
                            : 'Send to ${_selectedIds.length} ${_selectedIds.length == 1 ? 'friend' : 'friends'}',
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
