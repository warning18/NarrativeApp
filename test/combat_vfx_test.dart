// v1.129: every skill and spell plays its own effect in a fight. Covers
// the data (each record names a known style), the mapping from faces,
// skills, spells, moves and statuses to styles, and the layer itself
// playing every style between two cards and then going quiet.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/skill_vfx.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/widgets/combat_vfx.dart';

Map<String, dynamic> _load(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('missing $name');
}

void main() {
  group('data', () {
    test('every skill names a known effect', () {
      final skills = _load('skills.json');
      expect(skills, isNotEmpty);
      for (final entry in skills.entries) {
        final vfx = (entry.value as Map<String, dynamic>)['vfx'];
        expect(authorableVfxIds, contains(vfx), reason: entry.key);
      }
    });

    test('every spell names a known effect', () {
      final spells = _load('spells.json');
      expect(spells, isNotEmpty);
      for (final entry in spells.entries) {
        final vfx = (entry.value as Map<String, dynamic>)['vfx'];
        expect(authorableVfxIds, contains(vfx), reason: entry.key);
      }
    });
  });

  group('mapping', () {
    test('every style has one id, and the id reads back', () {
      expect(vfxStyleIds.keys.toSet(), VfxStyle.values.toSet());
      expect(vfxStyleIds.values.toSet().length, VfxStyle.values.length);
      for (final style in VfxStyle.values) {
        expect(vfxStyleFromId(vfxStyleIds[style]), style);
      }
      expect(vfxStyleFromId(''), isNull);
      expect(vfxStyleFromId('confetti'), isNull);
    });

    test('die faces play their own kind of effect', () {
      expect(styleForFace('Attack', null), VfxStyle.slash);
      expect(styleForFace('Defend', null), VfxStyle.shield);
      expect(styleForFace('Heal', null), VfxStyle.heal);
      expect(styleForFace('Mana', null), VfxStyle.mana);
      expect(styleForFace('Empty', null), VfxStyle.miss);
      expect(styleForFace('Skill', {'vfx': 'meteor'}), VfxStyle.meteor);
    });

    test('a skill with no effect falls back on its element and use', () {
      expect(styleForSkill({'element': 'Fire', 'damageMultiplier': 1.5}),
          VfxStyle.flame);
      expect(styleForSkill({'element': 'Void', 'damageMultiplier': 1.4}),
          VfxStyle.voidRift);
      expect(styleForSkill({'element': 'Earth', 'healAmount': 15}),
          VfxStyle.stoneShield);
      expect(
          styleForSkill({'element': 'None', 'healAmount': 20}), VfxStyle.heal);
      expect(styleForSkill(null), VfxStyle.slash);
    });

    test('a heal skill plays on its user, a strike on its target', () {
      expect(
          isSupportSkill({'healAmount': 20, 'damageMultiplier': 1.0}), isTrue);
      expect(
          isSupportSkill(
              {'healAmount': 12, 'damageMod': 5, 'damageMultiplier': 1.8}),
          isFalse);
      expect(isSupportSkill({'damageMultiplier': 1.5}), isFalse);
      expect(isSupportSkill(null), isFalse);
    });

    test('spells, enemy moves and statuses', () {
      expect(styleForSpell(vfx: 'bolt', element: 'Fire', effect: 'damage'),
          VfxStyle.bolt);
      expect(
          styleForSpell(element: 'Light', effect: 'heal'), VfxStyle.radiance);
      expect(styleForSpell(element: 'None', effect: 'Block'), VfxStyle.shield);
      expect(styleForEnemyMove('', const {}), VfxStyle.claw);
      expect(
          styleForEnemyMove('frigid_grip', {
            'frigid_grip': {'vfx': 'frost'}
          }),
          VfxStyle.frost);
      expect(styleForStatus(StatusEffectType.poison), VfxStyle.poison);
      expect(styleForStatus(StatusEffectType.stun), VfxStyle.stun);
      expect(styleForStatus(StatusEffectType.weaken), VfxStyle.weaken);
    });

    test('every element and style has colors', () {
      for (final element in [
        'None',
        'Fire',
        'Ice',
        'Water',
        'Earth',
        'Wind',
        'Void',
        'Light',
        'Electricity',
        'Enemy',
        'Unknown',
      ]) {
        for (final style in VfxStyle.values) {
          final palette = paletteFor(style, element);
          expect(palette.primary >> 24, 0xFF);
        }
      }
    });

    test('each clan card has its accent, and nothing else does', () {
      final skills = _load('skills.json');
      final counts = <VfxAccent, int>{};
      for (final entry in skills.entries) {
        final accent = vfxAccentOf(entry.value as Map<String, dynamic>);
        counts[accent] = (counts[accent] ?? 0) + 1;
      }
      expect(counts[VfxAccent.fusion], 10);
      expect(counts[VfxAccent.ascension], 10);
      expect(counts[VfxAccent.subclan], 10);
      expect(counts[VfxAccent.secret], 10);
      expect(vfxAccentOf(null), VfxAccent.none);
      expect(vfxAccentOf(skills['fireball'] as Map<String, dynamic>),
          VfxAccent.none);
    });

    test('an enemy move reports the skill it used', () {
      final skills = _load('skills.json');
      final result = resolveEnemyMove(
        enemy: {
          'enemyName': 'Tester',
          'damage': 10,
          'skillMoves': [
            {'skillID': 'frigid_grip', 'condition': 'Always', 'priority': 1}
          ],
        },
        skills: skills,
        enemyCurrentHealth: 50,
        enemyMaxHealth: 50,
        random: Random(1),
      );
      expect(result.skillId, 'frigid_grip');
      final plain = resolveEnemyMove(
        enemy: {'enemyName': 'Tester', 'damage': 10},
        skills: skills,
        enemyCurrentHealth: 50,
        enemyMaxHealth: 50,
        random: Random(1),
      );
      expect(plain.skillId, '');
    });
  });

  group('layer', () {
    testWidgets('plays every style between two cards, then goes quiet',
        (tester) async {
      final controller = CombatVfxController();
      final hero = GlobalKey();
      final foe = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            Positioned(
                left: 20,
                top: 300,
                width: 160,
                height: 70,
                child: SizedBox(key: hero)),
            Positioned(
                left: 220,
                top: 200,
                width: 160,
                height: 140,
                child: SizedBox(key: foe)),
            Positioned.fill(
              child: IgnorePointer(
                child: CombatVfxLayer(controller: controller),
              ),
            ),
          ],
        ),
      ));
      var i = 0;
      for (final style in VfxStyle.values) {
        controller.play(
          style: style,
          target: i.isEven ? foe : hero,
          source: i.isEven ? hero : foe,
          element: const ['Fire', 'Void', 'None', 'Ice', 'Light'][i % 5],
          delayMs: (i % 4) * 60,
          text: '-${i + 1}',
          textKind: VfxTextKind.values[i % VfxTextKind.values.length],
          big: i % 3 == 0,
        );
        i++;
      }
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      // Every burst has run its course: the layer stops asking for frames.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.dispose();
    });

    testWidgets('plays every clan accent over a style, then goes quiet',
        (tester) async {
      final controller = CombatVfxController();
      final hero = GlobalKey();
      final foe = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            Positioned(
                left: 20,
                top: 300,
                width: 160,
                height: 70,
                child: SizedBox(key: hero)),
            Positioned(
                left: 220,
                top: 200,
                width: 160,
                height: 140,
                child: SizedBox(key: foe)),
            Positioned.fill(
              child: IgnorePointer(
                child: CombatVfxLayer(controller: controller),
              ),
            ),
          ],
        ),
      ));
      var i = 0;
      for (final accent in VfxAccent.values) {
        for (final style in [VfxStyle.impact, VfxStyle.heal, VfxStyle.flame]) {
          controller.play(
            style: style,
            target: i.isEven ? foe : hero,
            source: i.isEven ? hero : foe,
            element: const ['Fire', 'Void', 'None', 'Ice', 'Light'][i % 5],
            delayMs: (i % 4) * 60,
            text: '-${i + 1}',
            textKind: VfxTextKind.values[i % VfxTextKind.values.length],
            power: 0.85 + (i % 4) * 0.2,
            accent: accent,
          );
          i++;
        }
      }
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.dispose();
    });

    testWidgets('with reduced motion only the numbers are drawn',
        (tester) async {
      final controller = CombatVfxController();
      final foe = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Stack(children: [
          Positioned(
              left: 40,
              top: 40,
              width: 120,
              height: 100,
              child: SizedBox(key: foe)),
          Positioned.fill(
            child: CombatVfxLayer(controller: controller, reducedMotion: true),
          ),
        ]),
      ));
      controller.play(
          style: VfxStyle.meteor,
          target: foe,
          text: '-12',
          textKind: VfxTextKind.damage);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.dispose();
    });
  });

  group('a weapon sets the plain strike, and the power sets its size', () {
    test('each family strikes its own way', () {
      WeaponFamily of(String id, String name, int dmg) =>
          weaponFamilyOf(id, name, dmg);
      expect(of('spear_t3', 'Iron War Spear', 14), WeaponFamily.spear);
      expect(of('halo_lance', 'Halo Lance', 15), WeaponFamily.spear);
      expect(of('dagger_t1', 'Chipped Dagger', 4), WeaponFamily.dagger);
      expect(of('blackened_fang', 'Blackened Fang', 14), WeaponFamily.dagger);
      expect(of('staff_t6', 'Runed Staff', 13), WeaponFamily.staff);
      expect(of('sword_t3', 'Steel Broadsword', 12), WeaponFamily.sword);
      expect(of('sword_t6', 'Warforged Claymore', 21), WeaponFamily.greatsword);
      expect(of('shield_t1', 'Cracked Buckler', 0), WeaponFamily.bare);
      expect(styleForFace('Attack', null), VfxStyle.slash);
      expect(styleForFace('Attack', null, weapon: WeaponFamily.spear),
          VfxStyle.pierce);
      expect(styleForFace('Attack', null, weapon: WeaponFamily.bare),
          VfxStyle.impact);
      expect(styleForFace('Attack', null, weapon: WeaponFamily.dagger),
          VfxStyle.claw);
      expect(styleForFace('Attack', null, weapon: WeaponFamily.greatsword),
          VfxStyle.heavySlash);
      // A skill face keeps its own style whatever is in hand.
      expect(
          styleForFace('Skill', {'vfx': 'meteor'}, weapon: WeaponFamily.spear),
          VfxStyle.meteor);
    });

    test('a plain strike covers little, a legendary spell a lot', () {
      final plain = vfxExtentFor(VfxStyle.slash, 0.85);
      final heavy = vfxExtentFor(VfxStyle.heavySlash, 1.3);
      final meteor = vfxExtentFor(VfxStyle.meteor, 1.45);
      expect(plain, lessThan(0.55));
      expect(heavy, greaterThan(plain * 2));
      expect(meteor, greaterThan(heavy));
      expect(meteor, lessThanOrEqualTo(1.5));
      // The same style grows with its power.
      expect(vfxExtentFor(VfxStyle.fireball, 1.3),
          greaterThan(vfxExtentFor(VfxStyle.fireball, 0.9)));
      // Every style has a size.
      for (final style in VfxStyle.values) {
        expect(vfxGrandeur(style), inInclusiveRange(0.5, 1.3));
      }
    });
  });
}
