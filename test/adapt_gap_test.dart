// The element dice (v1.615, docs/proposals/difficulty-pass.md §8, option B
// chosen by the user): "you need to change your dice". Each elemental die
// carries its element on all its Attack faces and its element-less Skill
// faces, and a weakness takes ×3, so the die that matches a foe's weakness
// beats the starter die against it.
//
// Six set fights of chapters 3–6, one per weakness, hero + Vica, no gear,
// at each chapter's usual level, each profession holding its most common
// specialisation: the starter die, the matching die, and the same matching
// die with its elements taken off. Fights only (no story walk), seeded, so a
// story PR can't move it.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_companions.dart';
import 'package:narrative_data_app/data/sim_policy.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Each foe, its chapter, the usual level there, and the die carrying the
/// element it is weak to.
const _fights = [
  ('void_wisp', 3, 5, 'pilgrim_die'),
  ('inquisition_auxiliary', 3, 5, 'tempest_die'),
  ('compact_anvil_deaf_tove', 3, 5, 'tide_die'),
  ('catacomb_ghoul', 4, 9, 'flame_die'),
  ('drowned_pilgrim', 5, 12, 'tempest_die'),
  ('kraken_arm', 6, 16, 'flame_die'),
];

/// The specialisation each profession most often holds in the simulator's
/// walk (boss_balance_test's runs).
const _specs = {
  'warrior': 'briar_guard',
  'mage': 'burden_bearer',
  'rogue': 'fever_blade',
  'cleric': 'long_vigil',
  'ranger': 'trapwright',
};

const _tries = 60;

void main() {
  test('the die matching a weakness beats the starter die, by its element', () {
    final races = _table('races');
    final professions = _table('professions');
    final config = _table('game_config');
    final dice = _table('dice');
    final skills = _table('skills');
    final items = _table('items');
    final enemies = _table('enemies');
    final companions = _table('companions');
    final spells = parseSpells(_table('spells'));

    double rate(
        String profession, (String, int, int, String) fight, String dieId,
        {bool stripped = false}) {
      final (foe, chapter, level, _) = fight;
      var won = 0;
      for (var seed = 0; seed < _tries; seed++) {
        final hero = SimCharacter.create(
            raceId: 'human',
            race: races['human'] as Map<String, dynamic>,
            professionId: profession,
            profession: professions[profession] as Map<String, dynamic>,
            gameConfig: config,
            dice: dice,
            spells: spells);
        var xp = 0;
        for (var l = 1; l < level; l++) {
          xp += l * 100;
        }
        hero.gainXp(xp);
        hero.specIds = [_specs[profession]!];
        var faces = ((dice[dieId] as Map)['faces'] as List)
            .cast<Map<String, dynamic>>();
        if (stripped) {
          faces = [
            for (final f in faces) {...f, 'element': 'None'}
          ];
        }
        hero.diceFaces = faces;
        hero.diceSkillAssignments = simSkillAssignments(
            faces: faces,
            current: const {},
            unlocked: hero.unlockedSkillIds,
            skills: skills);
        final party = SimParty(
            companions: companions,
            races: races,
            professions: professions,
            gameConfig: config,
            dice: dice,
            skills: skills)
          ..levelIs(level);
        party.recruit('vica', chapter: chapter, cause: 'the story');
        final outcome = simulateSimFight(
            character: hero,
            enemies: [MapEntry(foe, enemies[foe] as Map<String, dynamic>)],
            chapter: chapter,
            skills: skills,
            items: items,
            random: Random(seed),
            allies: party.fightAllies());
        if (outcome.won) won++;
      }
      return won / _tries;
    }

    var starter = 0.0, matching = 0.0, stripped = 0.0;
    final cells = _specs.length * _fights.length;
    for (final profession in _specs.keys) {
      for (final fight in _fights) {
        starter += rate(profession, fight, 'starter_die') / cells;
        matching += rate(profession, fight, fight.$4) / cells;
        stripped += rate(profession, fight, fight.$4, stripped: true) / cells;
      }
    }
    final summary = 'starter ${starter.toStringAsFixed(2)}, matching '
        '${matching.toStringAsFixed(2)}, matching without its element '
        '${stripped.toStringAsFixed(2)}';
    // v1.615: about 0.23, 0.34 and 0.08.
    expect(matching, greaterThanOrEqualTo(starter + 0.08), reason: summary);
    expect(matching, greaterThanOrEqualTo(stripped + 0.10), reason: summary);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
