// Skill effects that touch the Tower fight's interface: a blow, a Fire spell
// or skill, and the poison of a poisoning skill. Three reaches: PANEL (the
// effect stays in the target's panel: its frame flashes, only that panel
// shifts a pixel or two, the HP bar loses a chunk), CROSS-PANEL (an ember
// leaves "You", crosses the gutter, both frames react) and FULL SCREEN (a tint
// or a flash, a shake, embers over the app bar), kept for crits and big hits.
//
// Every effect is a pure function of the time since it started, so a picture
// can freeze any instant. The fight screen feeds the player from the fight's
// own events (`fightEventsProvider`: hits with their crit flag, tier, skill
// and element; poison ticks).
//
// Off switches: the panel shifts, the screen shake, the tint and the flash
// follow the tremble setting (`trembleEnabledProvider`) and the system's
// reduce-motion; the effects as a whole follow `combatEffectsEnabledProvider`
// (the fight screen plays nothing with it off).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/combat_settings_provider.dart';
import '../../theme/palette.dart';
import '../../theme/stitched_ink.dart' show InkFonts;
import '../tower/ink/ink_palette.dart';

enum PanelFxSkill { basic, fire, poison }

/// What kind of play one effect is.
enum PanelFxKind { hit, tick }

/// One effect in flight.
class PanelFxPlay {
  PanelFxPlay({
    required this.skill,
    required this.kind,
    required this.onFoe,
    required this.index,
    required this.count,
    required this.startMs,
    this.strong = false,
    this.crit = false,
    this.text = '',
    this.seed = 1,
  });

  final PanelFxSkill skill;
  final PanelFxKind kind;

  /// On a foe's panel (else on the party's).
  final bool onFoe;

  /// The target's place in its side, and how many stand on that side.
  final int index;
  final int count;
  final double startMs;
  final bool strong;
  final bool crit;
  final String text;
  final int seed;

  /// How long it lasts.
  double get length => switch (kind) {
        PanelFxKind.tick => 560,
        PanelFxKind.hit => switch (skill) {
            PanelFxSkill.basic => strong ? 560 : 440,
            PanelFxSkill.fire => strong ? 1100 : 900,
            PanelFxSkill.poison => 560,
          },
      };

  /// When the first blow lands.
  double get hitAt => switch (skill) {
        PanelFxSkill.basic => 110,
        PanelFxSkill.fire => 260,
        PanelFxSkill.poison => 90,
      };
}

/// The effects in flight and the clock they run on.
class PanelFxPlayer extends ChangeNotifier {
  final Stopwatch _clock = Stopwatch()..start();
  final List<PanelFxPlay> active = [];

  /// A fixed time (pictures): every effect shows at [frozenMs] after its start.
  double? frozenMs;

  /// Foes shown poisoned whatever their status (pictures).
  final Set<int> previewPoison = {};

  double get nowMs => _clock.elapsedMicroseconds / 1000;

  void add(PanelFxPlay play) {
    active.add(play);
    notifyListeners();
  }

  /// Plays a hit (the fight screen calls it).
  void play({
    required PanelFxSkill skill,
    required bool onFoe,
    required int index,
    required int count,
    bool strong = false,
    bool crit = false,
    String text = '',
    PanelFxKind kind = PanelFxKind.hit,
    double delayMs = 0,
  }) =>
      add(PanelFxPlay(
        skill: skill,
        kind: kind,
        onFoe: onFoe,
        index: index,
        count: count,
        startMs: (frozenMs == null ? nowMs : 0) + delayMs,
        strong: strong,
        crit: crit,
        text: text,
        seed: active.length * 7 + 3,
      ));

  /// The time of [p] now.
  double msOf(PanelFxPlay p) => (frozenMs ?? nowMs) - p.startMs;

  /// Drops the ones that are over.
  void prune() {
    if (frozenMs != null) return;
    active.removeWhere((p) => msOf(p) > p.length + 40);
  }

  void clear() {
    active.clear();
    frozenMs = null;
    previewPoison.clear();
  }

  /// How far the foes' panel moves now (a pixel or two, only that panel).
  Offset panelOffset(bool foe) {
    var dx = 0.0;
    for (final p in active) {
      if (p.kind != PanelFxKind.hit || p.onFoe != foe) continue;
      dx += _shake(msOf(p), p.hitAt, p.strong ? 2 : 1);
    }
    return Offset(dx.clamp(-2.0, 2.0), 0);
  }

