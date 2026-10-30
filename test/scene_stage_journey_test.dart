// Stage mode (v1.687): a scene with a fight among its choices, facing someone
// with a standing sprite (the family house, Aurel Vane), plays on the stage:
// the two figures, their name, the question; a choice picked speaks in a
// balloon over the hero.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

import 'support/pump.dart';

Future<void> _until(WidgetTester tester, Finder found) async {
  for (var i = 0; i < 40 && found.evaluate().isEmpty; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('the family house plays on the stage; a pick speaks',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    usePhone(tester, const Size(420, 900));
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.tap(find.byKey(const Key('menu_new_game')));
    await settleApp(tester);
    final confirm = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton));
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await settleApp(tester);
    }
    container.read(storyPlayProvider.notifier).restart('400');
    await _until(tester, find.text('Read'));
    await tester.tap(find.text('Read'));
    await _until(tester, find.byKey(const Key('scene_stage')));
    expect(find.byKey(const Key('scene_stage')), findsOneWidget);
    expect(find.byKey(const Key('scene_vignette')), findsNothing);
    expect(find.byKey(const Key('scene_stage_hero')), findsOneWidget);
    expect(find.byKey(const Key('scene_stage_foe')), findsWidgets);
    expect(find.byKey(const Key('scene_stage_balloon')), findsNothing);

    // A choice picked speaks over the hero (its text, until Narrative's
    // spoken reply is written).
    await tester.tap(find.byKey(const ValueKey('journey_choice_card_0')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('scene_stage_balloon')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
