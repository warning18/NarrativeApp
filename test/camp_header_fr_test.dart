// The camp's chapter card on a 360x640 phone in French: its header
// ("ENSUITE · QUÊTE PRINCIPALE") fits, cut short if need be, where v1.186
// overflowed.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the camp\'s chapter card fits a small phone in French',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'characterName': 'Maren',
          'raceId': 'human',
          'professionId': 'warrior',
          'flags': [campFoundedFlag],
        })));
    container.read(storyPlayProvider.notifier).jumpTo('3001_camp');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(find.byKey(const Key('chapter_card')), findsOneWidget);
    expect(find.textContaining('QUÊTE PRINCIPALE'), findsOneWidget);
    // No "RenderFlex overflowed" from the card's header.
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
