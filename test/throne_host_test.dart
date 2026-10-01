// The Host in the last battles (v1.196): every faction's contingent in
// factions.json (its effects ones a fight really applies to the party,
// its words in both languages, its worth), a `hostFight` choice making
// its fights and its zone's the last battles, and the in-app simulator's
// model of it (the story's claim and muster, the Host's effects in a
// fight, a choice's gate).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_growth.dart';
import 'package:narrative_data_app/data/throne.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

/// The kinds a fight applies to the party (see fight_setup.dart and
/// signEffectsFor): no gold, no XP, nothing at sea.
const Set<SignEffectKind> _fightKinds = {
  SignEffectKind.strikeDamagePercent,
  SignEffectKind.strikeFlat,
  SignEffectKind.guardBlockPercent,
  SignEffectKind.guardFlat,
  SignEffectKind.guardHeal,
  SignEffectKind.guardRetaliate,
  SignEffectKind.mendPercent,
  SignEffectKind.spellDamagePercent,
  SignEffectKind.maxHealth,
  SignEffectKind.armor,
  SignEffectKind.critChance,
  SignEffectKind.dodgeChance,
  SignEffectKind.lifestealPercent,
  SignEffectKind.thorns,
  SignEffectKind.potionBonus,
  SignEffectKind.allyDamagePercent,
  SignEffectKind.partyStartBlock,
  SignEffectKind.startMomentum,
  SignEffectKind.killHeal,
  SignEffectKind.firstRoundDamagePercent,
  SignEffectKind.partyMaxHealthPercent,
  SignEffectKind.writFace,
  SignEffectKind.intentLookahead,
  SignEffectKind.compactEdge,
  SignEffectKind.emberFace,
};

/// What one point of a kind is worth to a late hero, in percent, as the
/// in-app simulator measured it for v1.196 (the damage a level-14 hero of
/// each profession deals before falling to the final boss, 1,500 fights
/// each): the balance the Host's contingents were written to. The kinds
/// the simulator cannot see (the party's, the telegraph's, a curse
/// lifted, a guard broken) count for nothing here.
const Map<SignEffectKind, double> _worthPerPoint = {
  SignEffectKind.writFace: 3.8,
  SignEffectKind.armor: 2.9,
  SignEffectKind.thorns: 1.8,
  SignEffectKind.dodgeChance: 1.55,
  SignEffectKind.guardHeal: 0.95,
  SignEffectKind.lifestealPercent: 0.86,
  SignEffectKind.partyMaxHealthPercent: 0.8,
  SignEffectKind.spellDamagePercent: 0.38,
  SignEffectKind.strikeDamagePercent: 0.36,
  SignEffectKind.potionBonus: 0.24,
  SignEffectKind.maxHealth: 0.16,
  SignEffectKind.partyStartBlock: 0.15,
};

double _worth(List<SignEffect> effects) => effects.fold(
    0.0, (sum, e) => sum + (_worthPerPoint[e.kind] ?? 0) * e.value);

