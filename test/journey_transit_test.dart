// The party's road on the Journey map (v1.245): when the story sets it down
// somewhere it did not walk to (a jump along no choice, a failed roll that
// drops it at another place), the map walks it there by the world chart's
// road and says why, in the language read; a tap skips the walk. Its road is
// the world's own (v1.254): the stops it passes are named on the way.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

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
    usePhone(tester, const Size(360, 800));

    final container = await openGame(tester, overrides: [storedCityPlans]);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);

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
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(find.byKey(_transit), findsNothing);

    // The roll fails: the story sets the party down on the wharf. The map
    // tells the author's words, and shows the road.
    play.choose('2070_cut_failed');
    await settleApp(tester);
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
    await settleApp(tester);
    expect(find.byKey(_transit), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(_caption)).data,
        startsWith('You make your way to'));
    // From the wharf to the alley the party goes by the world's roads
    // (v1.254), and the words name the stops it passes.
    expect(find.byKey(_stop), findsNothing, reason: 'none passed yet');
    // (Alster is one place since v1.535: the walk is shorter and ends
    // before two seconds, so look while it is still under way.)
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(_stop), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(_stop)).data, startsWith('You pass '));
    // A tap on the map skips the move.
    await tester.tap(find.byKey(const ValueKey('journey_transit_skip')));
    await tester.pump();
    expect(find.byKey(_transit), findsNothing, reason: 'a tap skips');
    await tester.pump(const Duration(seconds: 4));
    await clearCards();

    // Back at the yard, the same failed roll tells the author's French.
    play.jumpTo('2070');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await settleApp(tester);
    play.choose('2070_cut_failed');
    await settleApp(tester);
    expect(find.byKey(_transit), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(_caption)).data,
      'La main de Vane se referme sur votre poignet : on vous retient sur le quai.',
    );
    // It ends by itself.
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_transit), findsNothing);
    expect(tester.takeException(), isNull);

    // A fight is acted out where the party stands (a card in the scene view,
    // no road to walk), and one turned back from leaves it on its mark.
    play.jumpTo('2011');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 400));
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
    // Back from the scene view to the map.
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 400));

    // Set down in another district of the same city along no choice (from
    // the lower town into the Undercroft), the walk is told in words, and
    // ends by itself. (The mark that came by the generated streets is gone
    // with them, N11: the stored chart shows where the party stands.) (From the street, 250: the family
    // house, 470, is a building of its own since the scene-or-map rule.)
    play.jumpTo('250');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    play.choose('855');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Along the streets of one city there is no road to draw, but the walk
    // is told in a line (v1.537): no world map, only the words.
    expect(find.byKey(_transit), findsOneWidget);
    expect(find.byType(JourneyWorldMap), findsNothing);
    final walk = tester.widget<Text>(find.byKey(_caption)).data!;
    expect(walk, anyOf(contains('the Undercroft'), contains('les Souterrains')),
        reason: walk);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_transit), findsNothing);
    expect(tester.takeException(), isNull);

    // A way out to another place says by which road it goes (v1.256): the
    // stops it passes, under where it leads.
    play.jumpTo('960');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 6));
    await clearCards();
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await settleApp(tester);
    // The stops of every way out (the rows of the city's chart, each one
    // opening its sheet), read in the language of the moment.
    Future<List<String>> roadLines(String label) async {
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        final row = find.byKey(ValueKey('journey_city_row_$i'));
        if (row.evaluate().isEmpty) continue;
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pump(const Duration(milliseconds: 500));
        lines.addAll([
          for (final t in tester.widgetList<Text>(find.textContaining(label)))
            t.data!,
        ]);
        await tester.tap(find.byKey(const ValueKey('journey_city_not_now')));
        await tester.pump(const Duration(milliseconds: 500));
      }
      return lines;
    }

    // The chart opens on the whole town: the District tab shows the ways.
    final district = find.byKey(const Key('journey_tab_district'));
    if (district.evaluate().isNotEmpty) {
      await tester.tap(district);
      await tester.pump(const Duration(milliseconds: 600));
    }
    final roads = await roadLines('Road: ');
    expect(roads, isNotEmpty, reason: 'a way out names its road');
    expect(roads.any((t) => t.contains('Road: The Harbour Chain')), isTrue,
        reason: '$roads');
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await settleApp(tester);
    final routes = await roadLines('Route\u00a0: ');
    expect(routes, isNotEmpty, reason: 'the road is named in French too');
    expect(
        routes.any((t) => t.contains('Route\u00a0: La chaîne du port')), isTrue,
        reason: '$routes');
    expect(tester.takeException(), isNull);
  });
}
