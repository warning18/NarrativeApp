// The fight screen's mark for the place's rule (context_rules.dart):
// its omen the round before it starts, then how far it has risen; the
// watch's whistle in a town; nothing for the Tide alone.
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/widgets/fight_markers.dart';

void main() {
  test('the Tide alone has no place mark', () {
    for (var round = 1; round < 14; round++) {
      expect(placeRuleStatus(ContextRule.tide, round), isNull);
    }
  });

  test('mist, heat and holy ground: omen at round 5, level from round 6', () {
    for (final (rule, stem) in [
      (ContextRule.marshMist, 'mist'),
      (ContextRule.desertHeat, 'heat'),
      (ContextRule.sanctified, 'holy'),
    ]) {
      for (var round = 1; round < 5; round++) {
        expect(placeRuleStatus(rule, round), isNull, reason: '$stem $round');
      }
      expect(placeRuleStatus(rule, 5),
          PlaceRuleStatus(stem, level: 0, omen: true));
      expect(placeRuleStatus(rule, 6),
          PlaceRuleStatus(stem, level: 1, omen: false));
      expect(placeRuleStatus(rule, 9),
          PlaceRuleStatus(stem, level: 4, omen: false),
          reason: 'one more level each round');
    }
  });

  test('rising water: omen the round before the Tide, three levels at most',
      () {
    const rule = ContextRule.risingWater;
    expect(placeRuleStatus(rule, waterStartRound - 2), isNull);
    expect(placeRuleStatus(rule, waterStartRound - 1),
        const PlaceRuleStatus('water', level: 0, omen: true));
    expect(placeRuleStatus(rule, waterStartRound)!.level, 1);
    expect(placeRuleStatus(rule, waterStartRound + 1)!.level, 2);
    final top = placeRuleStatus(rule, waterStartRound + 2)!;
    expect(top.level, waterMaxLevel);
    expect(top.maxed, isTrue);
    expect(placeRuleStatus(rule, waterStartRound + 9)!.level, waterMaxLevel,
        reason: 'it stays at the top');
    expect(placeRuleStatus(rule, waterStartRound + 1)!.maxed, isFalse);
  });

  test('the watch: its whistle the round before, then the fight is over', () {
    const rule = ContextRule.townGuards;
    expect(placeRuleStatus(rule, 4), isNull);
    expect(placeRuleStatus(rule, risingStartRound - 1),
        const PlaceRuleStatus('guards', level: 0, omen: true));
    expect(placeRuleStatus(rule, risingStartRound), isNull,
        reason: 'the watch has come; the log tells it');
  });

  test('every rule’s mark and tip are written in both languages', () {
    for (final stem in ['mist', 'heat', 'water', 'holy', 'guards']) {
      for (final key in [
        'context_${stem}_mark',
        'context_${stem}_omen_mark',
        'context_${stem}_tip',
      ]) {
        for (final lang in AppLanguage.values) {
          final text = trFor(lang, key);
          expect(text, isNot(key), reason: '$key in ${lang.name}');
          expect(text.trim(), isNotEmpty);
        }
      }
      // Every rule has a look.
      final (_, colour) = placeRuleLook(stem);
      expect(colour.a, 1);
    }
    for (final key in ['boss_enraged_mark', 'boss_enraged_tip']) {
      for (final lang in AppLanguage.values) {
        expect(trFor(lang, key), isNot(key));
      }
    }
  });
}
