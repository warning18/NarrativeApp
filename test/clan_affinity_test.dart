// The clans' favorability matrix and the cards two clans, or one at
// Trusted, put on the table (v1.232): the real data is consistent (every
// clan favors a people and a class, every people two clans), the 20
// fusions and ascensions are well formed and reachable, a fusion needs
// both parents and both clans at Known and raises both, an ascension needs
// Trusted with its clan, and the Edit Mode tab shows the matrix.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/clan_affinity.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/utils/pixel_icons/skill_icons.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _clan(List<String> sponsors) => {
      'kind': 'clan',
      'name': 'N',
      'startStanding': 0,
      'lean': 0,
      'subclans': <String>[],
      'sponsors': sponsors,
      'objects': <Map<String, dynamic>>[],
      'greetings': ['Hail.'],
    };

/// Red and blue each sponsor one warrior branch; `fuse` needs a1 and b1,
/// `rise` raises a1.
final ClanData _data = ClanData.fromTables(
  factions: {
    'red': _clan(['warrior_a']),
    'blue': _clan(['warrior_b']),
  },
  subclans: {
    'red_sub': {'clan': 'red', 'name': 'Red Sub', 'lean': 0},
  },
  relations: const {},
  titles: const {},
);

const Map<String, dynamic> _trees = {
  'warrior_a': {
    'professionId': 'warrior',
    'skillIds': ['a1', 'a2'],
  },
  'warrior_b': {
    'professionId': 'warrior',
    'skillIds': ['b1', 'b2'],
  },
};

const Map<String, dynamic> _skills = {
  'a1': {'rarity': 'common'},
  'a2': {'rarity': 'rare'},
  'b1': {'rarity': 'common'},
  'b2': {'rarity': 'rare'},
  'fuse': {
    'rarity': 'epic',
    'restrictedProfessionID': 'warrior',
    'fusionOf': ['a1', 'b1'],
  },
  'rise': {
    'rarity': 'epic',
    'restrictedProfessionID': 'warrior',
    'ascendsSkillID': 'a1',
    'requiredSkillID': 'a1',
  },
  'subby': {
    'rarity': 'rare',
    'restrictedProfessionID': 'warrior',
    'subclanId': 'red_sub',
  },
  'secretly': {
    'rarity': 'epic',
    'restrictedProfessionID': 'warrior',
    'hiddenFlags': ['deed_done'],
    'hiddenClan': 'blue',
  },
};

PoliticsState _at(Map<String, num> values) {
  var state = PoliticsState.empty;
  values.forEach((id, v) {
    state = setStandingValue(state, id, v, 'edit', data: _data).state;
  });
  return state;
}

