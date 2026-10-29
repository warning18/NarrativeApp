// What each die adds to its skin (docs/proposals/dice-looks.md, the sheet of
// the 31): a few pieces of its own drawn over the die, keyed to its id, a
// handful of paths each and no image files: spikes, flames, a crown, a
// crescent, vines, an arrow through it. It is painted with the die, so it
// turns and squeezes with it. Drawn in a unit disc about the die's centre,
// so one set of paths fits every shape; [corners] are the shape's outermost
// points, where spikes and crowns go.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'die_skins.dart';

/// A line of words saying what a die's art is, for its sheet.
const Map<String, String> dieArtNotes = {
  'void_die': 'stars and a dark swirl',
  'stone_die': 'chipped corners, a cut rune',
  'berserker_die': 'spikes, blood running',
  'shadow_die': 'a crescent moon cut in',
  'twinfang_die': 'curved fangs for tips',
  'headsman_die': 'an axe blade at its side',
  'apprentice_die': 'a chalk star doodle',
  'iron_die': 'riveted bands',
  'holy_die': 'a cross and rays',
  'bulwark_die': 'battlements on top',
  'pilgrim_die': 'a scallop shell',
  'liora_die': 'vines and leaves',
  'grosh_die': 'tusk spikes, notches',
  'tobin_die': 'a reliquary cross, brass caps',
  'malrik_die': 'rust and a crack',
  'flame_die': 'flame tongues rising',
  'tide_die': 'a wave curling over',
  'huntsman_die': 'an arrow through it',
  'vess_die': 'an ink drop, ripples',
  'frost_die': 'icicles hanging',
  'greenwood_die': 'a crown of leaves',
  'vigil_die': 'a candle flame, wax',
  'storm_die': 'lightning over the faces',
  'arcane_die': 'a ring of runes',
  'sage_die': 'an eye on its face',
  'ossuary_die': 'a small skull',
  'tempest_die': 'thunder bolt, a cloud',
  'chorus_die': 'sound rings, a bell',
  'tearglass_die': 'the legendary d12: a crown, a tear, a halo',
  'gambler_die': 'suits and red pips',
  'hound_die': 'a paw print in her white',
  'tally_die': 'tally marks, the fifth across',
};

/// Whether die [id] has art to draw (the plain first die has none).
bool dieHasArt(String? id) => id != null && dieArtNotes.containsKey(id);

/// The halo behind the legendary die: twelve rays of its own light.
void paintDieHalo(Canvas canvas, Size size, String? id) {
  if (id != 'tearglass_die') return;
  final c = size.center(Offset.zero);
  final r = size.shortestSide / 2;
  final p = Paint()..color = const Color(0xFF38D6C0).withValues(alpha: 0.2);
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - 0.1) * r * 1.25,
              c.dy + math.sin(a - 0.1) * r * 1.25)
          ..lineTo(c.dx + math.cos(a + 0.1) * r * 1.25,
              c.dy + math.sin(a + 0.1) * r * 1.25)
          ..close(),
        p);
  }
}

