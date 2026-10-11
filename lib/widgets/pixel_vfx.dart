// The fight's skill and spell effects in pixel art (v1.221): every VfxStyle
// is a short plan of pixel strips (see tool/gen_fight_fx.py) laid on its
// target, or flown from its source to it. The strips are drawn in four flat
// tones; the game recolours them to the effect's element, so one strip
// serves every element. Until a strip is in (or with its tint made), the
// vector effect in combat_vfx.dart plays in its place.
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../combat/skill_vfx.dart';
import 'pixel_sprite.dart';

/// How a layer of a plan moves.
enum PixelMotion {
  /// Centred on the target.
  at,

  /// Flies from its source to the target (its head to the right).
  travel,

  /// Falls on the target from above and to the right (its head down).
  fall,
}

/// One strip of a plan, played over a window of the burst's time.
class PixelLayer {
  const PixelLayer(
    this.name, {
    this.motion = PixelMotion.at,
    this.t0 = 0,
    this.span = 1,
    this.anchor = const Offset(24, 24),
    this.size = 1,
    this.loop = false,
    this.hitOnly = false,
  });

  /// The strip's file, without `vfx_`.
  final String name;
  final PixelMotion motion;

  /// When it starts and how long it plays, as shares of the burst.
  final double t0;
  final double span;

  /// The strip's pixel that sits on the target (or travels along).
  final Offset anchor;

  /// How much bigger than the burst's pixel size it is drawn.
  final double size;

  /// A projectile's few frames repeat for as long as it flies.
  final bool loop;
  final bool hitOnly;

  String get asset => 'vfx_$name';
}

const _impactAt = PixelLayer('impact_s', t0: 0.45, span: 0.55);

/// The plan of every style that is a fixed list of layers; the volley and
/// the drain are laid out in code (see [paintPixelBurst]).
const Map<VfxStyle, List<PixelLayer>> pixelPlans = {
  VfxStyle.slash: [PixelLayer('slash')],
  VfxStyle.heavySlash: [PixelLayer('heavy')],
  VfxStyle.pierce: [PixelLayer('pierce')],
  VfxStyle.whirl: [PixelLayer('whirl')],
  VfxStyle.claw: [PixelLayer('claw')],
  VfxStyle.impact: [PixelLayer('impact')],
  VfxStyle.arrow: [
    PixelLayer('arrow_proj',
        motion: PixelMotion.travel, span: 0.45, loop: true),
    _impactAt,
  ],
  VfxStyle.bolt: [
    PixelLayer('orb',
        motion: PixelMotion.travel,
        span: 0.45,
        loop: true,
        anchor: Offset(32, 24)),
    PixelLayer('zap', t0: 0.45, span: 0.55),
  ],
  VfxStyle.lightning: [PixelLayer('lightning', anchor: Offset(24, 40))],
  VfxStyle.flame: [PixelLayer('flame', anchor: Offset(24, 40))],
  VfxStyle.fireball: [
    PixelLayer('orb',
        motion: PixelMotion.travel,
        span: 0.45,
        loop: true,
        anchor: Offset(32, 24),
        size: 1.3),
    PixelLayer('explosion', t0: 0.45, span: 0.55),
  ],
  VfxStyle.meteor: [
    PixelLayer('meteor_proj',
        motion: PixelMotion.fall,
        span: 0.4,
        loop: true,
        anchor: Offset(24, 30),
        size: 1.3),
    PixelLayer('explosion', t0: 0.4, span: 0.6, size: 1.4),
    PixelLayer('quake', t0: 0.4, span: 0.6, anchor: Offset(24, 34)),
  ],
  VfxStyle.holyFire: [PixelLayer('holy_beam', anchor: Offset(24, 40))],
  VfxStyle.frost: [PixelLayer('frost')],
  VfxStyle.splash: [PixelLayer('splash', anchor: Offset(24, 32))],
  VfxStyle.poison: [PixelLayer('poison', anchor: Offset(24, 32))],
  VfxStyle.smoke: [PixelLayer('smoke', anchor: Offset(24, 36))],
  VfxStyle.wind: [PixelLayer('wind')],
  VfxStyle.quake: [PixelLayer('quake', anchor: Offset(24, 34))],
  VfxStyle.voidRift: [PixelLayer('void_rift')],
  VfxStyle.drain: [PixelLayer('drain', span: 0.8)],
  VfxStyle.shadow: [PixelLayer('shadow', anchor: Offset(24, 40))],
  VfxStyle.radiance: [PixelLayer('radiance')],
  VfxStyle.heal: [PixelLayer('heal', anchor: Offset(24, 28))],
  VfxStyle.shield: [PixelLayer('shield', anchor: Offset(24, 26))],
  VfxStyle.stoneShield: [PixelLayer('stone_shield', anchor: Offset(24, 32))],
  VfxStyle.mana: [PixelLayer('mana', anchor: Offset(24, 26))],
  VfxStyle.shout: [PixelLayer('shout', anchor: Offset(24, 26))],
  VfxStyle.stun: [PixelLayer('stun', anchor: Offset(24, 14))],
  VfxStyle.weaken: [PixelLayer('weaken')],
  VfxStyle.crit: [PixelLayer('crit')],
  VfxStyle.miss: [PixelLayer('miss')],
  VfxStyle.phase: [PixelLayer('phase', size: 1.8)],
};

