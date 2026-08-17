import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/shimmer_placeholder.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/story_media.dart';
import 'package:outspot/CommonWidgets/community_access.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/number_format.dart';
import 'package:outspot/Views/FriendList/friendList_controller.dart';
import 'package:outspot/Views/FriendsProfile/friendsFriends.dart';
import 'package:outspot/Views/MyProfile/myProfile_controller.dart';
import 'package:outspot/Views/NonPrivateProfile/non_private_profile_controller.dart';

import 'package:outspot/utils/routes.dart';

class NonPrivateProfile extends GetView<NonPrivateProfileController> {
  const NonPrivateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolve the requested user id from arguments. If the (singleton) controller
    // is currently showing someone else (friend → friend-of-friend chain), reload
    // it for the requested id so it never shows the previous person.
    final args = Get.arguments;
    int requestedId = 0;
    if (args is FriendsModel) {
      requestedId = args.id;
    } else if (args is Map && args['id'] != null) {
      requestedId =
          args['id'] is int ? args['id'] : int.tryParse('${args['id']}') ?? 0;
    } else if (args is int) {
      requestedId = args;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (requestedId > 0 &&
          (controller.friendRx.value == null ||
              controller.friend.id != requestedId)) {
        controller.loadForId(requestedId);
      } else if (controller.friendRx.value != null) {
        await controller.init(controller.friend);
      }
    });
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          center: Alignment.topRight,
          stops: [0.1, 0.5],

          radius: 1.5,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
        body: Obx(() {
          final friend = controller.friendRx.value;
          // Show a loader only when we have NOTHING to display yet (wrong/no
          // user, or first load with no avatar). When we already have the
          // person's basic data (e.g. arriving here from Unfriend, which passes
          // the full model), render immediately and refresh underneath — this
          // avoids the jarring full-screen blank during the unfriend transition.
          if (friend == null ||
              (requestedId > 0 && friend.id != requestedId) ||
              (controller.isProfileLoading.value && friend.avatarUrl.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return CustomScrollView(
            controller: controller.profileScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Header — collapsed (200.h) by default. Drag DOWN to expand
              // up to full screen height showing the entire avatar.
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height,
                collapsedHeight: 150.h,
                toolbarHeight: 56.h,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leadingWidth: 50.w,
                leading: IconButton(
                  onPressed: () => Get.back(),
                  icon: SvgPicture.asset(
                    'assets/svg/icons/back_icon.svg',
                    width: 25.r,
                    height: 25.r,
                  ),
                  padding: EdgeInsets.all(8.w),
                  constraints: const BoxConstraints(),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheetFunctionProfileOptions(
                          context,
                          friend.id,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.h),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgGradientBottom,
                        ),
                        child: SvgPicture.asset(
                          "assets/svg/icons/menuDot.svg",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final topPadding = MediaQuery.of(context).padding.top;
                    return SizedBox(
                      height: constraints.maxHeight,
                      width: double.infinity,
                      child:
                          friend.avatarUrl != null &&
                                  friend.avatarUrl!.isNotEmpty
                              ? Container(
                                padding: EdgeInsets.only(top: topPadding),
                                child: CachedNetworkImage(
                                  imageUrl: friend.avatarUrl!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  placeholder:
                                      (context, url) => ShimmerPlaceholder(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: constraints.maxHeight,
                                      ),
                                  errorWidget:
                                      (context, url, error) =>
                                          _avatarFallback(context),
                                ),
                              )
                              : _avatarFallback(context),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 5.h),
                    Text(
                      friend.fullName,
                      style: TextStyle(
                        fontSize: 23.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "@${friend.username}",
                      style: TextStyle(fontSize: 13.sp, color: Colors.white),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset("assets/svg/level/coinshape1.svg"),
                        SizedBox(width: 4.w),
                        Text(
                          compactNumber(friend.totalPoints),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          height: 12.h,
                          width: 1.5.w,
                          color: AppColors.bgGradientTop,
                        ),
                        SizedBox(width: 9.w),
                        SvgPicture.asset("assets/svg/level/coinshape2.svg"),
                        SizedBox(width: 4.w),
                        Text(
                          compactNumber(friend.thisWeekPoints),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // ------------------- Bio -------------------
                    Obx(() {
                      final bioText = controller.bio.value.trim();
                      if (bioText.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(
                          top: 10.h,
                          left: 24.w,
                          right: 24.w,
                        ),
                        child: Text(
                          bioText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      );
                    }),

                    SizedBox(height: 12.h),

                    // ✅ Friend Button
                    Obx(() {
                      // Relationship status (friend / requested / incoming) isn't
                      // known until the profile finishes loading. Show a neutral
                      // loading button until then, otherwise it briefly defaults
                      // to "Add Friend" and then flips to Accept/Decline — a
                      // jarring flash for someone who sent YOU a request.
                      if (controller.isProfileLoading.value) {
                        return _statusLoadingButton();
                      }

                      if (controller.isFriend.value) {
                        // Navigate to friend profile screen
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Get.offNamed(
                            Routes.friendsProfile,
                            arguments: friend,
                          );
                        });
                        return const SizedBox.shrink();
                      }

                      if (controller.isRequested.value) {
                        return _requestSentContainer(friend);
                      }

                      if (controller.hasIncomingRequest.value) {
                        return _acceptRequestContainer(friend);
                      }

                      return _addFriendContainer(friend);
                    }),

                    SizedBox(height: 16.h),

                    Obx(() {
                      if (controller.isPrivate.value) {
                        return SizedBox(height: 1.h);
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          children: [
                            // ---------------- Friends ----------------
                            Expanded(
                              child: GestureDetector(
                                onTap: () => controller.goToFriendsList(),
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Friends",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      Padding(
                                        padding: EdgeInsets.only(left: 50.w),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svg/icons/friends1.svg',
                                              height: 12.h,
                                              width: 12.w,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 5.w),
                                            Obx(
                                              () => Text(
                                                "${controller.friendCount.value}",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // ---------------- Community ----------------
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                // Same logic as FriendsProfile: enter the
                                // community only if I'm a member, else a soft
                                // popup explains I can't access it.
                                onTap: () {
                                  final comms = controller.communities;
                                  if (comms.isEmpty) return;
                                  final last = comms.last;
                                  final rawId = last['id'];
                                  final id =
                                      rawId is int
                                          ? rawId
                                          : int.tryParse('$rawId') ?? 0;
                                  final name =
                                      (last['name'] ?? 'Community').toString();
                                  if (id != 0) {
                                    openCommunityIfMember(
                                      id,
                                      communityName: name,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                  children: [
                                    Text(
                                      "Community",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Obx(() {
                                      final url =
                                          controller
                                              .recentCommunityImageUrl
                                              .value;
                                      if (url.isEmpty) {
                                        return Text(
                                          "No Community",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12.sp,
                                          ),
                                        );
                                      }
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 2.w,
                                            ),
                                            child: CircleAvatar(
                                              radius: 12.r,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              foregroundImage:
                                                  CachedNetworkImageProvider(
                                                    url,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Obx(() {
                      return controller.isPrivate.value
                          ? SizedBox.shrink()
                          : SizedBox(height: 16.h);
                    }),

                    // Posts / Private Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Obx(
                        () =>
                            controller.isPrivate.value
                                ? _privateAccountContainer()
                                : Obx(() {
                                  // Don't show anything while loading or when empty —
                                  // matches friends profile behaviour.
                                  if (controller.isStoriesLoading.value) {
                                    return const SizedBox.shrink();
                                  }
                                  if (controller.savedStories.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                    ),
                                    itemCount: controller.savedStories.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 3,
                                          mainAxisSpacing: 2,
                                          childAspectRatio: .5,
                                        ),
                                    itemBuilder: (context, index) {
                                      final story =
                                          controller.savedStories[index];
                                      return GestureDetector(
                                        onTap:
                                            () => Get.to(
                                              () => StoryViewerScreen(
                                                url: story.mediaUrl,
                                                type: story.type,
                                              ),
                                            ),
                                        child: StoryGridThumb(
                                          url: story.mediaUrl,
                                          type: story.type,
                                        ),
                                      );
                                    },
                                  );
                                }),
                      ),
                    ),

                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Neutral loading button shown while the relationship status is still being
  /// fetched — avoids flashing the wrong default ("Add Friend") first.
  Widget _statusLoadingButton() {
    return Container(
      height: 45.h,
      width: 320.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        gradient: const LinearGradient(
          colors: [Color(0xffFF8364), Color(0xffFFB14D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
      child: Center(
        child: SizedBox(
          height: 20.h,
          width: 20.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _addFriendContainer(FriendsModel friend) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          height: 45.h,
          width: 320.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            gradient: LinearGradient(
              colors: [Color(0xffFF8364), Color(0xffFFB14D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
          child: Center(
            child: SizedBox(
              height: 20.h,
              width: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        );
      }

      if (controller.isRequested.value) {
        // Friend request already sent → Show Cancel button
        return GestureDetector(
          onTap: () async => await controller.declineRequest(friend),
          child: Container(
            height: 45.h,
            width: 320.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: Colors.red,
            ),
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, color: Colors.white, size: 20),
                  SizedBox(width: 8.w),
                  Text(
                    "Cancel Request",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Default state → Add Friend button
      return GestureDetector(
        onTap: () async => await controller.sendFriendRequest(friend.id),
        child: Container(
          height: 45.h,
          width: 320.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            gradient: LinearGradient(
              colors: [Color(0xffFF8364), Color(0xffFFB14D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset("assets/svg/icons/plus.svg", height: 20.h),
                SizedBox(width: 8.w),
                Text(
                  "Add Friend",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200.h,
      color: AppColors.bgGradientBottom,
      child: Center(
        child: Container(
          height: 90.r,
          width: 90.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
          ),
          child: Icon(
            Icons.person,
            size: 50.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _requestSentContainer(FriendsModel friend) {
    return GestureDetector(
      onTap:
          controller.isLoading.value
              ? null
              : () async => await controller.declineRequest(friend),
      child: Container(
        height: 45.h,
        width: 320.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: const Color(0xffF8AC00), width: 2.w),
        ),
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
        child: Center(
          child:
              controller.isLoading.value
                  ? SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    "Cancel",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xffF8AC00),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _privateAccountContainer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Container(
        height: 200.h,
        width: 350.w,
        decoration: BoxDecoration(
          color: const Color(0xff2D0731),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/svg/lock.svg'),
              SizedBox(height: 10.h),
              Text(
                "This account is private",
                style: GoogleFonts.notoSans(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Send them a friend request to see their\n friends, groups, badges, and photos!",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14.sp,
                  // color: Color(0xff95A4A7),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showModalBottomSheetFunctionProfileOptions(
    BuildContext context,
    int friendId,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
          decoration: BoxDecoration(
            color: Color(0xff323434),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 2.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                /// Title
                Center(
                  child: Text(
                    "Profile Options",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h, color: Colors.black),

                /// Share Profile
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.shareText(context),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Text(
                      "Share Profile",
                      style: TextStyle(
                        color: AppColors.bgGradientTop,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h, color: Colors.black),

                /// Block User
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _confirmBlock(context, friendId),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Text(
                      "Block User",
                      style: TextStyle(
                        color: Color(0xffDD4141),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Divider(thickness: 0.6.h, color: Colors.black),

                /// Report User
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _confirmReport(context, friendId),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Text(
                      "Report User",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Display name for the confirmation dialogs (falls back to @username).
  String _friendDisplayName() {
    final f = controller.friendRx.value;
    final name = '${f?.firstName ?? ''} ${f?.lastName ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    final user = f?.username ?? '';
    return user.isNotEmpty ? '@$user' : 'this user';
  }

  // Confirm before blocking (matches ConversationOptionsScreen's dialog).
  void _confirmBlock(BuildContext context, int friendId) {
    final name = _friendDisplayName();
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
          "$name will no longer be able to message you, and you won't see "
          "their messages.",
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
              Get.back(); // close the dialog
              await controller.blockUser(friendId);

              if (Get.isRegistered<FriendListController>()) {
                Get.find<FriendListController>().friends1.removeWhere(
                  (f) => f.id == friendId,
                );
              }
              if (Get.isRegistered<MyProfileController>()) {
                Get.find<MyProfileController>().decrementFriendCount();
              }

              Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 0});
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

  // Confirm before reporting (matches ConversationOptionsScreen's dialog).
  void _confirmReport(BuildContext context, int friendId) {
    final name = _friendDisplayName();
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
          'This sends this profile to the OutSpot team for review. '
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
              Get.back(); // close the dialog
              final ok = await controller.reportFriend(friendId);
              // Close the options sheet on success.
              if (ok && context.mounted) Navigator.of(context).pop();
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

  Widget _acceptRequestContainer(FriendsModel friend) {
    return Obx(() {
      if (!controller.hasIncomingRequest.value) return SizedBox.shrink();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Accept button
          GestureDetector(
            onTap:
                controller.isLoading.value
                    ? null
                    : () async => await controller.acceptFriendRequest(friend),
            child: Container(
              height: 45.h,
              width: 150.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                color: const Color(0xff42D880),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Center(
                child:
                    controller.isLoading.value
                        ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          GestureDetector(
            onTap:
                controller.isLoading.value
                    ? null
                    : () async => await controller.declineRequest(friend),
            child: Container(
              height: 45.h,
              width: 150.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Colors.red, width: 2.w),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Center(
                child: Text(
                  "Decline",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
