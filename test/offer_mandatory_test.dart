// The clans' offer is mandatory (v1.552): it opens on its own after a
// level-up and whenever one waits over the home screen (offer_autopilot),
// a tap outside or the system back never closes it, only a gift taken
// does; the offers an older save left waiting come one after another at
// launch until none is left. Before the clans' feature opens on the ladder,
// nothing opens.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/feature_unlocks.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/offer_autopilot.dart';
import 'package:narrative_data_app/widgets/level_up_dialog.dart';
import 'package:narrative_data_app/widgets/offer_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;

const OfferTicket _level = OfferTicket(source: OfferSource.level);

/// A real session with [offers] waiting (none drawn yet) and the tables
/// an offer is drawn from loaded.
Future<ProviderContainer> _container(WidgetTester tester,
    {required int offers, List<String> flags = const []}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // The session's own load from the (empty) prefs ends before ours.
  final notifier = container.read(playerSessionProvider.notifier);
  container.read(appLanguageProvider);
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
      skillsSchema,
      skillTreesSchema,
      itemsSchema,
      spellsSchema,
      specialisationsSchema,
      specVariantsSchema,
    ]) {
      await container.read(gameDbProvider(schema).notifier).whenLoaded();
    }
  });
  await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
        ...baseSession().toJson(),
        'characterName': 'Ash',
        'raceId': 'human',
        'professionId': 'warrior',
        'unlockedSkillIds': ['warrior_shield_bash', 'bulwark_stance'],
      }).copyWith(
          pendingOffers: List.filled(offers, _level),
          clearClanOffer: true,
          flags: flags)));
  return container;
}

/// Lets the tables load and the dialogs settle (real async in between).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    for (var j = 0; j < 8; j++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Takes the first suitor on the table that is not a risky card: picked,
/// taken, confirmed, and the reward card closed.
Future<void> _takeGift(WidgetTester tester, ProviderContainer container) async {
  final offer = container.read(playerSessionProvider).clanOffer!;
  final suitor = offer.suitors.firstWhere((s) => !s.risky);
  final banner = find.byKey(Key('offer_suitor_${suitor.factionId}'));
  await tester.ensureVisible(banner);
  await tester.tap(banner);
  await tester.pump();
  final take = find.byKey(const Key('offer_take_button'));
  await tester.ensureVisible(take);
  await tester.tap(take);
  await _settle(tester);
  await tester.tap(find.byKey(const Key('offer_confirm_accept')));
  await _settle(tester);
  await tester.tap(find.byKey(const Key('reward_button')));
  await _settle(tester);
}

void main() {
  testWidgets(
      'after a level-up the offer opens on its own; outside and back keep '
      'it; a gift taken closes it', (tester) async {
    final container = await _container(tester, offers: 1);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              key: const Key('level'),
              onPressed: () => showLevelUpDialog(context, ref, newLevel: 2),
              child: const Text('Level'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('level')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('level_up_close')));
    await _settle(tester);
    expect(find.byType(OfferDialog), findsOneWidget,
        reason: 'the offer follows the level-up on its own');

    // A tap outside and the system back leave it, the offer kept.
    final offer = container.read(playerSessionProvider).clanOffer;
    expect(offer, isNotNull);
    await tester.tapAt(const Offset(2, 2));
    await _settle(tester);
    expect(find.byType(OfferDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(OfferDialog), findsOneWidget);
    expect(container.read(playerSessionProvider).clanOffer, offer);
    expect(find.text('Later'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing, reason: 'no close button');

    await _takeGift(tester, container);
    expect(find.byType(OfferDialog), findsNothing);
    expect(container.read(playerSessionProvider).pendingOffers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'three offers from an older save come one after another at launch '
      'until none waits', (tester) async {
    final container = await _container(tester, offers: 3);
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: OfferAutopilot(child: Text('Journey', key: Key('journey'))),
        ),
      ),
    ));
    await _settle(tester);
    for (var left = 3; left > 0; left--) {
      expect(find.byType(OfferDialog), findsOneWidget,
          reason: '$left offer(s) waiting: one is on the table');
      expect(
          container.read(playerSessionProvider).pendingOffers, hasLength(left));
      await _takeGift(tester, container);
    }
    expect(container.read(playerSessionProvider).pendingOffers, isEmpty);
    expect(find.byType(OfferDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'before the clans open on the ladder, nothing opens; once '
      'they do, the waiting offers come', (tester) async {
    final container =
        await _container(tester, offers: 2, flags: const [featureLadderFlag]);
    final notifier = container.read(playerSessionProvider.notifier);
    expect(container.read(playerSessionProvider).featureOpen(GameFeature.clans),
        isFalse);
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: OfferAutopilot(child: Text('Journey', key: Key('journey'))),
        ),
      ),
    ));
    await _settle(tester);
    expect(find.byType(OfferDialog), findsNothing);
    expect(container.read(playerSessionProvider).pendingOffers, hasLength(2),
        reason: 'they wait for the clans');

    // The clans come (the ladder's rung reached): the offers open.
    await tester.runAsync(() => notifier.loadSession(
        container.read(playerSessionProvider).copyWith(flags: const [])));
    await _settle(tester);
    expect(find.byType(OfferDialog), findsOneWidget);
  });

  testWidgets(
      'a level-up in a fight left at once still brings its offer, over '
      'the home screen', (tester) async {
    final container = await _container(tester, offers: 1);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('fight'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      key: const Key('level'),
                      onPressed: () =>
                          showLevelUpDialog(context, ref, newLevel: 2),
                      child: const Text('Level'),
                    ),
                  ),
                ),
              )),
              child: const Text('Fight'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('fight')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('level')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('level_up_close')));
    // The fight leaves before the offer's tables are read.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await _settle(tester);
    expect(find.byKey(const Key('level')), findsNothing);
    expect(find.byType(OfferDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
