// The story screen on small phones: a town hub, the late hubs, an ending
// and a scene with long choices all fit, in English and French -- the
// choices scroll within their share of the screen instead of overflowing.
// A hub keeps a finished activity on its list, ticked and greyed.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

/// Lets the story and game data load (their assets are decoded off the
/// fake test clock) and the screen settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _expectNoLayoutError(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: where);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('story scenes fit small phone screens in both languages',
      (tester) async {
    // The device voice the test host doesn't have answers nothing.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

    for (final size in const [Size(390, 844), Size(360, 640)]) {
      tester.view.physicalSize = size;
      for (final language in AppLanguage.values) {
        await tester.runAsync(() =>
            container.read(appLanguageProvider.notifier).setLanguage(language));
        for (final nodeId in ['2015', '3005', '5010', '6010', '7002', '7005']) {
          final where =
              '$nodeId at ${size.width.toInt()}x${size.height.toInt()} '
              '(${language.name})';
          container.read(storyPlayProvider.notifier).jumpTo(nodeId);
          await _settle(tester);
          _expectNoLayoutError(tester, where);
          // Close an arrival pop-up if one opened.
          final dialogButton = find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(FilledButton));
          if (dialogButton.evaluate().isNotEmpty) {
            await tester.tap(dialogButton.first, warnIfMissed: false);
            await _settle(tester);
            _expectNoLayoutError(tester, where);
          }
          // The scene really is on screen, not a loading spinner.
          expect(find.textContaining(' $nodeId'), findsWidgets,
              reason: '$where not shown');
        }
      }
    }

    // A hub keeps its finished activities as a ticked checklist.
    tester.view.physicalSize = const Size(360, 640);
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    final story = container.read(storyDataProvider).value!;
    final hub = story.nodeFor('2015')!;
    final finished = hub.choices.firstWhere((c) => c.hideIfFlags.isNotEmpty);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'flags': [finished.hideIfFlags.first],
        })));
    container.read(storyPlayProvider.notifier).jumpTo('2015');
    await _settle(tester);
    final dialogButton = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton));
    if (dialogButton.evaluate().isNotEmpty) {
      await tester.tap(dialogButton.first, warnIfMissed: false);
      await _settle(tester);
    }
    _expectNoLayoutError(tester, '2015 with one activity done');
    expect(find.textContaining(' done'), findsOneWidget);
    expect(find.text(finished.text), findsOneWidget);
  });
}
