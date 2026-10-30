// The scene panel (v1.686): a scene with someone it faces and a question
// shows them in small over its choices -- the Stone Bridge's toll keeper and
// "Pay the toll, or fight?" -- in English and French, folded to a line when
// a choice is long.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
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

Finder _inVignette(String text) => find.descendant(
    of: find.byKey(const Key('scene_vignette')),
    matching: find.textContaining(text));

void main() {
  setUp(rootBundle.clear);

  testWidgets('the Stone Bridge: its question and the one it faces',
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
    container.read(storyPlayProvider.notifier).restart('260');
    await _until(tester, find.text('Read'));
    await tester.tap(find.text('Read'));
    await _until(tester, find.byKey(const Key('scene_vignette')));
    expect(find.byKey(const Key('scene_vignette')), findsOneWidget);
    expect(find.text('Pay the toll, or fight?'), findsOneWidget);
    expect(_inVignette('Slum Thug'), findsOneWidget);

    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await settleApp(tester);
    expect(find.textContaining('Payer le péage, ou vous battre'), findsOneWidget);
    expect(_inVignette('Voyou des bas-quartiers'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
