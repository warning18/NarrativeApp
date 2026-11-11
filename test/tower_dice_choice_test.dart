// The Tower's dice bag (tower_dice.dart, the Tower review §1.5): a die
// gained goes to the bag, the player chooses the one in play
// (TowerRun.dieChoice), a save from before keeps the old automatic rule;
// and the Tower's own faces of its three dice (towerDieFaces), which the
// story's dice.json never sees.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sim_policy.dart'
    show simSkillAssignments;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_dice.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart' show diceSchema;
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/tower_fight_session.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

void main() {
  final data = towerDataFromAssets();
  final storyDice =
      jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
          as Map<String, dynamic>;

  // A human mage sworn to the Dominion from the start (the review's repro:
  // the automatic rule rolls the Dominion's die at once).
  TowerRun sworn() => towerStart(
      seed: 14,
      raceId: 'human',
      professionId: 'mage',
      clanId: 'dominion',
      data: data);
  final dominionDie = towerClanDieOf('dominion', data.dice)!;

  /// [run] on floor 1 won, [card] the one card on the table, taken.
  TowerRun taking(TowerRun run, TowerReward card) => towerPick(
      run.copyWith(status: TowerStatus.choosing, offer: [card]), data, 0);

  /// [run] as a save from before the bag: no 'die', no 'seen'.
  TowerRun oldSave(TowerRun run) => TowerRun.fromJson(
      {...run.toJson()}..removeWhere((k, _) => k == 'die' || k == 'seen'));

  test('a new run rolls its calling\'s die, seen; the start\'s dice wait', () {
    final run = sworn();
    expect(run.dieChoice, 'apprentice_die');
    expect(run.seenDieIds, {'apprentice_die'});
    final hero = towerHeroOf(run, data);
    expect(hero.diceId, 'apprentice_die');
    expect(hero.ownedDice.keys, contains(dominionDie));
  });

  test('a die gained goes to the bag; the die in play stays', () {
    final before = towerHeroOf(sworn(), data);
    final run = taking(
        sworn(), const TowerReward(TowerRewardKind.die, id: 'flame_die'));
    final hero = towerHeroOf(run, data);
    expect(hero.ownedDice.keys, contains('flame_die'));
    expect(hero.diceId, 'apprentice_die');
    expect(hero.diceFaces, before.diceFaces);
    expect(run.seenDieIds, isNot(contains('flame_die')));
  });

  test('towerChooseDie puts it in play, its skills placed, and seen', () {
    final run = towerChooseDie(sworn(), data, dominionDie);
    expect(run.dieChoice, dominionDie);
    expect(run.seenDieIds, containsAll(['apprentice_die', dominionDie]));
    final hero = towerHeroOf(run, data);
    expect(hero.diceId, dominionDie);
    expect(hero.diceFaces, data.facesOf(dominionDie));
    expect(
        hero.diceSkillAssignments,
        simSkillAssignments(
            faces: hero.diceFaces,
            current: const {},
            unlocked: hero.unlockedSkillIds,
            skills: data.skills));
    // A skill learned after the choice is placed on the chosen die.
    final skillId = data.skills.keys.firstWhere((id) =>
        !hero.unlockedSkillIds.contains(id) &&
        (data.skills[id] as Map)['restrictedProfessionID'] == 'mage');
    final later = towerHeroOf(
        taking(run, TowerReward(TowerRewardKind.skill, id: skillId)), data);
    expect(later.diceId, dominionDie);
    expect(later.unlockedSkillIds, contains(skillId));
    expect(
        later.diceSkillAssignments,
        simSkillAssignments(
            faces: later.diceFaces,
            current: const {},
            unlocked: later.unlockedSkillIds,
            skills: data.skills));
  });

  test('towerChooseDie: a die not owned, or a run over, changes nothing', () {
    final run = sworn();
    expect(identical(towerChooseDie(run, data, 'storm_die'), run), isTrue);
    final dead = run.copyWith(status: TowerStatus.dead);
    expect(identical(towerChooseDie(dead, data, dominionDie), dead), isTrue);
  });

  test('the choice and the dice seen survive the save', () {
    final run = towerChooseDie(sworn(), data, dominionDie);
    final json = run.toJson();
    expect(json['die'], dominionDie);
    expect(json['seen'], [...run.seenDieIds]..sort());
    final back = TowerRun.fromJson(jsonDecode(jsonEncode(json)));
    expect(back.dieChoice, dominionDie);
    expect(back.seenDieIds, run.seenDieIds);
    expect(towerHeroOf(back, data).diceId, dominionDie);
  });

  test('an old save rebuilds as before: the automatic rule, all seen', () {
    final old = oldSave(sworn());
    expect(old.dieChoice, isNull);
    expect(old.toJson().containsKey('die'), isFalse);
    expect(old.toJson().containsKey('seen'), isFalse);
    // The rule of before, by hand: each die gained rolled when the
    // simulator's worth rates it higher.
    final byHand = towerFreshHero('human', 'mage', const [], data)..potions = 0;
    towerApplyReward(byHand,
        const TowerReward(TowerRewardKind.clanOath, id: 'dominion'), data);
    final hero = towerHeroOf(old, data);
    expect(hero.diceId, byHand.diceId);
    expect(hero.diceId, dominionDie);
    expect(hero.diceSkillAssignments, byHand.diceSkillAssignments);
    expect([for (final d in towerDiceOf(old, data)) d.isNew],
        everyElement(isFalse));
    // Choosing takes it up: what it owned counts as seen.
    final chosen = towerChooseDie(old, data, 'apprentice_die');
    expect(chosen.dieChoice, 'apprentice_die');
    expect(towerHeroOf(chosen, data).diceId, 'apprentice_die');
    expect([for (final d in towerDiceOf(chosen, data)) d.isNew],
        everyElement(isFalse));
  });

  test('towerDiceOf: the die in play first, then by id; new and resonance', () {
    final run = taking(
        sworn(), const TowerReward(TowerRewardKind.die, id: 'flame_die'));
    final dice = towerDiceOf(run, data);
    expect(dice.first.id, 'apprentice_die');
    expect(dice.first.inPlay, isTrue);
    expect(dice.first.isNew, isFalse);
    final rest = [for (final d in dice.skip(1)) d.id];
    expect(rest, [...rest]..sort());
    expect(rest, containsAll(['flame_die', dominionDie]));
    expect(dice.skip(1).every((d) => !d.inPlay && d.isNew), isTrue);
    expect(dice.firstWhere((d) => d.id == 'flame_die').faces,
        data.facesOf('flame_die'));
    // The main clan's die resonates; the calling's die does not.
    expect(dice.firstWhere((d) => d.id == dominionDie).resonates, isTrue);
    expect(dice.first.resonates, isFalse);
    final chosen = towerDiceOf(towerChooseDie(run, data, dominionDie), data);
    expect(chosen.first.id, dominionDie);
    expect(chosen.first.inPlay, isTrue);
  });

  test('towerMarkDieSeen: a die no longer new; an old save is all seen', () {
    final run = sworn();
    final seen = towerMarkDieSeen(run, dominionDie);
    expect(seen.seenDieIds, containsAll(['apprentice_die', dominionDie]));
    expect(towerDiceOf(seen, data).every((d) => !d.isNew), isTrue);
    expect(identical(towerMarkDieSeen(seen, dominionDie), seen), isTrue);
    final old = oldSave(run);
    expect(identical(towerMarkDieSeen(old, dominionDie), old), isTrue);
  });

  test('the controller chooses a die and marks one seen, saved at once',
      () async {
    final start = sworn();
    SharedPreferences.setMockInitialValues(
        {towerRunPrefsKey: jsonEncode(start.toJson())});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final tower = container.read(towerProvider.notifier);
    while (container.read(towerProvider).value?.run == null) {
      await Future<void>.delayed(Duration.zero);
    }
    Future<TowerRun> saved() async => TowerRun.fromJson(jsonDecode(
        (await SharedPreferences.getInstance()).getString(towerRunPrefsKey)!));

    await tower.markDieSeen(dominionDie);
    expect((await saved()).seenDieIds, contains(dominionDie));
    expect((await saved()).dieChoice, 'apprentice_die');
    await tower.chooseDie(dominionDie, data: data);
    expect((await saved()).dieChoice, dominionDie);
    expect(container.read(towerProvider).value!.run!.dieChoice, dominionDie);
  });

  test(
      'the Tower rolls its own faces of its three dice; dice.json is as it '
      'was', () {
    expect(towerDieFaces.keys,
        unorderedEquals(['flame_die', 'tide_die', 'tearglass_die']));
    for (final id in towerDieFaces.keys) {
      final story = storyDice[id] as Map<String, dynamic>;
      final tower = data.facesOf(id);
      expect(tower, isNot(story['faces']), reason: id);
      // Its size and its faces' names kept: only types, values, counts.
      expect(tower.length, story['numberOfFaces'], reason: id);
      expect(tower.length, (story['faces'] as List).length, reason: id);
      final names = {for (final f in story['faces'] as List) f['faceName']};
      expect(names, containsAll({for (final f in tower) f['faceName']}),
          reason: id);
      // The fresh hero's start die rolls them too.
      expect(towerHeroOf(sworn(), data).ownedDice[id] ?? tower, tower);
    }
    // The others, and the story's own table, untouched.
    expect(data.facesOf('starter_die'),
        (storyDice['starter_die'] as Map)['faces']);
    final tables = {
      for (final name in TowerData.tableNames)
        name: jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>,
    };
    final story = jsonEncode(tables['dice']);
    TowerData.fromTables(tables);
    expect(jsonEncode(tables['dice']), story);
    expect(story, jsonEncode(storyDice));
  });

  testWidgets('the Tower\'s fight reads the Tower\'s dice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Map<String, dynamic>? raw, shown;
    await tester.pumpWidget(ProviderScope(
      child: TowerFightSession(sworn(), data).wrap(Consumer(
        builder: (context, ref, _) {
          raw = ref.watch(gameDbProvider(diceSchema)).value;
          shown = ref.watch(localizedDbProvider(diceSchema)).value;
          return const SizedBox();
        },
      )),
    ));
    for (final id in towerDieFaces.keys) {
      expect((raw![id] as Map)['faces'], data.facesOf(id), reason: id);
      expect([
        for (final f in (shown![id] as Map)['faces'] as List) f['value']
      ], [
        for (final f in data.facesOf(id)) f['value']
      ], reason: id);
    }
  });
}
