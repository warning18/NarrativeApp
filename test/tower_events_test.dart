// The Tower's floor events (floor events PR 1,
// docs/proposals/tower-snakes-and-ladders.md): a run with its events off (a
// save from before, or TowerRun.events 0) plays as before; a setback's test
// pays a potion or falls a few floors, never below the floor after the last
// gate, once a run; a rival beaten in time skips the next floor; a floor met
// again pays nothing; a fall never takes a level or a mark.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/fight_numbers.dart'
    show potionHealAmount;
import 'package:narrative_data_app/combat/stat_rules.dart' show levelStatPicks;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();

  bool isGate(int floor) => towerBudgetOf(floor).kind != TowerFloorKind.fight;

  TowerRun start(int seed, {int events = 1}) => towerStart(
      seed: seed,
      raceId: 'human',
      professionId: 'warrior',
      events: events,
      data: data);

  /// [seed]'s run standing on [floor] (climbing), the floors below won with
  /// no cards.
  TowerRun at(int seed, int floor, {int events = 1}) {
    final run = start(seed, events: events).copyWith(floor: floor);
    return run.copyWith(health: towerHeroOf(run, data).maxHealth);
  }

  /// The first floors of seeds 1.. holding an event of [kind].
  List<(int, int)> floorsOf(TowerEventKind kind, {int count = 40}) {
    final found = <(int, int)>[];
    for (var seed = 1; found.length < count && seed < 2000; seed++) {
      for (var floor = 1; floor < towerTop; floor++) {
        if (towerEventKindOf(at(seed, floor)) == kind) {
          found.add((seed, floor));
        }
      }
    }
    return found;
  }

  /// [run] won (rounds [rounds]) and moved on with no card.
  TowerRun winAndMove(TowerRun run, {int? rounds}) {
    final won = towerAfterFight(run, data,
        won: true, healthLeft: run.health, rounds: rounds);
    return towerPick(won, data, null);
  }

  group('a run with its events off', () {
    test('a save without the new keys loads, round-trips and has no events',
        () {
      final run = playTowerRun(seed: 3, data: data);
      final json = jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>;
      for (final key in ['crest', 'events', 'setbacks', 'last', 'shortcut']) {
        expect(json, isNot(contains(key)));
      }
      final loaded = TowerRun.fromJson(json);
      expect(loaded.crest, 0);
      expect(loaded.events, 0);
      expect(loaded.setbacks, 0);
      expect(loaded.lastEvent, isNull);
      expect(loaded.heightCleared, loaded.floorsCleared);
      expect(jsonEncode(loaded.toJson()), jsonEncode(json));
      // Mid-run: no event on any floor, and the floor plays as before.
      final mid = TowerRun.fromJson(
          jsonDecode(jsonEncode(at(5, 4, events: 0).toJson())));
      for (var floor = 1; floor <= towerTop; floor++) {
        final run = mid.copyWith(floor: floor);
        expect(towerEventOf(run, data), isNull);
        expect(towerEventKindOf(run), isNull);
      }
    });

    test('playTowerRun with no events writes none of the new keys', () {
      for (var seed = 1; seed <= 60; seed++) {
        for (final progress in [const TowerProgress(), towerAllUnlocked]) {
          final off = playTowerRun(seed: seed, data: data, progress: progress);
          final zero = playTowerRun(
              seed: seed, data: data, progress: progress, events: 0);
          final json = off.toJson();
          for (final key in [
            'crest',
            'events',
            'setbacks',
            'last',
            'shortcut'
          ]) {
            expect(json, isNot(contains(key)), reason: '$seed');
          }
          expect(jsonEncode(zero.toJson()), jsonEncode(json), reason: '$seed');
          expect(off.floorReached, off.floor);
          expect(
              off.marks, towerMarksOf(off.floorsCleared, off.refused.length));
        }
      }
    });

    test('the new fields round-trip through the save', () {
      final run = at(4, 7).copyWith(
          crest: 9,
          setbacks: 1,
          lastEvent: const TowerEventResult(
              kind: TowerEventKind.test,
              roll: 4,
              total: 9,
              passed: false,
              from: 9,
              to: 7));
      final loaded = TowerRun.fromJson(jsonDecode(jsonEncode(run.toJson())));
      expect(loaded.crest, 9);
      expect(loaded.events, 1);
      expect(loaded.setbacks, 1);
      expect(loaded.lastEvent, run.lastEvent);
      expect(loaded.heightCleared, 9);
      expect(loaded.copyWith(clearLastEvent: true).lastEvent, isNull);
      expect(loaded.copyWith(floor: 8).lastEvent, run.lastEvent);
    });
  });

  group('where events sit', () {
    test('never on a warden, a boss or the top; never on a floor met again',
        () {
      for (var seed = 1; seed <= 200; seed++) {
        for (var floor = 1; floor <= towerTop; floor++) {
          final run = at(seed, floor);
          final kind = towerEventKindOf(run);
          if (isGate(floor) || floor == towerTop) {
            expect(kind, isNull, reason: '$seed f$floor');
          }
          if (kind == TowerEventKind.rival || kind == TowerEventKind.shortcut) {
            // A skip fits: the floor skipped and the one landed on are
            // ordinary floors.
            expect(isGate(floor + 1) || isGate(floor + 2), isFalse);
            expect(floor + 2, lessThan(towerTop));
          }
          // Met again: no event, and the view says the floor pays nothing.
          final again = run.copyWith(crest: floor, setbacks: 1);
          expect(towerEventKindOf(again), isNull);
          final view = towerEventOf(again, data)!;
          expect(view.revisit, isTrue);
          expect(view.kind, isNull);
        }
      }
    });

    test(
        'about a tenth of floors a rival, a fifth a setback, less than '
        'a sixth a shortcut', () {
      var floors = 0, rivals = 0, tests = 0, shortcuts = 0;
      for (var seed = 1; seed <= 400; seed++) {
        for (var floor = 1; floor < towerTop; floor++) {
          if (isGate(floor)) continue;
          floors++;
          switch (towerEventKindOf(at(seed, floor))) {
            case TowerEventKind.rival:
              rivals++;
            case TowerEventKind.test:
              tests++;
            case TowerEventKind.shortcut:
              shortcuts++;
            case null:
          }
        }
      }
      expect(tests / floors, closeTo(towerSetbackShare, .02));
      // Only where a skip fits.
      expect(rivals / floors, inInclusiveRange(.05, towerRivalShare + .01));
      expect(
          shortcuts / floors, inInclusiveRange(.05, towerShortcutShare + .01));
    });
  });

  group('the setback', () {
    final tests = floorsOf(TowerEventKind.test);

    test('the view: the DC by floor, the odds, the fall shown before', () {
      expect(tests, isNotEmpty);
      for (final (seed, floor) in tests) {
        final run = at(seed, floor);
        final view = towerEventOf(run, data)!;
        expect(view.kind, TowerEventKind.test);
        expect(view.floor, floor);
        expect(view.revisit, isFalse);
        expect(view.setbacksLeft, 1);
        expect(view.dc, 10 + (floor - 1) ~/ 6);
        expect(view.ability, towerSetbackAbilities[(floor - 1) % 3]);
        expect(
            view.modifier, towerHeroOf(run, data).abilityBonus(view.ability!),
            reason: '$seed f$floor');
        expect(view.chance, inInclusiveRange(.05, .95));
        expect(view.gain, 1);
        expect(view.fallTo, inInclusiveRange(floor - 2, floor));
        expect(view.fallTo, greaterThanOrEqualTo(towerFloorAfterGate(floor)));
      }
    });

    test('pass: a potion; fail: down to the floor shown, once a run', () {
      var passes = 0, fails = 0;
      for (final (seed, floor) in tests) {
        final run = at(seed, floor);
        final view = towerEventOf(run, data)!;
        final next = winAndMove(run);
        final result = next.lastEvent!;
        expect(result.kind, TowerEventKind.test);
        expect(result.from, floor);
        // The roll reads the hero after the floor's picks and card.
        final modifier = towerHeroOf(next, data).abilityBonus(view.ability!);
        expect(result.total, result.roll! + modifier);
        expect(
            result.passed,
            result.roll == 20 ||
                (result.roll != 1 && result.total! >= view.dc!));
        if (result.passed) {
          passes++;
          expect(next.floor, floor + 1);
          expect(result.to, floor + 1);
          final won =
              towerAfterFight(run, data, won: true, healthLeft: run.health);
          expect(next.potions,
              won.potions < towerBagCap ? won.potions + 1 : towerBagCap);
          expect(next.setbacks, 0);
          expect(next.crest, 0);
        } else {
          fails++;
          expect(next.floor, view.fallTo);
          expect(result.to, view.fallTo);
          expect(next.crest, floor);
          expect(next.setbacks, 1);
          expect(next.heightCleared, floor);
          expect(next.marks, towerMarksOf(floor, next.refused.length));
          // None left: no test is offered again this run.
          for (var f = floor + 1; f < towerTop; f++) {
            expect(towerEventKindOf(next.copyWith(floor: f)),
                isNot(TowerEventKind.test));
          }
          final shown = towerEventOf(next, data)!;
          expect(shown.setbacksLeft, 0);
          expect(shown.result, result);
          expect(shown.revisit, isTrue);
        }
      }
      expect(passes, greaterThan(0));
      expect(fails, greaterThan(0));
    });

    test('a pass with the bag full: the potion is drunk', () {
      for (final (seed, floor) in tests) {
        final full = at(seed, floor);
        final run = full.copyWith(potions: towerBagCap, health: 10);
        final next = winAndMove(run);
        if (!next.lastEvent!.passed) continue;
        expect(next.potions, towerBagCap);
        final max = towerHeroOf(next, data).maxHealth;
        // The floor's own recovery, then the potion.
        final won = towerAfterFight(run, data, won: true, healthLeft: 10);
        expect(next.health, (won.health + potionHealAmount).clamp(1, max));
        return;
      }
      fail('no pass found');
    });
  });

  group('a floor met again', () {
    test('pays nothing: no spoils, card, healing, level or event', () {
      for (final (seed, floor) in floorsOf(TowerEventKind.test)) {
        final run = at(seed, floor);
        final fell = winAndMove(run);
        if (fell.lastEvent!.passed) continue;
        final before = towerHeroOf(fell, data);
        final picks = towerPendingPicks(fell);
        final again =
            towerAfterFight(fell, data, won: true, healthLeft: 10, rounds: 1);
        expect(again.status, TowerStatus.choosing);
        expect(again.offer, isEmpty);
        expect(again.health, 10);
        expect(again.spoils, fell.spoils);
        expect(again.lastEvent, isNull);
        expect(towerPendingPicks(again), picks);
        expect(towerHeroOf(again, data).maxHealth, before.maxHealth);
        expect(again.marks, fell.marks);
        final moved = towerPick(again, data, null);
        expect(moved.refused, fell.refused);
        expect(moved.floor, fell.floor + 1);
        expect(moved.crest, fell.crest);
        return;
      }
      fail('no fall found');
    });

    test('the bot\'s refight is a fresh fight', () {
      final run = at(3, 4).copyWith(crest: 6, setbacks: 1);
      expect(towerBotFightDraw(run), 4 + towerBotRevisitSalt);
      expect(towerBotFightDraw(at(3, 4)), 4);
    });
  });

  group('the rival', () {
    final rivals = floorsOf(TowerEventKind.rival, count: 20);

    test('the view: the rounds and the landing', () {
      expect(rivals, isNotEmpty);
      for (final (seed, floor) in rivals) {
        final view = towerEventOf(at(seed, floor), data)!;
        expect(view.kind, TowerEventKind.rival);
        expect(view.rounds, towerRivalRounds);
        expect(view.landsOn, floor + 2);
      }
    });

    test('won within 3 rounds: lands two floors up with the skipped levels',
        () {
      for (final (seed, floor) in rivals) {
        final run = at(seed, floor);
        final won = towerAfterFight(run, data,
            won: true, healthLeft: run.health, rounds: towerRivalRounds);
        expect(won.lastEvent!.passed, isTrue);
        final mid = towerPick(won, data, null);
        expect(mid.floor, floor + 2, reason: '$seed f$floor');
        expect(mid.crest, floor + 1);
        expect(mid.heightCleared, floor + 1);
        expect(mid.lastEvent!.to, floor + 2);
        expect(mid.spoils, isNot(contains(floor + 1)));
        expect(mid.taken, isNot(contains(floor + 1)));
        expect(mid.marks, towerMarksOf(floor + 1, mid.refused.length));
        // The skipped floor's level-ups: its picks wait, its health added.
        final earned = (towerLevelAfter(floor + 1) - 1) * levelStatPicks;
        expect(towerPendingPicks(mid), earned - mid.statPicks.length);
        final plain = towerPick(won.copyWith(clearLastEvent: true), data, null);
        final gain = towerHeroOf(mid, data).maxHealth -
            towerHeroOf(plain, data).maxHealth;
        expect(mid.health,
            (plain.health + gain).clamp(1, towerHeroOf(mid, data).maxHealth));
      }
    });

    test('more than 3 rounds, or not counted: the climb as usual', () {
      for (final (seed, floor) in rivals) {
        for (final rounds in [towerRivalRounds + 1, null]) {
          final run = at(seed, floor);
          final next = winAndMove(run, rounds: rounds);
          expect(next.floor, floor + 1);
          expect(next.crest, 0);
          expect(next.lastEvent!.passed, isFalse);
          expect(next.lastEvent!.to, floor + 1);
        }
      }
    });
  });

  group('the shortcut', () {
    final shortcuts = floorsOf(TowerEventKind.shortcut, count: 30);

    int nextGate(int floor) {
      var g = floor + 1;
      while (g < towerTop && !isGate(g)) {
        g++;
      }
      return g;
    }

    test('the view: the tougher foes, the skip, where it lands', () {
      expect(shortcuts, isNotEmpty);
      for (final (seed, floor) in shortcuts) {
        final run = at(seed, floor);
        final view = towerEventOf(run, data)!;
        final base = towerFloorsFor(seed, data.enemies)[floor - 1];
        expect(view.kind, TowerEventKind.shortcut);
        expect(view.lossEndsRun, isTrue);
        expect(view.accepted, isNull);
        expect(view.skip, inInclusiveRange(1, 3));
        expect(view.landsOn, floor + 1 + view.skip!);
        expect(view.landsOn, lessThan(nextGate(floor)));
        if (base.isPack || base.elite) {
          expect(view.foeIds, [...base.enemyIds, base.enemyIds.first]);
          expect(view.elite, isFalse);
        } else {
          expect(view.foeIds, base.enemyIds);
          expect(view.elite, isTrue);
        }
        // A floor met again offers none.
        expect(
            towerEventKindOf(run.copyWith(crest: floor, setbacks: 1)), isNull);
      }
    });

    test('chosen once, before the fight; taken, the fight is the tougher', () {
      final (seed, floor) = shortcuts.first;
      final run = at(seed, floor);
      final base = towerFloorsFor(seed, data.enemies)[floor - 1];
      expect(towerFloorOf(run, data).enemyIds, base.enemyIds);
      final taken = towerChooseShortcut(run, data, true);
      expect(taken.shortcut, isTrue);
      expect(towerEventOf(taken, data)!.accepted, isTrue);
      final fought = towerFloorOf(taken, data);
      expect(fought.enemyIds, towerEventOf(run, data)!.foeIds);
      expect(fought.elite, towerEventOf(run, data)!.elite);
      expect(fought.modifiersFor('warrior').forceElite, fought.elite);
      expect(towerChooseShortcut(taken, data, false).shortcut, isTrue);
      final declined = towerChooseShortcut(run, data, false);
      expect(declined.shortcut, isFalse);
      expect(towerFloorOf(declined, data).enemyIds, base.enemyIds);
      // Not offered: nothing to choose.
      final plain = at(seed, floor + 1);
      if (towerEventKindOf(plain) != TowerEventKind.shortcut) {
        expect(towerChooseShortcut(plain, data, true).shortcut, isNull);
      }
      expect(TowerRun.fromJson(jsonDecode(jsonEncode(taken.toJson()))).shortcut,
          isTrue);
    });

    test('taken and lost: the run ends', () {
      final (seed, floor) = shortcuts.first;
      final taken = towerChooseShortcut(at(seed, floor), data, true);
      final lost =
          towerAfterFight(taken, data, won: false, healthLeft: 0, rounds: 9);
      expect(lost.status, TowerStatus.dead);
    });

    test('declined: the climb as usual', () {
      for (final (seed, floor) in shortcuts) {
        final declined = towerChooseShortcut(at(seed, floor), data, false);
        final next = winAndMove(declined);
        expect(next.floor, floor + 1);
        expect(next.crest, 0);
        expect(next.shortcut, isNull);
      }
    });

    test('taken and won: its spoils and card, k floors up, a card on landing',
        () {
      var landingCards = 0;
      for (final (seed, floor) in shortcuts) {
        final run = at(seed, floor);
        final view = towerEventOf(run, data)!;
        final to = view.landsOn!;
        final taken = towerChooseShortcut(run, data, true);
        final won = towerAfterFight(taken, data,
            won: true, healthLeft: taken.health, rounds: 9);
        final plain =
            towerAfterFight(run, data, won: true, healthLeft: run.health);
        // The floor's own spoils and card.
        expect(won.spoils, plain.spoils);
        expect(won.offer.map((r) => r.toJson()).toList(),
            plain.offer.map((r) => r.toJson()).toList());
        final card = won.offer.isEmpty ? null : 0;
        var next = towerPick(won, data, card);
        if (card != null) expect(next.taken[floor], won.offer[0]);
        expect(next.shortcut, isNull);
        expect(next.crest, to - 1);
        expect(next.heightCleared, to - 1);
        expect(next.lastEvent!.kind, TowerEventKind.shortcut);
        expect(next.lastEvent!.to, to);
        for (var f = floor + 1; f < to; f++) {
          expect(next.spoils, isNot(contains(f)));
        }
        expect(
            towerPendingPicks(next),
            (towerLevelAfter(to - 1) - 1) * levelStatPicks -
                next.statPicks.length);
        if (next.status == TowerStatus.choosing) {
          // The card on landing: the floor below the landing deals it.
          landingCards++;
          expect(next.floor, to - 1);
          expect(next.offer, isNotEmpty);
          expect(towerIsShortcutLanding(next), isTrue);
          expect(towerIsRevisit(next), isFalse);
          expect(towerEventOf(next, data)!.kind, isNull);
          final offered = next.offer.first;
          next = towerPick(next, data, 0);
          expect(next.taken[to - 1], offered);
        }
        expect(next.status, TowerStatus.climbing);
        expect(next.floor, to);
        expect(next.crest, to - 1);
        expect(next.marks, towerMarksOf(to - 1, next.refused.length));
        expect(towerIsRevisit(next), isFalse);
      }
      expect(landingCards, greaterThan(0));
    });
  });

  test('the bot with events: runs end, levels and marks never drop', () {
    var fell = 0, skipped = 0, shortcuts = 0;
    for (var seed = 1; seed <= 40; seed++) {
      var height = 0, marks = 0, level = 1;
      final seen = <TowerRun>[];
      final run = playTowerRun(
          seed: seed,
          data: data,
          events: 1,
          choice: (run) {
            seen.add(run);
            expect(run.heightCleared, greaterThanOrEqualTo(height));
            expect(run.marks, greaterThanOrEqualTo(marks));
            final now = towerLevelAfter(run.heightCleared);
            expect(now, greaterThanOrEqualTo(level));
            height = run.heightCleared;
            marks = run.marks;
            level = now;
            if (towerIsRevisit(run)) expect(run.offer, isEmpty);
            return towerBotChoice(run);
          });
      expect(run.isOver, isTrue);
      expect(run.setbacks, lessThanOrEqualTo(towerSetbacksPerRun));
      expect(run.marks, greaterThanOrEqualTo(marks));
      if (run.setbacks > 0) fell++;
      if (seen.any((r) =>
          r.lastEvent?.kind == TowerEventKind.rival && r.lastEvent!.passed)) {
        skipped++;
      }
      if (seen.any((r) =>
          r.lastEvent?.kind == TowerEventKind.shortcut &&
          r.lastEvent!.passed)) {
        shortcuts++;
      }
    }
    expect(fell, greaterThan(0));
    expect(skipped, greaterThan(0));
    expect(shortcuts, greaterThan(0));
  });
}
