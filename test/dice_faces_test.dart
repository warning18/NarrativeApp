// Dice faces: every face is named after the skill it casts, basic faces
// take a skill at channeled power, fixed faces keep their signature, and
// the dice data stays consistent with those rules.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name');
}

DiceFaceResult _face(String type, int value, [String linked = '']) =>
    DiceFaceResult(
      faceIndex: 0,
      faceName: '',
      type: type,
      value: value,
      linkedSkillID: linked,
      element: 'None',
    );

void main() {
  final dice = _loadGamedata('dice.json');
  final skills = _loadGamedata('skills.json');
  final shops = _loadGamedata('shops.json');

  group('names', () {
    test('skill names drop race and profession prefixes', () {
      expect(skillDisplayName('warrior_shield_bash'), 'Shield Bash');
      expect(skillDisplayName('heavy_attack'), 'Heavy Attack');
      expect(skillDisplayName('mage_meteor'), 'Meteor');
      expect(skillDisplayName('human_resolve'), 'Resolve');
      expect(dieDisplayName('twinfang_die'), 'Twinfang Die');
    });

    test('a face is named after its skill, or its basic action', () {
      final slash = {'type': 'Attack', 'value': 5, 'faceName': 'Slash'};
      expect(faceDisplayName(slash, language: AppLanguage.en), 'Attack');
      expect(
          faceDisplayName(slash,
              assignedSkillId: 'power_strike', language: AppLanguage.en),
          'Power Strike');
      final fireball = {
        'type': 'Skill',
        'linkedSkillID': 'fireball',
        'faceName': 'Fireball'
      };
      expect(
          faceDisplayName(fireball,
              assignedSkillId: 'power_strike', language: AppLanguage.en),
          'Fireball',
          reason: 'a signature face ignores a stale pick');
      expect(
          faceDisplayName({'type': 'Defend', 'value': 5},
              language: AppLanguage.fr),
          'Garde');
    });
  });

  group('which faces are open', () {
    test('basic faces and generic skill faces are open; signatures fixed', () {
      expect(isAssignableFace({'type': 'Attack', 'value': 5}), isTrue);
      expect(isAssignableFace({'type': 'Defend', 'value': 5}), isTrue);
      expect(isAssignableFace({'type': 'Heal', 'value': 8}), isTrue);
      expect(isAssignableFace({'type': 'Skill', 'linkedSkillID': ''}), isTrue);
      expect(
          isAssignableFace({'type': 'Skill', 'linkedSkillID': 'heavy_attack'}),
          isTrue);
      expect(isAssignableFace({'type': 'Skill', 'linkedSkillID': 'fireball'}),
          isFalse);
      expect(isAssignableFace({'type': 'Mana', 'value': 2}), isFalse);
      expect(isAssignableFace({'type': 'Attack', 'value': 5, 'fixed': true}),
          isFalse);
    });

    test('a die lends its signature skills to whoever holds it', () {
      expect(dieSignatureSkillIds(dice['flame_die'] as Map<String, dynamic>),
          containsAll(['fireball', 'mage_meteor']));
      expect(dieSignatureSkillIds(dice['starter_die'] as Map<String, dynamic>),
          isEmpty);
    });
  });

  group('applying a pick to a rolled face', () {
    test('a skill face takes the picked skill at full power', () {
      final rolled = applyFaceAssignment(_face('Skill', 0),
          {'type': 'Skill', 'linkedSkillID': ''}, 'fireball');
      expect(rolled.type, 'Skill');
      expect(rolled.linkedSkillID, 'fireball');
      expect(rolled.isChanneled, isFalse);
      expect(rolled.faceName, 'Fireball');
    });

    test('a basic face channels the picked skill', () {
      final rolled = applyFaceAssignment(
          _face('Attack', 5), {'type': 'Attack', 'value': 5}, 'heavy_attack');
      expect(rolled.type, 'Skill');
      expect(rolled.channeledFrom, 'Attack');
      expect(rolled.value, 5);
      expect(rolled.faceName, 'Heavy Attack');
    });

    test('a fixed face ignores a pick and a bare face keeps its action', () {
      final fixed = applyFaceAssignment(_face('Skill', 0, 'fireball'),
          {'type': 'Skill', 'linkedSkillID': 'fireball'}, 'power_strike');
      expect(fixed.linkedSkillID, 'fireball');
      final bare = applyFaceAssignment(
          _face('Defend', 5), {'type': 'Defend', 'value': 5}, null);
      expect(bare.type, 'Defend');
      expect(bare.faceName, 'Guard');
    });
  });

  group('channeled power', () {
    test('a channeled damage skill hits at 70%, never below the Attack face',
        () {
      // heavy_attack: (10 + 6) * 1.4 = 22 at full power.
      final full = resolvePlayerFace(
          _face('Skill', 0, 'heavy_attack'), skills, 10,
          luck: -1000);
      expect(full.damageDealt, 22);
      final channeled = resolvePlayerFace(
          _face('Attack', 5).channeling('heavy_attack'), skills, 10,
          luck: -1000);
      expect(channeled.damageDealt, (22 * channeledSkillPower).round());
      // power_strike: (10 + 5) * 1.0 = 15 -> 70% is 11, but the Attack 8
      // face alone would hit for 18, so the floor holds.
      final floored = resolvePlayerFace(
          _face('Attack', 8).channeling('power_strike'), skills, 10,
          luck: -1000);
      expect(floored.damageDealt, 18);
    });

    test('a channeled heal is scaled, never below a Heal face\'s own amount',
        () {
      final guard = resolvePlayerFace(
          _face('Defend', 5).channeling('quick_heal'), skills, 10);
      expect(guard.healingDone, (14 * channeledSkillPower).round());
      expect(guard.blockAmount, 0);
      final heal = resolvePlayerFace(
          _face('Heal', 12).channeling('quick_heal'), skills, 10);
      expect(heal.healingDone, 12);
    });

    test('a channeled skill the actor cannot use falls back to the face', () {
      final result = resolvePlayerFace(
          _face('Defend', 6).channeling('no_such_skill'), skills, 10);
      expect(result.blockAmount, 6);
    });
  });

  group('dice data', () {
    test('every die is well formed and every linked skill exists', () {
      const types = {'Attack', 'Defend', 'Skill', 'Heal', 'Mana'};
      for (final entry in dice.entries) {
        final faces = (entry.value as Map<String, dynamic>)['faces'] as List;
        expect(faces, isNotEmpty, reason: entry.key);
        for (final raw in faces) {
          final face = raw as Map<String, dynamic>;
          expect(types, contains(face['type']), reason: entry.key);
          final linked = face['linkedSkillID']?.toString() ?? '';
          if (linked.isNotEmpty) {
            expect(skills, contains(linked), reason: '${entry.key}: $linked');
          }
        }
      }
    });

    test('every die a shop sells exists, and the new dice are for sale', () {
      final sold = <String>{};
      for (final shop in shops.values) {
        for (final id
            in ((shop as Map<String, dynamic>)['diceStock'] as List?) ??
                const []) {
          expect(dice, contains(id));
          sold.add(id.toString());
        }
      }
      expect(
          sold,
          containsAll([
            'gambler_die',
            'frost_die',
            'twinfang_die',
            'bulwark_die',
            'pilgrim_die',
            'tempest_die',
          ]));
    });

    test('every die a player can buy has at least one open face', () {
      for (final entry in dice.entries) {
        final faces = ((entry.value as Map<String, dynamic>)['faces'] as List)
            .cast<Map<String, dynamic>>();
        expect(faces.any(isAssignableFace), isTrue, reason: entry.key);
      }
    });
  });
}
