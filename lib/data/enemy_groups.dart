// The groups of the enemies that answer to no faction (the user's call of
// 16 November 2026, for the fight's stats blocks, UX-2's design C): the
// people of no clan get groups of their own, so that each block can wear
// its group's look. A group is a plain id on the enemy (enemies.json
// `group`); its name is the string `enemy_group_<id>` (lib/l10n).

/// The groups an enemy can name in its `group` field, in the order the
/// game database offers them.
const List<String> enemyGroupIds = [
  'hollow_court',
  'turned',
  'claimants',
  'champions',
  'void_cults',
  'spire',
  'common_folk',
];

/// The string key of [groupId]'s name (English and French in
/// lib/l10n/app_strings.dart).
String enemyGroupNameKey(String groupId) => 'enemy_group_$groupId';

/// What an enemy's look is grouped by: its own `group` when it names one,
/// else its `faction`, else its `kind` ('' when it has none of them).
String enemyGroupOf(Map<String, dynamic> enemy) {
  for (final key in const ['group', 'faction', 'kind']) {
    final value = enemy[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}