/// The strips a blow of [tier] adds under its landing.
List<PixelLayer> pixelTierLayers(VfxStyle style, VfxTier tier, bool hit) {
  if (!hit ||
      tier.index < VfxTier.strong.index ||
      systemVfxStyles.contains(style)) {
    return const [];
  }
  final at = vfxImpactAt(style);
  return [
    PixelLayer('shock',
        t0: at,
        span: 0.5,
        anchor: const Offset(24, 38),
        size: tier == VfxTier.mighty ? 1.4 : 1.0),
  ];
}

/// Every strip a style may use, for preloading.
Set<String> pixelAssetsFor(VfxStyle style) => {
      for (final l in pixelPlans[style] ?? const <PixelLayer>[]) l.asset,
      if (style == VfxStyle.volley) ...['vfx_arrow_proj', 'vfx_impact_s'],
      if (style == VfxStyle.drain) 'vfx_orb',
      'vfx_shock',
    };

/// Every strip any style uses, for the fight to start loading.
Set<String> get allPixelVfxAssets => {
      for (final style in VfxStyle.values) ...pixelAssetsFor(style),
    };

// ------------------------------------------------------------------ tints

/// The strips recoloured to an effect's palette, made once and kept.
class PixelVfxTints {
  PixelVfxTints._();

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _asked = {};

  /// The four tones the strips are drawn in: highlight, middle, shadow,
  /// deep (see tool/gen_fight_fx.py).
  static const List<int> _source = [0xFFFFFF, 0xC9D1DC, 0x5E6B7E, 0x2A303B];

  /// The tones [palette] recolours them to; null for the plain steel.
  static List<int>? tonesFor(VfxPalette palette) {
    if (palette.primary == 0xFFFFFFFF) return null;
    final mid = Color(palette.primary);
    final hi = Color.lerp(Color(palette.secondary), Colors.white, 0.4)!;
    final lo = Color.lerp(mid, Colors.black, 0.5)!;
    final deep = Color.lerp(mid, Colors.black, 0.78)!;
    int rgb(Color c) =>
        ((c.r * 255).round() << 16) |
        ((c.g * 255).round() << 8) |
        (c.b * 255).round();
    return [rgb(hi), rgb(mid), rgb(lo), rgb(deep)];
  }

  static String _key(String asset, VfxPalette palette) =>
      '$asset:${palette.primary}:${palette.secondary}';

  /// [asset] in [palette]'s colours, or null while it is made.
  static ui.Image? of(String asset, VfxPalette palette) {
    final tones = tonesFor(palette);
    final base = PixelStrips.of(asset);
    if (tones == null) return base;
    final key = _key(asset, palette);
    final made = _images[key];
    if (made == null && base != null && _asked.add(key)) {
      _make(key, base, tones);
    }
    return made;
  }

  static Future<void> _make(String key, ui.Image base, List<int> tones) async {
    try {
      final data = await base.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return;
      final bytes = Uint8List.fromList(data.buffer.asUint8List());
      for (var i = 0; i < bytes.length; i += 4) {
        if (bytes[i + 3] == 0) continue;
        final v = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
        final k = _source.indexOf(v);
        if (k < 0) continue;
        bytes[i] = (tones[k] >> 16) & 0xFF;
        bytes[i + 1] = (tones[k] >> 8) & 0xFF;
        bytes[i + 2] = tones[k] & 0xFF;
      }
      ui.decodeImageFromPixels(
          bytes, base.width, base.height, ui.PixelFormat.rgba8888, (image) {
        _images[key] = image;
        PixelStrips.loaded.value++;
      });
    } catch (_) {
      _asked.remove(key);
    }
  }

  /// Starts loading and recolouring what [style] plays in [palette].
  static void request(VfxStyle style, VfxPalette palette) {
    for (final asset in pixelAssetsFor(style)) {
      of(asset, palette);
    }
  }
}

// ---------------------------------------------------------------- painting

