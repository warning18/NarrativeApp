// The first-launch intro, version B (a proposal, nothing of it is in the app):
// one long drop of the camera, from the ash sky over Alster to the player's
// own table on Tallow Street, where the old bone die is thrown. Each frame
// pushes into the next; the die is the through-line (the story's first scene
// is the player rolling it). Drawn from the game's own widgets. With
// UX_SHOTS (a folder) set it saves intro-storyboard-b.png; UX_LAST is the
// picture of the real "choose your race and profession" screen (see
// ux_intro_mock_test.dart for how it is taken).
//   UX_SHOTS=docs/ux-shots UX_LAST=<png> flutter test test/ux_intro_b_mock_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/side_view/side_sprite.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(
          ByteData.view(File('assets/fonts/$f').readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

const _bg = Color(0xFF0B0A0D);
const _cream = Color(0xFFEDE3C8);
const _ash = Color(0xFF9A93A6);
const _gold = Color(0xFFE2B890);
const _frameW = 210.0;
const _frameH = 373.0;

TextStyle _px(double size, {Color color = _cream, FontWeight? w}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, color: color, fontWeight: w);
TextStyle _serif(double size,
        {Color color = _cream, FontStyle style = FontStyle.normal}) =>
    TextStyle(
        fontFamily: 'Spectral', fontSize: size, color: color, fontStyle: style);

/// Narrative's set A (Grim), English: each line types itself out over its
/// frame, in the story's own text.
const _lines = {
  1: 'Alster at dusk. The ash had already begun to fall.',
  2: 'The bell rang for the Inquisition. Nobody on Tallow Street looked up.',
  3: 'Every clan wanted the city. None of them wanted you in it.',
  4: 'Tonight it burns. First, decide who you are.',
};

class _LineSlot extends StatelessWidget {
  const _LineSlot(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xDD000000)])),
          child: Text(text,
              textAlign: TextAlign.center,
              style: _serif(13.5, style: FontStyle.italic)),
        ),
      );
}

/// The street scene, the camera pushed in on [focus] by [zoom].
Widget _crop(String kind, String name, Alignment focus, double zoom,
        {DayPhase phase = DayPhase.dusk}) =>
    ClipRect(
      child: Transform.scale(
        scale: zoom,
        alignment: focus,
        child: StreetViewScene(
            kind: kind,
            name: name,
            phase: phase,
            sky: WeatherKind.ash,
            party: false),
      ),
    );

class _Bell extends CustomPainter {
  const _Bell(this.swing);
  final double swing;
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 40;
    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.rotate(swing);
    final bronze = Paint()..color = const Color(0xFFB9803A);
    final dark = Paint()..color = const Color(0xFF6B4520);
    final lit = Paint()..color = const Color(0xFFE0B060);
    void px(Paint p, double x, double y, double w, double h) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), p);
    px(dark, -1, 0, 2, 5);
    px(bronze, -5, 5, 10, 3);
    px(bronze, -7, 8, 14, 5);
    px(bronze, -9, 13, 18, 6);
    px(lit, -7, 8, 3, 9);
    px(dark, -10, 19, 20, 2);
    px(dark, -1.5, 21, 3, 3);
    canvas.restore();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.8;
    for (var i = 1; i <= 3; i++) {
      ring.color = _cream.withValues(alpha: 0.5 / i);
      canvas.drawCircle(Offset(size.width / 2, 15 * u), (12 + i * 7) * u, ring);
    }
  }

  @override
  bool shouldRepaint(_Bell old) => old.swing != swing;
}

