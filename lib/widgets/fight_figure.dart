// A figure standing in the fight: the hero, or an enemy that has art. (The hero: the user's ask: "add the character sprite in the
// combat too, oriented east to the enemy"): the ronin of the side view
// (assets/visuals/walker, see side_sprite.dart) stands on the left of the
// battlefield, facing east, toward the enemies. It breathes while the fight
// waits, steps in with its blow when the hero strikes (a lunge cue, as the
// enemies' portraits get), and flinches red when a blow lands on the hero
// (a hit cue). With animations off it stands still; knocked out, it dims.
//
// It draws under the cards and takes no touch, and takes no room: the fight
// places it in the empty ground below the party's cards, and not at all
// where they leave none.
import 'dart:math';

import 'package:flutter/material.dart';

import 'combat_vfx.dart';
import 'fight_sprites.dart';
import 'pixel_portrait.dart' show PortraitCue, portraitCueMs;

class FightFigure extends StatefulWidget {
  const FightFigure({
    super.key,
    required this.controller,
    required this.anchor,
    required this.alive,
    required this.animate,
    required this.sprite,
    this.pixel = 3,
    this.downOpacity = 0.4,
    this.phase = 0,
    this.figureKey = const Key('fight_hero_sprite'),
    this.fallback = true,
  });

  /// True for the hero: a missing image shows the ronin instead. An enemy
  /// (false) with a missing image shows nothing, only its card.
  final bool fallback;

  /// How visible the figure stays once it is down (the hero dims, an enemy
  /// that is beaten goes).
  final double downOpacity;

  /// Where in its breathing the figure starts (0 to 1), so a pack of
  /// enemies does not breathe together.
  final double phase;

  /// The key of the painted figure (a test finds it by this).
  final Key figureKey;

  /// The hero's art (see heroFightSprite): its frame size is what the
  /// figure is sized and placed from.
  final FightSpriteSet sprite;

  final CombatVfxController controller;

  /// The hero's own card key: the cues for it are the sprite's.
  final GlobalKey anchor;

  /// False once the hero is knocked out.
  final bool alive;

  /// False with reduced motion, quick fights or the effects switched off.
  final bool animate;

  /// Screen pixels one sprite pixel covers.
  final double pixel;

  /// The room the figure needs: its height and its width with the lunge's
  /// reach.
  static Size sizeFor(FightSpriteSet sprite, double pixel) => Size(
        sprite.frameWidth * pixel + lungeReach,
        sprite.frameHeight * pixel + 6,
      );

  /// How far a lunge carries the hero forward, in screen pixels.
  static const double lungeReach = 30;

  @override
  State<FightFigure> createState() => _FightFigureState();
}

class _FightFigureState extends State<FightFigure>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  late final AnimationController _cue = AnimationController(vsync: this);
  PortraitCue _kind = PortraitCue.hit;

  @override
  void initState() {
    super.initState();
    FightSpriteImages.load(widget.sprite);
    widget.controller.addCueListener(_onCue);
    _syncIdle();
  }

  @override
  void didUpdateWidget(FightFigure old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeCueListener(_onCue);
      widget.controller.addCueListener(_onCue);
    }
    _syncIdle();
  }

  @override
  void dispose() {
    widget.controller.removeCueListener(_onCue);
    _idle.dispose();
    _cue.dispose();
    super.dispose();
  }

  void _syncIdle() {
    if (widget.animate && widget.alive) {
      if (!_idle.isAnimating) _idle.repeat();
      if (_idle.value == 0 && widget.phase > 0) _idle.value = widget.phase;
    } else {
      _idle.stop();
    }
  }

  void _onCue(VfxCue cue) {
    if (!mounted || !widget.animate || cue.target != widget.anchor) return;
    if (cue.cue == PortraitCue.death) return;
    void go() {
      if (!mounted || !widget.alive) return;
      _kind = cue.cue;
      _cue.duration = Duration(milliseconds: portraitCueMs(cue.cue));
      _cue.forward(from: 0);
    }

    if (cue.delay == Duration.zero) {
      go();
    } else {
      Future<void>.delayed(cue.delay, go);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fallback && FightSpriteImages.failed(widget.sprite)) {
      return const SizedBox.shrink();
    }
    final sprite = FightSpriteImages.effective(widget.sprite);
    final size = FightFigure.sizeFor(sprite, widget.pixel);
    return ValueListenableBuilder<int>(
      valueListenable: FightSpriteImages.loaded,
      builder: (context, _, __) => AnimatedBuilder(
        animation: Listenable.merge([_idle, _cue]),
        builder: (context, _) => AnimatedOpacity(
          duration: Duration(milliseconds: widget.animate ? 700 : 0),
          opacity: widget.alive ? 1 : widget.downOpacity,
          child: CustomPaint(
            key: widget.figureKey,
            size: size,
            painter: _FigurePainter(
              sprite: sprite,
              pixel: widget.pixel,
              idle: _idle.value,
              cue: _cue.isAnimating ? _kind : null,
              cueT: _cue.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.sprite,
    required this.pixel,
    required this.idle,
    required this.cue,
    required this.cueT,
  });

  final FightSpriteSet sprite;
  final double pixel;
  final double idle;
  final PortraitCue? cue;
  final double cueT;

  @override
  void paint(Canvas canvas, Size size) {
    final w = sprite.frameWidth * pixel;
    final h = sprite.frameHeight * pixel;
    const lunge = FightFigure.lungeReach;
    // The hero lunges east, an enemy west; the room for it is on that side.
    final way = sprite.facesEast ? 1.0 : -1.0;
    final left = sprite.facesEast ? 0.0 : lunge;
    var dx = 0.0;
    var tint = 0.0;
    switch (cue) {
      case PortraitCue.lunge:
        // In with the blow, and back: out fast, home slowly.
        final k = cueT < 0.35 ? cueT / 0.35 : 1 - (cueT - 0.35) / 0.65;
        dx = way * lunge * Curves.easeOut.transform(k.clamp(0.0, 1.0));
      case PortraitCue.hit:
        // A red flash and a shake that dies away.
        final decay = 1 - cueT;
        dx = -sin(cueT * pi * 6) * decay * 5;
        tint = decay;
      case PortraitCue.death:
      case null:
        break;
    }
    final baseY = size.height - 6;
    // Standing, the figure breathes: one sprite pixel up and down, slowly.
    final bob = (idle % 1.0) < 0.5 ? 0.0 : -pixel;
    // The ground shadow under the feet.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(left + w / 2 + dx * 0.4, baseY + 1),
          width: w * 0.55,
          height: 7),
      Paint()..color = const Color(0x33000000),
    );
    final image = FightSpriteImages.idleOf(sprite);
    if (image == null) {
      // The image is not in yet: a quiet mark where the figure will stand.
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(left + w / 2, baseY - h / 2),
            width: w * 0.4,
            height: h * 0.6),
        Paint()..color = const Color(0x22000000),
      );
      return;
    }
    if (tint > 0.05) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..colorFilter = ColorFilter.mode(
              const Color(0xFFE5392B).withValues(alpha: 0.55 * tint),
              BlendMode.srcATop),
      );
    }
    // The empty rows under the feet hang below the ground line.
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
          0, 0, sprite.frameWidth.toDouble(), sprite.frameHeight.toDouble()),
      Rect.fromLTWH(
          left + dx, baseY - h + bob + sprite.footInset * pixel, w, h),
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    if (tint > 0.05) canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.sprite != sprite ||
      old.pixel != pixel ||
      old.idle != idle ||
      old.cue != cue ||
      old.cueT != cueT;
}
