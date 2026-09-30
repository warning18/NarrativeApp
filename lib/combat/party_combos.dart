/// Party combos (v1.182): what the party's kept faces add up to when they
/// match, on top of what each face does alone. A roll becomes a team
/// puzzle -- keep the Attack that lines up with a friend's, reroll the one
/// that doesn't. A lone fighter never makes one: it takes two acting
/// members.
///
/// - [flank]: exactly two strikes -- each hits [comboStrikeMultiplier]
///   harder.
/// - [volley]: three strikes or more -- each hits as hard as a Flank and
///   also catches every other enemy standing for [volleySplashShare] of the
///   blow.
/// - [shelter]: a Defend and a Heal -- every Heal also mends each other
///   party member for [shelterShare] of it.
/// - [shieldWall]: two Defends or more -- every party member holds the
///   biggest block kept this round.
/// - [wellspring]: two Mana faces or more -- [wellspringMana] more mana.
enum PartyCombo { flank, volley, shelter, shieldWall, wellspring }

/// What a kept face does, for matching: the first of its effects in this
/// order (a strike that also heals is a strike).
enum FaceRole { strike, defend, heal, mana, none }

/// A Flank's (and a Volley's) damage multiplier on every strike.
const double comboStrikeMultiplier = 1.15;

/// The share of each Volley strike that catches the other enemies (a
/// Cleave face splashes more, see cleaveSplashShare).
const double volleySplashShare = 0.25;

/// The share of a Heal that a Shelter passes to each other party member.
const double shelterShare = 0.5;

/// The mana a Wellspring adds.
const int wellspringMana = 2;

/// The role of a face that deals [damage], blocks [block], heals [heal]
/// and gives [mana].
FaceRole faceRoleOf({
  required int damage,
  required int block,
  required int heal,
  required int mana,
}) {
  if (damage > 0) return FaceRole.strike;
  if (block > 0) return FaceRole.defend;
  if (heal > 0) return FaceRole.heal;
  if (mana > 0) return FaceRole.mana;
  return FaceRole.none;
}

/// The combos the acting party's kept faces make, one [FaceRole] per acting
/// member. Empty for fewer than two.
Set<PartyCombo> partyCombosFor(Iterable<FaceRole> roles) {
  final list = roles.toList();
  if (list.length < 2) return const {};
  int count(FaceRole role) => list.where((r) => r == role).length;
  final strikes = count(FaceRole.strike);
  final defends = count(FaceRole.defend);
  return {
    if (strikes == 2) PartyCombo.flank,
    if (strikes >= 3) PartyCombo.volley,
    if (defends >= 1 && count(FaceRole.heal) >= 1) PartyCombo.shelter,
    if (defends >= 2) PartyCombo.shieldWall,
    if (count(FaceRole.mana) >= 2) PartyCombo.wellspring,
  };
}

/// The multiplier [combos] put on every strike's damage.
double comboDamageMultiplier(Set<PartyCombo> combos) =>
    combos.contains(PartyCombo.flank) || combos.contains(PartyCombo.volley)
        ? comboStrikeMultiplier
        : 1.0;

/// [damage] after [combos]' multiplier.
int comboDamage(int damage, Set<PartyCombo> combos) {
  if (damage <= 0) return damage;
  final multiplier = comboDamageMultiplier(combos);
  return multiplier == 1.0 ? damage : (damage * multiplier).round();
}

/// The string key of [combo]'s name ('combo_flank') and of its rules line
/// ('combo_flank_desc').
String comboLabelKey(PartyCombo combo) => 'combo_${combo.name}';
String comboDescriptionKey(PartyCombo combo) => 'combo_${combo.name}_desc';
