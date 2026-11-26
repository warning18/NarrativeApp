# Tower check plumbing: fields for UX

Plumbing only: no rule, odds or number moved (`test/qa_tower_live_pin_test.dart`
unchanged and green). Core files: `lib/data/tower/tower_events.dart`,
`lib/data/tower/tower_event_outcomes.dart`. Test: `test/tower_check_plumbing_test.dart`.

## On `TowerEventResult` (saved on `TowerRun.lastEvent`)

| Field | JSON | What |
|---|---|---|
| `ability` | `'ability'` | the ability the check read (setback: `towerSetbackAbilityOf`, parley: `towerParleyAbilityOf`) |
| `modifier` | `'mod'` | the modifier the roll was actually given |
| `dc` | `'dc'` | the check's DC (`towerSetbackDcOf`) |

Filled where a setback (`towerAfterEvent`) and a parley's talk
(`towerChooseParley`) resolve. Null with no roll (rival, shortcut, stores, a
parley passed on the oath) and on a save from before (the keys are optional).

## `towerCheckResultOf(TowerEventResult result) -> AbilityCheckResult?`

The roll as the main game's `AbilityCheckResult`, ready for
`showAbilityRoll(context, result: ..., message: ...)`
(`lib/widgets/ability_roll_dialog.dart`). Null for a kind without a roll. Uses
the stored fields; an old save rebuilds them (floor's ability and DC, modifier
= `total - roll`). Its `success` equals `result.passed` (the same
`checkPasses`: a natural 20 always passes, a natural 1 always fails).

## Preview vs roll: `TowerEventView.picksBeforeCheck`

Both the view and the roll read the modifier with `towerCheckModifierOf(hero,
ability)`. A setback is rolled after the floor's win, its Level Up picks and
its card; a parley at the talk, on the hero as it stands.

- A card never changes an ability (`towerApplyReward` gives dice, skills,
  spells, rank-ups, oaths), so the card taken never moves the modifier.
- **The one case that can still differ:** a setback preview shown *before the
  floor's fight* when winning that floor gives a level, and the Level Up stat
  pick taken then raises the checked ability (or a stat pick still waits from
  an earlier skip): the roll's modifier is then higher than the preview's.
  `picksBeforeCheck` is the number of stat picks still to come before the roll
  (`towerPicksBeforeSetback`); when it is 0 the preview's `modifier` is the
  roll's exactly.
- Once the floor is won and its Level Up done (choosing the card), it is 0 and
  the preview is exact. A parley's is always 0.

## Choices: `towerChoiceOutcomesOf(TowerEventView view) -> List<TowerChoiceOutcome>`

`TowerChoiceOutcome {choiceKey, kind, amount?, floor?, id?}`, in the card's
order, built from the view's typed fields. `choiceKey` is the key the card
already uses (a button's `Key`, or the l10n key of the outcome line).

| Event | choiceKey | kind | amount / floor / id |
|---|---|---|---|
| test | `tower_event_pass` | `potion` | amount `gain` |
| test | `tower_event_fail` | `fall` | floor `fallTo` |
| parley | `tower_parley_pass` | `land` | floor `landsOn` |
| parley | `tower_parley_pass` | `forgo` (one per item) | id `spoils` / `card` / `heal` |
| parley | `tower_parley_fail` (not when `oathPass`) | `fight` | floor |
| parley | `tower_parley_fight` | `fight` | floor |
| rival | `tower_event_rival_win` | `land` | amount `rounds`, floor `landsOn` |
| rival | `tower_event_rival_slow` | `land` | floor + 1 |
| shortcut | `tower_event_shortcut_win` | `land` | amount `skip`, floor `landsOn` |
| shortcut | `tower_event_shortcut_lose` | `endRun` | |
| shortcut | `tower_shortcut_decline` | `fight` | floor |
| merchant | `tower_stall_buy_<id>` (each stock line, then the boon) | `buy` | amount price, id |
| merchant | `tower_stall_buy_<id>` | `heal` / `potion` / `boon` | amount (health, potions, cards) |
| bargain | `tower_bargain_accept` | `maxHealth` | amount `maxHealthCost` |
| bargain | `tower_bargain_accept` | `stat` | amount `points`, id `stat` |
| bargain | `tower_bargain_refuse` | `none` | |

A view with no event gives an empty list.
