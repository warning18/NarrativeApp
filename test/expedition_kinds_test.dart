// Escort and delivery expeditions (v1.179): their stages, what each choice
// does to the wagons' load and the days, and what they pay.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/expedition_kinds.dart';

void main() {
  test('a zone says what kind of expedition it is', () {
    expect(expeditionKindOf(const {}), ExpeditionKind.clear);
    expect(expeditionKindOf(const {'kind': 'escort'}), ExpeditionKind.escort);
    expect(
        expeditionKindOf(const {'kind': 'delivery'}), ExpeditionKind.delivery);
    expect(deliveryDeadlineOf(const {'expeditionCount': 4}), 6);
    expect(
        deliveryDeadlineOf(const {'expeditionCount': 4, 'deadlineDays': 5}), 5);
  });

  test('an escort pays for what arrives; a late delivery pays half', () {
    expect(escortPayFor(200, escortCargoFull), 200);
    expect(escortPayFor(200, 55), 110);
    expect(escortPayFor(200, -10), 0);
    expect(escortKeepsItem(escortItemCargo), isTrue);
    expect(escortKeepsItem(escortItemCargo - 1), isFalse);
    expect(deliveryPayFor(200, daysUsed: 5, deadline: 5), 200);
    expect(deliveryPayFor(200, daysUsed: 6, deadline: 5), 100);
    expect(deliveryOnTime(daysUsed: 6, deadline: 5), isFalse);
  });

  test('a choice costs load and days by how it went', () {
    const ambush = StepOutcome(cargo: -5, fightCargo: -10);
    expect(ambush.resolve(failed: false, fought: false),
        (cargo: -5, days: 0, hurt: 0));
    expect(ambush.resolve(failed: true, fought: true),
        (cargo: -15, days: 0, hurt: 0));
    const bridge = StepOutcome(failDays: 1, hurtOnFail: 10);
    expect(bridge.resolve(failed: true, fought: false),
        (cargo: 0, days: 1, hurt: 10));
    expect(const StepOutcome(days: -1).resolve(failed: false, fought: false),
        (cargo: 0, days: -1, hurt: 0));
  });

  for (final kind in [ExpeditionKind.escort, ExpeditionKind.delivery]) {
    group(kind.name, () {
      test('every scene reads in both languages, and says what it costs', () {
        final keys = kindSceneKeys(kind);
        expect(keys.length, greaterThanOrEqualTo(6));
        final seen = <String>{};
        for (var seed = 0; seed < 300; seed++) {
          for (final chapter in [2, 4, 6]) {
            final step = buildKindStep(kind,
                chapter: chapter,
                random: Random(seed),
                used: const {},
                enemyPool: const ['harbor_rat', 'slum_thug'],
                packPool: const ['harbor_rat']);
            seen.add(step.key);
            expect(step.node.description, isNotEmpty);
            expect(step.node.descriptionFr, isNotEmpty);
            expect(step.node.choices, isNotEmpty);
            expect(step.outcomes.length, step.node.choices.length);
            for (final (i, choice) in step.node.choices.indexed) {
              expect(choice.textFr, isNotEmpty, reason: choice.text);
              expect(choice.text.length, lessThanOrEqualTo(55),
                  reason: choice.text);
              // A choice that costs a day says so.
              if (step.outcomeFor(i).days > 0) {
                expect(choice.text, contains('a day'), reason: choice.text);
                expect(choice.textFr, contains('un jour'), reason: choice.text);
              }
              if (choice.hasAbilityCheck) {
                expect(choice.checkDC, greaterThanOrEqualTo(10));
              }
            }
          }
        }
        expect(seen, keys.toSet());
      });

      test('an expedition meets each scene once before any comes back', () {
        final used = <String>{};
        final random = Random(7);
        for (var i = 0; i < kindSceneKeys(kind).length; i++) {
          final step = buildKindStep(kind,
              chapter: 3,
              random: random,
              used: used,
              enemyPool: const ['harbor_rat']);
          expect(used, isNot(contains(step.key)));
          used.add(step.key);
        }
        expect(used, kindSceneKeys(kind).toSet());
      });

      test('with no foe to draw, a scene without a fight comes instead', () {
        for (var seed = 0; seed < 100; seed++) {
          final step = buildKindStep(kind,
              chapter: 4,
              random: Random(seed),
              used: const {},
              enemyPool: const []);
          expect(step.node.choices, isNotEmpty);
          expect(step.node.choices.every((c) => !c.triggersCombat), isTrue);
        }
      });
    });
  }

  test('only escorts carry a load; a delivery counts days', () {
    for (var seed = 0; seed < 200; seed++) {
      final delivery = buildKindStep(ExpeditionKind.delivery,
          chapter: 3,
          random: Random(seed),
          used: const {},
          enemyPool: const ['harbor_rat']);
      for (final outcome in delivery.outcomes) {
        expect(outcome.cargo, 0);
        expect(outcome.failCargo, 0);
        expect(outcome.fightCargo, 0);
      }
    }
    expect(escortBossOutcome.resolve(failed: false, fought: true).cargo,
        lessThan(0));
  });
}