  /// How far the whole screen moves (a strong Fire's impact).
  Offset screenOffset() {
    var dx = 0.0;
    for (final p in active) {
      if (p.kind == PanelFxKind.hit &&
          p.skill == PanelFxSkill.fire &&
          p.strong) {
        dx += _shake(msOf(p), p.hitAt, 3, len: 200);
      }
    }
    return Offset(dx.clamp(-3.0, 3.0), 0);
  }
}

/// The one player (one fight is played at a time).
final PanelFxPlayer panelFx = PanelFxPlayer();

/// The two panels' keys (set on the fighter panels).
final GlobalKey towerFoePanelKey = GlobalKey(debugLabel: 'tower_foe_panel');
final GlobalKey towerPartyPanelKey = GlobalKey(debugLabel: 'tower_party_panel');
final GlobalKey _layerKey = GlobalKey(debugLabel: 'panel_fx_layer');

/// A pixel shake: whole pixels, decaying, alternating.
double _shake(double ms, double hit, double amp, {double len = 240}) {
  final dt = ms - hit;
  if (dt < 0 || dt > len) return 0;
  final decay = 1 - dt / len;
  return (amp * decay * (cos(dt / 30 * pi) >= 0 ? 1 : -1)).round().toDouble();
}

double _seg(double ms, double a, double b) =>
    b <= a ? (ms >= b ? 1 : 0) : ((ms - a) / (b - a)).clamp(0.0, 1.0);

double _easeOut(double x) => 1 - (1 - x) * (1 - x);

/// Moves one fighter panel with the effects on it (and only that panel).
class PanelFxShake extends ConsumerWidget {
  const PanelFxShake({super.key, required this.foe, required this.child});

  final bool foe;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tremble = ref.watch(trembleEnabledProvider) &&
        !MediaQuery.disableAnimationsOf(context);
    return ListenableBuilder(
      listenable: panelFx,
      child: child,
      builder: (context, child) => Transform.translate(
          offset: tremble ? panelFx.panelOffset(foe) : Offset.zero,
          child: child),
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
    return ListenableBuilder(
      listenable: panelFx,
      child: child,
      builder: (context, child) => Transform.translate(
          offset: tremble ? panelFx.screenOffset() : Offset.zero, child: child),
    );
  }
}

/// Where the layer finds what it draws on: a fighter's card (its plate, with
/// the HP bar at its foot) and whether a fighter is poisoned.
class PanelFxTargets {
  const PanelFxTargets({required this.cardOf, required this.poisoned});

  /// The card of fighter [index] on a side, in global coordinates.
  final Rect? Function(bool foe, int index) cardOf;
  final bool Function(bool foe, int index) poisoned;
  static const none = PanelFxTargets(cardOf: _noCard, poisoned: _notPoisoned);
}

Rect? _noCard(bool foe, int index) => null;
bool _notPoisoned(bool foe, int index) => false;

/// Draws the effects over the whole fight, never taking a touch.
class PanelFxLayer extends ConsumerStatefulWidget {
  const PanelFxLayer({super.key, this.targets = PanelFxTargets.none});

  final PanelFxTargets targets;

  @override
  ConsumerState<PanelFxLayer> createState() => _PanelFxLayerState();
}

