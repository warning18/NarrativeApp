import 'dart:math';

import 'random_names.dart';

/// Enemies that are creatures rather than people -- a hunt names them
/// with a beast-name ("Old Scar") instead of a given name plus epithet
/// ("Merrick the Half-Faced").
const Set<String> beastEnemyIds = {
  'harbor_rat',
  'rat_matriarch',
  'plague_hound',
  'void_wisp',
  'iron_golem',
  'void_stalker',
  'void_manifestation',
};

const List<String> _beastNames = [
  'Old Scar',
  'Mange',
  'Redmaw',
  'Bitterfang',
  'Sootback',
  'Halfear',
  'Gnawbone',
  'The Grey One',
  'Ashbelly',
  'Nightcough',
];

const List<String> _epithets = [
  'the Gutter-King',
  'the Unkillable',
  'Two-Knives',
  'the Ashen',
  'Widowmaker',
  'the Half-Faced',
  'Bonecollar',
  'the Hollow',
  'Blackhand',
  'the Quiet',
  'Saltbeard',
  'the Branded Twice',
];

/// A one-off name for a hunt's quarry of [enemyId] -- "Old Scar" for a
/// beast, "Merrick the Half-Faced" for a person. Never translated: a name
/// is a name in either language, as with `random_names.dart`.
String huntNameFor(String enemyId, Random random) {
  if (beastEnemyIds.contains(enemyId)) {
    return _beastNames[random.nextInt(_beastNames.length)];
  }
  final given = randomCharacterName('human', random);
  return '$given ${_epithets[random.nextInt(_epithets.length)]}';
}
