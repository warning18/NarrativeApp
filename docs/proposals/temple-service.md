# The temple (Core, proposal, wave 15)

Design only: nothing here is in the game yet.

Wave 14 gave every town with a city plan a `temple` pin (`townServicesProvider`, `docs/proposals/journey-world-data.md`). Its `opens` is empty, so the sheet says "nothing yet" (`service_nothing_yet`). This note says what it should open.

## 1. What it offers

**Two services: Mending and a Blessing.** No curse lifting (see question 1).

The temple belongs to **whoever rules its district**, else the town (`rulerOfTown`, v1.483). A town no one rules has a neutral temple.

### Mending: health now, without the night

- **Effect**: the whole party back to full health, as `healPartyToFull` does, but **mana stays** and **no time passes** (no `restUntilDawn`, no day, no threat).
- **Cost**: `templeMendPrice(chapter) = 20 × chapter` gold: 40 in chapter 2, 80 in 4, 120 in 6, 160 in 8.
- **Limit**: once a day (`templeMendDay == day` blocks it). A rest moves the day on and opens it again.
- **From chapter 2** (`roadRulesFromChapter`). In chapter 1 the night costs nothing, so the row is hidden.
- **Why**: from chapter 3 a day matters. Past the grace (`threatGraceDaysFor`: 8 days in chapter 3, 28 in 4 and 5, 36 in 6), each day makes enemies 3% stronger (`threatPerDay`, up to 30%). Mending lets a player pay gold instead of a day.

### Blessing: the clan's favour for three fights

- **Effect**: for the next **3 fights** (`templeBlessingFights = 3`, like `sellswordContractFights` and `defaultPactFights`), the party fights with:
  - the ruling clan's `host.effects` from `factions.json` (the same small kit its contingent brings to the Host, see `hostEffects` in `throne.dart`);
  - plus `partyStartBlock` 1 (the ward every temple gives).
  - A neutral temple gives `partyMaxHealthPercent` 3 and `partyStartBlock` 1.
- The effects go through the Signs pipeline as `extra` in `signEffectsFor`, the way the Host's do. The effect strings already exist (`sign_fx_*`).
- **Cost**: `templeBlessingPrice(chapter) = 30 + 30 × chapter` gold: 60 in chapter 1, 90 in 2, 150 in 4, 210 in 6, 270 in 8.
- **Limit**: one blessing at a time. A new one replaces the old one (no stacking), like the sellsword's contract.
- **Standing**: the first blessing of each chapter from a clan gives **+1 standing** with it (question 2). Not with an opposite-alignment clan (`alignmentOpposite` in `risky_gifts.dart`): it blesses you but doesn't warm to you.

### Who can use it

