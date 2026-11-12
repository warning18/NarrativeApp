// The Tower's floor events (floor events PR 1 and 2,
// docs/proposals/tower-snakes-and-ladders.md): some ordinary floors hold a
// setback (the story's d20 check after the win: fail, and the climb goes
// down a few floors), a rival (win within a few rounds and skip the next
// floor) or a shortcut (fight an Elite instead and skip a few floors; lose
// and the run ends). Drawn per floor from their own stream (TowerStream.board), so no
// other draw moves; a run whose TowerRun.events is 0 meets none and plays
// as before. Floor events PR 3 (docs/proposals/tower-peaceful-floors-and-stores.md)
// adds the parley, on its own draw of that stream: talk past a floor's
// guardian (a check, or no roll when sworn to its clan) or fight it. Pure: towerAfterFight and towerPick resolve them, the screen
// reads towerEventOf.

import 'dart:math';

import '../../combat/fight_numbers.dart' show potionHealAmount;
import '../ability_check.dart' show checkBonusFor, checkChance, checkPasses;
import '../sim_combat.dart' show SimCharacter;
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_rewards.dart' show towerOfferFor;
import 'tower_run.dart';
import 'tower_tables.dart';

/// What a floor's event is. (A kind added later goes last.)
enum TowerEventKind {
  /// The setback: the d20 check after the win and the card.
  test,

  /// The rival: the floor's fight won within [towerRivalRounds] rounds
  /// skips the next floor.
  rival,

  /// The shortcut (floor events PR 2), offered before the fight: the
  /// floor's foe made tougher (towerShortcutFloor); won, the floor's own
  /// spoils and card, then k floors skipped and a card on landing; lost,
  /// the run ends.
  shortcut,

  /// The parley (floor events PR 3), offered before the fight: talk (the
  /// setback's d20 check, towerParleyAbilities by floor; no roll when sworn
  /// to the guardian's clan) or fight. Passed, the run goes on to the next
  /// floor, the floor's level and marks given, its spoils, card and
  /// recovery given up; failed, or the fight chosen, the floor's fight.
  parley,
}

/// The background picture of each kind's card (UX-2's, drawn by Art): a
/// plain key per kind.
String towerEventBackgroundOf(TowerEventKind kind) => switch (kind) {
      TowerEventKind.test => 'setback',
      TowerEventKind.rival => 'rival',
      TowerEventKind.shortcut => 'shortcut',
      TowerEventKind.parley => 'parley',
    };

/// What a parley's pass gives up (TowerEventView.forgoes): the floor's
/// spoils chest, its card (and the oath it might offer), the health a win
/// gives back (towerRecoveryShare).
const List<String> towerParleyForgoes = ['spoils', 'card', 'heal'];

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

  /// The test's or the parley's d20 and its total with the modifier; null
  /// for a rival, a shortcut, a parley passed on the oath.
  final int? roll;
  final int? total;

  /// The test passed, the rival beaten in time, the parley talked past.
  final bool passed;

  /// The floor the event was on, and the floor it sent the run to (the
  /// next one, a fall's, a skip's landing; a parley's next floor when
  /// passed, its own floor when failed, the fight there).
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
    this.foeIds,
    this.elite,
    this.skip,
    this.lossEndsRun,
    this.accepted,
    this.clanId,
    this.oathPass,
    this.forgoes,
    this.background = '',
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

  /// A rival: the rounds to win within. A rival or a shortcut: the floor
  /// a win lands on.
  final int? rounds;
  final int? landsOn;

  /// A shortcut: the foes fought if it is taken (towerShortcutFloor), the
  /// first an Elite or not ([elite]; a floor already a pack or an Elite
  /// gets one more foe instead), the floors skipped ([skip], landing on
  /// [landsOn]), a loss ending the run ([lossEndsRun], true), and the
  /// player's choice ([accepted]: null until chosen, TowerRun.shortcut).
  final List<String>? foeIds;
  final bool? elite;
  final int? skip;
  final bool? lossEndsRun;
  final bool? accepted;

  /// A parley: the ability its talk checks ([ability]: charisma, wisdom or
  /// dexterity), the setback's [dc], [modifier] and [chance] (the check's
  /// odds, as they stand without the oath), the guardian's clan
  /// ([clanId]), sworn to it ([oathPass]: the talk passes with no roll),
  /// the floor a pass lands on ([landsOn], the next), what a pass gives up
  /// ([forgoes], towerParleyForgoes) and the choice ([accepted]: null until
  /// chosen, true talked, false the fight chosen; TowerRun.parley).
  final String? clanId;
  final bool? oathPass;
  final List<String>? forgoes;

  /// The key of the card's background picture (towerEventBackgroundOf:
  /// 'setback', 'rival', 'shortcut', 'parley'); '' when the floor holds no
  /// event.
  final String background;

  /// The last event's end (TowerRun.lastEvent), until the next fight ends.
  final TowerEventResult? result;
}