class _PanelFxLayerState extends ConsumerState<PanelFxLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> _frame = ValueNotifier(0);
  double _idleSince = 0;

  @override
  void initState() {
    super.initState();
    panelFx.addListener(_wake);
  }

  @override
  void dispose() {
    panelFx.removeListener(_wake);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _wake() {
    _idleSince = panelFx.nowMs;
    if (!_ticker.isActive) _ticker.start();
    _frame.value++;
  }

  bool _poisoned(bool foe, int i) =>
      widget.targets.poisoned(foe, i) ||
      (foe && panelFx.previewPoison.contains(i));

  bool _anyPoison() {
    for (var i = 0; i < 12; i++) {
      if (_poisoned(true, i) || _poisoned(false, i)) return true;
    }
    return false;
  }

  void _tick(Duration _) {
    panelFx.prune();
    final poisoned = _anyPoison();
    if (poisoned || panelFx.active.isNotEmpty) _idleSince = panelFx.nowMs;
    // Stays awake half a second past the last effect, so a status that lands
    // just after its hit is caught.
    if (panelFx.nowMs - _idleSince > 600 && panelFx.frozenMs == null) {
      _ticker.stop();
    }
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    final on = ref.watch(combatEffectsEnabledProvider);
    final tint = ref.watch(trembleEnabledProvider) &&
        !MediaQuery.disableAnimationsOf(context);
    if (!on) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox.expand(
        key: _layerKey,
        child: ValueListenableBuilder<int>(
          valueListenable: _frame,
          builder: (context, _, __) {
            final box = _layerKey.currentContext?.findRenderObject();
            if (box is! RenderBox || !box.hasSize) {
              return const SizedBox.shrink();
            }
            Rect? local(GlobalKey key) {
              final b = key.currentContext?.findRenderObject();
              if (b is! RenderBox || !b.hasSize) return null;
              return box.globalToLocal(b.localToGlobal(Offset.zero)) & b.size;
            }

            Rect? card(bool foe, int i) {
              final g = widget.targets.cardOf(foe, i);
              if (g == null) return null;
              return Rect.fromPoints(box.globalToLocal(g.topLeft),
                  box.globalToLocal(g.bottomRight));
            }

            final foe = local(towerFoePanelKey);
            final party = local(towerPartyPanelKey);
            if (foe == null || party == null) return const SizedBox.shrink();
            return CustomPaint(
              painter: _FxPainter(
                plays: List.of(panelFx.active),
                msOf: panelFx.msOf,
                nowMs: panelFx.frozenMs ?? panelFx.nowMs,
                foe: foe,
                party: party,
                cardOf: card,
                poisoned: _poisoned,
                tint: tint,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.plays,
    required this.msOf,
    required this.nowMs,
    required this.foe,
    required this.party,
    required this.cardOf,
    required this.poisoned,
    required this.tint,
  });

  final List<PanelFxPlay> plays;
  final double Function(PanelFxPlay) msOf;
  final double nowMs;
  final Rect foe;
  final Rect party;
  final Rect? Function(bool foe, int index) cardOf;
  final bool Function(bool foe, int index) poisoned;

  /// Full-screen tints and flashes allowed (the tremble setting).
  final bool tint;

  // The tones (Apollo, the skill effects' palette).
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

  Rect _snap(Rect r) => Rect.fromLTRB(r.left.roundToDouble(),
      r.top.roundToDouble(), r.right.roundToDouble(), r.bottom.roundToDouble());

  Rect _panel(bool onFoe) => onFoe ? foe : party;

  /// The target's HP bar: the foot of its plate (card), else where the plate
  /// sits in the panel as drawn.
  Rect _bar(PanelFxPlay p) {
    final card = cardOf(p.onFoe, p.index);
    final panel = _panel(p.onFoe);
    if (card != null) {
      return Rect.fromLTRB(
          card.left + 10, card.bottom - 13, card.right - 10, card.bottom - 6);
    }
    return p.onFoe
        ? Rect.fromLTRB(
            panel.left + 20, panel.top + 36, panel.right - 114, panel.top + 43)
        : Rect.fromLTRB(
            panel.left + 112, panel.top + 24, panel.right - 16, panel.top + 31);
  }

  /// Where a blow's number floats: over the target's body, clear of its plate.
  Offset _numberAt(PanelFxPlay p) {
    final s = _spot(p);
    return Offset(s.dx, s.dy - 34);
  }

  /// Where the blow lands in the panel: a lone foe stands on the right, a pack
  /// shares the width.
  Offset _spot(PanelFxPlay p) {
    final panel = _panel(p.onFoe);
    final y = panel.top + panel.height * .62;
    if (!p.onFoe) return Offset(panel.left + panel.width * .2, y);
    if (p.count <= 1) return Offset(panel.left + panel.width * .74, y);
    return Offset(panel.left + panel.width * (p.index + .5) / p.count, y);
  }

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
  void _chunk(
      Canvas c, double ms, Rect bar, double at, double frac, Color tintCol,
      {double at0 = 0.55}) {
    if (ms < at) return;
    final w = max(3.0, (bar.width * frac).roundToDouble());
    final x = bar.left + bar.width * at0;
    final hole = Rect.fromLTWH(x, bar.top, w, bar.height);
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
    c.drawRect(piece, _px(inkRed, alpha));
    c.drawRect(piece, _px(inkPaper, flash * alpha));
    c.restore();
  }

  void _number(
      Canvas c, double ms, String text, Offset origin, double at, Color col,
      {double size = 20, double life = 420}) {
    if (text.isEmpty || ms < at || ms > at + life) return;
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
    for (final p in plays) {
      final ms = msOf(p);
      if (ms < 0 || ms > p.length) continue;
      if (p.kind == PanelFxKind.tick) {
        _tick(c, p, ms);
      } else {
        switch (p.skill) {
          case PanelFxSkill.basic:
            _basic(c, size, p, ms);
          case PanelFxSkill.fire:
            _fire(c, size, p, ms);
          case PanelFxSkill.poison:
            _poisonHit(c, p, ms);
        }
      }
    }
    // The lingering poison, on every poisoned fighter.
    for (final onFoe in const [true, false]) {
      for (var i = 0; i < 12; i++) {
        if (poisoned(onFoe, i)) _drips(c, onFoe, i);
      }
    }
  }

  // ---- Basic attack: a slash across the panel, its frame flashing ----

  void _basic(Canvas c, Size size, PanelFxPlay p, double ms) {
    final strong = p.strong;
    final r = _panel(p.onFoe);
    final spot = _spot(p);
    final w = r.width, h = r.height;
    // A pack's slash stays on its own foe's share of the panel.
    final cx = spot.dx;
    final half = min(w * 0.22, w / max(1, p.count) * 0.5);
    void slash(Offset a, Offset b, double start, double width) {
      final t = _easeOut(_seg(ms, start, start + 90));
      if (t <= 0) return;
      final alpha = 1 - _seg(ms, 150, 300);
      final end = Offset.lerp(a, b, t)!;
      _line(c, a, end, inkBlack, width + 4, alpha);
      _line(c, a, end, inkPaper, width, alpha);
    }

    slash(Offset(cx - half, r.top + h * .14),
        Offset(cx + half, r.top + h * .86), 0, strong ? 4 : 3);
    if (strong) {
      slash(Offset(cx + half, r.top + h * .18),
          Offset(cx - half, r.top + h * .80), 40, 4);
      slash(Offset(cx - half * .3, r.top + h * .10),
          Offset(cx + half * .4, r.top + h * .40), 70, 3);
    }
    _frameFlash(c, r, inkPaper, 1 - _seg(ms, 110, strong ? 330 : 250));
    final bar = _bar(p);
    _chunk(c, ms, bar, 110, strong ? 0.22 : 0.12, inkRed);
    _number(c, ms, p.text, _numberAt(p), 120, inkRed, size: p.crit ? 26 : 20);
    if (p.crit && tint) {
      // The crit: a brief paper flash over the whole fight.
      final a = 0.38 * (1 - _seg(ms, 110, 300)) * (ms >= 110 ? 1 : 0);
      c.drawRect(Offset.zero & size, _px(inkPaper, a));
    }
  }

  // ---- Fire: an ember crosses the gutter, spills over the frame ----

  void _fire(Canvas c, Size size, PanelFxPlay p, double ms) {
    final strong = p.strong;
    final f = _panel(true);
    final spot = _spot(p);
    final from = Offset(party.left + party.width * .62, party.top + 34);
    final to = Offset(spot.dx, f.bottom - f.height * .26);
    Offset at(double t) {
      final o = Offset.lerp(from, to, t)!;
      return Offset(o.dx, o.dy - 36 * sin(pi * t));
    }

    final fly = _seg(ms, 0, 260);
    if (ms < 280) {
      for (var i = 7; i >= 0; i--) {
        final t = (fly - i * 0.045).clamp(0.0, 1.0);
        if (fly <= 0 || (i > 0 && t <= 0)) continue;
        final s = ((strong ? 12 : 9) - i * 1.2).clamp(3.0, 14.0);
        final col = i == 0
            ? _fireHi
            : i < 3
                ? _fireMid
                : i < 5
                    ? _fireLow
                    : _fireDeep;
        _sq(c, at(_easeOut(t) * .6 + t * .4), s, col, 1 - _seg(ms, 240, 280));
      }
      // The muzzle: "You"'s frame flashes as it leaves.
      _frameFlash(c, party, _fireMid, 1 - _seg(ms, 0, 200), w: 2);
    }
    const hit = 260.0;
    if (ms < hit) return;
    _frameFlash(c, f, _fireMid, 1 - _seg(ms, hit, hit + 320));
    _frameFlash(c, f.deflate(3), _fireHi, 0.8 * (1 - _seg(ms, hit, hit + 120)),
        w: 2);
    final n = strong ? 40 : 18;
    final rnd = Random(p.seed);
    for (var i = 0; i < n; i++) {
      final side = rnd.nextInt(5);
      final sx = switch (side) {
        0 => f.left + 8,
        1 => f.right - 8,
        _ => f.left + 10 + rnd.nextDouble() * (f.width - 20),
      };
      final sy = side < 2
          ? f.top + 10 + rnd.nextDouble() * (f.height - 20)
          : f.top + 4;
      final life = 420 + rnd.nextDouble() * (strong ? 460 : 260);
      final dt = ms - hit - rnd.nextDouble() * 80;
      if (dt < 0 || dt > life) continue;
      final t = dt / life;
      final vy = (strong ? 190 : 110) + rnd.nextDouble() * (strong ? 150 : 70);
      final dx = (rnd.nextDouble() - .5) * 60 * t + sin(t * 6 + i) * 6;
      final col = t < .3
          ? _fireHi
          : t < .6
              ? _fireMid
              : _fireLow;
      _sq(
          c,
          Offset(sx + dx, sy - vy * dt / 1000),
          (3 + rnd.nextInt(2) + (strong ? 1 : 0)).toDouble(),
          col,
          1 - _seg(dt, life * .6, life));
    }
    final bar = _bar(p);
    _chunk(c, ms, bar, hit, strong ? 0.2 : 0.1, _fireMid);
    _number(c, ms, p.text, _numberAt(p), hit + 10, inkRed,
        size: strong ? 24 : 20);
    if (tint) {
      // The warm vignette.
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
  }

  // ---- Poison fist: a punch, a green splash ----

  void _poisonHit(Canvas c, PanelFxPlay p, double ms) {
    final strong = p.strong;
    final r = _panel(p.onFoe);
    const hit = 90.0;
    final spot = _spot(p);
    if (ms < hit) return;
    final star = 1 - _seg(ms, hit, hit + 150);
    if (star > 0) {
      final len =
          (strong ? 34 : 24) * (0.6 + 0.4 * _easeOut(_seg(ms, hit, hit + 50)));
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        final l = i.isEven ? len : len * .55;
        _line(c, spot + Offset(cos(a), sin(a)) * 5,
            spot + Offset(cos(a), sin(a)) * l, inkPaper, 3, star);
      }
    }
    final rnd = Random(p.seed);
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
    _frameFlash(c, r, _poisonHi, 1 - _seg(ms, hit, hit + (strong ? 300 : 200)));
    final bar = _bar(p);
    _chunk(c, ms, bar, hit, strong ? 0.18 : 0.1, _poisonMid);
    _number(c, ms, p.text, _numberAt(p), hit + 10, inkRed,
        size: strong ? 24 : 20);
  }

  // ---- A poison tick: the bar pulses green ----

  void _tick(Canvas c, PanelFxPlay p, double ms) {
    final bar = _bar(p);
    final pulse = 1 - _seg(ms, 0, 300);
    c.drawRect(_snap(bar.inflate(1)), _px(_poisonHi, 0.85 * pulse));
    _frameFlash(c, _panel(p.onFoe), _poisonMid, 0.5 * pulse, w: 2);
    _chunk(c, ms, bar, 0, 0.05, _poisonMid, at0: 0.35);
    _number(c, ms, p.text, _numberAt(p), 10, _poisonHi, size: 16, life: 400);
    _sq(c, Offset(bar.left + bar.width * .5, bar.bottom + 5), 3, _poisonLow,
        0.6 * pulse);
  }

  // ---- The lingering poison: drips on the border and the bar ----

  void _drips(Canvas c, bool onFoe, int index) {
    final panel = _panel(onFoe);
    final card = cardOf(onFoe, index);
    final left = card?.left ?? panel.left + 14;
    final right = card?.right ?? panel.right - 14;
    final p = PanelFxPlay(
        skill: PanelFxSkill.poison,
        kind: PanelFxKind.hit,
        onFoe: onFoe,
        index: index,
        count: 1,
        startMs: 0);
    final bar = _bar(p);
    c.drawRect(
        _snap(panel.deflate(4)),
        _px(_poisonMid, 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    const drips = 4;
    for (var i = 0; i < drips; i++) {
      final x = (left + (right - left) * (.12 + .76 * (i + .5) / drips))
          .roundToDouble();
      final phase = (nowMs / 1000 * (0.8 + 0.15 * i) + i * .31) % 1.0;
      final double len = 4 + 14 * (phase < .7 ? phase / .7 : 1.0);
      final drop = phase >= .7 ? (phase - .7) / .3 * 12 : 0.0;
      final y0 = panel.top + 5;
      c.drawRect(Rect.fromLTWH(x - 1, y0, 3, len), _px(_poisonMid));
      c.drawRect(Rect.fromLTWH(x - 1, y0, 1, len), _px(_poisonHi));
      _sq(c, Offset(x, y0 + len + 2 + drop), 4, _poisonMid, 1 - drop / 14);
    }
    c.drawRect(
        Rect.fromLTWH(bar.left, bar.bottom, bar.width, 2), _px(_poisonMid));
    for (var i = 0; i < 2; i++) {
      final x = (bar.left + bar.width * (.3 + .3 * i)).roundToDouble();
      final ph = (nowMs / 900 + i * .4) % 1.0;
      c.drawRect(Rect.fromLTWH(x, bar.bottom + 2, 2, 2 + 6 * ph),
          _px(_poisonHi, 1 - ph * .5));
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => true;
}
