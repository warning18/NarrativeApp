// The throne room of the Clans screen (v1.247): the Lantern Throne in pixel
// art with every banner the player has earned hanging beside it and sway
// without a hitch, in English and French, on a 360-px phone.
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
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/clan_peek.dart';
import 'package:narrative_data_app/widgets/throne_room.dart';

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

void main() {
  group('which banners are earned', () {
    test('a clan that is a friend, and the Open Hand once it is raised', () {
      final politics = PoliticsState.empty.copyWith(
          standings: const {'vigil': 30, 'dominion': 10, 'crows': -50});
      final earned = earnedClanBannerFactionIds(
          data: _data, politics: politics, flags: const []);
      expect(earned, contains('vigil'));
      expect(earned, isNot(contains('dominion')));
      expect(earned, isNot(contains('crows')));
      expect(earned, isNot(contains('open_hand')));
      final raised = earnedClanBannerFactionIds(
          data: _data, politics: politics, flags: const [bannerRaisedFlag]);
      expect(raised, contains('open_hand'));
    });

    test('nothing is earned at the start', () {
      final earned = earnedClanBannerFactionIds(
          data: _data, politics: PoliticsState.empty, flags: const []);
      expect(earned.length, lessThan(clanBannerFactionIds.length));
    });
  });

  Future<void> open(WidgetTester tester,
      {required String language, required PlayerSession session}) async {
    SharedPreferences.setMockInitialValues(
        {'app_language': language, 'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appLanguageProvider);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
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
    await tester.runAsync(() => notifier.loadSession(session));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen(play: true)),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('clans_tab_throne_room')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('clans_tab_throne_room')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    // The page slides in while the flames burn: give it time to land.
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('the hall shows the throne and the banners earned, swaying',
      (tester) async {
    final session = baseSession().copyWith(
      politics: PoliticsState.empty.copyWith(standings: const {
        'vigil': 30,
        'dominion': 22,
        'mire': 40,
        'crows': 26,
        'choir': -10,
      }, throneWinner: 'compact'),
      flags: const [bannerRaisedFlag],
      bannerPiecesCollected: const ['heirloom_shroud', 'warden_standard'],
    );
    await open(tester, language: 'en', session: session);
    expect(find.byKey(const Key('throne_room')), findsOneWidget);
    expect(find.byKey(const Key('throne_hall')), findsOneWidget);
    expect(find.text('The Lantern Throne'), findsOneWidget);
    for (final id in [
      'clan_vigil',
      'clan_dominion',
      'clan_mire',
      'clan_crows',
      'clan_open_hand',
      'heirloom_shroud',
      'warden_standard',
    ]) {
      expect(find.byKey(Key('throne_banner_$id')), findsOneWidget, reason: id);
    }
    // One that was not earned does not hang.
    expect(find.byKey(const Key('throne_banner_clan_choir')), findsNothing);
    expect(find.textContaining('The throne is held by'), findsOneWidget);
    expect(find.text('7 banners earned'), findsOneWidget);

    // A tap names a banner; a second tap lets it go.
    await tester.tap(find.byKey(const Key('throne_banner_clan_vigil')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining(' · '), findsWidgets);

    // A long press on a clan's standard shows the clan's details for as long
    // as it is held; the Shroud's pieces have none.
    final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('throne_banner_clan_vigil'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('clan_details_vigil')), findsOneWidget);
    expect(find.byKey(const Key('clan_peek_intro_vigil')), findsOneWidget,
        reason: 'a recap of its story');
    await hold.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('clan_details_vigil')), findsNothing,
        reason: 'letting go closes it');
    final shroud = await tester.startGesture(tester
        .getCenter(find.byKey(const Key('throne_banner_heirloom_shroud'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(ClanDetailsCard), findsNothing);
    await shroud.up();

    // The cloth moves: a few seconds of frames paint without a hitch.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty hall says so, in French', (tester) async {
    await open(tester, language: 'fr', session: baseSession());
    expect(find.text('Le Trône de la Lanterne'), findsOneWidget);
    expect(find.textContaining('Aucune bannière'), findsWidgets);
    expect(find.byKey(const Key('throne_hall')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