/// A lit window in a dark wall, the hero at the table inside: the hero's
/// own sprite, standing frame, as a silhouette against the lamp.
class _Window extends CustomPainter {
  const _Window();
  @override
  void paint(Canvas canvas, Size size) {
    // The wall: dark brick courses.
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF1B1613));
    final brick = Paint()..color = const Color(0xFF241C17);
    for (var y = 0.0; y < size.height; y += 18) {
      for (var x = ((y ~/ 18) % 2) * 20.0 - 20; x < size.width; x += 40) {
        canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, 38, 16), brick);
      }
    }
    final win = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.46),
        width: size.width * 0.74,
        height: size.height * 0.5);
    // The lamp's glow spilling out.
    canvas.drawRect(
        win.inflate(26),
        Paint()
          ..shader = ui.Gradient.radial(win.center, win.width * 0.9,
              [const Color(0x66F0B050), const Color(0x00F0B050)]));
    canvas.drawRect(
        win,
        Paint()
          ..shader = ui.Gradient.linear(win.topCenter, win.bottomCenter,
              [const Color(0xFFF2C070), const Color(0xFFC77A30)]));
    // The hero, inside, a silhouette.
    canvas.save();
    canvas.clipRect(win);
    final u = win.width / 36;
    canvas.translate(win.left, win.top);
    canvas.saveLayer(
        Offset.zero & win.size,
        Paint()
          ..colorFilter =
              const ColorFilter.mode(Color(0xFF1A0F08), BlendMode.srcATop));
    SideSprites.paint(canvas, u, 18, 34, 0, moving: false);
    canvas.restore();
    canvas.restore();
    // The sash and the sill.
    final frame = Paint()..color = const Color(0xFF3A2A1E);
    canvas.drawRect(
        Rect.fromLTWH(win.left, win.center.dy - 3, win.width, 6), frame);
    canvas.drawRect(
        Rect.fromLTWH(win.center.dx - 3, win.top, 6, win.height), frame);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFF3A2A1E);
    canvas.drawRect(win, edge);
    canvas.drawRect(
        Rect.fromLTWH(win.left - 10, win.bottom + 4, win.width + 20, 8),
        Paint()..color = const Color(0xFF4A382A));
  }

  @override
  bool shouldRepaint(_Window old) => false;
}

/// Planks, and a candle's pool of light from the top.
class _Table extends CustomPainter {
  const _Table();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF2A1D14));
    final plank = Paint()..color = const Color(0xFF33241A);
    for (var x = 0.0; x < size.width; x += 38) {
      canvas.drawRect(Rect.fromLTWH(x + 2, 0, 34, size.height), plank);
    }
    final seam = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 61) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 3), seam);
    }
    final c = Offset(size.width * 0.5, size.height * 0.42);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(c, size.width * 0.85,
              [const Color(0x00000000), const Color(0xDD000000)], [0.25, 1]));
    canvas.drawCircle(
        c,
        size.width * 0.55,
        Paint()
          ..shader = ui.Gradient.radial(c, size.width * 0.55,
              [const Color(0x55F2B860), const Color(0x00F2B860)]));
  }

  @override
  bool shouldRepaint(_Table old) => false;
}

Widget _die(double size,
        {Animation<double>? roll, bool rolling = false, bool still = true}) =>
    Die3D(
      faces: [
        for (var i = 1; i <= 6; i++)
          DieCubeFace(
              glyph: Text('$i',
                  style: _px(size * 0.45,
                      color: const Color(0xFF3A2A1E), w: FontWeight.w600)),
              color: const Color(0xFFE8DDC0)),
      ],
      accent: _gold,
      size: size,
      skin: boneSkin,
      roll: roll,
      rolling: rolling,
      still: still,
    );

class _Beat {
  const _Beat(this.time, this.title, this.how, this.move, this.scene,
      {this.line, this.isNew = ''});
  final String time;
  final String title;
  final String how;
  final String move;
  final Widget scene;
  final int? line;
  final String isNew;
}

