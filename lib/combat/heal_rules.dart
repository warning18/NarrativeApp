// One healing rule for the fight screen and the playthrough simulator
// (v1.866, round 3 item C): what a heal in a fight heals, whatever it comes
// from. Before it, each heal path (a die's Heal face, a spell, a potion; on
// the screen and in the simulator) wrote its own copy of these steps, and
// the copies drifted apart (the Mending Light bug of v1.859; the
// simulator's cleric spell skipping the fight's length rule).
//
// The steps, in order:
// 1. the Anvil-Deaf's wall takes no Heal faces ([noHealFaces], a face only);
// 2. a shrine heals more ([shrineHealMultiplier]);
// 3. the fight's length rule (the ground: desert heat, rising water, the
//    sanctified ground: context_rules.dart), [roundRule];
// 4. healing fatigue (each heal a member gives this fight heals a little
//    less, fight_length.dart), [fatigue]: never a potion's, and never the
//    cleric's ([watchfire]: the Watchfire doesn't tire, it burns).
//
// What the heal then does past full (the Watchfire's fire, a mend sign's
// block) is [healFeedsFire] and the callers' own.
import 'battlefield_condition.dart' show shrineHealMultiplier;

/// Where a heal in a fight comes from.
enum HealSource { face, spell, potion }

/// What [raw] healing from [source] heals (the steps above). [roundRule]
/// is the fight's length rule for the round (null: none); [fatigue] tires a
/// heal and counts it (null: no fatigue, as the simulator without its
/// fatigue rule).
int healDealt({
  required HealSource source,
  required int raw,
  bool noHealFaces = false,
  bool shrine = false,
  bool watchfire = false,
  int Function(int amount)? roundRule,
  int Function(int amount)? fatigue,
}) {
  if (source == HealSource.face && noHealFaces) return 0;
  var healing = raw;
  if (healing <= 0) return healing;
  if (shrine) healing = (healing * shrineHealMultiplier).round();
  if (roundRule != null) healing = roundRule(healing);
  if (healing <= 0) return healing;
  final tires = source != HealSource.potion && !watchfire;
  return tires && fatigue != null ? fatigue(healing) : healing;
}

/// Whether a heal from [source] past full feeds the Watchfire: the cleric's
/// die and spells ([watchfire]); a potion only under the Brimming Draught.
bool healFeedsFire({
  required HealSource source,
  required bool watchfire,
  bool brimmingDraught = false,
}) =>
    source == HealSource.potion ? brimmingDraught : watchfire;
