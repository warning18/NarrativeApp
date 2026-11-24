import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../combat/skill_vfx.dart';
import '../theme/stitched_ink.dart' show InkFonts;
import 'pixel_portrait.dart';
import 'pixel_vfx.dart';

part 'combat_vfx/vfx_fx.dart';
part 'combat_vfx/vfx_blocks.dart';
part 'combat_vfx/vfx_tiers.dart';

/// What a floating number says, which sets its color.
enum VfxTextKind { damage, hurt, heal, block, mana, crit, info }

/// One effect in flight: a [VfxStyle] played on [target] (and, for the
/// travelling styles, from [source]), with an optional floating [text],
/// at a [power] (see [vfxPowerFor]) that sets its size, its particles, its
/// length and the details its [tier] adds. Anchors are the widgets'
/// [GlobalKey]s, resolved at every frame so an effect follows its card;
/// the rects captured when it was played stand in if a card is gone.
class VfxBurst {
  VfxBurst({
    required this.style,
    required this.palette,
    required this.target,
    this.source,
    this.targetFallback,
    this.sourceFallback,
    this.delay = Duration.zero,
    this.text,
    this.textKind = VfxTextKind.info,
    this.big = false,
    this.power = 1.0,
    this.hit = true,
    this.accent = VfxAccent.none,
    required this.seed,
  })  : tier = vfxTierFor(power),
        durationMs =
            (vfxDurationMs(style) * vfxDurationFactor(vfxTierFor(power)))
                .round(),
        particles = _makeParticles(seed);

  final VfxStyle style;
  final VfxPalette palette;
  final GlobalKey target;
  final GlobalKey? source;
  final Rect? targetFallback;
  final Rect? sourceFallback;
  final Duration delay;
  final String? text;
  final VfxTextKind textKind;
  final bool big;

  /// How strongly it plays (see [vfxPowerFor]): its size, and through its
  /// [tier] its particles, length and extra details.
  final double power;

  /// A blow landing (as against a heal, a shield, mana): the strong tiers
  /// give a blow a shockwave, embers and a flash, and the rest a rising
  /// aura.
  final bool hit;

  /// The clan card's own particles over the style (see [VfxAccent]).
  final VfxAccent accent;
  final VfxTier tier;
  final int seed;
  final int durationMs;
  final List<VfxParticle> particles;

  /// Set when the layer takes the burst: the layer clock's time it starts.
  Duration? startAt;

  /// Set once the layer has reported the moment it lands (see
  /// [VfxImpact]).
  bool impacted = false;

  /// When, on the layer's clock, the blow lands (see [vfxImpactAt]).
  Duration get impactAt =>
      startAt! +
      Duration(milliseconds: (vfxImpactAt(style) * durationMs).round());

  /// How long the burst stays on screen: its style, then its number.
  int get lifeMs => durationMs + (text == null ? 0 : _textExtraMs);

  static const int _textExtraMs = 350;
}

/// One particle's fixed traits, drawn when a burst is made.
class VfxParticle {
  const VfxParticle(
      this.angle, this.speed, this.size, this.delay, this.spin, this.dx);
  final double angle;
  final double speed;
  final double size;
  final double delay;
  final double spin;
  final double dx;
}

/// Enough particles for the busiest style at the mightiest tier.
const int _vfxParticleCount = 64;

List<VfxParticle> _makeParticles(int seed) {
  final random = Random(seed);
  return [
    for (var i = 0; i < _vfxParticleCount; i++)
      VfxParticle(
        random.nextDouble() * pi * 2,
        0.45 + random.nextDouble() * 0.55,
        0.5 + random.nextDouble() * 0.5,
        random.nextDouble() * 0.2,
        random.nextDouble() * 2 - 1,
        random.nextDouble() * 2 - 1,
      ),
  ];
}

/// A cue for a portrait: do [cue] after [delay].
class VfxCue {
  const VfxCue(this.target, this.cue,
      {this.delay = Duration.zero, this.dir = const Offset(-1, 0)});

  final GlobalKey target;
  final PortraitCue cue;
  final Duration delay;
  final Offset dir;
}

/// The moment a strong or mighty effect lands on [target], as the layer
/// plays it: a card recoils (see [VfxRecoil]), a mighty blow shakes the
/// screen.
class VfxImpact {
  const VfxImpact({
    required this.target,
    required this.tier,
    required this.hit,
    required this.palette,
  });

  final GlobalKey target;
  final VfxTier tier;

  /// A blow (see [VfxBurst.hit]), not a heal or a shield.
  final bool hit;
  final VfxPalette palette;
}

/// Queues effects for a [CombatVfxLayer] to play.
class CombatVfxController extends ChangeNotifier {
  final List<VfxBurst> _queue = [];
  final List<void Function(VfxImpact)> _impactListeners = [];
  int _seed = 1;