/// A floor's event as the seed draws it, before the run's state is read.
class _Drawn {
  const _Drawn(this.kind, this.fall, this.roll, {this.clanId = ''});
  final TowerEventKind kind;
  final int fall;
  final int roll;

  /// A parley's guardian's clan.
  final String clanId;
}

bool _isGate(int floor) => towerBudgetOf(floor).kind != TowerFloorKind.fight;

/// The event the run of [seed] holds on [floor], drawn from its own stream
/// (TowerStream.board): a draw, the fall (1 to [towerSetbackMaxFall]) and
/// the d20, in that order, on every ordinary floor. The draw's ranges, so
/// one event sits on a floor at most: a rival under [towerRivalShare]
/// (0 to .10) where a skip fits, a setback in the next [towerSetbackShare]
/// (.10 to .30), a shortcut in the next [towerShortcutShare] (.30 to .45)
/// where a skip fits; nothing above. (The shortcut's range comes after
/// PR 1's, so their floors did not move.)
_Drawn? _drawn(int seed, int floor) {
  if (floor < 1 || floor >= towerTop || _isGate(floor)) return null;
  final random = towerRandom(seed, floor, TowerStream.board);
  final u = random.nextDouble();
  final fall = 1 + random.nextInt(towerSetbackMaxFall);
  final roll = random.nextInt(20) + 1;
  // A skip fits: the floor skipped and the floor landed on both ordinary
  // (a skip stops on the floor before the next gate).
  final fits =
      floor + 2 < towerTop && !_isGate(floor + 1) && !_isGate(floor + 2);
  if (u < towerRivalShare) {
    return fits ? _Drawn(TowerEventKind.rival, fall, roll) : null;
  }
  if (u < towerRivalShare + towerSetbackShare) {
    return _Drawn(TowerEventKind.test, fall, roll);
  }
  if (u < towerRivalShare + towerSetbackShare + towerShortcutShare) {
    return fits ? _Drawn(TowerEventKind.shortcut, fall, roll) : null;
  }
  return null;
}

/// The parley (floor events PR 3) the run of [seed] holds on [floor], drawn
/// on its own index of the board stream ([towerPeacefulDraw] + floor): a
/// draw, the guardian's clan and the d20, in that order, on every ordinary
/// floor from [towerPeacefulFirstFloor] below the top that holds no floor
/// event (_drawn). A parley under [towerParleyShare]; the ranges above are
/// PR 4's stores'.
_Drawn? _peacefulDrawn(int seed, int floor) {
  if (floor < towerPeacefulFirstFloor || floor >= towerTop || _isGate(floor)) {
    return null;
  }
  if (_drawn(seed, floor) != null) return null;
  final random =
      towerRandom(seed, towerPeacefulDraw + floor, TowerStream.board);
  final u = random.nextDouble();
  final clanId = towerClans[random.nextInt(towerClans.length)];
  final roll = random.nextInt(20) + 1;
  if (u < towerParleyShare) {
    return _Drawn(TowerEventKind.parley, 0, roll, clanId: clanId);
  }
  return null;
}

/// [run] choosing the card on a shortcut's landing (floor events PR 2):
/// its floor the one below the landing, already counted in TowerRun.crest,
/// its offer on the table.
bool towerIsShortcutLanding(TowerRun run) =>
    run.status == TowerStatus.choosing &&
    run.floor <= run.crest &&
    run.offer.isNotEmpty;

/// [run]'s floor is met again (at or below TowerRun.crest): it pays
/// nothing (towerAfterFight) and holds no event. (A shortcut's landing
/// card is not a floor met again.)
bool towerIsRevisit(TowerRun run) =>
    !run.isOver &&
    run.crest > 0 &&
    run.floor <= run.crest &&
    !towerIsShortcutLanding(run);

