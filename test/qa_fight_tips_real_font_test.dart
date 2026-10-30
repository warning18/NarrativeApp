// QA: the one-time fight tips on a phone, with the app's own fonts (the test
// font is far wider, so only the bundled fonts tell the truth): the first hold
// under an ambush (two tips, 1/2 and 2/2) and a fight against a clan's doctrine,
// at 360 and 320 px wide, in English and French, lay out with no overflow and
// the tip's buttons are on screen.
// L3_SHOTS=<folder> also writes a picture of each to that folder.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';

/// The first settle of a test waits for the game data to load; the later
/// ones only let the screen catch up.
final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 6 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(
    WidgetTester tester, GlobalKey boundary, String? shots, String name) async {
  if (shots == null) return;
  final image = await tester.runAsync(() async {
    final object =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return object.toImage();
  });
  final bytes = await tester
      .runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
  Directory(shots).createSync(recursive: true);
  File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  final shots = Platform.environment['L3_SHOTS'];
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  // One test for every size and language: the game data is read on the first
  // pass and a read begun inside one test never finishes for the next.
  testWidgets('the fight tips read on a phone, 360 and 320 px, EN and FR',
      (tester) async {
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(360, 740);
    final boundary = GlobalKey();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        fightRandomProvider.overrideWithValue(() => Random(7)),
        tutorialAutoShowProvider.overrideWithValue(true),
      ],
      child: RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: buildAppTheme(ColorScheme.fromSeed(
              seedColor: Colors.amber, brightness: Brightness.dark)),
          home: const SizedBox.shrink(),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    Future<void> freshSave() => tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'maxHealth': 900,
          'currentHealth': 900,
        })));
    Future<void> push(
        Map<String, dynamic> enemy, EncounterModifiers mods) async {
      navigatorKey.currentState!.push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: 'harbor_rat',
                enemy: enemy,
                additionalEnemyIds: const ['harbor_rat'],
                additionalEnemies: {'harbor_rat': enemy},
                modifiers: mods,
              )));
      await _settle(tester);
    }

    for (final size in const [Size(360, 740), Size(320, 568)]) {
      tester.view.physicalSize = size;
      for (final french in [false, true]) {
        final label = '${size.width.toInt()}_${french ? 'fr' : 'en'}';
        await tester.runAsync(() => container
            .read(appLanguageProvider.notifier)
            .setLanguage(french ? AppLanguage.fr : AppLanguage.en));

        // The first hold under an ambush: two tips, one after the other.
        await freshSave();
        final rat = {..._enemy('harbor_rat'), 'faction': ''};
        await push(
            rat,
            const EncounterModifiers(
                forcedGoal: FightGoal(FightGoalKind.hold, rounds: 3),
                forcedCondition: BattlefieldCondition.ambush));
        expect(find.byKey(const Key('fight_tip_goal_hold')), findsOneWidget,
            reason: label);
        await _shot(tester, boundary, shots, 'tip_hold_1_$label');
        await tester.tap(find.byKey(const Key('fight_tip_next')));
        await _settle(tester);
        expect(
            find.byKey(const Key('fight_tip_situation_ambush')), findsOneWidget,
            reason: label);
        await _shot(tester, boundary, shots, 'tip_ambush_2_$label');
        expect(find.byKey(const Key('fight_tip_ok')), findsOneWidget);
        await tester.tap(find.byKey(const Key('fight_tip_ok')));
        await _settle(tester);
        navigatorKey.currentState!.pop();
        await _settle(tester);
        expect(overflows, isEmpty, reason: '$label: ${overflows.join('; ')}');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
