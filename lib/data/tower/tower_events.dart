// The Tower's floor events (floor events PR 1,
// docs/proposals/tower-snakes-and-ladders.md): some ordinary floors hold a
// setback (the story's d20 check after the win: fail, and the climb goes
// down a few floors) or a rival (win within a few rounds and skip the next
// floor). Drawn per floor from their own stream (TowerStream.board), so no
// other draw moves; a run whose TowerRun.events is 0 meets none and plays
// as before. Pure: towerAfterFight and towerPick resolve them, the screen
// reads towerEventOf.

import 'dart:math';

import '../../combat/fight_numbers.dart' show potionHealAmount;
import '../ability_check.dart' show checkBonusFor, checkChance, checkPasses;
import '../sim_combat.dart' show SimCharacter;
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

/// What a floor's event is. (A kind added later goes last: the shortcut of
/// floor events PR 2.)
enum TowerEventKind {
  /// The setback: the d20 check after the win and the card.
  test,

  /// The rival: the floor's fight won within [towerRivalRounds] rounds
  /// skips the next floor.
  rival,
}

/// How an event ended (saved, TowerRun.lastEvent): shown until the next
/// fight ends, or replaced by the next event's.
class TowerEventResult {
  const TowerEventResult({
    required this.kind,
    this.roll,
    this.total,
    required this.passed,
    required this.from,
    required this.to,
  });

  factory TowerEventResult.fromJson(Map<String, dynamic> json) =>
      TowerEventResult(
        kind: TowerEventKind.values.byName(json['kind'] as String),
        roll: (json['roll'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
        passed: json['passed'] == true,
        from: (json['from'] as num).toInt(),
        to: (json['to'] as num).toInt(),
      );

  final TowerEventKind kind;

  /// The test's d20 and its total with the modifier; null for a rival.
  final int? roll;
  final int? total;

  /// The test passed, or the rival beaten in time.
  final bool passed;

  /// The floor the event was on, and the floor it sent the run to (the
  /// next one, a fall's, a skip's landing).
  final int from;
  final int to;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (roll != null) 'roll': roll,
        if (total != null) 'total': total,
        'passed': passed,
        'from': from,
        'to': to,
      };

  @override
  bool operator ==(Object other) =>
      other is TowerEventResult &&
      other.kind == kind &&
      other.roll == roll &&
      other.total == total &&
      other.passed == passed &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, roll, total, passed, from, to);
}

/// What the floor screen shows of [TowerRun.floor]'s event (towerEventOf).
class TowerEventView {
  const TowerEventView({
    required this.kind,
    required this.floor,
    required this.revisit,
    required this.setbacksLeft,
    this.ability,
    this.dc,
    this.modifier,
    this.chance,
    this.fallTo,
    this.gain,
    this.rounds,
    this.landsOn,
    this.result,
  });

  /// The floor's event; null when it has none (a floor met again, or one
  /// shown only for [result]).
  final TowerEventKind? kind;

  /// The floor it is on (the run's floor).
  final int floor;

  /// The floor is met again (at or below TowerRun.crest): it pays nothing,
  /// no spoils, no card, no healing, no event (the "no reward" line).
  final bool revisit;

  /// The setbacks the run may still take ([towerSetbacksPerRun] less those
  /// taken).
  final int setbacksLeft;

  /// A test: the ability checked (strength, dexterity or wisdom), its DC,
  /// the hero's modifier as it stands now (checkBonusFor), the chance to
  /// pass (checkChance, 0.05 to 0.95), the floor a fail lands on, and the
  /// potions a pass gives.
  final String? ability;
  final int? dc;
  final int? modifier;
  final double? chance;
  final int? fallTo;
  final int? gain;

  /// A rival: the rounds to win within, and the floor a win lands on.
  final int? rounds;
  final int? landsOn;

  /// The last event's end (TowerRun.lastEvent), until the next fight ends.
  final TowerEventResult? result;
}

/// A floor's event as the seed draws it, before the run's state is read.
class _Drawn {
  const _Drawn(this.kind, this.fall, this.roll);
  final TowerEventKind kind;
  final int fall;
  final int roll;
}

