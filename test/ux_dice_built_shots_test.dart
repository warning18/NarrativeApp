// The dice loadout as built (v1.635): the real screen, the die in the middle of
// its ring, a d12, a d20, a d4 and a d8 at 412 and 320 px, from the real code.
// Drawn only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots/dice-built flutter test test/ux_dice_built_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'ux_skills_mock_parts.dart';

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
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
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

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _session(String die) => {
      'raceId': 'human',
      'professionId': 'warrior',
      'characterName': 'Mara',
      'level': 12,
      'ownedDiceIds': [die],
      'equippedDiceId': die,
      'unlockedSkillIds': [
        'warrior_shield_bash',
        'bulwark_stance',
        'power_strike',
        'guard_break',
      ],
      'diceSkillAssignments': {
        die: {
          '0': 'warrior_shield_bash',
          '2': 'bulwark_stance',
          '3': 'power_strike',
        },
      },
    };

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the dice loadout is drawn only with UX_SHOTS', () {});
    return;
  }

  setUp(rootBundle.clear);

  testWidgets('the loadout as built', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    Directory(shots).createSync(recursive: true);

    final frames = <(ProviderContainer, double, String)>[];
    for (final (die, width, caption) in const [
      ('tearglass_die', 412.0, 'd12 · Tear-glass, 412 px'),
      ('gambler_die', 412.0, 'd20 · 412 px'),
      ('berserker_die', 320.0, 'd4 · 320 px'),
      ('flame_die', 320.0, 'd8 · Ember, 320 px'),
    ]) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(playerSessionProvider);
      await _settle(tester);
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson(_session(die))));
      await _settle(tester, n: 3);
      frames.add((container, width, caption));
    }

    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    const height = 900.0;
    var total = 48.0 + 24 * frames.length;
    for (final f in frames) {
      total += f.$2;
    }
    tester.view.physicalSize = Size(total, height + 110);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Material(
          color: const Color(0xFF17151B),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in frames) ...[
                  Column(children: [
                    UncontrolledProviderScope(
                      container: f.$1,
                      child: Phone(
                          width: f.$2,
                          height: height,
                          bare: true,
                          child: const DiceLoadoutScreen()),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: f.$2,
                      child: Text(f.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Spectral',
                              fontSize: 15,
                              color: Color(0xFFEDE6DC))),
                    ),
                  ]),
                  const SizedBox(width: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
    await _settle(tester, n: 5);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/dice-loadout-built.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
