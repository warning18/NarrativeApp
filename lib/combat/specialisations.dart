// The main clans' specialisations (v5.2 step 2,
// docs/proposals/profession-clan-mechanics.md): each profession's core
// (profession_cores.dart) is bent by the clans it is linked to. The main
// clan of a specialisation offers it as a gift from Friend (offers.dart,
// GiftKind.spec), once; it stays for the run, and several stack.
//
// specialisations.json holds the words (Narrative's: the name, the gift's
// text and the clan's voice, EN and FR) and which profession and clan each
// one belongs to; the numbers are here.
//
// - Warrior (Fury):
//   - Berserker (Crows): Attack faces are Pain strikes (face_keywords.dart),
//     and the life a Pain strike costs adds one more Fury.
//   - Briar Guard (Compact): a blow the block and armour stop adds Fury, and
//     [briarReflectShare] of what they stopped goes back; no dodge.
//   - Lantern Vanguard (Dominion): the heavy blow is worth
//     [vanguardHeavyMultiplier], is Fire and Pierces;
//     against an Evil foe (one weak to Light) it heals
//     [vanguardEvilHealShare] of its damage.
// - Cleric (the Watchfire):
//   - Long Vigil (Vigil): above half health, [longVigilHealShare] of max
//     health mended each round.
//   - Ashen Hand (Penitents): whenever the fire burns (a heal's burn or the
//     round's), [ashenManaPerBurn] mana, [ashenMendShare] of the burn
//     mended, and one affliction cleansed.
//   - Beacon (Dominion): the fire holds up to the whole max health, and
//     every burn strikes every enemy, in Light, [beaconBurnMultiplier]
//     times.
// - Mage (the Ash Well):
//   - Censer Mage (Dominion): mana past full burns the enemy,
//     [censerBurnPerMana] of the strike per point.
//   - Burden-Bearer (Penitents): a spell cast from a full Well hits
//     [burdenFullWellMultiplier] times.
//   - Tempest Toll (Crows): spells heal [tempestLifeShare] of their damage;
//     the Crows offer Teleport Strike.
// - Rogue (Flurry):
//   - Fever Blade (Mire): a critical hit adds the Rot to its target, a
//     poison of [rotShare] of the hit that stacks and lasts the fight.
//   - Ledger Knife (Crows): each hit that isn't critical raises the next
//     one's chance by [ledgerChainStep] points; a critical resets it and
//     hits [ledgerCriticalMultiplier] times instead of the usual.
//   - Relicbreaker (Penitents): each critical hit gives 1 mana; at
//     [relicSureCritMana], the next strike is a sure critical and spends it.
// - Ranger (the Trail):
//   - Corsair's Eye (Crows): the Verdict, the last face of a run, counts
//     [verdictMultiplier] times and Pierces.
//   - Trapwright (Compact): the Verdict also stuns its target.
//   - Fen Guide (Mire): the first face of each run poisons its target.
//
// Pure rules; the fight screen and the playthrough simulator play them.
import 'dart:math';

import '../data/factions.dart';
import 'combat_engine.dart';
import 'profession_cores.dart';
import 'status_effect.dart';

export 'foe_kind.dart' show isEvilFoe;

/// The fifteen main specialisations, then the eight weak links' (step 3c,
/// [weakLinkSpecs]).
enum Spec {
  berserker,
  briarGuard,
  lanternVanguard,
  longVigil,
  ashenHand,
  beacon,
  censerMage,
  burdenBearer,
  tempestToll,
  feverBlade,
  ledgerKnife,
  relicbreaker,
  corsairsEye,
  trapwright,
  fenGuide,
  standfast,
  burningPenance,
  brimmingDraught,
  doubleKindling,
  lingeringHex,
  stitchThrust,
  pitchHand,
  secondBroadside,
}

/// The weak links' gifts (step 3c): a clan only weakly tied to a
/// profession offers one, half as often as a main clan its specialisation,
/// rare, and never with sub-clan gifts or a rank II.
const Set<Spec> weakLinkSpecs = {
  Spec.standfast,
  Spec.burningPenance,
  Spec.brimmingDraught,
  Spec.doubleKindling,
  Spec.lingeringHex,
  Spec.stitchThrust,
  Spec.pitchHand,
  Spec.secondBroadside,
};

