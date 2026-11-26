// The Tower's check plumbing (docs/simulation/tower-check-plumbing.md): a
// setback's and a parley's result carry the ability, the modifier and the DC
// the rule used; towerCheckResultOf turns a result into the main game's
// AbilityCheckResult (old saves rebuilt); the view's modifier is the roll's
// once no stat pick waits before it; towerChoiceOutcomesOf reads each
// event's choices from the view. No rule and no number moves.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/stat_rules.dart' show levelStatPicks;
import 'package:narrative_data_app/data/ability_check.dart' show checkPasses;
import 'package:narrative_data_app/data/tower/tower_bot.dart'
    show towerDataFromAssets;
import 'package:narrative_data_app/data/tower/tower_event_outcomes.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();

  /// [seed]'s run climbing [floor], the floors below won with no cards and
  /// their stat picks taken (the first offer each), at full health.
  TowerRun at(int seed, int floor, {int events = 1, String clanId = ''}) {
    final picks = (towerLevelAfter(floor - 1) - 1) * levelStatPicks;
    final run = towerStart(
            seed: seed,
            raceId: 'human',
            professionId: 'warrior',
            clanId: clanId,
            events: events,
            data: data)
        .copyWith(floor: floor, statPicks: List.filled(picks, 0));
    return run.copyWith(health: towerHeroOf(run, data).maxHealth);
  }

  List<(int, int)> floorsOf(TowerEventKind kind,
      {int count = 60, int events = 1}) {
    final found = <(int, int)>[];
    for (var seed = 1; found.length < count && seed < 3000; seed++) {
      for (var floor = 1; floor < towerTop; floor++) {
        if (towerEventKindOf(at(seed, floor, events: events)) == kind) {
          found.add((seed, floor));
        }
      }
    }
    return found;
  }

  final setbacks = floorsOf(TowerEventKind.test, count: 200);
  final parleys =
      floorsOf(TowerEventKind.parley, count: 200, events: towerPeacefulEvents);

  /// [run] won with full health, its Level Up picks taken (the first offer
  /// each): choosing its card.
  TowerRun wonAndLevelled(TowerRun run) {
    var won = towerAfterFight(run, data, won: true, healthLeft: run.health);
    while (towerPendingPicks(won) > 0) {
      won = towerTakeStatPick(won, data, 0);
    }
    return won;
  }

  test('a setback result carries the rule\'s ability, modifier and DC', () {
    expect(setbacks, isNotEmpty);
    for (final (seed, floor) in setbacks) {
      final won = wonAndLevelled(at(seed, floor));
      final next = towerPick(won, data, null);
      final result = next.lastEvent!;
      expect(result.kind, TowerEventKind.test);
      expect(result.ability, towerSetbackAbilityOf(floor));
      expect(result.dc, towerSetbackDcOf(floor));
      final hero = towerHeroOf(
          won.copyWith(status: TowerStatus.climbing, floor: floor + 1), data);
      expect(result.modifier,
          towerCheckModifierOf(hero, towerSetbackAbilityOf(floor)));
      expect(result.total, result.roll! + result.modifier!);
      expect(result.passed,
          checkPasses(result.roll!, result.modifier!, result.dc!));
    }
  });

  test('a parley result carries the rule\'s ability, modifier and DC', () {
    expect(parleys, isNotEmpty);
    for (final (seed, floor) in parleys) {
      final run = at(seed, floor, events: towerPeacefulEvents);
      final view = towerEventOf(run, data)!;
      final result = towerChooseParley(run, data, true).lastEvent!;
      expect(result.kind, TowerEventKind.parley);
      expect(result.ability, towerParleyAbilityOf(floor));
      expect(result.dc, towerSetbackDcOf(floor));
      expect(result.modifier, view.modifier);
      expect(view.picksBeforeCheck, 0);
      expect(result.total, result.roll! + result.modifier!);
    }
    // Sworn to the guardian's clan: no roll, nothing to show.
    final (seed, floor) = parleys.first;
    final run = at(seed, floor, events: towerPeacefulEvents);
    final sworn = at(seed, floor,
        events: towerPeacefulEvents, clanId: towerEventOf(run, data)!.clanId!);
    final passed = towerChooseParley(sworn, data, true).lastEvent!;
    expect(passed.roll, isNull);
    expect(passed.ability, isNull);
    expect(passed.modifier, isNull);
    expect(passed.dc, isNull);
    expect(towerCheckResultOf(passed), isNull);
  });

  test('the new keys round-trip; a result saved before reads them as null', () {
    const stored = TowerEventResult(
        kind: TowerEventKind.test,
        roll: 7,
        total: 13,
        ability: 'wisdom',
        modifier: 6,
        dc: 11,
        passed: true,
        from: 3,
        to: 4);
    final json =
        jsonDecode(jsonEncode(stored.toJson())) as Map<String, dynamic>;
    expect(json['ability'], 'wisdom');
    expect(json['mod'], 6);
    expect(json['dc'], 11);
    expect(TowerEventResult.fromJson(json), stored);

    // A save from before: no keys, the check rebuilt from the floor and the
    // total.
    final old = Map<String, dynamic>.of(json)
      ..remove('ability')
      ..remove('mod')
      ..remove('dc');
    final loaded = TowerEventResult.fromJson(old);
    expect(loaded.ability, isNull);
    expect(loaded.modifier, isNull);
    expect(loaded.dc, isNull);
    expect(loaded.toJson().keys, isNot(contains('mod')));
    final check = towerCheckResultOf(loaded)!;
    expect(check.ability, towerSetbackAbilityOf(3));
    expect(check.dc, towerSetbackDcOf(3));
    expect(check.modifier, 6);
    expect(check.roll, 7);
    expect(check.total, 13);

    // A whole run saved before.
    final run = at(1, 3).copyWith(lastEvent: loaded);
    final reloaded = TowerRun.fromJson(
        jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
    expect(reloaded.lastEvent, loaded);

    // A kind without a roll.
    for (final kind in [
      TowerEventKind.rival,
      TowerEventKind.shortcut,
      TowerEventKind.merchant,
      TowerEventKind.bargain
    ]) {
      expect(
          towerCheckResultOf(
              TowerEventResult(kind: kind, passed: true, from: 2, to: 4)),
          isNull);
    }
  });

  test('towerCheckResultOf matches the result, its success the pass', () {
    var nat1 = 0, nat20 = 0, checked = 0;
    void check(TowerEventResult result) {
      final c = towerCheckResultOf(result)!;
      expect(c.roll, result.roll);
      expect(c.modifier, result.modifier);
      expect(c.dc, result.dc);
      expect(c.ability, result.ability);
      expect(c.total, result.total);
      expect(c.success, result.passed);
      // The old save's rebuild gives the same check.
      final old = TowerEventResult(
          kind: result.kind,
          roll: result.roll,
          total: result.total,
          passed: result.passed,
          from: result.from,
          to: result.to);
      final o = towerCheckResultOf(old)!;
      expect((o.ability, o.roll, o.modifier, o.dc, o.success),
          (c.ability, c.roll, c.modifier, c.dc, c.success));
      if (c.roll == 1) {
        nat1++;
        expect(c.success, isFalse);
      }
      if (c.roll == 20) {
        nat20++;
        expect(c.success, isTrue);
      }
      checked++;
    }

    for (final (seed, floor) in setbacks) {
      check(towerPick(wonAndLevelled(at(seed, floor)), data, null).lastEvent!);
    }
    for (final (seed, floor) in parleys) {
      check(towerChooseParley(
              at(seed, floor, events: towerPeacefulEvents), data, true)
          .lastEvent!);
    }
    expect(checked, setbacks.length + parleys.length);
    expect(nat1, greaterThan(0));
    expect(nat20, greaterThan(0));
    // The natural rules on a made-up check too: a 1 that would reach the DC
    // fails, a 20 that would not passes.
    final one = towerCheckResultOf(const TowerEventResult(
        kind: TowerEventKind.test,
        roll: 1,
        total: 31,
        passed: false,
        from: 5,
        to: 3))!;
    expect(one.success, isFalse);
    final twenty = towerCheckResultOf(const TowerEventResult(
        kind: TowerEventKind.parley,
        roll: 20,
        total: 18,
        passed: true,
        from: 25,
        to: 26))!;
    expect(twenty.success, isTrue);
  });

  test('the preview\'s modifier is the roll\'s when no pick waits before it',
      () {
    var same = 0, differ = 0, waiting = 0;
    for (final (seed, floor) in setbacks) {
      final run = at(seed, floor);
      final before = towerEventOf(run, data)!;
      final won = wonAndLevelled(run);
      // Choosing, the Level Up done: no pick waits, the preview is exact
      // (a card never moves an ability).
      final choosing = towerEventOf(won, data)!;
      expect(choosing.kind, TowerEventKind.test);
      expect(choosing.picksBeforeCheck, 0);
      for (final index in [null, 0]) {
        final result = towerPick(won, data, index).lastEvent!;
        expect(result.modifier, choosing.modifier);
        expect(result.total, result.roll! + choosing.modifier!);
      }
      final result = towerPick(won, data, null).lastEvent!;
      // Before the fight: exact when no Level Up pick comes on the win.
      if (before.picksBeforeCheck == 0) {
        expect(result.modifier, before.modifier);
        same++;
      } else {
        waiting++;
        expect(
            before.picksBeforeCheck,
            towerPendingPicks(
                towerAfterFight(run, data, won: true, healthLeft: run.health)));
        if (result.modifier != before.modifier) {
          // The documented case: the floor's Level Up pick raised the
          // checked ability between the preview and the roll.
          expect(result.modifier, greaterThan(before.modifier!));
          differ++;
        }
      }
    }
    expect(same, greaterThan(0));
    expect(waiting, greaterThan(0));
    expect(differ, greaterThan(0));
  });

  group('towerChoiceOutcomesOf', () {
    test('a setback: a potion, or the fall', () {
      for (final (seed, floor) in setbacks.take(20)) {
        final view = towerEventOf(at(seed, floor), data)!;
        expect(towerChoiceOutcomesOf(view), [
          TowerChoiceOutcome(
              choiceKey: 'tower_event_pass', kind: 'potion', amount: view.gain),
          TowerChoiceOutcome(
              choiceKey: 'tower_event_fail', kind: 'fall', floor: view.fallTo),
        ]);
        expect(view.gain, 1);
      }
    });

    test('a parley: the landing and what it forgoes, or the fight', () {
      final (seed, floor) = parleys.first;
      final run = at(seed, floor, events: towerPeacefulEvents);
      final view = towerEventOf(run, data)!;
      expect(towerChoiceOutcomesOf(view), [
        TowerChoiceOutcome(
            choiceKey: 'tower_parley_pass', kind: 'land', floor: floor + 1),
        for (final what in towerParleyForgoes)
          TowerChoiceOutcome(
              choiceKey: 'tower_parley_pass', kind: 'forgo', id: what),
        TowerChoiceOutcome(
            choiceKey: 'tower_parley_fail', kind: 'fight', floor: floor),
        TowerChoiceOutcome(
            choiceKey: 'tower_parley_fight', kind: 'fight', floor: floor),
      ]);
      final sworn = towerEventOf(
          at(seed, floor, events: towerPeacefulEvents, clanId: view.clanId!),
          data)!;
      expect(sworn.oathPass, isTrue);
      expect(towerChoiceOutcomesOf(sworn).map((o) => o.choiceKey),
          isNot(contains('tower_parley_fail')));
    });

    test('a rival and a shortcut: the landing', () {
      final (rs, rf) = floorsOf(TowerEventKind.rival, count: 1).first;
      final rival = towerEventOf(at(rs, rf), data)!;
      expect(towerChoiceOutcomesOf(rival), [
        TowerChoiceOutcome(
            choiceKey: 'tower_event_rival_win',
            kind: 'land',
            amount: towerRivalRounds,
            floor: rf + 2),
        TowerChoiceOutcome(
            choiceKey: 'tower_event_rival_slow', kind: 'land', floor: rf + 1),
      ]);
      final (ss, sf) = floorsOf(TowerEventKind.shortcut, count: 1).first;
      final shortcut = towerEventOf(at(ss, sf), data)!;
      expect(towerChoiceOutcomesOf(shortcut), [
        TowerChoiceOutcome(
            choiceKey: 'tower_event_shortcut_win',
            kind: 'land',
            amount: shortcut.skip,
            floor: shortcut.landsOn),
        const TowerChoiceOutcome(
            choiceKey: 'tower_event_shortcut_lose', kind: 'endRun'),
        TowerChoiceOutcome(
            choiceKey: 'tower_shortcut_decline', kind: 'fight', floor: sf),
      ]);
    });

    test('a merchant and a bargain: the stock, the bargain\'s terms', () {
      TowerEventView? merchant, bargain;
      for (final (seed, floor) in [
        for (var s = 1; s < 400; s++)
          for (var f = 1; f < towerTop - 1; f++) (s, f)
      ]) {
        if (merchant != null && bargain != null) break;
        final run = at(seed, floor, events: towerPeacefulEvents)
            .copyWith(status: TowerStatus.choosing);
        final landed = towerOpenStore(
            run,
            run.copyWith(
                status: TowerStatus.climbing, floor: floor + 1, offer: []));
        if (landed.store == null) continue;
        final view = towerEventOf(landed, data)!;
        if (view.kind == TowerEventKind.merchant) merchant ??= view;
        if (view.kind == TowerEventKind.bargain) bargain ??= view;
      }
      expect(merchant, isNotNull);
      expect(bargain, isNotNull);
      final outcomes = towerChoiceOutcomesOf(merchant!);
      final items = [...merchant.stock!, merchant.boon!];
      expect(outcomes, hasLength(items.length * 2));
      for (final (i, item) in items.indexed) {
        expect(
            outcomes[2 * i],
            TowerChoiceOutcome(
                choiceKey: 'tower_stall_buy_${item.id}',
                kind: 'buy',
                amount: item.price,
                id: item.id));
        expect(outcomes[2 * i + 1].choiceKey, 'tower_stall_buy_${item.id}');
        expect(outcomes[2 * i + 1].amount, item.amount);
      }
      expect(outcomes[1].kind, 'heal');
      expect(outcomes[3].kind, 'potion');
      expect(outcomes[5].kind, 'boon');
      expect(towerChoiceOutcomesOf(bargain!), [
        TowerChoiceOutcome(
            choiceKey: 'tower_bargain_accept',
            kind: 'maxHealth',
            amount: bargain.maxHealthCost),
        TowerChoiceOutcome(
            choiceKey: 'tower_bargain_accept',
            kind: 'stat',
            amount: towerBargainPoints,
            id: bargain.stat),
        const TowerChoiceOutcome(
            choiceKey: 'tower_bargain_refuse', kind: 'none'),
      ]);
    });

    test('no event, no choice', () {
      expect(
          towerChoiceOutcomesOf(const TowerEventView(
              kind: null, floor: 4, revisit: true, setbacksLeft: 1)),
          isEmpty);
    });
  });
}
