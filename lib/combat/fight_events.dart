// What a fight tells the screen's looks as it happens (hooks for UX's fight
// panels and skill effects): each blow that lands, and each round's status
// ticks. Plumbing only: the fight publishes what it has already worked out
// (the damage, the critical roll, the skill and its element) after it has
// applied it, and nothing here is read back by a rule, so a listener can
// never change a fight's outcome. See docs/simulation/fight-hooks.md.
import 'dart:async';

import 'skill_vfx.dart' show VfxTier, vfxTierFor;
import 'status_effect.dart' show StatusEffectType;

/// Which side of the fight a hit or a tick landed on.
enum FightSide {
  /// One of the foes ([FightTarget.index] is its place in the fight's foes,
  /// 0 the first; [FightTarget.id] its key, `enemy_0`...).
  foe,

  /// The hero or an ally ([FightTarget.index] is its place in the party, 0
  /// the hero; [FightTarget.id] `player` or the companion's id).
  party,
}

/// Who a hit or a tick landed on.
class FightTarget {
  const FightTarget(this.side, this.index, this.id);

  final FightSide side;
  final int index;
  final String id;

  bool get isFoe => side == FightSide.foe;

  /// The hero himself (not an ally).
  bool get isPlayer => side == FightSide.party && id == 'player';

  @override
  bool operator ==(Object other) =>
      other is FightTarget &&
      other.side == side &&
      other.index == index &&
      other.id == id;

  @override
  int get hashCode => Object.hash(side, index, id);

  @override
  String toString() => 'FightTarget(${side.name} $index $id)';
}

/// Where a hit came from.
enum FightHitKind {
  /// A party member's Attack or Skill face on the foe it aimed at (all its
  /// blows: a Gale Cut's three count as one hit, [FightHitEvent.blows] 3).
  strike,

  /// The share of a strike that a Cleave, a Volley or a chain skill
  /// carries to another foe.
  splash,

  /// A Damage spell on one of its foes.
  spell,

  /// A foe's move on a party member.
  foeMove,
}

/// One hit, after it was applied.
class FightHitEvent {
  const FightHitEvent({
    required this.kind,
    required this.target,
    required this.amount,
    required this.power,
    required this.crit,
    required this.element,
    required this.round,
    this.source,
    this.skillId,
    this.blows = 1,
    this.dodged = false,
  });

  final FightHitKind kind;
  final FightTarget target;

  /// Who struck (a party member for a strike, a splash or a spell; the foe
  /// for a foe's move).
  final FightTarget? source;

  /// The health it took off [target] (0: blocked, absorbed or dodged).
  final int amount;

  /// How strongly the effect of this hit plays: vfxPowerFor (skill_vfx.dart)
  /// with the same inputs the fight's own effect is played with.
  final double power;

  /// [power] as a tier (vfxTierFor): light, normal, strong, mighty.
  VfxTier get tier => vfxTierFor(power);

  /// The engine's critical roll for the face (PlayerActionResult.isCritical:
  /// criticalChanceFor's roll, or a Momentum surge's guaranteed critical).
  /// A splash shares its strike's. Spells and foes' moves never crit.
  final bool crit;

  /// The skill behind it: the linked skill of a Skill face, the spell's id,
  /// the foe's move id; null for a plain Attack face, '' for a foe's plain
  /// attack.
  final String? skillId;

  /// The element it hit with, as the game data spells it: 'None' (physical),
  /// 'Fire', 'Ice', 'Water', 'Wind', 'Earth', 'Electricity', 'Light',
  /// 'Void'. A foe's plain attack is 'None'. Poison is a status, not an
  /// element: a poisoning skill says so through its [skillId].
  final String element;

  /// A strike's blows (a multi-blow skill); 1 otherwise.
  final int blows;

  /// A foe's move the member dodged ([amount] 0).
  final bool dodged;

  /// The round it landed in (1 the first).
  final int round;

  @override
  String toString() => 'FightHitEvent(${kind.name} $target -$amount '
      '${tier.name}${crit ? ' crit' : ''} skill=$skillId $element r$round)';
}

/// One status tick at the start of a round, after it was applied.
class FightStatusTickEvent {
  const FightStatusTickEvent({
    required this.target,
    required this.amount,
    required this.status,
    required this.round,
  });

  final FightTarget target;

  /// The health it took off [target].
  final int amount;

  /// The status that ticked. Poison is the only status that deals damage
  /// each round today; a burn status would tick through here too.
  final StatusEffectType status;

  /// [status] as a string id: 'poison'.
  String get statusId => status.name;

  final int round;

  @override
  String toString() =>
      'FightStatusTickEvent($target -$amount $statusId r$round)';
}

/// The fight's events, as streams: subscribe to [hits] and [ticks]. Both
/// are synchronous broadcast streams, so a listener runs at the moment the
/// fight publishes, before the screen rebuilds.
class FightEvents {
  final StreamController<FightHitEvent> _hits =
      StreamController<FightHitEvent>.broadcast(sync: true);
  final StreamController<FightStatusTickEvent> _ticks =
      StreamController<FightStatusTickEvent>.broadcast(sync: true);

  Stream<FightHitEvent> get hits => _hits.stream;
  Stream<FightStatusTickEvent> get ticks => _ticks.stream;

  /// Whether anyone listens to [hits] (the fight works a hit's power out
  /// only then).
  bool get hasHitListener => _hits.hasListener;

  /// Publishes [event] (the fight calls it; nothing to do with no listener).
  void hit(FightHitEvent event) {
    if (_hits.hasListener) _hits.add(event);
  }

  /// Publishes [event] (the fight calls it).
  void tick(FightStatusTickEvent event) {
    if (_ticks.hasListener) _ticks.add(event);
  }

  void dispose() {
    _hits.close();
    _ticks.close();
  }
}
