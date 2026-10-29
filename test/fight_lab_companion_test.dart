// The Edit Mode fight lab can add any companion to a test fight (v1.228):
// they join the party, recruited for the test when the story has not
// recruited them, and are put back afterwards, even with "Keep what
// happens" on (a companion the story never recruited does not stay).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_lab_screen.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a companion added in the lab fights, then is put back',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    usePhone(tester, const Size(420, 2400));

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
        })));
    await _settle(tester);
    expect(container.read(playerSessionProvider).recruitedAllies, isEmpty);

    // One harbor rat, and Maren beside the character.
    await tester.tap(find.text('Add an enemy (up to 3)'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'harbor_rat');
    await _settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Harbor Rat'));
    await _settle(tester);
    await tester
        .ensureVisible(find.byKey(const Key('fight_lab_add_companion')));
    await tester.tap(find.byKey(const Key('fight_lab_add_companion')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('fight_lab_pick_maren')));
    await _settle(tester);
    expect(find.byKey(const Key('fight_lab_companion_maren')), findsOneWidget);

    Future<void> fight() async {
      await tester
          .ensureVisible(find.byKey(const Key('fight_lab_start_fight')));
      await tester.tap(find.byKey(const Key('fight_lab_start_fight')));
      await _settle(tester);
      expect(find.byType(FightScreen), findsOneWidget);
      // In the fight Maren is in the party, with her signature die's skills.
      final during = container.read(playerSessionProvider);
      expect(during.activeAllyIds, ['maren']);
      final maren =
          during.recruitedAllies.singleWhere((a) => a.companionId == 'maren');
      expect(maren.unlockedSkillIds, isNotEmpty);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pop<bool>(true);
      await _settle(tester);
      expect(find.byType(FightScreen), findsNothing);
    }

    // Put back as it was.
    await fight();
    var session = container.read(playerSessionProvider);
    expect(session.recruitedAllies, isEmpty);
    expect(session.activeAllyIds, isEmpty);

    // Even when what happens is kept: she was never recruited by the story.
    await tester.ensureVisible(find.text('Keep what happens'));
    await tester.tap(find.text('Keep what happens'));
    await _settle(tester);
    await fight();
    session = container.read(playerSessionProvider);
    expect(session.recruitedAllies, isEmpty);
    expect(session.activeAllyIds, isEmpty);

    // The chip takes her off the test again.
    await tester
        .ensureVisible(find.byKey(const Key('fight_lab_companion_maren')));
    // The chip's delete button: its icon differs between Flutter versions.
    tester
        .widget<InputChip>(find.byKey(const Key('fight_lab_companion_maren')))
        .onDeleted!();
    await _settle(tester);
    expect(find.byKey(const Key('fight_lab_companion_maren')), findsNothing);
  });
}
