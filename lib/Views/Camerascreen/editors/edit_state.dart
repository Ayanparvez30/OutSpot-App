import 'dart:ui';

class TextLayer {
  Offset position;
  String text;
  double fontSize;
  Color color;
  double opacity;
  String fontFamily;

  TextLayer({
    required this.position,
    required this.text,
    this.fontSize = 24,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 1.0,
    this.fontFamily = 'Noto Sans',
  });
}

enum BrushType { pen, marker, neon, highlighter, eraser }

class DrawPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final BrushType brushType;

  DrawPath({
    required this.points,
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 4.0,
    this.opacity = 1.0,
    this.brushType = BrushType.pen,
  });
}

class EmojiLayer {
  Offset position;
  String emoji;
  double scale;

  EmojiLayer({
    required this.position,
    required this.emoji,
    this.scale = 1.0,
  });
}

class PixelateRegion {
  final Rect rect;
  final int blockSize;

  PixelateRegion({required this.rect, this.blockSize = 10});
}

class BlurRegion {
  final Rect rect;
  final double radius;

  BlurRegion({required this.rect, this.radius = 10.0});
}

class TuneData {
  double brightness;
  double contrast;
  double saturation;

  TuneData({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
  });

  bool get hasChanges =>
      brightness.abs() > 0.001 || contrast.abs() > 0.001 || saturation.abs() > 0.001;

  List<double> toColorMatrix() {
    // Build each adjustment as a separate matrix, then compose them

    // Brightness matrix
    final b = brightness * 100;
    final brightnessMatrix = <double>[
      1, 0, 0, 0, b,
      0, 1, 0, 0, b,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ];

    // Contrast matrix
    final c = 1 + contrast;
    final t = 128 * (1 - c);
    final contrastMatrix = <double>[
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ];

    // Saturation matrix
    final s = 1 + saturation;
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;
    final saturationMatrix = <double>[
      lr * (1 - s) + s, lg * (1 - s),     lb * (1 - s),     0, 0,
      lr * (1 - s),     lg * (1 - s) + s, lb * (1 - s),     0, 0,
      lr * (1 - s),     lg * (1 - s),     lb * (1 - s) + s, 0, 0,
      0,                0,                0,                1, 0,
    ];

    // Compose: brightness * contrast * saturation
    var result = _multiply4x5(brightnessMatrix, contrastMatrix);
    result = _multiply4x5(result, saturationMatrix);
    return result;
  }

  static List<double> _multiply4x5(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        // Add the translation component
        if (col == 4) sum += a[row * 5 + 4];
        result[row * 5 + col] = sum;
      }
    }
    return result;
  }
}

class FilterPreset {
  final String name;
  final List<double> matrix;

  const FilterPreset({required this.name, required this.matrix});