/// Whether [spec] is one of the fifteen main specialisations.
bool isMainSpec(Spec spec) => !weakLinkSpecs.contains(spec);

/// A specialisation's id in specialisations.json and in a save.
String specId(Spec spec) => switch (spec) {
      Spec.berserker => 'berserker',
      Spec.briarGuard => 'briar_guard',
      Spec.lanternVanguard => 'lantern_vanguard',
      Spec.longVigil => 'long_vigil',
      Spec.ashenHand => 'ashen_hand',
      Spec.beacon => 'beacon',
      Spec.censerMage => 'censer_mage',
      Spec.burdenBearer => 'burden_bearer',
      Spec.tempestToll => 'tempest_toll',
      Spec.feverBlade => 'fever_blade',
      Spec.ledgerKnife => 'ledger_knife',
      Spec.relicbreaker => 'relicbreaker',
      Spec.corsairsEye => 'corsairs_eye',
      Spec.trapwright => 'trapwright',
      Spec.fenGuide => 'fen_guide',
      Spec.standfast => 'standfast',
      Spec.burningPenance => 'burning_penance',
      Spec.brimmingDraught => 'brimming_draught',
      Spec.doubleKindling => 'double_kindling',
      Spec.lingeringHex => 'lingering_hex',
      Spec.stitchThrust => 'stitch_thrust',
      Spec.pitchHand => 'pitch_hand',
      Spec.secondBroadside => 'second_broadside',
    };

/// The specialisation of id [id], or null.
Spec? specNamed(String? id) =>
    Spec.values.where((s) => specId(s) == id).firstOrNull;

/// The core a specialisation bends.
ProfessionCore coreOfSpec(Spec spec) => switch (spec) {
      Spec.berserker ||
      Spec.briarGuard ||
      Spec.lanternVanguard ||
      Spec.standfast ||
      Spec.burningPenance =>
        ProfessionCore.fury,
      Spec.longVigil ||
      Spec.ashenHand ||
      Spec.beacon ||
      Spec.brimmingDraught =>
        ProfessionCore.watchfire,
      Spec.censerMage ||
      Spec.burdenBearer ||
      Spec.tempestToll ||
      Spec.doubleKindling ||
      Spec.lingeringHex =>
        ProfessionCore.ashWell,
      Spec.feverBlade ||
      Spec.ledgerKnife ||
      Spec.relicbreaker ||
      Spec.stitchThrust ||
      Spec.pitchHand =>
        ProfessionCore.flurry,
      Spec.corsairsEye ||
      Spec.trapwright ||
      Spec.fenGuide ||
      Spec.secondBroadside =>
        ProfessionCore.trail,
    };

/// The main clan that offers a specialisation (specialisations.json's
/// `faction`, kept here for the fight: a test holds them equal).
String clanOfSpec(Spec spec) => switch (spec) {
      Spec.berserker ||
      Spec.tempestToll ||
      Spec.ledgerKnife ||
      Spec.corsairsEye =>
        'crows',
      Spec.briarGuard ||
      Spec.trapwright ||
      Spec.doubleKindling ||
      Spec.pitchHand =>
        'compact',
      Spec.lanternVanguard ||
      Spec.beacon ||
      Spec.censerMage ||
      Spec.secondBroadside =>
        'dominion',
      Spec.longVigil || Spec.standfast || Spec.stitchThrust => 'vigil',
      Spec.ashenHand ||
      Spec.burdenBearer ||
      Spec.relicbreaker ||
      Spec.burningPenance =>
        'penitents',
      Spec.feverBlade ||
      Spec.fenGuide ||
      Spec.brimmingDraught ||
      Spec.lingeringHex =>
        'mire',
    };

/// How a held specialisation plays with its clan's standing (v5.2 step 3,
/// "the more you are enemy with a clan, the less it gives you").
enum SpecStrength {
  /// As given.
  full,

  /// Resented or Hostile: every other round, and its sub-clan gifts and
  /// rank II go quiet.
  half,

