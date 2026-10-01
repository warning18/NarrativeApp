// The climb and the Host on a 360-px phone (v1.196): the Character tab's
// climb (the claim, its rungs, the Throne, "Your Host"), the Host's
// sheet, and Edit Mode's Throne tab (the claim, the steps, a pledge, the
// muster), in English and in French.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/throne.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_politics.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';
import 'package:narrative_data_app/widgets/clan_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

/// A climb under way: the Quarrymen and the Stitchers friends, the
/// Compact's quest at its second step, the Vigil Trusted.
PlayerSession _session(ClanData data) {
  var politics =
      setStandingValue(PoliticsState.empty, 'vigil', 30, 'edit', data: data)
          .state;
  for (final house in ['quarrymen', 'stitchers']) {
    politics =
        setSubclanMark(politics, house, SubclanMark.friend, 'edit', data: data)
            .state;
  }
  return baseSession().copyWith(
    politics: politics,
    flags: const ['clan_compact_step_1', 'clan_compact_step_2'],
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
      politicsEventsSchema,
      companionsSchema,
    ]) {
      await container.read(gameDbProvider(schema).notifier).whenLoaded();
    }
  });
  await tester.pump();
  final data = container.read(clanDataProvider);
  await tester.runAsync(() => notifier.loadSession(_session(data)));
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Character tab\'s climb and the Host, in English',
      (tester) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'en');
    final data = container.read(clanDataProvider);
    final notifier = container.read(playerSessionProvider.notifier);
    Widget section() => UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Card(child: ClansSection()),
              ),
            ),
          ),
        );
    await tester.pumpWidget(section());
    await tester.pumpAndSettle();

    // No claim: the furthest climb, the Compact's (a House, two steps).
    expect(find.byKey(const Key('character_climb')), findsOneWidget);
    expect(find.text('No claim yet'), findsOneWidget);
    expect(find.text('Furthest climb: The Cinder Compact'), findsOneWidget);
    expect(find.text('House · The Quarrymen'), findsOneWidget);
    expect(find.text('Clan 2/3'), findsOneWidget);
    Finder throneRung(IconData icon) => find.descendant(
        of: find.byKey(const Key('climb_rung_throne_compact')),
        matching: find.byIcon(icon));
    expect(throneRung(Icons.circle_outlined), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // The claim, then the Throne and the muster.
    await tester.runAsync(() => notifier.applyThroneEdit(
        const StoryPolitics(claim: 'compact'),
        data: data,
        chapter: 6));
    await _settle(tester);
    expect(find.text('Your claim: The Cinder Compact'), findsOneWidget);
    expect(find.text('Clan'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('climb_rung_clan_compact')),
            matching: find.byIcon(Icons.check_circle)),
        findsOneWidget);
    expect(find.byKey(const Key('climb_open_host')), findsNothing);
    await tester.runAsync(() => notifier.applyThroneEdit(
        const StoryPolitics(throneWinner: 'compact', muster: true),
        data: data,
        chapter: 8));
    await _settle(tester);
    expect(find.text('On the Lantern Throne for The Cinder Compact'),
        findsOneWidget);
    expect(throneRung(Icons.check_circle), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Your Host: the Compact's banner, the Vigil (Trusted), two Houses.
    await tester.tap(find.byKey(const Key('climb_open_host')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('host_sheet')), findsOneWidget);
    expect(find.text('Your Host'), findsWidgets);
    expect(find.byKey(const Key('host_contingent_compact')), findsOneWidget);
    expect(find.byKey(const Key('host_contingent_vigil')), findsOneWidget);
    expect(find.byKey(const Key('host_house_quarrymen')), findsOneWidget);
    expect(find.byKey(const Key('host_house_stitchers')), findsOneWidget);
    expect(find.text('4 in the Host'), findsOneWidget);
    expect(find.text('Mustered in chapter 8, day 1'), findsOneWidget);
    expect(find.text(data.faction('compact')!.host!.line), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
    Navigator.of(tester.element(find.byKey(const Key('host_sheet')))).pop();
    await tester.pumpAndSettle();

    // The Open Hand's House, the Fishbasket Line, on its card.
    await tester.runAsync(() => container
            .read(gameDbProvider(subclansSchema).notifier)
            .upsertRecord('fishbasket_line', {
          'id': 'fishbasket_line',
          'clan': 'open_hand',
          'name': 'The Fishbasket Line',
          'name_fr': 'La Lignée des Paniers',
        }));
    // The session moves at once; its save follows in the test's own time.
    notifier.setOpenHandStage(2, data: container.read(clanDataProvider));
    notifier.setSubclanMark('fishbasket_line', SubclanMark.friend,
        data: container.read(clanDataProvider), cause: 'edit');
    await _settle(tester);
    expect(
        find.descendant(
            of: find.byKey(const Key('lost_clan_card_open_hand')),
            matching: find.byKey(const Key('subclan_square_fishbasket_line'))),
        findsOneWidget);
    expect(
        rungFor('open_hand', container.read(playerSessionProvider).politics,
            container.read(clanDataProvider)),
        rungHouse);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });

  testWidgets('Edit Mode\'s Throne tab, in French', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(tester, language: 'fr');
    PoliticsState politics() => container.read(playerSessionProvider).politics;
    List<String> flags() => container.read(playerSessionProvider).flags;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('clans_tab_throne')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clans_tab_throne')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clans_throne_list')), findsOneWidget);
    expect(find.text('Étapes 2/3'), findsOneWidget);
    expect(find.text('Maison · Les Carriers'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // A step up on the Vigil's quest, then the Vigil as the claim.
    await tester.ensureVisible(find.byKey(const Key('throne_step_up_vigil')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('throne_step_up_vigil')));
    await _settle(tester);
    expect(flags(), contains('clan_vigil_step_1'));
    await tester.tap(find.byKey(const Key('throne_claim_vigil')));
    await _settle(tester);
    expect(politics().claim, 'vigil');
    expect(flags(), contains('claim_vigil'));
    expect(find.text('Prétention'), findsWidgets);

    // The giants pledge; the preview counts them.
    await tester.ensureVisible(find.byKey(const Key('throne_pledge_giants')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('throne_pledge_giants')));
    await _settle(tester);
    expect(politics().pledged, ['giants']);
    expect(find.textContaining('Bannière : Veille'), findsOneWidget);
    expect(find.textContaining('Géants'), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Muster now: the Host, kept, and its sheet.
    await tester.ensureVisible(find.byKey(const Key('throne_muster')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('throne_muster')));
    await _settle(tester);
    expect(politics().host.mustered, isTrue);
    expect(politics().host.banner, 'vigil');
    expect(flags(), containsAll(['host_vigil', 'host_giants']));
    expect(find.text('Votre Ost'), findsOneWidget);
    expect(find.text('La Bannière'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
    Navigator.of(tester.element(find.byKey(const Key('host_sheet')))).pop();
    await tester.pumpAndSettle();

    // Undo the climb.
    await tester.ensureVisible(find.byKey(const Key('throne_clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('throne_clear')));
    await _settle(tester);
    expect(politics().claim, isEmpty);
    expect(politics().host.mustered, isFalse);
    expect(flags().where((f) => f.startsWith('host_')), isEmpty);
    expect(flags(), contains('clan_vigil_step_1'), reason: 'steps stay');

    // The Character tab's climb, in French: the Compact is furthest up.
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
    expect(find.text('L’Ascension'), findsOneWidget);
    expect(find.text('Aucune prétention pour l’instant'), findsOneWidget);
    expect(find.text('Ascension la plus avancée : Le Pacte des Cendres'),
        findsOneWidget);
    expect(find.text('Clan 2/3'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });
}
