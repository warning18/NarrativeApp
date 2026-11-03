// The opening animation is on the page a new game really opens (the Journey's
// reading page, not only the Story tab): the text is told, a double tap
// skips to the choice, which then opens the character's making. The game
// hasn't started: no way to the map at all (v1.692).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';

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

  testWidgets('a new game opens on the animated first scene', (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    usePhone(tester, const Size(420, 900));
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.tap(find.byKey(const Key('menu_new_game')));
    await settleApp(tester);
    final confirm = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton));
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await settleApp(tester);
    }
    final text = find.byKey(const Key('prologue_text'));
    await _until(tester, text);
    expect(text, findsOneWidget);
    // Told a sentence at a time: the choice waits; no map, neither the
    // page's corner button nor the top bar's.
    expect(find.byKey(const Key('prologue_sentence_0')), findsOneWidget);
    expect(find.byKey(const Key('prologue_sentence_5')), findsNothing);
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsNothing);
    expect(find.byKey(const Key('home_full_map')), findsNothing);
    // Two taps: the end of the text, the choice settles in, and still no
    // way back to the map.
    await tester.tap(text);
    await tester.tap(text);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsNothing);
    expect(find.byKey(const Key('home_full_map')), findsNothing);
    final card = find.byKey(const ValueKey('journey_choice_cards'));
    expect(card, findsOneWidget);
    expect(find.textContaining('Choisissez qui vous êtes'), findsOneWidget);
    // The choice is reachable with one tap: the character's making opens.
    await tester.tap(find.descendant(
        of: card, matching: find.textContaining('Choisissez qui vous êtes')));
    await _until(tester, find.byType(RaceProfessionScreen));
    expect(find.byType(RaceProfessionScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