/// The pixel size a burst of size [s] (the target's, 40 to 110) is drawn
/// at, from how much of the target it covers ([extent], see
/// [vfxExtentFor]: a 48-pixel strip covers its pixel size times 48), in
/// half pixels from 1 to 4.5.
double pixelSizeFor(double s, double extent) =>
    (s * extent * 1.05 / 48 * 2).round().clamp(2, 9) / 2;

double _easeInOut(double t) {
  final x = t.clamp(0.0, 1.0);
  return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
}

/// Draws burst progress [t] of [style] in pixel art; false when a strip it
/// needs is not in yet (the caller draws the vector effect then).
bool paintPixelBurst(
  Canvas canvas, {
  required VfxStyle style,
  required VfxPalette palette,
  required VfxTier tier,
  required bool hit,
  required Rect rect,
  required Rect? sourceRect,
  required double t,
  required double s,
  required double extent,
}) {
  final layers = <PixelLayer>[];
  final c = rect.center;
  final unit = pixelSizeFor(s, extent);
  final paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  // The few layers the volley and the drain lay out in code.
  final extra = <(PixelLayer, Offset, Offset?)>[];
  if (style == VfxStyle.volley) {
    final arrows = switch (tier) {
      VfxTier.light => 2,
      VfxTier.normal => 3,
      VfxTier.strong => 5,
      VfxTier.mighty => 7,
    };
    final step = 0.3 / arrows;
    for (var i = 0; i < arrows; i++) {
      final lane = i - (arrows - 1) / 2;
      final from = Offset(
          c.dx - s * 1.4 + i * s * 0.22 * 5 / arrows, rect.top - s * 1.3);
      final to = Offset(
          c.dx + lane * s * 0.3 * 3 / arrows, c.dy + (i.isEven ? 0 : s * 0.12));
      extra.add((
        PixelLayer('arrow_proj',
            motion: PixelMotion.travel, t0: i * step, span: 0.4, loop: true),
        from,
        to
      ));
      extra.add((
        PixelLayer('impact_s', t0: i * step + 0.4, span: 0.4, size: 0.8),
        to,
        null
      ));
    }
  } else if (style == VfxStyle.drain) {
    layers.addAll(pixelPlans[style]!);
    final to = sourceRect?.center ?? Offset(c.dx, rect.top - s);
    extra.add((
      const PixelLayer('orb',
          motion: PixelMotion.travel,
          t0: 0.3,
          span: 0.5,
          loop: true,
          anchor: Offset(32, 24),
          size: 0.6),
      c,
      to,
    ));
  } else {
    layers.addAll(pixelPlans[style] ?? const []);
    layers.addAll(pixelTierLayers(style, tier, hit));
  }
  if (layers.isEmpty && extra.isEmpty) return false;

  // Every strip in first, or none drawn: no half a burst.
  for (final l in [...layers, for (final e in extra) e.$1]) {
    if (PixelVfxTints.of(l.asset, palette) == null) {
      PixelVfxTints.request(style, palette);
      return false;
    }
  }

  void draw(PixelLayer l, Offset at, Offset? to) {
    final lt = (t - l.t0) / l.span;
    if (lt < 0 || lt > 1) return;
    final image = PixelVfxTints.of(l.asset, palette)!;
    final side = image.height.toDouble();
    final frames = (image.width / side).round();
    final progress =
        l.loop && frames < 8 ? (lt * frames * 2.4) % frames : lt * frames;
    final i = progress.floor().clamp(0, frames - 1);
    final k = unit * l.size;
    var pos = at;
    var angle = 0.0;
    switch (l.motion) {
      case PixelMotion.at:
        break;
      case PixelMotion.travel:
        final from = to == null
            ? (sourceRect?.center ??
                Offset(rect.left - s * 1.2, c.dy - s * 0.8))
            : at;
        final dest = to ?? c;
        pos = Offset.lerp(from, dest, _easeInOut(lt))!;
        final d = dest - from;
        angle = d.distance == 0 ? 0 : atan2(d.dy, d.dx);
      case PixelMotion.fall:
        final from = Offset(c.dx + s * 1.3, rect.top - s * 2.2);
        pos = Offset.lerp(from, c, lt * lt)!;
        final d = c - from;
        angle = -atan2(d.dx, d.dy);
    }
    canvas.save();
    canvas.translate(pos.dx.roundToDouble(), pos.dy.roundToDouble());
    if (angle != 0) canvas.rotate(angle);
    final dst =
        Rect.fromLTWH(-l.anchor.dx * k, -l.anchor.dy * k, side * k, side * k);
    canvas.drawImageRect(
        image, Rect.fromLTWH(i * side, 0, side, side), dst, paint);
    canvas.restore();
  }

  for (final l in layers) {
    draw(l, c, null);
  }
  for (final (l, at, to) in extra) {
    draw(l, at, to);
  }
  return true;
}
