// The Tower's checks and choices as plain data for the screens (the check
// plumbing, docs/simulation/tower-check-plumbing.md): a setback's or a
// parley's roll as the main game's AbilityCheckResult (so the floor screen
// can show it with showAbilityRoll), and each event's choices with what
// they lead to, read from the typed fields of TowerEventView. Pure: no rule
// and no number is decided here.

import '../ability_check.dart' show AbilityCheckResult;
import 'tower_events.dart';

/// [result]'s d20 check as an AbilityCheckResult: a setback's or a
/// parley's, with its roll; null for a kind without a roll (rival,
/// shortcut, merchant, bargain) and for a parley passed on the oath. Its
/// ability, modifier and DC are the ones saved on [result]; a result saved
/// before they were (no keys) rebuilds them: the floor's ability
/// (towerSetbackAbilityOf, towerParleyAbilityOf), its DC
/// (towerSetbackDcOf) and the modifier [TowerEventResult.total] less the
/// roll. Its success is [TowerEventResult.passed] (the same checkPasses,
/// a natural 20 always, a natural 1 never).
AbilityCheckResult? towerCheckResultOf(TowerEventResult result) {
  final roll = result.roll;
  if (roll == null) return null;
  final String ability;
  switch (result.kind) {
    case TowerEventKind.test:
      ability = result.ability ?? towerSetbackAbilityOf(result.from);
    case TowerEventKind.parley:
      ability = result.ability ?? towerParleyAbilityOf(result.from);
    case TowerEventKind.rival:
    case TowerEventKind.shortcut:
    case TowerEventKind.merchant:
    case TowerEventKind.bargain:
      return null;
  }
  final modifier = result.modifier ?? (result.total ?? roll) - roll;
  return AbilityCheckResult(
    ability: ability,
    roll: roll,
    modifier: modifier,
    dc: result.dc ?? towerSetbackDcOf(result.from),
  );
}

/// What a choice (or a branch of the check) on a Tower event leads to: one
/// line per effect (towerChoiceOutcomesOf).
///
/// [choiceKey] names the branch with the key the event card already uses
/// for it (a button's Key, or the l10n key of its outcome line); several
/// outcomes may share one. [kind] is one of the stable strings:
///
/// - 'potion': a potion ([amount]) to the bag (drunk when the bag is full)
/// - 'fall': the climb falls to floor [floor]
/// - 'land': the run goes on at floor [floor] ([amount], when given, the
///   rounds a rival is won within, or the floors a shortcut skips)
/// - 'forgo': the floor's [id] given up (towerParleyForgoes: 'spoils',
///   'card', 'heal')
/// - 'fight': the floor's fight, on floor [floor]
/// - 'endRun': a loss ends the run
/// - 'buy': stock [id] for [amount] coins
/// - 'heal': [amount] health (a salve)
/// - 'boon': [amount] cards to take one from (a stall's boon)
/// - 'maxHealth': [amount] max health lost for the rest of the run
/// - 'stat': [amount] points to stat [id]
/// - 'none': nothing changes
class TowerChoiceOutcome {
  const TowerChoiceOutcome({
    required this.choiceKey,
    required this.kind,
    this.amount,
    this.floor,
    this.id,
  });

  final String choiceKey;
  final String kind;
  final int? amount;
  final int? floor;

  /// What the outcome is about, where its kind needs it: a forgo's item, a
  /// stock's id, a stat's name.
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is TowerChoiceOutcome &&
      other.choiceKey == choiceKey &&
      other.kind == kind &&
      other.amount == amount &&
      other.floor == floor &&
      other.id == id;

  @override
  int get hashCode => Object.hash(choiceKey, kind, amount, floor, id);

  @override
  String toString() => 'TowerChoiceOutcome($choiceKey, $kind'
      '${amount == null ? '' : ', amount $amount'}'
      '${floor == null ? '' : ', floor $floor'}'
      '${id == null ? '' : ', $id'})';
}