OfferContext _ctx(
        {Set<String> known = const {'a1', 'b1'},
        PoliticsState? politics,
        List<String> flags = const []}) =>
    OfferContext(
      data: _data,
      flags: flags,
      politics: politics ?? _at({'red': 30, 'blue': 30}),
      skills: _skills,
      skillTrees: _trees,
      raceId: 'human',
      professionId: 'warrior',
      knownSkillIds: known,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the real matrix', () {
    final data = ClanData.fromTables(
      factions: _json('factions'),
      subclans: _json('subclans'),
      relations: _json('relations'),
      titles: _json('titles'),
    );
    final trees = _json('skill_trees');
    final skills = _json('skills');
    final matrix = buildAffinityMatrix(
      data: data,
      skillTrees: trees,
      raceIds: _json('races').keys.toList(),
      professionIds: _json('professions').keys.toList(),
    );

    test('every clan favors a people and a class, every people has two', () {
      expect(matrix.issues(), isEmpty);
      expect(matrix.clanIds, hasLength(6));
      for (final race in matrix.raceIds) {
        expect(matrix.clansOfRace(race).length, greaterThanOrEqualTo(2),
            reason: race);
      }
      // The orphans have a home: voidkin with Crows, human with Penitents.
      expect(matrix.raceLevel('crows', 'voidkin'), 1);
      expect(matrix.raceLevel('penitents', 'human'), 1);
      expect(matrix.raceLevel('penitents', 'elf'), 1);
      // A class's three branches sit with three clans.
      for (final p in matrix.professionIds) {
        final total = matrix.clanIds
            .map((c) => matrix.professionLevel(c, p))
            .fold<int>(0, (a, b) => a + b);
        expect(total, 3, reason: p);
      }
    });

    test('the forty cards: fusions, ascensions, sub-clans and secrets', () {
      final cards =
          clanCardSkills(data: data, skills: skills, skillTrees: trees);
      int count(ClanCardKind k) => cards.where((c) => c.kind == k).length;
      expect(count(ClanCardKind.fusion), 10);
      expect(count(ClanCardKind.ascension), 10);
      expect(count(ClanCardKind.subclan), 10);
      expect(count(ClanCardKind.secret), 10);
      for (final card in cards) {
        final skill = skills[card.skillId] as Map<String, dynamic>;
        final branches = skillBranchesFor(trees,
            raceId: 'human', professionId: card.professionId);
        final onTree = {for (final b in branches) ...b.skillIds};
        expect(card.professionId, isNotEmpty, reason: card.skillId);
        for (final parent in card.parents) {
          expect(onTree, contains(parent), reason: card.skillId);
        }
        expect(skill['name_fr'], isNotEmpty);
        expect(skill['description_fr'], isNotEmpty);
        expect(skill['vfx'], isNotEmpty);
        switch (card.kind) {
          case ClanCardKind.ascension:
            expect(skill['rarity'], 'epic');
            expect(card.clanIds, hasLength(1), reason: card.skillId);
            expect(skill['requiredSkillID'], card.parents.single);
          case ClanCardKind.fusion:
            expect(skill['rarity'], 'epic');
            // Two clans, behind two different branches.
            expect(card.clanIds, hasLength(2), reason: card.skillId);
            expect(skill['requiredSkillID'], '');
          case ClanCardKind.subclan:
            expect(skill['rarity'], 'rare');
            expect(data.subclan(card.detail), isNotNull, reason: card.skillId);
            expect(card.clanIds, [data.subclan(card.detail)!.clanId]);
          case ClanCardKind.secret:
            expect(skill['rarity'], 'epic');
            expect(card.clanIds, hasLength(1), reason: card.skillId);
            expect(data.faction(card.clanIds.single)!.isClan, isTrue);
        }
      }
      // Two of each kind for each of the five classes.
      for (final p in matrix.professionIds) {
        for (final kind in ClanCardKind.values) {
          expect(cards.where((c) => c.professionId == p && c.kind == kind),
              hasLength(2),
              reason: '$p $kind');
        }
      }
    });

    test('every card has its own icon, not a borrowed one', () {
      for (final entry in skills.entries) {
        final skill = entry.value as Map<String, dynamic>;
        if (skill['fusionOf'] == null &&
            skill['ascendsSkillID'] == null &&
            skill['subclanId'] == null &&
            skill['hiddenFlags'] == null) {
          continue;
        }
        final path = 'assets/icons/skills/${entry.key}.png';
        expect(SkillIcons.pathFor(entry.key), path);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('every secret is revealed by a flag the story really sets', () {
      final story = jsonDecode(
              File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
      final set = <String>{};
      for (final node in story.values) {
        for (final c in (node['choices'] as List?) ?? const []) {
          for (final f in (c['flagsToAdd'] as List?) ?? const []) {
            set.add(f.toString());
          }
        }
      }
      for (final entry in skills.entries) {
        final flags = (entry.value as Map)['hiddenFlags'];
        if (flags is! List) continue;
        for (final f in flags) {
          expect(set, contains(f), reason: '${entry.key}: $f');
        }
      }
    });
  });

  group('fusions and ascensions', () {
    test('a fusion needs both parents and Trusted with both clans', () {
      expect(
          accordsFor('red', _ctx())
              .where((a) => a.skillId == 'fuse')
              .map((a) => (a.skillId, a.partnerId)),
          [('fuse', 'blue')]);
      expect(accordsFor('blue', _ctx()).map((a) => (a.skillId, a.partnerId)),
          [('fuse', 'red')]);
      List<String> fusions(String clan, PoliticsState politics,
              {Set<String> known = const {'a1', 'b1'}}) =>
          accordsFor(clan, _ctx(politics: politics, known: known))
              .where((a) => a.skillId == 'fuse')
              .map((a) => a.skillId)
              .toList();
      // A parent missing.
      expect(
          fusions('red', _at({'red': 30, 'blue': 30}), known: {'a1'}), isEmpty);
      // Unknown with one of the clans, or only Friend with it.
      expect(fusions('red', _at({'red': 30})), isEmpty);
      expect(fusions('blue', _at({'red': 30})), isEmpty);
      expect(fusions('red', _at({'red': 30, 'blue': 22})), isEmpty);
      // Already known.
      expect(
          fusions('red', _at({'red': 30, 'blue': 30}),
              known: {'a1', 'b1', 'fuse'}),
          isEmpty);
    });

    test('an ascension needs Friend with its clan alone, and offers one only',
        () {
      // Red is Friend (22), blue only Known: red offers the ascension, not
      // the fusion; blue sponsors nothing to raise.
      final friend = _ctx(politics: _at({'red': 22, 'blue': 10}));
      expect(accordsFor('red', friend).map((a) => a.skillId), ['rise']);
      expect(accordsFor('red', friend).single.partnerId, isEmpty);
      expect(accordsFor('blue', friend), isEmpty);
      // Friendly is not enough.
      expect(accordsFor('red', _ctx(politics: _at({'red': 15}))), isEmpty);
      // Both Trusted: the fusion joins it.
      expect(accordsFor('red', _ctx()).map((a) => a.skillId),
          containsAll(['fuse', 'rise']));
    });

    test('the clans behind a card are the clans behind its parents', () {
      final c = _ctx();
      List<String> sponsors(String id) => sponsorsOfSkill(id,
          data: _data,
          skillTrees: _trees,
          raceId: 'human',
          professionId: 'warrior',
          skills: _skills);
      expect(sponsors('fuse'), unorderedEquals(['red', 'blue']));
      expect(sponsors('rise'), ['red']);
      expect(c.tierOf('red'), StandingTier.trusted);
    });

    test('taking a fusion raises both clans, the second by half', () {
      final c = _ctx();
      final suitor = Suitor(
        factionId: 'red',
        gift: const OfferGift(
            kind: GiftKind.skill,
            id: 'fuse',
            rarity: SignRarity.epic,
            partnerId: 'blue'),
      );
      const ticket = OfferTicket(source: OfferSource.level);
      final taken =
          acceptPolitics(suitor, ticket, politics: c.politics, data: _data);
      expect(taken.politics.standingOf('red', _data),
          closeTo(c.politics.standingOf('red', _data) + 6, 0.01));
      expect(taken.politics.standingOf('blue', _data),
          closeTo(c.politics.standingOf('blue', _data) + 3, 0.01));
      final preview =
          suitorPreview(suitor, ticket, politics: c.politics, data: _data);
      expect(preview['red'], closeTo(6, 0.01));
      expect(preview['blue'], closeTo(3, 0.01));
      // The partner survives a save.
      expect(OfferGift.tryParse(suitor.gift.toJson()), suitor.gift);
    });

    test('a sub-clan skill needs the sub-clan a friend, and is voiced by it',
        () {
      List<String> subs(PoliticsState p) => accordsFor('red', _ctx(politics: p))
          .where((a) => a.skillId == 'subby')
          .map((a) => a.skillId)
          .toList();
      expect(subs(_at({'red': 30, 'blue': 30})), isEmpty,
          reason: 'not yet a friend');
      final friend = setSubclanMark(_at({'red': 30, 'blue': 30}), 'red_sub',
              SubclanMark.friend, 'edit',
              data: _data)
          .state;
      expect(subs(friend), ['subby']);
      // Only its own clan, and only from Known.
      expect(
          accordsFor('blue', _ctx(politics: friend))
              .where((a) => a.skillId == 'subby'),
          isEmpty);
      final unknown = setSubclanMark(_at({'red': 0, 'blue': 30}), 'red_sub',
              SubclanMark.friend, 'edit',
              data: _data)
          .state;
      expect(subs(unknown), isEmpty);
      // The card is voiced by the sub-clan.
      final suitor = drawSuitor('red', _ctx(politics: friend), Random(3),
          gift: const OfferGift(
              kind: GiftKind.skill, id: 'subby', rarity: SignRarity.rare));
      expect(suitor!.subclanId, 'red_sub');
      expect(
          sponsorsOfSkill('subby',
              data: _data,
              skillTrees: _trees,
              raceId: 'human',
              professionId: 'warrior',
              skills: _skills),
          ['red']);
    });

    test('a secret waits for its flags and is taught by its clan alone', () {
      List<String> secrets(String clan, List<String> flags) =>
          accordsFor(clan, _ctx(flags: flags))
              .where((a) => a.skillId == 'secretly')
              .map((a) => a.skillId)
              .toList();
      expect(secrets('blue', const []), isEmpty);
      expect(secrets('blue', ['deed_done']), ['secretly']);
      expect(secrets('red', ['deed_done']), isEmpty);
      // Hidden: no sponsor is shown for it.
      expect(
          sponsorsOfSkill('secretly',
              data: _data,
              skillTrees: _trees,
              raceId: 'human',
              professionId: 'warrior',
              skills: _skills),
          isEmpty);
    });

    test('a grown tree still has a home seat while a card is left', () {
      // Every branch skill known: only the fusion and the ascension remain.
      final grown = _ctx(
          known: {'a1', 'a2', 'b1', 'b2'},
          politics: _at({'red': 30, 'blue': 30}));
      expect(homeClansFor(grown).keys, unorderedEquals(['red', 'blue']));
      final random = Random(5);
      final seen = <String>{};
      for (var i = 0; i < 100; i++) {
        final seat = drawHomeSuitor(grown, random)!;
        expect(seat.gift.kind, GiftKind.skill);
        seen.add(seat.gift.id);
      }
      expect(seen, {'fuse', 'rise'});
    });
  });

  testWidgets('the Affinities tab shows the matrix and the cards at 360 px',
      (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(
        {'app_language': 'en', 'tutorial_enabled': false});
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
        skillsSchema,
        skillTreesSchema,
        professionsSchema,
        racesSchema,
      ]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
    });
    await tester.runAsync(() => notifier.loadSession(baseSession()));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ClansPoliticsScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('clans_tab_affinity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clans_tab_affinity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clans_affinity_matrix')), findsOneWidget);
    expect(
        find.byKey(const Key('affinity_cell_crows_voidkin')), findsOneWidget);
    expect(find.text('3/3'), findsNothing,
        reason: 'no clan sponsors a whole class');
    expect(find.byKey(const Key('clans_affinity_issue')), findsNothing);
    await tester.scrollUntilVisible(
        find.byKey(const Key('affinity_card_warrior_bastion_charge')), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.byKey(const Key('affinity_card_warrior_bastion_charge')),
        findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');
  });
}
