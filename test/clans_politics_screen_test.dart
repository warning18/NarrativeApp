// Clans (v1.193) on a 360-px phone: Edit Mode's Clans & Politics screen,
// its four tabs -- the standing cards with their slider and sub-clan
// squares, the relations table with its reasons, shifts and chapter
// slider, the chart and the log, the intrigues and the stage reached --
// in English, then in French with the Character tab's Clans section; and
// a faction's shop, priced by the standing with it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';
import 'package:narrative_data_app/screens/shop_detail_screen.dart';
import 'package:narrative_data_app/widgets/clan_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final ClanData _data = ClanData.fromTables(
  factions: _json('factions'),
  subclans: _json('subclans'),
  relations: _json('relations'),
  titles: _json('titles'),
  intrigues: _json('intrigues'),
);

/// A coast that has moved: the Vigil Trusted after a quest, sworn to the
/// Penitents, the Inquisition a foe, the Dominion and the Vigil at war since
/// chapter 3, and the Hooded Lantern at its third stage.
PlayerSession _session() {
  var politics = applyStandingChange(PoliticsState.empty, 'vigil', 30, 'quest',
          data: _data, chapter: 2, day: 9)
      .state;
  politics = applyStandingChange(politics, 'penitents', 70, 'intrigue:Help',
          data: _data, chapter: 3, day: 20)
      .state;
  politics = setSubclanMark(
          politics, 'inquisition', SubclanMark.foe, 'intrigue',
          data: _data, chapter: 3, day: 21)
      .state;
  politics = shiftRelation(politics, 'dominion', 'vigil', -1, 'story',
          data: _data, chapter: 3, day: 22)
      .state;
  return baseSession().copyWith(
    politics: politics,
    alignmentScore: 12,
    flags: const ['intrigue_hooded_lantern_stage_3'],
  );
}

Future<ProviderContainer> _container(WidgetTester tester,
    {required String language}) async {
  SharedPreferences.setMockInitialValues(
      {'app_language': language, 'tutorial_enabled': false});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(appLanguageProvider);
  final notifier = container.read(playerSessionProvider.notifier);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.runAsync(() async {
    for (final schema in [
      factionsSchema,
      subclansSchema,
      relationsSchema,
      titlesSchema,
      intriguesSchema,
      signsSchema,
      companionsSchema,
      shopsSchema,
      itemsSchema,
      diceSchema,
      professionsSchema,
      racesSchema,
      spellsSchema,
      itemSetsSchema,
    ]) {
      await container.read(gameDbProvider(schema).notifier).whenLoaded();
    }
  });
  await tester.pump();
  await tester.runAsync(() => notifier.loadSession(_session()));
  return container;
}

