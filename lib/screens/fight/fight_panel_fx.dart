// Skill effects that touch the Tower fight's interface (a proposal drawn for
// the pictures; nothing plays it in a real fight yet).
//
// Three reaches: PANEL (the effect stays in the target panel: its frame
// flashes, only that panel shakes a pixel or two, the HP bar loses a chunk),
// CROSS-PANEL (an ember leaves "You", crosses the gutter, both frames react)
// and FULL SCREEN (a tint or vignette, a shake, embers over the app bar), kept
// for crits and big moves. Everything is a pure function of the time since the
// skill started ([PanelFxFrame.ms]), so a picture can freeze any instant and a
// player can drive it from one animation controller.
//
// Off switches: the shake and the full-screen tint follow the tremble setting
// (`trembleEnabledProvider`) and the system's reduce-motion; the effects as a
// whole follow `combatEffectsEnabledProvider`.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/combat_settings_provider.dart';
import '../../theme/palette.dart';
import '../../theme/stitched_ink.dart' show InkFonts;
import '../tower/ink/ink_palette.dart';

enum PanelFxSkill { basic, fire, poison }

enum PanelFxStrength { subtle, strong }

/// One instant of a skill's effect: [ms] since it started. [poisoned] keeps
/// the poison's drips and ticks going after the punch.
class PanelFxFrame {
  const PanelFxFrame(this.skill, this.strength, this.ms);

  final PanelFxSkill skill;
  final PanelFxStrength strength;
  final double ms;

  bool get strong => strength == PanelFxStrength.strong;
}

/// The frame being shown (null: nothing).
final ValueNotifier<PanelFxFrame?> panelFx = ValueNotifier(null);

/// Keys of the two fighter panels, so the layer can find them.
final GlobalKey towerFoePanelKey = GlobalKey(debugLabel: 'tower_foe_panel');
final GlobalKey towerPartyPanelKey = GlobalKey(debugLabel: 'tower_party_panel');
final GlobalKey _layerKey = GlobalKey(debugLabel: 'panel_fx_layer');

double _seg(double ms, double a, double b) =>
    b <= a ? (ms >= b ? 1 : 0) : ((ms - a) / (b - a)).clamp(0.0, 1.0);

double _easeOut(double x) => 1 - (1 - x) * (1 - x);

/// When the first blow lands, per skill.
double _hitAt(PanelFxSkill s) => switch (s) {
      PanelFxSkill.basic => 110,
      PanelFxSkill.fire => 260,
      PanelFxSkill.poison => 90,
    };

/// A pixel shake: whole pixels, decaying, alternating.
double _shake(double ms, double hit, double amp, {double len = 240}) {
  final dt = ms - hit;
  if (dt < 0 || dt > len) return 0;
  final decay = 1 - dt / len;
  final k = cos(dt / 30 * pi);
  return (amp * decay * (k >= 0 ? 1 : -1)).round().toDouble();
}

/// How far the foe's panel moves at [f] (its own shake, a pixel or two).
Offset panelFxFoeOffset(PanelFxFrame? f) {
  if (f == null) return Offset.zero;
  return Offset(_shake(f.ms, _hitAt(f.skill), f.strong ? 2 : 1), 0);
}

/// How far the whole screen moves at [f] (strong fire only).
Offset panelFxScreenOffset(PanelFxFrame? f) {
  if (f == null || f.skill != PanelFxSkill.fire || !f.strong) {
    return Offset.zero;
  }
  return Offset(_shake(f.ms, _hitAt(f.skill), 3, len: 200), 0);
}

/// Moves the foe's panel with the effect (only that panel).
class PanelFxFoeShake extends ConsumerWidget {
  const PanelFxFoeShake({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tremble = ref.watch(trembleEnabledProvider) &&
        !MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder<PanelFxFrame?>(
      valueListenable: panelFx,
      child: child,
      builder: (context, f, child) => Transform.translate(
          offset: tremble ? panelFxFoeOffset(f) : Offset.zero, child: child),
    );
  }
}

/// Moves the whole fight with a big hit.
class PanelFxScreenShake extends ConsumerWidget {
  const PanelFxScreenShake({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tremble = ref.watch(trembleEnabledProvider) &&
        !MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder<PanelFxFrame?>(
      valueListenable: panelFx,
      child: child,
      builder: (context, f, child) => Transform.translate(
          offset: tremble ? panelFxScreenOffset(f) : Offset.zero, child: child),
    );
  }
}

/// Draws the effect over the whole fight, never taking a touch.
class PanelFxLayer extends ConsumerWidget {
  const PanelFxLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(combatEffectsEnabledProvider);
    final tint = ref.watch(trembleEnabledProvider) &&
        !MediaQuery.disableAnimationsOf(context);
    if (!on) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox.expand(
        key: _layerKey,
        child: ValueListenableBuilder<PanelFxFrame?>(
          valueListenable: panelFx,
          builder: (context, f, _) {
            final box = _layerKey.currentContext?.findRenderObject();
            final foe = _rect(towerFoePanelKey, box);
            final party = _rect(towerPartyPanelKey, box);
            if (f == null || foe == null || party == null) {
              return const SizedBox.shrink();
            }
            return CustomPaint(painter: _FxPainter(f, foe, party, tint: tint));
          },
        ),
      ),
    );
  }

