// A town's scene is read once: on arrival it fills the screen with one
// Enter under it; once entered (and on every later visit) the town opens
// straight onto its card and tabbed lists, the scene a Reread away. New
// text shows it in full again, and the last fight's aftermath stays.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _closeDialogs(WidgetTester tester) async {
  final button = find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(FilledButton));
  while (button.evaluate().isNotEmpty) {
    await tester.tap(button.first, warnIfMissed: false);
    await _settle(tester);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a town scene folds once read and unfolds for new text',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    final play = container.read(storyPlayProvider.notifier);
    final scene = find.textContaining('Even with the Inquisition patrolling');
    final unfold = find.text('Read the scene again');

    Future<void> goTo(String nodeId) async {
      play.jumpTo(nodeId);
      await _settle(tester);
      await _closeDialogs(tester);
    }

    final enter = find.byKey(const Key('hub_enter'));
    final card = find.byKey(const Key('hub_place_card'));
    final bazaar = find.text('Visit the Arcane Bazaar');

    // First arrival: the scene is there to read, and the town waits behind
    // Enter.
    await goTo('2015');
    expect(scene, findsOneWidget);
    expect(enter, findsOneWidget);
    expect(find.text("Enter Smugglers' Wharf"), findsOneWidget);
    expect(card, findsNothing);
    expect(bazaar, findsNothing);

    // Entering opens the town: its card, its tabs and its lists.
    await tester.tap(enter);
    await _settle(tester);
    expect(scene, findsNothing);
    expect(card, findsOneWidget);
    expect(bazaar, findsOneWidget);
    expect(
        container.read(playerSessionProvider).readSceneKeys,
        contains(sceneReadKey(
            '2015',
            composeNarration(
                container.read(storyDataProvider).value!.nodes['2015']!,
                container.read(playerSessionProvider),
                french: false))));

    // One tab at a time: the townsfolk, without the shops.
    await tester.ensureVisible(find.byKey(const Key('hub_tab_people')));
    await tester.tap(find.byKey(const Key('hub_tab_people')));
    await _settle(tester);
    expect(bazaar, findsNothing);
    expect(find.text("Take the harbor master's job"), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('hub_tab_all')));
    await tester.tap(find.byKey(const Key('hub_tab_all')));
    await _settle(tester);
    expect(bazaar, findsOneWidget);

    // Back from one of the town's scenes: straight onto the town.
    await goTo('2015_bazaar');
    await goTo('2015');
    expect(scene, findsNothing);
    expect(enter, findsNothing);
    expect(card, findsOneWidget);
    expect(tester.takeException(), isNull);

    // Reread opens the scene again, and one tap goes back in.
    await tester.tap(find.byKey(const Key('hub_reread')));
    await _settle(tester);
    expect(scene, findsOneWidget);
    expect(find.text("Back to Smugglers' Wharf"), findsOneWidget);
    await tester.tap(enter);
    await _settle(tester);
    expect(scene, findsNothing);
    expect(card, findsOneWidget);

    // The last fight's aftermath stays visible over the town.
    await goTo('2015_bazaar');
    container.read(pendingAftermathProvider.notifier).state =
        'The dust settled over the stalls.';
    play.jumpTo('2015');
    await _settle(tester);
    await _closeDialogs(tester);
    expect(unfold, findsOneWidget);
    expect(find.text('The dust settled over the stalls.'), findsOneWidget);
    container.read(pendingAftermathProvider.notifier).state = null;

    // Something new in the scene (here a callback line for a flag just
    // set) shows it in full again.
    await goTo('2015_bazaar');
    await container
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(flagsToAdd: ['wharf_scouted']);
    await goTo('2015');
    expect(scene, findsOneWidget);
    expect(find.text("Back to Smugglers' Wharf"), findsOneWidget);
    expect(card, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