  /// Hunted: it sleeps, gifts and all, until the clan is won back.
  asleep,
}

/// What standing [standing] with a specialisation's clan leaves of it.
SpecStrength specStrengthAt(num standing) =>
    switch (standingTierFor(standing)) {
      StandingTier.hunted => SpecStrength.asleep,
      StandingTier.hostile || StandingTier.resented => SpecStrength.half,
      _ => SpecStrength.full,
    };

/// The specialisation a held id ([specId], a sub-clan gift
/// `<subclan>_<spec>`, a rank `<spec>_ii`) belongs to, or null.
Spec? specOfHeldId(String id) {
  if (specNamed(id) case final spec?) return spec;
  for (final spec in Spec.values) {
    final sid = specId(spec);
    if (id == '${sid}_ii' || id.endsWith('_$sid')) return spec;
  }
  return null;
}

/// [held] (a character's specialisation ids, gifts and ranks) as their
/// clans' standings ([standingOf] a clan) leave them: the ids that still
/// play, and the specialisations that play only every other round.
({List<String> ids, Set<Spec> halved}) specsByStanding(
    Iterable<String> held, num Function(String clanId) standingOf) {
  final halved = <Spec>{};
  final ids = <String>[];
  for (final id in held) {
    final spec = specOfHeldId(id);
    if (spec == null) {
      ids.add(id);
      continue;
    }
    switch (specStrengthAt(standingOf(clanOfSpec(spec)))) {
      case SpecStrength.full:
        ids.add(id);
      case SpecStrength.half:
        if (specNamed(id) == spec) {
          ids.add(id);
          halved.add(spec);
        }
      case SpecStrength.asleep:
        break;
    }
  }
  return (ids: ids, halved: halved);
}

/// Whether a specialisation [halved] by its clan's standing plays in
/// [round] (1, 2, ...): the odd rounds.
bool halvedPlaysIn(int round) => round.isOdd;

/// The specialisations of [ids] (a save's, a character's) that bend
/// [core]: one held for another profession plays nothing.
Set<Spec> specsFor(Iterable<String> ids, ProfessionCore core) => {
      for (final id in ids)
        if (specNamed(id) case final spec? when coreOfSpec(spec) == core) spec,
    };

// --- Warrior ---------------------------------------------------------------

/// The Briar Guard: the share of a stopped blow that goes back.
const double briarReflectShare = 1 / 4;

/// What a Briar Guard sends back of [stopped] damage.
int briarReflect(int stopped) =>
    stopped <= 0 ? 0 : max(1, (stopped * briarReflectShare).round());

/// The Lantern Vanguard: what its heavy blow heals against an Evil foe, as
/// a share of its damage (the Order's upgrade raises it, step 2b).
const double vanguardEvilHealShare = 0.20;

/// What the Lantern Vanguard's heavy blow is worth (Fury's own is
/// furyHeavyMultiplier).
const double vanguardHeavyMultiplier = 2.85;

/// The heavy blow's element under the Lantern Vanguard.
const String vanguardElement = 'Fire';

// An Evil foe (the Vanguard's heal) is told by its kind: foe_kind.dart's
// isEvilFoe.

// --- Cleric ----------------------------------------------------------------

/// The Long Vigil: what is mended each round above half health.
const double longVigilHealShare = 0.05;

/// What the Long Vigil mends a cleric at [health] of [maxHealth] this
/// round (nothing at or below half).
int longVigilMend(int health, int maxHealth) =>
    health * 2 > maxHealth && health < maxHealth
        ? max(1, (maxHealth * longVigilHealShare).round())
        : 0;

/// The Ashen Hand: the mana a burn of the fire gives.
const int ashenManaPerBurn = 1;

/// The Ashen Hand: what a burn of the fire mends the cleric, as a share
/// of the burn.
const double ashenMendShare = 1.0;

/// The Beacon's burns are Light (an enemy weak to it takes more), and
/// burn this much harder.
const double beaconBurnMultiplier = 1.5;

/// The Beacon's burns are Light: an enemy weak to it takes more.
const String beaconElement = 'Light';

/// The Beacon's fire holds up to this share of max health.
const double beaconCapShare = 1.0;

