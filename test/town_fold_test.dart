// A town's scene folds to one line when the player comes back to the place
// with nothing new in it, so the town's own lists get the screen; new text
// shows it in full again, and the last fight's aftermath stays visible.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

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
    final fold = find.text('Fold the scene');

    Future<void> goTo(String nodeId) async {
      play.jumpTo(nodeId);
      await _settle(tester);
      await _closeDialogs(tester);
    }

    // First arrival: the scene is there to read.
    await goTo('2015');
    expect(scene, findsOneWidget);
    expect(unfold, findsNothing);
    expect(fold, findsNothing);

    // Back from one of the town's scenes: folded to one line.
    await goTo('2015_bazaar');
    await goTo('2015');
    expect(scene, findsNothing);
    expect(unfold, findsOneWidget);
    expect(tester.takeException(), isNull);

    // A tap opens it again, and it can be folded back.
    await tester.tap(unfold);
    await _settle(tester);
    expect(scene, findsOneWidget);
    await tester.tap(fold);
    await _settle(tester);
    expect(scene, findsNothing);
    expect(unfold, findsOneWidget);

    // The last fight's aftermath stays visible under the folded line.
    await goTo('2015_bazaar');
    container.read(pendingAftermathProvider.notifier).state =
        'The dust settled over the stalls.';
    play.jumpTo('2015');
    await _settle(tester);
    await _closeDialogs(tester);
    expect(unfold, findsOneWidget);
    expect(find.text('The dust settled over the stalls.'), findsOneWidget);

    // Something new in the scene (here a callback line for a flag just
    // set) shows it in full again.
    await goTo('2015_bazaar');
    await container
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(flagsToAdd: ['wharf_scouted']);
    await goTo('2015');
    expect(scene, findsOneWidget);
    expect(unfold, findsNothing);
    expect(fold, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
