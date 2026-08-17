import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_state.dart';

class TextEditorPanel extends StatefulWidget {
  final Function(TextLayer) onAdd;
  final VoidCallback onClose;
  final TextLayer? editingLayer;
  final VoidCallback? onDelete;

  const TextEditorPanel({
    super.key,
    required this.onAdd,
    required this.onClose,
    this.editingLayer,
    this.onDelete,
  });

  @override
  State<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends State<TextEditorPanel>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  double _fontSize = 24;
  Color _selectedColor = Colors.white;
  double _opacity = 1.0;
  String _selectedFont = 'Noto Sans';
  int _activeTab = 0; // 0=Font, 1=Color, 2=Size
  bool _collapsed = false;

  static const List<_FontOption> _fonts = [
    // Sans Serif
    _FontOption('Noto Sans', 'Aa'),
    _FontOption('Poppins', 'Aa'),
    _FontOption('Montserrat', 'Aa'),
    _FontOption('Raleway', 'Aa'),
    _FontOption('Oswald', 'Aa'),
    _FontOption('Bebas Neue', 'Aa'),
    _FontOption('Comfortaa', 'Aa'),
    _FontOption('Righteous', 'Aa'),
    _FontOption('Nunito', 'Aa'),
    _FontOption('Quicksand', 'Aa'),
    _FontOption('Fredoka', 'Aa'),
    _FontOption('Baloo 2', 'Aa'),
    _FontOption('Archivo Black', 'Aa'),
    _FontOption('Rubik', 'Aa'),
    // Serif & Display
    _FontOption('Playfair Display', 'Aa'),
    _FontOption('Abril Fatface', 'Aa'),
    _FontOption('Lora', 'Aa'),
    _FontOption('Merriweather', 'Aa'),
    _FontOption('Cinzel', 'Aa'),
    _FontOption('Cormorant Garamond', 'Aa'),
    // Script & Handwriting
    _FontOption('Lobster', 'Aa'),
    _FontOption('Pacifico', 'Aa'),
    _FontOption('Dancing Script', 'Aa'),
    _FontOption('Caveat', 'Aa'),
    _FontOption('Satisfy', 'Aa'),
    _FontOption('Great Vibes', 'Aa'),
    _FontOption('Sacramento', 'Aa'),
    _FontOption('Kaushan Script', 'Aa'),
    _FontOption('Shadows Into Light', 'Aa'),
    _FontOption('Indie Flower', 'Aa'),
    _FontOption('Amatic SC', 'Aa'),
    _FontOption('Cookie', 'Aa'),
    // Fun & Creative
    _FontOption('Permanent Marker', 'Aa'),
    _FontOption('Press Start 2P', 'Aa'),
    _FontOption('Bungee', 'Aa'),
    _FontOption('Bangers', 'Aa'),
    _FontOption('Russo One', 'Aa'),
    _FontOption('Titan One', 'Aa'),
    _FontOption('Concert One', 'Aa'),
    _FontOption('Black Ops One', 'Aa'),
    _FontOption('Orbitron', 'Aa'),
    _FontOption('Audiowide', 'Aa'),
    _FontOption('Leckerli One', 'Aa'),
    _FontOption('Courgette', 'Aa'),
    _FontOption('Alfa Slab One', 'Aa'),
    _FontOption('Bree Serif', 'Aa'),
    _FontOption('Acme', 'Aa'),
    _FontOption('Lilita One', 'Aa'),
  ];

  static const List<_ColorSwatch> _colorSwatches = [
    _ColorSwatch('White', Color(0xFFFFFFFF)),
    _ColorSwatch('Snow', Color(0xFFF5F5F5)),
    _ColorSwatch('Black', Color(0xFF000000)),
    _ColorSwatch('Red', Color(0xFFFF3B30)),
    _ColorSwatch('Coral', Color(0xFFFF6B6B)),
    _ColorSwatch('Rose', Color(0xFFFF2D55)),
    _ColorSwatch('Orange', Color(0xFFFF9500)),
    _ColorSwatch('Amber', Color(0xFFFFBB00)),
    _ColorSwatch('Yellow', Color(0xFFFFCC00)),
    _ColorSwatch('Lime', Color(0xFFC6FF00)),
    _ColorSwatch('Green', Color(0xFF34C759)),
    _ColorSwatch('Mint', Color(0xFF00C7BE)),
    _ColorSwatch('Teal', Color(0xFF30B0C7)),
    _ColorSwatch('Cyan', Color(0xFF32ADE6)),
    _ColorSwatch('Blue', Color(0xFF007AFF)),
    _ColorSwatch('Indigo', Color(0xFF5856D6)),
    _ColorSwatch('Purple', Color(0xFFAF52DE)),
    _ColorSwatch('Violet', Color(0xFFDA5EF3)),
    _ColorSwatch('Magenta', Color(0xFFFF2D95)),
    _ColorSwatch('Pink', Color(0xFFFF6FA3)),
    _ColorSwatch('Lavender', Color(0xFFD4BBFF)),
    _ColorSwatch('Peach', Color(0xFFFFB5A7)),
    _ColorSwatch('Gold', Color(0xFFFFD700)),
    _ColorSwatch('Bronze', Color(0xFFCD7F32)),
  ];

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