  /// Calls [listener] each time a strong or mighty effect lands.
  void addImpactListener(void Function(VfxImpact) listener) =>
      _impactListeners.add(listener);

  void removeImpactListener(void Function(VfxImpact) listener) =>
      _impactListeners.remove(listener);

  final List<void Function(VfxCue)> _cueListeners = [];

  /// Calls [listener] for every cue to a pixel portrait (see
  /// pixel_portrait.dart): a blow landing, a strike, a fall.
  void addCueListener(void Function(VfxCue) listener) =>
      _cueListeners.add(listener);

  void removeCueListener(void Function(VfxCue) listener) =>
      _cueListeners.remove(listener);

  /// Cues the portrait on [target] to [cue] after [delayMs] ([dir] points
  /// to whom a lunge strikes).
  void cue(GlobalKey target, PortraitCue cue,
      {int delayMs = 0, Offset dir = const Offset(-1, 0)}) {
    _emitCue(VfxCue(target, cue,
        delay: Duration(milliseconds: max(0, delayMs)), dir: dir));
  }

  void _emitCue(VfxCue cue) {
    for (final listener in List.of(_cueListeners)) {
      listener(cue);
    }
  }

  void _reportImpact(VfxImpact impact) {
    for (final listener in List.of(_impactListeners)) {
      listener(impact);
    }
  }

  /// Plays [style] on [target] after [delayMs], in [element]'s colors, at
  /// [power] (see [vfxPowerFor]; a [big] one with none given plays at
  /// 1.35). [hit] says whether it is a blow landing; left out, a heal, a
  /// shield or mana number says it isn't, and the style decides otherwise.
  void play({
    required VfxStyle style,
    required GlobalKey target,
    GlobalKey? source,
    String element = 'None',
    int delayMs = 0,
    String? text,
    VfxTextKind textKind = VfxTextKind.info,
    bool big = false,
    double? power,
    bool? hit,
    VfxAccent accent = VfxAccent.none,
  }) {
    final palette = paletteFor(style, element);
    PixelVfxTints.request(style, palette);
    _queue.add(VfxBurst(
      style: style,
      palette: palette,
      target: target,
      source: source,
      targetFallback: globalRectOf(target),
      sourceFallback: source == null ? null : globalRectOf(source),
      delay: Duration(milliseconds: max(0, delayMs)),
      text: text,
      textKind: textKind,
      big: big,
      power: power ?? (big ? 1.35 : 1.0),
      hit: hit ?? _isBlow(style, textKind),
      accent: accent,
      seed: _seed++ * 7919,
    ));
    notifyListeners();
  }

  /// Hands the queued bursts to the layer.
  List<VfxBurst> takeQueued() {
    final queued = List<VfxBurst>.of(_queue);
    _queue.clear();
    return queued;
  }
}

/// Whether an effect is a blow landing: a damage number says it is, a heal,
/// shield or mana number that it isn't; with no number, the style decides.
bool _isBlow(VfxStyle style, VfxTextKind kind) {
  switch (kind) {
    case VfxTextKind.damage:
    case VfxTextKind.hurt:
    case VfxTextKind.crit:
      return true;
    case VfxTextKind.heal:
    case VfxTextKind.block:
    case VfxTextKind.mana:
      return false;
    case VfxTextKind.info:
      return !supportVfxStyles.contains(style);
  }
}

/// [key]'s widget rect in global coordinates, or null when it is not laid
/// out.
Rect? globalRectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return null;
}

/// Wraps a fighter's card so it answers a strong or mighty effect landing
/// on [anchor] (see [VfxImpact]): a blow knocks it aside and flashes it
/// in the effect's color, a mighty one harder; a strong heal or shield
/// lifts it a little. Still when animations are off.
class VfxRecoil extends StatefulWidget {
  const VfxRecoil({
    super.key,
    required this.controller,
    required this.anchor,
    required this.child,
    this.flash = true,
  });

  final CombatVfxController controller;
  final GlobalKey anchor;
  final Widget child;

  /// Whether the card is washed in the effect's colour (a card with a
  /// pixel portrait flashes that instead).
  final bool flash;

  @override
  State<VfxRecoil> createState() => _VfxRecoilState();
}

