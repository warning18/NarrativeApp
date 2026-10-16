// The stat scale (docs/proposals/stat-scale.md, the user's decisions): one
// damage stat per profession, what each ability does in a fight
// (stat_rules.dart), the pick cards' lines (stat_pick_text.dart), and old
// saves rescaled once as they load (stat_scale_save.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/spells.dart' show baseMana;
import 'package:narrative_data_app/data/stat_pick_text.dart';
import 'package:narrative_data_app/data/stat_scale_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _fixture(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('the abilities in a fight', () {
    test('one damage stat per profession', () {
      expect(damageStatOf('warrior'), 'strength');
      expect(damageStatOf('ranger'), 'dexterity');
      expect(damageStatOf('rogue'), 'dexterity');
      expect(damageStatOf('mage'), 'intelligence');
      expect(damageStatOf('cleric'), 'intelligence');
      expect(damageStatOf(''), '');
    });

    test('the damage stat is base damage, Constitution health', () {
      expect(abilityGainEffects({'strength': 2, 'constitution': 1}, 'warrior'),
          (baseDamage: 2, maxHealth: 5));
      // Strength is not a rogue's damage.
      expect(abilityGainEffects({'strength': 2}, 'rogue'),
          (baseDamage: 0, maxHealth: 0));
      expect(abilityGainEffects({'dexterity': 1}, 'rogue'),
          (baseDamage: 1, maxHealth: 0));
    });

    test('Perception: a warrior blocks, a ranger or rogue crits and dodges',
        () {
      expect(blockChanceFor('warrior', 4), 12);
      expect(blockChanceFor('warrior', 40), blockCap);
      expect(blockChanceFor('rogue', 4), 0);
      expect(blockedBlow(7), 3);
      expect(perceptionCritBonus('ranger', 3), 3);
      expect(perceptionCritBonus('mage', 3), 0);
      expect(perceptionDodgeBonus('rogue', 3), 3);
      expect(perceptionDodgeBonus('warrior', 3), 0);
    });

    test('a session\'s gains bring their damage and health', () {
      final s = PlayerSession.fromJson({
        'professionId': 'warrior',
        'maxHealth': 26,
        'currentHealth': 20,
        'baseDamage': 3,
        'strength': 4,
      });
      final after = s.withAbilityGains({'strength': 2, 'constitution': 1});
      expect(after.strength, 6);
      expect(after.constitution, 1);
      expect(after.baseDamage, 5);
      expect(after.maxHealth, 31);
      expect(after.currentHealth, 25);
      // A mage's Wisdom is its mana, not its damage.
      final mage = PlayerSession.fromJson({'professionId': 'mage'})
          .withAbilityGains({'wisdom': 3});
      expect(mage.maxMana, baseMana + 3);
      expect(mage.baseDamage, 2);
    });
  });

  group('the pick cards', () {
    String en(String stat, String profession, [int n = 1]) =>
        statPickEffect(stat, profession, n, AppLanguage.en);

    test('the same ability reads by profession', () {
      expect(en('dexterity', 'rogue'), '+1 DEX: +1 damage, +2% dodge');
      expect(en('dexterity', 'warrior'), '+1 DEX: +2% dodge');
      expect(en('strength', 'warrior'), '+1 STR: +1 damage');
      expect(en('strength', 'mage'), '+1 STR: story checks');
      expect(en('intelligence', 'cleric'), '+1 INT: +1 damage');
      expect(en('constitution', 'mage'), '+1 CON: +5 health');
      expect(en('wisdom', 'cleric'), '+1 WIS: +1 mana');
      expect(
          en('perception', 'warrior'), '+1 PER: +3% block, reads foes better');
      expect(en('perception', 'ranger'),
          '+1 PER: +1% crit, +1% dodge, reads foes better');
      expect(en('luck', 'mage'), '+1 LUCK: +1.5% crit, rarer picks');
      expect(en('charisma', 'mage'), '+1 CHA: −2% shop prices');
    });

    test('a rarer pick reads its points', () {
      expect(en('dexterity', 'ranger', 2), '+2 DEX: +2 damage, +4% dodge');
      expect(en('luck', 'rogue', 3), '+3 LUCK: +4.5% crit, rarer picks');
      expect(
          statPickOfferEffect(
              {'strength': 2, 'constitution': 1}, 'warrior', AppLanguage.en),
          '+2 STR: +2 damage · +1 CON: +5 health');
    });

    test('in French', () {
      expect(statPickEffect('dexterity', 'rogue', 1, AppLanguage.fr),
          '+1 DEX: +1 dégâts, +2 % d’esquive');
      expect(statPickEffect('wisdom', 'mage', 1, AppLanguage.fr),
          '+1 SAG: +1 mana');
    });

    test('every ability has a line for every profession', () {
      for (final profession in [
        'warrior',
        'ranger',
        'rogue',
        'mage',
        'cleric'
      ]) {
        for (final stat in [
          'strength',
          'dexterity',
          'constitution',
          'intelligence',
          'wisdom',
          'perception',
          'luck',
          'charisma',
        ]) {
          expect(statPickEffects(stat, profession, 1), isNotEmpty,
              reason: '$profession $stat');
        }
      }
    });
  });

  group('an old save on the small scale', () {
    test('the numbers: a fifth, rounded, never to zero', () {
      expect(rescaleAmount(190), 38);
      expect(rescaleAmount(18), 4);
      expect(rescaleAmount(2), 1);
      expect(rescaleAmount(-12), -2);
      expect(rescaleAmount(0), 0);
      expect(rescaleAbility(4), 4);
      expect(rescaleAbility(29), 10);
      expect(picksFromOldPoints(0), 0);
      expect(picksFromOldPoints(1), 1);
      expect(picksFromOldPoints(5), 1);
      expect(picksFromOldPoints(7), 2);
      expect(rescaleCurrentHealth(151, 190, 38), 30);
      expect(rescaleCurrentHealth(0, 190, 38), 0);
      expect(rescaleCurrentHealth(1, 190, 38), 1);
    });

    for (final path in [
      'test/fixtures/session_v1_198.json',
      'test/fixtures/session_v1_204.json',
    ]) {
      test('$path becomes a sane level-9 hero, once', () {
        final raw = _fixture(path);
        expect(statScaleDue(raw), isTrue);
        final s = PlayerSession.fromJson(raw);
        // A level-9 warrior of the small scale: 190 health is 38, 151 is 30,
        // 18 damage is 4, 6 armor 1.
        expect(s.level, 9);
        expect(s.maxHealth, 38);
        expect(s.currentHealth, 30);
        expect(s.baseDamage, 4);
        expect(s.baseArmor, 1);
        // Its abilities were small enough to keep; its one point is a pick.
        expect(s.strength, raw['strength']);
        expect(s.statPoints, 1);
        expect(s.pendingStatPicks, 1);
        expect(s.statPickOffer, isEmpty);
        // An ally keeps its share of health; a full one stays full.
        for (final a in s.recruitedAllies) {
          final before = (raw['recruitedAllies'] as List)
                  .firstWhere((r) => (r as Map)['companionId'] == a.companionId)
              as Map;
          final hp = (before['currentHealth'] as num).toInt();
          expect(
              a.currentHealth,
              hp >= AllyState.fullHealthSentinel
                  ? AllyState.fullHealthSentinel
                  : rescaleAmount(hp),
              reason: a.companionId);
        }
        // Saved again, it is on the new version and never rescaled twice.
        final again = PlayerSession.fromJson(
            jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
        expect(s.toJson()['saveVersion'], statScaleSaveVersion);
        expect(again.maxHealth, 38);
        expect(again.baseDamage, 4);
        expect(again.currentHealth, 30);
      });
    }

    test('a later hero: its abilities shrink, its points become picks', () {
      final s = PlayerSession.fromJson({
        'saveVersion': 5,
        'level': 10,
        'professionId': 'rogue',
        'maxHealth': 353,
        'currentHealth': 353,
        'baseDamage': 32,
        'baseArmor': 2,
        'dexterity': 31,
        'luck': 6,
        'statPoints': 7,
        'statPickOffer': [
          {
            'path': 'duelist',
            'gains': {'baseDamage': 1},
          },
        ],
      });
      expect(s.maxHealth, 71);
      expect(s.currentHealth, 71);
      expect(s.baseDamage, 6);
      expect(s.baseArmor, 1);
      expect(s.dexterity, 10);
      expect(s.luck, 5);
      expect(s.statPoints, 2);
      expect(s.statPickOffer, isEmpty);
    });

    test('a session made in code (no version) is taken as it is', () {
      final s = PlayerSession.fromJson({'maxHealth': 100, 'baseDamage': 10});
      expect(s.maxHealth, 100);
      expect(s.baseDamage, 10);
    });
  });
}