  static Rect? _rect(GlobalKey key, RenderObject? layer) {
    final b = key.currentContext?.findRenderObject();
    if (b is! RenderBox || !b.hasSize || layer is! RenderBox) return null;
    final o = layer.globalToLocal(b.localToGlobal(Offset.zero));
    return o & b.size;
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.f, this.foe, this.party, {required this.tint});

  final PanelFxFrame f;
  final Rect foe;
  final Rect party;

  /// Full-screen tints and flashes allowed (the tremble setting).
  final bool tint;

  // The tones (Apollo, the skill effects' palette) and the ink's.
  static final Color _fireHi = Color(ApolloTones.fire[0]);
  static final Color _fireMid = Color(ApolloTones.fire[1]);
  static final Color _fireLow = Color(ApolloTones.fire[2]);
  static final Color _fireDeep = Color(ApolloTones.fire[3]);
  static final Color _poisonHi = Color(ApolloTones.poison[0]);
  static final Color _poisonMid = Color(ApolloTones.poison[1]);
  static final Color _poisonLow = Color(ApolloTones.poison[2]);

  Paint _px(Color c, [double a = 1]) => Paint()
    ..isAntiAlias = false
    ..color = c.withValues(alpha: a.clamp(0.0, 1.0));

  // Where the HP bar sits in each panel's plate (as drawn today).
  Rect get _foeBar =>
      Rect.fromLTRB(foe.left + 20, foe.top + 36, foe.right - 114, foe.top + 43);

  Rect _snap(Rect r) => Rect.fromLTRB(r.left.roundToDouble(),
      r.top.roundToDouble(), r.right.roundToDouble(), r.bottom.roundToDouble());

  void _sq(Canvas c, Offset p, double s, Color col, double a) {
    final h = (s / 2).roundToDouble();
    c.drawRect(
        Rect.fromLTWH(
            p.dx.roundToDouble() - h, p.dy.roundToDouble() - h, h * 2, h * 2),
        _px(col, a));
  }

  void _line(Canvas c, Offset a, Offset b, Color col, double w, double alpha) {
    c.drawLine(
        a,
        b,
        _px(col, alpha)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.butt);
  }

