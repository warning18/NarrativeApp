// The professions' core mechanics (docs/proposals/profession-clan-mechanics.md,
// v5.2): the profession owns how the hero plays, built on the die and its
// resources, solo; the clans later bend it through their offers.
//
// - Warrior, Fury: each hit the hero lands, and each blow that gets through
//   to them, adds 1 Fury; at [furyMax] the next damaging face is a heavy
//   blow worth [furyHeavyMultiplier], and spends it all.
// - Cleric, the Watchfire: every heal from the die also burns the enemy
//   for its amount; healing past full feeds a fire (up to
//   [watchfireCapShare] of max health) that takes blows first, and what is
//   left of it at the round's end burns the enemy for
//   [_watchfireBurnMultiplier] times. Healing fatigue (fight_length.dart) is
//   its cost.
// - Mage, the Ash Well: the well starts each fight empty; mana from the
//   die comes [ashWellManaMultiplier] times; spells cost
//   [_ashWellSpellDiscount] less (never under 1); mana left after a win
//   heals [_ashWellHealPerMana] of max health a point.
// - Rogue, Flurry: a damaging face strikes twice at [_flurryHitShare] each,
//   each strike rolling its own critical.
// - Ranger, the Trail: the die is a deck: each run draws [trailDrawsPerRun]
//   of its faces, one sitting out at random, and none comes twice in a
//   run; the ranger sees the next face before it comes.
//
// Pure rules; the fight screen and the playthrough simulator play them.
import 'dart:math';

import 'combat_engine.dart';

/// A profession's core mechanic.
enum ProfessionCore { none, fury, watchfire, ashWell, flurry, trail }

/// The core of profession [professionId] (professions.json's ids).
ProfessionCore coreOfProfession(String? professionId) => switch (professionId) {
      'warrior' => ProfessionCore.fury,
      'cleric' => ProfessionCore.watchfire,
      'mage' => ProfessionCore.ashWell,
      'rogue' => ProfessionCore.flurry,
      'ranger' => ProfessionCore.trail,
      _ => ProfessionCore.none,
    };

// --- Fury ------------------------------------------------------------------

/// Fury that makes the next damaging face a heavy blow.
const int furyMax = 5;

/// What a heavy blow is worth.
const double furyHeavyMultiplier = 2.5;

// --- The Watchfire ---------------------------------------------------------

/// The most the fire holds, as a share of the cleric's max health.
const double watchfireCapShare = 0.5;

/// What the fire left at the round's end burns for, times itself.
const double _watchfireBurnMultiplier = 2.0;

/// What a heal from the die burns the enemy for, as a share of it.
const double watchfireHealBurnShare = 2.0;

/// The fire after healing [healing] at [currentHealth] of [maxHealth] with
/// [fire] already lit: the part past full feeds it, up to its cap.
int watchfireAfterHeal({
  required int fire,
  required int healing,
  required int currentHealth,
  required int maxHealth,
}) {
  final over = currentHealth + healing - maxHealth;
  if (over <= 0) return fire;
  return min((maxHealth * watchfireCapShare).round(), fire + over);
}

/// What the fire burns the enemy for at the round's end.
int watchfireBurn(int fire) => (fire * _watchfireBurnMultiplier).round();

// --- The Ash Well ----------------------------------------------------------

const int ashWellManaMultiplier = 2;
const int _ashWellSpellDiscount = 1;
const double _ashWellHealPerMana = 0.02;

/// A spell's cost under the Ash Well.
int ashWellSpellCost(int cost) => max(1, cost - _ashWellSpellDiscount);

/// What [mana] left after a win heals a hero of [maxHealth].
int ashWellHeal(int mana, int maxHealth) =>
    mana <= 0 ? 0 : (mana * maxHealth * _ashWellHealPerMana).round();

// --- Flurry ----------------------------------------------------------------

/// What each of a Flurry's two strikes is worth.
const double _flurryHitShare = 0.55;

/// The damage of a Flurry's two strikes of [first] and [second].
int flurryDamage(int first, int second) =>
    ((first + second) * _flurryHitShare).round();

// --- The Trail -------------------------------------------------------------

/// Faces a run of the Trail draws (one of a six-face die sits out).
const int trailDrawsPerRun = 5;

/// A ranger's die as a deck: [draw] takes the next face index; [peek] is
/// the one after, which the ranger sees coming.
class TrailDeck {
  TrailDeck(this.faceCount, this._random);

  final int faceCount;
  final Random _random;
  final List<int> _run = [];

  /// The last [draw] opened a run (its first face) and closed one (its
  /// last, the Verdict: specialisations.dart).
  bool drewFirst = false;
  bool drewVerdict = false;
  bool _fresh = false;

  void _refill() {
    _fresh = true;
    final order = List<int>.generate(faceCount, (i) => i)..shuffle(_random);
    final draws = min(trailDrawsPerRun, faceCount);
    _run.addAll(order.take(draws));
  }

  /// The next face index, taken off the deck.
  int draw() {
    if (faceCount <= 0) return 0;
    if (_run.isEmpty) _refill();
    drewFirst = _fresh;
    _fresh = false;
    final index = _run.removeAt(0);
    drewVerdict = _run.isEmpty;
    return index;
  }

  /// The run so far dropped: the next [draw] deals a new one (the Drowned
  /// Debt's kill, spec_variants.dart).
  void reshuffle() => _run.clear();

  /// The next [count] face indices the Trail deals, as far as this run
  /// goes (the Returned see two, spec_variants.dart).
  List<int> peekAhead(int count) {
    if (faceCount <= 0) return const [];
    if (_run.isEmpty) _refill();
    return _run.take(count).toList();
  }

  /// The face index the next [draw] gives (a new run is dealt if this one
  /// is spent).
  int peek() {
    if (faceCount <= 0) return 0;
    if (_run.isEmpty) _refill();
    return _run.first;
  }
}

/// [r] with its damage or mana changed (a core's work on the face).
PlayerActionResult coreResult(PlayerActionResult r, {int? damage, int? mana}) =>
    PlayerActionResult(
      damageDealt: damage ?? r.damageDealt,
      healingDone: r.healingDone,
      blockAmount: r.blockAmount,
      message: r.message,
      inflictedStatus: r.inflictedStatus,
      isCritical: r.isCritical,
      manaGained: mana ?? r.manaGained,
      extras: r.extras,
    );
