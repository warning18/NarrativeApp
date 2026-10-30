// The Skills tab's sky as built (v1.619): the real screen at 412 and 320 px,
// level 1 and mid game, from the real code. Drawn only with UX_SHOTS (a
// folder):
//   UX_SHOTS=docs/ux-shots/star-chart flutter test test/ux_star_chart_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';

import 'ux_skills_mock_parts.dart';
import 'support/fonts.dart';

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _levelOne = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
};

const _midGame = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'level': 12,
  'skillEssence': 2600,
  'pendingOffers': [
    {'source': 'level'},
  ],
  'unlockedSkillIds': [
    'warrior_shield_bash',
    'bulwark_stance',
    'power_strike',
    'guard_break',
    'rallying_shout',
    'human_resolve',
  ],
  'skillTiers': {
    'warrior_shield_bash': 3,
    'power_strike': 2,
    'bulwark_stance': 1,
  },
  'builtHouseIds': ['skillwright'],
  'politics': {
    'standings': {'compact': 14},
  },
};

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the skills mock is drawn only with UX_SHOTS', () {});
    return;
  }

  setUp(rootBundle.clear);

  Future<ProviderContainer> scene(
      WidgetTester tester, Map<String, dynamic> session,
      {AppLanguage language = AppLanguage.en}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(playerSessionProvider);
    await _settle(tester);
    await tester.runAsync(() =>
        container.read(appLanguageProvider.notifier).setLanguage(language));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          ...session,
          'flags': ['feat_clans', 'feat_skills'],
        })));
    await _settle(tester, n: 3);
    return container;
  }

  /// [frames] side by side on a dark board, each with a caption; written to
  /// [file].
  Future<void> board(WidgetTester tester, String file,
      List<(ProviderContainer, double, String, Widget)> frames,
      {double height = 780, Widget? notes, bool bare = false}) async {
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    var width = 48.0 + 24 * frames.length;
    for (final f in frames) {
      width += f.$2;
    }
    if (notes != null) width += 300;
    tester.view.physicalSize = Size(width, height + 110);
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
                          width: f.$2, height: height, bare: bare, child: f.$4),
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
                if (notes != null) notes,
              ],
            ),
          ),
        ),
      ),
    ));
    await _settle(tester, n: 4);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<(ProviderContainer, ProviderContainer)> scenes(
      WidgetTester tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final one = await scene(tester, _levelOne);
    final mid = await scene(tester, _midGame);
    return (one, mid);
  }

  testWidgets('the sky as built', (tester) async {
    final (one, mid) = await scenes(tester);
    const real = SkillsScreen();
    final mage = await scene(
        tester,
        {
          'raceId': 'elf',
          'professionId': 'mage',
          'characterName': 'Mara',
          'unlockedSkillIds': ['mage_fireball'],
        },
        language: AppLanguage.fr);
    await board(
      tester,
      'star-chart-built.png',
      [
        (one, 412.0, 'Level 1 · 412 px', real),
        (mid, 412.0, 'Mid game · 412 px', real),
        (one, 320.0, 'Level 1 · 320 px', real),
        (mid, 320.0, 'Mid game · 320 px', real),
        (mage, 320.0, 'Mage, five constellations · 320 px · French', real),
      ],
      bare: true,
      height: 900,
    );
    expect(tester.takeException(), isNull);
  });
}
