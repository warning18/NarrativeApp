// The clan story layer (v1.195) on a 360-px phone: the news from the
// coast in the journal (in French), on a chapter's card and as the camp's
// notice; the hint under a choice and its setting; Edit Mode's events
// with "Fire now", the Open Hand's stage and its line in the Evolution
// log; and the codex's silhouette before the name is heard.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/combat_settings_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show choicePoliticsHint, chapterCardNews;
import 'package:narrative_data_app/widgets/clan_widgets.dart';
import 'package:narrative_data_app/widgets/coast_news.dart';
import 'package:narrative_data_app/widgets/moments.dart';
import 'package:narrative_data_app/widgets/offer_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The game's factions with the Open Hand among them, as the content will
/// have it.
Map<String, dynamic> _factionsWithTheHand() => {
      ..._json('factions'),
      'open_hand': {
        'id': 'open_hand',
        'kind': 'lost',
        'name': 'The Open Hand',
        'name_fr': 'La Main Ouverte',
        'motto': 'What is drawn, holds.',
        'motto_fr': 'Ce qui est tracé tient.',
        'icon': 'back_hand',
        'color': '#9A968C',
      },
    };

const List<CoastNews> _news = [
  CoastNews(
    eventId: 'lantern_bearer_failing',
    chapter: 1,
    day: 3,
    text: 'The Feast of the Flame came and went.',
    textFr: 'La fête de la Flamme passa.',
  ),
  CoastNews(
    eventId: 'lantern_bearer_dies',
    chapter: 4,
    day: 30,
    text: 'The bells of the Spire rang through the night.',
    textFr: 'Les cloches de la Flèche sonnèrent toute la nuit.',
  ),
];

Future<ProviderContainer> _container(
  WidgetTester tester, {
  String language = 'en',
  PlayerSession? session,
  bool loadClans = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'app_language': language,
    'tutorial_enabled': false,
    if (loadClans) 'gamedb_factions': jsonEncode(_factionsWithTheHand()),
  });
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(appLanguageProvider);
  final notifier = container.read(playerSessionProvider.notifier);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  if (loadClans) {
    await tester.runAsync(() async {
      for (final schema in [
        factionsSchema,
        subclansSchema,
        relationsSchema,
        titlesSchema,
        intriguesSchema,
        signsSchema,
        companionsSchema,
        itemsSchema,
        skillsSchema,
        skillTreesSchema,
        spellsSchema,
        politicsEventsSchema,
      ]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
    });
  }
  await tester.pump();
  if (session != null) {
    await tester.runAsync(() => notifier.loadSession(session));
  }
  return container;
}

