// Every move is on the map (v1.854, the user's call): in a place drawn with
// no plan (the Sleeper's Face, 1140), a way that leaves for another place is
// a pin even when it fights or rolls on its way, its tag on its name; only
// what is done where the party stands stays a card.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/choice_card.dart';
import 'support/open_game.dart' show storedCityPlans;
import 'support/pump.dart';

/// The Journey at scene [scene] as a player stands there: a new human
/// warrior with [flags], the stored city plans, in English.
Future<void> _openAt(
    WidgetTester tester, String scene, List<String> flags) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
  usePhone(tester, const Size(412, 915));
  await tester.pumpWidget(
      ProviderScope(overrides: [storedCityPlans], child: const MyApp()));
  await settleApp(tester);
  await tester.tap(find.byKey(const Key('menu_edit_mode')));
  await settleApp(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 100,
        'flags': ['journey_first_shown', ...flags],
      })));
  await tester.runAsync(
      () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
  await settleApp(tester);
  await tester.tap(find.text('Journey'));
  await settleApp(tester);
  container.read(storyPlayProvider.notifier).jumpTo(scene);
  await settleApp(tester);
  await tester.pump(const Duration(seconds: 6));
  for (var i = 0; i < 3; i++) {
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('1140: the fight and the sneak on the way out are pins',
      (tester) async {
    await _openAt(tester, '1140', const []);
    // No card under the map: all three ways are on it.
    expect(find.byType(ChoiceCard), findsNothing);
    final tags = find.byWidgetPredicate((w) =>
        w is ChoiceTagChip &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('journey_pin_tag_'));
    expect(tags, findsWidgets);
    expect(
        tester
            .widgetList<ChoiceTagChip>(tags)
            .map((c) => c.tag.label)
            .contains('Fight'),
        isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
