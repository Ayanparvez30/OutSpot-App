import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_state.dart';

class FilterEditorPanel extends StatefulWidget {
  final String imagePath;
  final FilterPreset? selectedFilter;
  final Function(FilterPreset?) onSelect;
  final VoidCallback onClose;

  const FilterEditorPanel({
    super.key,
    required this.imagePath,
    required this.selectedFilter,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<FilterEditorPanel> createState() => _FilterEditorPanelState();
}

class _FilterEditorPanelState extends State<FilterEditorPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  static const Map<String, List<String>> _categories = {
    'All': [],
    'Warm': ['Warm', 'Golden', 'Sunset', 'Honey'],
    'Cool': ['Cool', 'Arctic', 'Ocean', 'Frost'],
    'Vintage': ['Vintage', 'Retro', '70s', 'Polaroid'],
    'B&W': ['B&W', 'Noir', 'Silver', 'Ink', 'Sepia', 'Coffee'],
    'Vivid': ['Vivid', 'Pop', 'Electric', 'Neon'],
    'Fade': ['Fade', 'Matte', 'Haze'],
    'Cinema': ['Cinema', 'Film', 'Drama', 'Teal'],
    'Moody': ['Moody', 'Shadow', 'Dim'],
    'Pink': ['Rose', 'Blush', 'Lilac'],
    'Nature': ['Forest', 'Spring'],
    'Special': ['Dreamy', 'Glow', 'Crisp', 'Pastel'],
  };

  String _selectedCategory = 'All';
  bool _collapsed = false;
  final ScrollController _filterScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _filterScrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  List<FilterPreset> get _filteredPresets {
    if (_selectedCategory == 'All') return FilterPreset.presets;
    final names = _categories[_selectedCategory] ?? [];
    return FilterPreset.presets
        .where((p) => p.name == 'Original' || names.contains(p.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE6100018), Color(0xFF0A000E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Collapse toggle + Header
                GestureDetector(
                  onTap: () => setState(() => _collapsed = !_collapsed),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Center(
                        child: Icon(
                          _collapsed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white38,
                          size: 22.sp,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFDA5EF3),
                                      Color(0xFFAB50F6),
                                      Color(0xFF7B2FD4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFAB50F6).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Done',
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (!_collapsed) ...[
                SizedBox(height: 12.h),

                // Category chips
                SizedBox(
                  height: 32.h,
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _categories.keys.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, i) {
                      final cat = _categories.keys.elementAt(i);
                      final isActive = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          _filterScrollController.jumpTo(0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFDA5EF3),
                                      Color(0xFF9B40E6),
                                    ],
                                  )
                                : null,
                            color: isActive ? null : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16.r),
                            border: isActive
                                ? null
                                : Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 0.5,
                                  ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFAB50F6).withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: GoogleFonts.notoSans(
                              color: isActive ? Colors.white : Colors.white54,
                              fontSize: 11.sp,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              height: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 14.h),

                // Filter thumbnails
                SizedBox(
                  height: 112.h,
                  child: ListView.separated(
                    controller: _filterScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _filteredPresets.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (_, i) {
                      final preset = _filteredPresets[i];
                      final isSelected =
                          widget.selectedFilter?.name == preset.name ||
                              (widget.selectedFilter == null &&
                                  preset.name == 'Original');
                      return _FilterThumbnail(
                        preset: preset,
                        imagePath: widget.imagePath,
                        isSelected: isSelected,
                        onTap: () => widget.onSelect(
                          preset.name == 'Original' ? null : preset,
                        ),
                      );
                    },
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

class _FilterThumbnail extends StatelessWidget {
  final FilterPreset preset;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterThumbnail({
    required this.preset,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74.r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail with gradient border for selected
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 74.r,
              height: 74.r,
              padding: EdgeInsets.all(isSelected ? 2.5 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF8D7E),
                          Color(0xFFDA5EF3),
                          Color(0xFF7B2FD4),
                        ],
                      )
                    : null,
                border: isSelected
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFDA5EF3).withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 11.r : 13.5.r),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(preset.matrix),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: 74.r,
                    height: 74.r,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            // Filter name centered
            SizedBox(
              width: 74.r,
              child: Text(
                preset.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  color: isSelected ? const Color(0xFFDA5EF3) : Colors.white54,
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