    if (widget.editingLayer != null) {
      _controller.text = widget.editingLayer!.text;
      _fontSize = widget.editingLayer!.fontSize;
      _selectedColor = widget.editingLayer!.color;
      _opacity = widget.editingLayer!.opacity;
      _selectedFont = widget.editingLayer!.fontFamily;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _controller.dispose();
    super.dispose();
  }

  TextStyle _getGoogleFont(String fontName, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    switch (fontName) {
      case 'Poppins': return GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Montserrat': return GoogleFonts.montserrat(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Raleway': return GoogleFonts.raleway(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Oswald': return GoogleFonts.oswald(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Bebas Neue': return GoogleFonts.bebasNeue(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Comfortaa': return GoogleFonts.comfortaa(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Righteous': return GoogleFonts.righteous(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Nunito': return GoogleFonts.nunito(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Quicksand': return GoogleFonts.quicksand(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Fredoka': return GoogleFonts.fredoka(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Baloo 2': return GoogleFonts.baloo2(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Archivo Black': return GoogleFonts.archivoBlack(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Rubik': return GoogleFonts.rubik(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Playfair Display': return GoogleFonts.playfairDisplay(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Abril Fatface': return GoogleFonts.abrilFatface(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Lora': return GoogleFonts.lora(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Merriweather': return GoogleFonts.merriweather(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Cinzel': return GoogleFonts.cinzel(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Cormorant Garamond': return GoogleFonts.cormorantGaramond(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Lobster': return GoogleFonts.lobster(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Pacifico': return GoogleFonts.pacifico(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Dancing Script': return GoogleFonts.dancingScript(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Caveat': return GoogleFonts.caveat(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Satisfy': return GoogleFonts.satisfy(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Great Vibes': return GoogleFonts.greatVibes(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Sacramento': return GoogleFonts.sacramento(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Kaushan Script': return GoogleFonts.kaushanScript(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Shadows Into Light': return GoogleFonts.shadowsIntoLight(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Indie Flower': return GoogleFonts.indieFlower(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Amatic SC': return GoogleFonts.amaticSc(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Cookie': return GoogleFonts.cookie(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Permanent Marker': return GoogleFonts.permanentMarker(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Press Start 2P': return GoogleFonts.pressStart2p(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Bungee': return GoogleFonts.bungee(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Bangers': return GoogleFonts.bangers(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Russo One': return GoogleFonts.russoOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Titan One': return GoogleFonts.titanOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Concert One': return GoogleFonts.concertOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Black Ops One': return GoogleFonts.blackOpsOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Orbitron': return GoogleFonts.orbitron(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Audiowide': return GoogleFonts.audiowide(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Leckerli One': return GoogleFonts.leckerliOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Courgette': return GoogleFonts.courgette(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Alfa Slab One': return GoogleFonts.alfaSlabOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Bree Serif': return GoogleFonts.breeSerif(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Acme': return GoogleFonts.acme(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      case 'Lilita One': return GoogleFonts.lilitaOne(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
      default: return GoogleFonts.notoSans(color: color, fontSize: fontSize, fontWeight: fontWeight, height: height);
    }
  }

  void _done() {
    if (_controller.text.trim().isEmpty) return;
    final position = widget.editingLayer?.position ?? const Offset(100, 200);
    widget.onAdd(TextLayer(
      position: position,
      text: _controller.text.trim(),
      fontSize: _fontSize,
      color: _selectedColor,
      opacity: _opacity,
      fontFamily: _selectedFont,
    ));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingLayer != null;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.only(top: 12.h, bottom: keyboardHeight > 0 ? keyboardHeight : 8.h),
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
            child: SingleChildScrollView(
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              isEditing ? 'Edit Text' : 'Text',
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Cross icon: closes the sheet (discard). The
                            // keyboard's Enter key now acts as "Done".
                            GestureDetector(
                              onTap: widget.onClose,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
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
                SizedBox(height: 14.h),

                // Text input with live preview styling
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 1,
                    // Single line: the Enter key submits the text (acts as Done).
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _done(),
                    style: _getGoogleFont(
                      _selectedFont,
                      color: _selectedColor.withValues(alpha: _opacity),
                      fontSize: (_fontSize > 36 ? 36 : _fontSize).sp,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Type your text...',
                      hintStyle: GoogleFonts.notoSans(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 16.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Tab selector
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, Icons.text_fields, 'Font'),
                        _buildTab(1, Icons.palette_outlined, 'Color'),
                        _buildTab(2, Icons.format_size, 'Size'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Tab content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildTabContent(),
                ),

                // Delete button for editing
                if (isEditing && widget.onDelete != null) ...[
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 18.sp),
                            SizedBox(width: 6.w),
                            Text(
                              'Delete Text',
                              style: GoogleFonts.notoSans(
                                color: Colors.redAccent,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDA5EF3), Color(0xFF9B40E6)],
                  )
                : null,
            borderRadius: BorderRadius.circular(15.r),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14.sp,
                  color: isActive ? Colors.white : Colors.white38),
              SizedBox(width: 4.w),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  color: isActive ? Colors.white : Colors.white38,
                  fontSize: 11.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildFontTab();
      case 1:
        return _buildColorTab();
      case 2:
        return _buildSizeTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Font Tab ---
  Widget _buildFontTab() {
    return SizedBox(
      key: const ValueKey('font_tab'),
      height: 90.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _fonts.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final font = _fonts[i];
          final isSelected = _selectedFont == font.name;
          return GestureDetector(
            onTap: () => setState(() => _selectedFont = font.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 72.r,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A1040), Color(0xFF1A0828)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFDA5EF3).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 0.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFDA5EF3).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    font.preview,
                    style: _getGoogleFont(
                      font.name,
                      color: isSelected
                          ? const Color(0xFFDA5EF3)
                          : Colors.white54,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    font.name.length > 10
                        ? '${font.name.substring(0, 9)}...'
                        : font.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: isSelected ? Colors.white70 : Colors.white30,
                      fontSize: 8.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Color Tab ---
  Widget _buildColorTab() {
    return Column(
      key: const ValueKey('color_tab'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color grid
        SizedBox(
          height: 46.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _colorSwatches.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (_, i) {
              final swatch = _colorSwatches[i];
              final isSelected = _selectedColor == swatch.color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = swatch.color),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34.r,
                      height: 34.r,
                      decoration: BoxDecoration(
                        color: swatch.color.withValues(alpha: _opacity),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFDA5EF3)
                              : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2.5 : 0.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: swatch.color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      swatch.name.length > 5
                          ? swatch.name.substring(0, 5)
                          : swatch.name,
                      style: GoogleFonts.notoSans(
                        color: isSelected ? Colors.white60 : Colors.white24,
                        fontSize: 7.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),

        // Opacity slider
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.opacity, color: Colors.white38, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'Opacity',
                style: GoogleFonts.notoSans(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: const Color(0xFFDA5EF3),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => setState(() => _opacity = v),
                  ),
                ),
              ),
              SizedBox(
                width: 32.w,
                child: Text(
                  '${(_opacity * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.notoSans(
                    color: Colors.white38,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Size Tab ---
  Widget _buildSizeTab() {
    return Padding(
      key: const ValueKey('size_tab'),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Size preview
          Container(
            height: 50.h,
            alignment: Alignment.center,
            child: Text(
              _controller.text.isEmpty ? 'Preview' : _controller.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _getGoogleFont(
                _selectedFont,
                color: _selectedColor.withValues(alpha: _opacity),
                fontSize: _fontSize.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.text_decrease,
                  color: Colors.white38, size: 18.sp),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: const Color(0xFFDA5EF3),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 72,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
              ),
              Icon(Icons.text_increase,
                  color: Colors.white38, size: 18.sp),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_fontSize.round()}',
                  style: GoogleFonts.notoSans(
                    color: Colors.white54,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontOption {
  final String name;
  final String preview;
  const _FontOption(this.name, this.preview);
}

class _ColorSwatch {
  final String name;
  final Color color;
  const _ColorSwatch(this.name, this.color);
}
