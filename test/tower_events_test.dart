// The Tower's floor events (floor events PR 1,
// docs/proposals/tower-snakes-and-ladders.md): a run with its events off (a
// save from before, or TowerRun.events 0) plays as before; a setback's test
// pays a potion or falls a few floors, never below the floor after the last
// gate, once a run; a rival beaten in time skips the next floor; a floor met
// again pays nothing; a fall never takes a level or a mark.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/fight_numbers.dart'
    show eliteStatMultiplier, potionHealAmount;
import 'package:narrative_data_app/combat/stat_rules.dart' show levelStatPicks;
import 'package:narrative_data_app/data/ability_check.dart' show checkChance;
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
  List<(int, int)> floorsOf(TowerEventKind kind,
      {int count = 40, int events = 1}) {
    final found = <(int, int)>[];
    for (var seed = 1; found.length < count && seed < 2000; seed++) {
      for (var floor = 1; floor < towerTop; floor++) {
        if (towerEventKindOf(at(seed, floor, events: events)) == kind) {
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
      for (final key in [
        'crest',
        'events',
        'setbacks',
        'last',
        'shortcut',
        'parley',
        'spent',
        'bought',
        'store',
        'bargains'
      ]) {
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
            'shortcut',
            'parley',
            'spent',
            'bought',
            'store',
            'bargains'
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

  test('a run with the events on fights at their own scale and extras', () {
    final off = towerFloorsFor(7, data.enemies);
    final on = towerFloorsFor(7, data.enemies, events: 1);
    for (var floor = 1; floor <= towerTop; floor++) {
      final a = off[floor - 1], b = on[floor - 1];
      expect(b.enemyIds, a.enemyIds);
      expect(a.extra, towerBudgetOf(floor).extra);
      expect(b.extra, towerEventsExtras[floor] ?? a.extra);
      expect(a.extraFor('mage'), a.extra * towerProfessionScaleOf('mage'));
      expect(b.extraFor('mage'),
          b.extra * towerProfessionScaleOf('mage', events: 1));
    }
    expect(towerProfessionScaleOf('warrior'),
        towerProfessionScale['warrior']! * towerFoeScale);
    expect(towerProfessionScaleOf('warrior', events: 1),
        towerProfessionScale['warrior']! * towerEventsFoeScale);
    // The app's floor follows the run's events.
    expect(towerFloorOf(at(7, 20), data).extra, on[19].extra);
    expect(towerFloorOf(at(7, 20, events: 0), data).extra, off[19].extra);
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
            case TowerEventKind.parley:
            case TowerEventKind.merchant:
            case TowerEventKind.bargain:
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
        // The same foes: a pack an Elite pack, a lone foe an Elite; a
        // pack or a lone Elite, the extra times the Elite's.
        final tough = towerShortcutFloor(base);
        expect(view.foeIds, base.enemyIds);
        expect(view.elite, !base.isPack);
        expect(view.elitePack, base.isPack);
        expect(tough.elite, view.elite);
        expect(tough.elitePack, view.elitePack);
        expect(
            tough.extra,
            closeTo(
                base.isPack || base.elite
                    ? base.extra * eliteStatMultiplier
                    : base.extra,
                1e-9));
        // A floor met again offers none.
        expect(
            towerEventKindOf(run.copyWith(crest: floor, setbacks: 1)), isNull);
      }
    });

    test('the tougher floor: a lone foe an Elite, a pack an Elite pack', () {
      TowerFloor floor(List<String> ids, {bool elite = false}) => TowerFloor(
          floor: 21,
          kind: TowerFloorKind.fight,
          chapter: 6,
          extra: .5,
          enemyIds: ids,
          elite: elite);
      final lone = towerShortcutFloor(floor(['a']));
      expect((lone.elite, lone.elitePack, lone.extra), (true, false, .5));
      final loneElite = towerShortcutFloor(floor(['a'], elite: true));
      expect((loneElite.elite, loneElite.elitePack), (true, false));
      expect(loneElite.extra, closeTo(.5 * eliteStatMultiplier, 1e-9));
      final pack = towerShortcutFloor(floor(['a', 'b', 'b']));
      expect(pack.enemyIds, ['a', 'b', 'b']);
      expect((pack.elite, pack.elitePack), (false, true));
      expect(pack.extra, closeTo(.5 * eliteStatMultiplier, 1e-9));
      // The Elite pack's multiplier is in its extra: the fight forces no
      // Elite on top of it.
      expect(pack.modifiersFor('warrior').forceElite, isFalse);
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
      expect(fought.elitePack, towerEventOf(run, data)!.elitePack);
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

  group('the parley', () {
    test('only in a run of the floors without a fight (events 2)', () {
      for (var seed = 1; seed <= 200; seed++) {
        for (var floor = 1; floor < towerTop; floor++) {
          expect(
              towerEventKindOf(at(seed, floor)), isNot(TowerEventKind.parley),
              reason: 'events 1: $seed f$floor');
        }
      }
      expect(towerProfessionScaleOf('mage', events: 1),
          towerProfessionScale['mage']! * towerEventsFoeScale);
      expect(towerProfessionScaleOf('mage', events: towerPeacefulEvents),
          towerProfessionScale['mage']! * towerPeacefulFoeScale);
    });

    final parleys =
        floorsOf(TowerEventKind.parley, count: 60, events: towerPeacefulEvents);

    /// The floor events' draw as PR 2 drew it (tower_events.dart's _drawn),
    /// rewritten here: the parley must never move it.
    TowerEventKind? before(int seed, int floor) {
      if (floor < 1 || floor >= towerTop || isGate(floor)) return null;
      final random = towerRandom(seed, floor, TowerStream.board);
      final u = random.nextDouble();
      final fits =
          floor + 2 < towerTop && !isGate(floor + 1) && !isGate(floor + 2);
      if (u < .10) return fits ? TowerEventKind.rival : null;
      if (u < .30) return TowerEventKind.test;
      if (u < .45) return fits ? TowerEventKind.shortcut : null;
      return null;
    }

    /// [seed]'s run on [floor] sworn to [clan] from the start.
    TowerRun sworn(int seed, int floor, String clan) {
      final run = towerStart(
              seed: seed,
              raceId: 'human',
              professionId: 'warrior',
              clanId: clan,
              events: towerPeacefulEvents,
              data: data)
          .copyWith(floor: floor);
      return run.copyWith(health: towerHeroOf(run, data).maxHealth);
    }

    test('the draw: its own index, about 15% of the free ordinary floors', () {
      var free = 0, found = 0;
      for (var seed = 1; seed <= 400; seed++) {
        for (var floor = 1; floor <= towerTop; floor++) {
          final kind =
              towerEventKindOf(at(seed, floor, events: towerPeacefulEvents));
          // The floor events' draws have not moved.
          if (kind != TowerEventKind.parley) {
            expect(kind, before(seed, floor), reason: '$seed f$floor');
          }
          final eligible = floor >= 2 &&
              floor < towerTop &&
              !isGate(floor) &&
              before(seed, floor) == null;
          if (!eligible) {
            expect(kind, isNot(TowerEventKind.parley), reason: '$seed f$floor');
            continue;
          }
          free++;
          final random =
              towerRandom(seed, towerPeacefulDraw + floor, TowerStream.board);
          final drawn = random.nextDouble() < towerParleyShare;
          expect(kind == TowerEventKind.parley, drawn, reason: '$seed f$floor');
          if (drawn) {
            found++;
            expect(
                towerParleyClanOf(at(seed, floor, events: towerPeacefulEvents)),
                towerClans[random.nextInt(towerClans.length)]);
          }
        }
      }
      expect(found / free, closeTo(towerParleyShare, .02));
      // Never on a floor met again, nor in a run with its events off.
      for (final (seed, floor) in parleys) {
        expect(
            towerEventKindOf(at(seed, floor, events: towerPeacefulEvents)
                .copyWith(crest: floor)),
            isNull);
        expect(towerEventKindOf(at(seed, floor, events: 0)), isNull);
      }
    });

    test('the view: the check, the clan, the oath, the landing', () {
      expect(parleys, isNotEmpty);
      for (final (seed, floor) in parleys) {
        final run = at(seed, floor, events: towerPeacefulEvents);
        final view = towerEventOf(run, data)!;
        expect(view.kind, TowerEventKind.parley);
        expect(view.floor, floor);
        expect(view.revisit, isFalse);
        expect(view.ability, towerParleyAbilities[(floor - 1) % 3]);
        expect(view.ability, towerParleyAbilityOf(floor));
        expect(view.dc, towerSetbackDcOf(floor));
        expect(
            view.modifier, towerHeroOf(run, data).abilityBonus(view.ability!));
        expect(
            view.chance, checkChance(modifier: view.modifier!, dc: view.dc!));
        expect(view.clanId, towerParleyClanOf(run));
        expect(towerClans, contains(view.clanId));
        expect(view.oathPass, isFalse);
        expect(view.landsOn, floor + 1);
        expect(view.forgoes, ['spoils', 'card', 'heal']);
        expect(view.accepted, isNull);
        expect(view.background, 'parley');
        expect(towerEventOf(sworn(seed, floor, view.clanId!), data)!.oathPass,
            isTrue);
      }
      // The other kinds' background keys.
      for (final (kind, key) in [
        (TowerEventKind.test, 'setback'),
        (TowerEventKind.rival, 'rival'),
        (TowerEventKind.shortcut, 'shortcut'),
      ]) {
        final (seed, floor) = floorsOf(kind, count: 1).first;
        expect(
            towerEventOf(at(seed, floor, events: towerPeacefulEvents), data)!
                .background,
            key);
      }
    });

    test('talked: a pass goes on, a fail fights; chosen once', () {
      var passes = 0, fails = 0;
      for (final (seed, floor) in parleys) {
        final run = at(seed, floor, events: towerPeacefulEvents);
        final view = towerEventOf(run, data)!;
        final talked = towerChooseParley(run, data, true);
        final result = talked.lastEvent!;
        expect(result.kind, TowerEventKind.parley);
        expect(result.from, floor);
        expect(result.total, result.roll! + view.modifier!);
        expect(
            result.passed,
            result.roll == 20 ||
                (result.roll != 1 && result.total! >= view.dc!));
        if (result.passed) {
          passes++;
          expect(talked.status, TowerStatus.climbing);
          expect(talked.floor, floor + 1);
          expect(result.to, floor + 1);
          expect(talked.parley, isNull);
          expect(towerEventOf(talked, data)!.result, result);
        } else {
          fails++;
          expect(talked.floor, floor);
          expect(result.to, floor);
          expect(talked.parley, isTrue);
          expect(towerEventOf(talked, data)!.accepted, isTrue);
          expect(towerChooseParley(talked, data, true), same(talked));
          // The fight, as it would have been, and the climb as usual.
          expect(towerFloorOf(talked, data).enemyIds,
              towerFloorOf(run, data).enemyIds);
          final won = towerAfterFight(talked, data,
              won: true, healthLeft: talked.health);
          final plain =
              towerAfterFight(run, data, won: true, healthLeft: run.health);
          expect(won.spoils, plain.spoils);
          expect(won.health, plain.health);
          expect(won.lastEvent, isNull);
          final next = towerPick(won, data, null);
          expect(next.floor, floor + 1);
          expect(next.parley, isNull);
          expect(next.crest, 0);
        }
      }
      expect(passes, greaterThan(0));
      expect(fails, greaterThan(0));
    });

    test('the fight chosen: the floor fought as usual', () {
      final (seed, floor) = parleys.first;
      final run = at(seed, floor, events: towerPeacefulEvents);
      final fight = towerChooseParley(run, data, false);
      expect(fight.parley, isFalse);
      expect(fight.floor, floor);
      expect(fight.lastEvent, isNull);
      expect(towerEventOf(fight, data)!.accepted, isFalse);
      expect(towerChooseParley(fight, data, true), same(fight));
      final next = winAndMove(fight);
      expect(next.floor, floor + 1);
      expect(next.parley, isNull);
      expect(next.spoils, contains(floor));
      // Not offered: nothing to choose.
      for (var f = 1; f < towerTop; f++) {
        final plain = at(seed, f, events: towerPeacefulEvents);
        if (towerEventKindOf(plain) == TowerEventKind.parley) continue;
        expect(towerChooseParley(plain, data, true), same(plain));
      }
    });

    test('sworn to the guardian\'s clan: passed with no roll', () {
      for (final (seed, floor) in parleys.take(20)) {
        final clan =
            towerParleyClanOf(at(seed, floor, events: towerPeacefulEvents))!;
        final run = sworn(seed, floor, clan);
        final talked = towerChooseParley(run, data, true);
        expect(talked.floor, floor + 1);
        expect(talked.lastEvent!.passed, isTrue);
        expect(talked.lastEvent!.roll, isNull);
        expect(talked.lastEvent!.total, isNull);
        expect(talked.lastEvent!.to, floor + 1);
        // Sworn to another clan: the check.
        final other = towerClans.firstWhere((c) => c != clan);
        final checked =
            towerChooseParley(sworn(seed, floor, other), data, true);
        expect(checked.lastEvent!.roll, isNotNull);
      }
    });

    test('a pass: the level and the marks, no spoils, card or heal', () {
      var checked = 0;
      for (final (seed, floor) in parleys) {
        final clan =
            towerParleyClanOf(at(seed, floor, events: towerPeacefulEvents))!;
        final full = sworn(seed, floor, clan);
        final run = full.copyWith(health: full.health ~/ 2);
        final passed = towerChooseParley(run, data, true);
        expect(passed.floor, floor + 1);
        expect(passed.crest, floor);
        expect(passed.heightCleared, floor);
        expect(passed.marks, towerMarksOf(floor, passed.refused.length));
        expect(passed.spoils, isNot(contains(floor)));
        expect(passed.taken, isNot(contains(floor)));
        expect(passed.refused, isNot(contains(floor)));
        expect(passed.offer, isEmpty);
        expect(towerIsRevisit(passed), isFalse);
        // Its level: the picks wait, the max health added, no recovery.
        final earned = (towerLevelAfter(floor) - 1) * levelStatPicks;
        expect(towerPendingPicks(passed), earned - passed.statPicks.length);
        final gain = towerHeroOf(passed, data).maxHealth -
            towerHeroOf(run, data).maxHealth;
        expect(passed.health, run.health + gain);
        expect(passed.potions, run.potions);
        checked++;
      }
      expect(checked, greaterThan(0));
    });

    test('the choice round-trips through the save', () {
      final (seed, floor) = parleys.first;
      for (final talk in [true, false]) {
        final run =
            at(seed, floor, events: towerPeacefulEvents).copyWith(parley: talk);
        final json =
            jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>;
        expect(json['parley'], talk);
        final loaded = TowerRun.fromJson(json);
        expect(loaded.parley, talk);
        expect(loaded.copyWith(floor: 3).parley, talk);
        expect(loaded.copyWith(clearParley: true).parley, isNull);
      }
      expect(at(seed, floor, events: towerPeacefulEvents).toJson(),
          isNot(contains('parley')));
      const result = TowerEventResult(
          kind: TowerEventKind.parley, passed: true, from: 4, to: 5);
      expect(TowerEventResult.fromJson(result.toJson()), result);
    });
  });

  test('the bot with the floors without a fight meets parleys and ends', () {
    var met = 0;
    for (var seed = 1; seed <= 40; seed++) {
      final run = playTowerRun(
          seed: seed,
          data: data,
          events: towerPeacefulEvents,
          choice: towerBotChoice);
      expect(run.isOver, isTrue);
      expect(run.events, towerPeacefulEvents);
      for (var floor = 1; floor <= run.floorReached; floor++) {
        if (towerEventKindOf(at(seed, floor, events: towerPeacefulEvents)) ==
            TowerEventKind.parley) {
          met++;
        }
      }
    }
    expect(met, greaterThan(0));
  });

  group('the stores', () {
    const v = towerPeacefulEvents;

    /// The kind the peaceful draw gives [seed]'s [floor] ([towerPeacefulDraw]
    /// + floor), the floor's own events aside: PR 3's parley, then PR 4's
    /// merchant and bargain.
    TowerEventKind? peaceful(int seed, int floor) {
      final u = towerRandom(seed, towerPeacefulDraw + floor, TowerStream.board)
          .nextDouble();
      if (u < .15) return TowerEventKind.parley;
      if (u < .20) return TowerEventKind.merchant;
      if (u < .30) return TowerEventKind.bargain;
      return null;
    }

    /// [seed]'s run sworn to [clan] from the start, on [floor].
    TowerRun swornAt(int seed, int floor, String clan) {
      final run = towerStart(
              seed: seed,
              raceId: 'human',
              professionId: 'warrior',
              clanId: clan,
              events: v,
              data: data)
          .copyWith(floor: floor);
      return run.copyWith(health: towerHeroOf(run, data).maxHealth);
    }

    /// The floors of seeds 1.. whose landing holds a [kind] (seed, floor).
    List<(int, int)> storesOf(TowerEventKind kind, {int count = 12}) {
      final found = <(int, int)>[];
      for (var seed = 1; found.length < count && seed < 400; seed++) {
        for (var floor = 2; floor < towerTop; floor++) {
          if (isGate(floor) ||
              towerEventKindOf(at(seed, floor, events: v)) != null) {
            continue;
          }
          if (peaceful(seed, floor) == kind) found.add((seed, floor));
        }
      }
      return found;
    }

    test('the draw: the next slices of the peaceful draw, on the landing', () {
      var free = 0, merchants = 0, bargains = 0;
      for (var seed = 1; seed <= 150; seed++) {
        for (var floor = 1; floor < towerTop; floor++) {
          final run = at(seed, floor, events: v);
          // A store is never the floor's own event.
          final own = towerEventKindOf(run);
          expect(own, isNot(TowerEventKind.merchant));
          expect(own, isNot(TowerEventKind.bargain));
          final eligible = floor >= 2 &&
              !isGate(floor) &&
              (own == null || own == TowerEventKind.parley);
          final landing = winAndMove(run);
          final store = towerStoreKindOf(landing);
          if (towerShopFloors.contains(floor)) {
            expect(store, TowerEventKind.merchant, reason: '$seed f$floor');
            continue;
          }
          if (!eligible) {
            expect(store, isNull, reason: '$seed f$floor');
            continue;
          }
          free++;
          final drawn = peaceful(seed, floor);
          final expected = drawn == TowerEventKind.parley ? null : drawn;
          expect(store, expected, reason: '$seed f$floor');
          if (store != null) {
            expect(landing.store, floor);
            expect(landing.floor, floor + 1);
          }
          if (store == TowerEventKind.merchant) merchants++;
          if (store == TowerEventKind.bargain) bargains++;
        }
      }
      expect(merchants / free, closeTo(towerMerchantShare, .015));
      expect(bargains / free, closeTo(towerBargainShare, .02));
      // Never after a floor met again.
      for (final (seed, floor) in storesOf(TowerEventKind.merchant)) {
        expect(
            winAndMove(at(seed, floor, events: v).copyWith(crest: floor + 1))
                .store,
            isNull);
      }
    });

    test('version 1 (live) and 0 meet no merchant, shop room or bargain', () {
      final stores = [
        ...storesOf(TowerEventKind.merchant, count: 6),
        ...storesOf(TowerEventKind.bargain, count: 6),
        for (var seed = 1; seed <= 6; seed++)
          for (final floor in towerShopFloors) (seed, floor),
      ];
      for (final (seed, floor) in stores) {
        expect(towerStoreKindOf(winAndMove(at(seed, floor, events: v))),
            isNotNull);
        for (final events in [0, 1]) {
          final landing = winAndMove(at(seed, floor, events: events));
          expect(landing.store, isNull, reason: '$seed f$floor v$events');
          expect(towerStoreKindOf(landing), isNull);
          // Nothing to buy or strike, even with the store forced open.
          final forced = landing.copyWith(store: floor);
          expect(towerStoreKindOf(forced), isNull);
          expect(identical(towerBuy(forced, data, 'salve'), forced), isTrue);
          expect(identical(towerChooseBargain(forced, data, true), forced),
              isTrue);
          expect(towerEventOf(forced, data)?.storeOpen ?? false, isFalse);
        }
      }
    });

    test('a shop always opens after the bosses of floors 10 and 20', () {
      for (var seed = 1; seed <= 30; seed++) {
        for (final floor in towerShopFloors) {
          final landing = winAndMove(at(seed, floor, events: v));
          expect(landing.store, floor, reason: '$seed f$floor');
          expect(towerStoreKindOf(landing), TowerEventKind.merchant);
          final random =
              towerRandom(seed, towerPeacefulDraw + floor, TowerStream.board)
                ..nextDouble();
          expect(towerStoreClanOf(landing),
              towerClans[random.nextInt(towerClans.length)]);
        }
        // The top ends the climb: no store.
        final top = towerAfterFight(at(seed, towerTop, events: v), data,
            won: true, healthLeft: 1);
        expect(top.status, TowerStatus.won);
        expect(top.store, isNull);
      }
      expect(towerShopFloors, {10, 20});
    });

    test('buying: the price, the wallet, the stock once, marks banked less',
        () {
      final landing = winAndMove(at(3, 10, events: v));
      final hero = towerHeroOf(landing, data);
      final hurt = landing.copyWith(health: hero.maxHealth ~/ 4, potions: 1);
      final wallet = hurt.marks;
      expect(wallet, hurt.marksEarned);
      expect(wallet, greaterThanOrEqualTo(towerSalvePrice + towerBundlePrice));
      final salve = towerBuy(hurt, data, 'salve');
      final heal = (hero.maxHealth * towerSalveShare).round();
      expect(salve.health, hurt.health + heal);
      expect(salve.marksSpent, towerSalvePrice);
      expect(salve.marks, wallet - towerSalvePrice);
      expect(salve.marksEarned, hurt.marksEarned);
      expect(salve.bought, {
        10: ['salve']
      });
      expect(salve.lastEvent!.kind, TowerEventKind.merchant);
      expect(salve.lastEvent!.bought, ['salve']);
      expect(salve.lastEvent!.paid, towerSalvePrice);
      expect(salve.lastEvent!.healed, heal);
      // Once a store.
      expect(identical(towerBuy(salve, data, 'salve'), salve), isTrue);
      final both = towerBuy(salve, data, 'potions');
      expect(both.potions, 1 + towerBundlePotions);
      expect(both.marksSpent, towerSalvePrice + towerBundlePrice);
      expect(both.bought[10], ['salve', 'potions']);
      expect(both.lastEvent!.paid, towerSalvePrice + towerBundlePrice);
      expect(both.lastEvent!.healed, heal);
      // An unknown id buys nothing.
      expect(identical(towerBuy(hurt, data, 'whetstone'), hurt), isTrue);
      // The salve never heals past the max.
      final near = landing.copyWith(health: hero.maxHealth - 1);
      final full = towerBuy(near, data, 'salve');
      expect(full.health, hero.maxHealth);
      expect(full.lastEvent!.healed, 1);
      // The bundle fills the bag up to its cap, and needs room in it.
      final four = towerBuy(landing.copyWith(potions: 4), data, 'potions');
      expect(four.potions, towerBagCap);
      final brim = landing.copyWith(potions: towerBagCap);
      expect(identical(towerBuy(brim, data, 'potions'), brim), isTrue);
      // Never past the wallet.
      final poor = hurt.copyWith(marksSpent: hurt.marksEarned - 2);
      expect(poor.marks, 2);
      expect(identical(towerBuy(poor, data, 'salve'), poor), isTrue);
      expect(identical(towerBuy(poor, data, 'potions'), poor), isTrue);
      // What is spent is not banked.
      final ended = towerAbandon(both);
      expect(ended.marks, ended.marksEarned - ended.marksSpent);
      expect(const TowerProgress().afterRun(ended).marks,
          ended.marksEarned - towerSalvePrice - towerBundlePrice);
    });

    test('sworn to the merchant\'s clan: half price, rounded up', () {
      final clan = towerStoreClanOf(winAndMove(at(3, 10, events: v)))!;
      final landing = winAndMove(swornAt(3, 10, clan));
      expect(towerStoreClanOf(landing), clan);
      final view = towerEventOf(landing, data)!;
      expect(view.discount, isTrue);
      expect([for (final s in view.stock!) s.price], [2, 2]);
      final hurt = landing.copyWith(health: 1);
      final bought = towerBuy(towerBuy(hurt, data, 'salve'), data, 'potions');
      expect(bought.marksSpent, 4);
      // Another clan's merchant: full price.
      final other = towerClans.firstWhere((c) => c != clan);
      final full = winAndMove(swornAt(3, 10, other));
      expect(towerEventOf(full, data)!.discount, isFalse);
      expect(towerBuy(full.copyWith(health: 1), data, 'salve').marksSpent,
          towerSalvePrice);
    });

    test('leaving, or the next fight, closes the store', () {
      final landing = winAndMove(at(3, 10, events: v));
      final left = towerLeaveStore(landing);
      expect(left.store, isNull);
      expect(towerStoreKindOf(left), isNull);
      expect(towerEventOf(left, data)?.storeOpen ?? false, isFalse);
      expect(identical(towerBuy(left, data, 'salve'), left), isTrue);
      expect(identical(towerLeaveStore(left), left), isTrue);
      final fought =
          towerAfterFight(landing, data, won: true, healthLeft: landing.health);
      expect(fought.store, isNull);
      final lost = towerAfterFight(landing, data, won: false, healthLeft: 0);
      expect(lost.store, isNull);
      // A store saved on a floor the run has left is not open.
      expect(towerStoreKindOf(landing.copyWith(floor: 12)), isNull);
    });

    test('the bargain: max health for a point, kept through a replay', () {
      final bargains = storesOf(TowerEventKind.bargain, count: 6);
      expect(bargains, isNotEmpty);
      for (final (seed, floor) in bargains) {
        final landing = winAndMove(at(seed, floor, events: v));
        expect(towerStoreKindOf(landing), TowerEventKind.bargain,
            reason: '$seed f$floor');
        final before = towerHeroOf(landing, data);
        final stat = before.preferredStat;
        final cost = max(1, (before.maxHealth * .10).round());
        final view = towerEventOf(landing, data)!;
        expect(view.maxHealthCost, cost);
        expect(view.stat, stat);
        expect(view.points, 1);
        expect(view.accepted, isNull);
        final taken = towerChooseBargain(landing, data, true);
        expect(taken.bargains, {floor: cost});
        expect(taken.lastEvent!.kind, TowerEventKind.bargain);
        expect(taken.lastEvent!.passed, isTrue);
        expect(towerEventOf(taken, data)!.accepted, isTrue);
        final after = towerHeroOf(taken, data);
        expect(after.maxHealth, before.maxHealth - cost);
        expect(after.abilityScore(stat), before.abilityScore(stat) + 1);
        expect(taken.health, lessThanOrEqualTo(after.maxHealth));
        // Once.
        expect(
            identical(towerChooseBargain(taken, data, false), taken), isTrue);
        // A replay from the save rebuilds the same hero.
        final loaded =
            TowerRun.fromJson(jsonDecode(jsonEncode(taken.toJson())));
        final replay = towerHeroOf(loaded, data);
        expect(replay.maxHealth, after.maxHealth);
        expect(replay.abilityScore(stat), after.abilityScore(stat));
        // Later levels never give the cut back.
        final higher =
            loaded.copyWith(floor: min(floor + 6, towerTop), clearStore: true);
        final twin =
            landing.copyWith(floor: min(floor + 6, towerTop), clearStore: true);
        expect(towerHeroOf(higher, data).maxHealth,
            towerHeroOf(twin, data).maxHealth - cost);
        // Refused: nothing changes.
        final refused = towerChooseBargain(landing, data, false);
        expect(refused.bargains, {floor: 0});
        expect(refused.lastEvent!.passed, isFalse);
        expect(towerEventOf(refused, data)!.accepted, isFalse);
        expect(towerHeroOf(refused, data).maxHealth, before.maxHealth);
        // Not at a merchant.
        final shop = winAndMove(at(seed, 10, events: v));
        expect(identical(towerChooseBargain(shop, data, true), shop), isTrue);
      }
    });

    test('the views: the merchant\'s stock and the bargain\'s offer', () {
      final landing = winAndMove(at(3, 10, events: v));
      final view = towerEventOf(landing, data)!;
      expect(view.kind, TowerEventKind.merchant);
      expect(view.storeOpen, isTrue);
      expect(view.background, 'merchant');
      expect(view.floor, 11);
      expect(view.clanId, towerStoreClanOf(landing));
      expect(view.discount, isFalse);
      expect(view.wallet, landing.marks);
      final hero = towerHeroOf(landing, data);
      final stock = view.stock!;
      expect([for (final s in stock) s.id], ['salve', 'potions']);
      expect([for (final s in stock) s.kind],
          [TowerStockKind.salve, TowerStockKind.potions]);
      expect([for (final s in stock) s.price],
          [towerSalvePrice, towerBundlePrice]);
      expect([for (final s in stock) s.amount],
          [(hero.maxHealth * towerSalveShare).round(), towerBundlePotions]);
      expect([for (final s in stock) s.bought], [false, false]);
      expect([for (final s in stock) s.affordable], [true, true]);
      final bought = towerBuy(landing.copyWith(health: 1), data, 'salve');
      final after = towerEventOf(bought, data)!;
      expect(after.wallet, landing.marks - towerSalvePrice);
      expect([for (final s in after.stock!) s.bought], [true, false]);
      expect(after.stock!.first.affordable, isFalse);
      expect(after.result, bought.lastEvent);
      final poor = landing.copyWith(marksSpent: landing.marksEarned - 3);
      expect([for (final s in towerEventOf(poor, data)!.stock!) s.affordable],
          [true, false]);
      // The bargain's background, and the floor's own event once left.
      final (seed, floor) = storesOf(TowerEventKind.bargain, count: 1).first;
      final dark = towerEventOf(winAndMove(at(seed, floor, events: v)), data)!;
      expect(dark.background, 'bargain');
      expect(dark.storeOpen, isTrue);
      final left = towerLeaveStore(landing);
      expect(towerEventOf(left, data)?.kind, towerEventKindOf(left));
    });

    test('the store\'s fields round-trip through the save', () {
      final run = winAndMove(at(3, 10, events: v)).copyWith(
        marksSpent: 5,
        bought: {
          4: ['salve'],
          10: ['salve', 'potions'],
        },
        bargains: {7: 3, 8: 0},
        lastEvent: const TowerEventResult(
            kind: TowerEventKind.merchant,
            passed: true,
            from: 10,
            to: 11,
            bought: ['salve', 'potions'],
            paid: 7,
            healed: 12),
      );
      final json = jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>;
      expect(json['spent'], 5);
      expect(json['store'], 10);
      final loaded = TowerRun.fromJson(json);
      expect(loaded.marksSpent, 5);
      expect(loaded.bought, run.bought);
      expect(loaded.store, 10);
      expect(loaded.bargains, run.bargains);
      expect(loaded.lastEvent, run.lastEvent);
      expect(jsonEncode(loaded.toJson()), jsonEncode(json));
      expect(loaded.copyWith(clearStore: true).store, isNull);
      expect(loaded.copyWith(floor: 12).store, 10);
      // A result without the store's fields reads as before.
      const plain = TowerEventResult(
          kind: TowerEventKind.bargain, passed: false, from: 4, to: 5);
      expect(plain.toJson().keys, isNot(contains('bought')));
      expect(TowerEventResult.fromJson(plain.toJson()), plain);
    });

    test('the bot shops, strikes every bargain and leaves; spent not banked',
        () {
      var shopped = 0, bargained = 0;
      for (var seed = 1; seed <= 20; seed++) {
        final run = playTowerRun(seed: seed, data: data, events: v);
        expect(run.isOver, isTrue);
        expect(run.store, isNull);
        expect(run.marks, max(0, run.marksEarned - run.marksSpent));
        expect(run.bargains.values, everyElement(greaterThan(0)));
        if (run.marksSpent > 0) shopped++;
        if (run.bargains.isNotEmpty) bargained++;
      }
      expect(shopped, greaterThan(0));
      expect(bargained, greaterThan(0));
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