/// The tab bar scrolls on a narrow phone: bring the tab in, then open it.
Future<void> _openTab(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the four tabs at 360 px, in English', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'en');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen()),
    ));
    await tester.pumpAndSettle();
    PoliticsState politics() => container.read(playerSessionProvider).politics;

    // Standing: a card per faction, the tier and value in words.
    expect(find.text('Clans & Politics'), findsOneWidget);
    expect(find.text('The Grey Vigil'), findsWidgets);
    final vigil = politics().standingOf('vigil', _data);
    expect(find.text('TRUSTED ${formatStanding(vigil)}'), findsOneWidget);
    expect(find.byKey(const Key('faction_sworn_penitents')), findsOneWidget);
    expect(find.byKey(const Key('clans_otherworld')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // A tap on a square cycles the mark: none -> friend.
    await tester.tap(find.byKey(const Key('subclan_square_candlebearers')));
    await _settle(tester);
    expect(politics().markOf('candlebearers'), SubclanMark.friend);
    // Foe -> none.
    await tester.tap(find.byKey(const Key('subclan_square_inquisition')));
    await _settle(tester);
    expect(politics().markOf('inquisition'), SubclanMark.none);

    // The slider sets a standing, no ripple, logged as an edit.
    final before = politics().standingOf('mire', _data);
    await tester.drag(
        find.descendant(
            of: find.byKey(const Key('faction_slider_mire')),
            matching: find.byType(Slider)),
        const Offset(60, 0));
    await _settle(tester);
    expect(politics().standingOf('mire', _data), greaterThan(before));
    expect(politics().standingLog.last.cause, 'edit');
    expect(politics().standingLog.last.deltas.keys, ['mire']);

    // Politics: the table, a pair's reason and a shift.
    await _openTab(tester, 'clans_tab_politics');
    expect(find.byKey(const Key('clans_matrix')), findsOneWidget);
    expect(find.text('Relations now'), findsOneWidget);
    expect(find.text('The Long Night'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
    await tester.tap(find.byKey(const Key('relation_cell_compact_mire')));
    await tester.pumpAndSettle();
    expect(find.text(_data.relations.pair('compact', 'mire')!.reason),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('relation_shift_down')));
    await _settle(tester);
    expect(politics().relationStep('compact', 'mire', _data), 5);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    // The chapter slider: the Dominion and the Vigil were Hostile before
    // chapter 3.
    final slider = find.byKey(const Key('clans_chapter_slider'));
    await tester.drag(slider, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Relations in chapter 1'), findsOneWidget);
    final hostile = _data.relations.stepInfo(3)!.name;
    expect(
        find.descendant(
            of: find.byKey(const Key('relation_cell_dominion_vigil')),
            matching: find.text(hostile)),
        findsOneWidget);

    // Evolution: the chart, then the log, newest first.
    await _openTab(tester, 'clans_tab_evolution');
    expect(find.byKey(const Key('clans_chart')), findsOneWidget);
    expect(find.text('Quest'), findsOneWidget);
    expect(find.text('Intrigue · Help'), findsOneWidget);
    expect(
        find.text('Sworn: '
            '${_data.faction('penitents')!.nameFor(AppLanguage.en)}'),
        findsOneWidget);
    expect(find.text('The Grey Vigil +30'), findsOneWidget);
    expect(find.text('Relations that moved'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Intrigues: the stage reached, and the others not started.
    await _openTab(tester, 'clans_tab_intrigues');
    expect(find.text('Stage 3 of 6: Turn'), findsOneWidget);
    expect(find.text('Not started'), findsWidgets);
    expect(find.textContaining('The Grey Vigil +25'), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Reset puts the coast back as the story opens.
    await _openTab(tester, 'clans_tab_standing');
    await tester.scrollUntilVisible(find.byKey(const Key('clans_reset')), 300,
        scrollable: find.descendant(
            of: find.byKey(const Key('clans_standing_list')),
            matching: find.byType(Scrollable)));
    await tester.ensureVisible(find.byKey(const Key('clans_reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clans_reset')));
    await _settle(tester);
    expect(politics().isEmpty, isTrue);
  });

  testWidgets('in French, and the Character tab\'s Clans', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'fr');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Clans et politique'), findsOneWidget);
    expect(find.text('La Veille Grise'), findsWidgets);
    expect(find.textContaining('CONFIANCE'), findsWidgets);
    expect(find.textContaining('Vœux tenus\u00a0: 0'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    await _openTab(tester, 'clans_tab_politics');
    expect(find.text('Les relations aujourd’hui'), findsOneWidget);
    expect(
        find.text('Six cents ans en une ligne'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    await _openTab(tester, 'clans_tab_evolution');
    expect(find.text('Quête'), findsOneWidget);
    expect(find.text('Ch. 2 · jour 9'), findsOneWidget);
    expect(find.text('L’Inquisition\u00a0: Inimitié'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    await _openTab(tester, 'clans_tab_intrigues');
    expect(find.text('Étape 3 sur 6\u00a0: Tournant'), findsOneWidget);
    expect(find.text('Pas commencée'), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // The Character tab's section: the same cards, no slider.
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Card(child: ClansSection()),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Clans'), findsOneWidget);
    expect(find.byKey(const Key('faction_card_dominion')), findsOneWidget);
    expect(find.byKey(const Key('faction_card_penitents')), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.byKey(const Key('faction_card_giants')), findsNothing,
        reason: 'a tribe shows once its flag is set');
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });

  testWidgets('a faction\'s shop prices by standing, and a hunter won\'t trade',
      (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'en');
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(() => notifier.loadSession(baseSession(gold: 1000)
        .copyWith(
            politics: setStandingValue(PoliticsState.empty, 'crows', 40, 'edit',
                    data: _data)
                .state)));
    final shop = _json('shops')['smugglers_vault'] as Map<String, dynamic>;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          home: ShopDetailScreen(shopId: 'smugglers_vault', shop: shop)),
    ));
    await tester.pumpAndSettle();

    // Trusted: 15% off. The Bloodthorn Blade's 260 is 221.
    expect(find.textContaining('Trusted, prices'), findsOneWidget);
    expect(find.textContaining('221 gold'), findsOneWidget);
    expect(find.byTooltip('Sell'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Hunted: no trade at all.
    await tester
        .runAsync(() => notifier.setStandingForEdit('crows', -80, data: _data));
    await tester.pumpAndSettle();
    expect(find.textContaining('will not trade with you'), findsOneWidget);
    final buys = tester
        .widgetList<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Buy'));
    expect(buys, isNotEmpty);
    expect(buys.every((b) => b.onPressed == null), isTrue);
    expect(find.byTooltip('Sell'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });

  testWidgets('the story\'s view: nothing to set, no spoilers', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'en');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen(play: true)),
    ));
    await tester.pumpAndSettle();

    // Standing: the cards, read only.
    expect(find.text('Clans'), findsOneWidget);
    expect(find.byKey(const Key('faction_card_vigil')), findsOneWidget);
    expect(find.byKey(const Key('faction_slider_vigil')), findsNothing);
    expect(find.byKey(const Key('clans_reset')), findsNothing);
    expect(find.byKey(const Key('clans_offer_now')), findsNothing);
    final before = container.read(playerSessionProvider).politics;
    await tester.tap(find.byKey(const Key('subclan_square_candlebearers')),
        warnIfMissed: false);
    await _settle(tester);
    expect(
        container.read(playerSessionProvider).politics.markOf('candlebearers'),
        before.markOf('candlebearers'),
        reason: 'a square is not a switch in the story');

    // Politics: the table fits, a cell gives the reason with no shift; the
    // news in place of the events.
    await _openTab(tester, 'clans_tab_politics');
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
    await tester.tap(find.byKey(const Key('relation_cell_compact_mire')));
    await tester.pumpAndSettle();
    expect(find.text(_data.relations.pair('compact', 'mire')!.reason),
        findsOneWidget);
    expect(find.byKey(const Key('relation_shift_down')), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clans_events_list')), findsNothing);
    expect(find.text('News from the coast'.toUpperCase()), findsOneWidget);

    // Intrigues: only the one begun, up to its stage, the next one locked;
    // no premise before the reveal, no outcome before the choice.
    await _openTab(tester, 'clans_tab_intrigues');
    expect(find.byKey(const Key('intrigue_hooded_lantern')), findsOneWidget);
    expect(find.text('Not started'), findsNothing);
    expect(
        find.byKey(const Key('intrigue_next_hooded_lantern')), findsOneWidget);
    final lantern = _data.intrigues['hooded_lantern']!;
    expect(find.text(lantern.premiseFor(AppLanguage.en)), findsNothing);
    expect(find.text(lantern.stages[3].textFor(AppLanguage.en)), findsNothing);
    expect(find.textContaining('The Grey Vigil +25'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });

  testWidgets('the story\'s view with no intrigue begun says so',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'en');
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(baseSession()));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen(play: true)),
    ));
    await tester.pumpAndSettle();
    await _openTab(tester, 'clans_tab_intrigues');
    expect(find.byKey(const Key('clans_intrigues_empty')), findsOneWidget);
  });
}