class _VfxRecoilState extends State<VfxRecoil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  VfxImpact? _impact;

  @override
  void initState() {
    super.initState();
    widget.controller.addImpactListener(_onImpact);
  }

  @override
  void didUpdateWidget(VfxRecoil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeImpactListener(_onImpact);
      widget.controller.addImpactListener(_onImpact);
    }
  }

  @override
  void dispose() {
    widget.controller.removeImpactListener(_onImpact);
    _anim.dispose();
    super.dispose();
  }

  void _onImpact(VfxImpact impact) {
    if (!mounted || impact.target != widget.anchor) return;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _impact = impact;
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (context, child) {
        final impact = _impact;
        final t = _anim.value;
        final live = impact != null && _anim.isAnimating;
        final mighty = impact?.tier == VfxTier.mighty;
        final fade = live ? 1 - t : 0.0;
        // A blow: a damped shove sideways. A heal or shield: a lift.
        final swing = sin(t * pi * 3) * fade * (mighty ? 8 : 4);
        final offset = !live
            ? Offset.zero
            : impact.hit
                ? Offset(swing, 0)
                : Offset(0, -sin(t * pi) * 3);
        final flash = live && widget.flash
            ? Color(impact.palette.primary)
                .withValues(alpha: (impact.hit ? 0.35 : 0.2) * fade * fade)
            : Colors.transparent;
        return Transform.translate(
          offset: offset,
          child: Stack(
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: flash,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The overlay that draws the bursts: sits over the battle, ignores
/// touches, and ticks only while something is playing. With
/// [reducedMotion] it draws the numbers alone, where they land, without
/// particles or motion.
class CombatVfxLayer extends StatefulWidget {
  const CombatVfxLayer({
    super.key,
    required this.controller,
    this.reducedMotion = false,
  });

  final CombatVfxController controller;
  final bool reducedMotion;

  @override
  State<CombatVfxLayer> createState() => _CombatVfxLayerState();
}

class _CombatVfxLayerState extends State<CombatVfxLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Duration> _clock = ValueNotifier(Duration.zero);
  final List<VfxBurst> _active = [];
  final GlobalKey _boxKey = GlobalKey();
  Duration _base = Duration.zero;

  /// Hit-stop: the ticker time the layer's clock is held until, and how
  /// much held time the clock has given up since the ticker started.
  Duration? _heldUntil;
  Duration _held = Duration.zero;

  /// No new hit-stop before this ticker time: blows landing together share
  /// one pause instead of chaining theirs.
  Duration _nextHoldAt = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onQueued);
  }

  @override
  void didUpdateWidget(CombatVfxLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onQueued);
      widget.controller.addListener(_onQueued);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQueued);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onQueued() {
    final queued = widget.controller.takeQueued();
    if (queued.isEmpty) return;
    for (final burst in queued) {
      burst.startAt = _clock.value + burst.delay;
      _active.add(burst);
    }
    if (!_ticker.isActive) {
      _base = _clock.value;
      _held = Duration.zero;
      _heldUntil = null;
      _nextHoldAt = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final raw = _base + elapsed;
    final heldUntil = _heldUntil;
    if (heldUntil != null) {
      // A mighty blow just landed: every effect holds still a moment.
      if (raw < heldUntil) return;
      _held += vfxHitStop;
      _heldUntil = null;
    }
    final now = raw - _held;
    for (final burst in _active) {
      if (burst.impacted || now < burst.impactAt) continue;
      burst.impacted = true;
      // Any blow landing flashes a pixel portrait, light or mighty.
      if (burst.hit && !systemVfxStyles.contains(burst.style)) {
        widget.controller._emitCue(VfxCue(burst.target, PortraitCue.hit));
      }
      if (burst.tier.index < VfxTier.strong.index ||
          systemVfxStyles.contains(burst.style)) {
        continue;
      }
      widget.controller._reportImpact(VfxImpact(
        target: burst.target,
        tier: burst.tier,
        hit: burst.hit,
        palette: burst.palette,
      ));
      if (burst.tier == VfxTier.mighty &&
          burst.hit &&
          !widget.reducedMotion &&
          _heldUntil == null &&
          raw >= _nextHoldAt) {
        _heldUntil = raw + vfxHitStop;
        _nextHoldAt = raw + vfxHitStop + vfxHitStopCooldown;
      }
    }
    _active.removeWhere(
        (b) => now > b.startAt! + Duration(milliseconds: b.lifeMs));
    _clock.value = now;
    if (_active.isEmpty) _ticker.stop();
  }

  Rect? _localRect(GlobalKey key, Rect? fallbackGlobal) {
    final layer = _boxKey.currentContext?.findRenderObject();
    if (layer is! RenderBox || !layer.attached || !layer.hasSize) return null;
    final global = globalRectOf(key) ?? fallbackGlobal;
    if (global == null) return null;
    final topLeft = layer.globalToLocal(global.topLeft);
    return topLeft & global.size;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: _boxKey,
      child: CustomPaint(
        painter: _VfxPainter(
          bursts: _active,
          clock: _clock,
          resolve: _localRect,
          reducedMotion: widget.reducedMotion,
        ),
      ),
    );
  }
}

typedef _Resolve = Rect? Function(GlobalKey key, Rect? fallbackGlobal);

