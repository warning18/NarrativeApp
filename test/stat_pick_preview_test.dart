// The Level Up cards' before -> after preview (stat_pick_text.dart's
// statPickPreview): which numbers a pick moves, per stat and calling, in
// the story and in the Tower, each equal to the fight's own formula.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/shop_pricing.dart';
import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/data/stat_pick_text.dart';
import 'package:narrative_data_app/data/training.dart' show statPickOdds;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

const callings = ['warrior', 'ranger', 'rogue', 'mage', 'cleric'];
const stats = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];

/// Every ability at 3: one point moves every check bonus (5 -> 6).
PlayerSession hero(String calling, [Map<String, dynamic> extra = const {}]) =>
    PlayerSession.fromJson({
      'professionId': calling,
      'maxHealth': 25,
      'currentHealth': 25,
      'baseDamage': 4,
      for (final s in stats) s: 3,
      ...extra,
    });

List<String> labels(StatPickPreview p) => [for (final r in p.rows) r.labelKey];

/// The rows a pick of one point should show, in order (see statPickPreview).
List<String> expected(String stat, String calling, {required bool tower}) {
  final damage = damageStatOf(calling) == stat;
  final sharp = calling == 'ranger' || calling == 'rogue';
  final fight = <String>[
    if (damage) 'stat_preview_damage',
    if (stat == 'constitution') 'stat_preview_max_health',
    if (stat == 'dexterity' || (stat == 'perception' && sharp))
      'stat_preview_dodge',
    if (stat == 'luck' || (stat == 'perception' && sharp)) 'stat_preview_crit',
    if (stat == 'perception' && calling == 'warrior') 'stat_preview_block',
    if (stat == 'wisdom') ...[
      'stat_preview_max_mana',
      'stat_preview_heal',
      'stat_preview_mana',
    ],
    if (stat == 'perception') 'stat_preview_read_foes',
  ];
  final checks = tower
      ? [
          if (['strength', 'dexterity', 'wisdom'].contains(stat))
            'stat_preview_tower_setback',
          if (['charisma', 'wisdom', 'dexterity'].contains(stat))
            'stat_preview_tower_parley',
        ]
      : ['stat_preview_story_checks'];
  return [
    ...fight,
    ...checks,
    if (stat == 'luck') 'stat_preview_rare_picks',
    if (stat == 'charisma' && !tower) 'stat_preview_shop',
  ];
}

