import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/CustomExploreAppBar.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/ExploreCategoryCard.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/ExplorePostsView.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/ExploreTabItem.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/ExploreTrendingCard.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/explore_stories.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/Explorescreen/explore_controller.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  // Local key — lifetime tied to this State so duplicates can't occur
  // when the widget remounts.
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  late final ExploreController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ExploreController>()
        ? Get.find<ExploreController>()
        : Get.put(ExploreController());

    // Run ONCE on entry — not on every build. The old code scheduled this in
    // build(), so when the feeds were empty it re-fired initData() on every
    // rebuild → a refetch loop that janked the whole screen (the fixed category
    // cards' images flashed blank during it).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (controller.friendsFeed.isEmpty &&
          controller.communityGroups.isEmpty &&
          !controller.isLoading.value) {
        controller.initData();
      }
      // Warm the fixed card images (category icons + trending) so they don't
      // flash blank / load late when returning to Explore.
      final assets = <String>[
        ...controller.staticCategories.map((c) => c['icon']).whereType<String>(),
        'assets/Images/tending.png',
        'assets/Images/trending_icon.png',
      ];
      for (final p in assets) {
        precacheImage(AssetImage(p), context);
      }
    });
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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: const CustomExploreAppBar(),
        body: SafeArea(
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Pagination
              if (notification is ScrollEndNotification &&
                  controller.currentTab.value == 1 &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                controller.loadMorePosts();
              }

              // Lower the refresh threshold. Only count overscroll when the
              // user is actively dragging (dragDetails != null) — this filters
              // out ballistic momentum from a fast upward scroll that briefly
              // crosses into overscroll territory.
              if (notification is ScrollStartNotification) {
                controller.refreshOverscroll = 0;
                controller.refreshFired = false;
              } else if (notification is ScrollUpdateNotification &&
                  notification.dragDetails != null) {
                final pixels = notification.metrics.pixels;
                if (pixels < 0) {
                  final pulled = -pixels;
                  if (pulled > controller.refreshOverscroll) {
                    controller.refreshOverscroll = pulled;
                  }
                  if (pulled > 30 && !controller.refreshFired) {
                    controller.refreshFired = true;
                    _refreshKey.currentState?.show();
                  }
                }
              } else if (notification is ScrollEndNotification) {
                controller.refreshOverscroll = 0;
                controller.refreshFired = false;
              }
              return false;
            },
            child: RefreshIndicator(
              key: _refreshKey,
              color: const Color(0xffC574F7),
              backgroundColor: const Color(0xff2D0731),
              onRefresh: () async {
                // Always refresh the full "all" feed (friends + communities) so
                // tab switches keep working off complete data. Per-tab fetches
                // overwrite the lists with partial data and drop stories.
                await Future.wait([
                  controller.fetchFeed('all'),
                  controller.fetchPostFeed(),
                ]);
              },
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Obx(
                    () => Row(
                      children: List.generate(controller.explore.length, (
                        index,
                      ) {
                        return GestureDetector(
                          onTap: () => controller.selectIndex(index),
                          child: Container(
                            margin: EdgeInsets.only(right: 5.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1.sp,
                                color:
                                    controller.selectedIndex.value == index
                                        ? AppColors.inputBorderColor
                                        : AppColors.inputFillColor,
                              ),
                              color:
                                  controller.selectedIndex.value == index
                                      ? AppColors.inputBorderColor
                                      : AppColors.inputFillColor,
                              borderRadius: BorderRadius.circular(20.sp),
                            ),
                            child: Text(
                              controller.explore[index],
                              style: GoogleFonts.notoSans(
                                fontSize: 13.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ExploreTabItem(
                              title: "Explore",
                              imageUrl: "assets/svg/icons/exploreTab_icon.svg",
                              isActive: controller.currentTab.value == 0,
                              onTap: () => controller.changeTab(0),
                            ),
                            ExploreTabItem(
                              title: "Stories",
                              imageUrl: "assets/svg/icons/explore_post.svg",
                              isActive: controller.currentTab.value == 1,
                              onTap: () => controller.changeTab(1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(() {
                    // Per-filter check (All / Friends / Communities) so an empty
                    // active filter doesn't reserve a blank stories row.
                    bool hasStories = controller.hasStoriesForCurrentFilter;
                    if (controller.currentTab.value == 0) {
                      // ::::: EXPLORE TAB CONTENT :::::
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          hasStories
                              ? SizedBox(
                                height: 80.h,
                                child: const StoriesListSection(),
                              )
                              : const SizedBox.shrink(),
                          ExploreTrendingCard(
                            onTap: () {
                              // Trending now opens the SAME card list as every
                              // other category (the backend serves Google's
                              // trending places for the 'trending' key). The
                              // map keeps its own trending toggle for pins — this
                              // used to jump straight to the map, which was buggy.
                              Get.toNamed(
                                Routes.exploreCategory,
                                arguments: {
                                  'categoryKey': 'trending',
                                  'categoryTitle': 'Trending',
                                },
                              );
                            },
                          ),
                          SizedBox(height: 15.h),
                          // Static category grid — no API call
                          GridView.builder(
                            itemCount: controller.staticCategories.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: .80,
                                ),
                            itemBuilder: (context, index) {
                              final cat = controller.staticCategories[index];
                              return ExploreCategoryCard(
                                categoryKey: cat['key']!,
                                title: cat['title']!,
                                iconPath: cat['icon']!,
                              );
                            },
                          ),
                          SizedBox(height: 100.h),
                        ],
                      );
                    } else {
                      // ::::: POSTS TAB CONTENT :::::
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          hasStories
                              ? SizedBox(
                                height: 80.h,
                                child: const StoriesListSection(),
                              )
                              : const SizedBox.shrink(),
                          const ExplorePostsView(),
                        ],
                      );
                    }
                  }),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
