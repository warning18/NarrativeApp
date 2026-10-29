// The dice that are not cubes: the shape for every size, how long each rolls,
// the clan's banner, and a skin on any shape. Drawn only with UX_SHOTS (a
// folder) for the family picture:
//   UX_SHOTS=docs/ux-shots/dice-built flutter test test/poly_die_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_art.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    ('Spectral', ['Spectral-Regular.ttf', 'Spectral-Medium.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

final Map<String, dynamic> _dice =
    jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('every die size has its shape, a d7 reads as the next size up', () {
    expect([2, 4, 6, 8, 10, 12, 20].map(dieShapeOf), [
      DieShape.coin,
      DieShape.d4,
      DieShape.d6,
      DieShape.d8,
      DieShape.d10,
      DieShape.d12,
      DieShape.d20,
    ]);
    expect(dieShapeOf(7), DieShape.d8);
    expect(dieShapeOf(3), DieShape.d4);
    expect(dieShapeOf(16), DieShape.d20);
  });

  test('larger dice roll longer, a d20 clearly longer than a d4', () {
    var last = Duration.zero;
    for (final n in [2, 4, 6, 8, 10, 12, 20]) {
      expect(dieRollDuration(n), greaterThanOrEqualTo(last), reason: 'd$n');
      last = dieRollDuration(n);
    }
    expect(dieRollDuration(20).inMilliseconds,
        greaterThan(2 * dieRollDuration(4).inMilliseconds));
  });

  testWidgets('a die at rest shows its number; a clan die wears a banner',
      (tester) async {
    for (final shape in DieShape.values) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: PolyDie(
            shape: shape,
            size: 80,
            label: '7',
            skin: dieSkinOf('flame_die'),
            clan: shape == DieShape.d8
                ? const DieClan('dominion', Color(0xFF2F62B5))
                : null,
          ),
        ),
      ));
      expect(find.byKey(const ValueKey('poly_die')), findsOneWidget,
          reason: shape.name);
      expect(tester.takeException(), isNull, reason: shape.name);
    }
  });

  testWidgets('a roll turns and squeezes the die, then settles on its number',
      (tester) async {
    final host = GlobalKey<_RollerState>();
    await tester.pumpWidget(MaterialApp(home: _Roller(key: host)));
    host.currentState!.controller.forward();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(host.currentState!.controller.isCompleted, isFalse);
    await tester.pump(dieRollDuration(20) + const Duration(milliseconds: 100));
    expect(host.currentState!.controller.isCompleted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a clan\'s gift die wears its banner, a plain one does not',
      (tester) async {
    const blue = Color(0xFF2F62B5);
    Future<Color> bannerPixel(DieClan? clan) async {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: PolyDie(
                shape: DieShape.d8,
                size: 100,
                label: '5',
                skin: boneSkin,
                clan: clan),
          ),
        ),
      ));
      return (await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = (await image.toByteData())!;
        // The flag's body, a little right of the upper right corner.
        const x = 80;
        const y = 8;
        final at = (y * image.width + x) * 4;
        return Color.fromARGB(bytes.getUint8(at + 3), bytes.getUint8(at),
            bytes.getUint8(at + 1), bytes.getUint8(at + 2));
      }))!;
    }

    expect(await bannerPixel(const DieClan('dominion', blue)), blue);
    expect((await bannerPixel(null)).a, 0);
  });

  testWidgets('the fight\'s die takes any shape and bursts on landing',
      (tester) async {
    for (final shape in DieShape.values) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: Die3D(
            faces: [
              for (var i = 0; i < 6; i++)
                DieCubeFace(glyph: Text('$i'), color: Colors.primaries[i]),
            ],
            accent: Colors.amber,
            size: 46,
            shape: shape,
            skin: dieSkinOf('tearglass_die'),
            fx: DieFx.strike,
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PolyDie),
          shape == DieShape.d6 ? findsNothing : findsOneWidget,
          reason: shape.name);
      expect(tester.takeException(), isNull, reason: shape.name);
    }
  });

  testWidgets('every die with art paints in its shape, at both sizes',
      (tester) async {
    for (final id in ['starter_die', ...dieArtNotes.keys]) {
      for (final size in [76.0, 34.0]) {
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: PolyDie(
              shape: dieShapeOf((_dice[id]['faces'] as List).length),
              size: size,
              dieId: id,
              label: '3',
              skin: dieSkinOf(id),
            ),
          ),
        ));
        expect(tester.takeException(), isNull, reason: '$id at $size');
      }
    }
    expect(dieHasArt('starter_die'), isFalse);
    expect(dieHasArt('tearglass_die'), isTrue);
    // Every die of dice.json has art, bar the plain first one.
    final ids = _dice.keys;
    final missing = [
      for (final id in ids)
        if (!dieHasArt(id)) id,
    ];
    expect(missing, ['starter_die']);
  });

  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the family, drawn (UX_SHOTS)', (tester) async {
    if (shots != null && shots.isNotEmpty) await _loadFonts();
    tester.view.physicalSize = const Size(900, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Widget cell(DieShape shape, String skin, String label,
            {double size = 84, DieClan? clan}) =>
        Padding(
          padding: const EdgeInsets.all(8),
          child: PolyDie(
              shape: shape,
              size: size,
              label: label,
              skin: dieSkinOf(skin),
              clan: clan),
        );
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFF15131A),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                cell(DieShape.d4, 'starter_die', '3'),
                cell(DieShape.d6, 'starter_die', '5'),
                cell(DieShape.d8, 'starter_die', '7'),
                cell(DieShape.d10, 'starter_die', '9'),
                cell(DieShape.d12, 'starter_die', '11'),
                cell(DieShape.d20, 'starter_die', '17'),
                cell(DieShape.coin, 'starter_die', ''),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                cell(DieShape.d8, 'pilgrim_die', '7'),
                cell(DieShape.d12, 'tobin_die', '11'),
                cell(DieShape.d20, 'tempest_die', '17'),
                cell(DieShape.d8, 'shadow_die', '7'),
                cell(DieShape.d12, 'tearglass_die', '11'),
                cell(DieShape.d12, 'flame_die', '11'),
                cell(DieShape.d6, 'starter_die', '5',
                    clan: const DieClan('dominion', Color(0xFF2F62B5))),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final s in DieShape.values)
                  cell(s, 'starter_die', s == DieShape.coin ? '' : '7',
                      size: 34),
              ]),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();
    if (shots == null || shots.isEmpty) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(shots).createSync(recursive: true);
      File('$shots/dice-family-built.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('the sheet of the 31 dice, drawn (UX_SHOTS)', (tester) async {
    if (shots == null || shots.isEmpty) return;
    await _loadFonts();
    tester.view.physicalSize = const Size(1300, 1250);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final bySize = <int, List<String>>{};
    for (final e in _dice.entries) {
      bySize
          .putIfAbsent((e.value['faces'] as List).length, () => [])
          .add(e.key);
    }
    Widget cell(String id) => Container(
          width: 150,
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3A3642)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              PolyDie(
                  shape: dieShapeOf((_dice[id]['faces'] as List).length),
                  size: 76,
                  dieId: id,
                  label: '4',
                  skin: dieSkinOf(id)),
              const SizedBox(width: 14),
              PolyDie(
                  shape: dieShapeOf((_dice[id]['faces'] as List).length),
                  size: 34,
                  dieId: id,
                  label: '4',
                  skin: dieSkinOf(id)),
            ]),
            const SizedBox(height: 10),
            Text(id.replaceAll('_die', ''),
                style: const TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 13,
                    color: Color(0xFFEDE6DC))),
            Text(dieArtNotes[id] ?? 'plain',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 10,
                    color: Color(0xFF9A93A6))),
          ]),
        );
    await tester.pumpWidget(MaterialApp(
      home: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFF17151B),
            padding: const EdgeInsets.all(12),
            child: Wrap(children: [
              for (final n in bySize.keys.toList()..sort())
                for (final id in bySize[n]!) cell(id),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(shots).createSync(recursive: true);
      File('$shots/dice-sheet-built.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

class _Roller extends StatefulWidget {
  const _Roller({super.key});

  @override
  State<_Roller> createState() => _RollerState();
}

class _RollerState extends State<_Roller> with SingleTickerProviderStateMixin {
  late final controller =
      AnimationController(vsync: this, duration: dieRollDuration(20));

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: PolyDie(
            shape: DieShape.d20,
            size: 80,
            label: '17',
            roll: controller,
            skin: boneSkin),
      );
}
