// The dice's own rules (v1.182): face keywords, party combos, duo
// techniques, the enemies' tampering and Luck nudges -- the pure rules, and
// the data that uses them.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_tamper.dart';
import 'package:narrative_data_app/combat/duo_techniques.dart';
import 'package:narrative_data_app/combat/party_combos.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/l10n/dice_names_fr.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

DiceFaceResult _face(String type, int value,
        {String skill = '', Set<FaceKeyword> keywords = const {}}) =>
    DiceFaceResult(
      faceIndex: 0,
      faceName: type,
      type: type,
      value: value,
      linkedSkillID: skill,
      element: 'None',
      keywords: keywords,
    );

void main() {
  group('face keywords', () {
    test('read from a face record, unknown names skipped', () {
      expect(
          faceKeywordsOf({
            'keywords': ['Cleave', 'pain', 'nonsense']
          }),
          {FaceKeyword.cleave, FaceKeyword.pain});
      expect(faceKeywordsOf({'type': 'Attack'}), isEmpty);
      final face = faceFromJson({
        'type': 'Attack',
        'value': 5,
        'keywords': ['steady'],
      }, 2);
      expect(face.hasKeyword(FaceKeyword.steady), isTrue);
      expect(face.faceIndex, 2);
      // Copies keep them.
      expect(face.withValue(9).keywords, {FaceKeyword.steady});
      expect(face.channeling('heavy_attack').keywords, {FaceKeyword.steady});
    });

    test('strike keywords only fit faces that hit', () {
      for (final k in strikeKeywords) {
        expect(keywordFitsFaceType(k, 'Attack'), isTrue);
        expect(keywordFitsFaceType(k, 'Skill'), isTrue);
        expect(keywordFitsFaceType(k, 'Defend'), isFalse);
        expect(keywordFitsFaceType(k, 'Heal'), isFalse);
      }
      expect(keywordFitsFaceType(FaceKeyword.steady, 'Defend'), isTrue);
      expect(keywordFitsFaceType(FaceKeyword.growth, 'Mana'), isFalse);
      expect(keywordFitsFaceType(FaceKeyword.echo, 'Mana'), isTrue);
    });

    test('Pain costs a share of the max, never the last point', () {
      expect(painCost(maxHealth: 100, currentHealth: 100), 8);
      expect(painCost(maxHealth: 100, currentHealth: 5), 4);
      expect(painCost(maxHealth: 100, currentHealth: 1), 0);
      expect(painCost(maxHealth: 5, currentHealth: 5), 1);
    });

    test('every keyword on a die face is known and fits the face', () {
      final dice = _load('dice.json');
      var keyworded = 0;
      for (final die in dice.entries) {
        for (final face in ((die.value as Map)['faces'] as List).cast<Map>()) {
          final raw = (face['keywords'] as List?) ?? const [];
          for (final name in raw) {
            final keyword = faceKeywordNamed(name.toString());
            expect(keyword, isNotNull, reason: '${die.key}: $name');
            expect(
                keywordFitsFaceType(keyword!, face['type'].toString()), isTrue,
                reason: '${die.key}: $name on ${face['type']}');
            keyworded++;
          }
        }
      }
      expect(keyworded, greaterThan(20));
      // Every keyword turns up on some die.
      final all = {
        for (final die in dice.values)
          for (final face in ((die as Map)['faces'] as List).cast<Map>())
            ...faceKeywordsOf(face.cast<String, dynamic>()),
      };
      expect(all, FaceKeyword.values.toSet());
    });

    test('the new keyword dice are sold and named in French', () {
      final shops = _load('shops.json');
      for (final id in ['headsman_die', 'greenwood_die', 'chorus_die']) {
        expect(
            shops.values.any((s) =>
                ((s as Map)['diceStock'] as List? ?? const []).contains(id)),
            isTrue,
            reason: id);
        expect(diceNamesFr[id], isNotNull, reason: id);
      }
    });

    test('names and rules in both languages', () {
      for (final k in FaceKeyword.values) {
        for (final lang in AppLanguage.values) {
          expect(trFor(lang, keywordLabelKey(k)), isNot(keywordLabelKey(k)));
          expect(trFor(lang, keywordDescriptionKey(k)),
              isNot(keywordDescriptionKey(k)));
        }
      }
    });
  });

  group('party combos', () {
    const s = FaceRole.strike, d = FaceRole.defend;
    const h = FaceRole.heal, m = FaceRole.mana;

    test('a lone fighter never makes one', () {
      for (final role in FaceRole.values) {
        expect(partyCombosFor([role]), isEmpty);
      }
    });

    test('two strikes flank, three volley', () {
      expect(partyCombosFor([s, s]), {PartyCombo.flank});
      expect(partyCombosFor([s, s, s]), {PartyCombo.volley});
      expect(partyCombosFor([s, s, d]), {PartyCombo.flank});
      expect(partyCombosFor([s, d]), isEmpty);
    });

    test('guards and heals, mana', () {
      expect(partyCombosFor([d, h]), {PartyCombo.shelter});
      expect(partyCombosFor([d, d]), {PartyCombo.shieldWall});
      expect(partyCombosFor([d, d, h]),
          {PartyCombo.shieldWall, PartyCombo.shelter});
      expect(partyCombosFor([m, m, s]), {PartyCombo.wellspring});
      expect(partyCombosFor([FaceRole.none, FaceRole.none]), isEmpty);
    });

    test('a Flank or a Volley lands every strike harder', () {
      expect(comboDamage(20, {PartyCombo.flank}), 23);
      expect(comboDamage(20, {PartyCombo.volley}), 23);
      // A Volley's splash is lighter than a Cleave's.
      expect(volleySplashShare, lessThan(cleaveSplashShare));
      expect(comboDamage(10, {PartyCombo.shelter}), 10);
      expect(comboDamage(0, {PartyCombo.flank}), 0);
    });

    test('a face plays the role of its first effect', () {
      expect(faceRoleOf(damage: 5, block: 0, heal: 3, mana: 0), s);
      expect(faceRoleOf(damage: 0, block: 4, heal: 0, mana: 0), d);
      expect(faceRoleOf(damage: 0, block: 0, heal: 4, mana: 0), h);
      expect(faceRoleOf(damage: 0, block: 0, heal: 0, mana: 2), m);
      expect(faceRoleOf(damage: 0, block: 0, heal: 0, mana: 0), FaceRole.none);
    });

    test('named in both languages', () {
      for (final combo in PartyCombo.values) {
        for (final lang in AppLanguage.values) {
          expect(
              trFor(lang, comboLabelKey(combo)), isNot(comboLabelKey(combo)));
          expect(trFor(lang, comboDescriptionKey(combo)),
              isNot(comboDescriptionKey(combo)));
        }
      }
    });
  });

  group('duo techniques', () {
    final companions = _load('companions.json');
    final dice = _load('dice.json');

    test('every duo pairs two real companions, and every companion has one',
        () {
      for (final duo in duoTechniques) {
        expect(companions, contains(duo.first), reason: duo.id);
        expect(companions, contains(duo.second), reason: duo.id);
        expect(duo.first, isNot(duo.second));
        expect(duo.nameEn.trim(), isNotEmpty);
        expect(duo.nameFr.trim(), isNotEmpty);
      }
      for (final id in companions.keys) {
        expect(duosOf(id), isNotEmpty, reason: id);
      }
      expect(duoTechniques.map((d) => d.id).toSet(), hasLength(8));
    });

    test('Tobin and Malrik, who never share a party, share no duo', () {
      expect(duoFor('tobin', 'malrik'), isNull);
      expect(duoFor('kelda', 'grosh')?.id, 'anvil_and_hammer');
    });

    test('every companion die has a signature face to fire one with', () {
      for (final companion in companions.values) {
        final die = dice[(companion as Map)['signatureDiceId']] as Map;
        final signature = (die['faces'] as List).cast<Map>().where((f) =>
            f['type'] == 'Skill' &&
            f['linkedSkillID'] != '' &&
            f['linkedSkillID'] != 'heavy_attack');
        expect(signature, isNotEmpty, reason: companion['companionID']);
      }
    });

    test('both need the friendly tier and a signature face', () {
      DuoCandidate c(String id, {int approval = 8, bool sig = true}) =>
          DuoCandidate(
              companionId: id, approval: approval, onSignatureFace: sig);
      expect(
          duosFiring([c('grosh'), c('kelda')]).single.id, 'anvil_and_hammer');
      expect(duosFiring([c('grosh'), c('kelda', approval: 4)]), isEmpty);
      expect(duosFiring([c('grosh'), c('kelda', sig: false)]), isEmpty);
      expect(duosFiring([c('grosh')]), isEmpty);
    });

    test('a companion takes part in one duo a round', () {
      final firing = duosFiring([
        DuoCandidate(companionId: 'grosh', approval: 12, onSignatureFace: true),
        DuoCandidate(companionId: 'kelda', approval: 12, onSignatureFace: true),
        DuoCandidate(
            companionId: 'malrik', approval: 12, onSignatureFace: true),
      ]);
      expect(firing, hasLength(1));
      expect(firing.single.id, 'anvil_and_hammer');
      expect(duoPower(20, 15), 35);
    });
  });

  group('dice tampering', () {
    test('a Curse turns any face into a painful strike', () {
      final guard = cursedFace(_face('Defend', 6));
      expect(guard.type, 'Attack');
      expect(guard.value, 6);
      expect(guard.hasKeyword(FaceKeyword.pain), isTrue);
      final skill = cursedFace(_face('Skill', 0, skill: 'rogue_backstab'));
      expect(skill.type, 'Skill');
      expect(skill.linkedSkillID, 'rogue_backstab');
      expect(skill.hasKeyword(FaceKeyword.pain), isTrue);
    });

    test('a Silence blanks skill faces, and a channeled skill falls back', () {
      expect(silencedFace(_face('Skill', 0, skill: 'fireball')).type, 'Empty');
      final channeled = _face('Attack', 7).channeling('fireball');
      final back = silencedFace(channeled);
      expect(back.type, 'Attack');
      expect(back.value, 7);
      expect(silencedFace(_face('Heal', 5)).type, 'Heal');
    });

    test('a Mirror sends back the best blow, within bounds', () {
      expect(mirrorDamage(bestPartyHit: 30, enemyDamage: 20), 30);
      expect(mirrorDamage(bestPartyHit: 100, enemyDamage: 20), 40);
      expect(mirrorDamage(bestPartyHit: 0, enemyDamage: 20), 10);
    });

    test('a Curse picks a face not yet cursed; a Hex the best die', () {
      final random = Random(3);
      expect(curseTargetFace(6, {0, 1, 2, 3, 4}, random), 5);
      expect(curseTargetFace(3, {0, 1, 2}, random), isNull);
      expect(hexVictim({'player': 12, 'grosh': 20, 'kelda': 3}), 'grosh');
      expect(hexVictim(const {}), isNull);
    });

    test('the tamper skills read as moves, and enemies use each of them', () {
      final skills = _load('skills.json');
      final enemies = _load('enemies.json');
      final used = <DiceTamper>{};
      for (final enemy in enemies.values) {
        for (final move in ((enemy as Map)['skillMoves'] as List? ?? const [])
            .cast<Map>()) {
          final skill = skills[move['skillID']] as Map<String, dynamic>?;
          final tamper = diceTamperNamed(skill?['tamper']?.toString());
          if (tamper != null) used.add(tamper);
        }
      }
      expect(used, DiceTamper.values.toSet());

      EnemyMoveResult moveWith(String skillId) => resolveEnemyMove(
            enemy: {
              'enemyName': 'Test',
              'damage': 20,
              'skillMoves': [
                {'skillID': skillId, 'condition': 'Always', 'priority': 1},
              ],
            },
            skills: skills,
            enemyCurrentHealth: 100,
            enemyMaxHealth: 100,
            random: Random(1),
          );
      final hex = moveWith('hex_of_ill_luck');
      expect(hex.intent, EnemyIntent.tamper);
      expect(hex.tamper, DiceTamper.hex);
      expect(hex.damage, 0);
      expect(categoryFor(hex), MoveCategory.tamper);
      final mirror = moveWith('glass_reflection');
      expect(mirror.intent, EnemyIntent.attack);
      expect(categoryFor(mirror), MoveCategory.mirror);
      expect(moveWith('rotting_mark').tamper, DiceTamper.curse);
      expect(moveWith('edict_of_silence').tamper, DiceTamper.silence);
    });

    test('no tampering in chapters 1 and 2', () {
      final skills = _load('skills.json');
      final enemies = _load('enemies.json');
      for (final entry in enemies.entries) {
        final enemy = entry.value as Map;
        final tampers = (enemy['skillMoves'] as List? ?? const [])
            .cast<Map>()
            .any((m) => (skills[m['skillID']] as Map?)?['tamper'] != null);
        if (!tampers) continue;
        expect((enemy['minChapter'] as num?)?.toInt() ?? 1,
            greaterThanOrEqualTo(3),
            reason: entry.key);
      }
    });
  });

  group('Luck nudges', () {
    test('every three points of Luck, up to three', () {
      expect(nudgesForLuck(0), 0);
      expect(nudgesForLuck(2), 0);
      expect(nudgesForLuck(3), 1);
      expect(nudgesForLuck(8), 2);
      expect(nudgesForLuck(40), maxNudges);
    });

    test('opposite faces pair up across the die', () {
      expect(oppositeFaceIndex(0, 6), 5);
      expect(oppositeFaceIndex(2, 6), 3);
      expect(oppositeFaceIndex(5, 6), 0);
      expect(oppositeFaceIndex(1, 4), 2);
      for (var i = 0; i < 6; i++) {
        expect(oppositeFaceIndex(oppositeFaceIndex(i, 6), 6), i);
      }
    });
  });
}