/// The art of die [id], drawn over its shape and skin in the unit disc whose
/// centre is the middle of [size].
void paintDieArt(
    Canvas canvas, Size size, String? id, DieSkin skin, List<Offset> corners) {
  if (!dieHasArt(id)) return;
  final r = size.shortestSide / 2 * 0.98;
  final c = Offset(size.width / 2, size.height * 0.51);
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(r, r);
  final hair = 1.6 / r;
  Paint stroke(Color col, [double w = 1.0]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = hair * w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = col;
  Paint fill(Color col) => Paint()..color = col;

  const bone = Color(0xFFF0EAD6);

  void spikes(Color col, double len, double half) {
    for (final v in corners) {
      final n = v / v.distance;
      final perp = Offset(-n.dy, n.dx);
      canvas.drawPath(
          Path()
            ..moveTo(v.dx - perp.dx * half, v.dy - perp.dy * half)
            ..lineTo(v.dx + n.dx * len, v.dy + n.dy * len)
            ..lineTo(v.dx + perp.dx * half, v.dy + perp.dy * half)
            ..close(),
          fill(col));
    }
  }

  void leaf(double x, double y, double a, Color col, [double s = 1]) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(a);
    canvas.drawOval(
        Rect.fromLTWH(-0.045 * s, -0.12 * s, 0.09 * s, 0.24 * s), fill(col));
    canvas.restore();
  }

  void drop(double x, double y, double s, Color col) {
    canvas.drawPath(
        Path()
          ..moveTo(x, y - s * 1.3)
          ..quadraticBezierTo(x + s * 0.9, y, x, y + s * 0.5)
          ..quadraticBezierTo(x - s * 0.9, y, x, y - s * 1.3)
          ..close(),
        fill(col));
  }

  void flame(double x, double y, double s, Color a, Color b) {
    canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(
              x - s * 0.7, y - s * 0.5, x - s * 0.2, y - s * 1.3)
          ..quadraticBezierTo(
              x + s * 0.1, y - s * 0.7, x + s * 0.3, y - s * 0.9)
          ..quadraticBezierTo(x + s * 0.8, y - s * 0.3, x, y)
          ..close(),
        fill(a));
    canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x - s * 0.3, y - s * 0.3, x, y - s * 0.7)
          ..quadraticBezierTo(x + s * 0.3, y - s * 0.3, x, y)
          ..close(),
        fill(b));
  }

  void crown(Color col, double y0) {
    canvas.drawPath(
        Path()
          ..moveTo(-0.5, y0)
          ..lineTo(-0.55, y0 - 0.38)
          ..lineTo(-0.25, y0 - 0.16)
          ..lineTo(0, y0 - 0.5)
          ..lineTo(0.25, y0 - 0.16)
          ..lineTo(0.55, y0 - 0.38)
          ..lineTo(0.5, y0)
          ..close(),
        fill(col));
  }

  switch (id) {
    case 'starter_die':
      break;
    case 'apprentice_die': // a chalk star
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final rr = i.isEven ? 0.2 : 0.08;
        final p = Offset(0.38 + math.cos(a) * rr, -0.05 + math.sin(a) * rr);
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(star..close(), stroke(const Color(0xFF7C8CFF), 1.4));
    case 'iron_die': // riveted bands
      canvas.drawLine(const Offset(-0.87, -0.5), const Offset(0, 0),
          stroke(const Color(0xFF2B2F35), 3));
      canvas.drawLine(const Offset(0, 0), const Offset(0.87, -0.5),
          stroke(const Color(0xFF2B2F35), 3));
      for (final p in const [
        Offset(-0.55, -0.32),
        Offset(-0.2, -0.12),
        Offset(0.25, -0.15),
        Offset(0.6, -0.35),
        Offset(0.45, 0.45)
      ]) {
        canvas.drawCircle(p, 0.05, fill(const Color(0xFFC4CBD3)));
      }
    case 'holy_die': // a cross, rays about it
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        canvas.drawLine(
            Offset(math.cos(a) * 1.05, math.sin(a) * 1.05),
            Offset(math.cos(a) * 1.3, math.sin(a) * 1.3),
            stroke(const Color(0xFFF2C14E), 1.6));
      }
      canvas.drawLine(const Offset(0.45, -0.3), const Offset(0.45, 0.35),
          stroke(const Color(0xFFF2C14E), 2));
      canvas.drawLine(const Offset(0.3, -0.05), const Offset(0.6, -0.05),
          stroke(const Color(0xFFF2C14E), 2));
    case 'bulwark_die': // battlements
      for (final x in [-0.35, -0.05, 0.25]) {
        canvas.drawRect(
            Rect.fromLTWH(x, -1.2, 0.2, 0.2), fill(const Color(0xFF8E96A2)));
      }
    case 'pilgrim_die': // a scallop shell
      for (var i = 0; i < 6; i++) {
        final a = -math.pi + 0.35 + i * 0.5;
        canvas.drawLine(
            const Offset(0.42, 0.4),
            Offset(0.42 + math.cos(a) * 0.3, 0.4 + math.sin(a) * 0.3),
            stroke(const Color(0xFFDCCB9F), 1.3));
      }
      canvas.drawArc(
          Rect.fromCircle(center: const Offset(0.42, 0.4), radius: 0.3),
          -math.pi,
          math.pi,
          false,
          stroke(const Color(0xFFDCCB9F), 1.3));
    case 'liora_die':
      canvas.drawPath(
          Path()
            ..moveTo(-0.87, 0.5)
            ..quadraticBezierTo(-0.5, 0.2, -0.3, 0.55)
            ..quadraticBezierTo(0.0, 0.9, 0.35, 0.7),
          stroke(const Color(0xFF95D16F), 1.6));
      leaf(-0.5, 0.32, -0.8, const Color(0xFF6FBF4E));
      leaf(-0.1, 0.78, 0.6, const Color(0xFF6FBF4E));
      leaf(0.3, 0.72, -0.4, const Color(0xFF6FBF4E));
      leaf(0.74, -0.45, 0.9, const Color(0xFF6FBF4E));
    case 'grosh_die':
      spikes(const Color(0xFFE9E0C2), 0.26, 0.1);
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(Offset(0.2 + i * 0.1, 0.45),
            Offset(0.2 + i * 0.1, 0.62), stroke(const Color(0xFF8F8771), 1.2));
      }
    case 'tobin_die': // a reliquary cross, brass caps
      canvas.drawLine(const Offset(0.45, -0.3), const Offset(0.45, 0.35),
          stroke(const Color(0xFFE5B566), 2.4));
      canvas.drawLine(const Offset(0.3, -0.05), const Offset(0.6, -0.05),
          stroke(const Color(0xFFE5B566), 2.4));
      for (final v in corners) {
        canvas.drawCircle(v * 0.95, 0.06, fill(const Color(0xFFE5B566)));
      }
    case 'malrik_die': // rust and a crack
      for (final (x, y, s) in const [
        (-0.5, -0.3, 0.11),
        (0.45, 0.2, 0.09),
        (-0.3, 0.5, 0.08),
        (0.55, -0.4, 0.07)
      ]) {
        canvas.drawCircle(Offset(x, y), s, fill(const Color(0x99CC8250)));
      }
      canvas.drawPath(
          Path()
            ..moveTo(0.1, -0.6)
            ..lineTo(0.0, -0.2)
            ..lineTo(0.2, 0.1),
          stroke(const Color(0xFF2B1A12), 1.2));
    case 'void_die': // stars and a dark swirl
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: 0.3), 0.3,
          4.2, false, stroke(const Color(0xFF8D6CFF), 1.6));
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: 0.15), 3.4,
          4.2, false, stroke(const Color(0xFF8D6CFF), 1.4));
      for (final p in const [
        Offset(-1.1, -0.7),
        Offset(1.1, -0.4),
        Offset(0.9, 0.9),
        Offset(-0.9, 0.8)
      ]) {
        canvas.drawCircle(p, 0.04, fill(Colors.white));
      }
    case 'stone_die': // chipped corners, a cut rune
      for (final v in corners) {
        canvas.drawPath(
            Path()
              ..moveTo(v.dx * 0.86, v.dy * 0.86)
              ..lineTo(v.dx * 1.02 + 0.06, v.dy * 1.02 + 0.02)
              ..lineTo(v.dx * 0.9, v.dy * 0.7)
              ..close(),
            fill(const Color(0xFF2A241D)));
      }
      canvas.drawPath(
          Path()
            ..moveTo(0.3, 0.2)
            ..lineTo(0.52, 0.2)
            ..moveTo(0.41, 0.2)
            ..lineTo(0.41, 0.5),
          stroke(skin.edge, 1.4));
    case 'berserker_die': // spikes, blood running
      spikes(const Color(0xFFE8473F), 0.22, 0.09);
      for (final x in [-0.3, 0.05, 0.4]) {
        drop(x, 0.0, 0.06, const Color(0xFFE8473F));
        canvas.drawLine(Offset(x, -0.4), Offset(x, -0.1),
            stroke(const Color(0xFFE8473F), 1.6));
      }
    case 'shadow_die': // a crescent
      canvas.drawPath(
          Path.combine(
              PathOperation.difference,
              Path()
                ..addOval(Rect.fromCircle(
                    center: const Offset(0.2, 0.2), radius: 0.28)),
              Path()
                ..addOval(Rect.fromCircle(
                    center: const Offset(0.3, 0.12), radius: 0.24))),
          fill(const Color(0xFFD7DAEA)));
    case 'twinfang_die':
      spikes(bone, 0.3, 0.09);
    case 'headsman_die': // an axe blade at its side
      canvas.drawLine(const Offset(1.0, -1.1), const Offset(1.0, 0.1),
          stroke(const Color(0xFF8A6A48), 2.4));
      canvas.drawPath(
          Path()
            ..moveTo(1.0, -1.0)
            ..quadraticBezierTo(1.5, -0.8, 1.45, -0.35)
            ..quadraticBezierTo(1.3, -0.3, 1.0, -0.4)
            ..close(),
          fill(const Color(0xFFCF3E2F)));
    case 'flame_die':
      flame(-0.3, -0.9, 0.3, const Color(0xFFFF8A3D), const Color(0xFFFFD27A));
      flame(0.0, -0.95, 0.42, const Color(0xFFFF6A1F), const Color(0xFFFFD27A));
      flame(0.3, -0.9, 0.3, const Color(0xFFFF8A3D), const Color(0xFFFFD27A));
    case 'tide_die': // a wave curling
      canvas.drawPath(
          Path()
            ..moveTo(-0.7, 0.75)
            ..quadraticBezierTo(-0.3, 0.2, 0.15, 0.55)
            ..quadraticBezierTo(0.5, 0.8, 0.7, 0.4)
            ..quadraticBezierTo(0.5, 0.15, 0.35, 0.35),
          stroke(const Color(0xFFA6F5EC), 1.8));
    case 'huntsman_die': // an arrow through it
      canvas.drawLine(const Offset(-1.15, 0.9), const Offset(1.15, -0.9),
          stroke(const Color(0xFFB5935F), 1.8));
      canvas.drawPath(
          Path()
            ..moveTo(1.2, -1.0)
            ..lineTo(0.92, -0.9)
            ..lineTo(1.08, -0.72)
            ..close(),
          fill(const Color(0xFFDCCB9F)));
      for (final d in [0.0, 0.1]) {
        canvas.drawLine(
            Offset(-1.15 + d, 0.9 - d * 0.8),
            Offset(-1.3 + d, 0.8 - d * 0.8),
            stroke(const Color(0xFFDCCB9F), 1.4));
      }
    case 'vess_die': // an ink drop and ripples
      drop(0.0, -1.2, 0.14, const Color(0xFF86D6FF));
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(0, 0.28), width: 0.6, height: 0.18),
          stroke(const Color(0xFF86D6FF), 1.2));
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(0, 0.28), width: 0.34, height: 0.1),
          stroke(const Color(0xFF86D6FF), 1.2));
    case 'frost_die': // icicles
      for (final x in [-0.5, -0.15, 0.2, 0.55]) {
        canvas.drawPath(
            Path()
              ..moveTo(x - 0.08, 0.78)
              ..lineTo(x + 0.08, 0.78)
              ..lineTo(x, 1.1 + (x.abs() < 0.3 ? 0.12 : 0))
              ..close(),
            fill(const Color(0xFFC4EBFF)));
      }
    case 'greenwood_die': // a crown of leaves
      for (var i = 0; i < 5; i++) {
        leaf(-0.5 + i * 0.25, -1.0 - (i == 2 ? 0.1 : 0.0), -0.6 + i * 0.3,
            const Color(0xFFA8D96D), 1.2);
      }
    case 'vigil_die': // a candle flame and wax
      canvas.drawRect(const Rect.fromLTWH(-0.07, -1.25, 0.14, 0.27),
          fill(const Color(0xFFE8DFC4)));
      flame(0, -1.25, 0.2, const Color(0xFFFFC96B), const Color(0xFFFFF0B0));
      drop(0.5, 0.0, 0.06, const Color(0xFFE8DFC4));
    case 'storm_die':
      canvas.drawPath(
          Path()
            ..moveTo(-0.5, -0.8)
            ..lineTo(-0.1, -0.3)
            ..lineTo(-0.3, -0.2)
            ..lineTo(0.2, 0.4)
            ..lineTo(0.0, 0.45)
            ..lineTo(0.35, 0.95),
          stroke(const Color(0xFFDDEBFF), 1.6));
    case 'arcane_die': // a ring of runes
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final p = Offset(math.cos(a) * 1.15, math.sin(a) * 1.15);
        canvas.drawLine(p, p + const Offset(0.0, 0.1),
            stroke(const Color(0xFF8E9CFF), 1.6));
        canvas.drawLine(p + const Offset(-0.05, 0.03),
            p + const Offset(0.05, 0.06), stroke(const Color(0xFF8E9CFF), 1.4));
      }
    case 'sage_die': // an eye
      canvas.drawPath(
          Path()
            ..moveTo(-0.3, 0.1)
            ..quadraticBezierTo(0, -0.22, 0.3, 0.1)
            ..quadraticBezierTo(0, 0.4, -0.3, 0.1),
          stroke(skin.edge, 1.4));
      canvas.drawCircle(const Offset(0, 0.1), 0.1, fill(skin.edge));
      canvas.drawCircle(
          const Offset(0, 0.1), 0.045, fill(const Color(0xFF0B1220)));
    case 'ossuary_die': // a skull
      canvas.drawCircle(const Offset(0.4, 0.0), 0.2, fill(bone));
      canvas.drawRect(const Rect.fromLTWH(0.3, 0.12, 0.2, 0.14), fill(bone));
      canvas.drawCircle(
          const Offset(0.34, 0.0), 0.05, fill(const Color(0xFF3A3328)));
      canvas.drawCircle(
          const Offset(0.46, 0.0), 0.05, fill(const Color(0xFF3A3328)));
    case 'tempest_die': // a thunder bolt, a cloud
      canvas.drawCircle(
          const Offset(-0.3, -1.05), 0.2, fill(const Color(0xFF6B7487)));
      canvas.drawCircle(
          const Offset(0.0, -1.12), 0.26, fill(const Color(0xFF7C869B)));
      canvas.drawCircle(
          const Offset(0.3, -1.05), 0.2, fill(const Color(0xFF6B7487)));
      canvas.drawPath(
          Path()
            ..moveTo(0.15, -0.9)
            ..lineTo(-0.1, -0.35)
            ..lineTo(0.1, -0.35)
            ..lineTo(-0.15, 0.2),
          stroke(const Color(0xFFFFE48A), 2.4));
    case 'chorus_die': // sound rings and a bell
      for (final k in [1.12, 1.3]) {
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: k), -0.5,
            1.0, false, stroke(const Color(0xFFF5F7FB), 1.3));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: k),
            math.pi - 0.5, 1.0, false, stroke(const Color(0xFFF5F7FB), 1.3));
      }
      canvas.drawPath(
          Path()
            ..moveTo(-0.14, 0.2)
            ..quadraticBezierTo(-0.16, -0.12, 0, -0.14)
            ..quadraticBezierTo(0.16, -0.12, 0.14, 0.2)
            ..close(),
          fill(const Color(0xFFF5F7FB)));
    case 'tearglass_die': // THE LEGENDARY D12: a crown, a tear
      crown(const Color(0xFFA0F5E8), -1.0);
      drop(0.0, 0.1, 0.16, const Color(0xFFA0F5E8));
      for (final v in corners.skip(1)) {
        canvas.drawCircle(v, 0.05, fill(const Color(0xFFF2C14E)));
      }
    case 'hound_die': // a paw print
      const paw = Color(0xFFF2F0EA);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(0.4, 0.28), width: 0.3, height: 0.24),
          fill(paw));
      for (final p in const [
        Offset(0.22, 0.04),
        Offset(0.35, -0.08),
        Offset(0.5, -0.08),
        Offset(0.62, 0.04)
      ]) {
        canvas.drawCircle(p, 0.065, fill(paw));
      }
    case 'tally_die': // tally marks, the fifth across
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
            Offset(0.22 + i * 0.12, -0.12),
            Offset(0.22 + i * 0.12, 0.34),
            stroke(const Color(0xFF7C735B), 1.8));
      }
      canvas.drawLine(const Offset(0.16, 0.26), const Offset(0.7, -0.04),
          stroke(const Color(0xFF7C735B), 1.8));
    case 'gambler_die': // suits and red pips
      canvas.drawPath(
          Path()
            ..moveTo(0.0, -0.1)
            ..lineTo(0.1, 0.0)
            ..lineTo(0.0, 0.1)
            ..lineTo(-0.1, 0.0)
            ..close(),
          fill(const Color(0xFFC0392B)));
      for (final p in const [
        Offset(-0.55, -0.15),
        Offset(0.55, 0.45),
        Offset(-0.2, 0.6)
      ]) {
        canvas.drawCircle(p, 0.06, fill(const Color(0xFFC0392B)));
      }
  }
  canvas.restore();
}
