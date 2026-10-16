// The hero in the fight (the user's ask: "add the character sprite in the
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
import 'pixel_portrait.dart' show PortraitCue, portraitCueMs;
import 'side_view/side_sprite.dart';

class FightHeroSprite extends StatefulWidget {
  const FightHeroSprite({
    super.key,
    required this.controller,
    required this.anchor,
    required this.alive,
    required this.animate,
    this.pixel = 3,
  });

  final CombatVfxController controller;

  /// The hero's own card key: the cues for it are the sprite's.
  final GlobalKey anchor;

  /// False once the hero is knocked out.
  final bool alive;

  /// False with reduced motion, quick fights or the effects switched off.
  final bool animate;

  /// Screen pixels one sprite pixel covers.
  final double pixel;

  /// The room the sprite needs: its height and its width with the lunge's
  /// reach.
  static Size sizeFor(double pixel) => Size(
        SideSprites.frameWidth * SideSprites.scale * pixel * 2 + lungeReach,
        SideSprites.frameHeight * SideSprites.scale * pixel * 2 + 6,
      );

  /// How far a lunge carries the hero forward, in screen pixels.
  static const double lungeReach = 30;

  @override
  State<FightHeroSprite> createState() => _FightHeroSpriteState();
}

class _FightHeroSpriteState extends State<FightHeroSprite>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  late final AnimationController _cue = AnimationController(vsync: this);
  PortraitCue _kind = PortraitCue.hit;

  @override
  void initState() {
    super.initState();
    SideSprites.preload();
    widget.controller.addCueListener(_onCue);
    _syncIdle();
  }

  @override
  void didUpdateWidget(FightHeroSprite old) {
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
    final size = FightHeroSprite.sizeFor(widget.pixel);
    return ValueListenableBuilder<bool>(
      valueListenable: SideSprites.ready,
      builder: (context, _, __) => AnimatedBuilder(
        animation: Listenable.merge([_idle, _cue]),
        builder: (context, _) => Opacity(
          opacity: widget.alive ? 1 : 0.4,
          child: CustomPaint(
            key: const Key('fight_hero_sprite'),
            size: size,
            painter: _HeroPainter(
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

class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required this.pixel,
    required this.idle,
    required this.cue,
    required this.cueT,
  });

  final double pixel;
  final double idle;
  final PortraitCue? cue;
  final double cueT;

  @override
  void paint(Canvas canvas, Size size) {
    // One scene pixel is two sprite-pixel widths of the side view's scale.
    final u = pixel * 2;
    final w = SideSprites.frameWidth * SideSprites.scale * u;
    const lunge = FightHeroSprite.lungeReach;
    var dx = 0.0;
    var tint = 0.0;
    switch (cue) {
      case PortraitCue.lunge:
        // In with the blow, and back: out fast, home slowly.
        final k = cueT < 0.35 ? cueT / 0.35 : 1 - (cueT - 0.35) / 0.65;
        dx = lunge * Curves.easeOut.transform(k.clamp(0.0, 1.0));
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
    final x = w / 2 + dx;
    // The ground shadow under the feet.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2 + dx * 0.4, baseY + 1),
          width: w * 0.7,
          height: 7),
      Paint()..color = const Color(0x33000000),
    );
    if (tint > 0.05) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..colorFilter = ColorFilter.mode(
              const Color(0xFFE5392B).withValues(alpha: 0.55 * tint),
              BlendMode.srcATop),
      );
    }
    final drawn = SideSprites.paint(canvas, u, x / u, baseY / u, idle,
        moving: false, east: true);
    if (tint > 0.05) canvas.restore();
    if (!drawn) {
      // The images are not in yet: a quiet mark where the hero will stand.
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, baseY - 18), width: 16, height: 30),
        Paint()..color = const Color(0x22000000),
      );
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.pixel != pixel ||
      old.idle != idle ||
      old.cue != cue ||
      old.cueT != cueT;
}
