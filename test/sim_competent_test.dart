// The simulator's competent player (sim_policy.dart): the gear it wears,
// the die it rolls, the banner it takes and why; and the naive player, the
// CI bands' measure, unchanged.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_growth.dart';
import 'package:narrative_data_app/data/sim_policy.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _gear(String slot, {int attack = 0, int armor = 0}) => {
      'itemType': slot == 'Weapon' ? 'Weapon' : 'Armor',
      'isEquippable': true,
      'equipSlot': slot,
      'attackDamage': attack,
      'armor': armor,
      'cost': 10,
    };

final _items = <String, dynamic>{
  'rusty_sword': _gear('Weapon', attack: 1),
  'fine_sword': _gear('Weapon', attack: 4),
  'great_sword': _gear('Weapon', attack: 9),
  'leather': _gear('Top', armor: 1),
  'mail': _gear('Top', armor: 3),
  'set_blade': _gear('Weapon', attack: 2),
  'set_coat': _gear('Top', armor: 2),
};

final _sets = parseItemSets({
  'watch': {
    'setName': 'Watch',
    'itemIds': ['set_blade', 'set_coat'],
    'bonuses': [
      {'pieces': 2, 'attackDamage': 4, 'armor': 1},
    ],
  },
});

Map<String, dynamic> _face(String type, {int value = 1, String skill = ''}) => {
      'type': type,
      'value': value,
      'linkedSkillID': skill,
      'weight': 1.0,
      'element': 'None',
    };

final _dice = <String, dynamic>{
  'own_die': {
    'cost': 0,
    'professions': ['warrior'],
    'races': [],
    'faces': [
      _face('Attack'),
      _face('Attack'),
      _face('Defend'),
      _face('Skill', value: 0),
      _face('Skill', value: 0),
      _face('Skill', value: 0),
    ],
  },
  'war_die': {
    'cost': 50,
    'professions': ['warrior'],
    'races': [],
    'faces': [
      _face('Attack', value: 4),
      _face('Attack', value: 4),
      _face('Attack', value: 4),
      _face('Defend', value: 2),
      _face('Skill', value: 0),
      _face('Skill', value: 0),
    ],
  },
  'mage_die': {
    'cost': 10,
    'professions': ['mage'],
    'races': [],
    'faces': [for (var i = 0; i < 6; i++) _face('Attack', value: 9)],
  },
};

final _skills = <String, dynamic>{
  'warrior_cleave': {'damageMod': 3, 'damageMultiplier': 1.5},
  'human_grit': {'damageMod': 1, 'damageMultiplier': 1.0, 'healAmount': 2},
  'heavy_attack': {'damageMod': 1, 'damageMultiplier': 1.0},
};

SimGrowth _growth({SimPolicy policy = SimPolicy.competent}) {
  final character = SimCharacter.create(
    raceId: 'human',
    race: {'standardSkillID': 'human_grit'},
    professionId: 'warrior',
    profession: {
      'startingDiceId': 'own_die',
      'standardSkillID': 'warrior_cleave',
    },
    gameConfig: {'maxHealth': 30, 'baseDamage': 3},
    dice: _dice,
    spells: const {},
  )..policy = policy;
  return SimGrowth(
    mode: SimProgression.offers,
    tables: SimGrowthTables(
      items: _items,
      itemSets: _sets,
      skills: _skills,
      clans: ClanData.fromTables(
        factions: _table('factions'),
        subclans: _table('subclans'),
        relations: _table('relations'),
        titles: _table('titles'),
      ),
    ),
    character: character,
    policy: policy,
  );
}

StoryData _story() {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  return StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
}

// sim-tables-ok: specialisations: the frozen run's tuple and hash (S1 of
// docs/qa/chapter1-core.md) were pinned on the world before these five; Core
// replaces the pin with property checks, and the world goes with it.
final _tables = simTables(without: {
  'specialisations',
  'spec_variants',
  'skill_merges',
  'detour_scenes',
  'ports'
});

List<SimRunSummary> _warriorRun(SimPolicy policy) => simulatePlaythroughs(
      _story(),
      tables: _tables,
      gameConfig: _table('game_config'),
      plan: const [
        (strategy: SimStrategy.random, raceId: null, professionId: 'warrior'),
      ],
      seed: 7,
      policy: policy,
    );

/// A hash of the ways taken that does not change between Dart versions.
int _stableHash(Iterable<String> parts) {
  var h = 0x811c9dc5;
  for (final unit in parts.join('\n').codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xffffffff;
  }
  return h;
}

