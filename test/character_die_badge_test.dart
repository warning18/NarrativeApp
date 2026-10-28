// The die in hand on the Character tab's portrait (v1.605): a badge on the
// portrait's corner in the die's own look, +N for the other dice in the bag,
// one tap to the dice screen on that die; hidden while the dice are closed.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/feature_unlocks.dart'
    show featureLadderFlag;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';

Future<void> _settle(WidgetTester tester, {int n = 6}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, Map<String, dynamic> save,
    {double width = 412}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    child: const MaterialApp(
        home: Scaffold(body: CharacterScreen(embedded: true))),
  ));
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(playerSessionProvider);
  await _settle(tester, n: 4);
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(save)));
  await _settle(tester);
}

const _save = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'flags': [featureLadderFlag, 'feat_inventory'],
  'ownedDiceIds': ['starter_die', 'iron_die', 'bulwark_die'],
  'equippedDiceId': 'starter_die',
};

void main() {
  setUp(rootBundle.clear);

  testWidgets('the die in hand sits on the portrait, with the others counted',
      (tester) async {
    await _open(tester, _save);
    expect(find.byKey(const Key('character_die_badge')), findsOneWidget);
    expect(find.byKey(const Key('character_die_badge_more')), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    // On the portrait's lower right corner, over its edge.
    final badge = tester.getRect(find.byKey(const Key('character_die_badge')));
    final portrait = tester.getRect(find.text('M').first);
    expect(badge.center.dx, greaterThan(portrait.center.dx));
    expect(badge.center.dy, greaterThan(portrait.center.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap opens the dice screen on that die', (tester) async {
    await _open(tester, _save);
    await tester.tap(find.byKey(const Key('character_die_badge')));
    await _settle(tester);
    final screen =
        tester.widget<DiceLoadoutScreen>(find.byType(DiceLoadoutScreen));
    expect(screen.initialDieId, 'starter_die');
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden while the dice are closed, and with no die',
      (tester) async {
    await _open(tester, {
      ..._save,
      'flags': [featureLadderFlag]
    });
    expect(find.byKey(const Key('character_die_badge')), findsNothing);
    await _open(tester, {..._save, 'equippedDiceId': null});
    expect(find.byKey(const Key('character_die_badge')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with one die in the bag there is no +N', (tester) async {
    await _open(tester, {
      ..._save,
      'ownedDiceIds': ['starter_die'],
    });
    expect(find.byKey(const Key('character_die_badge')), findsOneWidget);
    expect(find.byKey(const Key('character_die_badge_more')), findsNothing);
  });

  testWidgets('at 320 px nothing overflows', (tester) async {
    await _open(tester, _save, width: 320);
    expect(find.byKey(const Key('character_die_badge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
