// PICTURES (UX_SHOTS=<folder>): the whole gamble rework: the card BACK as a real back (the
// whole face one cut-paper pattern, no name band, no type, no text. Two versions
// built from the tarot deck's own pieces, each between two real cards, and the
// flip from the back to the revealed face. Not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_styled_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

Widget _skill() => const SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.skill,
        kind: 'Skill',
        name: 'Parry',
        text: 'Block the next blow.',
        nudge: '+1 DEX',
        vignette: 'assets/visuals/tower_cards/skill_fire.png',
        badge: Icon(Icons.shield, size: 16, color: inkBlack),
      ),
    );

Widget _gear() => const SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.gear,
        kind: 'Gear',
        name: 'Ash Cloak',
        text: '+2 armour.',
        vignette: 'assets/visuals/tower_cards/loot_equipment.png',
        badge: Icon(Icons.checkroom, size: 16, color: inkBlack),
      ),
    );

Widget _fit(Widget c, double w) =>
    SizedBox(width: w, height: w * 201 / 122, child: FittedBox(child: c));

Widget _row(List<Widget> cards, double w, {List<String>? caps}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++)
          Column(children: [
            _fit(cards[i], w),
            if (caps != null) ...[
              const SizedBox(height: 4),
              Text(caps[i], style: _p(10.5, inkGrey)),
            ],
          ]),
      ],
    );

Widget _head(String t, String sub) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: _d(17, inkPaper)),
      Text(sub, style: _p(11.5, inkGrey)),
      const SizedBox(height: 8),
    ]);

const _dir = 'assets/visuals/tower_cards';

/// The lattice: diagonal ink hairlines with a red dot at each crossing.
class _Lattice extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = inkOnPaper.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final dot = Paint()..color = inkRed;
    const step = 16.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), line);
    }
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawRect(
            Rect.fromCenter(center: Offset(x, y), width: 2, height: 2), dot);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Concentric diamonds, the same ink on paper, symmetric top to bottom.
class _Diamonds extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final line = Paint()
      ..color = inkOnPaper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 1; i <= 6; i++) {
      final k = i * 0.17;
      final path = Path()
        ..moveTo(c.dx, c.dy - size.height * k * 0.62)
        ..lineTo(c.dx + size.width * k * 0.72, c.dy)
        ..lineTo(c.dx, c.dy + size.height * k * 0.62)
        ..lineTo(c.dx - size.width * k * 0.72, c.dy)
        ..close();
      canvas.drawPath(path, line..color = i.isEven ? inkRed : inkOnPaper);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// The frame shared by both backs: our paper card's rounded shape and border,
/// a hairline inside it, the pattern filling the whole face.
Widget _backShell(Widget pattern, Widget centre) => Container(
      width: 122,
      height: 201,
      decoration: BoxDecoration(
          color: inkPaper,
          border: Border.all(color: inkBlack, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Stack(fit: StackFit.expand, children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: DecoratedBox(
              decoration:
                  BoxDecoration(border: Border.all(color: inkBlack, width: 1)),
              child: ClipRect(child: pattern),
            ),
          ),
          Center(child: centre),
        ]),
      ),
    );

/// A: the watching eye, centred on the repeated pattern.
Widget _backA() => _backShell(
      CustomPaint(painter: _Lattice(), size: const Size(108, 187)),
      Container(
        width: 84,
        height: 58,
        decoration: BoxDecoration(
            color: inkPaper,
            border: Border.all(color: inkBlack, width: 2),
            borderRadius: BorderRadius.circular(6)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset('$_dir/skill_void.png',
              fit: BoxFit.cover, filterQuality: FilterQuality.none),
        ),
      ),
    );

/// B: concentric ink diamonds, the red wax seal at the heart.
Widget _backB() => _backShell(
      CustomPaint(painter: _Diamonds(), size: const Size(108, 187)),
      SizedBox(
        width: 56,
        height: 56,
        child: Image.asset('$_dir/seal_blank.png',
            fit: BoxFit.fill, filterQuality: FilterQuality.none),
      ),
    );

const _outcomes = [
  ('gilded', true),
  ('twin', true),
  ('hoard', true),
  ('bright', true),
  ('dud', false),
  ('wound', false),
  ('spill', false),
  ('hex', false),
];

/// An outcome as a card: the tarot frame, Art's picture, its name and line.
/// The good ones are paper with a gold band, the bad ones ink with a red one.
Widget _outcomeCard(WidgetRef ref, String id, bool good) => SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: good ? TowerCardStyle.skill : TowerCardStyle.die,
        kind: tr(ref, 'tower_kind_gamble'),
        name: tr(ref, 'tower_gamble_$id'),
        text: tr(ref, 'tower_gamble_${id}_line'),
        hue: good ? inkGold : inkRed,
        darkBadge: !good,
        vignette: '$_dir/gamble_$id.png',
        badge: Icon(good ? Icons.auto_awesome : Icons.warning_amber,
            size: 16, color: good ? inkOnPaper : inkPaper),
      ),
    );

Widget _flip(WidgetRef ref, Widget back, double scaleX, bool face) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(scaleX, 1, 1),
      child: face ? _outcomeCard(ref, 'bright', true) : back,
    );

Widget _statCard() => const SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.statPick,
        kind: 'Training',
        name: 'Stat point',
        text: 'Put +1 in a stat of your choice.',
        nudge: '+1 ?',
        vignette: '$_dir/stat_point.png',
        badge: Icon(Icons.add, size: 16, color: inkOnPaper),
      ),
    );

class _Sheet extends ConsumerWidget {
  const _Sheet(this.width);
  final double width;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cw = (width - 64) / 3;
    final fw = (width - 80) / 4;
    return TowerBackdrop(
      floor: 6,
      child: Container(
        color: inkBlack.withValues(alpha: 0.84),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (t, sub, back) in [
              (
                '1A · The back: the eye',
                'The whole face one pattern.',
                _backA()
              ),
              ('1B · The back: the seal', 'Symmetric ink on paper.', _backB()),
            ]) ...[
              _head(t, sub),
              _row([_skill(), back, _gear()], cw),
              const SizedBox(height: 6),
              _row(
                  [
                    _flip(ref, back, 1, false),
                    _flip(ref, back, .5, false),
                    _flip(ref, back, .5, true),
                    _flip(ref, back, 1, true),
                  ],
                  fw,
                  caps: ['back', 'turning', 'turning', 'the face']),
              const SizedBox(height: 12),
            ],
            _head('2 · The eight outcomes, revealed',
                'Art\'s pictures, our tarot frame: paper and gold for the good, ink and red for the bad.'),
            for (var r = 0; r < 2; r++) ...[
              _row([
                for (final (id, good) in _outcomes.skip(r * 4).take(4))
                  _outcomeCard(ref, id, good),
              ], fw),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            _head('3 · The Stat point card',
                'Art\'s cut-paper chart in its verdigris card.'),
            _row([_skill(), _statCard(), _gear()], cw),
          ]),
        ),
      ),
    );
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    testWidgets('gamble flow at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1640);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
              home: Scaffold(body: _Sheet(width))),
        ),
      ));
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/gamble-flow-${width.toInt()}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