/// The fire after healing, under the Beacon or not (see
/// watchfireAfterHeal).
int fireAfterHeal({
  required int fire,
  required int healing,
  required int currentHealth,
  required int maxHealth,
  required bool beacon,
}) {
  final over = currentHealth + healing - maxHealth;
  if (over <= 0) return fire;
  final cap =
      (maxHealth * (beacon ? beaconCapShare : watchfireCapShare)).round();
  return min(cap, fire + over);
}

// --- Mage ------------------------------------------------------------------

/// The Censer Mage: what each point of mana past full burns, as a share of
/// the mage's strike.
const double censerBurnPerMana = 3.0;

/// What [overflow] mana past full burns for a mage whose strike is
/// [strike].
int censerBurn(int overflow, int strike) =>
    overflow <= 0 ? 0 : max(1, (overflow * strike * censerBurnPerMana).round());

/// The Burden-Bearer: a spell cast from a full Well.
const double burdenFullWellMultiplier = 2.0;

/// The Tempest Toll: the share of a spell's damage it heals.
const double tempestLifeShare = 0.06;

/// The skill the Crows offer a Tempest Toll.
const String tempestSkillId = 'mage_teleport_strike';

// --- Rogue -----------------------------------------------------------------

/// The Fever Blade: the Rot a critical hit adds, as a share of the hit.
const double rotShare = 0.4;

/// The Rot lasts the fight.
const int rotTurns = 99;

/// [effects] with the Rot of a critical hit of [hit] added: the poison
/// there grows by it (the Rot stacks, where poison refreshes).
List<StatusEffect> withRot(List<StatusEffect> effects, int hit,
    {double share = rotShare}) {
  final add = hit <= 0 ? 0 : max(1, (hit * share).round());
  if (add == 0) return effects;
  final poison = poisonDamageFor(effects);
  return applyStatusEffect(
    effects,
    StatusEffect(
        type: StatusEffectType.poison,
        remainingTurns: rotTurns,
        magnitude: poison + add),
  );
}

/// The Ledger Knife: the chance each hit that isn't critical adds to the
/// next (in points), and what a critical hit is worth.
const double ledgerChainStep = 8;
const double ledgerCriticalMultiplier = 1.75;

/// A Ledger Knife's critical [damage] (dealt at the usual ×1.5): the same
/// hit at [ledgerCriticalMultiplier].
int ledgerCritical(int damage) => damage <= 0
    ? damage
    : (damage / criticalDamageMultiplier * ledgerCriticalMultiplier).round();

/// The Relicbreaker: mana that, gathered, makes the next strike a sure
/// critical hit (and is spent on it): a rogue has no spell to spend it on.
const int relicSureCritMana = 3;

// --- Ranger ----------------------------------------------------------------

/// Corsair's Eye: what the Verdict counts.
const double verdictMultiplier = 1.6;

/// The Trapwright's stun.
const StatusEffect trapStun =
    StatusEffect(type: StatusEffectType.stun, remainingTurns: 1);

/// The Fen Guide's poison: [fenPoisonShare] of the strike a turn, for
/// [fenPoisonTurns] turns.
const double fenPoisonShare = 0.5;
const int fenPoisonTurns = 3;

/// The Fen Guide's poison for a ranger whose strike is [strike].
StatusEffect fenPoison(int strike, {double share = fenPoisonShare}) =>
    StatusEffect(
        type: StatusEffectType.poison,
        remainingTurns: fenPoisonTurns,
        magnitude: max(1, (strike * share).round()));

// --- The weak links (step 3c) -----------------------------------------------
//
// - Standfast (Vigil, warrior): a Defend face adds 1 Fury.
// - Burning Penance (Penitents, warrior): a Mana face adds 1 Fury.
// - Brimming Draught (Mire, cleric): a potion's healing past full feeds the
//   Watchfire.
// - Double Kindling (Compact, mage): a Fire spell's reaction counts twice.
// - Lingering Hex (Mire, mage): a spell's status lasts
//   [lingeringHexTurns] more.
// - Stitch-Thrust (Vigil, rogue): healing past full strikes the foe for
//   [stitchThrustShare] of it.
// - Pitch Hand (Compact, rogue): Flurry's second hit slows its target
//   ([pitchSlow]).
// - Second Broadside (Dominion, ranger): once a fight, a face drawn that
//   would not strike goes back, and the Trail draws again.