void main() {
  group('the rows each stat shows', () {
    for (final tower in [false, true]) {
      for (final calling in callings) {
        for (final stat in stats) {
          test('${tower ? 'Tower' : 'story'}: $calling +1 $stat', () {
            final p = statPickPreview(hero(calling), stat, 1, tower: tower);
            expect(labels(p), expected(stat, calling, tower: tower));
            for (final r in p.rows) {
              expect(r.after, isNot(r.before), reason: '$r');
            }
          });
        }
      }
    }
  });

  group('the values are the fight\'s own', () {
    num value(StatPickPreview p, String key) =>
        p.rows.firstWhere((r) => r.labelKey == key).after;
    num was(StatPickPreview p, String key) =>
        p.rows.firstWhere((r) => r.labelKey == key).before;

    test('damage and health', () {
      final p = statPickPreview(hero('warrior'), 'strength', 2);
      expect(was(p, 'stat_preview_damage'), 4);
      expect(value(p, 'stat_preview_damage'),
          4 + abilityGainEffects({'strength': 2}, 'warrior').baseDamage);
      final c = statPickPreview(hero('mage'), 'constitution', 1);
      expect(was(c, 'stat_preview_max_health'), 25);
      expect(value(c, 'stat_preview_max_health'), 25 + healthPerConstitution);
    });

    test('dodge, crit and block', () {
      final rogue = statPickPreview(hero('rogue'), 'perception', 1);
      expect(was(rogue, 'stat_preview_dodge'),
          dodgeChanceFor(3, perception: 3, professionId: 'rogue'));
      expect(value(rogue, 'stat_preview_dodge'),
          dodgeChanceFor(3, perception: 4, professionId: 'rogue'));
      expect(was(rogue, 'stat_preview_crit'),
          criticalChanceFor(3) + perceptionCritBonus('rogue', 3));
      expect(value(rogue, 'stat_preview_crit'),
          criticalChanceFor(3) + perceptionCritBonus('rogue', 4));
      final luck = statPickPreview(hero('mage'), 'luck', 1);
      expect(was(luck, 'stat_preview_crit'), criticalChanceFor(3));
      expect(value(luck, 'stat_preview_crit'), criticalChanceFor(4));
      final warrior = statPickPreview(hero('warrior'), 'perception', 1);
      expect(
          was(warrior, 'stat_preview_block'), blockChanceWith('warrior', 3, 0));
      expect(value(warrior, 'stat_preview_block'),
          blockChanceWith('warrior', 4, 0));
      expect(value(warrior, 'stat_preview_read_foes'), 4);
    });

    test('Wisdom: mana, healing, the mana faces', () {
      final s = hero('cleric');
      final p = statPickPreview(s, 'wisdom', 1);
      expect(was(p, 'stat_preview_max_mana'), s.maxMana);
      expect(value(p, 'stat_preview_max_mana'), maxManaFor(wisdom: 4));
      expect(was(p, 'stat_preview_heal'), wisdomHealBonusFor(3));
      expect(value(p, 'stat_preview_heal'), wisdomHealBonusFor(4));
      expect(was(p, 'stat_preview_mana'), wisdomManaBonusFor(3));
      expect(value(p, 'stat_preview_mana'), wisdomManaBonusFor(4));
    });

    test('checks, rarer picks and the shop', () {
      final p = statPickPreview(hero('mage'), 'charisma', 1);
      expect(was(p, 'stat_preview_story_checks'), checkBonusFor(3));
      expect(value(p, 'stat_preview_story_checks'), checkBonusFor(4));
      expect(was(p, 'stat_preview_shop'),
          closeTo(charismaDiscountFor(3) * 100, 1e-9));
      expect(value(p, 'stat_preview_shop'),
          closeTo(charismaDiscountFor(4) * 100, 1e-9));
      final t = statPickPreview(hero('mage'), 'charisma', 1, tower: true);
      expect(value(t, 'stat_preview_tower_parley'), checkBonusFor(4));
      expect(t.noTowerEffect, isFalse);
      final luck = statPickPreview(hero('mage'), 'luck', 1);
      // The odds of a pick above Common: 10% and a point a Luck.
      expect(was(luck, 'stat_preview_rare_picks'),
          100 - statPickOdds(3)[SignRarity.common]!);
      expect(value(luck, 'stat_preview_rare_picks'),
          100 - statPickOdds(4)[SignRarity.common]!);
    });
  });

  group('caps and nothing to show', () {
    test('a dodge at its cap shows no dodge row', () {
      final p =
          statPickPreview(hero('warrior', {'dexterity': 13}), 'dexterity', 1);
      expect(dodgeChanceFor(13), dodgeCap);
      expect(labels(p), isNot(contains('stat_preview_dodge')));
    });

    test('a crit at its cap, rarer picks at theirs: Luck shows its check only',
        () {
      final p = statPickPreview(hero('mage', {'luck': 40}), 'luck', 1);
      expect(criticalChanceFor(40), critCap);
      expect(labels(p), isNot(contains('stat_preview_crit')));
      expect(labels(p), isNot(contains('stat_preview_rare_picks')));
      final t =
          statPickPreview(hero('mage', {'luck': 40}), 'luck', 1, tower: true);
      expect(t.rows, isEmpty);
      expect(t.noTowerEffect, isTrue);
    });

    test('Intelligence off the damage stat does nothing in the Tower', () {
      for (final calling in ['warrior', 'ranger', 'rogue']) {
        final p =
            statPickPreview(hero(calling), 'intelligence', 1, tower: true);
        expect(p.rows, isEmpty, reason: calling);
        expect(p.noTowerEffect, isTrue, reason: calling);
        // In the story it still counts for the checks.
        final story = statPickPreview(hero(calling), 'intelligence', 1);
        expect(labels(story), ['stat_preview_story_checks']);
        expect(story.noTowerEffect, isFalse);
      }
      final mage =
          statPickPreview(hero('mage'), 'intelligence', 1, tower: true);
      expect(mage.noTowerEffect, isFalse);
    });

    test('a known spell that scales with the stat shows its row', () {
      final spells = parseSpells({
        'spark': {
          'effect': 'Damage',
          'amount': 2,
          'scalingStat': 'intelligence',
        },
      });
      final s = hero('warrior', {
        'knownSpellIds': ['spark']
      });
      final p =
          statPickPreview(s, 'intelligence', 1, tower: true, spells: spells);
      expect(labels(p), ['stat_preview_spells']);
      expect(p.rows.single.before, max(0, 3) ~/ 4);
      expect(p.rows.single.after, 1);
      expect(p.noTowerEffect, isFalse);
    });
  });

  test('the old card lines keep the story\'s words; the Tower\'s own', () {
    expect(statPickEffect('charisma', 'warrior', 1, AppLanguage.en),
        '+1 CHA: −2% shop prices');
    expect(
        statPickEffect('charisma', 'warrior', 1, AppLanguage.en, tower: true),
        '+1 CHA: ${trFor(AppLanguage.en, 'stat_effect_tower_checks')}');
    expect(statPickEffects('intelligence', 'warrior', 1, tower: true), isEmpty);
    expect(statPickEffects('intelligence', 'warrior', 1), isNotEmpty);
  });

  test('every label has its English and French', () {
    for (final key in [...statPreviewLabelKeys, 'stat_effect_tower_checks']) {
      for (final lang in AppLanguage.values) {
        final text = trFor(lang, key);
        expect(text, isNotEmpty, reason: '$key $lang');
        expect(text, isNot(key), reason: '$key $lang');
      }
    }
  });
}
