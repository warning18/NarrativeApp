// The groups of the enemies that answer to no faction (the user's call of
// 16 November 2026, for the fight's stats blocks, UX-2's design C): the
// people of no clan get groups of their own, so that each block can wear
// its group's look. A group is a plain id on the enemy (enemies.json
// `group`): one of [enemyGroupIds], whose name is the string
// `enemy_group_<id>` (lib/l10n), or a faction's id when the enemy wears a
// clan's look without fighting under it (the Horn-Taker, the Dominion's).
// It is the look only: the rules read `faction`. A group wins over the
// faction (Cassian Oriel, of the Dominion, is one of the Claimants).

/// The groups of their own an enemy can name in its `group` field.
const List<String> enemyGroupIds = [
  'hollow_court',
  'turned',
  'claimants',
  'champions',
  'void_cults',
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
