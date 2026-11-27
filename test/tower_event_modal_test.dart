// Floor events in a modal (the setback's check deferred to the player's
// commit): each event's view says whether it is forced and which buttons
// its modal shows, each paired with the outcome lines it leads to. With the
// switch on (towerEventModalOverride), a setback's floor stops after its
// fight, picks and cards, the check pending (TowerRun.checkPending, saved)
// and nothing of it applied; towerResolveCheck then gives exactly what the
// switch off gives, however often the run is saved and loaded, and its
// result is the controller's new event. With the switch off nothing moves,
// and the bot plays the same either way.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_dice.dart';
import 'package:narrative_data_app/data/tower/tower_event_outcomes.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();

  tearDown(() => towerEventModalOverride = null);

  T withModal<T>(bool on, T Function() body) {
    final before = towerEventModalOverride;
    towerEventModalOverride = on;
    try {
      return body();
    } finally {
      towerEventModalOverride = before;
    }
  }

  TowerRun at(int seed, int floor, int rules) {
    final run = towerStart(
            seed: seed,
            raceId: 'human',
            professionId: 'warrior',
            events: towerEventsLive,
            rules: rules,
            data: data)
        .copyWith(floor: floor);
    return run.copyWith(health: towerHeroOf(run, data).maxHealth);
  }

  String js(TowerRun run) => jsonEncode(run.toJson());

  /// The first setback floors of seeds 1.. on [rules].
  List<TowerRun> setbacks(int rules, {int count = 6}) {
    final found = <TowerRun>[];
    for (var seed = 1; seed < 400 && found.length < count; seed++) {
      for (var floor = 2; floor < 28; floor++) {
        final run = at(seed, floor, rules);
        if (towerEventKindOf(run) == TowerEventKind.test) {
          found.add(run);
          break;
        }
      }
    }
    return found;
  }

  /// [run]'s floor won and its tables taken ([index]: the first card, or
  /// none refused), until the run moves on or a check waits.
  TowerRun winAndPick(TowerRun run, int? index) {
    var next = towerAfterFight(run, data, won: true, healthLeft: run.health);
    for (var i = 0;
        i < 12 && next.status == TowerStatus.choosing && !next.checkPending;
        i++) {
      next = towerPick(next, data, next.offer.isEmpty ? null : index);
    }
    return next;
  }

  group('forced and options (pure, live either way)', () {
    test('per kind', () {
      expect(towerEventForcedOf(TowerEventKind.test), isTrue);
      expect(towerEventForcedOf(TowerEventKind.rival), isTrue);
      for (final kind in [
        TowerEventKind.shortcut,
        TowerEventKind.parley,
        TowerEventKind.bargain,
        TowerEventKind.merchant,
        null,
      ]) {
        expect(towerEventForcedOf(kind), isFalse, reason: '$kind');
      }
      expect(
          towerEventOptionsOf(TowerEventKind.test), [TowerEventOption.check]);
      expect(
          towerEventOptionsOf(TowerEventKind.rival), [TowerEventOption.fight]);
      expect(towerEventOptionsOf(TowerEventKind.shortcut),
          [TowerEventOption.takeShortcut, TowerEventOption.standardClimb]);
      expect(towerEventOptionsOf(TowerEventKind.parley),
          [TowerEventOption.talk, TowerEventOption.fight]);
      expect(towerEventOptionsOf(TowerEventKind.bargain),
          [TowerEventOption.accept, TowerEventOption.refuse]);
      expect(towerEventOptionsOf(TowerEventKind.merchant),
          [TowerEventOption.shop, TowerEventOption.leave]);
      expect(towerEventOptionsOf(null), isEmpty);
    });

    test('each view\'s options split its outcome lines, in order', () {
      final seen = <TowerEventKind>{};
      for (var seed = 1; seed < 200 && seen.length < 4; seed++) {
        for (var floor = 2; floor < 28; floor++) {
          final view = towerEventOf(at(seed, floor, 4), data);
          final kind = view?.kind;
          if (view == null || kind == null) continue;
          seen.add(kind);
          expect(view.forced, towerEventForcedOf(kind));
          expect(view.options, towerEventOptionsOf(kind));
          final all = towerChoiceOutcomesOf(view);
          final split = [
            for (final o in view.options) ...towerOptionOutcomesOf(view, o)
          ];
          expect(split.toSet(), all.toSet(), reason: '$kind');
          expect(split.length, all.length, reason: '$kind');
          for (final o in view.options) {
            if (o != TowerEventOption.leave) {
              expect(towerOptionOutcomesOf(view, o), isNotEmpty,
                  reason: '$kind $o');
            }
          }
          expect(towerOptionOutcomesOf(view, TowerEventOption.accept),
              kind == TowerEventKind.bargain ? isNotEmpty : isEmpty);
        }
      }
      expect(
          seen,
          containsAll([
            TowerEventKind.test,
            TowerEventKind.rival,
            TowerEventKind.shortcut,
            TowerEventKind.parley,
          ]));
    });

    test('a store\'s view: a choice, its buttons', () {
      // A merchant's and a bargain's views are built on the landing.
      final kinds = <TowerEventKind>{};
      for (var seed = 1; seed < 300 && kinds.length < 2; seed++) {
        for (var floor = 2; floor < 28; floor++) {
          final run = withModal(false, () {
            final from = at(seed, floor, 1);
            if (towerEventKindOf(from) != null) return null;
            return winAndPick(from, null);
          });
          if (run == null || run.store == null) continue;
          final view = towerEventOf(run, data)!;
          kinds.add(view.kind!);
          expect(view.forced, isFalse);
          expect(view.options, towerEventOptionsOf(view.kind));
          expect(towerOptionOutcomesOf(view, TowerEventOption.leave), isEmpty);
          final all = towerChoiceOutcomesOf(view);
          expect(
              [for (final o in view.options) ...towerOptionOutcomesOf(view, o)],
              all);
        }
      }
      expect(kinds, {TowerEventKind.merchant, TowerEventKind.bargain});
    });
  });

  group('the switch on', () {
    for (final rules in [1, 2, 3, 4]) {
      for (final index in [null, 0]) {
        test(
            'rules $rules, cards ${index ?? 'refused'}: pending, then the '
            'same result as the switch off', () {
          final runs = setbacks(rules);
          expect(runs, isNotEmpty);
          for (final run in runs) {
            final off = withModal(false, () => winAndPick(run, index));
            expect(off.checkPending, isFalse);
            expect(off.lastEvent?.kind, TowerEventKind.test);
            final pending = withModal(true, () => winAndPick(run, index));
            // Held on the floor, nothing of the check applied.
            expect(pending.checkPending, isTrue);
            expect(pending.status, TowerStatus.choosing);
            expect(pending.floor, run.floor);
            expect(pending.offer, isEmpty);
            expect(pending.lastEvent, isNull);
            expect(pending.setbacks, run.setbacks);
            expect(pending.crest, run.crest);
            expect(pending.heightCleared, run.floor);
            expect(towerPendingPicks(pending), 0);
            final view = towerEventOf(pending, data)!;
            expect(view.kind, TowerEventKind.test);
            expect(view.forced, isTrue);
            expect(view.options, [TowerEventOption.check]);
            expect(view.picksBeforeCheck, 0);
            expect(view.result, isNull);
            // The view's modifier is the roll's.
            expect(view.modifier, off.lastEvent!.modifier);
            // Saved and loaded: still pending, unrolled.
            final json = pending.toJson();
            expect(json['checkPending'], isTrue);
            final loaded = TowerRun.fromJson(
                jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
            expect(js(loaded), js(pending));
            expect(loaded.checkPending, isTrue);
            // Resolved (before or after the reload, with the switch on or
            // off, by towerResolveCheck or by a towerPick): the same run as
            // the switch off.
            for (final on in [true, false]) {
              withModal(on, () {
                expect(js(towerResolveCheck(pending, data)), js(off));
                expect(js(towerResolveCheck(loaded, data)), js(off));
                expect(js(towerPick(loaded, data, null)), js(off));
              });
            }
            final resolved = towerResolveCheck(loaded, data);
            expect(resolved.checkPending, isFalse);
            expect(resolved.toJson().containsKey('checkPending'), isFalse);
            // Nothing waits any more: a second resolve does nothing.
            expect(
                identical(towerResolveCheck(resolved, data), resolved), isTrue);
          }
        });
      }
    }

    test('both branches of the check are met', () {
      final results = [
        for (final rules in [1, 2, 3, 4])
          for (final run in setbacks(rules, count: 10))
            withModal(true,
                () => towerResolveCheck(winAndPick(run, null), data).lastEvent!)
      ];
      expect(results.where((r) => r.passed), isNotEmpty);
      expect(results.where((r) => !r.passed), isNotEmpty);
    });

    test('the die cannot be changed while the check waits', () {
      final run = setbacks(1).first;
      final pending = withModal(true, () => winAndPick(run, null));
      for (final id in towerHeroOf(pending, data).ownedDice.keys) {
        expect(identical(towerChooseDie(pending, data, id), pending), isTrue);
      }
    });
  });

  group('save, reload and the controller', () {
    Future<TowerController> opened() async {
      final controller = TowerController();
      for (var i = 0; i < 50 && controller.state.value == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return controller;
    }

    test('a pending check reloads pending; resolved, it is new, once',
        () async {
      for (final rules in [1, 4]) {
        final run = setbacks(rules).first;
        final off = withModal(false, () => winAndPick(run, null));
        final pending = withModal(true, () => winAndPick(run, null));
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await TowerSave(prefs).saveRun(pending);
        final saved = prefs.getString(towerRunPrefsKey);
        // Menu, Continue climb, three times over: pending, unrolled, the
        // save untouched; each resolve the same (no re-roll).
        for (var resume = 0; resume < 3; resume++) {
          final loaded = (await opened()).state.value!.run!;
          expect(loaded.checkPending, isTrue);
          expect(loaded.lastEvent, isNull);
          expect(js(loaded), js(pending));
          expect(js(towerResolveCheck(loaded, data)), js(off));
          expect(prefs.getString(towerRunPrefsKey), saved);
        }
        final controller = await opened();
        await controller.resolveCheck(data: data);
        final now = controller.state.value!.run!;
        expect(js(now), js(off));
        expect(controller.eventIsNew(now.lastEvent!), isTrue);
        controller.markEventShown();
        expect(controller.eventIsNew(now.lastEvent!), isFalse);
        // Saved: read back, not pending, not new, not rolled again.
        final back = await opened();
        final reread = back.state.value!.run!;
        expect(reread.checkPending, isFalse);
        expect(js(reread), js(off));
        expect(back.eventIsNew(reread.lastEvent!), isFalse);
        await back.resolveCheck(data: data);
        expect(js(back.state.value!.run!), js(off));
      }
    });

    test('a save from before (no key) is not pending', () {
      final run = setbacks(1).first;
      final pending = withModal(true, () => winAndPick(run, null));
      final json = pending.toJson()..remove('checkPending');
      final old = TowerRun.fromJson(json);
      expect(old.checkPending, isFalse);
      expect(identical(towerResolveCheck(old, data), old), isTrue);
    });
  });

  group('the switch off', () {
    test('off: nothing is ever pending', () {
      expect(towerEventModalLive, isTrue);
      expect(towerEventModalOn, isTrue);
      towerEventModalOverride = false;
      for (final rules in [1, 2, 3, 4]) {
        for (final run in setbacks(rules)) {
          final next = winAndPick(run, null);
          expect(next.checkPending, isFalse);
          expect(next.toJson().containsKey('checkPending'), isFalse);
          expect(next.lastEvent?.kind, TowerEventKind.test);
        }
      }
    });
  });

  test('the bot plays the same with the switch on or off', () {
    var tests = 0;
    for (final rules in [1, 2, 3, 4]) {
      for (var seed = 1; seed <= 12; seed++) {
        TowerRun play() => playTowerRun(
            seed: seed,
            data: data,
            progress: seed.isEven ? towerAllUnlocked : const TowerProgress(),
            events: towerEventsLive,
            rules: rules);
        final off = withModal(false, play);
        final on = withModal(true, play);
        expect(js(on), js(off), reason: 'rules $rules seed $seed');
        expect(on.checkPending, isFalse);
        tests += off.setbacks;
      }
    }
    expect(tests, greaterThan(0));
  });
}