/// The turns the Lingering Hex adds to a spell's status.
const int lingeringHexTurns = 1;

/// [status] as a Lingering Hex leaves it: [lingeringHexTurns] longer.
StatusEffect lingered(StatusEffect status) => StatusEffect(
    type: status.type,
    remainingTurns: status.remainingTurns + lingeringHexTurns,
    magnitude: status.magnitude);

/// The share of healing past full the Stitch-Thrust sends at the foe.
const double stitchThrustShare = 1.0;

/// What healing [healing] at [currentHealth] of [maxHealth] spills past
/// full (0 when it doesn't).
int overheal(int healing, int currentHealth, int maxHealth) =>
    max(0, currentHealth + healing - maxHealth);

/// What a Stitch-Thrust strikes for, from [over] spilled past full.
int stitchThrust(int over) =>
    over <= 0 ? 0 : max(1, (over * stitchThrustShare).round());

/// The Pitch Hand's slowing: a short, light Weaken.
const StatusEffect pitchSlow = StatusEffect(
    type: StatusEffectType.weaken, remainingTurns: 1, magnitude: 15);

/// Whether a face of [type] strikes (the Second Broadside keeps those).
bool faceStrikes(String type) => type == 'Attack' || type == 'Skill';

// --- The words -------------------------------------------------------------

/// specialisations.json's record of one: its profession and clan, and the
/// words (Narrative's).
class SpecInfo {
  const SpecInfo({
    required this.spec,
    required this.professionId,
    required this.factionId,
    this.name = '',
    this.nameFr = '',
    this.gift = '',
    this.giftFr = '',
    this.voice = '',
    this.voiceFr = '',
  });

  static SpecInfo? tryParse(String id, Object? raw) {
    final spec = specNamed(id);
    if (spec == null || raw is! Map) return null;
    String text(String key) => raw[key]?.toString() ?? '';
    return SpecInfo(
      spec: spec,
      professionId: text('profession'),
      factionId: text('faction'),
      name: text('name'),
      nameFr: text('name_fr'),
      gift: text('gift'),
      giftFr: text('gift_fr'),
      voice: text('voice'),
      voiceFr: text('voice_fr'),
    );
  }

  final Spec spec;
  final String professionId;
  final String factionId;
  final String name;
  final String nameFr;
  final String gift;
  final String giftFr;
  final String voice;
  final String voiceFr;

  String get id => specId(spec);
  String nameFor(bool french) => french && nameFr.isNotEmpty ? nameFr : name;
  String giftFor(bool french) => french && giftFr.isNotEmpty ? giftFr : gift;
  String voiceFor(bool french) =>
      french && voiceFr.isNotEmpty ? voiceFr : voice;
}

/// specialisations.json parsed, by id (records it doesn't know are left
/// out).
Map<String, SpecInfo> specInfosFrom(Map<String, dynamic> raw) => {
      for (final MapEntry(:key, :value) in raw.entries)
        if (SpecInfo.tryParse(key, value) case final info?) key: info,
    };

/// The specialisations [factionId] offers a character of [professionId].
List<SpecInfo> specsOfferedBy(
  Map<String, SpecInfo> specs, {
  required String factionId,
  required String professionId,
}) =>
    [
      for (final info in specs.values)
        if (info.factionId == factionId && info.professionId == professionId)
          info,
    ]..sort((a, b) => a.id.compareTo(b.id));

/// [r] with its damage, healing or status changed (a specialisation's
/// work on the face).
PlayerActionResult specResult(PlayerActionResult r,
        {int? damage, int? healing, StatusEffect? status}) =>
    PlayerActionResult(
      damageDealt: damage ?? r.damageDealt,
      healingDone: healing ?? r.healingDone,
      blockAmount: r.blockAmount,
      message: r.message,
      inflictedStatus: status ?? r.inflictedStatus,
      isCritical: r.isCritical,
      manaGained: r.manaGained,
      extras: r.extras,
    );