bool _isGate(int floor) => towerBudgetOf(floor).kind != TowerFloorKind.fight;

/// The event the run of [seed] holds on [floor], drawn from its own stream
/// (TowerStream.board): a draw, the fall (1 to [towerSetbackMaxFall]) and
/// the d20, in that order, on every ordinary floor; a rival under
/// [towerRivalShare] where a skip fits, a setback in the next
/// [towerSetbackShare].
_Drawn? _drawn(int seed, int floor) {
  if (floor < 1 || floor >= towerTop || _isGate(floor)) return null;
  final random = towerRandom(seed, floor, TowerStream.board);
  final u = random.nextDouble();
  final fall = 1 + random.nextInt(towerSetbackMaxFall);
  final roll = random.nextInt(20) + 1;
  if (u < towerRivalShare) {
    // The floor skipped and the floor landed on: both ordinary.
    final fits =
        floor + 2 < towerTop && !_isGate(floor + 1) && !_isGate(floor + 2);
    return fits ? _Drawn(TowerEventKind.rival, fall, roll) : null;
  }
  if (u < towerRivalShare + towerSetbackShare) {
    return _Drawn(TowerEventKind.test, fall, roll);
  }
  return null;
}

/// [run]'s floor is met again (at or below TowerRun.crest): it pays
/// nothing (towerAfterFight) and holds no event.
bool towerIsRevisit(TowerRun run) =>
    !run.isOver && run.crest > 0 && run.floor <= run.crest;

/// The event on [run]'s floor, as the run stands: none when its events are
/// off (TowerRun.events 0), on a floor met again, or a test with no setback
/// left.
_Drawn? _eventOf(TowerRun run) {
  if (run.events < 1 || run.isOver || towerIsRevisit(run)) return null;
  final drawn = _drawn(run.seed, run.floor);
  if (drawn == null) return null;
  if (drawn.kind == TowerEventKind.test &&
      run.setbacks >= towerSetbacksPerRun) {
    return null;
  }
  return drawn;
}

/// The kind of event on [run]'s floor, or none (see towerEventOf).
TowerEventKind? towerEventKindOf(TowerRun run) => _eventOf(run)?.kind;

/// The ability a setback on [floor] checks ([towerSetbackAbilities] in
/// turn: floor 1 strength, 2 dexterity, 3 wisdom, 4 strength...).
String towerSetbackAbilityOf(int floor) =>
    towerSetbackAbilities[(floor - 1) % towerSetbackAbilities.length];

/// The DC of a setback on [floor]: 10, one more every 6 floors (10 to 14).
int towerSetbackDcOf(int floor) =>
    towerSetbackDcBase + (floor - 1) ~/ towerSetbackDcFloors;

/// The floor after the last gate (warden or boss) below [floor]: 1 when
/// none is: a fall never goes below it.
int towerFloorAfterGate(int floor) {
  for (var g = floor - 1; g >= 1; g--) {
    if (_isGate(g)) return g + 1;
  }
  return 1;
}

/// Where a setback on [floor] falling [fall] floors lands: the next floor
/// would be [floor] + 1, so [fall] floors down is [floor] - [fall] + 1,
/// never below the floor after the last gate.
int towerSetbackFallTo(int floor, int fall) =>
    max(towerFloorAfterGate(floor), floor - fall + 1);

