// QA guard (the rank-up cards, v2.4.0): Core's tower_rank_up_test holds the
// rule on one hero; this plays the bot over many climbs (every race and
// calling it picks) and holds what must be true of every run: a rank-up taken
// is for a real skill, a skill is never ranked past the
// last tier, the tiers the hero has are exactly the rank-ups taken, the fight
// is given those tiers (the session), a run is saved and read back with its
// rank-ups, and the card has its words in both languages. It also holds that
// the feature is alive: rank-ups do appear in a batch.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart' show maxSkillTier;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

void main() {
  final data = towerDataFromAssets();
  // Seeds 1 to 150, with no unlocks and the defaults of a new player.
  final runs = playTowerBatch(List.generate(150, (i) => i + 1), data);

  test('a rank-up taken is for a real skill; the tiers are the rank-ups', () {
    var rankUps = 0;
    var runsWith = 0;
    var off = 0;
    for (final run in runs) {
      final taken = [
        for (final r in run.taken.values)
          if (r.kind == TowerRewardKind.rankUp) r.id
      ];
      if (taken.isNotEmpty) runsWith++;
      rankUps += taken.length;
      final hero = towerHeroOf(run, data);
      final perSkill = <String, int>{};
      for (final id in taken) {
        perSkill[id] = (perSkill[id] ?? 0) + 1;
      }
      perSkill.forEach((id, n) {
        expect(data.skills[id], isA<Map>(),
            reason: 'seed ${run.seed}: rank-up of "$id", not a skill');
        expect(n, lessThanOrEqualTo(maxSkillTier),
            reason: 'seed ${run.seed}: "$id" ranked up $n times (max '
                '$maxSkillTier)');
        expect(hero.skillTiers[id], n,
            reason: 'seed ${run.seed}: "$id" has tier ${hero.skillTiers[id]} '
                'after $n rank-ups');
        if (!hero.diceSkillAssignments.values.contains(id)) off += n;
      });
      for (final e in hero.skillTiers.entries) {
        expect(e.value, inInclusiveRange(0, maxSkillTier),
            reason: 'seed ${run.seed}: tier of ${e.key}');
        expect(perSkill[e.key] ?? 0, e.value,
            reason: 'seed ${run.seed}: ${e.key} has a tier no rank-up gave');
      }
      // The fight plays what the hero has.
      expect(towerSessionOf(run, data).skillTiers, hero.skillTiers,
          reason: 'seed ${run.seed}: the fight is not given the tiers');
    }
    expect(rankUps, greaterThan(0), reason: 'no rank-up in 150 climbs');
    // Known and filed (#1147, Core): a later pick can re-place the die's
    // skills and take the face of a ranked one (about 18% of the rank-ups at
    // the end of a climb). A tripwire, not a rule: it must not grow past 35%.
    expect(off / rankUps, lessThan(0.35),
        reason: '$off of $rankUps rank-ups are on a skill off the die');
    expect(runsWith, greaterThan(5),
        reason: 'rank-ups in only $runsWith of 150 climbs');
  });

  test('a run with rank-ups is saved and read back as it was', () {
    final withUps = runs.where(
        (r) => r.taken.values.any((c) => c.kind == TowerRewardKind.rankUp));
    expect(withUps, isNotEmpty);
    for (final run in withUps.take(10)) {
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
      expect(
          towerHeroOf(back, data).skillTiers, towerHeroOf(run, data).skillTiers,
          reason: 'seed ${run.seed}: tiers lost across a save');
    }
  });

  test('the card has its words in English and French', () {
    for (final lang in AppLanguage.values) {
      final name = trFor(lang, 'tower_rank_up_name');
      for (final slot in const ['{skill}', '{from}', '{to}']) {
        expect(name, contains(slot), reason: '$lang name lacks $slot');
      }
      expect(trFor(lang, 'tower_kind_rank_up').trim(), isNotEmpty);
      expect(trFor(lang, 'tower_rank_up_text').trim(), isNotEmpty);
    }
    expect(trFor(AppLanguage.fr, 'tower_rank_up_text'),
        isNot(trFor(AppLanguage.en, 'tower_rank_up_text')),
        reason: 'the French text is the English one');
  });
}