void _phone(WidgetTester tester, {double height = 800}) {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

PlayerSession _withNews({bool read = false}) => baseSession().copyWith(
      politics: PoliticsState(news: [
        for (final n in _news) read ? n.markedRead() : n,
      ]),
    );

void main() {
  testWidgets('the journal keeps the news from the coast, at 360 px, in French',
      (tester) async {
    _phone(tester);
    final container =
        await _container(tester, language: 'fr', session: _withNews());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: JournalScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelles'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journal_news_tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('journal_news_list')), findsOneWidget);
    expect(find.text('Nouvelles de la côte'), findsOneWidget);
    // The latest first, dated.
    final bells =
        tester.getTopLeft(find.text('Les cloches de la Flèche sonnèrent toute '
            'la nuit.'));
    final feast = tester.getTopLeft(find.text('La fête de la Flamme passa.'));
    expect(bells.dy, lessThan(feast.dy));
    expect(find.text('CHAPITRE 4, JOUR 30'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });

  testWidgets('with no news, the journal says what the page is for',
      (tester) async {
    _phone(tester);
    final container = await _container(tester, session: baseSession());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CoastNewsList()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('No news from the coast yet'), findsOneWidget);
  });

  testWidgets('a chapter\'s card tells the news it brings, then goes',
      (tester) async {
    _phone(tester, height: 640);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return const Scaffold();
      }),
    ));
    final lines = chapterCardNews([
      ..._news,
      ..._news,
    ], AppLanguage.en);
    expect(lines, hasLength(4), reason: 'three, then how many more');
    expect(lines.last, '1 more in the journal');
    showChapterCard(ctx,
        number: 'Chapter 4',
        title: 'The Hollow Court',
        colour: Colors.orange,
        newsTitle: 'News from the coast',
        news: lines);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('chapter_card_news')), findsOneWidget);
    expect(find.text('NEWS FROM THE COAST'), findsOneWidget);
    expect(find.text('The bells of the Spire rang through the night.'),
        findsNWidgets(1));
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
    // It stays longer than a plain card.
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.byKey(const ValueKey('chapter_card')), findsOneWidget);
    expect(chapterCardDuration(0), const Duration(milliseconds: 2400));
    expect(chapterCardDuration(4) > chapterCardDuration(1), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chapter_card')), findsNothing);
  });

  testWidgets(
      'the camp\'s notice: the news not read yet a tap away; "Noted" puts '
      'it away', (tester) async {
    _phone(tester);
    final container = await _container(tester, session: _withNews());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
          home: Scaffold(body: Center(child: CoastNewsChip()))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('News (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('camp_coast_news')));
    await tester.pumpAndSettle();
    expect(find.text('News from the coast'), findsOneWidget);
    // The latest first, dated.
    final bells = tester.getTopLeft(
        find.text('The bells of the Spire rang through the night.'));
    final feast =
        tester.getTopLeft(find.text('The Feast of the Flame came and went.'));
    expect(bells.dy, lessThan(feast.dy));
    expect(find.text('CHAPTER 4, DAY 30'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
    await tester.tap(find.byKey(const Key('camp_coast_news_noted')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('camp_coast_news_sheet')), findsNothing);
    expect(find.byKey(const Key('camp_coast_news')), findsNothing);
    expect(container.read(playerSessionProvider).politics.unreadNews, isEmpty);
    expect(container.read(playerSessionProvider).politics.news, hasLength(2),
        reason: 'the journal keeps them');
  });

  testWidgets('the hint under a choice follows its setting', (tester) async {
    _phone(tester);
    final container = await _container(tester, language: 'fr', loadClans: true);
    final choice = StoryChoice.fromJson(const {
      'text': 'Stand with the Vigil',
      'next_id': 'x',
      'politics': {
        'standing': {'vigil': 5, 'dominion': -5},
      },
    });
    final hidden = StoryChoice.fromJson(const {
      'text': 'Say nothing',
      'next_id': 'x',
      'politics': {
        'standing': {'vigil': 5},
        'hidden': true,
      },
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Column(children: [
              Text('[${choicePoliticsHint(ref, choice)}]'),
              Text('<${choicePoliticsHint(ref, hidden)}>'),
            ]),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('[Veille +5 · Dominion −5]'), findsOneWidget);
    expect(find.text('<>'), findsOneWidget);
    await tester.runAsync(() => container
        .read(politicsHintsEnabledProvider.notifier)
        .setEnabled(false));
    await tester.pumpAndSettle();
    expect(find.text('[]'), findsOneWidget);
  });

  testWidgets(
      'Edit Mode: the Open Hand\'s stage, the events and "Fire now", the '
      'news in the log', (tester) async {
    _phone(tester, height: 2400);
    final container = await _container(tester,
        session: baseSession().copyWith(day: 6), loadClans: true);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen()),
    ));
    await tester.pumpAndSettle();
    final data = container.read(clanDataProvider);
    expect(data.openHand?.id, 'open_hand');

    // Standing: the lost clan, its stage and no meter.
    await tester.scrollUntilVisible(
        find.byKey(const Key('lost_clan_card_open_hand')), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('clans_standing_list')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Not remembered yet'), findsOneWidget);
    expect(find.byKey(const Key('lost_clan_silhouette_open_hand')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('open_hand_stage_3')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(container.read(playerSessionProvider).flags,
        ['open_hand_1', 'open_hand_2', 'open_hand_3']);
    expect(find.text('Remembrance 3/6'), findsOneWidget);
    expect(find.text('The Open Hand'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Politics: every event, fired or not, and Fire now.
    await tester.ensureVisible(find.byKey(const Key('clans_tab_politics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clans_tab_politics')));
    await tester.pumpAndSettle();
    final list = find
        .descendant(
            of: find.byKey(const Key('clans_politics_list')),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
        find.byKey(const Key('politics_event_fire_wharf_raid')), 200,
        scrollable: list);
    expect(find.byKey(const Key('clans_events_list')), findsOneWidget);
    expect(find.text('The Wharf raided again'), findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const Key('politics_event_state_wharf_raid')))
            .data,
        'Not yet');
    await tester
        .ensureVisible(find.byKey(const Key('politics_event_fire_wharf_raid')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('politics_event_fire_wharf_raid')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    final politics = container.read(playerSessionProvider).politics;
    expect(politics.hasFired('wharf_raid'), isTrue);
    expect(politics.news.single.eventId, 'wharf_raid');
    expect(
        tester
            .widget<Text>(
                find.byKey(const Key('politics_event_state_wharf_raid')))
            .data,
        startsWith('Fired: chapter'));
    expect(tester.takeException(), isNull);

    // Evolution: the event's line, its news under it.
    await tester.ensureVisible(find.byKey(const Key('clans_tab_evolution')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clans_tab_evolution')));
    await tester.pumpAndSettle();
    expect(find.text('News from the coast · The Wharf raided again'),
        findsWidgets);
    expect(find.text(politics.news.single.text), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      '"Your own hand" in an offer: its name and words, no tier, the '
      'Dominion\'s -2 once the banner is raised', (tester) async {
    _phone(tester);
    final container = await _container(tester,
        session: baseSession()
            .copyWith(flags: [...openHandFlagsUpTo(6), bannerRaisedFlag]),
        loadClans: true);
    final data = container.read(clanDataProvider);
    const ticket = OfferTicket(source: OfferSource.level);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SuitorCard(
              suitor: const Suitor(
                  factionId: 'open_hand',
                  gift: OfferGift(
                      kind: GiftKind.sign,
                      id: 'open_palm',
                      rarity: SignRarity.rare)),
              ticket: ticket,
              tables: OfferTables(data: data),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your own hand'), findsOneWidget);
    expect(find.textContaining('the old blood draws'), findsOneWidget);
    expect(find.text('Unknown'), findsNothing, reason: 'no standing tier');
    expect(find.textContaining('\u22122\u00a0Dominion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the codex: a silhouette with no name, then the Open Hand',
      (tester) async {
    _phone(tester);
    final container = await _container(tester,
        session: baseSession().copyWith(flags: const ['open_hand_1']),
        loadClans: true);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: ClansCodex()))),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lost_clan_silhouette_open_hand')),
        findsOneWidget);
    expect(find.text('A clan with no name'), findsOneWidget);
    expect(find.textContaining('Remembrance 1/6'), findsOneWidget);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .setOpenHandStage(2, data: container.read(clanDataProvider)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('lost_clan_silhouette_open_hand')), findsNothing);
    expect(find.text('The Open Hand'), findsOneWidget);
    expect(find.text('What is drawn, holds.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
