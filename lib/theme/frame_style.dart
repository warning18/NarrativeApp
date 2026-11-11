// The frame design system (old iron, v1.912): the material a frame is made of
// (wood, then iron, silver, gilt as the story goes on), the environment
// decorations that sit on its edges and corners (plants, sand, snow...), and
// the one shape, [FrameBorder], that paints both around any panel, card,
// dialog or button. The files are Art's kit (art/pixellab-iron-kit, bundled
// in assets/ui/frames): a 9-slice for each piece, drawn at a whole number of
// pixels per art pixel, with the edges TILED (never stretched).
//
// Tokens, in one place:
//  * [FrameMaterial]: the tier, one token read from the player's progress.
//  * [EnvDecor]: the place's decoration set, from the zone or biome.
//  * [FramePiece]: the kit's pieces with their size and 9-slice margin.
//  * scale: 1 for compact HUD panels, 2 for dialogs and big panels (the
//    16/32 pixel scale of the icons, one art pixel = scale logical pixels).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What a frame is made of: the interface gets less cheap as the story goes
/// on (wood, iron, silver, gilt).
enum FrameMaterial { wood, iron, silver, gilt }

/// The decorations of a place that sit on a frame's top edge and corners,
/// separate from the material: they are the same on every tier.
enum EnvDecor {
  none,
  wilds,
  dunes,
  frost,
  coast,
  ash,
  city,
  sacredVoid,

  /// The Tower's three sets, by band: night (chains, wax), stone (cracks,
  /// rubble), void (violet cracks).
  towerNight,
  towerStone,
  towerVoid;

  /// The file prefix of the set in assets/ui/frames/env.
  String get file => switch (this) {
        sacredVoid => 'sacred_void',
        towerNight => 'tower_night',
        towerStone => 'tower_stone',
        towerVoid => 'tower_void',
        _ => name,
      };
}

/// The pieces of the kit a [FrameBorder] can wear: the file, the art size
/// and the 9-slice margin (art/pixellab-iron-kit/anchors.json).
enum FramePiece {
  panelDark('panel_dark', 24, 8),
  panelParchment('panel_parchment', 24, 8),
  hudPanel('hud_panel', 16, 5),
  dialog('dialog', 32, 12),
  chip('chip', 16, 5),
  buttonPrimary('button_primary_normal', 24, 6),
  buttonPrimaryPressed('button_primary_pressed', 24, 6),
  buttonPrimaryDisabled('button_primary_disabled', 24, 6),
  buttonSecondary('button_secondary_normal', 24, 6),
  buttonSecondaryPressed('button_secondary_pressed', 24, 6),
  buttonSecondaryDisabled('button_secondary_disabled', 24, 6);

  const FramePiece(this.file, this.size, this.slice);
  final String file;

  /// The width of the art in pixels (the pieces are square but the buttons,
  /// which are [size] x 16); the margin is [slice] pixels on every side.
  final int size;
  final int slice;
}

/// The theme's frame tokens: the material of every frame and the place's
/// decorations. Put one in `ThemeData.extensions` (or override it for a
/// subtree with `Theme`).
@immutable
class FrameStyle extends ThemeExtension<FrameStyle> {
  const FrameStyle({
    this.material = FrameMaterial.iron,
    this.env = EnvDecor.none,
    this.compactScale = 1,
    this.largeScale = 2,
  });

  final FrameMaterial material;
  final EnvDecor env;
  final double compactScale;
  final double largeScale;

  static FrameStyle of(BuildContext context) =>
      Theme.of(context).extension<FrameStyle>() ?? const FrameStyle();

  @override
  FrameStyle copyWith({
    FrameMaterial? material,
    EnvDecor? env,
    double? compactScale,
    double? largeScale,
  }) =>
      FrameStyle(
        material: material ?? this.material,
        env: env ?? this.env,
        compactScale: compactScale ?? this.compactScale,
        largeScale: largeScale ?? this.largeScale,
      );

  @override
  FrameStyle lerp(FrameStyle? other, double t) =>
      t < 0.5 ? this : other ?? this;
}

/// The kit's images, loaded once. A frame whose image is not loaded yet
/// paints nothing (its fill still shows); [loaded] changes when one arrives.
abstract final class FrameImages {
  static final Map<String, ui.Image> _images = {};
  static final Set<String> _loading = {};
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  static String _key(String dir, String file) =>
      'assets/ui/frames/$dir/$file.png';

  static ui.Image? image(String dir, String file) {
    final key = _key(dir, file);
    final got = _images[key];
    if (got == null && _loading.add(key)) _load(key);
    return got;
  }