  static const List<FilterPreset> presets = [
    // --- Identity ---
    FilterPreset(
      name: 'Original',
      matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    ),

    // --- Warm / Golden Hour ---
    FilterPreset(
      name: 'Warm',
      matrix: [1.2, 0, 0, 0, 10, 0, 1.0, 0, 0, 0, 0, 0, 0.8, 0, -10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Golden',
      matrix: [1.2, 0.1, 0, 0, 15, 0, 1.05, 0.05, 0, 8, 0, 0, 0.75, 0, -15, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Sunset',
      matrix: [1.3, 0.15, 0, 0, 20, 0, 0.95, 0.05, 0, 5, 0, 0, 0.7, 0, -20, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Honey',
      matrix: [1.15, 0.08, 0.02, 0, 12, 0.05, 1.08, 0.02, 0, 8, 0, 0.02, 0.85, 0, -5, 0, 0, 0, 1, 0],
    ),

    // --- Cool / Blue Tones ---
    FilterPreset(
      name: 'Cool',
      matrix: [0.8, 0, 0, 0, -10, 0, 1.0, 0, 0, 0, 0, 0, 1.2, 0, 10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Arctic',
      matrix: [0.75, 0.05, 0.1, 0, -15, 0, 0.9, 0.1, 0, 5, 0.1, 0.1, 1.3, 0, 20, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Ocean',
      matrix: [0.7, 0, 0.1, 0, -5, 0, 1.0, 0.15, 0, 5, 0, 0.05, 1.25, 0, 15, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Frost',
      matrix: [0.85, 0.05, 0.1, 0, 10, 0.05, 0.95, 0.1, 0, 15, 0.1, 0.1, 1.15, 0, 25, 0, 0, 0, 1, 0],
    ),

    // --- Vintage / Retro ---
    FilterPreset(
      name: 'Vintage',
      matrix: [0.9, 0.1, 0.1, 0, 20, 0.05, 0.85, 0.05, 0, 10, 0.05, 0.05, 0.75, 0, -10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Retro',
      matrix: [0.85, 0.15, 0.05, 0, 25, 0.1, 0.8, 0.05, 0, 15, 0, 0.05, 0.7, 0, -5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: '70s',
      matrix: [1.1, 0.15, 0.05, 0, 15, 0, 0.95, 0.05, 0, 10, -0.05, 0.05, 0.7, 0, -15, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Polaroid',
      matrix: [1.1, 0.1, 0.08, 0, 10, 0, 1.0, 0.05, 0, 5, -0.05, 0, 0.85, 0, -10, 0, 0, 0, 1, 0],
    ),

    // --- B&W / Mono ---
    FilterPreset(
      name: 'B&W',
      matrix: [0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Noir',
      matrix: [0.4, 0.35, 0.25, 0, -20, 0.3, 0.35, 0.25, 0, -20, 0.2, 0.3, 0.25, 0, -20, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Silver',
      matrix: [0.35, 0.4, 0.25, 0, 15, 0.35, 0.4, 0.25, 0, 15, 0.35, 0.4, 0.25, 0, 15, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Ink',
      matrix: [0.5, 0.3, 0.2, 0, -35, 0.5, 0.3, 0.2, 0, -35, 0.5, 0.3, 0.2, 0, -35, 0, 0, 0, 1, 0],
    ),

    // --- Sepia / Brown ---
    FilterPreset(
      name: 'Sepia',
      matrix: [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Coffee',
      matrix: [0.95, 0.15, 0.05, 0, 15, 0.05, 0.8, 0.05, 0, 5, 0, 0.05, 0.65, 0, -15, 0, 0, 0, 1, 0],
    ),

    // --- Vivid / Pop ---
    FilterPreset(
      name: 'Vivid',
      matrix: [1.3, -0.1, -0.1, 0, 10, -0.1, 1.3, -0.1, 0, 10, -0.1, -0.1, 1.3, 0, 10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Pop',
      matrix: [1.4, -0.15, -0.1, 0, 5, -0.15, 1.4, -0.1, 0, 5, -0.1, -0.15, 1.4, 0, 5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Electric',
      matrix: [1.5, -0.2, -0.1, 0, 15, -0.1, 1.5, -0.2, 0, 15, -0.2, -0.1, 1.5, 0, 15, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Neon',
      matrix: [1.4, -0.1, 0.2, 0, 10, -0.1, 1.3, -0.05, 0, 5, 0.2, -0.1, 1.4, 0, 10, 0, 0, 0, 1, 0],
    ),

    // --- Fade / Matte ---
    FilterPreset(
      name: 'Fade',
      matrix: [0.8, 0, 0, 0, 30, 0, 0.8, 0, 0, 30, 0, 0, 0.8, 0, 30, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Matte',
      matrix: [0.85, 0, 0, 0, 25, 0, 0.85, 0, 0, 25, 0, 0, 0.85, 0, 25, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Haze',
      matrix: [0.9, 0.05, 0.05, 0, 35, 0.05, 0.9, 0.05, 0, 35, 0.05, 0.05, 0.9, 0, 35, 0, 0, 0, 1, 0],
    ),

    // --- Cinematic / Film ---
    FilterPreset(
      name: 'Cinema',
      matrix: [1.1, 0, 0.1, 0, -5, 0, 1.05, 0.05, 0, 0, -0.05, 0.1, 1.1, 0, 10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Film',
      matrix: [1.05, 0.05, 0, 0, 10, 0, 1.0, 0, 0, 5, -0.05, 0, 0.9, 0, 5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Drama',
      matrix: [1.2, 0.1, 0.05, 0, -10, 0, 1.0, 0.05, 0, -5, -0.05, 0.05, 0.9, 0, -5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Teal',
      matrix: [0.8, 0.05, 0.1, 0, -5, 0, 1.1, 0.1, 0, 5, 0.05, 0.05, 1.05, 0, 10, 0, 0, 0, 1, 0],
    ),

    // --- Moody / Dark ---
    FilterPreset(
      name: 'Moody',
      matrix: [0.9, 0.05, 0.05, 0, -15, 0, 0.85, 0.05, 0, -10, 0.05, 0.05, 0.9, 0, -5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Shadow',
      matrix: [0.85, 0, 0, 0, -25, 0, 0.85, 0, 0, -25, 0, 0, 0.85, 0, -25, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Dim',
      matrix: [0.8, 0.05, 0.05, 0, -10, 0.05, 0.8, 0.05, 0, -10, 0.05, 0.05, 0.8, 0, -10, 0, 0, 0, 1, 0],
    ),

    // --- Pink / Purple ---
    FilterPreset(
      name: 'Rose',
      matrix: [1.15, 0.1, 0.1, 0, 10, 0, 0.9, 0.05, 0, -5, 0.1, 0.05, 1.0, 0, 5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Blush',
      matrix: [1.1, 0.15, 0.05, 0, 15, 0, 0.85, 0, 0, -5, 0.05, 0.05, 0.95, 0, 5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Lilac',
      matrix: [1.0, 0.05, 0.15, 0, 10, 0, 0.85, 0.1, 0, 0, 0.15, 0.05, 1.1, 0, 15, 0, 0, 0, 1, 0],
    ),

    // --- Green / Nature ---
    FilterPreset(
      name: 'Forest',
      matrix: [0.85, 0.05, 0, 0, -5, 0.1, 1.15, 0.05, 0, 5, 0, 0.05, 0.85, 0, -10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Spring',
      matrix: [0.95, 0.05, 0, 0, 5, 0.05, 1.15, 0.05, 0, 10, 0, 0.05, 0.9, 0, 0, 0, 0, 0, 1, 0],
    ),

    // --- Special ---
    FilterPreset(
      name: 'Dreamy',
      matrix: [1.0, 0.1, 0.1, 0, 20, 0.05, 1.0, 0.1, 0, 20, 0.1, 0.1, 1.0, 0, 20, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Glow',
      matrix: [1.15, 0.05, 0.05, 0, 20, 0.05, 1.15, 0.05, 0, 20, 0.05, 0.05, 1.15, 0, 20, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Crisp',
      matrix: [1.2, -0.05, -0.05, 0, -5, -0.05, 1.2, -0.05, 0, -5, -0.05, -0.05, 1.2, 0, -5, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      name: 'Pastel',
      matrix: [0.9, 0.1, 0.1, 0, 30, 0.1, 0.9, 0.1, 0, 30, 0.1, 0.1, 0.9, 0, 30, 0, 0, 0, 1, 0],
    ),
  ];
}

class VideoEditState {
  double brightness;
  double trimStart;
  double trimEnd;
  int rotation; // 0, 90, 180, 270
  double speed; // 0.25 to 4.0
  String? cropRatio; // null = free, or "16:9", "9:16", "1:1", "4:3", "3:4"
  String? flipDirection; // null, "horizontal", "vertical"

  VideoEditState({
    this.brightness = 0.0,
    this.trimStart = 0.0,
    this.trimEnd = 0.0,
    this.rotation = 0,
    this.speed = 1.0,
    this.cropRatio,
    this.flipDirection,
  });

  bool get hasBrightnessChange => brightness.abs() > 0.001;
  bool get hasTrim => trimStart > 0.01 || trimEnd > 0.01;
  bool get hasRotation => rotation != 0;
  bool get hasSpeed => (speed - 1.0).abs() > 0.01;
  bool get hasCrop => cropRatio != null;
  bool get hasFlip => flipDirection != null;
  bool get hasEdits =>
      hasBrightnessChange || hasTrim || hasRotation || hasSpeed || hasCrop || hasFlip;
}

enum ActiveEditor {
  none,
  text,
  draw,
  emoji,
  pixelate,
  blur,
  crop,
  tune,
  filter,
  videoTrim,
  videoCrop,
  videoRotate,
  videoSpeed,
  videoFlip,
}

class EditState {
  final List<TextLayer> textLayers = [];
  final List<DrawPath> drawPaths = [];
  final List<EmojiLayer> emojiLayers = [];
  final List<PixelateRegion> pixelateRegions = [];
  final List<BlurRegion> blurRegions = [];
  TuneData tuneData = TuneData();
  FilterPreset? selectedFilter;
  VideoEditState videoEditState = VideoEditState();

  bool get hasEdits =>
      textLayers.isNotEmpty ||
      drawPaths.isNotEmpty ||
      emojiLayers.isNotEmpty ||
      pixelateRegions.isNotEmpty ||
      blurRegions.isNotEmpty ||
      tuneData.hasChanges ||
      (selectedFilter != null && selectedFilter!.name != 'Original');
}
