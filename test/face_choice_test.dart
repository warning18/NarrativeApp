// The skill choice helper (face_choice.dart): what a skill on one face of a
// die would change, before and after, gain or loss, the rarity limit and
// why it can't go there, on the real starter die and skills.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/face_choice.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final skills = _table('skills');
  final faces = (((_table('dice')['starter_die'] as Map)['faces']) as List)
      .cast<Map<String, dynamic>>();
  const baseDamage = 3;

  FaceSkillChoice choose(int face, String skill,
          {Map<String, String> assignments = const {}}) =>
      faceSkillChoice(
        faces: faces,
        assignments: assignments,
        faceIndex: face,
        candidateId: skill,
        skills: skills,
        baseDamage: baseDamage,
      );

  test('the numbers are the fight\'s own: a Slash, a Heavy Blow', () {
    final slash = faceOutputWith(faces, 0, null, skills, baseDamage: 3);
    expect(slash.skillId, isNull);
    expect(slash.damage, 4); // 3 + the face's 1
    final heavy = faceOutputWith(faces, 2, null, skills, baseDamage: 3);
    expect(heavy.skillId, 'heavy_attack');
    expect(heavy.damage, 6); // (3 + 1) x 1.4
  });

  test('a stun for less damage on a skill face is weighed as a loss', () {
    final choice = choose(2, 'warrior_shield_bash');
    expect(choice.allowed, isTrue);
    expect(choice.before.damage, 6);
    expect(choice.after.damage, 4);
    expect(choice.after.status, isNotNull);
    expect(choice.effect, FaceChoiceEffect.loss);
  });

  test('a skill on a basic face works at channeled power, never below it', () {
    final onSlash = choose(0, 'heavy_attack');
    // 6 x 0.7 = 4, never below the Slash's own 4.
    expect(onSlash.after.damage, 4);
    expect(onSlash.effect, FaceChoiceEffect.same);
    final onGuard = choose(3, 'human_resolve');
    expect(onGuard.before.block, 1);
    expect(onGuard.after.heal, greaterThan(0));
    expect(onGuard.after.block, 0);
  });

  test('the rarity limit: an epic skill takes one face of a die', () {
    final first = choose(0, 'warrior_whirlwind');
    expect(first.allowed, isTrue);
    expect(first.maxFaces, 1);
    expect(first.usedFaces, 0);
    final second =
        choose(1, 'warrior_whirlwind', assignments: {'0': 'warrior_whirlwind'});
    expect(second.allowed, isFalse);
    expect(second.block, FaceChoiceBlock.rarityLimit);
    expect(second.full, isTrue);
    // Moved, not doubled: the face it is on can take it again.
    expect(
        choose(0, 'warrior_whirlwind', assignments: {'0': 'warrior_whirlwind'})
            .block,
        FaceChoiceBlock.alreadyThere);
  });

  test('a fixed face takes nothing, and says so', () {
    final fixed = [
      ...faces.take(5),
      {...faces[5], 'fixed': true},
    ];
    final choice = faceSkillChoice(
      faces: fixed,
      assignments: const {},
      faceIndex: 5,
      candidateId: 'heavy_attack',
      skills: skills,
      baseDamage: baseDamage,
    );
    expect(choice.block, FaceChoiceBlock.notOpen);
    expect(choice.effect, FaceChoiceEffect.same);
  });
}
