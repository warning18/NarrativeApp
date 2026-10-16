// "Effects at 1" (docs/proposals/stat-scale.md): the flat effects that the
// small scale left at 1 (and so two to five times stronger than before)
// turned into shares that keep their fractions, a block chance, a Hone
// that at most doubles a face; and the dice faces keep their order.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/face_smithing.dart';
import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/stat_rules.dart';
import 'package:narrative_data_app/data/perks.dart';
import 'package:narrative_data_app/data/signs.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('a fraction bank', () {
    test('pays whole points and keeps the rest', () {
      final bank = FractionBank();
      // 10% of three blows of 3, then one of 4: 0.3, 0.6, 0.9, 1.3.
      expect([
        for (final blow in [3, 3, 3, 4]) bank.share(blow, 10)
      ], [
        0,
        0,
        0,
        1
      ]);
      expect(bank.owed, closeTo(0.3, 1e-9));
    });

    test('ten shares of a tenth make exactly one point', () {
      final bank = FractionBank();
      var paid = 0;
      for (var i = 0; i < 10; i++) {
        paid += bank.share(1, 10);
      }
      expect(paid, 1);
    });

    test('a preview pays what the next would, and keeps nothing', () {
      final bank = FractionBank()..owed = 0.8;
      expect(bank.share(3, 10, keep: false), 1);
      expect(bank.owed, 0.8);
      expect(bank.share(3, 10), 1);
      expect(bank.owed, closeTo(0.1, 1e-9));
    });
  });

  group('thorns are a share of the blow', () {
    final items = _table('items');
    final sets = parseItemSets(_table('item_sets'));

    test('the Thornmail sends back 30% of what lands, to the point', () {
      final gear = gearEffectsFor(['thornmail_hauberk'], items, sets);
      expect(gear.thornsPercent, 30);
      final thorns = ThornsBank();
      // 0.9, 1.8, 2.7, 3.6 owed over four blows of 3: 0, 1, 1, 1.
      expect([for (var i = 0; i < 4; i++) thorns.answer(3, gear.thornsPercent)],
          [0, 1, 1, 1]);
      expect(thorns.answer(0, gear.thornsPercent), 0, reason: 'a dodge');
    });

    test('signs and titles carry thorns as a share', () {
      final signs = parseSigns(_table('signs'));
      final mark = signs['stonemarked_passive_thorn_mark']!;
      final effects = signEffectsFor(
          [const HeldSign(signId: 'stonemarked_passive_thorn_mark')], signs,
          alignment: 0);
      expect(mark.effects.single.kind, SignEffectKind.thornsPercent);
      expect(effects.over(GearEffects.none).thornsPercent, 10);
    });
  });

  group('a sign\'s share on a small number', () {
    test('a strike share adds up over the fight instead of rounding away', () {
      const signs = SignEffects(strikeDamagePercent: 8);
      // A hit of 5 at 8% is 5.4: rounded, the sign would never show.
      expect(signs.strikeBase(4, 1, attackFace: true, percent: 8), 4);
      final bank = FractionBank();
      var extra = 0;
      for (var i = 0; i < 5; i++) {
        extra +=
            signs.strikeBase(4, 1, attackFace: true, percent: 8, bank: bank) -
                4;
      }
      expect(extra, 2, reason: '5 x 0.4');
    });

    test('a guard share on a Guard 1 adds up too; a malus leaves 1', () {
      const signs = SignEffects(guardBlockPercent: 12);
      final bank = FractionBank();
      final blocks = [
        for (var i = 0; i < 9; i++) signs.guardValue(1, bank: bank)
      ];
      expect(blocks.where((b) => b == 2), hasLength(1));
      expect(blocks.where((b) => b == 1), hasLength(8));
      expect(const SignEffects(guardFlat: -1).guardValue(1), 1);
      expect(const SignEffects(guardFlat: -1).guardValue(3), 2);
    });

    test('an element sign names its element; its damage is a share', () {
      final signs = parseSigns(_table('signs'));
      final gale = signs['painted_strike_gale']!;
      final element = gale.effects
          .firstWhere((e) => e.kind == SignEffectKind.strikeElement);
      expect(element.value, 0);
      expect(
          gale.effects.any((e) =>
              e.kind == SignEffectKind.strikeDamagePercent && e.value > 0),
          isTrue);
    });
  });

  group('armor +1 became a block chance', () {
    test('Iron Hide: 10% a rank, laid over the gear', () {
      final perks = perkEffectsFor(const {'ironHide': 2});
      expect(perks.blockChance, 20);
      expect(perks.over(GearEffects.none).blockChance, 20);
    });

    test('anyone blocks with it; with a warrior\'s Perception, up to 50%', () {
      expect(blockChanceWith('mage', 0, 8), 8);
      expect(blockChanceWith('warrior', 4, 8), 20);
      expect(blockChanceWith('warrior', 10, 30), blockChanceMax);
      expect(blockChanceWith('rogue', 0, 0), 0);
    });

    test('no sign or title gives flat armor any more', () {
      for (final name in ['signs', 'titles']) {
        for (final record in _table(name).values) {
          if (record is! Map) continue;
          for (final effect in (record['effects'] as List?) ?? const []) {
            expect((effect as Map)['kind'], isNot('armor'), reason: name);
          }
        }
      }
    });
  });

  group('a Hone at most doubles a face', () {
    test('as many Hones as the face\'s number, up to three', () {
      expect(maxHonesFor(1), 1);
      expect(maxHonesFor(2), 2);
      expect(maxHonesFor(5), maxHones);
      final one = {'type': 'Attack', 'value': 1};
      expect(canSmith(SmithingWork.hone, one), isTrue);
      expect(canSmith(SmithingWork.hone, one, const FaceUpgrade(hones: 1)),
          isFalse);
      final two = {'type': 'Defend', 'value': 2};
      expect(canSmith(SmithingWork.hone, two, const FaceUpgrade(hones: 1)),
          isTrue);
    });

    test('a save\'s extra Hones are kept but add nothing', () {
      final faces = [
        {'type': 'Attack', 'value': 1},
        {'type': 'Heal', 'value': 3},
      ];
      final smithed = smithedFaces(faces, const {
        '0': FaceUpgrade(hones: 3),
        '1': FaceUpgrade(hones: 3),
      });
      expect(smithed[0]['value'], 2);
      expect(smithed[1]['value'], 6);
    });
  });

  test('the dice: the starting dice stay at 1, the others keep a spread', () {
    final dice = _table('dice');
    List<int> numbers(String id) => [
          for (final face in (dice[id] as Map)['faces'] as List)
            if (['Attack', 'Defend', 'Heal'].contains(face['type']))
              (face['value'] as num).toInt(),
        ];
    expect(numbers('starter_die'), everyElement(1));
    expect(numbers('apprentice_die'), everyElement(1));
    // The Stone Die (7, 7, 9 before the small scale) is no longer the
    // Twinfang's (4, 4, 4) equal.
    expect(numbers('stone_die'), [2, 2, 2]);
    expect(numbers('twinfang_die'), [1, 1, 1]);
    for (final id in dice.keys) {
      for (final n in numbers(id)) {
        expect(n, inInclusiveRange(1, 5), reason: id);
      }
    }
  });
}
