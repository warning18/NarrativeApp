# The fight's effect tips: Poison, Stun, Weaken, Block, Shelter (Core, v1.656)

For UX-2's combat redesign (variant A'): each fighter's card shows small
effect icons, and a tap opens a pop-in that explains the effect. This note
gives the rules text for the five effects that have no tip yet (`fury_tip`,
`parry_tip` and `watchfire_tip` already exist), in English and French. It
also says where each number comes from in the code, so the texts stay true.

Docs only. Narrative may reword any line. The keys are suggestions and go
next to `fury_tip` in `app_strings.dart`.

**Placeholders:** `{n}` and `{turns}` come from the live effect on the card
(`StatusEffect.magnitude` and `.remainingTurns`, or the member's `block`).
So the pop-in shows that fight's real numbers, which vary by skill, spell,
die and specialisation.

## The texts

### Poison: `poison_tip`
- **EN:** Takes {n} damage at the start of each of its turns, for {turns} more turns. A new poison replaces the old one; poisons don't add up.
- **FR:** Subit {n} dégâts au début de chacun de ses tours, encore {turns} tours. Un nouveau poison remplace l’ancien ; les poisons ne s’additionnent pas.

### Stun: `stun_tip`
- **EN:** Loses its next turn: a stunned hero sits out the roll, a stunned enemy makes no move and drops a blow it was winding up. Lasts {turns} turn(s).
- **FR:** Perd son prochain tour : un héros étourdi ne lance pas son dé, un ennemi étourdi n’agit pas et perd le coup qu’il préparait. Dure {turns} tour(s).

### Weaken: `weaken_tip`
- **EN:** Its hits deal {n}% less damage, for {turns} more turns. A new weaken replaces the old one.
- **FR:** Ses coups infligent {n} % de dégâts en moins, encore {turns} tours. Un nouvel affaiblissement remplace l’ancien.

### Block: `block_tip`
- **EN:** Stops {n} damage of the next blow that reaches this fighter; that blow uses it up. It is doubled against the blow an enemy has announced on this fighter. It lasts until the party's next roll.
- **FR:** Arrête {n} dégâts du prochain coup qui atteint ce combattant ; ce coup l’épuise. Il est doublé contre le coup qu’un ennemi a annoncé sur ce combattant. Il dure jusqu’au prochain lancer du groupe.

### Shelter: `shelter_tip`
- **EN:** Your party kept a Defend and a Heal this round: every Heal also mends each other standing member for half of it.
- **FR:** Votre groupe a gardé une Défense et un Soin ce tour : chaque Soin soigne aussi chaque autre membre debout de la moitié.

### One shared line for the three afflictions on a hero (optional)
- **EN:** Wisdom shortens it: 1 turn less per 5 Wisdom, never under 1.
- **FR:** La Sagesse l’abrège : 1 tour de moins par tranche de 5 de Sagesse, jamais moins d’un.

## The rules behind them, and where the numbers live

| Effect | Who it lands on | How much, how long | How it ends | In code |
|---|---|---|---|---|
| Poison | Heroes, companions and enemies | Damage `magnitude` at the start of the fighter's turn. In the data, always 1 for 2–3 turns; a Venomous foe's blow gives 1 for 2. The rogue's Rot and Fen lines can raise it. | Counts down when the fighter's turn ends; gone at 0. A new poison replaces the old. | `status_effect.dart` (`poisonDamageFor`, `applyStatusEffect`); `skills.json`/`spells.json` `statusDuration`/`statusMagnitude`; `_venomousPoison` in `fight_screen.dart`; `specialisations.dart` (rot, fen) |
| Stun | Both sides | The fighter skips its turn. Always 1 turn in the data. | Ticks off as the turn is skipped. A stunned enemy also loses its charged blow and its stagger. | `isStunned`; `fight_rounds.dart` (`_sittingOut` for the party; the enemy turn loop) |
| Weaken | Both sides | Every hit it lands is cut by `magnitude`% (10–30 in the data, mostly 15–25), for 2–3 turns. Percents are summed and capped at 100. | Counts down like Poison; a new one replaces it. | `applyWeaken`; `skills.json`/`spells.json`; `pitchSlow` (15% for 1 turn) in `specialisations.dart` |
| Wisdom | Only on heroes and companions hit by an enemy | 1 turn off per 5 Wisdom, never below 1 | — | `applyWisdomResistance`, applied in `fight_rounds.dart` where an enemy's move lands |
| Block | Heroes and companions | A Defend face's value (a skill's or spell's block adds to it; a guard sign adds its shield). ×2 if this fighter is the target an enemy announced (`_telegraphBraceMultiplier`), ×1.5 on high ground (`highGroundBlockMultiplier`). A Shield Wall (two Defends kept) gives every member the biggest block. | Taken off the next blow (`damageAfterParry`: blow − parry − block − armour), then set to 0. Set again at the party's next roll. A Defend face set to parry an enemy guards no one. | `fight_rounds.dart` (`actor.block`, `target.block = 0`); `parry.dart`; `party_combos.dart` (`shieldWall`) |
| Shelter | The party, this round only | Needs two acting members, one keeping a Defend and one a Heal. Each Heal also heals every other standing member for `shelterShare` = 0.5 of it, rounded. | The round. | `party_combos.dart` (`partyCombosFor`, `shelterShare`); `fight_dice_rules.dart` (`_shelterFrom`) |

**Enemies' own guard** (`enemy.guard`, the shield chip on an enemy card)
is a different thing: it already has its tooltip (`enemy_guard_tooltip`)
and lasts until the enemy's next turn. If the redesign gives it an icon of
the same family, its text stays as it is.

**If a number changes,** the change happens in one of the places above, and
the tips with placeholders follow it. The fixed numbers in the texts are
×2 (Block), half (Shelter) and 5 (Wisdom), from `_telegraphBraceMultiplier`,
`shelterShare` and `applyWisdomResistance`. A Core PR that changes one of
them updates its tip in the same PR.