/// The event on [run]'s floor, as the run stands: none when its events are
/// off (TowerRun.events 0), on a floor met again, or a test with no setback
/// left.
_Drawn? _eventOf(TowerRun run) {
  if (run.events < 1 || run.isOver || run.floor <= run.crest) return null;
  final drawn =
      _drawn(run.seed, run.floor) ?? _peacefulDrawn(run.seed, run.floor);
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

/// The ability a parley's talk on [floor] checks ([towerParleyAbilities]
/// in turn: floor 1 charisma, 2 wisdom, 3 dexterity, 4 charisma...).
String towerParleyAbilityOf(int floor) =>
    towerParleyAbilities[(floor - 1) % towerParleyAbilities.length];

/// The DC of a setback on [floor]: 10, one more every 6 floors (10 to 14).
/// A parley's talk is checked against it too.
int towerSetbackDcOf(int floor) =>
    towerSetbackDcBase + (floor - 1) ~/ towerSetbackDcFloors;

/// The first gate (warden or boss) above [floor], or the top.
int _nextGate(int floor) {
  for (var g = floor + 1; g < towerTop; g++) {
    if (_isGate(g)) return g;
  }
  return towerTop;
}

/// Where a shortcut on [floor] skipping [skip] floors lands: [skip] floors
/// past the next one, never past the floor before the next gate.
int towerShortcutLandsOn(int floor, int skip) =>
    min(floor + 1 + skip, _nextGate(floor) - 1);

/// [floor] made tougher for a shortcut (the proposal's option (a)): a lone
/// foe made an Elite (eliteStatMultiplier); a pack, or a lone foe already
/// an Elite, one more foe (its strongest again).
TowerFloor towerShortcutFloor(TowerFloor floor) => TowerFloor(
      floor: floor.floor,
      kind: floor.kind,
      chapter: floor.chapter,
      extra: floor.extra,
      enemyIds: floor.isPack || floor.elite
          ? [...floor.enemyIds, floor.enemyIds.first]
          : floor.enemyIds,
      affixes: floor.affixes,
      elite: !floor.isPack && !floor.elite,
      events: floor.events,
    );

/// [run] with its shortcut taken ([accept]) or declined: only before the
/// fight of a floor that offers one, and once; [run] as it is otherwise.
/// Taken, the floor's fight is towerShortcutFloor's (towerFloorOf).
TowerRun towerChooseShortcut(TowerRun run, TowerData data, bool accept) {
  if (run.status != TowerStatus.climbing ||
      run.shortcut != null ||
      _eventOf(run)?.kind != TowerEventKind.shortcut) {
    return run;
  }
  return run.copyWith(shortcut: accept);
}

/// The guardian's clan of the parley on [run]'s floor; null when it holds
/// none (towerEventOf).
String? towerParleyClanOf(TowerRun run) {
  final event = _eventOf(run);
  return event?.kind == TowerEventKind.parley ? event!.clanId : null;
}

/// [run] after its parley's choice (floor events PR 3): only before the
/// fight of a floor that offers one, and once; [run] as it is otherwise.
/// The fight chosen ([talk] false): TowerRun.parley false, the floor's
/// fight. Talked: sworn to the guardian's clan, passed with no roll; else
/// the setback's d20 check (towerParleyAbilityOf, towerSetbackDcOf).
/// Passed, the run lands on the next floor, the floor counted in
/// TowerRun.crest (its level arrives, its max health added; its picks
/// wait; its marks paid by height), its spoils, card and recovery given
/// up. Failed, TowerRun.parley true and the floor's fight. Either way the
/// talk's end is TowerRun.lastEvent. [hero], when given, is [run]'s hero
/// already built (towerHeroOf): the check's modifier is read from it.
TowerRun towerChooseParley(TowerRun run, TowerData data, bool talk,
    {SimCharacter? hero}) {
  if (run.status != TowerStatus.climbing || run.parley != null) return run;
  final event = _eventOf(run);
  if (event == null || event.kind != TowerEventKind.parley) return run;
  if (!talk) return run.copyWith(parley: false);
  final from = run.floor;
  final TowerEventResult result;
  if (run.clanIds.contains(event.clanId)) {
    result = TowerEventResult(
        kind: TowerEventKind.parley, passed: true, from: from, to: from + 1);
  } else {
    final dc = towerSetbackDcOf(from);
    final modifier = checkBonusFor((hero ?? towerHeroOf(run, data))
        .abilityScore(towerParleyAbilityOf(from)));
    final passed = checkPasses(event.roll, modifier, dc);
    result = TowerEventResult(
      kind: TowerEventKind.parley,
      roll: event.roll,
      total: event.roll + modifier,
      passed: passed,
      from: from,
      to: passed ? from + 1 : from,
    );
  }
  if (!result.passed) return run.copyWith(parley: true, lastEvent: result);
  return _land(
      run.copyWith(lastEvent: result, clearShortcut: true, clearParley: true),
      from + 1,
      data);
}

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
  // A shortcut's landing card: no event, the shortcut's result.
  final event = towerIsShortcutLanding(run) ? null : _eventOf(run);
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
        background: towerEventBackgroundOf(TowerEventKind.test),
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
        background: towerEventBackgroundOf(TowerEventKind.rival),
        result: run.lastEvent,
      );
    case TowerEventKind.shortcut:
      final tough =
          towerShortcutFloor(towerFloorsFor(run.seed, data.enemies)[floor - 1]);
      final landsOn = towerShortcutLandsOn(floor, event!.fall);
      return TowerEventView(
        kind: TowerEventKind.shortcut,
        floor: floor,
        revisit: false,
        setbacksLeft: setbacksLeft,
        foeIds: tough.enemyIds,
        elite: tough.elite,
        skip: landsOn - floor - 1,
        landsOn: landsOn,
        lossEndsRun: true,
        accepted: run.shortcut,
        background: towerEventBackgroundOf(TowerEventKind.shortcut),
        result: run.lastEvent,
      );
    case TowerEventKind.parley:
      final ability = towerParleyAbilityOf(floor);
      final dc = towerSetbackDcOf(floor);
      final modifier =
          checkBonusFor((hero ?? towerHeroOf(run, data)).abilityScore(ability));
      return TowerEventView(
        kind: TowerEventKind.parley,
        floor: floor,
        revisit: false,
        setbacksLeft: setbacksLeft,
        ability: ability,
        dc: dc,
        modifier: modifier,
        chance: checkChance(modifier: modifier, dc: dc),
        clanId: event!.clanId,
        oathPass: run.clanIds.contains(event.clanId),
        landsOn: floor + 1,
        forgoes: towerParleyForgoes,
        accepted: run.parley,
        background: towerEventBackgroundOf(TowerEventKind.parley),
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

/// [next] (climbing) landed on floor [to], the floors below it counted in
/// TowerRun.crest: their level-ups arrive (their max health added; their
/// picks wait), their spoils and cards are lost.
TowerRun _land(TowerRun next, int to, TowerData data) {
  final before = towerHeroOf(next, data).maxHealth;
  final landed = next.copyWith(floor: to, crest: max(next.crest, to - 1));
  final after = towerHeroOf(landed, data).maxHealth;
  return landed.copyWith(
      health: (next.health + after - before).clamp(1, after));
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
  if (towerIsShortcutLanding(won)) return next;
  final event = _eventOf(won);
  if (event == null) return next;
  final from = won.floor;
  switch (event.kind) {
    // A parley's floor won: its fight was fought (the talk failed, or the
    // fight chosen), the climb as usual.
    case TowerEventKind.parley:
      return next;
    case TowerEventKind.rival:
      final result = won.lastEvent;
      if (result == null ||
          result.kind != TowerEventKind.rival ||
          result.from != from ||
          !result.passed) {
        return next;
      }
      return _land(next, from + 2, data);
    case TowerEventKind.shortcut:
      if (won.shortcut != true) return next;
      final to = towerShortcutLandsOn(from, event.fall);
      final landed = _land(next, to, data).copyWith(
          lastEvent: TowerEventResult(
              kind: TowerEventKind.shortcut, passed: true, from: from, to: to));
      // The card on landing (the proposal's "card on landing"): the floor
      // below the landing deals its offer, as the one just won would.
      final hero = towerHeroOf(landed, data);
      final offer = towerOfferFor(
        seed: landed.seed,
        floor: to - 1,
        hero: towerHeroView(landed, hero),
        oaths: landed.oathsLeft,
        items: data.items,
        dice: data.dice,
        skills: data.skills,
        spells: data.spells,
      );
      if (offer.isEmpty) return landed;
      return landed.copyWith(
          floor: to - 1, status: TowerStatus.choosing, offer: offer);
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
