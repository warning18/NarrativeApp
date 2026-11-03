// The wharf's way "pay for the insult" leads to a scene on the wharf whose one
// way on walks to the Yard (2040 -> 2040_paid -> 2900). Since v1.407 a payment
// is acted out where the party stands: a card under the map with its price,
// no mark on the plan. Since the scene-or-map rule (choice_flow.dart) the
// read-through stops where the stop changes: the walk to the Yard is a move
// on the map, so the story stops at 2040_paid, still on the wharf.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/pump.dart';

void main() {
  testWidgets(
      'a payment read through to another district is a card, and carries the party',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    await tester.pumpWidget(
      ProviderScope(
          // These test the streets' marks: the generated plan, not the stored
          // city chart (board 15, v1.355).
          overrides: [
            cityPlanRecordsProvider.overrideWith((ref) async => const {})
          ],
          child: const MyApp()),
    );
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    // Gold enough to pay, so the way is open.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior', 'gold': 100})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settleApp(tester);

    container.read(storyPlayProvider.notifier).jumpTo('2040');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    // The jump set the party down here along no choice: the map walks it
    // by the road first (a tap would skip it).
    await tester.pump(const Duration(seconds: 6));

    // The city's plan, with the fight and the payment as cards in the scene
    // view (a button under the map opens it): a way acted out where the
    // party stands has no mark of its own.
    expect(find.byKey(const ValueKey('journey_streets')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsOneWidget);
    final pay = find.byKey(const ValueKey('journey_choice_card_1'));
    expect(pay, findsOneWidget);
    // The payment carries its price as its tag.
    expect(find.descendant(of: pay, matching: find.textContaining('4')),
        findsWidgets);

    // Taking it (a second tap) pays; the walk on to the Yard is not read
    // through.
    await tester.tap(pay);
    await tester.pump();
    await tester.tap(pay);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settleApp(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '2040_paid');
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