- Prices follow standing with the ruling clan, like a clan's shop: `factionPriceFor(price, tier)` (×1.40 at Hostile ... ×0.75 at Sworn).
- **Hunted**: the temple refuses you (`shopRefusesTrade`). Hostile: open, at ×1.40 (question 3).
- Alignment doesn't gate anything.
- Charisma doesn't haggle here (no `shopPriceFor`).
- Not during a fight or an expedition (the same `busy` check as the tavern's Rest).

### How it differs from the tavern

| | Tavern (`restTheNight`) | Temple |
|---|---|---|
| Health | full | full (Mending) |
| Mana | full | unchanged |
| Time | one day passes (threat) | none |
| Gold | free | 20 × chapter |
| Buff | none | Blessing, 3 fights |

### What it doesn't do

- **No curse lifting.** The user decided a risky gift's curse can't be lifted early (`riskCurses`, 2 levels, `withCursesEnded`). A Pit pact's curse (`pactFightsLeft`) is the price of the sign's gift, so the same reasoning applies.
- **No revival.** A lost fight already refills the party, so there is nothing to revive.
- **No affliction cure.** Poison, Stun and Weaken end with the fight.

## 2. Clan flavour (light)

The kit is the clan's `host.effects`, so each temple feels different with no new numbers:

- **Ashen Penitents**: +3% party max health, +6% spell damage, the ember face.
- **Grey Vigil**: +3% dodge, see the next intent.
- **Lantern Dominion**: the Writ face, +1% party max health.
- **Cinder Compact**: +3% party max health, +6% strike damage, the Compact's edge.
- **Mire Courts**: +1 potion healing, guard heals.
- **Salt Crows**: +2% dodge, +5% strike damage.
- Everything else (the keeper, the line, the blessing's name) is text.
- If a clan's `host` changes, its blessing changes too. If a town changes hands, its temple changes with it.

## 3. Save fields (`PlayerSession`)

Each one is left out of the save when it is at its default, so an old save loads with no blessing.

- `blessingFights` (int, 0): fights left. It goes down by one after each fight, like `spendSellswordFight`.
- `blessingClan` (String, `''` = neutral). Its effects are read live from `factions.json`.
- `templeMendDay` (int, 0): the day of the last Mending.
- `templeStandingChapters` (`Map<String, int>`, clan → chapter): for the +1 standing, once a chapter per clan (like `AllyState.giftChapter`).

Code:
- `TownServiceAction.temple` in `town_services.dart`. The temple pin opens it, and it is always unlocked.
- The rules go in a new pure file, `lib/data/temple.dart`.
- The fight hook is a few lines in `fight_setup.dart`, next to the sellsword's.

## 4. What UX draws

- **The temple sheet**: the same bottom sheet as `town_service_sheet.dart`.
  - **Header**: the temple's name, the ruling clan's colour (`TownRuler.color`) and your tier with them.
  - **A Mending row**: the price and "no time passes". When it is greyed out, it says why: already mended today, too poor, or a fight in progress.
  - **A Blessing row**: the price, the effect lines (`sign_fx_*`), and "+1 standing" when it applies. If a blessing is already active, the row says it will replace it.
  - A Hunted player sees the keeper's refusal line instead of the rows.
- **An active blessing** shows as a small line in the `RoadPanel`, like the sellsword's ("Blessed by the Vigil: 2 fights"), and as a chip at the start of a fight.
- **Effects**: `showHealWave` for Mending. Optionally a soft glow when the blessing is taken.

## 5. What Narrative writes

- **New `factions.json` fields** (Core adds them, Narrative fills them, EN and FR):
  - `templeName`, for example "the Wall of Names" for the Penitents;
  - `blessingName`;
  - `templeLine`: what the keeper says;
  - `templeLineHunted`: the refusal.
- **Neutral temple texts**: in `app_strings.dart`.
- **Strings**, added next to the `service_*` block:
  - `temple_mend`, `temple_mend_hint`, `temple_mend_done`, `temple_mend_used`;
  - `temple_blessing`, `temple_blessing_hint`, `temple_blessing_replace`, `temple_blessing_active` (with `{clan}` and `{n}`), `temple_blessing_standing`;
  - `temple_refused`, `temple_neutral_name`, `temple_neutral_blessing`.

## 6. Simulator and autoplay

- **Mending: not simulated.** The simulator has no chapter threat and already rests at each hub (`SimCharacter.rest`, `sim_combat.dart`). Mending would change nothing there.
- **Blessing: simulated.** At each chapter hub, the walk buys one if its gold is at least 3× the price. It uses the ruling clan of the hub's town and adds the kit through `signEffectsFor` `extra` for the next 3 fights. The report gets a count of blessings and the gold spent on them.
- **Autoplay** ("Play to chapter", `autoplay_engine.dart`) buys nothing, as today.
- **Expected effect**:
  - The 3 fights after each hub: about +1 to 3 points of attempt win rate.
  - The overall attempt win rate: under +1 point.
  - The boss curve shouldn't move. Bosses come after the chapter's own fights, by which time the blessing has run out. `boss_balance_test.dart` should stay green.
  - Gold: about 8 × 150, so roughly 1 200 gold over a run. The median run ends with about 4 000 unspent (`report-100-runs.md`), so this is a sink, not a squeeze.

## 7. Questions for the user

1. **Should a temple lift a curse?** Recommended: **no**. You decided a risky gift's curse runs its 2 levels, and the Pit's pact curses are the price of their gift.
2. **Should a blessing give +1 standing with the temple's clan, once a chapter?** Recommended: **yes**. It is a small reason to visit a clan's temples, and it lets gold buy a little goodwill.
3. **Should a Hostile clan's temple serve you?** Recommended: **yes, at ×1.40**, like its shops. Only Hunted shuts the door.