  void _frameFlash(Canvas c, Rect r, Color col, double a, {double w = 3}) {
    if (a <= 0) return;
    c.drawRect(
        _snap(r.deflate(4)),
        _px(col, a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w);
  }

  /// The chunk of the HP bar that breaks off and falls.
  void _chunk(Canvas c, Rect bar, double at, double frac, Color tintCol,
      {double at0 = 0.55}) {
    final ms = f.ms;
    if (ms < at) return;
    final w = (bar.width * frac).roundToDouble();
    final x = bar.left + bar.width * at0;
    final hole = Rect.fromLTWH(x, bar.top, w, bar.height);
    // The bar's place goes dark where the chunk was.
    c.drawRect(_snap(hole), _px(inkBlack, 0.92));
    final fall = _seg(ms, at + 30, at + 330);
    final dy = 30 * fall * fall;
    final alpha = 1 - _seg(ms, at + 160, at + 330);
    final flash = 1 - _seg(ms, at, at + 60);
    c.save();
    c.translate(hole.center.dx, hole.center.dy + dy);
    c.rotate(0.5 * fall * (frac > 0.2 ? 1 : -1));
    final piece =
        Rect.fromCenter(center: Offset.zero, width: w, height: bar.height);
    c.drawRect(piece, _px(Color.lerp(inkRed, tintCol, 0.0)!, alpha));
    c.drawRect(piece, _px(inkPaper, flash * alpha)..style = PaintingStyle.fill);
    c.restore();
  }

  void _number(Canvas c, String text, Offset origin, double at, Color col,
      {double size = 20, double life = 420}) {
    final ms = f.ms;
    if (ms < at || ms > at + life) return;
    final p = _seg(ms, at, at + life);
    final y = origin.dy - 18 * _easeOut(p);
    final a = 1 - _seg(ms, at + life * 0.65, at + life);
    TextPainter mk(Color col) => TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontFamily: InkFonts.display,
                fontSize: size,
                fontWeight: FontWeight.w700,
                color: col.withValues(alpha: a),
                height: 1)),
        textDirection: TextDirection.ltr)
      ..layout();
    final ink = mk(inkBlack);
    final fill = mk(col);
    final o = Offset(origin.dx - fill.width / 2, y);
    for (final d in const [
      Offset(-1, 0),
      Offset(1, 0),
      Offset(0, -1),
      Offset(0, 1)
    ]) {
      ink.paint(c, o + d * 1.5);
    }
    fill.paint(c, o);
  }

  @override
  void paint(Canvas c, Size size) {
    switch (f.skill) {
      case PanelFxSkill.basic:
        _basic(c, size);
      case PanelFxSkill.fire:
        _fire(c, size);
      case PanelFxSkill.poison:
        _poison(c, size);
    }
  }

  // ---- Basic attack: a slash across the foe's panel, its frame flashing ----

  void _basic(Canvas c, Size size) {
    final ms = f.ms;
    final strong = f.strong;
    final r = foe;
    // The slashes: ink under, paper over, drawn in 110 ms and gone by 300.
    void slash(Offset a, Offset b, double start, double w) {
      final p = _easeOut(_seg(ms, start, start + 90));
      if (p <= 0) return;
      final alpha = 1 - _seg(ms, 150, 300);
      final end = Offset.lerp(a, b, p)!;
      _line(c, a, end, inkBlack, w + 4, alpha);
      _line(c, a, end, inkPaper, w, alpha);
    }

    final w = r.width, h = r.height;
    slash(Offset(r.left + w * .50, r.top + h * .14),
        Offset(r.left + w * .90, r.top + h * .86), 0, strong ? 4 : 3);
    if (strong) {
      slash(Offset(r.left + w * .86, r.top + h * .18),
          Offset(r.left + w * .46, r.top + h * .80), 40, 4);
      slash(Offset(r.left + w * .60, r.top + h * .10),
          Offset(r.left + w * .74, r.top + h * .40), 70, 3);
    }
    _frameFlash(c, r, inkPaper, 1 - _seg(ms, 110, strong ? 330 : 250));
    _chunk(c, _foeBar, 110, strong ? 0.22 : 0.12, inkRed);
    _number(c, strong ? '-27!' : '-12', Offset(r.left + w * .64, r.top + 44),
        120, inkRed,
        size: strong ? 26 : 20);
    if (strong && tint) {
      // The crit: a brief paper flash over the whole fight.
      final a = 0.38 * (1 - _seg(ms, 110, 300)) * (ms >= 110 ? 1 : 0);
      c.drawRect(Offset.zero & size, _px(inkPaper, a));
    }
  }

  // ---- Fire: an ember crosses the gutter, spills over the frame ----

  void _fire(Canvas c, Size size) {
    final ms = f.ms;
    final strong = f.strong;
    final k = strong ? 1.5 : 1.0;
    final from = Offset(party.left + party.width * .62, party.top + 34);
    final to =
        Offset(foe.left + foe.width * .70, foe.bottom - foe.height * .26);
    Offset at(double p) {
      final o = Offset.lerp(from, to, p)!;
      return Offset(o.dx, o.dy - 36 * sin(pi * p));
    }

    // The projectile and its trail (0 to 260 ms).
    final fly = _seg(ms, 0, 260);
    if (ms < 280) {
      for (var i = 7; i >= 0; i--) {
        final p = (fly - i * 0.045).clamp(0.0, 1.0);
        if (fly <= 0 || (i > 0 && p <= 0)) continue;
        final s = (strong ? 12 : 9) - i * 1.2;
        final col = i == 0
            ? _fireHi
            : i < 3
                ? _fireMid
                : i < 5
                    ? _fireLow
                    : _fireDeep;
        _sq(c, at(_easeOut(p) * .6 + p * .4), s.clamp(3, 14), col,
            1 - _seg(ms, 240, 280));
      }
      // The muzzle: "You"'s frame flashes as it leaves.
      _frameFlash(c, party, _fireMid, 1 - _seg(ms, 0, 200), w: 2);
    }
    // Impact at 260: embers spill over the foe's frame and rise over the app
    // bar; the frame flashes.
    const hit = 260.0;
    if (ms >= hit) {
      _frameFlash(c, foe, _fireMid, 1 - _seg(ms, hit, hit + 320));
      _frameFlash(
          c, foe.deflate(3), _fireHi, 0.8 * (1 - _seg(ms, hit, hit + 120)),
          w: 2);
      final n = strong ? 40 : 18;
      final rnd = Random(7);
      for (var i = 0; i < n; i++) {
        // Start on the foe's frame (top and sides), rise and drift.
        final side = rnd.nextInt(5);
        final sx = switch (side) {
          0 => foe.left + 8,
          1 => foe.right - 8,
          _ => foe.left + 10 + rnd.nextDouble() * (foe.width - 20),
        };
        final sy = side < 2
            ? foe.top + 10 + rnd.nextDouble() * (foe.height - 20)
            : foe.top + 4;
        final life = 420 + rnd.nextDouble() * (strong ? 460 : 260);
        final dt = ms - hit - rnd.nextDouble() * 80;
        if (dt < 0 || dt > life) continue;
        final p = dt / life;
        final vy =
            (strong ? 190 : 110) + rnd.nextDouble() * (strong ? 150 : 70);
        final dx = (rnd.nextDouble() - .5) * 60 * p + sin(p * 6 + i) * 6;
        final pos = Offset(sx + dx, sy - vy * dt / 1000);
        final col = p < .3
            ? _fireHi
            : p < .6
                ? _fireMid
                : _fireLow;
        _sq(c, pos, (3 + rnd.nextInt(2) + (strong ? 1 : 0)).toDouble(), col,
            1 - _seg(dt, life * .6, life));
      }
      _chunk(c, _foeBar, hit, strong ? 0.2 : 0.1, _fireMid);
      _number(c, strong ? '-31' : '-14',
          Offset(foe.left + foe.width * .64, foe.top + 44), hit + 10, inkRed,
          size: strong ? 24 : 20);
    }
    // The warm vignette (big hits and strong versions mostly).
    if (tint && ms >= hit) {
      final a = (strong ? 0.26 : 0.10) *
          _seg(ms, hit, hit + 90) *
          (1 - _seg(ms, hit + 160, hit + 520));
      if (a > 0) {
        final rect = Offset.zero & size;
        c.drawRect(
            rect,
            Paint()
              ..shader = RadialGradient(radius: 0.95, colors: [
                Colors.transparent,
                Colors.transparent,
                _fireLow.withValues(alpha: a),
              ], stops: const [
                0,
                0.55,
                1
              ]).createShader(rect));
      }
    }
    // The burn ticks later: small embers on the foe's frame, a sliver of bar.
    const tick = 1400.0;
    if (ms >= tick && ms < tick + 520) {
      final dt = ms - tick;
      _frameFlash(c, foe, _fireMid, 0.5 * (1 - _seg(ms, tick, tick + 260)),
          w: 2);
      final rnd = Random(3);
      for (var i = 0; i < (strong ? 8 : 5); i++) {
        final x = foe.left + 20 + rnd.nextDouble() * (foe.width - 40);
        final life = 380 + rnd.nextDouble() * 140;
        if (dt > life) continue;
        _sq(
            c,
            Offset(x, foe.top + 6 - 46 * dt / life),
            3 * k.clamp(1, 1.3),
            dt < life * .5 ? _fireMid : _fireLow,
            1 - _seg(dt, life * .5, life));
      }
      // A small chunk, 5% of the bar.
      _chunk(c, _foeBar, tick, 0.05, _fireMid, at0: 0.4);
      _number(c, '-2', Offset(foe.left + foe.width * .64, foe.top + 44),
          tick + 20, inkRed,
          size: 15, life: 380);
    }
  }

  // ---- Poison fist: a punch, a green splash, drips that stay ----

  void _poison(Canvas c, Size size) {
    final ms = f.ms;
    final strong = f.strong;
    const hit = 90.0;
    final spot = Offset(foe.left + foe.width * .74, foe.top + foe.height * .62);
    if (ms >= hit) {
      // The impact star in paper, 140 ms.
      final star = 1 - _seg(ms, hit, hit + 150);
      if (star > 0) {
        final len = (strong ? 34 : 24) *
            (0.6 + 0.4 * _easeOut(_seg(ms, hit, hit + 50)));
        for (var i = 0; i < 8; i++) {
          final a = i * pi / 4;
          final l = i.isEven ? len : len * .55;
          _line(c, spot + Offset(cos(a), sin(a)) * 5,
              spot + Offset(cos(a), sin(a)) * l, inkPaper, 3, star);
        }
      }
      // The sickly splash: droplets thrown out, falling.
      final rnd = Random(11);
      final n = strong ? 22 : 11;
      for (var i = 0; i < n; i++) {
        final ang = -pi * 0.9 + rnd.nextDouble() * pi * 1.6;
        final speed = 70 + rnd.nextDouble() * (strong ? 150 : 90);
        final life = 280 + rnd.nextDouble() * 200;
        final dt = ms - hit;
        if (dt > life) continue;
        final t = dt / 1000;
        final pos = spot +
            Offset(cos(ang) * speed * t, sin(ang) * speed * t + 260 * t * t);
        _sq(c, pos, (3 + (i % 3)).toDouble(), i.isEven ? _poisonHi : _poisonMid,
            1 - _seg(dt, life * .6, life));
      }
      _frameFlash(
          c, foe, _poisonHi, 1 - _seg(ms, hit, hit + (strong ? 300 : 200)));
      _chunk(c, _foeBar, hit, strong ? 0.18 : 0.1, _poisonMid);
      _number(c, strong ? '-19' : '-9',
          Offset(foe.left + foe.width * .64, foe.top + 44), hit + 10, inkRed,
          size: strong ? 24 : 20);
    }
    // The lingering poison: drips on the border and the bar, a thin green
    // line round the frame, a green pulse and a small number on each tick.
    if (ms >= 300) {
      final fade = _seg(ms, 300, 420);
      c.drawRect(
          _snap(foe.deflate(4)),
          _px(_poisonMid, 0.55 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      final drips = strong ? 6 : 3;
      for (var i = 0; i < drips; i++) {
        final x = (foe.left + foe.width * (.14 + .76 * (i + .5) / drips))
            .roundToDouble();
        final phase = (ms / 1000 * (0.8 + 0.15 * i) + i * .31) % 1.0;
        final double len = 4 + 14 * (phase < .7 ? phase / .7 : 1.0);
        final drop = phase >= .7 ? (phase - .7) / .3 * 12 : 0.0;
        final y0 = foe.top + 5;
        c.drawRect(Rect.fromLTWH(x - 1, y0, 3, len), _px(_poisonMid, fade));
        c.drawRect(Rect.fromLTWH(x - 1, y0, 1, len), _px(_poisonHi, fade));
        _sq(c, Offset(x, y0 + len + 2 + drop), 4, _poisonMid,
            fade * (1 - drop / 14));
      }
      // The bar: a green rim under it and two drips.
      final bar = _foeBar;
      c.drawRect(Rect.fromLTWH(bar.left, bar.bottom, bar.width, 2),
          _px(_poisonMid, fade));
      for (var i = 0; i < (strong ? 3 : 1); i++) {
        final x = (bar.left + bar.width * (.3 + .25 * i)).roundToDouble();
        final ph = (ms / 900 + i * .4) % 1.0;
        c.drawRect(Rect.fromLTWH(x, bar.bottom + 2, 2, 2 + 6 * ph),
            _px(_poisonHi, fade * (1 - ph * .5)));
      }
      for (final tick in const [900.0, 1800.0]) {
        if (ms < tick || ms > tick + 560) continue;
        final pulse = 1 - _seg(ms, tick, tick + 300);
        c.drawRect(_snap(bar.inflate(1)), _px(_poisonHi, 0.85 * pulse));
        _frameFlash(c, foe, _poisonMid, 0.5 * pulse, w: 2);
        _chunk(c, bar, tick, 0.05, _poisonMid, at0: 0.35);
        _number(c, '-3', Offset(foe.left + foe.width * .64, foe.top + 44),
            tick + 10, _poisonHi,
            size: 16, life: 400);
        // And the lowest tone, a speck of shade under the drips.
        _sq(c, Offset(bar.left + bar.width * .5, bar.bottom + 5), 3, _poisonLow,
            0.6 * pulse);
      }
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) =>
      old.f.ms != f.ms ||
      old.f.skill != f.skill ||
      old.f.strength != f.strength ||
      old.foe != foe ||
      old.party != party ||
      old.tint != tint;
}
