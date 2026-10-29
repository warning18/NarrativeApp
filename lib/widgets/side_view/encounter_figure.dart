// What the party meets on a land crossing (the scavengers, the Inquisition
// patrol): its figure walks in from the left (as the user asked), behind the
// party, and stops there facing it, then breathes while the choice is made.
// The enemy art faces west (assets/visuals/fighters), so it is drawn
// mirrored to face east, toward the party; the sprites have no walk strip,
// so it steps in with a bob. An enemy with no art yet is a plain grey
// placeholder figure. With animations off it simply stands in place.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../fight_sprites.dart';
import 'side_view.dart';

class EncounterWalk {
  EncounterWalk({required this.sprite, this.animate = true});

  /// The art of the figure; null for the placeholder.
  final FightSpriteSet? sprite;

  /// False with animations off: it stands at its place from the start.
  final bool animate;

  /// How long it takes to walk in, in seconds.
  static const double walkSeconds = 1.4;

  /// How far (scene pixels) it stops behind the party's last figure, and how
  /// far past the scene's left edge it starts.
  static const double gap = 26;
  static const double offscreen = 16;

  /// A sprite pixel in scene pixels (the hero's scale).
  static const double scale = 0.5;

  double? _start;

  /// Where it stops, given the place of the party's last figure.
  static double stopXFor(double partyX) => math.max(partyX - gap, 14.0);

  /// Where it stands at [progress] (0 to 1) of the walk: from past the left
  /// edge to its stop behind the party.
  static double xAt(double progress, double partyX) =>
      ui.lerpDouble(-offscreen, stopXFor(partyX), progress)!;

  /// How far along the walk is at clock [t] (0 to 1).
  double progressAt(double t) {
    if (!animate) return 1;
    final start = _start ??= t;
    final p = ((t - start) / walkSeconds).clamp(0.0, 1.0);
    return 1 - math.pow(1 - p, 2).toDouble();
  }

  /// Paints the figure on the ground (scene pixel row 66, the party's), with
  /// [partyX] the place of the party's last figure (the one nearest the
  /// left).
  void paint(ui.Canvas canvas, Size size, double t, double u,
      {required double partyX, double baseY = 66}) {
    final p = progressAt(t);
    final x = xAt(p, partyX);
    final walking = p < 1;
    // Stepping in it bobs a pixel every other stride; standing, it breathes.
    final bob = walking
        ? (((t * 6).floor() % 2) == 0 ? 0.0 : -1.0)
        : (((t * 1.2) % 1.0) < 0.5 ? 0.0 : -scale);
    final set = sprite;
    final image = set == null ? null : FightSpriteImages.idleOf(set);
    // The art faces west (a set drawn facing east keeps its side): mirrored
    // about its own middle, it faces east.
    canvas.save();
    if (set == null || !FightSpriteImages.effective(set).facesEast) {
      canvas.translate(x * u, 0);
      canvas.scale(-1, 1);
      canvas.translate(-x * u, 0);
    }
    if (set != null && image != null) {
      final use = FightSpriteImages.effective(set);
      final w = use.frameWidth * scale;
      final h = use.frameHeight * scale;
      final foot = use.footInset * scale;
      final dst = ui.Rect.fromLTWH(
          (x - w / 2) * u, (baseY - h + foot + bob) * u, w * u, h * u);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(
            0, 0, use.frameWidth.toDouble(), use.frameHeight.toDouble()),
        dst,
        ui.Paint()
          ..filterQuality = ui.FilterQuality.none
          ..isAntiAlias = false,
      );
    } else if (set == null) {
      _placeholder(canvas, u, x, baseY + bob);
    }
    canvas.restore();
  }

  void _placeholder(ui.Canvas canvas, double u, double x, double baseY) {
    final body = Paint()..color = const Color(0xFF6E6A66);
    final dark = Paint()..color = const Color(0xFF2A2624);
    final skin = Paint()..color = const Color(0xFFB09A86);
    // 16 px tall, like the sprites' 24: a hooded stranger (drawn facing west, mirrored by the walk).
    sidePixels(canvas, u, dark, x - 3, baseY - 4, 2, 4);
    sidePixels(canvas, u, dark, x + 1, baseY - 4, 2, 4);
    sidePixels(canvas, u, body, x - 4, baseY - 12, 8, 9);
    sidePixels(canvas, u, body, x - 3, baseY - 16, 6, 4);
    sidePixels(canvas, u, skin, x - 3, baseY - 14, 2, 2);
  }
}
