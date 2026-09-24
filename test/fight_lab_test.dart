// The Edit Mode fight lab: a test fight changes nothing in the real game
// unless "Keep what happens" is on, and the die picked for the test never
// stays equipped.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_lab_screen.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a test fight is marked as one and keeps the mark through copyWith', () {
    const modifiers = EncounterModifiers(isTest: true);
    expect(modifiers.isDefault, isFalse);
    expect(modifiers.copyWith(chapter: 3).isTest, isTrue);
    expect(EncounterModifiers.none.isTest, isFalse);
  });

  testWidgets('a lab fight is put back afterwards unless kept', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FightLabScreen())));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FightLabScreen)));
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'gold': 100,
        })));
    await _settle(tester);

    // One harbor rat, fought with a die the character doesn't own.
    await tester.tap(find.text('Add an enemy (up to 3)'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'harbor_rat');
    await _settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Harbor Rat'));
    await _settle(tester);
    expect(find.widgetWithText(InputChip, 'Harbor Rat'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await _settle(tester);
    await tester.tap(find.text('Iron Die').last);
    await _settle(tester);

    Future<void> fightAndWin({required int goldWon}) async {
      await tester.tap(find.byKey(const Key('fight_lab_start_fight')));
      await _settle(tester);
      expect(find.byType(FightScreen), findsOneWidget);
      expect(container.read(playerSessionProvider).equippedDiceId, 'iron_die');
      // The fight pays out, then ends in a win.
      await tester
          .runAsync(() => notifier.applyChoiceEffects(goldMod: goldWon));
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pop<bool>(true);
      await _settle(tester);
      expect(find.byType(FightScreen), findsNothing);
    }

    await fightAndWin(goldWon: 500);
    var session = container.read(playerSessionProvider);
    expect(session.gold, 100, reason: 'put back as it was');
    expect(session.equippedDiceId, 'starter_die');
    expect(session.ownedDiceIds, ['starter_die']);
    expect(find.textContaining('Test fight won'), findsOneWidget);

    // Kept: the gold stays; the character's own die comes back.
    await tester.tap(find.text('Keep what happens'));
    await _settle(tester);
    await fightAndWin(goldWon: 500);
    session = container.read(playerSessionProvider);
    expect(session.gold, 600);
    expect(session.equippedDiceId, 'starter_die');
    expect(session.ownedDiceIds, ['starter_die']);
  });
}