/// What the floor screen shows of [run]'s floor and its event (floor events
/// PR 1, the proposal's "State for UX-2"). Null when the run's events are
/// off (TowerRun.events 0, a run saved before) or over, or when there is
/// nothing to show (no event, not a floor met again, no last result). A
/// floor met again gives a view with [TowerEventView.kind] null and
/// [TowerEventView.revisit] true. [hero], when given, is [run]'s hero
/// already built (towerHeroOf): a test's modifier is read from it.
TowerEventView? towerEventOf(TowerRun run, TowerData data,
    {SimCharacter? hero}) {
  if (run.events < 1 || run.isOver) return null;
  final event = _eventOf(run);
  final revisit = towerIsRevisit(run);
  if (event == null && !revisit && run.lastEvent == null) return null;
  final setbacksLeft = max(0, towerSetbacksPerRun - run.setbacks);
  final floor = run.floor;
  switch (event?.kind) {
    case TowerEventKind.test:
      final ability = towerSetbackAbilityOf(floor);
      final dc = towerSetbackDcOf(floor);
      final modifier =
          checkBonusFor((hero ?? towerHeroOf(run, data)).abilityScore(ability));
      return TowerEventView(
        kind: TowerEventKind.test,
        floor: floor,
        revisit: false,
        setbacksLeft: setbacksLeft,
        ability: ability,
        dc: dc,
        modifier: modifier,
        chance: checkChance(modifier: modifier, dc: dc),
        fallTo: towerSetbackFallTo(floor, event!.fall),
        gain: 1,
        result: run.lastEvent,
      );
    case TowerEventKind.rival:
      return TowerEventView(
        kind: TowerEventKind.rival,
        floor: floor,
        revisit: false,
        setbacksLeft: setbacksLeft,
        rounds: towerRivalRounds,
        landsOn: floor + 2,
        result: run.lastEvent,
      );
    case null:
      return TowerEventView(
        kind: null,
        floor: floor,
        revisit: revisit,
        setbacksLeft: setbacksLeft,
        result: run.lastEvent,
      );
  }
}

/// The rival's end after [run]'s fight of its floor, won in [rounds]
/// (null: not counted, so not in time); null when the floor holds no rival
/// (towerAfterFight saves it, towerPick lands by it).
TowerEventResult? towerRivalResultOf(TowerRun run, int? rounds) {
  if (_eventOf(run)?.kind != TowerEventKind.rival) return null;
  final passed = rounds != null && rounds <= towerRivalRounds;
  return TowerEventResult(
    kind: TowerEventKind.rival,
    passed: passed,
    from: run.floor,
    to: passed ? run.floor + 2 : run.floor + 1,
  );
}

/// [next] (the run moved on from [won], its floor won and its card
/// applied) after [won]'s floor's event: a setback's test rolled (pass, a
/// potion, to the bag or drunk when it is full; fail, the fall, the height
/// kept in TowerRun.crest), a rival beaten in time landing two floors up
/// (the skipped floor's level-ups arrive here, their max health added; its
/// spoils and card are lost). [next] as it is when there is no event.
TowerRun towerAfterEvent(TowerRun won, TowerRun next, TowerData data) {
  final event = _eventOf(won);
  if (event == null) return next;
  final from = won.floor;
  switch (event.kind) {
    case TowerEventKind.rival:
      final result = won.lastEvent;
      if (result == null ||
          result.kind != TowerEventKind.rival ||
          result.from != from ||
          !result.passed) {
        return next;
      }
      final before = towerHeroOf(next, data).maxHealth;
      final landed =
          next.copyWith(floor: from + 2, crest: max(next.crest, from + 1));
      final after = towerHeroOf(landed, data).maxHealth;
      return landed.copyWith(
          health: (next.health + after - before).clamp(1, after));
    case TowerEventKind.test:
      final hero = towerHeroOf(next, data);
      final ability = towerSetbackAbilityOf(from);
      final dc = towerSetbackDcOf(from);
      final modifier = checkBonusFor(hero.abilityScore(ability));
      final passed = checkPasses(event.roll, modifier, dc);
      final to = passed ? from + 1 : towerSetbackFallTo(from, event.fall);
      final result = TowerEventResult(
        kind: TowerEventKind.test,
        roll: event.roll,
        total: event.roll + modifier,
        passed: passed,
        from: from,
        to: to,
      );
      if (passed) {
        // The potion: to the bag, or drunk when it is full.
        return next.potions < towerBagCap
            ? next.copyWith(potions: next.potions + 1, lastEvent: result)
            : next.copyWith(
                health: min(hero.maxHealth, next.health + potionHealAmount),
                lastEvent: result);
      }
      return next.copyWith(
        floor: to,
        crest: max(next.crest, from),
        setbacks: next.setbacks + 1,
        lastEvent: result,
      );
  }
}
