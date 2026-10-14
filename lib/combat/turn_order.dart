/// Who acts first in the party's round (v1.213): the quickest, by
/// Dexterity. Ties keep the party's own order (the player first, then the
/// companions as they joined), so a party of equals plays as it always did.
List<T> actingOrder<T>(List<T> members, int Function(T) dexterity) {
  final indexed = [
    for (var i = 0; i < members.length; i++) (i, members[i]),
  ];
  indexed.sort((a, b) {
    final byDex = dexterity(b.$2).compareTo(dexterity(a.$2));
    return byDex != 0 ? byDex : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
