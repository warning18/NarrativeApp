// PROTOTYPE (pictures only, no PR): dice that are thrown. The result is
// decided before the throw; this only chooses where the dice go. Each die
// flies in from the bottom edge on an arc, bounces 2 to 3 times with damping,
// slides, turns over as it slows, pushes the others aside without overlapping
// and lands on the face the rules picked (Die3D's roll ends on faces[0]).
// UX_SHOTS=<folder>: frames and the frame time on this machine.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_dice.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';

import 'support/fonts.dart';

class _Die {
  _Die(this.shape, this.size, this.skin, this.x, this.y, this.vx, this.vy,
      this.vz, this.seed);
  final DieShape shape;
  final double size;
  final DieSkin skin;
  double x, y, z = 46, vx, vy, vz;
  final int seed;
  int bounces = 0;
  double settledAt = -1;
  double get r => size * 0.5 * dieSolidScale(shape) * 0.95;
}

class _Frame {
  _Frame(this.pos, this.z, this.t);
  final List<Offset> pos;
  final List<double> z;
  final List<double> t; // each die's roll progress, 0..1
}

/// The throw, stepped at 1/120 s, sampled every 1/30 s.
List<_Frame> _simulate(List<_Die> dice, Size plate, {double seconds = 2.6}) {
  const dt = 1 / 120;
  const g = 1500.0;
  final frames = <_Frame>[];
  final steps = (seconds / dt).round();
  for (var s = 0; s <= steps; s++) {
    final time = s * dt;
    for (final d in dice) {
      if (d.settledAt >= 0) continue;
      d.vz -= g * dt;
      d.z += d.vz * dt;
      if (d.z <= 0) {
        d.z = 0;
        if (d.vz.abs() > 90 && d.bounces < 3) {
          d.vz = -d.vz * 0.52;
          d.vx *= 0.78;
          d.vy *= 0.78;
          d.bounces++;
        } else {
          d.vz = 0;
        }
      }
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      if (d.z == 0 && d.vz == 0) {
        final k = math.max(0.0, 1 - 2.6 * dt);
        d.vx *= k;
        d.vy *= k;
      }
      // The plate's walls (the bottom is open until the die is in).
      final inside = d.y < plate.height - d.r;
      if (d.x < d.r) {
        d.x = d.r;
        d.vx = d.vx.abs() * 0.5;
      }
      if (d.x > plate.width - d.r) {
        d.x = plate.width - d.r;
        d.vx = -d.vx.abs() * 0.5;
      }
      if (d.y < d.r) {
        d.y = d.r;
        d.vy = d.vy.abs() * 0.5;
      }
      if (inside && d.y > plate.height - d.r) {
        d.y = plate.height - d.r;
        d.vy = -d.vy.abs() * 0.5;
      }
    }
    // Dice push each other aside, on the ground only, never overlapping.
    for (var i = 0; i < dice.length; i++) {
      for (var j = i + 1; j < dice.length; j++) {
        final a = dice[i], b = dice[j];
        if (a.z > a.r * 0.8 || b.z > b.r * 0.8) continue;
        final dx = b.x - a.x, dy = b.y - a.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        final min = a.r + b.r;
        if (dist < min && dist > 0.001) {
          final nx = dx / dist, ny = dy / dist, push = (min - dist) / 2;
          a.x -= nx * push;
          a.y -= ny * push;
          b.x += nx * push;
          b.y += ny * push;
          final va = a.vx * nx + a.vy * ny, vb = b.vx * nx + b.vy * ny;
          final dv = (va - vb) * 0.6;
          if (dv > 0) {
            a.vx -= nx * dv;
            a.vy -= ny * dv;
            b.vx += nx * dv;
            b.vy += ny * dv;
          }
          a.settledAt = -1;
          b.settledAt = -1;
        }
      }
    }
    for (final d in dice) {
      final speed = math.sqrt(d.vx * d.vx + d.vy * d.vy);
      if (d.z == 0 && d.vz == 0 && speed < 6 && d.y < plate.height - d.r) {
        d.settledAt = d.settledAt < 0 ? time : d.settledAt;
      }
    }
    if (s % 4 == 0) {
      frames.add(_Frame([for (final d in dice) Offset(d.x, d.y)],
          [for (final d in dice) d.z], List<double>.filled(dice.length, 0)));
    }
  }
  // Each die's turn runs from its launch to its last move: it is still
  // turning while it slides, and square on the picked face when it stops.
  for (final d in dice) {
    d.settledAt = d.settledAt < 0 ? seconds : d.settledAt;
  }
  final out = <_Frame>[];
  for (var f = 0; f < frames.length; f++) {
    final time = f * 4 * dt;
    out.add(_Frame(frames[f].pos, frames[f].z, [
      for (final d in dice) (time / math.max(0.5, d.settledAt)).clamp(0.0, 1.0)
    ]));
  }
  return out;
}

