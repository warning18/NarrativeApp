// Old saves on the small scale (docs/proposals/stat-scale.md §4): a save
// written before the stat scale ([statScaleSaveVersion]) is rescaled once,
// as it loads, then saved with the new version so it never is again.
//
// - Max health, base damage and armor: divided by 5, rounded half up, an
//   amount that was not zero staying at least 1 ([rescaleAmount]).
// - Current health keeps its share of the max (a hero at 60% stays at
//   60%); a hero at 0 stays at 0. An ally's health likewise (a full one
//   stays full).
// - Abilities: the first 5 points kept, every 5 above as one
//   ([rescaleAbility]) -- a level-10 Str of 29 (five points a level) is 10,
//   about what one pick a level brings by then.
// - Unspent stat points become picks, one per level's worth (old points
//   ÷5, rounded up, so none is lost to rounding: [picksFromOldPoints]);
//   the pick on the table is drawn anew under the new rules.
// - Mana: kept as it is (its scale is unchanged); the next rest fills it
//   to the new pool.
//
// Pure: PlayerSession.fromJson runs [rescaledSave] on the raw map.
import 'dart:math';

/// The first save version on the small scale.
const int statScaleSaveVersion = 6;

/// Whether [json] (a raw save) predates the small scale: a save the game
/// wrote (every save since v1.226 carries its version) of an older
/// version. A map without a version -- a session built in code, a test's
/// -- is taken as it is.
bool statScaleDue(Map<String, dynamic> json) =>
    json['saveVersion'] is num &&
    (json['saveVersion'] as num).toInt() < statScaleSaveVersion;

/// [old] divided by 5, rounded half away from zero; not zero when [old]
/// was not.
int rescaleAmount(int old) {
  if (old == 0) return 0;
  final v = (old.abs() / 5).round() * old.sign;
  return v == 0 ? old.sign : v;
}

/// An ability of an old save: the first 5 points kept, every 5 above as
/// one (rounded).
int rescaleAbility(int old) => old <= 5 ? old : 5 + ((old - 5) / 5).round();

/// The picks [old] unspent stat points (five a level) are worth: one per
/// five, rounded up.
int picksFromOldPoints(int old) => old <= 0 ? 0 : (old + 4) ~/ 5;

/// [current] health of [oldMax], as a share of [newMax]: 0 stays 0, any
/// health left at least 1.
int rescaleCurrentHealth(int current, int oldMax, int newMax) {
  if (current <= 0) return 0;
  if (oldMax <= 0) return min(current, newMax);
  return (current * newMax / oldMax).round().clamp(1, newMax);
}

/// The abilities a save keeps (see [rescaleAbility]).
const List<String> _abilities = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];

/// [json] on the small scale when it predates it ([statScaleDue]), as it
/// was otherwise. Its saveVersion is left as written, so the other
/// migrations keyed on it still see the old version.
Map<String, dynamic> rescaledSave(Map<String, dynamic> json,
    {int allyFullHealth = 1 << 30}) {
  if (!statScaleDue(json)) return json;
  int read(String key, int fallback) =>
      (json[key] as num?)?.toInt() ?? fallback;
  final oldMax = read('maxHealth', 100);
  final newMax = max(1, rescaleAmount(oldMax));
  return {
    ...json,
    'maxHealth': newMax,
    'currentHealth':
        rescaleCurrentHealth(read('currentHealth', oldMax), oldMax, newMax),
    'baseDamage': max(1, rescaleAmount(read('baseDamage', 10))),
    'baseArmor': max(0, rescaleAmount(read('baseArmor', 0))),
    for (final stat in _abilities)
      if (json[stat] is num) stat: rescaleAbility((json[stat] as num).toInt()),
    'statPoints': picksFromOldPoints(read('statPoints', 0)),
    'statPickOffer': const [],
    if (json['recruitedAllies'] is List)
      'recruitedAllies': [
        for (final raw in json['recruitedAllies'] as List)
          if (raw is Map)
            {
              ...Map<String, dynamic>.from(raw),
              if (raw['currentHealth'] is num &&
                  (raw['currentHealth'] as num) < allyFullHealth)
                'currentHealth': max((raw['currentHealth'] as num) > 0 ? 1 : 0,
                    rescaleAmount((raw['currentHealth'] as num).toInt())),
            }
          else
            raw,
      ],
  };
}