  static ui.Image? piece(FrameMaterial m, FramePiece p) =>
      image(m.name, p.file);

  static Future<void> _load(String key) async {
    try {
      final data = await rootBundle.load(key);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[key] = (await codec.getNextFrame()).image;
      loaded.value++;
    } catch (_) {
      // A missing file leaves the frame bare.
    }
  }

  static List<String> _keys(FrameMaterial m, EnvDecor env) => [
        for (final p in FramePiece.values) _key(m.name, p.file),
        if (env != EnvDecor.none)
          for (final part in ['top', 'bottom', 'corner'])
            for (var i = 0; i < 3; i++) _key('env', '${env.file}_${part}_$i'),
      ];

  /// Whether every piece of [m] and sprite of [env] is loaded.
  static bool ready(FrameMaterial m, EnvDecor env) =>
      _keys(m, env).every(_images.containsKey);

  /// Loads a material's pieces and an environment's sprites ahead of use.
  static Future<void> preload(FrameMaterial m, EnvDecor env) async {
    await Future.wait([
      for (final k in _keys(m, env))
        if (!_images.containsKey(k)) _load(k),
    ]);
  }

  /// Every material's pieces, without waiting.
  static void preloadAll() {
    for (final m in FrameMaterial.values) {
      preload(m, EnvDecor.none);
    }
    for (final e in const [
      EnvDecor.towerNight,
      EnvDecor.towerStone,
      EnvDecor.towerVoid,
    ]) {
      preload(FrameMaterial.wood, e);
    }
  }

  static void reset() {
    _images.clear();
    _loading.clear();
  }
}

/// A frame: the piece's 9-slice drawn around the box, corners as they are,
/// edges tiled, then the environment's decorations on the top edge and
/// corners. The fill is the caller's (`Card.color`, `ShapeDecoration.color`).
class FrameBorder extends OutlinedBorder {
  const FrameBorder({
    this.piece = FramePiece.panelDark,
    this.material = FrameMaterial.iron,
    this.env = EnvDecor.none,
    this.pixel = 1,
    this.seed = 0,
    this.fillCenter = false,
    this.envPixel = 1,
    this.plate,
  }) : super(side: BorderSide.none);

  final FramePiece piece;
  final FrameMaterial material;
  final EnvDecor env;

  /// Logical pixels per art pixel: 1 for compact panels, 2 for big ones.
  final double pixel;

  /// Paints the art's own middle too (the buttons, whose fill is part of
  /// the art), stretched; panels leave the fill to the caller.
  final bool fillCenter;

  /// Logical pixels per art pixel of the decorations: always 1, so they never
  /// grow over the text of a panel drawn at 2.
  final double envPixel;

  /// Picks the decoration variants, so a panel never changes between frames.
  final int seed;

  /// A flat colour laid on the middle of a button over the art, so its label
  /// reads on the grain of a wood button (no art is redrawn).
  final Color? plate;