/// The choices of [view]'s event and what each leads to, in the order the
/// card shows them, from the view's own fields (no rule read again). Empty
/// for a view with no event. The keys, per kind:
///
/// - test: 'tower_event_pass' (potion [gain]), 'tower_event_fail' (fall to
///   [fallTo])
/// - parley: 'tower_parley_pass' (land on [landsOn], then a forgo per
///   [forgoes]); 'tower_parley_fail' (fight, not when [oathPass]: the talk
///   cannot fail); 'tower_parley_fight' (fight)
/// - rival: 'tower_event_rival_win' (land on [landsOn], amount the rounds),
///   'tower_event_rival_slow' (land on the next floor)
/// - shortcut: 'tower_event_shortcut_win' (land on [landsOn], amount the
///   floors skipped), 'tower_event_shortcut_lose' (endRun),
///   'tower_shortcut_decline' (fight)
/// - merchant: per stock line and the boon, `tower_stall_buy_<id>` (buy for
///   its price, then heal, potion or boon by its amount)
/// - bargain: 'tower_bargain_accept' (maxHealth [maxHealthCost], stat
///   [points] to [stat]), 'tower_bargain_refuse' (none)
List<TowerChoiceOutcome> towerChoiceOutcomesOf(TowerEventView view) {
  final floor = view.floor;
  switch (view.kind) {
    case null:
      return const [];
    case TowerEventKind.test:
      return [
        TowerChoiceOutcome(
            choiceKey: 'tower_event_pass', kind: 'potion', amount: view.gain),
        TowerChoiceOutcome(
            choiceKey: 'tower_event_fail', kind: 'fall', floor: view.fallTo),
      ];
    case TowerEventKind.parley:
      return [
        TowerChoiceOutcome(
            choiceKey: 'tower_parley_pass', kind: 'land', floor: view.landsOn),
        for (final what in view.forgoes ?? const <String>[])
          TowerChoiceOutcome(
              choiceKey: 'tower_parley_pass', kind: 'forgo', id: what),
        if (view.oathPass != true)
          TowerChoiceOutcome(
              choiceKey: 'tower_parley_fail', kind: 'fight', floor: floor),
        TowerChoiceOutcome(
            choiceKey: 'tower_parley_fight', kind: 'fight', floor: floor),
      ];
    case TowerEventKind.rival:
      return [
        TowerChoiceOutcome(
            choiceKey: 'tower_event_rival_win',
            kind: 'land',
            amount: view.rounds,
            floor: view.landsOn),
        TowerChoiceOutcome(
            choiceKey: 'tower_event_rival_slow',
            kind: 'land',
            floor: floor + 1),
      ];
    case TowerEventKind.shortcut:
      return [
        TowerChoiceOutcome(
            choiceKey: 'tower_event_shortcut_win',
            kind: 'land',
            amount: view.skip,
            floor: view.landsOn),
        if (view.lossEndsRun ?? true)
          const TowerChoiceOutcome(
              choiceKey: 'tower_event_shortcut_lose', kind: 'endRun'),
        TowerChoiceOutcome(
            choiceKey: 'tower_shortcut_decline', kind: 'fight', floor: floor),
      ];
    case TowerEventKind.merchant:
      return [
        for (final item in [
          ...?view.stock,
          if (view.boon != null) view.boon!
        ]) ...[
          TowerChoiceOutcome(
              choiceKey: 'tower_stall_buy_${item.id}',
              kind: 'buy',
              amount: item.price,
              id: item.id),
          TowerChoiceOutcome(
              choiceKey: 'tower_stall_buy_${item.id}',
              kind: switch (item.kind) {
                TowerStockKind.salve => 'heal',
                TowerStockKind.potions => 'potion',
                TowerStockKind.boon => 'boon',
              },
              amount: item.amount),
        ],
      ];
    case TowerEventKind.bargain:
      return [
        TowerChoiceOutcome(
            choiceKey: 'tower_bargain_accept',
            kind: 'maxHealth',
            amount: view.maxHealthCost),
        TowerChoiceOutcome(
            choiceKey: 'tower_bargain_accept',
            kind: 'stat',
            amount: view.points,
            id: view.stat),
        const TowerChoiceOutcome(
            choiceKey: 'tower_bargain_refuse', kind: 'none'),
      ];
  }
}
