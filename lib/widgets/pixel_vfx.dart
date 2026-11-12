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
import '../theme/palette.dart';
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

/// The turn that brings a strip drawn head to the lower left (3 pi over 4)
/// to a head to the right, the way a travel expects it.
const double _headLeft = -3 * pi / 4;

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
    this.fade = false,
    this.frameFrom = 0,
    this.frameTo = -1,
    this.tilt = 0,
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

  /// The frames of the strip it plays: from [frameFrom] up to (not
  /// including) [frameTo], the whole strip when [frameTo] is negative. A
  /// strip that holds a flight and its burst is cut in two layers.
  final int frameFrom;
  final int frameTo;

  /// A turn, in radians, so the strip's head leads along a travel: the
  /// strips are drawn diagonally, head to the lower left (3 pi over 4 on the
  /// screen), so a flight turns them by minus that.
  final double tilt;

  /// The last third of the strip shrinks and fades out in code (the flame
  /// and the heal: their last frames are not drawn to vanish).
  final bool fade;

  String get asset => 'vfx_$name';
}

/// The plan of every style that is a fixed list of layers; the drain is
/// laid out in code (see [paintPixelBurst]).
const Map<VfxStyle, List<PixelLayer>> pixelPlans = {
  // Art's Apollo strips: each effect is one strip drawn at the target; the
  // ones that end with the object still in view fade out in code.
  VfxStyle.slash: [PixelLayer('slash', fade: true)],
  VfxStyle.heavySlash: [PixelLayer('heavy_slash', fade: true)],
  VfxStyle.pierce: [PixelLayer('pierce', fade: true)],
  VfxStyle.whirl: [PixelLayer('whirl')],
  VfxStyle.claw: [PixelLayer('claw', fade: true)],
  VfxStyle.impact: [PixelLayer('impact')],
  // The arrow, the fireball and the volley keep their flight from the
  // caster; Art's strip holds the flight (head to the lower left, turned
  // along the path) and the burst, cut in two layers.
  VfxStyle.arrow: [
    PixelLayer('arrow',
        motion: PixelMotion.travel,
        span: 0.45,
        loop: true,
        anchor: Offset(8, 38),
        frameFrom: 4,
        tilt: _headLeft),
    PixelLayer('arrow', t0: 0.45, span: 0.55, frameTo: 4, fade: true),
  ],
  VfxStyle.volley: [
    PixelLayer('volley',
        motion: PixelMotion.travel,
        span: 0.7,
        anchor: Offset(8, 38),
        tilt: _headLeft),
    PixelLayer('volley', t0: 0.7, span: 0.3, frameFrom: 8, fade: true),
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
  VfxStyle.flame: [PixelLayer('flame', anchor: Offset(24, 40), fade: true)],
  VfxStyle.fireball: [
    PixelLayer('fireball',
        motion: PixelMotion.travel,
        span: 0.45,
        loop: true,
        anchor: Offset(17, 28),
        size: 1.3,
        frameTo: 6,
        tilt: _headLeft),
    PixelLayer('fireball', t0: 0.45, span: 0.55, frameFrom: 6, size: 1.3),
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
  VfxStyle.holyFire: [
    PixelLayer('holy_fire', anchor: Offset(24, 40), fade: true)
  ],
  VfxStyle.frost: [PixelLayer('frost')],
  VfxStyle.splash: [PixelLayer('splash', anchor: Offset(24, 32), fade: true)],
  VfxStyle.poison: [PixelLayer('poison', anchor: Offset(24, 32), fade: true)],
  VfxStyle.smoke: [PixelLayer('smoke', anchor: Offset(24, 36))],
  VfxStyle.wind: [PixelLayer('wind', fade: true)],
  VfxStyle.quake: [PixelLayer('quake', anchor: Offset(24, 34))],
  VfxStyle.voidRift: [PixelLayer('void_rift')],
  VfxStyle.drain: [PixelLayer('drain', span: 0.8)],
  VfxStyle.shadow: [PixelLayer('shadow', anchor: Offset(24, 40))],
  VfxStyle.radiance: [PixelLayer('radiance')],
  VfxStyle.heal: [PixelLayer('heal', anchor: Offset(24, 28), fade: true)],
  VfxStyle.shield: [PixelLayer('shield', anchor: Offset(24, 26))],
  VfxStyle.stoneShield: [
    PixelLayer('stone_shield', anchor: Offset(24, 32), fade: true)
  ],
  VfxStyle.mana: [PixelLayer('mana', anchor: Offset(24, 26))],
  VfxStyle.shout: [PixelLayer('shout', anchor: Offset(24, 26))],
  VfxStyle.stun: [PixelLayer('stun', anchor: Offset(24, 14))],
  VfxStyle.weaken: [PixelLayer('weaken')],
  VfxStyle.crit: [PixelLayer('crit')],
  VfxStyle.miss: [PixelLayer('miss')],
  VfxStyle.phase: [PixelLayer('phase', size: 1.8)],
};

/// The styles drawn in Art's Apollo strips, which carry their own impact:
/// the pale ground ring a strong blow adds is the old look and fights their
/// warm colours, so they go without it. The styles still on the old strips
/// (the bolt, the meteor, the quake, the smoke) keep it.
const Set<VfxStyle> _apolloImpact = {
  VfxStyle.slash,
  VfxStyle.heavySlash,
  VfxStyle.pierce,
  VfxStyle.whirl,
  VfxStyle.claw,
  VfxStyle.impact,
  VfxStyle.arrow,
  VfxStyle.volley,
  VfxStyle.lightning,
  VfxStyle.flame,
  VfxStyle.fireball,
  VfxStyle.holyFire,
  VfxStyle.frost,
  VfxStyle.splash,
  VfxStyle.poison,
  VfxStyle.wind,
  VfxStyle.voidRift,
  VfxStyle.drain,
  VfxStyle.shadow,
  VfxStyle.radiance,
};

/// The strips a blow of [tier] adds under its landing.
List<PixelLayer> _pixelTierLayers(VfxStyle style, VfxTier tier, bool hit) {
  if (!hit ||
      tier.index < VfxTier.strong.index ||
      systemVfxStyles.contains(style) ||
      _apolloImpact.contains(style)) {
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
    final own = palette.tones;
    if (own != null) return [for (final t in own) t & 0xFFFFFF];
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

  /// Which of the four tones each colour of a strip takes: a strip drawn in
  /// the four tones of [_source] maps them one to one; any other palette
  /// (Art's skill strips, v1.915: five colours and an ink) is ranked by
  /// brightness and split into four runs, the brightest to the highlight and
  /// the darkest (the ink) to the deep tone.
  static Map<int, int> toneRanks(Uint8List bytes) {
    final colours = <int>{};
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i + 3] == 0) continue;
      colours.add((bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2]);
    }
    if (colours.every(_source.contains)) {
      return {for (final c in colours) c: _source.indexOf(c)};
    }
    double lum(int c) =>
        0.299 * ((c >> 16) & 0xFF) +
        0.587 * ((c >> 8) & 0xFF) +
        0.114 * (c & 0xFF);
    final sorted = colours.toList()..sort((a, b) => lum(b).compareTo(lum(a)));
    final n = sorted.length;
    return {
      for (var r = 0; r < n; r++)
        sorted[r]: n <= 1 ? 1 : (r * 4 ~/ n).clamp(0, 3),
    };
  }

  static Future<void> _make(String key, ui.Image base, List<int> tones) async {
    try {
      final data = await base.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return;
      final bytes = Uint8List.fromList(data.buffer.asUint8List());
      final ranks = toneRanks(bytes);
      for (var i = 0; i < bytes.length; i += 4) {
        if (bytes[i + 3] == 0) continue;
        final v = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
        final k = ranks[v] ?? -1;
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

/// How far a fading strip has gone out at the share [lt] of its time: 0 until
/// its last third, then 0 to 1 (eased), so it shrinks and thins away.
double pixelFadeOut(double lt) {
  final x = ((lt - 2 / 3) * 3).clamp(0.0, 1.0);
  return x * x;
}

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
  if (style == VfxStyle.drain) {
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
    layers.addAll(_pixelTierLayers(style, tier, hit));
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
    final strip = (image.width / side).round();
    final first = l.frameFrom.clamp(0, strip - 1);
    final end = l.frameTo < 0 ? strip : l.frameTo.clamp(first + 1, strip);
    final frames = end - first;
    final progress =
        l.loop && frames < 8 ? (lt * frames * 2.4) % frames : lt * frames;
    final i = first + progress.floor().clamp(0, frames - 1);
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
    if (angle != 0 || l.tilt != 0) canvas.rotate(angle + l.tilt);
    // A fading strip (flame, heal): the last third shrinks toward its anchor
    // and fades, in whole pixels.
    final out = l.fade ? pixelFadeOut(lt) : 0.0;
    final kk = k * (1 - 0.3 * out);
    final dst = Rect.fromLTWH(
        -l.anchor.dx * kk, -l.anchor.dy * kk, side * kk, side * kk);
    final drawPaint = out > 0
        ? (Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false
          ..color = Color.fromRGBO(0, 0, 0, 1 - out))
        : paint;
    canvas.drawImageRect(
        image, Rect.fromLTWH(i * side, 0, side, side), dst, drawPaint);
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

// ----------------------------------------------------------------- moments

/// One strip of a [PixelMoment]: played over a share of its time.
class PixelMomentLayer {
  const PixelMomentLayer(this.asset,
      {this.t0 = 0, this.span = 1, this.scale = 3});

  /// The strip's file under assets/visuals/pixel_fx/, without `.png`.
  final String asset;

  /// When it starts and how long it plays, as shares of the moment.
  final double t0;
  final double span;

  /// The pixel size it is drawn at.
  final double scale;
}

/// A short pixel flourish for a big moment (a level gained, a chapter
/// opened): the fight's strips, recoloured to [palette], laid one over
/// another and played once over [duration], then gone. With reduced motion
/// it plays nothing.
class PixelMoment extends StatefulWidget {
  const PixelMoment({
    super.key,
    required this.layers,
    required this.palette,
    this.duration = const Duration(milliseconds: 1400),
    this.delay = Duration.zero,
  });

  final List<PixelMomentLayer> layers;
  final VfxPalette palette;
  final Duration duration;
  final Duration delay;

  /// The gold of a moment worth marking.
  static const VfxPalette gold =
      VfxPalette(0xFFF2C14E, 0xFFFFF6E0, ApolloTones.gold);

  @override
  State<PixelMoment> createState() => _PixelMomentState();
}

class _PixelMomentState extends State<PixelMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this, duration: widget.duration + widget.delay);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    for (final l in widget.layers) {
      PixelVfxTints.of(l.asset, widget.palette);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _t.forward();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          key: const ValueKey('pixel_moment'),
          painter: _MomentPainter(
            layers: widget.layers,
            palette: widget.palette,
            clock: _t,
            delayShare: widget.delay.inMilliseconds /
                (widget.duration + widget.delay).inMilliseconds,
          ),
        ),
      ),
    );
  }
}

class _MomentPainter extends CustomPainter {
  _MomentPainter({
    required this.layers,
    required this.palette,
    required this.clock,
    required this.delayShare,
  }) : super(repaint: Listenable.merge([clock, PixelStrips.loaded]));

  final List<PixelMomentLayer> layers;
  final VfxPalette palette;
  final Animation<double> clock;
  final double delayShare;

  @override
  void paint(Canvas canvas, Size size) {
    final raw = clock.value;
    if (raw <= delayShare || raw >= 1) return;
    final u = (raw - delayShare) / (1 - delayShare);
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (final l in layers) {
      final v = (u - l.t0) / l.span;
      if (v < 0 || v >= 1) continue;
      final image = PixelVfxTints.of(l.asset, palette);
      if (image == null) continue;
      final side = image.height.toDouble();
      final frames = (image.width / side).round();
      final i = (v * frames).floor().clamp(0, frames - 1);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(i * side, 0, side, side),
        Rect.fromCenter(
            center: size.center(Offset.zero),
            width: side * l.scale,
            height: side * l.scale),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MomentPainter old) =>
      old.layers != layers || old.palette != palette;
}