  double get _inset => piece.slice * pixel;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(_inset * 0.5);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect.deflate(_inset * 0.5));

  /// The box with its four corners cut by a step, as the kit's corners are.
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final c = pixel * 2;
    return Path()
      ..moveTo(rect.left + c, rect.top)
      ..lineTo(rect.right - c, rect.top)
      ..lineTo(rect.right, rect.top + c)
      ..lineTo(rect.right, rect.bottom - c)
      ..lineTo(rect.right - c, rect.bottom)
      ..lineTo(rect.left + c, rect.bottom)
      ..lineTo(rect.left, rect.bottom - c)
      ..lineTo(rect.left, rect.top + c)
      ..close();
  }

  @override
  FrameBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final img = FrameImages.piece(material, piece);
    if (img == null) return;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final sl = piece.slice.toDouble();
    final iw = img.width.toDouble();
    final ih = img.height.toDouble();
    final s = _inset;
    final k = pixel;

    void blit(Rect src, Rect dst) => canvas.drawImageRect(img, src, dst, paint);

    if (fillCenter) {
      blit(
        Rect.fromLTWH(sl, sl, iw - 2 * sl, ih - 2 * sl),
        Rect.fromLTWH(
          rect.left + s,
          rect.top + s,
          rect.width - 2 * s,
          rect.height - 2 * s,
        ),
      );
    }
    if (plate != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + s,
          rect.top + s,
          rect.width - 2 * s,
          rect.height - 2 * s,
        ),
        Paint()..color = plate!,
      );
    }
    // Corners.
    blit(Rect.fromLTWH(0, 0, sl, sl), Rect.fromLTWH(rect.left, rect.top, s, s));
    blit(
      Rect.fromLTWH(iw - sl, 0, sl, sl),
      Rect.fromLTWH(rect.right - s, rect.top, s, s),
    );
    blit(
      Rect.fromLTWH(0, ih - sl, sl, sl),
      Rect.fromLTWH(rect.left, rect.bottom - s, s, s),
    );
    blit(
      Rect.fromLTWH(iw - sl, ih - sl, sl, sl),
      Rect.fromLTWH(rect.right - s, rect.bottom - s, s, s),
    );

    // Edges, tiled: the middle strip of the art repeated, the last tile cut.
    final midW = iw - 2 * sl;
    final midH = ih - 2 * sl;
    if (midW > 0) {
      final tile = midW * k;
      for (var x = rect.left + s; x < rect.right - s - 0.01; x += tile) {
        final w = (rect.right - s - x).clamp(0.0, tile);
        blit(Rect.fromLTWH(sl, 0, w / k, sl), Rect.fromLTWH(x, rect.top, w, s));
        blit(
          Rect.fromLTWH(sl, ih - sl, w / k, sl),
          Rect.fromLTWH(x, rect.bottom - s, w, s),
        );
      }
    }
    if (midH > 0) {
      final tile = midH * k;
      for (var y = rect.top + s; y < rect.bottom - s - 0.01; y += tile) {
        final h = (rect.bottom - s - y).clamp(0.0, tile);
        blit(
          Rect.fromLTWH(0, sl, sl, h / k),
          Rect.fromLTWH(rect.left, y, s, h),
        );
        blit(
          Rect.fromLTWH(iw - sl, sl, sl, h / k),
          Rect.fromLTWH(rect.right - s, y, s, h),
        );
      }
    }
    if (env != EnvDecor.none) _paintEnv(canvas, rect, paint);
  }

  int _hash(int i) {
    var h = seed * 73856093 ^ i * 19349663;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)).abs();
  }

  void _paintEnv(Canvas canvas, Rect rect, Paint paint) {
    final k = envPixel;
    ui.Image? sprite(String part, int variant) =>
        FrameImages.image('env', '${env.file}_${part}_${variant % 3}');

    // The top edge: 32 x 10 tiles side by side overlapping by 4 px, the
    // variant cycling; kept clear of the corners (16 px each side).
    final cornerW = 16 * k;
    final from = rect.left + cornerW;
    final to = rect.right - cornerW;
    if (to - from > 24 * k) {
      var i = 0;
      for (var x = from; x < to - 0.01; x += 28 * k, i++) {
        final img = sprite('top', _hash(i));
        if (img == null) continue;
        final w = (to - x).clamp(0.0, 32 * k);
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, w / k, img.height.toDouble()),
          Rect.fromLTWH(x, rect.top, w, img.height * k),
          paint,
        );
      }
    }
    // The corners: the top-left sprite, mirrored for the others.
    for (var c = 0; c < 4; c++) {
      final img = sprite('corner', _hash(100 + c));
      if (img == null) continue;
      final right = c.isOdd;
      final bottom = c >= 2;
      if (bottom && rect.height < 48 * k) continue;
      canvas.save();
      final x = right ? rect.right : rect.left;
      final y = bottom ? rect.bottom : rect.top;
      canvas.translate(x, y);
      canvas.scale(right ? -k : k, bottom ? -k : k);
      canvas.drawImage(img, Offset.zero, paint);
      canvas.restore();
    }
  }

  @override
  FrameBorder copyWith({
    BorderSide? side,
    FramePiece? piece,
    FrameMaterial? material,
    EnvDecor? env,
    double? pixel,
    int? seed,
    bool? fillCenter,
    Color? plate,
  }) =>
      FrameBorder(
        piece: piece ?? this.piece,
        material: material ?? this.material,
        env: env ?? this.env,
        pixel: pixel ?? this.pixel,
        seed: seed ?? this.seed,
        fillCenter: fillCenter ?? this.fillCenter,
        envPixel: envPixel,
        plate: plate ?? this.plate,
      );

  @override
  bool operator ==(Object other) =>
      other is FrameBorder &&
      other.piece == piece &&
      other.material == material &&
      other.env == env &&
      other.pixel == pixel &&
      other.seed == seed &&
      other.fillCenter == fillCenter &&
      other.plate == plate;

  @override
  int get hashCode =>
      Object.hash(piece, material, env, pixel, seed, fillCenter, plate);
}
