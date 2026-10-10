// The pixel animations (v1.216, see pixel_sprite.dart and
// tool/gen_pixel_fx.py): every strip is there as a row of square frames, a
// strip plays once or loops, reduced motion plays none, the dice land in
// pixel art, a chest bursts open in its tier's light.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/loot_box.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/utils/pixel_icons/pixel_icon.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/pixel_sprite.dart';
import 'package:narrative_data_app/widgets/spoils_chest_dialog.dart';

const _kinds = [
  'strike',
  'ward',
  'bloom',
  'arcs',
  'miasma',
  'shock',
  'drain',
  'fizzle'
];
const _elements = [
  'fire',
  'water',
  'wind',
  'earth',
  'electricity',
  'ice',
  'void',
  'light'
];
const _words = ['cleave', 'pierce', 'growth', 'echo', 'pain', 'steady'];

/// (width, height) of a PNG, off its header.
(int, int) _size(String path) {
  final b = ByteData.sublistView(File(path).readAsBytesSync());
  return (b.getUint32(16), b.getUint32(20));
}

void main() {
  test('every strip is a row of square frames of the right count', () {
    final expected = <String, (int, int)>{
      for (final k in _kinds) 'die_$k': (8, 40),
      for (final e in _elements) 'el_$e': (8, 40),
      for (final w in _words) 'kw_$w': (8, 40),
      'die_surge': (8, 40),
      'die_curse': (8, 40),
      'die_glint': (8, 40),
      'moment_seal': (10, 48),
      'campfire': (6, 18),
      for (final t in ['wooden', 'iron', 'silver', 'gold', 'void'])
        'chest_$t': (8, 48),
    };
    for (final entry in expected.entries) {
      final (w, h) = _size('assets/visuals/pixel_fx/${entry.key}.png');
      expect(h, entry.value.$2, reason: entry.key);
      expect(w, entry.value.$1 * entry.value.$2, reason: entry.key);
    }
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('assets/visuals/pixel_fx/'));
  });

  testWidgets('a strip loads and paints, frame by frame', (tester) async {
    PixelStrips.preload(['die_strike']);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    expect(PixelStrips.ready(['die_strike']), isTrue);
    expect(PixelStrips.of('no_such_strip'), isNull);
    for (final p in [0.0, 0.3, 0.99, 1.0]) {
      await tester.pumpWidget(MaterialApp(
        home: CustomPaint(
          size: const Size(120, 120),
          painter: PixelStripPainter(names: const ['die_strike'], progress: p),
        ),
      ));
      expect(tester.takeException(), isNull, reason: '$p');
    }
  });

  testWidgets('a sprite plays once and says it is done; a loop goes on',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: PixelSprite(
        name: 'moment_seal',
        frames: 10,
        frameSize: 48,
        fps: 10,
        onDone: () => done++,
      ),
    ));
    expect(find.byKey(const ValueKey('pixel_moment_seal')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 700));
    expect(done, 1);

    await tester.pumpWidget(const MaterialApp(
      home: PixelSprite(
          name: 'campfire', frames: 6, frameSize: 18, fps: 6, loop: true),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reduced motion: a loop rests on one frame, a play is skipped',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Column(children: [
          const PixelSprite(
              name: 'campfire', frames: 6, frameSize: 18, loop: true),
          PixelSprite(
              name: 'moment_seal',
              frames: 10,
              frameSize: 48,
              onDone: () => done++),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('pixel_campfire')), findsOneWidget);
    expect(find.byKey(const ValueKey('pixel_moment_seal')), findsNothing);
    expect(done, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a landed die bursts in pixel art once its strips are in',
      (tester) async {
    PixelStrips.preload(['die_strike', 'el_fire', 'kw_cleave', 'die_glint']);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    final roll = AnimationController(
        vsync: const TestVSync(), duration: const Duration(milliseconds: 650));
    addTearDown(roll.dispose);
    Widget die(bool rolling) => MaterialApp(
          home: Center(
            child: Die3D(
              faces: [
                for (final k in FaceKind.values.take(6))
                  DieCubeFace(glyph: Icon(k.icon, size: 20), color: k.color)
              ],
              accent: Colors.red,
              roll: roll,
              rolling: rolling,
              fx: DieFx.strike,
              big: true,
              element: 'Fire',
              keywords: const {},
            ),
          ),
        );
    await tester.pumpWidget(die(true));
    await tester.pumpWidget(die(false));
    await tester.pump(const Duration(milliseconds: 300));
    final paint =
        tester.widget<CustomPaint>(find.byKey(const ValueKey('die_burst')));
    expect(paint.painter, isA<PixelStripPainter>());
    expect((paint.painter! as PixelStripPainter).names,
        ['die_strike', 'el_fire', 'die_glint']);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('die_burst')), findsNothing);
  });

  testWidgets('a chest bursts open in its own light', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpoilsChestDialog(
          result: const LootBoxResult(
            tier: ChestTier.gold,
            roll: 80,
            modifiers: [],
            gold: 20,
            itemIds: [],
            extraSlot: false,
          ),
          items: const {},
          autoOpen: false,
          language: AppLanguage.en,
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('pixel_chest_gold')), findsNothing);
    // The chest's image decodes, then a tap on it opens the chest.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    await tester.tap(find.byType(PixelIcon).first);
    // The lid shakes, then the burst plays.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('pixel_chest_gold')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('pixel_chest_gold')), findsNothing);
  });
}