Widget _frame(int n, _Beat b) => SizedBox(
      width: _frameW,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: _frameW,
          height: _frameH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: Colors.black, child: b.scene),
              if (b.line != null) _LineSlot(_lines[b.line!]!),
              Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: const Color(0xCC000000),
                    child: Text('$n', style: _px(13, color: _gold)),
                  )),
              if (b.move.isNotEmpty)
                Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: const Color(0xCC000000),
                      child: Text(b.move, style: _px(11, color: _gold)),
                    )),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text(b.time, style: _px(13, color: _gold, w: FontWeight.w600)),
        Text(b.title, style: _serif(12.5)),
        const SizedBox(height: 2),
        Text(b.how, style: _serif(10.5, color: _ash)),
        if (b.isNew.isNotEmpty)
          Text('new: ${b.isNew}',
              style: _px(10.5, color: const Color(0xFFE08A6A))),
      ]),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final last = Platform.environment['UX_LAST'];
  if (shots == null) {
    test('intro storyboard B is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('storyboard B', (tester) async {
    await tester.runAsync(_loadFonts);
    await tester.runAsync(SideSprites.preload);
    ui.Image? lastImage;
    if (last != null && File(last).existsSync()) {
      lastImage = await tester.runAsync(() async {
        final codec =
            await ui.instantiateImageCodec(File(last).readAsBytesSync());
        return (await codec.getNextFrame()).image;
      });
    }
    final clanIds = [
      for (final id in clanBannerFactionIds)
        if (clanBannerId(id) != null) id,
    ];

    // Each piece of the Shroud as the character screen draws it, lying on the
    // table: dark, but the heirloom, which the hero already has.
    Widget scraps() => Stack(children: [
          for (final (i, id) in shroudPieceIds.indexed)
            Positioned(
              left: 18.0 + (i % 3) * 62 + (i.isEven ? 0 : 8),
              top: 70.0 + (i ~/ 3) * 140 + (i % 3 == 1 ? 14 : 0),
              child: Transform.rotate(
                angle: (i - 2.5) * 0.28,
                child: Opacity(
                  opacity: 0.92,
                  child: SizedBox(
                      width: 40,
                      height: 80,
                      child: FittedBox(
                          child: PixelBanner(id: id, scale: 1, found: i == 0))),
                ),
              ),
            ),
        ]);

    final beats = <_Beat>[
      _Beat(
          '0.0 – 3.0 s',
          'The ash sky',
          'Fades up from black on the sky over Alster: the roofs, the chapel’s cross, the ash. Line 1.',
          'drop',
          Stack(fit: StackFit.expand, children: [
            _crop('temple', 'The Inquisition chapel', const Alignment(0, -1),
                1.9),
            Align(
                alignment: Alignment.topCenter,
                child: Container(
                    height: 150,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xDD000000), Color(0x00000000)])))),
          ]),
          line: 1),
      _Beat(
          '3.0 – 6.0 s',
          'The bell',
          'The camera drops to the bell in its tower; it swings, rings spread, the ash shivers. Just a bell. Line 2.',
          'drop',
          Stack(fit: StackFit.expand, children: [
            _crop('temple', 'The Inquisition chapel', const Alignment(0, -0.7),
                1.9),
            Align(
                alignment: const Alignment(0, -0.45),
                child: SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(painter: const _Bell(0.28)))),
          ]),
          line: 2,
          isNew: 'a pixel bell and its rings (about 30 lines)'),
      _Beat(
          '6.0 – 8.0 s',
          'The rooftops and their flags',
          'Over the roofs, the thirteen clans’ flags rise one after another on their poles. The camera slides right. Line 3.',
          'pan right',
          Stack(fit: StackFit.expand, children: [
            _crop('warehouse', 'The quay', const Alignment(0.6, -1), 1.7),
            Align(
              alignment: const Alignment(0, -0.1),
              child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (i, id) in clanIds.indexed)
                      Padding(
                          padding: EdgeInsets.only(top: i.isEven ? 0 : 16),
                          child: ClanFlag(factionId: id, height: 52)),
                  ]),
            ),
          ]),
          line: 3),
      _Beat(
          '8.0 – 9.0 s',
          'Tallow Street',
          'The drop ends at one house on Tallow Street, a lamp in its window (the hero’s own).',
          'push in',
          _crop('house', 'Tallow Street, our house', const Alignment(-0.1, 0.1),
              1.8)),
      _Beat(
          '9.0 – 10.5 s',
          'The window',
          'Closer: the lit window, the hero at the table inside, a silhouette against the lamp.',
          'push in',
          const CustomPaint(painter: _Window()),
          isNew: 'the window and its glow (one painter)'),
      _Beat(
          '10.5 – 12.0 s',
          'The table',
          'Through the glass: the table in candlelight; the old bone die; the six torn pieces of the Shroud, the heirloom faintly lit.',
          'push in',
          Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: _Table()),
            scraps(),
            Align(alignment: const Alignment(0.05, 0.12), child: _die(72)),
          ]),
          isNew: 'the table (planks and candle light, one painter)'),
      _Beat(
          '12.0 – 13.5 s',
          'The throw, and the title',
          'The die is thrown and tumbles over the scraps; the title comes up under it in the pixel face.',
          'hold',
          Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: _Table()),
            Align(
                alignment: const Alignment(0, -0.35),
                child: _die(84,
                    roll: const AlwaysStoppedAnimation(0.55),
                    rolling: true,
                    still: false)),
            Align(
                alignment: const Alignment(0, 0.55),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('The Grey Shroud',
                      textAlign: TextAlign.center,
                      style: _px(27, w: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                          'A tale of dice, debts and a shroud that should not exist',
                          textAlign: TextAlign.center,
                          style: _serif(12,
                              color: _ash, style: FontStyle.italic))),
                ])),
          ])),
      _Beat(
          '13.5 – 15.0 s',
          'It lands on the choice',
          'The die comes to rest on the real “choose your race and profession” screen: that screen is its table. Line 4 holds. (The still frame with reduced motion is frame 7.)',
          'cut',
          Stack(fit: StackFit.expand, children: [
            lastImage == null
                ? const ColoredBox(color: Color(0xFFF3EAD7))
                : RawImage(
                    image: lastImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter),
            Align(alignment: const Alignment(0.85, 0.7), child: _die(44)),
          ]),
          line: 4),
    ];

    const spans = [3.0, 3.0, 2.0, 1.0, 1.5, 1.5, 1.5, 1.5];
    final total = spans.fold<double>(0, (a, b) => a + b);
    const boardW = 4 * (_frameW + 16) + 16;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(boardW, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget chip(String t, {Color c = _cream}) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(t, style: _serif(12, color: c)));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: boardW,
            color: _bg,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Intro · version B: one long drop (${total.toStringAsFixed(0)} s)',
                  style: _px(22, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'The camera falls from the ash sky to the player’s own table on Tallow Street, each frame pushing into the next, and the old bone die is thrown: the die is the through-line, as in the story’s first scene. Same lines (set A), same rules: plays once, a tap skips, reduced motion shows frame 7, replayable from Settings.',
                  style: _serif(12.5, color: _ash)),
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 14, children: [
                for (var i = 0; i < beats.length; i++) _frame(i + 1, beats[i]),
              ]),
              const SizedBox(height: 12),
              Text('Timing', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: Row(children: [
                  for (var i = 0; i < spans.length; i++)
                    Expanded(
                      flex: (spans[i] * 10).round(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        color: Color.lerp(
                            const Color(0xFF3A3642), _gold, i / spans.length),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: _px(13, color: Colors.black)),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                  '0 s · ${total.toStringAsFixed(0)} s — lines at 0.3, 3.3, 6.3 and 13.8 s; a low bell on frame 2 and the die’s clatter on frame 7 are the optional sounds',
                  style: _serif(11.5, color: _ash)),
              const SizedBox(height: 16),
              Text('What it is made of', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              chip(
                  'Reused as it is: the street-view kit at dusk with ash, pushed in (frames 1 – 4), the clans’ flags (3), the hero’s sprite as a silhouette (5), the six Shroud pieces as the character screen draws them (6), the bone die (6, 7, 8: Die3D with its bone skin, still or tumbling), the title’s words (7), the story’s typewriter for the lines, the real Race & Profession screen (8), the reduced-motion check.'),
              chip(
                  'New: the bell and its rings (2), the lit window (5) and the candlelit table (6), three small painters; one intro screen with a camera that pushes each frame into the next (a scale and a dissolve), tap to skip; a “seen” flag and a Replay row in Settings; Narrative’s four lines.',
                  c: const Color(0xFFE08A6A)),
              chip(
                  'Build: about a day and a half, one PR, about 450 lines and a test (the beats in order, a tap skips, reduced motion shows frame 7, the flag is set once). No new art files. The lines need no rewording; line 2 hands the camera to Tallow Street.',
                  c: _ash),
            ]),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/intro-storyboard-b.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(math.max(1, total), greaterThan(0));
  });
}
