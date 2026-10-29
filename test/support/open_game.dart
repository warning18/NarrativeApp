// QA: the opening most Journey and story widget tests share: pump the app,
// press Edit Mode on the main menu (it opens the game with no save), then set
// the language to English, load a save and switch to in-game mode. It was
// written out in 23 files.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'pump.dart';

/// No stored city chart: the Journey draws the generated plan under the marks
/// (the stored chart has its own test, journey_city_view_test).
final noCityPlans =
    cityPlanRecordsProvider.overrideWith((ref) async => const {});

/// The app, open on the game with [session] (a plain human warrior by
/// default), English, in-game mode. Returns the provider container. [overrides]
/// go to the provider scope.
Future<ProviderContainer> openGame(
  WidgetTester tester, {
  List<Override> overrides = const [],
  Map<String, dynamic> session = const {
    'raceId': 'human',
    'professionId': 'warrior',
  },
}) async {
  await tester
      .pumpWidget(ProviderScope(overrides: overrides, child: const MyApp()));
  await settleApp(tester);
  await tester.tap(find.byKey(const Key('menu_edit_mode')));
  await settleApp(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(session)));
  await tester.runAsync(
      () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
  await settleApp(tester);
  return container;
}
