// The reading page flows (v1.696): after a choice the new scene's words start
// at the top of the card (not centred in dead space), the lead-in paragraphs
// read in the same type as the text, and the "New:" card takes a place of its
// own above the page instead of covering its first lines.
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

  testWidgets('after a choice the text starts at the top of the card',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    usePhone(tester, const Size(412, 880));
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
    // The wreck scene after the storm: a long text, a callback paragraph.
    container.read(storyPlayProvider.notifier).restart('965');
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text('Read').evaluate().isNotEmpty) {
      await tester.tap(find.text('Read'));
    }
    await _until(tester, find.byKey(const ValueKey('journey_choice_card_0')));
    await tester.tap(find.byKey(const ValueKey('journey_choice_card_0')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump(const Duration(seconds: 2));
    await _until(tester, find.byKey(const ValueKey('journey_scene_text')));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final card =
        tester.getRect(find.byKey(const ValueKey('journey_scene_text')));
    final first = tester.getRect(find
        .descendant(
            of: find.byKey(const ValueKey('journey_scene_text')),
            matching: find.byType(RichText))
        .first);
    expect(first.top - card.top, lessThan(60),
        reason: 'the first line is at the top, not centred in empty space');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