void main() {
  final data = ClanData.fromTables(
    factions: _gamedata('factions.json'),
    subclans: _gamedata('subclans.json'),
    relations: _gamedata('relations.json'),
    titles: _gamedata('titles.json'),
  );

  group('factions.json\'s Host', () {
    test('every faction brings a contingent a fight applies', () {
      expect(data.factions, isNotEmpty);
      for (final faction in data.factions.values) {
        final host = faction.host;
        expect(host, isNotNull, reason: faction.id);
        expect(host!.unknownEffectKinds, isEmpty, reason: faction.id);
        expect(host.effects, isNotEmpty, reason: faction.id);
        for (final effect in host.effects) {
          expect(_fightKinds, contains(effect.kind),
              reason: '${faction.id}: ${effect.kind}');
          expect(effect.value, greaterThan(0), reason: faction.id);
        }
        expect(host.line.trim(), isNotEmpty, reason: faction.id);
        expect(host.lineFr.trim(), isNotEmpty, reason: faction.id);
        expect(host.lineFr, isNot(host.line), reason: faction.id);
      }
    });

    test(
        'each contingent is worth about five percent, a full Host about '
        'thirty', () {
      for (final faction in data.factions.values) {
        expect(_worth(faction.host!.effects), inInclusiveRange(3.5, 6.5),
            reason: faction.id);
      }
      double hostWorth(List<String> ids, int houses) => _worth([
            for (final id in ids) ...data.faction(id)!.host!.effects,
            ...houseEffects(houses),
          ]);
      // A typical Host: the banner, one or two allies, two or three Houses.
      expect(hostWorth(['compact', 'vigil'], 2), inInclusiveRange(8, 15));
      expect(hostWorth(['dominion', 'crows', 'mire'], 3),
          inInclusiveRange(10, 18));
      // A full one: the banner, four allies, six Houses.
      expect(hostWorth(['vigil', 'compact', 'penitents', 'giants', 'choir'], 6),
          inInclusiveRange(22, 34));
      expect(
          hostWorth(
              ['open_hand', 'vigil', 'penitents', 'tidekin', 'kindly'], 6),
          inInclusiveRange(22, 34));
    });
  });

  group('a hostFight choice', () {
    test('makes its fight one of the last battles', () {
      final plain = StoryChoice.fromJson({
        'text': 'Fight',
        'next_id': '2',
        'triggerEnemyId': 'void_sovereign',
      });
      final last = StoryChoice.fromJson({
        'text': 'Lead the Host',
        'next_id': '2',
        'triggerEnemyId': 'tear_herald',
        'hostFight': true,
      });
      expect(EncounterModifiers.fromChoice(plain).hostFight, isFalse);
      expect(EncounterModifiers.fromChoice(plain).isDefault, isTrue);
      final modifiers = EncounterModifiers.fromChoice(last);
      expect(modifiers.hostFight, isTrue);
      expect(modifiers.isDefault, isFalse);
      // A zone's tier and chapter keep it; a zone launched by one makes
      // its boss one too.
      expect(modifiers.copyWith(chapter: 8).hostFight, isTrue);
      expect(
          EncounterModifiers.zoneBoss(chapter: 8)
              .copyWith(hostFight: true)
              .hostFight,
          isTrue);
      // With a defeat branch it is still both.
      final withLoss = EncounterModifiers.fromChoice(StoryChoice.fromJson({
        'text': 'Hold',
        'next_id': '2',
        'triggerEnemyId': 'tear_herald',
        'loseNextId': '3',
        'hostFight': true,
      }));
      expect(withLoss.lossContinues, isTrue);
      expect(withLoss.hostFight, isTrue);
    });
  });

  group('the simulator\'s Host', () {
    final tables = SimGrowthTables(
      skills: _gamedata('skills.json'),
      skillTrees: _gamedata('skill_trees.json'),
      items: _gamedata('items.json'),
      spells: parseSpells(_gamedata('spells.json')),
      patrons: parsePatrons(_gamedata('factions.json')),
      signs: parseSigns(_gamedata('signs.json')),
      clans: data,
    );
    SimGrowth growth() => SimGrowth(
          mode: SimProgression.offers,
          tables: tables,
          character: SimCharacter.create(
            raceId: 'human',
            race: _gamedata('races.json')['human'] as Map<String, dynamic>,
            professionId: 'warrior',
            profession: _gamedata('professions.json')['warrior']
                as Map<String, dynamic>,
            gameConfig: _gamedata('game_config.json'),
            dice: _gamedata('dice.json'),
            spells: parseSpells(_gamedata('spells.json')),
          ),
        );

    test('the story\'s claim, crown and muster reach its politics', () {
      final g = growth();
      var flags = g.applyStoryPolitics(
          StoryPolitics.tryParse({
            'claim': 'vigil',
            'pledge': 'giants',
            'marks': {'stitchers': 'friend', 'quarrymen': 'friend'},
          })!,
          flags: const ['x'],
          chapter: 6,
          key: 'story:a:choice0');
      expect(g.politics.claim, 'vigil');
      expect(flags, containsAll(['x', 'claim_vigil', 'pledged_giants']));
      // Once under its key.
      final again = g.applyStoryPolitics(
          StoryPolitics.tryParse({'pledge': 'oni'})!,
          flags: flags,
          chapter: 6,
          key: 'story:a:choice0');
      expect(again, flags);
      flags = g.applyStoryPolitics(
          StoryPolitics.tryParse({'throneWinner': 'vigil', 'muster': true})!,
          flags: flags,
          chapter: 8);
      expect(g.politics.host.mustered, isTrue);
      expect(g.host.banner, 'vigil');
      expect(g.host.allies, contains('giants'));
      expect(g.host.houses, containsAll(['stitchers', 'quarrymen']));
      expect(flags, containsAll(['on_throne', 'host_vigil', 'host_giants']));
      // The throne's title, worn.
      final throneTitles = throneTitlesOf('vigil', data);
      if (throneTitles.isNotEmpty) {
        expect(g.activeTitle, throneTitles.first.id);
      }
    });

    test('a last battle fights with the Host, any other without it', () {
      final g = growth();
      g.applyStoryPolitics(
          StoryPolitics.tryParse({
            'claim': 'compact',
            'marks': {'stitchers': 'friend', 'quarrymen': 'friend'},
          })!,
          flags: const [],
          chapter: 7);
      final plain = g.effects(0);
      final last = g.effects(0, host: true);
      expect(last.armor, greaterThan(plain.armor));
      expect(
          last.partyMaxHealthPercent, greaterThan(plain.partyMaxHealthPercent));
      expect(last.compactEdge, greaterThan(plain.compactEdge));
    });

    test('a choice behind a politics gate waits for it', () {
      final g = growth();
      final choice = StoryChoice.fromJson({
        'text': 'Walk before us',
        'next_id': '2',
        'politicsIf': {
          'rungAtLeast': {'penitents': 1}
        },
      });
      expect(g.gateOpen(choice, flags: const [], chapter: 5), isFalse);
      g.applyStoryPolitics(
          StoryPolitics.tryParse({
            'marks': {'spire_fallen': 'friend'}
          })!,
          flags: const [],
          chapter: 5);
      expect(g.gateOpen(choice, flags: const [], chapter: 5), isTrue);
    });
  });
}
