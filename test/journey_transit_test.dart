// The party's road on the Journey map (v1.245): when the story sets it down
// somewhere it did not walk to (a jump along no choice, a failed roll that
// drops it at another place), the map walks it there by the world chart's
// road and says why, in the language read; a tap skips the walk. Its road is
// the world's own (v1.254): the stops it passes are named on the way.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _transit = ValueKey('journey_transit');
const _caption = ValueKey('journey_transit_caption');
const _stop = ValueKey('journey_transit_stop');

void main() {
  testWidgets('a failed roll sets the party down elsewhere and the map says so',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
          // These test the streets' marks: the generated plan, not the stored
          // city chart (board 15, v1.355).
          overrides: [
            cityPlanRecordsProvider.overrideWith((ref) async => const {})
          ],
          child: const MyApp()),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await _settle(tester);

    // What arriving somewhere opens over the game (a new place's card, a
    // chapter's notice) is closed.
    Future<void> clearCards() async {
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    // Stands at the yard, where the first roll is taken.
    play.jumpTo('2070');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(find.byKey(_transit), findsNothing);

    // The roll fails: the story sets the party down on the wharf. The map
    // tells the author's words, and shows the road.
    play.choose('2070_cut_failed');
    await _settle(tester);
    expect(find.byKey(_transit), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(_caption)).data,
      'Vane’s hand closes on your wrist: you are held on the wharf.',
    );
    expect(tester.takeException(), isNull);

    // Inside one city the words show over the map, which stays to be played
    // with; a tap on them puts them away.
    await tester.tap(find.byKey(_caption));
    await tester.pump();
    expect(find.byKey(_transit), findsNothing);

    // A jump along no choice (here, to the alley) tells it in plain words,
    // then the walk ends by itself.
    play.jumpTo('270');
    await _settle(tester);
    expect(find.byKey(_transit), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(_caption)).data,
        startsWith('You make your way to'));
    // From the wharf to the alley the party goes by the world's roads
    // (v1.254), and the words name the stops it passes.
    expect(find.byKey(_stop), findsNothing, reason: 'none passed yet');
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(_stop), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(_stop)).data, startsWith('You pass '));
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(find.byKey(_transit), findsNothing, reason: 'the transit ends');

    // Back at the yard, the same failed roll tells the author's French.
    play.jumpTo('2070');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await _settle(tester);
    play.choose('2070_cut_failed');
    await _settle(tester);
    expect(find.byKey(_transit), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(_caption)).data,
      'La main de Vane se referme sur votre poignet : on vous retient sur le quai.',
    );
    // It ends by itself.
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_transit), findsNothing);
    expect(tester.takeException(), isNull);

    // A fight is acted out where the party stands (a card under the map, no
    // road to walk), and one turned back from leaves it on its mark.
    play.jumpTo('2011');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    final card = find.byKey(const ValueKey('journey_choice_card_0'));
    await tester.tap(card);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    for (var i = 0;
        i < 240 && find.byType(FightScreen).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(FightScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(FightScreen))).pop(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_traveller')), findsNothing);
    expect(container.read(storyPlayProvider).currentNodeId, '2011');
    expect(find.byKey(_transit), findsNothing);
    expect(tester.takeException(), isNull);

    // Set down in another district of the same city along no choice (from
    // the lower town into the Undercroft), the mark comes by the streets from
    // where it stood and is home after.
    play.jumpTo('470');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(find.byKey(const ValueKey('journey_arriving')), findsNothing);
    play.choose('855');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_arriving')), findsOneWidget);
    // Along the streets of one city nothing needs saying: no world transit.
    expect(find.byKey(_transit), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('journey_arriving')), findsNothing);
    expect(find.byKey(_transit), findsNothing);
    expect(tester.takeException(), isNull);

    // A way out to another place says by which road it goes (v1.256): the
    // stops it passes, under where it leads.
    play.jumpTo('960');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 6));
    await clearCards();
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await _settle(tester);
    // The stops of every way out, read in the language of the moment.
    Future<List<String>> roadLines(String label) async {
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        if (find.byKey(ValueKey('journey_step_$i')).evaluate().isEmpty) {
          continue;
        }
        await tester.tap(find.byKey(ValueKey('journey_step_$i')));
        await tester.pump(const Duration(milliseconds: 500));
        lines.addAll([
          for (final t in tester.widgetList<Text>(find.textContaining(label)))
            t.data!,
        ]);
      }
      return lines;
    }

    final roads = await roadLines('Road: ');
    expect(roads, isNotEmpty, reason: 'a way out names its road');
    expect(roads.any((t) => t.contains('Road: The Harbour Chain')), isTrue,
        reason: '$roads');
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await _settle(tester);
    final routes = await roadLines('Route\u00a0: ');
    expect(routes, isNotEmpty, reason: 'the road is named in French too');
    expect(
        routes.any((t) => t.contains('Route\u00a0: La chaîne du port')), isTrue,
        reason: '$routes');
    expect(tester.takeException(), isNull);
  });
}