List<DieCubeFace> _faces(int n, Color text) => [
      for (var i = 0; i < n; i++)
        DieCubeFace(
            glyph: Text('${(i + 1) % n == 0 ? n : (i + 1) % n}',
                style: TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 18,
                    color: text,
                    fontWeight: FontWeight.w700)),
            color: FaceKind.values[i % FaceKind.values.length].color)
    ];

Widget _stage(
    List<_Die> dice, _Frame f, Size plate, Color bg, Color edge, bool reduced) {
  return Container(
    width: plate.width,
    height: plate.height,
    decoration: BoxDecoration(color: bg, border: Border.all(color: edge)),
    child: ClipRect(
      child: Stack(clipBehavior: Clip.none, children: [
        for (var i = 0; i < dice.length; i++) ...[
          // The shadow on the ground, smaller and paler the higher the die.
          Positioned(
              left: f.pos[i].dx - dice[i].r * (1 - f.z[i] / 260),
              top: f.pos[i].dy + dice[i].r * 0.55,
              width: 2 * dice[i].r * (1 - f.z[i] / 260),
              height: dice[i].r * 0.5,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black
                          .withValues(alpha: 0.5 * (1 - f.z[i] / 200))))),
          Positioned(
            left: f.pos[i].dx - dice[i].size / 2,
            top: f.pos[i].dy - dice[i].size / 2 - f.z[i],
            child: Transform.scale(
              scale: 1 + f.z[i] / 380,
              child: Die3D(
                faces: _faces(6, inkPaper),
                facets: _faces(
                    {
                      DieShape.d6: 6,
                      DieShape.d8: 8,
                      DieShape.d12: 12
                    }[dice[i].shape]!,
                    inkPaper),
                accent: edge,
                size: dice[i].size,
                shape: dice[i].shape,
                skin: dice[i].skin,
                rolling: !reduced && f.t[i] < 1,
                still: reduced,
                roll: AlwaysStoppedAnimation(f.t[i]),
              ),
            ),
          ),
        ],
      ]),
    ),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> run(WidgetTester t, String name, List<_Die> dice, Size plate,
      Color bg, Color edge) async {
    final frames = _simulate(dice, plate);
    final key = GlobalKey();
    final times = <double>[];
    final notifier = ValueNotifier<int>(0);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: InkFonts.prose),
      home: Material(
        color: bg,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: ValueListenableBuilder<int>(
                valueListenable: notifier,
                builder: (_, i, __) =>
                    _stage(dice, frames[i], plate, bg, edge, false)),
          ),
        ),
      ),
    ));
    final dir = Directory('$shots/$name')..createSync(recursive: true);
    for (var i = 0; i < frames.length; i++) {
      notifier.value = i;
      final sw = Stopwatch()..start();
      await t.pump(const Duration(milliseconds: 33));
      times.add(sw.elapsedMicroseconds / 1000);
      if (i % 1 == 0) {
        await t.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/f${i.toString().padLeft(3, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
    // Overlap check at the end and the frame cost.
    final last = frames.last;
    for (var i = 0; i < dice.length; i++) {
      for (var j = i + 1; j < dice.length; j++) {
        final d = (last.pos[i] - last.pos[j]).distance;
        expect(d, greaterThanOrEqualTo(dice[i].r + dice[j].r - 1.0),
            reason: '$name dice $i and $j overlap');
      }
    }
    times.sort();
    File('${dir.path}/frame_ms.txt').writeAsStringSync(
        'median ${times[times.length ~/ 2].toStringAsFixed(2)} ms, '
        'p95 ${times[(times.length * 0.95).floor()].toStringAsFixed(2)} ms, '
        'max ${times.last.toStringAsFixed(2)} ms over ${times.length} frames '
        '(build+layout+paint, no raster, this machine)\n');
  }

  testWidgets('dice thrown: ink plate and story fight', skip: shots == null,
      (t) async {
    await t.runAsync(loadAppFonts);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 300);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    dieResetQuality();

    const plate = Size(330, 190);
    await run(
        t,
        'tower',
        [
          _Die(DieShape.d6, 56, inkDieSkinLit, 70, 215, 40, -330, 300, 1),
          _Die(DieShape.d8, 56, inkDieSkin, 170, 225, -10, -380, 280, 2),
          _Die(DieShape.d12, 56, inkDieSkin, 260, 220, -45, -350, 320, 3),
        ],
        plate,
        inkDeep,
        const Color(0xFFB7C0C4));
    dieResetQuality();
    const story = Size(330, 190);
    await run(
        t,
        'story',
        [
          for (var i = 0; i < 5; i++)
            _Die(
                DieShape.d6,
                44,
                dieSkinOf(i.isEven ? 'starter_die' : 'iron_die'),
                45 + i * 60.0,
                215 + (i * 29 % 50),
                (i.isEven ? 1 : -1) * (10 + i * 12.0),
                -250 - (i * 37 % 70),
                280 + i * 15.0,
                i),
        ],
        story,
        const Color(0xFF2A1F17),
        const Color(0xFF6B5A44));
  });
}