class _VfxPainter extends CustomPainter {
  _VfxPainter({
    required this.bursts,
    required this.clock,
    required this.resolve,
    required this.reducedMotion,
  }) : super(repaint: clock);

  final List<VfxBurst> bursts;
  final ValueNotifier<Duration> clock;
  final _Resolve resolve;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.value;
    // Many effects at once (a pack fight's dice and a spell landing
    // together): the extra details are thinned so the frame holds, and the
    // screen flashes once.
    var live = 0;
    for (final burst in bursts) {
      final start = burst.startAt;
      if (start == null || now < start) continue;
      if ((now - start).inMilliseconds <= burst.durationMs) live++;
    }
    final frame = _Frame(crowded: live > vfxCrowdedBursts);
    for (final burst in bursts) {
      final start = burst.startAt;
      if (start == null || now < start) continue;
      final elapsedMs = (now - start).inMicroseconds / 1000.0;
      final target = resolve(burst.target, burst.targetFallback);
      if (target == null) continue;
      final source = burst.source == null
          ? null
          : resolve(burst.source!, burst.sourceFallback);
      final t = elapsedMs / burst.durationMs;
      if (!reducedMotion && t <= 1) {
        _Fx(canvas, size, burst, target, source, t.clamp(0.0, 1.0), frame)
            .paint();
      }
      if (burst.text != null) {
        _paintText(
            canvas, burst, target, (elapsedMs / burst.lifeMs).clamp(0.0, 1.0));
      }
    }
  }

  void _paintText(Canvas canvas, VfxBurst burst, Rect target, double t) {
    final color = Color(_textColor(burst.textKind));
    final opacity = t < 0.7 ? 1.0 : max(0.0, 1 - (t - 0.7) / 0.3);
    final painter = TextPainter(
      text: TextSpan(
        text: burst.text,
        style: TextStyle(
          // The app's own pixel font: with no family the number fell back to
          // the platform's, and where that is not loaded it drew as a solid
          // block (QA's pale and red rectangles by the cards, v1.915).
          fontFamily: InkFonts.system,
          fontSize: _textSize(burst) * _textPop(burst, t),
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: opacity),
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.8 * opacity),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final jitter = burst.particles.first.dx * 14;
    final rise = reducedMotion ? 0.0 : 34 * _easeOut(t);
    final offset = Offset(
      target.center.dx - painter.width / 2 + jitter,
      target.top + target.height * 0.3 - painter.height / 2 - rise,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _VfxPainter oldDelegate) => true;
}

/// A floating number's size: by the burst's tier, a critical or a big one
/// never below 22.
double _textSize(VfxBurst burst) {
  final size = vfxTextSize(burst.tier);
  return burst.big || burst.textKind == VfxTextKind.crit ? max(size, 22) : size;
}

/// A strong or mighty number lands big and settles.
double _textPop(VfxBurst burst, double t) {
  if (burst.tier.index < VfxTier.strong.index || t >= 0.15) return 1;
  final k = burst.tier == VfxTier.mighty ? 0.45 : 0.25;
  return 1 + k * (1 - t / 0.15);
}

/// What the bursts drawn in one frame share.
class _Frame {
  _Frame({required this.crowded});

  /// More than [vfxCrowdedBursts] effects in flight.
  final bool crowded;

  /// A burst has already flashed the screen this frame.
  bool flashed = false;
}

int _textColor(VfxTextKind kind) {
  switch (kind) {
    case VfxTextKind.damage:
      return 0xFFFFF3E0;
    case VfxTextKind.hurt:
      return 0xFFFF5252;
    case VfxTextKind.heal:
      return 0xFF69F0AE;
    case VfxTextKind.block:
      return 0xFF82B1FF;
    case VfxTextKind.mana:
      return 0xFFB388FF;
    case VfxTextKind.crit:
      return 0xFFFFD740;
    case VfxTextKind.info:
      return 0xFFE0E0E0;
  }
}

double _easeOut(double t) => 1 - pow(1 - t.clamp(0.0, 1.0), 3).toDouble();
double _easeInOut(double t) {
  final x = t.clamp(0.0, 1.0);
  return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
}

/// Opacity that fades in over [fadeIn] and out from [fadeOutStart].
double _fade(double t, [double fadeIn = 0.1, double fadeOutStart = 0.55]) {
  if (t <= 0 || t >= 1) return 0;
  if (t < fadeIn) return t / fadeIn;
  if (t > fadeOutStart) {
    return max(0, 1 - (t - fadeOutStart) / (1 - fadeOutStart));
  }
  return 1;
}

/// Progress of the window [t0, t0 + span] at [t], or null outside it.
double? _window(double t, double t0, double span) {
  if (t < t0 || t > t0 + span) return null;
  return (t - t0) / span;
}