void main() {
  group('gear', () {
    test('the competent player wears the best piece per slot after a loot', () {
      final g = _growth();
      g.prepareForFight(inventory: ['rusty_sword', 'leather']);
      expect(g.character.equippedBySlot,
          {'Weapon': 'rusty_sword', 'Top': 'leather'});
      // The next loot brings better pieces: each slot takes its best.
      g.prepareForFight(
          inventory: ['rusty_sword', 'leather', 'fine_sword', 'mail']);
      expect(
          g.character.equippedBySlot, {'Weapon': 'fine_sword', 'Top': 'mail'});
      expect(g.character.ownedItemIds, contains('rusty_sword'));
    });

    test('the naive player is left as it was', () {
      final g = _growth(policy: SimPolicy.naive);
      g.prepareForFight(inventory: ['fine_sword', 'mail']);
      expect(g.character.equippedBySlot, isEmpty);
    });

    test('keeps a set bonus over a single upgrade it beats', () {
      final g = _growth();
      // set_blade + set_coat: 2 + 2 armor + the set's 4 attack and 1 armor
      // beat fine_sword + mail (4 attack, 3 armor).
      g.prepareForFight(
          inventory: ['fine_sword', 'mail', 'set_blade', 'set_coat']);
      expect(g.character.equippedBySlot,
          {'Weapon': 'set_blade', 'Top': 'set_coat'});
      // A sword far better than the set's bonus breaks it.
      g.prepareForFight(inventory: ['great_sword']);
      expect(g.character.equippedBySlot['Weapon'], 'great_sword');
      expect(simLoadoutValue(['set_blade', 'set_coat'], _items, _sets),
          greaterThan(simLoadoutValue(['fine_sword', 'mail'], _items, _sets)));
    });

    test('never wears what its stats do not allow', () {
      final items = {
        ..._items,
        'giant_axe': {..._gear('Weapon', attack: 20), 'reqStrength': 99},
      };
      final best = simBestLoadout(
        worn: const {},
        owned: ['fine_sword', 'giant_axe'],
        items: items,
        sets: _sets,
        canWear: (item) => ((item['reqStrength'] as num?) ?? 0) < 50,
      );
      expect(best, {'Weapon': 'fine_sword'});
    });
  });

  group('the die', () {
    test('the cup keeps the signature die; the best die owned is rolled', () {
      final g = _growth();
      final c = g.character;
      expect(c.diceId, 'own_die');
      expect(c.ownedDice.keys, ['own_die']);
      g.assignSkills();
      expect(c.diceSkillAssignments.values,
          containsAll(['warrior_cleave', 'human_grit']));
      final left = c.visitShop(
        {
          'diceStock': ['war_die', 'mage_die'],
        },
        _items,
        _dice,
        const {},
        200,
        skills: _skills,
        itemSets: _sets,
      );
      // The warrior's better die bought (never the mage's), the signature
      // die still owned, its skills placed on the new die's open faces.
      expect(left, 150);
      expect(c.ownedDice.keys, containsAll(['own_die', 'war_die']));
      expect(c.ownedDice.keys, isNot(contains('mage_die')));
      expect(c.diceId, 'war_die');
      expect(c.diceSkillAssignments.values,
          containsAll(['warrior_cleave', 'human_grit']));
      g.prepareForFight();
      expect(c.diceId, 'war_die');
    });

    test('merges only a recipe that raises the die', () {
      final skills = {
        ..._skills,
        'cleaving_grit': {'damageMod': 9, 'damageMultiplier': 2.0},
        'weak_merge': {'damageMod': 0, 'damageMultiplier': 1.0},
      };
      final faces = (_dice['own_die'] as Map)['faces'] as List;
      final good = simMergeWorthIt(
        merges: {
          'a': {
            'inputSkillIDs': ['warrior_cleave', 'human_grit'],
            'resultSkillID': 'weak_merge',
          },
          'b': {
            'inputSkillIDs': ['warrior_cleave', 'human_grit'],
            'resultSkillID': 'cleaving_grit',
          },
        },
        unlocked: {'warrior_cleave', 'human_grit'},
        faces: faces.cast<Map<String, dynamic>>(),
        current: const {},
        skills: skills,
        damage: 3,
      );
      expect(good?.result, 'cleaving_grit');
    });
  });

  group('the banner', () {
    test('never takes a gift that turns a clan it needs Hostile', () {
      final g = _growth();
      final data = g.tables.clans;
      // The Vigil backed; the Penitents, its ally, one step from Hostile;
      // the Compact, their rival, offers the strongest gift.
      g.politics = const PoliticsState(
          standings: {'vigil': 30, 'penitents': -24, 'compact': 0});
      const ticket = OfferTicket(source: OfferSource.level);
      const strong = Suitor(
          factionId: 'compact',
          gift: OfferGift(kind: GiftKind.spec, id: 'any_spec'));
      const weak = Suitor(
          factionId: 'vigil',
          gift: OfferGift(kind: GiftKind.title, id: 'any_title'));
      final after =
          acceptPolitics(strong, ticket, politics: g.politics, data: data)
              .politics;
      expect(after.tierOf('penitents', data).isAtLeast(StandingTier.resented),
          isFalse,
          reason: 'the Compact\'s banner would turn the Penitents Hostile');
      final pick = g.competentSuitor(
          const ClanOffer(ticket: ticket, suitors: [strong, weak]), ticket);
      expect(pick.suitor, weak);
      expect(pick.reason, contains('compact would turn penitents Hostile'));
      // With no clan backed, the strongest gift is taken.
      g.politics = const PoliticsState();
      final free = g.competentSuitor(
          const ClanOffer(ticket: ticket, suitors: [strong, weak]), ticket);
      expect(free.suitor, strong);
      expect(free.reason, startsWith('most power'));
    });

    test('a tie goes to the clan it stands closest to', () {
      final g = _growth();
      g.politics = const PoliticsState(standings: {'mire': 8, 'crows': 2});
      const ticket = OfferTicket(source: OfferSource.boss);
      const a = Suitor(
          factionId: 'crows',
          gift: OfferGift(kind: GiftKind.spec, id: 'spec_a'));
      const b = Suitor(
          factionId: 'mire',
          gift: OfferGift(kind: GiftKind.spec, id: 'spec_b'));
      final pick = g.competentSuitor(
          const ClanOffer(ticket: ticket, suitors: [a, b]), ticket);
      expect(pick.suitor, b);
      expect(pick.reason, contains('closest clan'));
    });
  });

  group('whole runs (seed 7, one warrior)', () {
    late SimRunSummary naive;
    late SimRunSummary competent;
    late SimRunSummary stubborn;
    setUpAll(() {
      naive = _warriorRun(SimPolicy.naive).single;
      competent = _warriorRun(SimPolicy.competent).single;
      stubborn = _warriorRun(SimPolicy.stubborn).single;
    });

    test('naive is unchanged: the run before the policy existed', () {
      // v1.562's numbers for this seed, before sim_policy.dart; re-pinned at
      // v1.577 when three scenes became two pages each (the run's dice move),
      // at v1.597 (the difficulty pass), at v1.601 (Vica, with her table) and at
      // v1.613 (the bosses in the full world: Aurel Vane is no longer a wall)
      // at v1.614 (the specialisations pass) and at v1.615 (the element
      // dice, weakness ×3).
      expect((
        naive.raceId,
        naive.finalLevel,
        naive.finalGold,
        naive.fightsWon,
        naive.fightsLost,
        naive.offers,
        naive.steps,
        naive.furthestChapter,
      ), (
        'dwarf',
        16,
        2412,
        27,
        62,
        32,
        269,
        8
      ));
      expect(_stableHash(naive.choicesTaken), _naiveChoicesHash);
    });

    test('every offer is taken, its banners and reason recorded', () {
      for (final run in [naive, competent]) {
        expect(run.offerPicks, hasLength(run.offers));
        for (final pick in run.offerPicks) {
          expect(pick.offered, isNotEmpty);
          expect(pick.offered, contains(pick.taken));
          expect(pick.reason, isNotEmpty);
          expect(pick.chapter, greaterThanOrEqualTo(1));
          expect(pick.source, isNotEmpty);
        }
      }
      expect(competent.offerPicks.map((p) => p.reason),
          everyElement(anyOf(contains('most power'), contains('closest'))));
    });

    test('the competent player wears gear and owns its signature die', () {
      expect(competent.gear, isNotEmpty);
      expect(competent.die, isNotEmpty);
    });

    test('the stubborn player keeps its starting gear and die', () {
      // A warrior starts with nothing worn and the starter die: the naive
      // player wears what it is given, the stubborn one never does.
      expect(naive.gear, isNotEmpty);
      expect(stubborn.gear, isEmpty);
      expect(stubborn.die, 'starter_die');
      expect(stubborn.offerPicks, hasLength(stubborn.offers));
    });
  });
}

/// _stableHash of the naive warrior's ways taken (seed 7), from v1.562;
/// re-pinned at v1.577 (three scenes became two pages each) and at v1.578
/// (the Wharf lists fewer entries) and at v1.597 (the difficulty pass:
/// smaller health on both sides, a weakness ×2) and at v1.601 (Vica joins
/// every hero).
const int _naiveChoicesHash = 3588117958;
