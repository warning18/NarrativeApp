# Changelog

All notable changes to this project are documented here, generated from the
repository's pull-request history (each entry corresponds to one merged PR
and the version it bumped `pubspec.yaml` to). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

History before v1.23.1 predates per-PR versioning in this repository and
isn't reconstructable from git history alone.

## [1.127.0+156]

Boarding, both ways, and the ship battle's polish: what a shot would do
shown on every room, an auto-station button, and the boarding crew named
before the grapples are thrown.

### Added
- **Boarding.** When the enemy's bulwark is out and her layers are gone,
  her rail is open: a Board button beside End turn throws the grapples.
  Her helm may slip them (a roll against her evasion; the turn is spent
  either way). If they hold, the battle drops onto her deck: the existing
  dice fight against the ship's boarding crew (two street bandits on the
  Skiff, two and a harbor rat on the Brig, two auxiliaries and a soldier
  on the Cutter, two void hounds and a wisp on the Barge), fought at 2.5x
  difficulty, a crew on its own pitching deck being far more than the same
  men met on a road. Win and the ship is taken: her gold, and her prize
  part installed when the Eel has room for it (its worth in gold
  otherwise): spare canvas from the Brig, iron plating from the Cutter,
  fire pots from the Barge. Lose and the party is thrown back to the Eel,
  15% of her hull the poorer, once a battle.
- **They board you too.** While the Eel's own rail is open, a boarding
  crew may come over on any enemy turn (30-40% a turn by ship, once a
  battle). A hand in the Hold meets them at the companionway and the
  boarders fight at three-quarters health; with nobody in the Hold they
  come at full strength. Boarders beaten are gone; boarders that win wreck
  the Hold (knocked out) and a fifth of the hull.
- **Shot preview.** With a weapon armed, every enemy room shows what the
  shot would do if it lands: the hull it would cost and the pips it would
  knock off, "KO" on a room it would put out, a flame when it would set
  the room burning, and "shield +0" when a layer would stop it (the
  bulwark pip the blow would still crack is shown). Evasion is the one
  thing not previewed.
- **Auto-station.** A button in the crew bar places the crew the way the
  simulator does: the nimblest hand to the helm, the strongest to the
  guns, the third to the bulwark, the fourth to the hold; under half hull
  a hand goes to the hold, and an unmanned fire pulls a hand to it.
- The hint line names the boarding crew when the rail is open ("board and
  fight Street Bandit x2, Harbor Rat at the rail"), and a door icon marks
  a bulwark that is open to boarding.
- enemy_ships.json gains `boardingCrew`, `boardingChance`, `prizePartId`
  and `prizeGold` (schema-validated, checked against enemies.json and
  ship_parts.json by the data test). The Raider Skiff gets a gunwale for
  a bulwark (one pip), so even she must be shot open before she is
  boarded.

### Verification
- `ship_combat.dart` gains `bulwarkOpen`, `grapplesHold`,
  `boardingRepelled`, `boardersWreck`, `boardingProfileFor`, `previewShot`
  and `autoStations`, all pure and unit-tested (39 ship-combat tests).
- The simulator's `sim_v11.py` boards when the rail is open and the crew
  are fit, and is boarded on the same rule as the game. The deck fight's
  difficulty was swept over 24 playthroughs: at 2x the party took 77 of
  the 84 ships it boarded, the Barge among them, and boarding was the
  opening against everything; at 3x the Barge's deck was never taken and
  her fights fell to 40% won, the auto-pilot paying 15% hull for every
  refused boarding. At the shipped 2.5x, over 78 voyages and 97 raider
  fights: the Skiff won every time in 2.2 rounds, the Brig every time in
  4.6, the Cutter every time in 3.5, the Barge 68% in 12.8 with 43% hull
  left; the party boarded 79 times and took 63 ships (the Brig and Skiff
  every time, the Cutter 26 of 28, the Barge 2 of 16); the enemy boarded
  25 times and took the deck 5; 6 voyages turned back; every run reached
  an ending.

## [1.126.0+155]

Ship battles rebuilt in the manner of FTL: two ships of four rooms each,
weapons that charge and fire at a room, shield layers that stop shots and
crack under them, fires, and the party as crew at their stations.

### Added
- **Rooms.** Every ship has a Helm, Guns, Bulwark and Hold, each with
  system pips. The Helm gives 8% evasion a pip; the Bulwark holds one
  shield layer a pip and raises one back each round; the Guns charge the
  weapons, extra pips speeding the heaviest; the Hold is where the crew
  shelters and the hull is patched. A hit knocks pips off the room it
  lands in; a room at zero is out (a silenced ship charges nothing, a
  blind one slips nothing, a broken bulwark holds no layer).
- **Shots.** A weapon fires at a room of the enemy's ship: tap the weapon,
  then the room. The target's evasion is rolled first; then a shield
  layer stops a non-piercing shot, though the blow still cracks a pip off
  the bulwark behind it (so a single gun can wear a bulwark down); a shot
  that gets through costs hull and pips, and an incendiary one leaves the
  room burning (a pip and hull a round until someone fights it).
- **Crew stations.** The player and every active companion sail as crew.
  Tap a member, then a room: a helmsman adds evasion (more with
  Dexterity), a gunner a charge step to the heaviest gun, a bulwark hand a
  second layer a round, a hold hand hull repairs (more with Wisdom).
  Anyone repairs the room they stand in or fights its fire, and that
  takes their turn at the station. A shot that lands in a crewed room
  hurts whoever stands there, and the hurt persists to the shore.
- **The enemy's crew and aim.** Enemy ships repair a pip or fight a fire
  each round (their guns first, the bigger crews twice), and aim: fire at
  the hold, otherwise the bulwark or the guns, then down the list. With
  the Kraken's Eye aboard the enemy's aim is marked on your rooms and
  named on its weapons before it fires.
- **Weapons and parts re-read.** The ballista fires every turn; the
  harpoon rack pierces the bulwark and tears two pips, three turns to
  wind; fire pots burn, four turns; the void volley pierces, four turns.
  Iron plating is one more Bulwark pip (a second layer), the tar-sealed
  hull one more Hold pip, spare canvas one more Helm pip. ship_parts.json
  gains `chargeTurns`, `piercesShield`, `setsFire`, `roomDamage` and
  `roomBonus`; the old bulwark-pool fields are gone.
- **Four enemy ships with rooms and weapons of their own**, in
  enemy_ships.json's new `rooms`, `weapons` and `crew`: the Raider Skiff
  (open boat, bow chaser and grapnel, no bulwark, nimble), the new
  Corsair Brig (chapter 3: twin ballistae, a 24% helm, a thin bulwark),
  the Inquisition Cutter (a layer, a ballista, fire arrows for the hold,
  two hands) and the Void Barge (chapter 4: two layers, a piercing void
  lance, a harpoon, a chaser, two hands). Each has a description.
- **ShipBattlePanel** draws it: the enemy's rooms, weapons and charge on
  top, the log, the Eel's rooms with her crew, her weapons and crew chips
  below, and one End turn button.

### Changed
- The Kraken's Eye no longer blunts a first volley; it shows the enemy's
  aim every turn instead (its description and label say so).
- The boat screen lists the Eel's room pips instead of a bulwark pool,
  and a part's summary reads its charge, piercing, fire and room pips.

### Balance
- The Python simulator carries the same rules (sim_v11.py). Over 24
  playthroughs with a four-part Eel and a full crew: the Skiff is won
  every time in 4 rounds with 88% hull left, the Brig 95% of the time
  (7 rounds, 79% hull), the Cutter 88% (9 rounds, 71% hull), the Barge
  79% (14 rounds, 43% hull), 8 voyages in 80 turned back, every run
  reaching an ending. A first pass without busy hands and with the enemy
  repairing its bulwark first was won 100% everywhere with no hull lost;
  a second with a harpoon wound in two turns lost to the Barge 93% of the
  time.

## [1.125.1+154]

### Changed
- **The coming damage is blue.** The slice of an enemy's health bar that
  the aimed dice would take off, and its "-N" chip, are now painted blue
  instead of darkened. Nothing else on the enemy side is blue, so it never
  reads as damage already taken, and in a pack fight the blue moves to
  whichever enemy the player aims at.

## [1.125.0+153]

The number before the confirm: every rolled die now says what it will do
to the enemy it is aimed at.

### Added
- **Damage preview on the dice.** Under each landed die's name, the damage
  its target would take if confirmed now (or the healing, block or mana
  it gives), computed with the confirm's own formula: base, gear, stat
  scaling, alignment gear, element bonus, Weaken, the target's Armored
  affix, bracing and the battlefield's multipliers. A strike that would
  drop its target reads "KO"; a strike that cashes in the momentum meter
  shows its guaranteed-critical number with a star. A lucky critical is
  the one thing not shown, since it is rolled at the confirm.
- **The enemy's bar shows the slice about to go.** The health bar of an
  enemy with dice aimed at it darkens the part those dice would take off,
  reads "now → after / max", and carries a "-N" chip (or "-N KO"). In a
  pack fight, re-aiming a die moves the slice and the number with it, so
  the player can pick a target from what each choice actually does.
- **The face sheet says the same.** A long-press on a die now adds
  "Against <enemy>: N damage, M HP left" under the face's own line, from
  the same preview.

### Fixed
- The face sheet's numbers left out alignment gear and unique/set gear
  damage, so they could read lower than what the confirm dealt. The
  confirm, the preview and the sheet now share one damage formula
  (`_totalDamageFor`) and one affix rule (`strikeDamageAfterAffixes`).

## [1.124.0+152]

A fight the story can lose, and outcomes said plainly.

### Added
- **Defeat branches.** `StoryChoice.loseNextId`: a story fight with one is
  played once, and losing it is a scene rather than a retreat (the
  choice's own effects and unlocks stay the winner's). The fight's end
  button reads "Face what comes" instead of "Retreat", the editor has a
  Defeat Destination field next to the check-failure one, the graph
  check walks the branch, and the in-app and Python simulators take it.
- **The hovel is a real fight.** Unfurling the Bundle at 400 now means
  three White Soldiers (a new chapter-1 enemy, weak alone and hard as a
  pack for a first character) before the Shroud's shockwave finishes
  them. Win and the Guardian path is yours as before. Lose and you are
  taken to the Black Hold with Lysa lost, a scar from rib to hip that the
  docks read back, and +2 alignment for having fought. Surrendering is
  interrogated all the same and now costs the character's name: -2 to
  beg for her, -4 to tell them what they want to hear (was 0 and -2).
- **Outcomes stated where the story lands.** The defeat scene opens with
  "I lost.", the Black Hold with "Captured, then." and a line for how you
  got there (fought and lost, or surrendered), the Guardian scene with
  "I won, barely", the tear's failed check with "The tear won."

## [1.123.0+151]

The chapter-1 rules applied to chapters 2 through 6: a choice is a short
line, a lock is one line, a lock the story already decided is hidden, no
node whose only choice is "continue", and every choice costs, gains or
leaves a mark a later scene reads back. `story_rules_test.dart` now holds
those rules for the whole story.

### Changed
- **Eighteen padding beats given a real choice or a cost.** The wharf
  arrival (walk the stalls, or lift from an unwatched crate), the bilge
  swim (-10 health), the inspector's corpse (+20 gold), Vane's tunnel
  key and his broken cordon (-10 health), the stained-glass drop (-10
  health), the Warden's standard, the catacomb descent (down in the dark
  for -10 health, or a lantern for 25 gold), the way to the drowned
  cloister (the candles, or the rats' dry passage on a Perception
  check for a dead runner's purse), the altar (reached by the circle
  fleeing or by breaking it), the climb out (before the roof comes down,
  or searching the loyalists' dead for +40 gold and -1), the ledger in
  daylight (read at once, or rest an hour first for +20 health), the
  road to the Quarter (go now, or pay a runner to warn the camp), the
  tear (the crew at your back, or sent home first), the Void's showing
  (accepted, or torn loose from for -25 health), Lysa's mask (kept, or
  left on her), the turned companion's body (carried aboard, or left to
  the legate's rowers), and the Sovereign's throne (leave at once, or cut
  the taken's names from it for -10 health). Each leaves a mark the next
  scene reads.
- **Thirty-five choice lines cut to at most 55 characters** (the longest
  was 112, an acolyte "still chanting among the ashes as though
  conviction alone might stop a blade"), ten paragraph locks cut to one
  line (the three harbor recruits, the orc mercenary, the choir deserter,
  the white sail, the chapel), the cleric Maren's scene hidden for a
  player who lost Lysa instead of explained, and "(Combat Encounter)"
  gone from Vane's fight.
- **Two silent marks now read:** the storm's lost stores on landfall, the
  Warden's mercy in the Hollow Court; the Sovereign's "Tell it nothing"
  now leaves one too.

### Tests
- `story_rules_test.dart`: the five rules over every node, with the final
  crossing's explained lock as the one named exception.

## [1.122.0+150]

Chapter 1 consistency pass, on the owner's rules: a choice is a short
line, never a paragraph; a lock the story already decided is hidden, not
explained; no node whose only choice is "continue"; every choice costs
something, gains something, or leaves a mark a later scene reads back.

### Changed
- **Twelve padding nodes removed** (47 → 35 in the chapter): the tavern
  cellar folds into the escape choice (250), the Black Hold's wake /
  breach / search / shim / door chain becomes two scenes (800, 816), the
  toll fight, the freed hound, the hound's Warden kill, the battlements
  jump, the sewer exit, the dockside hound and Kroll's entrance become
  effects on the choice that caused them plus a callback line where the
  story next stops (280, 823, 891, 960).
- **Fake forks are gone.** Kroll's aftermath no longer offers "Climb
  toward Lysa" to a player who lost her (or "Climb up alone" to one who
  kept her) with a paragraph explaining why they cannot: the climb shows
  only the path the player earned, and the Rat/Broken choice moves up
  onto it. The cloaked figure at the market, the hound at the hallway
  and at the docks appear only when the story allows them. "Back away"
  from the Rat Matriarch, which looped straight back into the same fight,
  is replaced by a Constitution check to wade past her; "Try to push
  past" the Wardens, which always ended in the same fight, is a Strength
  check that costs health on success.
- **Every remaining lock is one line** (the toll, the smuggler's three
  approaches, the Broken's rage): the longest is 66 characters, down from
  239.
- **Every choice does something.** The slums offer a neighbor to help
  (+1, -10 health), stalls to empty (+20 gold, -1) or a straight run
  the cellar remembers; the market detour no longer has a free exit
  (the bandit, the forge's smoke, or the figure at the edge); the tear's Luck
  check pays out on success (+30 gold from what the looters dropped) and
  scars on failure (-10 health, void-marked); the hovel can be searched
  (+15 gold for -10 health); leaving the hound is remembered; the keeper
  can be covered before the run (+1, -10 health); the Black Hold's
  wounded assistant can be finished for his purse (-2, +10 gold) or
  dragged clear (+1, -5 health); the torturer's instruments can be
  pocketed (+20 gold, -1); the battlements cost the river jump (-20
  health); the smuggler's three doors now differ (+1 / a debt and -10
  health / -2 and +25 gold, each read back on the crossing).
- **Path-blind lines fixed.** Kroll is "my torturer" only for a player
  who was in the Black Hold; a player who kept Lysa meets him as the man
  sent for the Bundle, and the mercy/vengeance aftermaths no longer
  mention sessions that never happened. The ex-quest meta labels in
  choice text ("(Start Battle)", "(Luck Check)", "(The Rat Path)") are
  gone; the UI already shows a check's stat and DC.
- Twenty new flags, each read back by a callback or a gate; `keeper_dead`,
  set since 1.118 and never read, now is.

### Tests
- `chapter_one_test.dart` holds the rules: choice text ≤ 55 characters,
  lock text ≤ 80, a story-decided lock is hidden, every single-choice
  node's choice carries an effect, every choice differs from its
  siblings in effect or destination, and every chapter-1 flag is read.

## [1.121.0+149]

The four improvements the 1.120 simulation pass proposed and the owner
approved: a gentler New Game+ step, Lysa's fate as a beat the story does
not let you miss, Resolve (a small stacking edge against a boss that has
beaten you), and a late gold sink in the camp.

### Changed
- **New Game+ is +10% per cycle** (was +15%): at +15% the Sovereign was
  beaten first try by 8 of 32 simulated parties and two runs never
  crossed; at +10% every run finishes.
- **The Reliquary Quarter has a gate** (`6010_gate`, between 6002 and
  the hub). A character who kept Lysa walks through with her at their
  shoulder; one who lost her cannot go in among the chapels until they
  have followed the chalk to the chair (alignment 5 and up) or faced the
  masked penitent (4 and down). Before, the fate was one hub activity
  among fifteen and 8 of 44 simulated players who lost her never took
  it; now none miss it. The hub's own fate choices stay as a fallback
  for saves already past the gate.

### Added
- **Resolve.** A lost boss fight goes on the books
  (`PlayerSession.bossDefeatCounts`, one per boss in the fight), and the
  next attempt against that boss gives the whole party +5% health and
  damage per defeat, up to five stacks, shown on the fight's setup card.
  It softens the tail without moving the median: with Resolve alone the
  Sovereign's first-try rate is unchanged, but no simulated run lost to
  it more than seven times (one lost 25 times before) and a run's worst
  case fell from 26 losses to 7.
- **The camp's works**, three late houses priced in the thousands with a
  party-wide bonus: the Hearth-Hall (1,500 gold, +3% health, after
  Cinder Row), the Banner Loft (2,500, +3% damage, after the Ossuary
  Galleries) and the Shroud Shrine (4,000, +2% health and damage, after
  the Dead Heart). Together +5%/+5%, deliberately small (a +10%/+10%
  version pushed the Sovereign's first-try rate from 65% to 90%). Gold
  left at the end of a simulated run falls from 14.5k to 6.4k.
  `houses.json` gains `partyHealthBonus` / `partyDamageBonus`, the camp
  card shows them, and `party_bonus.dart` resolves Resolve and the works
  into one `PartyBonus` the fight screen applies at party build.

### Simulation (80 runs, same seeds as 1.120; 32 New Game+ runs)
- Base: 99% of fights won, 0.7 losses per run (max 6, 46 flawless runs),
  the Sovereign first try 61/80 (was 52) with 29 losses across the batch
  (was 139), the Archon 68/80 (was 59). New Game+ at +10% with both:
  96% won, 2.4 losses per run, the Sovereign first try 19/32, all 32 runs
  finishing (at the old +15%: 59%, 40.6 losses per run, 8/32, 30/32).

### Tests
- `party_bonus_test.dart` (stacks, cap, the works' data), the session's
  boss-defeat book, and the gate's routing in `story_direction_test`.

## [1.120.0+148]

Simulation pass on 1.119: 80 playthroughs on the shipped tuning, 32 more on
each of three New Game+ steps, and the one bug the numbers exposed, fixed.

### Fixed
- An excursion could offer Tobin's vigil (Good only) and Malrik's cut
  (Evil only) to any character: the excursion quest pool never read a
  quest's `requiredAlignment`, and it prioritizes companion-recruit
  quests, so nearly every playthrough ended with both companions their
  story nodes gate by alignment (Malrik in 78 of 80 simulated runs, Tobin
  in 73). `SubNodeEngine.filterQuestPool` now applies the same gate as
  the recruit nodes ('Good' or 'Evil' must match the character's
  alignment label; 'Neutral' or unset means anyone), the story player
  passes the session's label, and the Python simulator mirrors it. After
  the fix: Tobin in 37 of 80 runs (all Good), Malrik in 20 (all Evil),
  and a Neutral character in neither.

### Tests
- `sub_node_engine_test.dart`: the quest pool by alignment, and the two
  shipped recruit quests against their gates.

## [1.119.0+147]

The 1.118 seams closed, the Shroud given its meaning, the companions
given their say at every dilemma, Lysa's arc carried through to a fate,
an Inquisition pact that turns a companion against you, and a painted
sail that lets the Rusty Eel fly.

### Fixed (1.118 regressions)
- Vane's maintenance tunnel now runs under the Inquisition's cordon to
  the old berths (2030, 2070) instead of an Upper Gate that no longer
  exists; the harbor's-end companion lines and callbacks no longer
  mention a tunnel or a Gate.
- `7005_seeker`'s three epilogues carry the whole Shroud.
- `7004` no longer says the camp is waiting when it was given to the
  Sovereign, and `2900` no longer says the Eel needs a hull and a sail
  when both are done: `FlagCallback.andFlags` (all must be held) joins
  `unlessFlags`, and both nodes read their state from callbacks.
- Lysa sails with you (callbacks at 2001, 2015, the wharf and the camp;
  the sailed-alone lines yield to her), her hub scenes hide instead of
  locking for a player who lost her, and 6010_lysa no longer has her
  arrive over water on the only hull.
- 3002's "second set of doors", and a death narration that named the camp
  before it existed.

### Added
- **The Shroud's meaning**: the Void wanted it whole (6004), the Court's
  kneeling inquisitors were its hands, the crossing thanks the bearer for
  carrying it (7002_confront), 4999 plants the question and 7005_dawn
  answers it: whole is also the only way the door closes.
- **Companion voices at the dilemmas**: `ally_acknowledgments.dart` gains
  the wharf, the storm, the Warden, the altar, the reliquary, the
  Sovereign's price (every companion steps forward) and the legate's
  offer, in both languages; the `{lost}` token names the companion the
  story took last (7003, 7004, 7005_dawn, the betrayal).
- **The Inquisition's pact** (`7002_pact`, Evil only, alignment ≤ -15): the
  last legate lands on the Hollow Shore; taking the pact turns the first
  active companion against you (`@first_ally` resolves to a new
  `<companion>_turned` enemy with that companion's own skills and a
  phase, or to the legate's champion with no one left to turn), removes
  them for good, and pays in gold and a fourth toll at the crossing (give
  the Sovereign the legate). Eight turned companions, the champion and
  their icons; callbacks through 7003, 7004, 7005 and 7005_crown.
- **Lysa's fate** for a character who surrendered her: on the Reliquary
  Quarter hub, a Good character (alignment ≥ 5) finds her dead in the
  Inquisition's penitent-chair with the player's name scratched twelve
  times beside it; anyone else fights a masked penitent who will not
  stop staring and learns whose face was under the porcelain only when
  the mask comes away. New `masked_penitent` enemy whose phase says your
  name; `lysa_found_dead` / `lysa_fallen` read back through chapter 6 and
  the endings.
- **Painted sails** (`lib/data/sail_powers.dart`, a `Sail` slot on the
  Eel, five ship parts): the Gull's Wing (elven paint: flight, storms and
  raiders pass beneath the keel), the Kraken's Eye (orcish ink: tomorrow's
  weather shown, the first volley seen coming), the Hearth-Mark (dwarven
  stone-mark: every day at sea heals the crew and mends the hull), the
  Wind-Knot (human banner: a shorter crossing, richer wrecks) and the Void
  Mark (a void volley in battle, storms that do not bite). One sigil at a
  time; repainting replaces it; painted the character's own people's way
  a sigil holds twice as strong. Wired into the voyage and ship battle,
  the shipwright card, the schema and l10n.
- Tests: `sail_powers_test.dart`; story-direction groups for the pact,
  Lysa's fate and the regressions; session and narration suites extended.
  The Python simulator turns the first companion on `@first_ally`; 40/40
  runs reach an ending.

## [1.118.0+146]

The story reviewed against the owner's direction: one Shroud, in pieces,
carried from the first chapter and completed on the spine at a cost; a
transport built to leave the town; a camp on a remote coast after a long
voyage; power that is worn, not held; and no clean way through.

### Changed
- **Every origin carries the Shroud.** The Rat steals the Bundle back
  from the Black Hold's table and the Broken has it burned into his scars;
  all three epilogues set `void_banner_bearer` and grant the heirloom
  piece. The seeker branch (`void_banner_seeker`, `5003_seeker`,
  `6001_seeker`) is retired; `7005_seeker` is now the wanderer's ending
  (sailing for the other tears with the whole Shroud) open to anyone.
- **Chapter 2 ends by building the transport.** Node 2900 is the harbor's
  end: the Rusty Eel needs a hull (Fisherman's Row) and a sail (Tanner's
  Court), both launched from the story and mandatory; "Cast off" appears
  only with both done. Casting off is a choice about who sails: everyone
  (stores thrown over), the twenty who can fight (the rest left to the
  Crusade), or no one. The voyage (2999) is three weeks at sea and a storm
  that costs the stores, the refugees' skiff, or the character's body.
- **Chapter 3 is remote.** Landfall on the Ashen Coast after twenty days;
  the Spire of Judgment (the Inquisition's mother-house, where the Crusade
  sailed from) a day's walk inland; the camp founded in a hidden cove and
  written to grow into whatever the player brings back. The old Upper
  Gate/Lower City geography is gone from chapter 3 onward, including the
  death narration and the ending texts.
- **The Shroud's four pieces on the spine.** The heirloom (chapter 1); the
  Warden's standard, stitched to the High Warden's living back
  (`4999_standard`: cut it free alive, wait for him to die in the burning
  Cathedral, or give him the blade first); the Court's twin, wrapped
  around twelve sleeping taken (`5004_altar`: wake them to die as
  themselves, or cut it free without waking them); the reliquary thread,
  sewn around the chart-keeper's sister (`6010_thread`: open it yourself,
  pay for the chapel and let her cut it, or hand the penitent the seal).
  6002 explains the four pieces. `banner_whole` gates `7002_confront`, and
  the Sovereign then names a price (`7002_price`): a companion, the
  character's blood, or the camp.
- **Power is worn.** Node 0 sets it out; races.json gains `powerMedium`
  (banner, painted sigil, stone-mark, ink, void-mark) and a sentence per
  race; the `{sigil}` token resolves to the character's medium; the Court's
  ash-ink, the Warden's standard-into-skin and 13 new persona lines at
  250, 450, 3001 and 7003 show it.
- **No clean way through.** The unfurling costs 15 health and the
  Beggar's keeper; every choice of the seven spine dilemmas (400,
  2900_boat_fixed, 2999, 4999_standard, 5004_altar, 6010_thread,
  7002_price) wounds, impoverishes, blackens, takes a companion or leaves
  a mark; 24 new callbacks read those marks back from the camp's founding
  to each ending.
- Quests `q_ch1_*` and `q_ch3_alsters_dawn` no longer grant Shroud pieces
  (the story does).

### Added
- `StoryChoice.grantsBannerPieceId` (adds to `bannerPiecesCollected`) and
  `StoryChoice.loseAllyId` (a companion id, or `*` for the first active
  ally, removed from the roster for good and never re-recruited:
  `PlayerSession.lostAllyIds`, `loseAlly`). A negative `healAmount` is a
  wound the story deals and stops at 1 health. Editor fields and l10n for
  both; the character screen names the two new pieces.
- `docs/chapter-flow-roadmap.md` records the refined structure.
- Tests: `test/story_direction_test.dart` (origins, seeker retirement,
  four pieces in order and unavoidable, the whole-Shroud gate, the
  boat-building exit, the remote chapter 3 and the old geography's
  absence, every dilemma choice costing something and its mark being read
  back, races' media and `{sigil}`), session tests for the new effects.
- The Python simulator applies the new costs; a 40-run batch reaches an
  ending 40/40 through the mandatory boat zones and the dilemmas (94.2%
  fight win rate).

## [1.117.0+145]

Narration that remembers, reacts and varies: scenes that call back the
player's earlier choices, hubs that note how they have changed, companions
in their own voices, fights that leave a mark on the next scene, a written
death, second beats and a spoken finale, and far more variety on the road.

### Added
- **Flag callbacks** (`flag_callbacks` on a story node): paragraphs shown
  only to a player holding an earned flag, with an optional `unlessFlags`
  veto. 34 callbacks across chapters 1-6 and the four endings wire up the
  eleven flags the story set but never read (`took_bundle`,
  `forge_cache_found`, `tern_row_spared`, `ashen_ledger_decoded`,
  `reckoning_wall_saved`, `camp_founded`, the optional zones' reward flags,
  `banner_second_piece_lead`) plus `lysa_survived`, `void_marked` and the
  penitent's confession.
- **Hub progress lines** (`hub_progress`): each of the four late hubs
  (2015, 3005, 5010, 6010) adds a what-has-changed sentence once 3-4 and
  again once 6-9 of its activities are done, counting its own
  `hub_<id>_` flags.
- **Persona variants** (`persona_variants`, keyed `race:<id>` /
  `profession:<id>`): 26 sentences on ten scenes that react to an orc on
  the wharf, a voidkin in the drowned cloister, a mage at the bazaar, a
  cleric in the Hollow Court, and the like.
- **Name tokens**: `{name}`, `{race}`, `{profession}` and `{companion}` in
  story text are filled from the session at render time
  (`lib/data/narration_tokens.dart`, with French nouns for every race and
  profession). Tobin, Malrik and Vane now say the character's name.
- **Companion voices**: `ally_acknowledgments.dart` is now keyed by node
  *and* companion -- seventeen scenes carry a party-wide default and two
  to nine companion-specific lines each (Kelda at the Warden's fall,
  Sable on the Eel's rail, Vess hearing the Void, ...), in English and
  French; the first active ally with a line speaks.
- **Fight aftermath** (`lib/combat/combat_aftermath.dart`): FightScreen
  publishes a `FightOutcome` (won, enemy names, Elite/hunt/boss, phases
  crossed, companion knocked out, flawless, rounds) and the next story
  node or expedition event opens with a paragraph drawn from seven
  bilingual pools -- a retreat, a boss that changed stance, an Elite, a
  hunt's quarry, a companion down, a clean fight, a plain win.
- **A written death**: the permadeath screen now opens with one of four
  bilingual death narrations naming the killer, above the tally.
- **Second beats** on the late hubs, via the new `StoryChoice.showIfFlags`
  (hidden until every flag is held -- the mirror of `hideIfFlags`): the
  deserter's warning, the archivist's second ledger, an hour with Tobin,
  the sapper's thanks (5010); the chart-keeper's sister, the penitent's
  answer (three alignment-weighted replies), a walk with Lysa, the Last
  Lantern's keeper (6010). Eight nodes, each appearing only after its
  first visit and retiring itself.
- **Finale**: "Sail into the tear" now leads to `7002_confront`, where the
  Sovereign speaks through the tear and the player answers (the names of
  the taken +2, the ballista, or the crown -2) before the crossing; and
  `7002_crew`, a last word to the companions with a line for every one of
  them.
- **Speaker labels**: a node whose `speaker` is not the Narrator shows an
  italic eyebrow above its text (The Archivist, The Sovereign, The
  Chart-keeper, The Penitent, The Lantern-keeper, The Deserter, Vane,
  Lysa), translated.
- **Zone midpoint beats** (`midpointFlavorText`/`midpointFlavorTextFr` on
  zones.json): halfway through a zone of three or more events, its own
  paragraph of narration between two draws (Scaffold Yards, Drowned
  Stair, Dead Heart Approach, Shroud's Vigil, Beyond the Tear).
- **Variety on the road**: every excursion flavor pool grows from 7 to 12
  lines per kind per theme (120 new lines, English and French); the
  hunt's trail lines go from 3 to 8 and its quarry lines from 2 to 8; the
  60 generic "Back to the market / into the quarter / to the Cloister /
  to the Quarter" return choices are rewritten from a pool of eight per
  hub, assigned round-robin.
- l10n: `aftermath_heading`, `expedition_midpoint_label`,
  `expedition_press_on`.
- Tests: `test/narration_test.dart` (show-if flags, callbacks, persona
  lines, hub progress, tokens, speaker labels, companion voices, aftermath
  pools and routing, pool sizes and EN/FR parity, and the authored data:
  every callback and show-if flag is settable, every persona key is a real
  race or profession, tokens match across languages, return lines vary,
  second beats retire themselves, the finale confronts before crossing).

### Changed
- `withAllyAcknowledgment` takes the party's `activeAllyIds` instead of a
  boolean, so the line can be the speaking companion's own.
- The Python simulator's `hidden()` honors `showIfFlags`; a 40-run batch on
  the new graph still reaches an ending 40/40 (94.4% fight win rate).

## [1.116.0+144]

A medium-hard difficulty curve, boss phases, item sets and unique gear,
companions that aim their own strikes, New Game+ and alignment epilogues
with two alignment-locked companions.

### Changed
- **Difficulty curve.** The v1.115 equip-gate fix had left the corrected
  40-run batch winning 99.6% of its fights. Every regular enemy now
  carries a flat floor (health ×1.15, damage ×1.10) under the unchanged
  chapter curve (+12% health per chapter, damage half that); bosses skip
  the floor and get their difficulty from phases instead. A steeper
  global step was tried first and rejected: it left chapters 1–4 at 100%
  while turning the chapter 5–6 bosses into walls. The same 40 seeds now
  win 96.6% of fights (1.9 losses per run, 16 flawless runs, all 40
  reach an ending); first-attempt rates are 100% on story fights, 96.6%
  in chapter-4 zones, 91.8% in chapter-5 zones and 81.7% in chapter-6
  zones, with the Void Archon beaten first try 27/40 and the Void
  Sovereign 26/40 (from 37/40 and 38/40). Ordinary fights stay a resource
  drain rather than a lethal threat for a full party of three; the risk
  now lives in the bosses.
- `difficultyCurveFor` in `combat_engine.dart` is the one place the fight
  screen, the in-app simulator and the autoplay engine resolve a fight's
  health and damage multipliers (floor, chapter, zone tier, New Game+).

### Added
- **Boss phases** (`phases` on an enemies.json record, `BossPhase` in
  `combat_engine.dart`). Once a boss falls to a phase's health threshold
  it changes stance, once: a heal, a cleanse of its afflictions, a
  damage multiplier for the rest of the fight, and new moves added to
  (or replacing) its list. The battle log announces the transition in
  purple, the enemy card shows a phase chip, the enemy sheet lists how
  many stances it has, and the telegraph is re-rolled so the new move
  shows on its very next turn. Every zone boss, every solo-only unique
  and both tier-2 alignment hunters have phases (18 enemies, the Void
  Stalker, Hollow Court Inquisitor, Void Archon and Void Sovereign two
  each), with eight new phase-only moves and pixel icons: brood call,
  meltdown, bone storm, eclipse, unmaking, martyrdom, many faces,
  stalker's ambush. Phase multipliers are capped at ×1.15 (×1.10 each on
  a two-phase boss): the first cut at ×1.3 made the two final bosses
  unwinnable for a fifth of the seeded builds.
- **Item sets and unique gear** (`lib/combat/gear_effects.dart`, a new
  `item_sets.json` table). The Harborwatch Kit (cutlass, coat, lantern;
  chapter 2, sold across the chapter-2 shops) gives +2 armor and +5%
  dodge at two pieces, +4 attack and +8% crit at three; the Hollow Court
  Vestments (blade, mantle, seal; chapter 4, sold at the Ossuary Trade
  and the Last Lantern, the seal a signature drop of the Inquisitor) give
  +5 armor and 4 thorns at two, +8 attack and 10% lifesteal at three. Four
  uniques: the Bloodthorn Blade (heals 20% of its damage), the Thornmail
  Hauberk (6 damage back to whatever connects), the Phoenix Sigil (once
  per fight a lethal blow leaves you at 1 HP) and the Siphon Wand (+1 mana
  per damaging hit). Set and unique effects apply in the fight screen and
  the simulator alike (flat attack/armor, crit and dodge bonuses through a
  new `critChanceBonus` on `resolvePlayerFace`, lifesteal and mana on
  hit per landed hit, thorns and second wind on the enemy's turn, all
  logged); the inventory shows "Set: Name (n/3)" with every tier and its
  check mark, and "Unique: …" with the effect, on tiles and in the
  detail dialog. Ten pixel icons.
- **Companions aim their own strikes.** A new combat setting (on by
  default) has companions focus fire on the player's target in a pack
  fight, or on the weakest enemy when the player has none, following a
  retarget as it happens; their cards leave the target picker. Off, every
  party member is aimed by hand as before.
- **New Game+.** A genuine story ending now offers the next cycle: a
  quarter of the gold, every die owned and every spell known are banked as
  a legacy that survives the reset at character creation and is handed to
  the new character; level, gear, companions, camp, quests and flags start
  over, and every enemy is +15% health and damage per cycle (the fight
  setup screen and a character-screen card say so). The same 40 seeds on
  cycle 1 win 73.8% of fights with 19.8 losses per run and all 40 still
  reaching an ending; +30% per cycle was tried and left eight runs stuck
  on the late bosses. An Edit-Mode reset wipes the legacy back to a first
  run.
- **Alignment epilogues.** Each of the four endings closes with an
  italic paragraph for the alignment the character actually reached it
  with (Good, Neutral or Evil; ten paragraphs, English and French), read
  from a new `alignment_epilogues` field on the node.
- **Two alignment-locked companions.** Brother Tobin, a dwarf cleric who
  deserted the Court's choir and keeps the drowned cloister's candles
  (chapter 4, Good only: Holy Light, Celestial Ward, Stoneskin, Mend), and
  Malrik Sarn, an orc rogue selling what the tear leaves behind in the
  Reliquary Quarter (chapter 5, Evil only: Poison Blade, Ruthless Edge,
  Savage Cleave, Bloodlust). Each has a recruit scene on the chapter hub
  (locked text when the alignment doesn't fit), a recruit quest, a
  signature die and battle banter in both languages.

### Tests
- New `boss_phases_test.dart` (phase parsing, ordering, index, move
  merging, heals, and a data check that every phase names real skills,
  is bilingual and stays under the enrage cap, and that every zone boss
  and unique has one), `gear_effects_test.dart` (set tiers, uniques,
  stacking, and a data check on item_sets.json); the difficulty test
  covers the floor, the boss exemption and New Game+; the session test
  covers banking, keeping and spending a legacy; the simulator test
  covers phases, gear numbers and a harder New Game+ fight; the
  story-node test covers epilogue parsing and round-trip; the engine
  test covers the crit-chance bonus and its cap.

## [1.115.0+143]

The in-app playthrough simulator now plays its fights out and reports
spells cast per run, and a gear-requirement bug that left every Mage
unarmed is fixed.

### Added
- **Simulator fight model** (`lib/data/sim_combat.dart`). Each simulated
  run now rolls a character of a random race and profession, created the
  way a new game creates one (defaults plus bonuses, the profession's
  starting die with the Technique faces wired on, its starting spells, a
  full mana pool), and plays every combat choice out with the engine a
  live fight uses: `rollDie`, `resolvePlayerFace`, `resolveEnemyMove`,
  statuses, the chapter curve and pack multipliers, Mana faces feeding
  the pool, and the same caster policy the Python simulator uses (heal
  below half, cleanse, the strongest affordable damage spell keeping a
  heal in reserve, block against a heavy swing, a hex on a long-lived
  enemy). A lost fight is retried up to three times, then the walk moves
  on and counts it lost; a loss refills health and mana as the app does;
  a new chapter counts as a rest; XP levels the character through the
  app's own thresholds. A shop is visited once when the story unlocks it:
  the profession's spellbook first, two potion charges per potion entry,
  the best affordable piece per slot, the sage die for a caster. No
  companions, affixes or battlefield conditions; a solo player's read,
  stated on the card.
- **Spells cast per run, on the simulator screen.** The batch recap gains
  fights won / lost and spells cast per run (with mana gained from dice),
  a Spells cast section with one chip per spell (total casts, runs that
  cast it on hover), a By profession list (runs, fights won / lost,
  casts) and the model's assumptions in one line. Each run's row shows
  its profession, level and casts; the run detail shows the character,
  its fight record and every spell with its count, and each step's fight
  as won or lost (with attempts) plus the spells cast in it. The chapter
  breakdown counts fights lost and spells per chapter. The transcript,
  batch summary (also what the Gemini analysis reads), CSV and JSON
  exports carry the same fields.

### Fixed
- **Half the builds could never equip gear.** The equip gate compared
  each of a character's four scores against an item's requirement, and
  treated a missing requirement as 0. Any character with a score below
  zero (a Mage's Strength −1, every Orc's Intelligence −1, every
  Voidkin's Constitution −2) therefore failed "score >= 0" on every item
  in the game and could equip nothing at all -- in the inventory screen
  as much as in the simulators. A requirement of 0 is now no gate, as
  the gate's own doc comment always said. The Python simulator had the
  same comparison: 15 of the 40 seeded builds had fought unarmed in every
  batch to date, which is why the same 40 seeds re-run after the fix win
  99.6% of their fights (from 82.3%), with 9 losses against 460 and the
  chapter-4 to chapter-6 bosses beaten on the first attempt 37 to 40
  times out of 40. Earlier batches' balance numbers stand corrected by
  this one; the enemy curve was tuned against a half-armed party and now
  reads as easy for a player who shops.

### Tests
`sim_combat_test.dart`: character creation for a Mage and a Warrior,
level-ups, a won fight with Arcane Bolt casts recorded, a loss refilling
health and mana, Mana faces feeding the pool over many fights, a
spell-less Warrior, and shop visits (spellbook, potions, gear, the sage
die, another profession's book left on the shelf). A regression test for
the requirement gate with a negative score.

## [1.114.0+142]

Mana and spells on the character screen and the skills tab, so the pool
and the spellbook are readable outside a fight.

### Added
- **Stats bar**: a mana chip (current / pool) next to health, pulsing
  when it changes like the health and gold chips.
- **Character screen**: a Mana & Spells card under the stats bar with the
  pool as pips and the names of every known spell; tapping it opens the
  Skills screen.
- **Skills tab** (the player's own, never a companion's): a Spells
  section heads the list with the pool, how it refills and where spells
  are cast from, then one card per spell the profession can ever cast --
  known ones with the numbers they would land right now (the same sum the
  battle screen uses: base damage, gear, stat scaling, alignment gear and
  the spell's element bonus, then the spell's own scaling), the unlearned
  ones greyed out with the shop that sells their spellbook. Each card
  opens a detail dialog: cost, effect, live amount, target, element,
  status, whether it is known and where to learn it.
- `lib/utils/spell_preview.dart`: the session-side spell preview and the
  spellbook-shop lookup; `lib/widgets/mana_meter.dart`: the shared pip
  meter; the mana and spell icons and labels move to `game_icons.dart`
  so the battle, character and skills screens draw them the same way.

### Tests
`spell_preview_test.dart`: caster damage from a session with a weapon,
its stat scaling and element bonus; the preview matching the engine's
own spell scaling; a hex's level-scaled poison; the spellbook-shop
lookup against the real data, including that every non-starting spell
is sold somewhere; the profession spell list's ordering and filtering.

## [1.113.0+141]

Mana and spells, and a combat screen rebuilt around them. Spells are cast
on demand during the party's turn, like potions, and cost mana; dice can
carry a Mana face that refills the pool mid-fight; a Mage or Cleric starts
with an apprentice die and two spells, everyone else can buy their
profession's spellbooks. The battle screen now reads like a dice-battler:
the party's dice in a tray on top (tap to keep one through a reroll,
long-press for every face of the die), the party down the left with each
member's die slot, the enemies down the right with an intent box, and one
action bar at the bottom for mana, spells, potions, reroll and confirm.

### Added
- **Mana.** A pool of 4 plus half the higher of Intelligence and Wisdom
  (a starting Mage or Cleric has 6). It carries over between fights like
  health, refills on a rest, on a lost fight and at a new game, and comes
  back mid-fight through a die's `Mana` faces (any party member's Mana
  face feeds the one pool). Persisted on every cast and every Mana face,
  so a fight abandoned half-way keeps what was spent. Saves from before
  mana existed wake up with a full pool. The debug stats editor exposes
  it.
- **Spells** (`assets/gamedata/spells.json`, a new Data tab table): eleven
  spells across the five professions -- Arcane Bolt, Frost Bind (damage
  plus a one-turn Stun), Ember Wave (every enemy) and Mana Ward (block for
  the whole party) for Mages; Mending Light, Sanctified Ground (party
  heal), Smite the Wicked and Purge (cleanse) for Clerics; Venom Hex for
  Rogues, Hunter's Mark for Rangers, War Shout for Warriors. A damage
  spell reads like a skill: the caster's own damage (base, gear, stat
  scaling, element) plus the spell's surge and half its stat, times its
  multiplier (Arcane Bolt x1.6), so it stays the caster's strongest single
  action from chapter 1 to chapter 6; healing and block grow with level
  on the enemies' own health curve, a hex's poison with level like enemy
  damage. Spells never crit, are never Weakened and ignore the Armored
  affix, so the number on the button is the number that lands. A spell
  that needs a single target asks for it in a sheet when there is a real
  choice.
- **Spellbooks**, a new item type: bought in a shop, the spell is learned
  on the spot and the book never enters the inventory; a book the player
  already knows, or another profession's, is greyed out with the reason.
  Seven books across the Arcane Bazaar, the Academy, Apothecary Row, The
  Last Lantern, the Black Market Docks and the Weaponsmith's Forge, each
  with a pixel icon. A spellbook handed out as loot is read the same way.
- **Dice.** The `apprentice_die` (two Focus faces for 1 mana, a jab and
  a ward worth the starter die's own, and the two Technique faces at the
  starter die's indexes) is a
  Mage's and Cleric's starting die and sells at the Bazaar; the
  `sage_die` (two Deep Focus faces for 2 mana, Arcane Missile, a mend) is
  sold at the Academy and the Ossuary Trade; the Arcane and Holy dice
  trade their Heavy Strike for a Mana Well / Prayer face. `Mana` joins
  the Data tab's face types.
- **Professions** carry `startingDiceId` and `startingSpellIds`; a new
  character owns both the starter die and the profession's die with the
  Technique faces wired on each, and permadeath resets spells to the
  starting ones.

### Changed
- **Battle screen.** Dice tray on top with each party member's die in
  their own accent color; a tap on a landed die keeps it (locks it)
  through the next reroll, and only unlocked dice reroll; a long-press
  shows what confirming would do and every face of the die. Party column
  on the left: avatar, thin health bar with numbers, damage/armor/block
  and status chips, and a die slot holding the rolled face; a crosshair
  marks whoever a readable enemy is about to hit. Enemy column on the
  right: portrait, health bar, affix and status chips, one colored dot
  per party die aimed at it, and an intent box that shows what the
  party's Perception can read (a question mark, the target, a move
  category, or the damage number, element and the move's own words).
  In a pack fight, tap a party card then an enemy to re-aim that die;
  every strike is aimed at the first living enemy by default, so Confirm
  is never blocked on a pick. The log shrinks to a two-line ticker that
  opens the full log in a sheet. The bottom bar holds the mana meter and
  one button per known spell (cost shown as pips, greyed when short),
  potion and antidote as icon buttons with counts, and Reroll (rolls
  left) / Confirm or Roll.
- A `Mana` face resolves through `resolvePlayerFace` like every other face
  type (`PlayerActionResult.manaGained`).

### Tests
`spells_test.dart` (mana formula, spell parsing, scaling, learning gate,
spellbook lookup), `spells_data_test.dart` (every spell well-formed and
obtainable, every spellbook teaches a real spell exactly once, starting
spells and dice consistent with the profession, Technique faces at the
starter die's indexes, Mana faces on the caster dice, the sage die on
sale), a Mana-face group in `combat_engine_test.dart`, and a mana/spells
group in `player_session_provider_test.dart` (round-trip, pre-mana save
migration, clamping, learning, spellbook purchase, rest refill, combat
persistence, new-game grant, permadeath reset). 377 tests pass.

### Simulation
40 seeded runs with the simulator taught to roll Mana faces, start a Mage
or Cleric on the apprentice die, buy the profession's spellbooks and cast
one spell a round (heal below half, cleanse, the best damage spell it can
afford, block against a heavy swing, a hex on a long-lived enemy), against
the same 40 seeds with spells off. Casters gained the most: the Mage's win
rate rose from 56.6% to 75.0% with deaths per run down from 43.5 to 18.1,
Mage and Cleric together from 62.6% to 79.1%; overall combat went from
79.5% to 82.3% with 460 deaths against 565. Boss first-attempt rates are
unchanged (Inquisitor 31/40 against 34/40, Void Archon 30/40 against
31/40, Void Sovereign 27/39 against 28/40), so the pool is a caster's
tool rather than a shortcut. 2,689 casts over 2,606 fights, 3,619 mana
back from dice faces, Arcane Bolt 1,848 of the casts. A first pass with
flat spell numbers (14 damage plus half of Intelligence) made the Mage
worse (45% win rate): by chapter 5 a bolt was worth a third of a Slash
and the apprentice die's two Focus faces were dead weight, which is why
damage spells now ride the caster's own damage and heals grow with level.
Two non-caster seeds diverged the other way (a Ranger and a Rogue reached
the chapter-4 boss with one companion fewer on the spells-on path and died
there repeatedly), a path effect of a spellbook's gold on recruitment, not
of the spells themselves. The simulator never rests at camp, so its mana
is the pessimistic read.

## [1.112.0+140]

The late-game batch, fourth step of the chapter-flow roadmap: chapter 4
becomes the second big zone, chapter 5 the last big zone, and a new
chapter 6 the final zone with four endings -- nine new enemies, five
zones, three ports, two hubs, two shops, six quests and three pieces of
gear, all with pixel icons and French text.

### Added
- **Chapter 4, the Hollow Court.** A new hub, the Sunken Cloister
  (node 5010), between the descent and the Court: an archivist who hands
  out the Main quest The Second Ledger, the sapper's Ossuary Bounty (a
  two-ghoul pack), the Bone Warden at the sealed stair, the deserters'
  ossuary stall (a new shop, The Ossuary Trade), a collapsed span
  (Dexterity check), void wisps among the candles and a deserter to
  question (Charisma check). Two zones at the new port The Drowned Stair:
  the Ossuary Galleries (tier 1, boss Bone Warden) and the Drowned Stair
  itself (tier 2, main zone, boss Hollow Court Inquisitor), which the
  hub's exit launches as an expedition before the story descends.
- **Chapter 5, the Reliquary Quarter** (node 6010): the chart-keeper who
  reads the ledger's last page (Main quest The Dead Heart), Lysa if she
  survived the Spire, void hounds, a penitent Inquisitor's confession
  and challenge, The Last Lantern (a new shop), a tear-spawn in the
  chapel and the frost's pattern (Wisdom check). Two zones at the port
  The Black Reliquary: the Dead Heart Approach (tier 2, boss Tear-Spawn)
  and the Shroud's Vigil (tier 3, main zone, boss Void Archon), launched
  by the hub's exit.
- **Chapter 6, Beyond the Tear.** The Void returns the party to the
  Hollow Shore with the Rusty Eel beached beside them; hollow reflections
  wearing the faces of the fallen walk the sand (side quest Faces of the
  Fallen), a last fire, then the Eel sails into the tear: the final zone
  Beyond the Tear (tier 3, port The Hollow Shore, boss The Void Sovereign,
  Main quest Beyond the Tear). After the throne room, four endings: carry
  the Banner home (bearers), keep seeking it (seekers), sew the tear shut
  with it (bearers of good standing) or take the Sovereign's crown (the
  wicked). The old chapter-5 endings live on as the first two.
- **Enemies**: Catacomb Ghoul, Bone Warden, Hollow Court Inquisitor
  (chapter 4); Void Hound, Tear-Spawn, Inquisition Penitent, Void Archon
  (chapter 5); Hollow Reflection and The Void Sovereign (chapter 6), each
  with skill moves, guile, loot and a pixel icon. The three new bosses
  join the solo-only set.
- **Gear**: the Tear-Glass Blade, the Archon's Mantle and The Sovereign's
  Crown (a guaranteed drop from the final boss).
- **Story-launched zones.** A story choice can carry `launchZoneId`: the
  expedition (and its boss) runs before the choice resolves; a retreat or
  defeat leaves the player on the node, an already-cleared zone is
  skipped. The editor exposes the field.

### Changed
- Story and zone bosses (the solo-only set) are no longer drawn as random
  expedition or excursion events.
- Chapter spine: chapter 4 and 5 gain their hub beats, chapter 6 is new;
  the map's chapter grid follows.

### Simulation
40 seeded runs: 40/40 reach chapter 6 and end (bearer 6, seeker 20, dawn
10, crown 4), party level by chapter 2.3 / 5.4 / 8.9 / 12.8 / 16.3 / 18.6,
three voyages per run with 142 raider battles all won once the harpoon
rack and iron plating are aboard. First-attempt win rates against the new
bosses: Bone Warden 90%, Hollow Court Inquisitor 88%, Tear-Spawn 92%,
Void Archon 72%, The Void Sovereign 72%; late packs 95% or better. Two
earlier passes were dropped: one where the simulator sailed to later
chapters' ports ahead of the story (levels 14 by chapter 3) and one where
the Sovereign could be drawn as a random expedition event.

## [1.111.0+139]

The boat batch, third step of the chapter-flow roadmap: chapter 3 opens
on raising the camp, and the Rusty Eel becomes the way to reach every
port's expeditions -- a chart of ports, short voyages of sea events, ship
battles fought with the parts aboard, and a shipwright to fit her out.

### Added
- **Camp founding beat.** A new node between the Upper Gate and the Spire
  district: the refugees who followed the party up from the Lower City
  raise a camp on the shingle below the Spire, with the Rusty Eel hauled
  up above the tide, and the story flags `camp_founded`. The camp stays
  there for the rest of the game.
- **Ports** (ports.json, `portsSchema`): a name and description in both
  languages, a chapter, the zones and shops found there, days at sea to
  reach it, `isHome` and `requiredFlags`. Ashen Landing (the camp's
  shore, home port: Cinder Row and the Scaffold Yards) and the Smugglers'
  Wharf (chapter 2's harbor: Fisherman's Row, Tanner's Court, Lantern
  Docks and the three starter shops). The Town Hub is now that port under
  its familiar name; the Camp's zone list is the home port's.
- **The Rusty Eel** (Play → The Rusty Eel, from chapter 3): hull and
  bulwark, the parts fitted by slot (two weapon, one bulwark, one rigging
  slot), repairs at one gold per hull point, the shipwright's six parts
  (ballista to start; harpoon rack, fire pots, iron plating, tar-sealed
  hull, spare canvas) and the chart of ports the story has reached, each
  with its chapter, days at sea and zone count. Setting sail opens a
  voyage; landfall moors the boat there and opens that port.
- **Voyages** (`lib/data/sea_events.dart`): one event per day at sea --
  calm days that mend the hull, storms that cost it, derelicts worth
  salvaging, sightings, and raiders (from chapter 2: a raider skiff;
  chapter 3: an Inquisition cutter; chapter 4: a void barge) that open a
  **ship battle**: pick a fitted part each turn (loose the ballista,
  brace the plating, patch the hull...), the bulwark absorbs before the
  hull, cooldowns keep the heavy parts honest, and a sunk hull limps back
  to the port it left at a quarter strength. Prizes pay gold and XP.
- **Session state**: hull, fitted parts, current and visited ports, with
  full save round-tripping.
- Tests: ship-combat rules, sea-event drawing, ports/ship data validation,
  session ship state.

### Changed
- ships.json / ship_parts.json / enemy_ships.json lose their sci-fi
  placeholders (starter freighter, laser) for the Rusty Eel, fantasy
  parts with FR names and labels, and three enemy ships gated by chapter.

### Simulation
40 seeded runs: 40/40 true endings, 92.2% win rate, every zone cleared,
an attentive player buying the harpoon rack, iron plating and tar-sealed
hull by the end (mean 439 gold on the ship) -- but zero voyages, because
every current zone is either on foot in chapter 2 or at the home port:
the later chapters' ports (next batch) are what make sailing mandatory.
The ship battle itself, run 300 times per loadout: the ballista alone
beats a skiff untouched and a cutter with half a hull, cannot beat a void
barge; harpoons make the barge winnable (15 hull left), iron plating
makes it comfortable (72).

## [1.110.0+138]

The difficulty batch, second step of the chapter-flow roadmap: enemies now
scale with the chapter as well as the party's level, every expedition zone
has a tier, a recommended level and a boss guarding its reward, zones and
the camp's workshops unlock in order, and the Smugglers' Vault no longer
sells endgame steel in chapter 3.

### Added
- **Chapter difficulty curve.** Every enemy's max health is multiplied by
  1 + 0.12 × (chapter − 1) and its damage by half that excess (chapter 3:
  ×1.24 health, ×1.12 damage; chapter 6: ×1.6 / ×1.3), on top of level
  scaling and before the Elite and pack multipliers. Gold and XP climb
  more gently (+10% per chapter). A fight's chapter is its story node's,
  or the zone's for an expedition.
- **Zone tiers and bosses.** zones.json rows carry `tier` (each tier past
  the first adds a tenth to health and half that to damage),
  `recommendedLevel`, `bossEnemyId` with EN/FR boss narration,
  `requiredFlags` and `isMainZone`. Once a zone's events are done its boss
  steps out: the dock overseer at Fisherman's Row, the plague hound under
  Tanner's Court, the smuggler captain at Lantern Docks, an iron sentinel
  on Cinder Row and a void stalker in the Scaffold Yards. Beating it banks
  the zone's reward with a Gold chest at least and half again the gold and
  XP; losing ends the expedition as a defeat.
- **Zone gating and cards.** Lantern Docks waits on the hull being patched
  (Fisherman's Row), the Scaffold Yards on Cinder Row; a locked card names
  the zone to clear first. Town Hub and Camp share one zone card with
  tier, recommended-level (highlighted while the party is below it) and
  Main-zone chips, plus the boss's name.
- **Camp workshops gated on zones.** houses.json `requiredFlags`: the
  Hammersmith waits on the Scaffold Yards, the Academy on Cinder Row, the
  Sharpweave Den on the Lantern Docks' lead; the camp shows the lock and
  `buildHouse` refuses an early build.
- Cinder Row and the Scaffold Yards now set `cinder_row_cleared` /
  `scaffold_yards_cleared` when cleared.

### Changed
- **Smugglers' Vault** stocks tier 6–7 weapons and shields plus the Void
  Banner instead of tier 8–10 (those stay behind the camp's workshops).
- The fight setup screen shows a "Zone boss" note alongside the hunt and
  hunter notes.

### Simulation
40 seeded runs with a player who heeds the recommended level: 40/40 true
endings, combat win rate 91.7% (94.7% with the curve off on the same
seeds), deaths per run 3.4 (2.2), zone bosses won 200 of 201 expeditions
(dock overseer 70% per attempt at level 3, smuggler captain 47% at level
5, void stalker 85% at level 8), chapter-2 story fights 93%, chapter 3
still 100% at a mean level of 9.6 -- the later chapters' new enemies (next
batch) are what that end of the curve is waiting on. A first pass with a
full-rate damage curve (+15% per chapter on both stats) collapsed the
tuned chapter-2 fights (smuggler captain 100% → 16%) and was dropped.

## [1.109.0+137]

The hub-loops batch, first step of the chapter-flow roadmap: the harbor
market and the Spire district are now real hubs that every route passes
through and that the party works through activity by activity, the
chapter Main quests are handed out where their story happens, and quest
items no longer depend on a drop roll.

### Added
- **Hub loops.** A story choice can now carry `hideIfFlags`: once any of
  those flags is set, the choice disappears from its node. Every activity
  on the harbor market (node 2015) and in the Spire district (node 3005)
  sets its own flag and its bridge node ends on "Back to the market" /
  "Back to the district", so a hub plays as a list of things to do that
  shrinks as it is worked through instead of a one-shot pick. The Iron
  Anvil's armoury, shieldwright and patch-up stalls loop the same way.
  Choices that lead back to their own node never roll an excursion. The
  story editor exposes the field ("Hide if flags", comma-separated).
- **Harbor bounty.** A new market activity, the harbor master's bounty on
  the wharf bandits (a two-bandit pack), hands out the Main quest The
  Burning Manifest.
- **Lysa's dawn.** If Lysa survived the Spire, a new district activity
  delivers her message and starts Alster's Dawn.
- **Failure branches** for the Spire archive and ledger checks: a failed
  read now lands on its own consequence node instead of a dead end.
- **Guaranteed drops.** A loot-table entry with a drop rate of 100 or more
  is always awarded on a win, on top of the spoils chest, so the High
  Warden's sealed letter can no longer be missed.

### Changed
- **Every route reaches the hubs.** Disembarking at the wharf now leads
  straight into the market before Vane is dealt with (his three exits,
  the crane and the rooftop archer sit on the hub itself); the stowaway
  route's bilge drain and inspector ambush both come out under the wharf
  and climb into the same market instead of skipping to the Upper Gate.
  The Spire's first doors open onto the district hub, whose only exit
  pushes deeper into the Spire; the openings of nodes 3002 and 3005 were
  rewritten in both languages to fit the new order.
- **Main quests wired to their beats.** The High Warden's Fall starts on
  entering the Spire, the Inquisition Ledger on the ledger choice, the
  Captain's Gambit on the smuggler and Harbor Reckoning on the plague
  hound; the weaponsmith's forge unlocks from the market armoury and the
  blind beggar's stall from the forge.
- **Chapter spine.** The bilge-drain node (2050) moved to chapter 2's
  arrival beat alongside 2010 and 2020.

### Simulation
40 seeded runs (4 strategies, alternating builds) with a player-like hub
policy (take an untried activity 85% of the time): 40/40 true endings,
combat win rate 97.0%, 8.3 harbor-market and 11.9 Spire activities per
run (37/40 and 40/40 runs visit them), 16.7 quests completed per run
(5.2 on v1.108), Kelda recruited in 29 runs (14 before), Sable in 25
(15), full roster 5/40 (1/40), mean final level 10.2 (7.3). The same
seeds under v1.107 rules still end 40/40.

## [1.108.0+136]

The dynamics batch: a clickable spoils chest after every win, enemy
affixes, battlefield conditions, momentum, charms and tomes, hunts, and an
alignment layer in which angels hunt the wicked, demons hunt the righteous,
and both court the undecided.

### Added
- **Spoils chest.** Every won fight now ends on a chest the player taps
  open, then flips slot by slot (or takes all at once; a Settings toggle
  auto-opens it). Its tier — Wooden, Iron, Silver, Gold or Void — comes from
  one visible fortune roll: d100 plus Luck (×2 for the player, ×1 for the
  best ally), +25 for an Elite, +6 per extra pack member, +8 for a
  flawless fight (no potion, nobody knocked out), +8 for two rounds or
  fewer, +8 for a critical killing blow, +8 per affixed enemy, +10 under
  an Ambush or Darkness, and +15 per consecutive Wooden chest. An Elite is
  never below Silver, a boss never below Gold, a first kill of an enemy
  type never below Iron, and a full telegraph read finds one extra slot.
  Contents are drawn by tier from a chapter window of items.json's new
  `rarity`/`lootChapter` bands: gear the party already carries never drops
  again, the last three drops weigh half, profession affinity and a
  matching alignment weigh more, and an enemy's old `lootTable` now only
  marks its signature drops (×3, ×6 on a first kill). Replaces the
  per-enemy drop-rate roll entirely; gold and XP are unchanged, the chest's
  own gold comes on top.
- **New item kinds.** Four charms (Gambler's Knucklebone: one extra reroll;
  Lucky Coin: +15% crit; Ironskin Salve: +5 armor; Warding Knot: the first
  hit taken is negated), picked on the fight's setup screen and burned for
  that fight only; two tomes read on the spot (Tome of Insight: +1 stat
  point; Tome of Mastery: +1 skill point); eight named pieces of gear, four
  of them alignment-bound.
- **Enemy affixes.** A solo enemy has a 20% chance (a pack member 15%) of
  one trait: Venomous (attacks poison), Armored (ignores 4 damage from
  Attack faces; Skill faces cut through), Skittish (flees below a quarter
  health with half its reward and one chest tier), Frenzied (×1.4 damage
  below half health) or, in packs only, Pack Leader (+20% health, and the
  rest of the pack hits ×1.25 while it stands). Bosses, uniques and Elites
  never carry one. Shown as a title ("Venomous Harbor Rat") with its rules
  on the setup screen.
- **Battlefield conditions.** A quarter of fights open under one: Ambush
  (enemies strike first, nothing reads off them that round), Darkness
  (every telegraph one tier worse), Cramped (packs of three: only two reach
  the party each round), High Ground (Defend ×1.5), Shrine (Heal faces and
  potions ×1.5).
- **Momentum.** Three damaging party hits with no enemy hit landing in
  between make the next Attack/Skill face a guaranteed critical.
- **Hunts.** After a random pack fight, a 35% chance of a trail leading to
  the pack's named survivor ("Merrick the Half-Faced", "Old Scar"): 20% more
  health, two affixes, ×1.5 rewards and a chest never below Gold. Expedition
  hunts are extra events, never a substitute for the zone's own.
- **Alignment on the road.** Off a Good or Evil score (±20), a hunter of
  the other side ambushes 10–22% of story transitions and expedition draws:
  angels (Sentinel and Judicator of the Choir) for the wicked, demons (Pit
  Imp and Tormentor of the Pit) for the righteous, the stronger pair from
  chapter 3. Hunters yield ×1.25 rewards and never less than a Silver chest,
  and never appear as ordinary random enemies. A Neutral character instead
  meets temptations (10%): four short scenes that pull the score one way or
  the other for gold, and two quest offers — "A Charge of Light" (kill a Pit
  Imp, +15) and "A Bargain in Shadow" (kill a Sentinel, −15) — which let the
  hunted side come looking while active. A Settings toggle turns the whole
  layer off.
- **Alignment on skills and gear.** A skill tagged `alignment` in
  skills.json is ×1.25 for a matching character and ×0.75 for the opposite
  (fourteen existing skills are tagged: the cleric's light and the void/
  poison kit chiefly); two new gated skills, Celestial Ward (Good) and
  Infernal Pact (Evil). Gear tagged with an alignment can't be worn by the
  opposite one and pays an `alignedAttackBonus`/`alignedArmorBonus` to a
  match; opposed gear never drops. The inventory and skills screens say so.
- **Companion banter** for four more moments (fight start, a pack sighted,
  an ally knocked out, a Gold-or-better chest), authored EN/FR for all six
  companions.

### Changed
- The Inquisition Warden leaves the random pack pool (17 damage is the
  chapter-1 heavy; a pair of them stuck a level-1 character for 25
  attempts in simulation). It stays a solo encounter with its own
  signature drop.
- Simulator port (sim_v3.py) of every rule above, run over the same 40
  seeds as the v1.107 batch: 40/40 endings, 98.4% combat win rate (98.0%
  before), affixed fights 98.1% vs plain 98.4%, chests Iron 25% / Silver
  25% / Gold 45% (about 26 points of that from the boss and hunt floors) /
  Void 3%, 2.5 tomes and 7.7 charms per run, 83 hunts and hunter ambushes
  across the batch (the Judicator, at 55%, is now the hardest fight in the
  game and only stalks the wicked), and end-of-run gold roughly doubled
  (1191 vs 604) from chest gold and the extra fights.

## [1.107.0+135]

The review's remaining P2 items: the Chapter-1 difficulty wall, three
combat-engine/data outliers, and the continuity nits.

### Fixed
- **The Rat Matriarch is no longer a Chapter-1 wall.** Node 855's forced
  fight (195 HP / 24 damage, the lowest win rate in the game at 48–63%,
  and a hard stop for a level-2 mage) is now 150 / 18, and the node offers
  "Back away and look for another way through" — the sewer's other exit.
- **`OnLowHealth` moves now honor their `chance`.** Every wounded-enemy
  nuke in enemies.json is authored at 40–60%, but the engine fired it 100%
  of turns below the threshold.
- **`void_blast` is no longer a one-shot.** 25 × 2.5 gave a flat +62.5 to
  every enemy that carries it (three times any other enemy skill) and
  ~128 damage in a level-4 player's hands (Sable's die now carries it for
  free). Retuned to 12 × 1.8. The three regression-tested bosses that leaned
  on it get a small base bump to stay in their tuned win-rate bands (High
  Warden 170 HP, Zealot 20 dmg / 160 HP, Manifestation 21 dmg / 165 HP).
- **`heavy_attack` no longer beats every purchasable skill for free**
  (8 × 1.6 → 6 × 1.4; still the default for any unassigned Skill face).
  The Plague Hound and Smuggler Captain — the other two Chapter-2 heavies
  a random excursion can force on a level-3 character — come down with it
  (175 / 21 and 180 / 21, from 205–210 / 24) so neither is a wall for a
  weak solo build.
- **Packs scale to the party.** A random pack never outnumbers the party's
  dice — a solo character meets at most a pair — and pair/triple members
  now fight at 80% / 70% of their solo stats (a level-5 solo mage went 0
  for 25 against a triple on action economy alone). The Dock Overseer and
  Inquisition Soldier leave the pack pool: two 40%-chance stunners lock a
  solo character out of most rounds, whatever their stats.
- **Pack overkill is redirected instead of wasted.** A hit whose picked
  enemy went down to an earlier blow this round now carries on to the next
  one standing, with the log saying so — previously it vanished while the
  log still claimed a hit.
- A telegraph badge can no longer name a party member poison just knocked
  out — the cached move is re-aimed at someone conscious.
- Story continuity: the Chapter-2 rat swarm is in the ship's forward hold,
  not a sewer; hiding in the cargo hold means slipping back aboard; a failed
  winch roll no longer draws steel on Vane; Kroll's fight now follows his
  taunt (the choice of mercy or vengeance is the fight, not its aftermath);
  the informant's ambush is three men fighting for the informant, not one
  for Vane; the smuggler waves *you* aboard on every path; the Chapter-3
  climax names the High Warden and knows two chapters remain; bribing the
  archivist costs 40 gold (and needs it); a failed archive lockpick skips
  the archive; paying the bridge toll no longer starts a kill quest; and
  `[COMBAT]`/`[TORTURE]`/`[SUCCESS]`-style authoring tags no longer leak
  into the prose.

## [1.106.0+134]

Fixes from the full mechanics/narrative review and the 40-playthrough
simulation.

### Fixed
- **Orc and Voidkin characters could not finish Chapter 1.** Any node with
  a flag/gold/alignment requirement also silently required Charisma ≥ 0
  (the default `reqCharisma` of 0 was compared against a negative starting
  Charisma), which locked all three doors at the smuggler gate (node 895)
  and every later gated node. Only a node that actually sets `reqCharisma`
  gates on it now.
- **Random enemy packs were unwinnable.** Packs of two or three chapter-2
  heavies (Rat Matriarch, Smuggler Captain, Plague Hound) out-statted every
  boss; in simulation a third of chapter-2 expedition fights were lost and 4
  of 40 runs ended stuck on one. Packs now draw only from `packEligible`
  trash-tier enemies, are capped at pairs through chapter 2, and each member
  is scaled to 85% (pairs) / 75% (triples) of its solo stats. Rewards are
  unchanged, so a pack still pays more than the same enemy alone.
- **Bought and looted potions/antidotes were inert.** They landed in the
  inventory where nothing could drink them; only the starting 3 potions and
  1 antidote ever existed. Potion-type items now become charges (a Major
  Healing Potion is worth two) when bought, looted, or granted by a quest.
- **Weaken lost a turn on both sides.** Party members' effects ticked before
  they acted (a 2-turn Weaken weakened one swing; with Wisdom ≥5, none), and
  a Weaken landed on an enemy was baked into its already-pre-rolled move a
  turn late. Members now tick after acting, and enemy moves are pre-rolled
  un-weakened with the debuff applied when the hit actually lands.
- **Companion signature-die faces fizzled.** Maren's Smite/Revive Prayer,
  Sable's Void Blast, Liora's Beast Bond, Vess's Entropy Touch and Grosh's
  Adrenaline Surge were all "Skill fizzles" until that exact skill was
  bought; every skill linked on a companion's signature die is now unlocked
  at recruit.
- Story: Vane's guards (2040) and the pushed-past Wardens (822) now actually
  fight; a failed ledger check at 3005 no longer lands on the acolyte's
  post-fight text; the torturer no longer dies at 810 before returning at
  955; the Rusty Eel beat reads correctly whether or not it was repaired.
- Quests: the Ashen Oath, Void Relic, Liora's Watch, Kelda's Stand and
  Dockside Debts kill targets are fought on the bridge node that hands out
  the quest, instead of being unreachable once the one-shot hub is left;
  Tern Row and Reckoning Wall quests are offered before their kill, not with
  it; The Heirloom of Alster completes by taking the bundle at the hovel
  (new `Flag` objective type) instead of only by buying the heirloom back.

### Changed
- **Perception is readable earlier and pays off tactically.** Every
  character starts with 1 Perception (Elf/Ranger +4 as before), enemy Guile
  is rescaled (trash 0–1, mid-tier 2–3, uniques 4–5, bosses 6–7) so an early
  investment reads trash immediately and a dedicated build can read a boss,
  and a Defend face rolled by the member a readable telegraph is aimed at
  blocks double.
- Data polish: Slum Thug shows its name instead of its id, two no-op enemy
  moves are gone, and `void_die` declares its real face count.

## [1.105.0+133]

Perception-gated enemy telegraphing and multi-enemy pack combat.

### Added
- **Perception stat and enemy telegraphing.** A new Perception stat (mirrored
  onto allies, race/profession bonuses — Elf and Ranger both get +4, making
  it their signature stat) is compared against a new enemy-side Guile stat to
  determine how much of an enemy's next move the party can see ahead of
  time: nothing below 1 net Perception, just who's targeted from 1-4, who
  plus a rough move category (attack/heal/debuff icon) from 5-9, and full
  detail (move name, element, effect) at 10+. Guile is deterministic and
  subtractive (`perception − guile`), not a per-turn roll, so bosses stay
  harder to read even for a heavily invested Perception build. Enemy moves
  are now decided one step ahead and shown as a telegraph badge, then
  applied unchanged on that enemy's actual turn.
- **Multi-enemy pack combat.** Fights can now pit the party against 2-3
  enemies at once, with an explicit target picker letting each attacking
  party member choose which living enemy to hit. Random expedition/excursion
  encounters have a chance to roll a pack instead of a single enemy, and two
  hand-placed pack encounters were added to the Chapter 2 and Chapter 3 hub
  nodes. The game's tuned boss/unique fights are excluded from packs (and
  packs are never Elite), so their balance is untouched. Rewards, loot, and
  kill-count credit are summed across every enemy defeated in a pack.

## [1.104.0+132]

Critical hits, dodging, companion banter, and Elite enemy encounters.

### Added
- **Critical hits and dodging in combat.** Luck now drives a critical-hit
  chance (5% baseline, +1.5% per point, capped at 35%) on every damaging
  Attack/Skill die face for the player and every active ally alike — a crit
  multiplies the hit's damage by 1.5x and is called out in the log. Dexterity
  now drives a dodge chance (5% baseline, +1.5% per point, capped at 30%) for
  whoever the enemy targets — a dodge evades the hit entirely, no damage, no
  status effect. Allies derive their own Luck the same way they already
  derive Wisdom, from their race/profession bonuses, so the mechanic applies
  uniformly across the whole party.
- **Companion banter.** An active ally has a chance to react with a short,
  personality-voiced line in the fight log when a crit lands or a hit is
  dodged — six new lines per companion (crit + dodge, EN + FR).
- **Elite enemy encounters.** Roughly 12% of eligible fights promote the
  enemy to an "Elite" version: +35% health/damage, +50% gold/XP reward, and
  a guaranteed unique "Elite Mark" trophy drop, with a gold-accented name and
  portrait in the fight UI. The game's tuned boss fights are excluded, so
  Elite stays a trash-pool variance mechanic rather than a boss reskin.

## [1.103.0+131]

### Added
- **A Map tab in normal (in-game) play**, not just Edit Mode. Now that the
  map shadows nodes you haven't reached yet (previous release), it's safe
  to hand to players — same fog-of-war rules apply, so nothing about a
  future chapter is spoiled. Edit Mode keeps its extra Generate/Data tabs;
  Map now shows in both.

## [1.102.0+130]

Fog of war for the story map: outside Edit Mode, it now shows your journey
so far rather than the entire spoiler-laden graph at once.

### Added
- **The story map shadows nodes you haven't reached yet.** A node the
  player hasn't actually visited this playthrough now renders as an
  unrevealed shadow (position and connecting edges still visible, so the
  map's shape reads as a map) instead of its real kind, id, and
  description — tapping it explains it hasn't been discovered yet rather
  than opening the full node-info sheet. Edit Mode is unaffected and
  always sees the whole graph, same as every other authoring feature
  already gated to it. A new legend row explains the shadow style.
- `StoryPlayState.visitedNodeIds`, a monotonically-growing set backing
  this — persisted alongside the existing autosaved position/history, and
  backfilled from history for a save written before this feature existed
  so a returning player doesn't lose map progress they've actually made.

### Fixed
- `StoryPlayNotifier._persistAutosave` read `state` after an `await`,
  which could throw ("Tried to use StoryPlayNotifier after dispose") if
  the notifier was disposed while a fire-and-forget autosave was still in
  flight — a pre-existing latent race, made easy to hit by this batch's
  extra autosaved field. Now snapshots `state` synchronously before the
  first await instead.

## [1.101.0+129]

A quicker way to hand a reviewer (human or AI) your authoring notes without
sharing the whole repository.

### Added
- **JSON and CSV export for Review Comments.** The Review Comments screen's
  export button (Edit Mode → the notes left on story nodes while reading or
  testing) now offers a format picker — plain text as before, plus a
  compact JSON array and a CSV file, each just `id`/`chapter`/`comment` per
  commented node. Meant to be pasted straight into a prompt when a repo
  link isn't the easiest way to hand someone your notes.

### Changed
- Extracted the Review Comments export formatters into
  `lib/utils/comment_export_format.dart`, shared by the screen and now
  covered by dedicated unit tests independent of the widget tree.

## [1.100.0+128]

A follow-up balance pass on the last two updates: endgame gear is reachable
again, `kroll_the_branded`'s signature move is no longer a stun-lock trap,
achievement copy matches the current roster, and the playthrough simulator
finally models Wisdom and status effects — which is what surfaced the real
size of kroll's problem in the first place.

### Changed
- **Endgame sword/spear requirements loosened.** Tier 8-10 swords and spears
  required Strength 10-14 plus Constitution 4-8 — thresholds high enough
  that a normally-leveled character could reach the late chapters without
  ever qualifying for their own tier of gear. Now Strength 6/7/8 with only a
  small Constitution add-on at t9-10 (2/3); t4-7 unchanged.
- **`kroll_the_branded` rebalanced twice this batch**, once before and once
  after extending the simulator (see Fixed below): `maxHealth` 196 → 145,
  `damage` 24 → 19. Its signature move, Radiant Judgment, inflicts Stun on
  top of a heavy hit — `damageMultiplier` 1.4 → 1.2 and trigger `chance`
  35 → 18, so the stun-then-big-hit combo is rarer and less punishing when
  it lands, rather than the near-guaranteed spiral it was.
- **`plague_hound` trimmed to its actual weight class**: `maxHealth` 239 →
  205, `damage` 28 → 24 (matching `rat_matriarch`/`smuggler_captain`, the
  next enemies down), and its Poison-inflicting bite's trigger chance
  45% → 33% — it had drifted well above its chapter-2 peers.
- **`full_roster`/`full_party` achievement copy corrected** to match the
  current 6-companion roster and 2-active-ally party cap: "Three's
  Company" → "Full House" ("Recruit all three companions" → "all six"),
  and "Field a full 3-member active party" → "Field two active companions
  at once."

### Fixed
- **The (non-shipping) Python playthrough simulator never modeled Wisdom's
  combat role or status effects** (Poison/Stun/Weaken), even though both
  have been live in the shipped game since v1.98.0 — every simulation
  batch since then was blind to them. Fixed: the simulator now ticks
  Poison, skips a Stunned combatant's round, applies Weaken to a
  combatant's own outgoing damage, and gives Wisdom its real heal-bonus
  and status-resistance effect, turn-for-turn matching
  `_startPartyRound`/`_confirmRoll`/`_takeEnemyTurn` in `fight_screen.dart`.
  This immediately surfaced that `kroll_the_branded`'s Stun move made it a
  genuine outlier (a ~36% true win rate, invisible to every earlier,
  status-blind simulation) — the deeper kroll rebalance above is a direct
  result of this fix.

Re-simulated after this batch: 85.7% combat win rate, no enemy below a 50%
win rate (down from `kroll_the_branded` at ~36% once status effects were
actually counted), 100% true-ending rate across 40 runs, and
`boss_balance_test.dart` still passes unchanged.

## [1.99.0+127]

Real pixel-art icons for every item, skill, enemy, and shop, replacing the
generic Material glyphs that stood in for them since launch.

### Added
- **170 procedurally-generated pixel-art icons** (16x16, upscaled with
  crisp-pixel rendering) covering all 63 items, 79 skills, 18 enemies, and
  10 shops -- full 1:1 coverage with the current game data, verified by a
  new coverage test. Wired into every place a player actually sees one of
  these by its own identity: the Inventory/Equipment screen (equipped
  slots, item list, item-picker sheet, detail dialog), shop stock lists,
  the Skills screen (list rows and detail dialog), the race/profession
  skill preview during character creation, the Fight screen's enemy
  portrait, and the Boutiques/basic-shops lists in Camp and Town Hub. Falls
  back to the existing generic icon for any id without a matching asset
  (defensive, not expected to trigger today).

## [1.98.0+126]

Wisdom finally does something in a fight, status effects show up more often,
and combat is meaningfully harder across the first three chapters.

### Added
- **Wisdom's combat role.** Beyond backing Wisdom story checks, it now
  amplifies every point healed (by `wisdom ÷ 2`, both dice-face Heal and
  healing Skill faces) and shortens the duration of Poison/Stun/Weaken
  landed on you by 1 round per 5 points, never below 1 round. Applies to
  active allies too, derived from their own race/profession the same way
  Strength/Dexterity/Constitution/Intelligence already were.
- **7 more status-inflicting skills** (up from 7 to 14 of 79): Rogue's
  Poison Blade now actually poisons, Mage's Frost Nova and Orc's Savage
  Cleave inflict Weaken, and Ranger's Trap Set plus 3 elemental enemy moves
  (Frigid Grip, Molten Backlash, Radiant Judgment) inflict Stun/Weaken —
  status effects show up in noticeably more fights.

### Changed
- **Harder combat in Chapters 1-3.** Enemy health and damage scale up by
  chapter (+15% in Ch1, +35% in Ch2, +10% in Ch3), pulling the overall
  combat win rate down from ~95% to ~87% and roguelike-style "close calls"
  (lost fights — permadeath is off by default, so these cost time, not the
  run) up to an average of 3 per playthrough. Chapters 4-5 are intentionally
  left alone: an existing regression test (`boss_balance_test.dart`) locks
  in win-rate floors for 3 late-game bosses that a prior session already
  found could become unwinnable, and that ceiling is the reason overall
  difficulty stops short of an even harder target.

### Fixed
- The playthrough simulator never actually visited Camp's own Expedition
  zones (chapter 3 onward) — only Town Hub's chapter-2 zones were ever
  driven, so `z_cinder_row`/`z_scaffold_yards` always showed 0 attempts in
  every prior simulation batch. Fixed in the (non-shipping) Python
  simulator only.

## [1.97.0+125]

Three new camp buildings that finally give endgame gear somewhere to be
bought, and loot that leans toward what your profession actually wants.

### Added
- **Three new camp houses: Hammersmith, Academy, and Sharpweave Den.** Each
  is buildable from Camp for 350 gold and, on completion, immediately
  unlocks a themed shop — the Hammersmith's Forge (swords/spears/shields),
  the Arcane Academy (staves), and the Sharpweave Den (daggers) — stocking
  tier 6-10 gear that was previously only obtainable as loot, quest, or zone
  rewards and had no purchasable source anywhere in the game. Built houses
  now show an "Unlocks: ..." line alongside their existing stats, and Camp
  gained a new Boutiques section listing every shop a built house has
  opened, reusing the same shop-browsing screen as Town Hub.
- **Profession loot affinity.** Every profession now favors one ability
  score's gear (Warrior → Strength, Mage → Intelligence, Rogue/Ranger →
  Dexterity; Cleric has none, since Wisdom has no gear-scaling tie-in) via a
  new `preferredScalingStat` field. A combat loot roll for an item whose own
  `scalingStat` matches gets a flat +20 percentage-point bump on top of the
  existing luck bonus — a Mage sees noticeably more staves off the same
  enemy a Warrior would fight, without any single drop ever becoming
  guaranteed.

## [1.96.0+124]

Gear that actually cares who's wielding it: weapons now scale with your
ability scores, and the heaviest ones require enough of them to wield at all.

### Added
- **Ability-score weapon/shield scaling.** Every sword, spear, dagger,
  staff, and shield now declares which ability score it scales with
  (Strength for sword/spear, Dexterity for dagger, Intelligence for staff,
  Constitution for shield), adding `stat ~/ 2` on top of its flat
  attackDamage (or armor, for shields) — a Mage's staff hits harder with
  Intelligence, a Warrior's sword with Strength, without any profession-
  specific code: the effect is entirely driven by which weapon type is
  equipped. Never subtracts below an item's flat value, so an off-build
  weapon just doesn't reach its full potential. Applies to allies' own
  equipment too, scaled off their race/profession-derived scores.
- **Stat-gated equipment requirements.** The heaviest three tiers of every
  sword and spear now require both Strength and Constitution to equip (a
  "heavy sword" needs the power to swing it and the stamina to keep
  swinging); daggers, staves, and shields scale their own single-stat
  requirement up through their tiers. Early-tier gear (t1-t3) stays
  unrestricted so no build is locked out of basic equipment. The
  Inventory/Equipment screen shows a lock icon and a "Requires: N STR, M
  CON"-style note on anything not yet met, for both the player and any
  ally.
- Updated the four ability-score stat-hold explanations (Strength,
  Dexterity, Constitution, Intelligence) to mention their new gear tie-in.

## [1.95.0+123]

Hold a stat to see what it does.

### Added
- **Long-press stat explanations.** Every core stat row (Health, Base
  Damage, Base Armor, Luck, Charisma, Strength, Dexterity, Constitution,
  Intelligence, Wisdom) on the character sheet (`RaceProfessionScreen`) and
  the level-up screen (`LevelUpScreen`) can now be held to pop up its
  purpose and gameplay impact, reusing the existing `*_desc` strings so the
  two screens' explanations never drift apart. The level-up screen's
  existing tap-the-icon shortcut still works alongside it.
- A small hint ("Hold a stat to see what it does") on both screens so the
  new interaction is discoverable.

## [1.94.0+122]

A reviewer-comment system for story nodes: leave a private note while
reading/testing in Edit Mode, then find every note again in one place.

### Added
- **Reviewer comments on story nodes.** The node editor (`StoryNodeEditorScreen`)
  has a new "Reviewer comment" field, saved on `StoryNode.authoringComment` —
  a free-text note never shown to players, for things like "pacing feels
  rushed here" or "needs a 3rd choice". Persists through the same local
  edit-override mechanism every other node edit already uses.
- **Review Comments screen**, reached from the Data tab: lists every node
  with a comment (id, chapter, comment text), tap to jump straight into
  that node's editor, plus Copy/Export actions (reusing a newly-extracted
  `lib/utils/export_utils.dart`) so the whole list can be pulled off the
  device as plain text.
- The Map (story graph) view now marks commented nodes with a small badge,
  and its node-info sheet shows the comment inline plus a new "Edit Node"
  button, so a comment is discoverable without leaving the graph.

### Known issue (pre-existing, not touched here)
- While live-verifying this feature, found the choice editor's "destination
  node" dropdown overflows at phone width — unrelated to this change, left
  as-is; flagged for a follow-up fix.

## [1.93.0+121]

Over-branched story nodes (10-12 choices piled into one flat button list)
now present like a village instead of a wall of text.

### Changed
- **Nodes with more than 5 choices** (currently 2010, 2015, 3005) now split
  their non-core choices — shops, fights/skill checks, and people to talk
  to — into categorized "Shops" / "Challenges" / "People" sections with a
  Rest option, rendered as icon-led cards below the node's own main
  branches, instead of one long list of identical-looking buttons. Nodes
  with 5 or fewer choices are unchanged. All existing choice logic (ability
  checks, combat, unlocks, routing) is shared via one extracted function,
  so the new cards behave exactly like the buttons they replace.

## [1.92.0+120]

Chapter 1 follow-up to the Town Hub/Camp redesign: two of Chapter 1's own
shop unlocks turned out to duplicate Town Hub's now-permanent boutique list,
undercutting "Town Hub is the first shopping stop between Chapter 1 and 2."

### Fixed
- **Removed two Chapter 1 shop unlocks that now duplicate Town Hub's
  permanent boutiques.** Node 100 (the opening tavern scene) no longer
  unlocks the Blind Beggar Stall, and node 891 (the pre-boss docks scene) no
  longer unlocks the Weaponsmith's Forge — both are already always available
  at Town Hub from the Chapter 1/2 seam, so granting them again mid-Chapter-1
  was redundant and made the boutiques feel like they "arrived too early."
  Node 891's other two shop unlocks (Black Market Docks, Shieldwright's
  Hall) are untouched: neither is part of Town Hub's curated list, and
  neither has any other unlock point in the story graph, so removing them
  would have made those shops permanently unobtainable.



Reshapes the mid-game meta-progression loop so Town Hub and Camp read as two
distinct, sequential stops rather than one thing available from the start
and another available from the very first chapter.

### Changed
- **Town Hub is genuinely "the first stop between Chapter 1 and 2"** now
  that it has more than two shops: added Apothecary Row to its permanent
  boutique list (alongside the Blind Beggar Stall and the Weaponsmith's
  Forge). Its unlock point was already exactly this seam
  (`chapterOfNode >= 2`, flipping the moment Chapter 2's opening node
  fires) — this was a content gap, not a gating one.
- **Camp is now discovered at the start of Chapter 3**, not available from
  the very first minute of a new game. `PlayScreen`'s Camp entry mirrors
  Town Hub's own lock/subtitle treatment, unlocking once
  `chapterOfNode >= 3`.
- **A freshly recruited companion now joins the active party immediately**
  (up to capacity, respecting their own house gate if they have one) —
  `recruitAlly` no longer requires a trip to Camp to actually help in a
  fight. Needed once Camp stopped being available from turn one: Kelda,
  Sable, and Liora all recruit in Chapter 2, before Camp exists.
- **Camp becomes the second expedition hub, picking up where Town Hub
  leaves off.** Camp's Roster/Houses now sit above a new Zones section
  showing every zone from Chapter 3 onward (two new ones: Cinder Row and
  the Scaffold Yards, `ashenStreets`-themed, dropping gold and the new
  `plate_emberproof` armor respectively) — forward-compatible with future
  chapters' zones without further wiring.

### Added
- **A quiet payoff for actually doing Town Hub's expeditions**: completing
  Fisherman's Row and Tanner's Court (2 of Town Hub's 3 zones) now marks
  the Rusty Eel's hull patched and sail mended. At Chapter 2's close (node
  `2900`, the approach to the Upper Gate), a new choice lets the player
  check on the ship one last time and see it seaworthy again — locked with
  in-character flavor text if they never got around to it. Deliberately a
  narrative acknowledgment, not a hard requirement: skipping every
  expedition still lets the story continue exactly as before, just without
  that beat.
- `partyCapacityFor` (`player_session_provider.dart`), extracted out of
  `CampScreen` so its own roster capacity math and `recruitAlly`'s new
  auto-activate logic can never drift apart.

## [1.90.0+118]

Elements go from flavor text to a real combat layer, and last patch's
status-effect system gets a wider footprint across skills, companions, and
items.

### Added
- **Elemental damage/resistance, finally wired up.** `items.json` has
  carried per-element `<element>DmgBonus`/`<element>Resist` fields (and a
  fully-authored Fire→Wind→Earth→Water→Electricity staff progression) since
  early in this project, completely unread by combat. `resolvePlayerFace`
  and `resolveEnemyMove` now both apply them: a party member's outgoing
  Attack/Skill damage is boosted by their gear's matching element bonus (the
  element comes from the skill's own `element` field for Skill faces, the
  die face's own for Attack faces), and an enemy move's damage is cut by the
  target's matching resist gear the same way armor and block already are.
- **Two new elements: Ice and Light.** Added to `elementOptions` alongside
  Fire/Wind/Earth/Water/Electricity/Void, with their own `iceDmgBonus`/
  `iceResist`/`lightDmgBonus`/`lightResist` item fields (Void picked up the
  matching `voidDmgBonus`/`voidResist` pair too, completing `void_banner`'s
  existing all-elements bonus).
- **`OnHitByElement` is a real condition now.** `skillMoveConditionOptions`
  has listed it since enemy moves first shipped; it always evaluated to
  false. `FightScreen` now tracks which elements the party actually hit the
  enemy with each round and feeds it to `resolveEnemyMove`, so a move can
  react to it — `iron_golem` now shrugs off Fire and flings it right back
  (`molten_backlash`, a real reason to *not* bring fire against a golem).
- **New elemental content:** `frigid_grip` (Ice) for the docks' Overseer
  Renn, `radiant_judgment` (Light) for Inquisitor Kroll, plus three new
  elemental-gear drops (`plate_emberproof`, `cloak_frostward`,
  `circlet_radiance`).
- **Status effects reach further.** Three more signature skills now inflict
  one: `warrior_shield_bash` (Stun — a shield bash staggers), `rogue_backstab`
  (Weaken — thrown off balance), and `voidkin_entropy_touch` (Poison —
  unraveling flesh, matching last patch's "void corruption" pitch).
- **A cure for them, too.** New `antidoteCount` resource (mirrors
  `potionCount`'s plumbing exactly) and `consumeAntidote()` clear every
  active Poison/Stun/Weaken off the player. A new Antidote button appears in
  `FightScreen` whenever the player actually has something to cure; a new
  `antidote` item drops from Plague Hounds.

## [1.89.0+117]

Combat gets a status-effect system: Poison, Stun, and Weaken now exist as
real, persistent afflictions rather than one-off numbers, on both sides of a
fight.

### Added
- **Poison/Stun/Weaken status effects.** New `lib/combat/status_effect.dart`
  holds the pure model (`StatusEffect`, `applyStatusEffect`,
  `poisonDamageFor`, `isStunned`, `applyWeaken`, `tickStatusEffects`) and
  `FightScreen` wires it into the party's simultaneous-round turn loop:
  Poison ticks flat damage at the start of the afflicted side's round,
  Stun excludes a combatant from acting that round (with the whole party
  round auto-skipped straight to the enemy's turn if everyone able to act
  is stunned, rather than stalling on a roll nobody can make), and Weaken
  cuts the afflicted combatant's own outgoing damage for its duration.
  A new row of small chips under each health bar (party and enemy) shows
  every active effect with its remaining rounds.
- **Skills and enemy moves can inflict them.** `skills.json` records gained
  optional `inflictsStatus`/`statusDuration`/`statusMagnitude` fields, read
  by both `resolvePlayerFace` (Skill faces) and `resolveEnemyMove` (enemy
  `skillMoves`, via the same referenced skill record) in
  `combat_engine.dart`. Wired into real content: the player's existing
  `venomous_ambush` merge-skill now actually poisons on hit (matching its
  "the wound that doesn't stop" flavor text), a new `plague_bite` gives
  Plague Hounds their disease bite, and two new Void-flavored abilities —
  `void_drain` (Weaken) and `disorienting_pulse` (Stun) — round out Void
  Stalkers and the Void Manifestation boss.

### Changed
- `resolvePlayerFace`/`resolveEnemyMove` take an optional `activeEffects`
  parameter so a Weakened attacker's damage is correct in both the
  resolved number and its preview/log message, not just applied
  after the fact.

## [1.88.0+116]

Interface diversity, this time: the story graph has tagged every node with
its setting (`context_taxonomy.ui_theme` — docks, cathedral, slums,
catacombs, sewers, torture chamber...) since the very first version of this
app, but that field only ever picked which flavor pool random excursions
drew from. The reading screen itself always looked identical no matter
where the player was.

### Added
- **Location-based accent theming on the story reading screen.** Eight
  settings with real narrative weight — docks, cathedral, torture chamber,
  slums, catacombs, sewers, and the two ending flavors (origin_ending,
  epilogue) — now shift the prose card's border, header color, and a faint
  background tint to match, plus a light typographic nudge (letter-spacing,
  line height) for a few of them: tighter and quicker through interrogation
  scenes, slower and heavier through the catacombs and sewers. The
  remaining, rarer settings (bridge, market, hovel, gate, prologue,
  battlements — each under 5 nodes) are left exactly as they were.
  Deliberately layered on top of the player's own selectable app palette
  (Settings → 7 color options) rather than replacing it: only this one
  card's colors move, never the app's chrome, navigation, or any other
  screen. New `lib/data/ui_theme_palettes.dart` holds the per-location
  palette data and a pure `resolveUiAccent` blending function — accent
  hues are blended into the scheme's own `onSurface`/`outlineVariant`
  colors (not used raw) so every location stays legible in both light and
  dark mode and against all 7 base palettes, verified with unit tests
  checking luminance in both directions.

## [1.87.0+115]

Gameplay diversity, as opposed to the last two entries' narrative/world
content: a genuinely new non-combat interaction type, not just another
single ability-check roll.

### Added
- **Skill Challenges: a new multi-round "push your luck" mechanic**, distinct
  from both a one-shot ability check (a single roll settles it) and full
  combat (health, dice faces, an enemy). A skill challenge is a sequence of
  rolls against the same ability and DC, won by reaching a set number of
  successes before a set number of failures — an early bad roll doesn't end
  the attempt, it just narrows the margin, which is the whole point of
  offering it as its own thing. Implemented as two new optional fields on a
  story choice (`challengeSuccessesNeeded`/`challengeMaxFailures`, alongside
  the existing `checkAbility`/`checkDC`/`failNextId`) resolved by a new pure,
  independently-testable function (`lib/data/skill_challenge.dart`) and
  presented through a new dedicated screen
  (`lib/screens/skill_challenge_screen.dart`) that reveals each round in
  turn with a running success/failure tally before the final result — pushed
  and popped the same way the combat screen reports a win. Added editor
  support for the two new fields alongside the existing ability-check editor
  UI, so more of this content can be authored later.
- **First real use: a card game at the Chapter 2 harbor market** (new choice
  on node `2015`, "Sit in on a card game with dock regulars"). Win 3 hands
  before 2 losses (a Luck-based skill challenge, DC 12) for a solid payout;
  lose the challenge and it costs a little instead — either way, the story
  continues normally.

## [1.86.0+114]

Second round of narrative/world diversity content, this time in Chapter 3:
a population the story had repeatedly referenced as backstory (the
Inquisition's slum purge, mentioned at nodes `100`/`3001` and named as the
High Warden's crime in `q_ch3_the_high_wardens_fall`) but never gave real
presence to.

### Added
- **The Reckoning Wall, a new Chapter 3 location, and its side quest.**
  Reached via a new choice on the Ashen Quarter hub (node `3005`), the wall
  is where purge survivors — led by a woman named Reya — chalk the names of
  everyone the Inquisition's official record insists simply "relocated," a
  counter-record to the same erasure already running through this chapter's
  Hall of Records content. An Inquisition auxiliary (a new
  `inquisition_auxiliary` enemy) is sent to burn the wall before it becomes
  evidence. Players can talk him down with a DC 13 Intelligence check —
  quoting Inquisition procedure back at him, deliberately a different stat
  and angle than Tern Row's Charisma-based resolution — for a no-combat
  outcome (25 gold, +5 alignment, its own flag), or fight him directly,
  which registers the formal quest (`q_ch3_reckoning_wall`, 50 gold/60 XP/+5
  alignment on completion). Failing the check still leads to the fight
  rather than a dead end, same pattern as Tern Row.

## [1.85.0+113]

Acted on a full Chapter 1-2 audit: one game-breaking bug fixed, two smaller
balance/continuity issues cleaned up, plus a requested change moving the
chapter's first shop access next to its boss fight. (One audit finding —
`rat_matriarch`/`kroll_the_branded` tagged `minChapter: 2` despite fighting
in Chapter 1 — turned out to be correct as shipped: that field only gates
the *random* excursion pool, not their scripted story fights, and was
deliberately set that way in a previous pass to keep Chapter 1's random
encounters safe. Left unchanged. Also skipped a purely cosmetic finding —
missing `npcs.json` entries for Kelda/Sable/Liora — since nothing currently
reads that data for them and adding unused records isn't worth the churn.)

### Fixed
- **Vess's questline (`q_ch1_vess_in_the_dark`) was permanently
  unreachable.** Node `151_vess` requires the `void_marked` flag, but the
  only choice that ever sets it (`281_scarred`, reached by *failing* the
  luck check at the Tear) routed straight past the market stall that leads
  to her — no playthrough could ever satisfy the gate. `281_scarred`'s
  "Continue" now routes through node `151` first, so a void-marked player
  can actually find her. Added a permanent regression test
  (`test/story_graph_integrity_test.dart`) that walks every path from the
  start node tracking which flags are set along the way, since the
  existing integrity check deliberately ignores `reqFlags` gating and
  wouldn't have caught this.
- **Failing the Chapter 2 "read the crowd for an informant" Wisdom check
  landed the player on the *aftermath* text for a plague-hound fight they
  never actually had.** `failNextId` jumps straight to a node, skipping
  combat entirely — so the old target (`2015_hound`, the hardest fight at
  that hub) played as pure narration of a win that never happened. Added a
  proper failure node (`2015_informant_caught`) with its own light,
  appropriately-scaled consequence (a real `street_bandit` fight).
- Reworded node `2030`'s arrival text at Vane's, which assumed "whatever
  I'd brought him" — a real mismatch for the newer branches (Kelda, Sable,
  Tern Row) where nothing was physically brought. Now frames it as Vane
  having heard about the player's evening generally, which fits every
  incoming path.

### Changed
- **Moved the Chapter 1 market's first shop access to node `891`**, the
  single node every Chapter 1 branch (Surrender or Unfurl the Bundle)
  passes through immediately before the boss fight — previously it only
  lived at node `151`, an optional detour skippable outright by two of the
  three choices at the node before it, so a real playthrough had no
  guarantee of ever seeing a shop before Chapter 1's climax. Also added an
  explicit heal choice at the same node, so a player who took the harsher
  Surrender branch (which stacks two unhealed fights) isn't forced into
  the boss below full health while the Bundle branch always was.

## [1.84.0+112]

Added narrative/world content: a new dockside location and side quest
giving real presence to a population the story had only ever mentioned in
passing.

### Added
- **Tern Row, a new Chapter 2 location, and its side quest "Tern's
  Toll."** `Liora's Watch` has always referenced smuggler-run "refugee
  boats," but the refugees themselves never appeared as people — Tern Row
  fixes that: a quarter of the Tide-Kin, seafaring refugees from the
  Drowned Isles, with their own funerary custom of setting lit paper boats
  adrift at dusk. Reached via a new choice on the harbor hub (node
  `2015`), the quarter's organizer, Nadira, explains that an Inquisition
  customs officer (Overseer Renn, a new `dock_overseer` enemy) is
  extorting the quarter with an invented "landing toll" and threats of
  deportation. Players can talk him down with a DC 13 Charisma check for a
  no-combat resolution (20 gold, +5 alignment, its own flag), or refuse
  and fight him directly, which registers the formal quest
  (`q_ch2_terns_toll`, 40 gold/45 XP/+5 alignment on completion). Either
  way, failing the talk-down still leads to the fight rather than a dead
  end.

## [1.83.0+111]

Follow-up to a question about whether an NPC could actually mislead or trap
the player: it turned out the narrative engine already had every piece
needed (ability checks, `triggerEnemyId`, branching), but no NPC in the
story graph actually used them that way. Added a real example.

### Added
- **The Chapter 2 harbor informant (node `2015_informant`) can now genuinely
  set you up.** Trusting him outright — or trying to see through him and
  failing a DC 12 Wisdom check — routes into a new node
  (`2015_informant_trap`) where his "associates" spring an ambush
  (`street_bandit`) the moment you go looking for the warden he named.
  Catching the lie on a successful Wisdom check instead routes to
  `2015_informant_exposed`: no fight, and he pays out 15 gold for your
  discretion. The quest (`q_ch2_informants_tip`) still unlocks either way —
  only whether you walk into the ambush changes.

## [1.82.0+110]

Correction to the previous entry: "Slum Thug — cleared, not the culprit" was
only true for the diagnostic's own hand-rolled combat loop, which always
modeled a properly created character. It never actually exercised the real
in-app autoplay tools those bosses were investigated with, and a real
in-app **Play to Chapter** run hit exactly the "stuck against slum_thug"
failure the earlier investigation had ruled out — caught from a player's own
screenshot of that failure.

### Fixed
- **Autoplay (`Play to Chapter` and the map's node/chapter jump) lost every
  single fight when starting from a brand-new game, reporting "stuck"
  against whichever enemy happened to be first on the path — Slum Thug in
  the reported case, but any enemy would have triggered it.** Root cause:
  `autoplayToNode`/`autoplayToChapter` (`lib/data/autoplay_engine.dart`)
  walked straight through the story's character-creation choice (node 0's
  "Choose who you are...") like any other choice, without ever calling
  `PlayerSessionNotifier.startNewGame(...)` — unlike the real story player
  screen, which special-cases that choice. The simulated session was left
  with no race, profession, or equipped die, so `_simulateFight`'s die-face
  lookup came back empty and every combat auto-lost, exhausting all retries
  against the first fight on the walked path. Fixed by handling
  `StoryChoice.opensCharacterCreation` the same way the real player flow
  does: autoplay now picks a random race/profession and starts a real game
  the moment it walks through that choice, mirroring the "Randomize"
  convenience already on the race/profession picker. Added a regression
  test (`test/autoplay_engine_test.dart`) that drives a real
  `autoplayToChapter` run from a fresh session and asserts it doesn't get
  stuck on its first fight.

## [1.81.0+109]

Investigated a "speedrun" playthrough to see how far the fastest route
through the story could actually get, which surfaced a real problem: three
late-game bosses were effectively unwinnable for a normal (non-optimal,
non-party-boosted) character, hard-blocking the story at three separate
points. Diagnosed with a proper simulation (30 full playthroughs, real
combat resolution, correctly modeling that a lost story fight blocks
progress and must be retried) rather than guesswork — also used the same
diagnostic to check an unrelated report that Slum Thug was blocking
progress, and cleared it: 33 encounters, 100% first-attempt win rate,
not the culprit.

### Fixed
- **Inquisition High Warden (Ch3), Hollow Court Zealot (Ch4), and Void
  Manifestation (Ch5, the climax) were near-unwinnable walls.** The
  diagnostic simulation showed a normal playthrough needed an average of
  93, 176, and **249** retry attempts respectively to clear these three —
  Void Manifestation regularly hit the 300-attempt cap outright (a genuine
  soft-lock). Root cause: `scaledMaxHealth`/`scaledDamage` scale *every*
  enemy's stats up with player level, but these three had such a high base
  that the scaling compounded faster than a character's own (linear,
  stat-point-driven) growth could keep pace — checked directly, win rate
  against Void Manifestation barely moved between level 3 and level 10
  (0% → 7%), so grinding wasn't a real way past it either.
  Reduced each boss's base stats (found via a win-rate search targeting
  ~30-50% for a solo, unassisted character at the level a normal
  playthrough actually reaches them):
  - Inquisition High Warden: 200hp/23dmg → 150hp/17dmg (~47% win rate at
    level 3)
  - Hollow Court Zealot: 218hp/25dmg → 142hp/16dmg (~34% win rate at
    level 4)
  - Void Manifestation: 236hp/27dmg → 154hp/18dmg (~30% win rate at
    level 4, matching this fight's original "tough but fair" design
    intent) — and critically, this win rate now actually **rises with
    level** (~30% → 40% → 64% → 75% from level 4 to 8), so a player who
    grinds a bit more before attempting the climax is meaningfully
    rewarded for it, instead of hitting a wall that doesn't move no
    matter how strong they get.

Added `test/boss_balance_test.dart`, a permanent regression test asserting
each boss's win rate stays in a healthy band (catches both a regression
back toward the old unwinnable stats and an over-correction that makes the
fight trivial), and confirming Void Manifestation's win rate keeps rising
with level.

## [1.80.0+108]

Balanced difficulty across the early chapters so Chapter 1 reads as the
safe tutorial it's meant to be, and Chapter 2's roguelike expeditions are
where real death risk actually starts — before the escalation continues
into Chapter 3 and beyond.

### Fixed
- **Expeditions could roll any enemy in the game, with zero chapter
  gating.** `ExpeditionScreen._rollEvent` built its enemy pool from every
  entry in `enemies.json`, filtering only by "already fought" — unlike
  regular excursions, it never checked `minChapter`. A Chapter 2
  expedition (a level ~2 character) could randomly draw a Chapter 5
  endgame monster (236hp/27dmg) with no way to decline the fight and no
  way to win it. Extracted the excursion engine's existing chapter-gate
  logic into a new shared `SubNodeEngine.filterEnemyPool`, used by both
  excursions and expeditions now, so a zone's encounters are always
  capped to enemies that chapter's story has actually introduced.
- **Rat Matriarch and Inquisitor Kroll could ambush a brand-new
  character.** Both are scripted Chapter 1 story bosses fought near the
  chapter's end (nodes 850/855 and 955, right before the Chapter 1
  finale) — strong enough to be a real threat at that point — but were
  flagged `minChapter: 1`, making them eligible for a *random* Chapter 1
  excursion from the very first node. Bumped both to `minChapter: 2`:
  their scripted story fights are unaffected (main-path encounters never
  consult `minChapter`), but they can no longer ambush an early Chapter 1
  run, and they now also fold into Chapter 2's random pool — one more
  reason expeditions there feel noticeably more dangerous than the
  tutorial chapter that came before them.

Net effect: Chapter 1's random encounters are now capped at Inquisition
Warden (80hp/12dmg) — safe, teaches the mechanics, essentially unlosable
for a fresh character. Chapter 2's pool tops out around Plague Hound
(146hp/17dmg) and the now-included Kroll/Rat Matriarch (145/120hp,
18/15dmg) — a real chance of going down in an expedition's three-encounter
run, especially back-to-back with no healing between fights, exactly
where the "start to die a little" ramp should begin.

Added `test/sub_node_engine_test.dart` covering the shared chapter gate,
including the exact regression (a chapter-2 pool never contains a
chapter-5 enemy).

## [1.79.0+107]

Reworked the skill system to play like a roguelike build each run: skills
now level up in place, two skills can be fused into a new one, and dying
wipes the build back to class basics so every life is its own experiment.

### Added
- **Skill tiers** — any unlocked skill can be upgraded up to 3 times,
  each tier adding +25% to its damage/heal numbers and +0.1 to its damage
  multiplier (`combat_engine.dart`'s new `applySkillTier`). Upgrades are
  applied live at combat-resolution time from a per-player tier map, never
  by mutating the shared skills database (enemies read from that same
  table via their own skill references).
- **Skill Essence** — a new resource earned 1:1 alongside XP from combat
  wins and quest completions, spent to buy tiers (rising cost: 3/6/9
  essence per tier). Shown next to Skill Points at the top of the Skills
  screen.
- **Merging skills** — a new "Craft a Skill" button on the Skills screen
  opens a recipe list (`assets/gamedata/skill_merges.json`) of two-skill
  fusions; picking a ready recipe consumes both input skills and unlocks a
  new, more powerful hybrid in their place. Six recipes ship with this
  release: Blazing Shadow, Unbreakable Will, Bastion of Stone, Arcane
  Convergence, Venomous Ambush, and Wrath of Dawn — each crafted from two
  existing race/profession or starter skills.
- **Skills reset on death** — permadeath now wipes the skill build back to
  exactly what a fresh character would have (the race and profession's
  own standard skill, wired onto the starter die), clearing every other
  unlocked skill, all tier progress, and skill essence, and refunding
  skill points back to the profession's starting amount. Level, gold,
  stats, owned dice, and story progress are untouched — only the skill
  build itself restarts, so each life is a genuinely new roguelike run.
  The death screen now shows how many skills were lost in the reset.

## [1.78.0+106]

The Level Up popup was unreadable on narrow phone screens — stat labels like
"Damage" and "Armor" were being split mid-word ("Dam"/"age", "Armo"/"r")
because the dialog's default insets plus a wide leading icon and trailing
button left almost no room for the label text. Also adds tap-to-learn stat
descriptions, previously only implicitly understood from context.

### Fixed
- **Level Up modal readability on mobile** — rebuilt each stat row's layout
  in `level_up_dialog.dart` with a tighter, width-budgeted `Row`
  (smaller icon avatar, single-line label, compact `+1 Point` button) and
  added explicit `insetPadding`/`contentPadding` overrides to the
  `AlertDialog`, so labels render on one line instead of wrapping mid-word
  on narrow viewports. Verified numerically via a widget test measuring
  rendered text height at 412px and 360px simulated screen widths.

### Added
- **Stat descriptions on tap** — tapping a stat's icon on either the Level
  Up modal or the full-screen Level Up tab now opens a short description of
  what that stat actually does in-game (e.g. Luck improves post-fight loot
  odds, Strength/Dexterity/Constitution/Intelligence/Wisdom back their
  respective story-choice ability checks, Charisma opens persuasion-gated
  dialogue), reusing the existing `showDetailDialog` helper. All ten
  descriptions are localized in English and French.

## [1.77.0+105]

Three new recruitable companions, each gated behind a different kind of
requirement — so which allies a playthrough can actually reach depends on
the build and the choices that got it there, not just on finding the right
hub node.

### Added
- **Liora** (Elf Ranger) — a wary rooftop archer at the Chapter 2 harbor
  hub (node `2010`), who only comes down if you can talk your way past her
  (`reqCharisma: 3`). Signature die: `liora_die` (aimed shots, evasive
  steps, `ranger_aimed_shot`/`ranger_beast_bond`).
- **Vess** (Voidkin Mage) — a fellow void-marked stranger at the Chapter 1
  market hub (node `151`), reachable only by players carrying the
  `void_marked` flag from a failed Luck check at the Tear (node `280`) —
  a direct consequence chain from an earlier round's content, not a new
  gate type in isolation. Signature die: `vess_die` (void/arcane, `mage_arcane_missile`,
  `voidkin_umbral_veil`/`voidkin_entropy_touch`).
- **Grosh** (Orc Warrior) — a mercenary at the Chapter 3 Ashen Quarter hub
  (node `3005`) who only takes clients who look like they can pay
  (`reqGold: 80`). Signature die: `grosh_die` (`orc_berserk_rage`,
  `warrior_shield_bash`).

  Each ships with its own recruit quest (`q_ch2_lioras_watch`,
  `q_ch1_vess_in_the_dark`, `q_ch3_groshs_price`) and bridge node, following
  the exact pattern Kelda/Sable/Maren established — no new mechanics, just
  new data reusing `reqCharisma`/`reqFlags`/`reqGold` node gating and the
  existing companion/signature-die/recruit-quest schema.

## [1.76.0+104]

Five new build-specific interactions and a new quest, so every one of the
six core stats (plus Luck) now has at least one real moment where it
changes what happens — reinforcing that a playthrough's build determines
what it can actually do, not just how hard it hits in combat.

### Added
- **Five new ability checks**, each exercising a stat that had no story
  moment of its own yet:
  - **Luck** — the Chapter 1 "Touch the Tear" choice was flavor-text only
    (labeled "Luck Check" but never actually rolled); it now rolls for
    real (DC 10), with a new failure scene (`281_scarred`) for a bad roll.
  - **Strength** (DC 13, Chapter 2 harbor) — force a jammed loading crane
    open for bonus gold, or fail and draw Vane's crossbow.
  - **Constitution** (DC 12, Chapter 1 market) — push through a
    smoke-choked forge to find a stashed cache.
  - **Wisdom** (DC 13, Chapter 2 harbor market) — read the crowd for an
    informant, unlocking the new quest below; fail and a plague hound
    notices you instead.
  - **Intelligence** (DC 13, Chapter 3 Ashen Quarter) — decipher scorched
    ledger fragments outside the archive for bonus gold and a flag; fail
    and a cultist acolyte notices you rifling through their things.

  `ability_check.dart`'s `abilityScoreKeys` now includes `luck` alongside
  the six D&D-style stats, reusing the exact same roll/DC/`failNextId`
  machinery already proven out by the Dexterity check from last round —
  every failure route reuses an existing sibling node instead of adding
  new dead ends.
- **New quest: The Informant's Tip** (`q_ch2_informants_tip`) — unlocked by
  the Wisdom check above, a bounty on a corrupt warden skimming smuggled
  goods.

## [1.75.1+103]

### Fixed
- **Story Map panning.** Removed the Edit Mode "Jump to Chapter" panel,
  which sat over the top-right corner of the map and silently swallowed
  any drag gesture that started on it — the likely cause of the map
  feeling unscrollable in that area. The map's `InteractiveViewer` always
  supported free pan/zoom in every direction; with the panel gone, nothing
  on screen blocks it anymore. (Jumping to a chapter is still available
  from the map by tapping a node and using "Jump to this node".)

## [1.75.0+102]

Sharper item/quest icons, and the first choices whose consequences reach past
their own scene: which companions you can recruit, and which skills you can
learn, now depend on who you've been so far.

### Added
- **Choice-driven build divergence.** Recruiting Kelda (the dwarf
  shieldbearer) now requires an alignment score of at least 2; recruiting
  Sable (the rogue) requires -2 or lower; recruiting Sister Maren requires
  having saved Lysa back in Chapter 1 (`lysa_survived`). All three use the
  existing node-level `reqAlignmentScore`/`reqAlignmentMax`/`reqFlags` gates,
  each with its own in-voice locked reason instead of a generic message. Two
  new signature skills, `zealous_conviction` (alignment ≥ 3) and
  `ruthless_edge` (alignment ≤ -3), extend the same idea to skills via new
  `requiredAlignmentMin`/`requiredAlignmentMax` fields on the skill schema,
  shown in the Skills screen as "Reserved: Good-aligned"/"Evil-aligned"
  alongside the existing race/profession restriction. The point: who you
  recruit and what you can learn is no longer available to every
  playthrough — it's shaped by the choices you already made.

### Changed
- **Item and quest icons are sharper.** Weapon items now render a
  sword/dagger/spear/staff/shield-specific icon instead of one generic
  glyph for the whole "Weapon" category (`itemIcon`), and quests render an
  icon for what their first objective actually asks — a fight, a fetch, or
  a conversation — instead of just their Main/Side category
  (`questIcon`), across Inventory, Shops, and the Quests tab.

## [1.74.0+101]

A D&D/Baldur's Gate 3-style ability check system: five new stats and a
dice-roll "attempt" mechanic for story choices, layered alongside last
round's flat Charisma gate rather than replacing it.

### Added
- **Strength, Dexterity, Constitution, Intelligence, and Wisdom** join
  Luck and Charisma as full character stats — derived at creation from
  `game_config.json` + race/profession bonuses (e.g. Dwarves run high
  Constitution, Mages run high Intelligence, Rogues run high Dexterity),
  spendable from the level-up dialog/screen, and editable from the debug
  stats panel like every other stat.
- **Ability checks on story choices.** `StoryChoice` gained
  `checkAbility`/`checkDC`/`failNextId`: tapping a checked choice rolls a
  d20 plus the matching stat against the DC (`lib/data/ability_check.dart`)
  and shows the roll in a themed popup before anything else happens — the
  BG3 "attempt" pattern, distinct from `reqCharisma`'s hard, deterministic
  gate. Success applies the choice's effects as normal; failure either
  routes to `failNextId` when the author set one, or continues to the same
  destination without the reward. Authorable from the Story Node Editor's
  choice panel, and the graph-integrity checker now walks `failNextId` too,
  so a check-only branch is neither flagged orphaned nor left unvalidated.
  Wired into a new optional choice at the Ashen Quarter hub (a Dexterity
  check to pick a sealed archive's lock) as a worked example.

## [1.73.0+100]

A round of new-mechanics requests: a proper celebration for leveling up,
two new stats with real gameplay teeth, and NPCs the player can actually
talk to.

### Added
- **Colored level-up dialog.** The plain gray "Level Up!" alert is now a
  gold-gradient trophy icon with a soft glow, a gold title, and each
  spendable stat given its own themed color (red damage, blue armor, pink
  health, purple luck, teal charisma) instead of identical gray rows.
- **Luck and Charisma stats.** Derived at character creation the same way
  as every other stat (`game_config.json` base + race bonus + profession
  bonus — e.g. Rogues run high luck, Clerics and Humans run high
  charisma), spendable from the level-up dialog/screen alongside Damage,
  Armor, and Health.
  - **Luck** boosts the drop-rate roll on combat loot directly (in
    percentage points), so a lucky character sees noticeably better item
    drops.
  - **Charisma** gates story content: `StoryNode` gained a `reqCharisma`
    requirement (checked in `PlayerSession.meetsRequirements` alongside
    the existing reqGold/reqAlignment/reqFlags), authorable from the
    Story Node Editor like every other requirement, for
    persuasion-flavored choices a low-charisma character can't take.
- **NPCs you can talk to.** A new `npcs.json`/`npcsSchema` (three NPCs to
  start: a returning companion from the opening chapter, and two flavor
  encounters), surfaced as a new NPCs section in the Play tab —
  flag-gated the same way node requirements already are, so an NPC can be
  tied to a story event before they're discoverable. Tapping one opens a
  simple conversation screen (description + a few flavor lines) with a
  Talk button that records the conversation
  (`PlayerSession.talkedToNpcIds`). Quests' existing `Talk`-type
  objectives (previously always auto-met, with nothing to actually check)
  now gate on a new `targetNPCID` field against that record when one is
  set — wired end-to-end for one real quest (`q_ch3_alsters_dawn`) as a
  worked example, with older/other Talk objectives left ungated exactly
  as before if they don't specify a target NPC.

## [1.72.0+99]

Follow-up to the last round of live-device feedback: relocate a
half-discoverable feature, make character creation faster to start, and
make quest completion actually mean something.

### Changed
- **"Play to Chapter" moved from the Story Map to Settings → Simulate a
  Playthrough.** The strategy-driven chapter autoplay added last round sat
  awkwardly on the Map's node-jump picker; it now lives alongside the
  batch-simulation controls it's a natural sibling of, sharing the same
  strategy selector. Still lands the player back in live Story view with a
  real, earned session once the target chapter is reached.

### Added
- **Randomize button on the Race & Profession screen.** Picks a random race
  and profession in one tap, next to the existing random-name die — for
  players who just want to jump in without reading five race/profession
  cards first.
- **Real quest objective tracking.** `quests.json`'s `objectives` field
  (previously unread by any gameplay code) is now enforced: a quest's
  Complete button stays disabled until its Kill objectives (tracked via a
  new lifetime `PlayerSession.enemyKillCounts`, bumped on every combat win)
  and Fetch objectives (checked against current inventory) are satisfied.
  The active quest card shows each objective as its own checklist line,
  which doubles as sub-quest tracking for any quest with more than one
  objective — no new "quest group" concept was needed, since a multi-part
  quest is just a quest with multiple `objectives` entries. Talk objectives
  are left ungated (no reliable signal exists yet to detect them). Existing
  saves with quests already active before this change are grandfathered so
  they're never stuck unable to complete.

## [1.71.0+98]

Live-device UX feedback from actually playing the app: the story map's
overlapping panels, a genuinely useful "simulate up to a chapter" feature
that turned out to be half-built, and a fullscreen-reading toggle that
fired but was too subtle to notice.

### Fixed
- Story Map: the Legend panel and the "Jump to Chapter" panel both sat at
  the top of the screen, overlapping on narrower viewports. Legend now
  anchors to the bottom-left instead.
- Double-tapping the story text to enter distraction-free fullscreen
  reading worked, but the narration card stayed pinned at its normal small
  size with the freed-up space left as dead blank area below it — easy to
  read as "nothing happened." It now fills and centers in the available
  viewport height.

### Added
- `autoplayToChapter`: a strategy-driven counterpart to the existing
  shortest-path `autoplayToNode` — walks real choices forward from the
  player's current position toward a target chapter, favoring good/evil/
  gold (or random) at each branch, applying every step's true effects
  (gold, alignment, flags, shop/quest unlocks, real simulated combat) via
  the same session methods a live choice tap uses. Wired into the Story
  Map's "Autoplay to chapter" picker alongside a strategy selector, so
  picking a chapter now plays a real, strategy-flavored path there instead
  of always taking the single shortest route — and lands the player back
  in live Story view afterward, ready to keep going manually with a real
  earned session. This is the "simulate up to a chapter, then take over"
  capability `firstNodeIdForChapter`'s doc comment had anticipated but
  never actually existed.

## [1.70.0+97]

The remaining CI/polish loose ends from the last review round.

### Added
- **A one-time nudge toward In-Game Mode.** Every fresh install defaults to Edit Mode (the full authoring app) since that's what this project's own development relies on — flipping that default would work against the developer's own daily workflow, so it stays. Instead, a dismissible banner on the Play tab now points a genuine first-time player at the Settings toggle, shown once until dismissed either by switching or by closing it outright.
- **`docs/quest-progress-tracking.md`** — a scoping writeup (not an implementation) for enforcing quest objectives for real, grounding the plan in the `objectives` schema that already exists in `quests.json` but was never read anywhere in gameplay code.
- **`.github/workflows/format.yml`** — a manual (`workflow_dispatch`-only) way to actually apply `dart format` via CI's Flutter install, since this dev environment has no local Dart SDK to run it directly.

### Changed
- **The codebase is now actually `dart format`-clean** (71 files reformatted via the new workflow) and **the CI format check is a real gate** — dropped the `continue-on-error` that was only ever meant to be temporary, pending a pass that confirmed the repo was clean.

## [1.69.0+96]

Fixes from a 40-run simulated-playthrough analysis (built as an accurate Python port of the real combat/quest/achievement logic, cross-checked against `test/combat_engine_test.dart`'s hand-verified values). 3 confirmed bugs fixed, 2 of 3 balance findings addressed; the third needs a product decision rather than a code fix (see below).

### Fixed
- **A level-1 character could roll an unwinnable fight in the very first random encounter.** `SubNodeEngine`'s procedural "excursion" encounters drew from the *entire* enemy roster with no level/chapter filter, so a chapter-1 side-fight could occasionally draw a chapter-4/5-tier monster (230 HP / 27 dmg vs. a fresh character) — unwinnable, with no way to decline or route around it. Traced in simulation to every one of 12/300 permanently-stuck sample runs. Every `enemies.json` entry now carries a `minChapter` (derived from where the main story itself first uses that enemy), and excursions only draw from enemies already at-or-below the current chapter.
- **Quest `alignmentChange` was defined in data but never applied.** `completeQuest()` had no alignment parameter at all, so `quests.json`'s `alignmentChange` field (set on several quests, including the near-mandatory banner quest) was silently dropped every time — quietly denying players alignment the content was designed to grant, on a game that gates real story branches on alignment thresholds. Now threaded through from the quest record into the same `alignmentScore` update `applyChoiceEffects` already uses for choice-driven alignment.
- **A completed quest could be re-offered by a later excursion.** The excursion quest pool excluded `unlockedQuestIds`, but a quest reached via `questIDToProgress` (rather than `unlockQuestId`) never lands in that list — so `q_first_blood` specifically could resurface after completion. The pool now also excludes `completedQuestIds`.

### Changed
- **Companion co-recruitment is more reliable.** Kelda and Sable are offered as a single, mutually-exclusive, non-revisitable pick at node 2015 (by design — every other recruitment/vignette hub in this story works the same way), so getting both in one run depended entirely on a later excursion randomly re-offering the one not picked, at roughly a 1-in-N chance against the whole side-quest pool. Excursions now prioritize an eligible companion-recruit quest over an ordinary side quest whenever one is available, without changing the main-path structure.
- **Unspent stat/skill points now show a badge on the Character card** (matching the existing unseen-quest/shop/enemy badge style) — spending them is entirely manual and nothing else calls attention to it; a full-game simulation with points never spent saw Chapter 4-5 win rates roughly halve.

### Investigated, not changed
- **Quest "objectives" (kill X, fetch Y) aren't enforced — completion is gated on nothing**, so reward chains resolve the instant they unlock regardless of whether the described events happened. This inflates the in-game economy (~30% of average simulated end-game gold is quest rewards) but may be an intentional lightweight quest-log design rather than a bug. Actually enforcing objectives would mean building real progress-tracking (kill counts, item possession, flag state) per quest — a new feature, not a fix — so left alone pending a product decision.

## [1.68.0+95]

The remaining two of five requested UX improvements, scoped after a clarifying round: a real-state "autoplay ahead" testing tool, and closing the Camp Rest gap.

### Added
- **Autoplay to a node or chapter (Edit Mode).** `lib/data/autoplay_engine.dart` finds the shortest forward path through the story graph to a target node, then walks it applying every choice's real effects (gold/alignment/heal/flags/quest-progress, shop/quest unlocks, achievement checks) through the exact same `PlayerSessionNotifier` methods a live choice tap calls — including a genuine simulated combat (the same `combat_engine.dart` functions and scaling a real fight uses, retried a bounded number of times on a loss) for any triggered fight, so the state you land in is a real earned one, not a fabricated snapshot. Reachable from the map: "Autoplay to this node" in a node's detail sheet, and "Autoplay to chapter…" next to the existing Jump-to-Chapter chips. Both Edit-Mode-only, like the quick-preview jump they sit beside. Deliberately skips procedural excursions and ignores active allies in the simulated fight — a testing tool, not a faithful full replay.
- **Rest at the Town Hub, not just Camp.** Town Hub gets its own "Rest" action (same `healPartyToFull()`), since a town is as much a safe haven as camp.

### Fixed
- **Camp Rest is now blocked while a fight or expedition is in progress** (`expedition_active_provider.dart`, mirroring the existing `combat_active_provider.dart`), applied to both Camp's and Town Hub's Rest buttons. Mostly a defensive check today — both already cover the bottom nav with their own full-screen route — but closes the gap for good.

## [1.67.0+94]

Three of five requested UX improvements (the other two — a "simulate ahead to a node/chapter" testing tool, and precisely scoping where Camp's Rest action should be allowed — need a design decision first and are being scoped separately).

### Added
- **Autosave for story position.** `PlayerSession` (stats, inventory, quests) has always auto-persisted continuously, but the *story position* (`StoryPlayNotifier`'s current node + history) only ever lived in memory — closing and reopening the app silently reset the narration back to the very first node while every stat/item earned since stayed intact. It's now autosaved on every real position change, to its own slot separate from the existing manual Save/Load checkpoint, and restored on launch. A restart (permadeath, or the Edit Mode reset) correctly clears it too, and an autosave pointing at a since-deleted node still degrades to the existing "trail went cold" recovery screen rather than crashing.
- **Double-tap the story text for a distraction-free fullscreen read.** Hides the status bar, header row, walking companion, and choices, leaving just the narration; double-tap again to bring them back.

### Changed
- **Story map readability.** Node labels were unbounded-width text, so a long id (e.g. `2015_dockside`) could render wider than its column and visually overlap the next one — now fixed-width and ellipsized. Same-depth nodes were ordered alphabetically with no regard for which column their edges actually connected to, producing heavy crossing clutter in fan-out/fan-in clusters like the Chapter 3 companion-quest diamond; they're now ordered by a barycenter heuristic (each node sorted near the average row of its already-placed predecessors), which measurably cuts down edge-crossing on the real story graph. Column and row spacing widened slightly to match.

## [1.66.0+93]

Two regressions found by a fresh functional review of the companion/camp system (spawned as three parallel reviews covering combat/camp, Town Hub/expeditions/achievements, and map/UI/origin-story features — the latter two found no bugs).

### Fixed
- **A winning fight that leveled the player up would immediately undo that level-up's full heal for every active ally.** `applyCombatResult` already full-heals and grants skill points to every recruited ally when its XP gain crosses a level threshold, but `FightScreen._finishFight`'s very next loop unconditionally wrote each ally's stale, pre-level-up battle-end HP over that heal (and revived a knocked-out ally against their *old*, lower max health instead of the new one). That per-ally write is now skipped whenever the fight's win also leveled the player up.
- **A companion's one customizable die face was permanently stuck on `heavy_attack`.** `InventoryScreen` and `SkillsScreen` were parameterized by `allyId` when the companion/camp system landed, but `DiceLoadoutScreen` never was — so there was no UI path to ever reassign a companion's single open Skill-die face, making their skill-point/unlock progression's actual combat payoff unreachable. `DiceLoadoutScreen` now takes an optional `allyId` (mirroring the other two screens: no die-switcher, since an ally only ever has their one fixed signature die) and Camp's roster cards got a third "Dice Loadout" button to reach it.

## [1.65.0+92]

CI/build pipeline and test-coverage improvements, from a review of the setup itself rather than the game.

### Added
- **Real unit tests for game logic, for the first time.** `test/combat_engine_test.dart` covers dice rolling, player/enemy move resolution (Attack/Defend/Heal/Skill faces, Always/Chance/OnLowHealth enemy conditions, priority ordering including the "a match consumes the turn even if its skill doesn't resolve" edge case), and the three level-scaling formulas. `test/player_session_provider_test.dart` covers `completeQuest` (gold/XP/item rewards, leveling up, banner-piece de-dup), `completeZone` (rewards, one-time payout), `applyCombatResult` (rewards, leveling, HP clamping), `recruitAlly` (starter skills, no duplicate recruits), and `checkAchievements` (including a regression test pinning `full_party` at exactly 2 active allies — the threshold bug fixed a few versions back). Every one of this session's real balance bugs was previously only ever caught by a hand-written Python simulation run manually, outside CI; this is the start of closing that gap for real.
- `.github/dependabot.yml` — weekly update PRs for pub packages and GitHub Actions, so "N packages have newer versions" is an actual PR to review instead of a CI log line nobody acts on.

### Changed
- **CI workflow (`build_apk.yml`)**: added `concurrency` with `cancel-in-progress` so a branch that gets several quick follow-up pushes stops burning minutes on runs whose result is already superseded; enabled `subosito/flutter-action`'s built-in SDK+pub caching (was off) and added a Gradle cache, both aimed at the 7-9 minute build-APK step being the slowest thing in every run; bumped `actions/setup-java` from the now-deprecated v3 to v5; added a `dart format --set-exit-if-changed` check (non-blocking for now — the repo's formatting hasn't been verified clean without a local Dart SDK to check first); tightened the workflow-level permissions default from `contents: write` to `read`, with `build` granting itself `write` explicitly for its own release step.

### Investigated, no change needed
- `flutter_tts` (the package CI warns applies the Kotlin Gradle Plugin directly) is already pinned to its latest published release, 4.2.5 — there's no newer version to bump to yet. Dependabot will now surface one automatically whenever the maintainers ship a fix.

## [1.64.0+91]

### Added
- **Profession-flavored origin story.** The "beggar's plea" childhood prompt (one of the five formative-memory beats shown at character creation) now has a variant per profession instead of one generic version for everyone: Warrior (a wounded veteran's ration), Mage (a hedge-mage's warming charm), Cleric (a pilgrim's offering coin), Ranger (a trapper's dried meat) each get a small reskin of the same beat; Rogue gets a genuinely different scenario — a rigged card game, warn the mark or run it as rigged. New `originPromptForSlot()` picks the right variant for the player's chosen profession, falling back to the original generic prompt for any profession without one.

## [1.63.0+90]

### Changed
- **Narrative text throughout the app now reads like prose, not a form field.** The childhood/teenage origin-story dialog (shown once at character creation), the Quests tab's quest cards, and the shared item/skill/quest detail popup all now render their descriptive text with a serif typeface, 1.55-1.6 line height, and slight letter-spacing — the same readability treatment the story reader itself got earlier this session. The Quests tab's cards were also rebuilt from a cramped 3-line-max `ListTile` (which truncated longer dialogue) into a proper card layout that shows the full text.
- **Added a "Jump to Chapter" panel to the Map screen.** A row of chapter chips (Prologue through the current content's last chapter) in the top-right corner jumps straight to that chapter's opening beat, reusing the same `jumpTo` the map's existing (undiscoverable) per-node double-tap already used — now there's a visible way to skip ahead and pick up a playthrough from a specific chapter without replaying from the start.

## [1.62.0+89]

Phases 2 and 3 of the roguelike redesign (see the design doc's Phase 1 entry below for background). Both delivered without touching the story graph's existing routing — Phase 3 in particular turned out to need far less new content than expected, since its two "banner piece" payoffs were already fully built and just needed tagging.

### Added
- **Town Hub now has all 3 of Chapter 2's tutorial zones.** New zone: Lantern Docks — rewards a narrative lead (a flag, not an item) on where the Shroud's second piece went, rather than gold or an item, giving zones their first non-material reward type.
- **Banner-piece tracking.** `PlayerSession.bannerPiecesCollected` (new field) tracks recovered pieces of the Shroud — the "heirloom cut into pieces" mechanic from this session's design doc. A quest's new `grantsBannerPieceId` field (mirrors the existing `rewardAllyId` pattern) tags a piece on completion; a zone's new `rewardFlag` field (mirrors a quest's `flagToAdd`) grants a plain narrative flag instead of gold/item/dice/ally, for zone rewards that are leads rather than loot.
- Both of Chapter 1 and Chapter 3's **existing** quests already delivered on the brief's "expedition to get the map to the second part" / "go get the flag" beats without any new content: `q_retrieve_banner` (Ch1, "The Heirloom of Alster" — literally the heirloom pickup) now tags the first piece; `q_ch3_alsters_dawn` (Ch3, the payoff of the already-wired `q_ch3_void_relic → q_ch3_the_high_wardens_fall → q_ch3_alsters_dawn` chain reachable from node `3005`) now tags the second. Character screen shows collected pieces when there are any.

### Not in this slice
The existing Chapter 2 harbor (`2015`) and Chapter 3 Ashen Quarter (`3005`) hub nodes were deliberately **not** restructured into the expedition/zone frame — turning an authored, one-shot story choice into a repeatable zone is a real engine change, distinct from adding parallel zone content, and risks the narrative-audit fixes from a few versions back. The new zones wrap around this content rather than replacing it, per the design doc's central recommendation. The boat (Phase 4) and Chapters 4-7's content (Phase 5) are still ahead.

## [1.61.0+88]

The first build slice of a larger roguelike redesign discussed and written up as a design doc this session ("The Scattered Banner"): a town-and-expedition loop wrapped around the existing chapters rather than replacing them. This entry is Phase 1 only — "one zone, land only" — proving the mechanism before any existing story content is touched.

### Added
- **Town Hub screen.** A new, separate screen (`lib/screens/town_hub_screen.dart`, reachable from a new Play-tab card) distinct from Camp: a tutorial/prologue stop with a couple of already-stocked basic shops (Blind Beggar Stall, Weaponsmith's Forge — nothing to build) and a list of the current chapter's expedition zones. Camp remains the one persistent base the player builds from scratch and keeps for the rest of the game; the town hub is what they have before they have that.
- **Expeditions.** A new `zones.json` data table (2 zones added for Chapter 2: Fisherman's Row, Tanner's Court) and `ExpeditionScreen` (`lib/screens/expedition_screen.dart`) that walks a zone's fixed chain of events — each one drawn live from `SubNodeEngine`'s existing themed flavor pools (its internal node-builder was made public, `SubNodeEngine.buildNode`, rather than duplicated) so a new zone needs no per-event writing, only a data row. Fights resolve through the existing `FightScreen`/`combat_engine.dart` unchanged; shop finds push the existing `ShopDetailScreen`; treasure/rest apply through the existing `applyChoiceEffects`. Losing or fleeing a fight, or retreating voluntarily between events, ends the run — everything already gained that run (gold, items, XP from any won fight) is kept, but the zone's own banked completion reward is forfeit until the zone is cleared in one run. `PlayerSession.completedZoneIds` (new field) tracks cleared zones permanently, mirroring `completedQuestIds`.

### Not in this slice
Re-plumbing Chapters 2-3's *existing* content onto this frame, the boat/FTL system, and Chapters 5-7's content are later phases per the design doc — deliberately not started here.

## [1.60.0+87]

### Changed
- **The story map now lays out as a grid capped at 5 nodes per column, with each chapter as its own vertical band** ("a map in itself"), instead of an automatic Sugiyama layered-graph layout with no ceiling on how many nodes could stack in one column. New `ChapterGridAlgorithm` (`lib/screens/story_graph_screen.dart`) positions every node from a precomputed slot map (`lib/data/chapter_grid_layout.dart`): column = BFS hops from that chapter's opening beat (following only same-chapter edges), row = position within that column, split into extra columns whenever a depth level would otherwise exceed the cap. Each chapter's band is labeled and sized to its own tallest column, so a low-branching chapter doesn't waste space matching a denser one. Verified against the real 97-node graph via a Python mirror of the same algorithm before porting to Dart: every column caps at exactly 5, and all 97 nodes place correctly.
- Content-side note: the *target* node budget this map layout is meant to support — roughly 15 authored nodes per chapter (5 main beats + up to 10 side nodes) — isn't met yet by the existing chapters (currently 43/21/17/7/8 across chapters 1-5); that's a separate, larger content pass, not part of this change.

## [1.59.0+86]

### Added
- **Random name generation.** A dice-icon button next to the character-name field on the lock-in dialog fills it with a random name drawn from a race-matched pool (`lib/data/random_names.dart`, 20 names per race) — Kelda-style dwarven names for a dwarf, elvish for an elf, and so on. Purely a convenience for players who don't want to type one; the field stays freely editable either way.

## [1.58.0+85]

A full audit of the story graph's 133 choice→node transitions, requested to make sure every scene follows sensibly from the choice that leads into it — found and fixed two structural bugs and two smaller routing/wording issues. Followed by 50 simulated full playthroughs (graph walk + real combat/quest/shop/companion resolution) judging narration coverage, feature usage, item usage, and combat difficulty — which turned up a game-breaking combat bug and two economy bugs, also fixed here.

### Fixed
- **Chapter 2's harbor hub (`2015`) and Chapter 3's outer-district hub (`3005`) had no real content of their own.** All 7 choices at `2015` (visit the Arcane Bazaar, visit Apothecary Row, take the harbor master's job, fight a smuggler captain, fight a plague hound, and the two companion-recruit choices for Kelda and Sable) landed on the exact same unrelated node — a Vane bribery scene meant for a different edge entirely — with zero acknowledgment of what was actually chosen. Chapter 3's `3005` had the identical bug across all 8 of its choices (the Ashen Oath, four separate fights, the Smugglers' Vault, the Void Relic contract, and Maren's recruit choice), landing on an unrelated Hall-of-Records scene. Neither companion-recruit choice had ever had its own scene — the actual "meeting them" dialogue only ever showed up in the quest-discovery popup, never in the story itself. Added 15 new short bridge nodes (one per choice) that acknowledge the specific thing just done — winning that fight, taking that oath, hearing that companion out — before continuing on to Vane or the archives as before. Lightly reworded both shared continuation nodes (`2030`, `3020`) so they read naturally regardless of which of several very different preceding scenes led into them.
- **Node `280` (the Tear's first appearance) assumed every arrival came from the alley.** Two of its four incoming routes are from crossing the bridge instead, where the opening line "The alley opened onto a scorched square" doesn't hold. Reworded to "Whichever way I'd come, it let out onto a scorched square" — the same route-agnostic-opener trick already used for the harbor's multi-path buffer node.
- **Escaping into the canals mid-fight (node `2021`) skipped the multi-path buffer node built to handle exactly this.** It jumped straight to the Chapter 2 end-of-chapter gate with no transition from "fleeing through canal tunnels" to "standing at the threshold." Rerouted through `2900` (the existing "whatever path had brought me here" buffer), same as the harbor's other three convergent routes.
- **The Void Manifestation and Void Stalker's `void_blast` was set to fire every single turn, guaranteed.** Both enemies had this skill (a ~60-90 flat-damage hit on top of their base attack) on `condition: "Always"` at top priority, while every other enemy with access to the same skill gates it behind a 25-40% `Chance` instead. Void Manifestation guards the one and only choice at node `6003b` — a mandatory, no-alternative fight late in Chapter 5 — so this made the game **unfinishable**: a 50-playthrough simulation had a 1.1% win rate against it and 47 of 50 runs permanently stuck there, unable to progress or pick a different option. Changed both to `Chance` (30% for Void Manifestation, 35% for Void Stalker), matching the pattern already used by `inquisition_high_warden`/`hollow_court_zealot`. Re-simulated: 48 of 50 runs now reach a real ending, and Void Manifestation is a genuinely tough (34% win rate) but fair climactic fight rather than an impossible one.
- **Completing a quest never actually granted its XP reward**, despite the discovery popup and completion notice both displaying a "+N XP" figure — `completeQuest()` only ever applied gold/item/dice/ally rewards. Extracted the level-up logic `applyCombatResult()` already had into a shared `_applyXp()` helper and wired `completeQuest()` through it, so quest XP now actually levels the player (and shows the same level-up dialog combat does). This was silently starving players of a large chunk of their intended XP income — average simulated player level by the Chapter 5 climax rose from 2.6 to 3.8 once fixed.
- **The "Field a full 3-member active party" achievement required 4 people, not 3.** Its condition checked `activeAllyIds.length >= 3` (three *active allies*, i.e. the player plus three companions) instead of the two active allies that make up a 3-member party at the default party capacity — meaning it was unreachable without first building the party-capacity-boosting house, despite nothing in its name or description saying so. Changed the threshold to 2.

### Reviewed, no changes needed
- The `960` → `965`/`965_mercy`/`965_vengeance` fork and its downstream flag-gated split — tone and gating both correctly match each branch.
- The `5003_seeker`/`6001_seeker`/`6005_seeker` bearer/seeker variant pairs — correctly differentiated and flag-gated.
- Chapter 4/5 content generally.

Two more nodes (`6003b`'s "faces I had put down" retrospective, and `4999`'s "the High Inquisitor fell" line after fighting a warden rather than the Inquisitor by name) look like they might be reading a specific fight into a line meant to stay impressionistic — flagged for a possible follow-up rather than changed here, since resolving it either way is an authorial call, not a structural bug.

## [1.57.0+84]

A round of usability fixes to the companion/party feature and the QA tooling, from direct play feedback.

### Changed
- **Party combat now rolls together.** Previously each active ally took a full separate sequential turn (their own roll/reroll/confirm cycle) after the player's — with one ally that meant up to 6 rolls before the enemy acted. Now the player and every active ally roll their own die *at the same time*, shown side by side, and Reroll rerolls the whole group together under one shared budget of 3 rolls per round (not 3 per member) — so a 2-person party still only ever takes as many taps as a solo fight did. `fight_screen.dart`'s turn state collapsed accordingly: no more per-member turn cycling, just one combined roll → confirm → enemy-turn loop.
- **Story text is easier to skim.** Each node's opening sentence is now bolded (a quick "what's this scene about" hook) and quoted dialogue is italicized to stand out from narration, via a small `_highlightedSpans()` helper in `story_player_screen.dart`. Every node's text is one continuous block with no author paragraph breaks, so this highlights within that block rather than across paragraphs.
- **Removed the floating collapse/expand arrow** on the story screen's status header — it sat alone in its own row doing little but getting in the way. Tapping the header (the stats bar itself) now collapses it directly, and tapping the collapsed state's slim handle bar re-expands it; scrolling down still auto-collapses it as before.

### Added
- **Companion-quest map legend entry.** The story map previously classified every quest-unlocking node the same amber "Quest" color, including the three companion recruit quests. Those now get their own teal "Companion Quest" kind (`_NodeKind.companionQuest` in `story_graph_screen.dart`, detected via the target quest's `rewardAllyId`), togglable in the legend like every other kind.
- **Simulator recap: color + companions encountered.** The batch recap's key stats (nodes visited, gold, alignment, combat encounters) are now icon-led and colored instead of plain uncolored text. A new "Companions encountered" section shows, per companion, how many of the batch's runs discovered their recruit quest (the closest signal this graph-walk simulator has to "met this companion", since it doesn't model quest completion) — colored chips, `_companionEncounterCounts()` in `playthrough_simulator_screen.dart`.

## [1.56.0+83]

A follow-up review of the companion feature (PR #85) against quests, story, and — since it turned out not to exist yet — achievements.

### Added
- A small achievements system: `assets/gamedata/achievements.json` (new `DbSchema`, like every other data table) and a new Achievements screen (card on the Play tab), seeded with 7 milestones — 4 tied to the new companion feature (recruit your first companion, recruit all three, field a full 3-member active party, build Kelda's Hall specifically) and 3 general ones (win a fight after reviving a knocked-out ally, complete your first quest, discover your first shop). `PlayerSession` gained `unlockedAchievementIds`; a new `checkAchievements()` scans persisted state for newly-met conditions after recruiting/activating/building/completing, and `unlockAchievement()` grants one-off event achievements directly (the ally-revival case, detected in `FightScreen` itself since "was knocked out this fight" isn't state that survives past the fight).
- The story prose now briefly acknowledges having an active ally at the two biggest post-Chapter-2 combat beats (the Chapter 3 climax and the Chapter 5 finale) — previously "fighting alongside you" was never mentioned anywhere in the narration, even when the player mechanically had two companions in the fight. Deliberately generic (never names which companion, to avoid enumerating every active-party combination) and computed live off the player's current party via a small `withAllyAcknowledgment()` helper in `story_player_screen.dart`, rather than forked story nodes — simpler and more correct than a flag-gated variant, since active-party membership is state that changes at any time (via Camp), not a one-time story flag.

### Reviewed, no changes needed
- All 15 quests (12 existing + the 3 new recruit quests) — schema-consistent, no name collisions with existing NPCs, dialogue reads consistently with the game's voice, and quest difficulty/rewards are player-level-scaled rather than party-composition-scaled, so nothing there interacts with active allies.
- The rest of the story's "alone" language — all of it predates Chapter 2, before any companion can exist, so none of it contradicts the new feature.

Deliberately out of scope: acknowledging allies at every combat encounter across all 5 chapters (a much larger content project than this pass), and naming which specific companions are present in the acknowledgment lines (would need real templating support the story format doesn't have).

## [1.55.0+82]

### Added
- **Companions.** Three recruitable allies — Kelda (dwarven shieldbearer), Sable (rogue), and Sister Maren (cleric) — each earned through a new side quest (`q_ch2_keldas_stand`, `q_ch2_sables_wager` in Chapter 2, `q_ch3_marens_penance` in Chapter 3, surfaced as new optional choices on the existing Chapter 2/3 hub nodes). Recruiting is permanent for the save the moment the quest completes, regardless of whether that companion ever fights.
- **Party combat.** Up to 2 recruited allies (more with the right House, see below) can be active at once and fight alongside the player as full combatants, not a stat buff: each active ally gets their own turn in `FightScreen` with the same roll/reroll-up-to-3 dice flow the player has always had, using their own signature die (`iron_die` for Kelda, `shadow_die` for Sable, `holy_die` for Maren), their own damage/armor, and their own equipment. The enemy's own turn now picks a target at random among every conscious party member instead of always hitting the player. An ally reduced to 0 HP is knocked out (skipped for the rest of that fight, not a loss condition) and revived at 30% health on a win, or fully healed at Camp; only the player's own death still ends the fight.
- **Automatic scaling.** An ally's combat stats are derived from their race/profession (the same New-Game-Defaults-plus-bonuses formula used for the player) and scaled to the player's current level via the same functions already used to scale enemies — so recruiting someone at level 12 doesn't hand you a level-1 stat block, and every ally (and their skill points) grows automatically whenever the player levels up.
- **Ally gear and skills.** Each recruited ally has their own equipment slots and their own learnable-skill pool, restricted by their own race/profession using the exact same `restrictedRaceID`/`restrictedProfessionID` mechanism skills already had — a Voidkin spell still can't go on a Dwarf, whichever character is holding the die. Managed through the same Inventory and Skills screens the player uses, now accepting an optional `allyId` to point them at a companion instead.
- **Camp & Houses.** A new Camp screen (reachable from a new card on the Play tab) shows the recruited roster — active/benched toggle, live HP, and quick links into that companion's Inventory/Skills — plus a Houses list and a Rest action that fully heals the whole party. Houses are a new buildable, gold-spending structure: Kelda specifically requires "Kelda's Hall" to be built before she can join the active party (shown on her roster card as recruited-but-benched with a note explaining why), while the separate "Barracks Annex" simply raises active-party capacity from the default 2 to 3, independent of any one companion.

### Changed
- `PlayerSession` gained `recruitedAllies`, `activeAllyIds`, and `builtHouseIds`, following the same append-only-list and hand-written-JSON patterns already used for quests/shops/dice — no persistence restructuring needed.

Deliberately out of scope for this pass: a dedicated die-face-reassignment UI for allies (their one open "Heavy Strike" slot works, just not yet player-customizable the way `DiceLoadoutScreen` lets the player reassign their own); and wiring up `adventure_nodes.json`'s long-dormant "Rest" node category (confirmed unread anywhere in the live game already) — Camp's own Rest action delivers the "fully healed at camp" behavior without touching that unrelated, pre-existing gap.

## [1.54.0+81]

### Fixed
- Kroll — the story's Chapter 1 antagonist, described across three nodes as "my torturer" wielding a blade with "fond familiarity" — never actually had a `triggerEnemyId`, so the climactic "boss fight" at the docks was entirely narrated with no mechanical combat behind it. Added a `kroll_the_branded` enemy and wired it to the fight's starting choice.
- The Chapter 3 climax (node 4999, "The High Inquisitor fell") was reachable via two routes (bribing or subduing the archivist) with zero combat of any kind — only the third, rooftop route actually fought anyone. Both now fight the same `inquisition_high_warden` vanguard the rooftop route always has, so "The High Inquisitor fell" is earned on every path instead of being a non sequitur on two of the three.
- Node 4999's `speaker` metadata read "High Inquisitor" despite the text being third-person narrator prose, not a quote. Corrected to "Narrator".
- Node 6003b's climax specter recalled fighting "Wardens... on a bridge, in a hallway, on a dock" — none of which matches what those fights actually were (a `slum_thug` on the bridge, no "hallway" encounter exists at all). Reworded to match the actual fights without over-claiming a specific enemy type.
- Chapter 4 was the only chapter whose opening node (5001) lacked a "[CHAPTER 4: ...]" title, unlike every other chapter's opener. Added "[CHAPTER 4: THE HOLLOW COURT]".
- The Chapter 3 hub (node 3005, reached by choosing to "pause and take stock") silently forecloses the rooftop/cloisters infiltration route (3010) without ever telling the player — its own text even claimed choices here were still "before committing to a path". Reworded to state plainly that the rooftop route is off the table once you're here.

### Changed
- How Kroll's death is narrated now depends on how the fight was resolved: ending it quickly (the mercy option) and making him "pay for every session" (the vengeance option) each get their own aftermath text distinct from a plain fight, instead of all three of node 960's choices funneling into identical prose regardless of what the player actually chose.
- Chapters 4 and 5 assumed every player is physically carrying the Void Banner/Grey Shroud by the time they reach the catacombs and beyond ("the Void Banner had gone warm... against my back") — true only for the Guardian origin, which starts with it. The Rat and Broken origins explicitly begin with no Heirloom and no Banner. The Hollow Court altar scene (5003), the Chapter 5 opener (6001), and the ending (6005) now each have a Banner-seeker variant reflecting that honestly, selected automatically by which origin was played; node 6004's "the Shroud speaking" line was also generalized to "the Void itself" since that line didn't need forking to be accurate for both.

A fresh 3000-run random-walk simulation (same model as before, ignoring gating) confirms these additions don't regress the economy: average final gold actually rises further (217 → 329, still zero zero-gold outcomes) since Kroll's now-guaranteed fight and the archivist-route fights both pay out, and average alignment is unchanged at -0.48 since none of this touches alignment math.

## [1.53.0+80]

### Fixed
- The Playthrough Simulator's gold model never paid out a won fight's `goldReward` — it counted the encounter but only ever applied the choice's own (usually zero) `goldMod`. Since most of the story's gold comes from combat rather than flat pickups, every "random strategy" batch reliably ended near 0 gold despite visiting working shops, which is exactly the "can't participate in the economy" pattern a Gemini analysis of simulator batches flagged. Combat gold now folds into the step's recorded `goldMod` so the chapter breakdown and CSV/JSON exports stay consistent with the run's final total. The "maximize gold" strategy also now accounts for a fight's payout when scoring choices, instead of only ever chasing flat `goldMod` bonuses.
- Node 260's "Refuse & Fight" carried a -1 alignment penalty despite being the only reachable choice for any player without the 50 gold node 261 requires to pay the toll instead — i.e. a guaranteed alignment hit for self-defense with no real alternative this early in the story. Removed.

### Added
- A real fork at the Hollow Court altar (node 5003): fighting the zealots outright (`hollow_court_zealot`) is now an alternative to letting them scatter, leading to its own aftermath beat before rejoining the main path.
- A climax guardian fight at the Void tear (node 6003/6003b): a `void_manifestation` now contests the crossing into Chapter 5's final scene instead of it being an unopposed walk-through.
- Two new enemies (`hollow_court_zealot`, `void_manifestation`) extending the existing difficulty curve past the previous `inquisition_high_warden` ceiling, so Chapters 4 and 5 — previously zero combat encounters between them — have real stakes at the story's climax.

A random-walk simulation against the story graph (ignoring gating, matching the in-app simulator's own model) confirms the intended effect: average final gold across 3000 simulated runs goes from 86 to 217 with the zero-gold outcome eliminated entirely (was 1.6% of runs even before this fix, would have been ~75% without any combat payout at all), and average final alignment improves from -0.97 to -0.48.

Chapter 3-5 branching still falls well short of Chapter 1's — closing that gap properly is a larger, multi-release content project rather than something to rush into one PR alongside a balance/bug-fix pass.

## [1.52.1+79]

### Fixed
- Collapsing the story view's status bar left a large blank band instead of actually reclaiming the space (an `Expanded(child: statusBarCollapsed ? SizedBox.shrink() : ...)` inside a `Row` kept the row's own height and the Expanded's claimed width regardless of the collapsed state). Restructured so collapsed shows nothing but the small toggle itself.

### Changed
- Quest/item/skill/dice detail dialogs now render their flavor-text description with larger text and more generous line spacing, matching how the main story narration is styled, instead of the dialog's cramped default text style.


### Added
- Copy button for the Playthrough Simulator's batch summary (previously only individual runs and the Gemini analysis could be copied — batches only had Export).
- CSV and JSON export options for a batch's results, alongside the existing plain-text transcript export — CSV as one row per run (ending, gold, alignment, nodes visited, combat encounters, etc.) ready to drop into a spreadsheet, JSON as the same per-run data structured for scripting.

## [1.51.1+77]

### Added
- A `secret-scan` job in CI (using [gitleaks](https://github.com/gitleaks/gitleaks)) that runs before every build and gates the whole pipeline: if an API key, token, or other credential is ever committed, the push or PR fails before anything is built or released. Verified against the full existing codebase and git history first — both clean.

## [1.51.0+76]

### Added
- Copy button next to "Analyze with Gemini" in the Playthrough Simulator, matching the Copy/Export actions individual run transcripts already had.

### Fixed
- Playthrough Simulator results were lost every time the screen was backed out of and reopened (it's reached via `Navigator.push`, so a fresh widget instance means fresh, empty state) — moved the batch list into a Riverpod provider that lives for the app's lifetime, so results now persist until explicitly cleared with the app bar's clear-all button.
- Settings > Check for Updates always failed silently: this repository is private, and both the release lookup and the APK download were unauthenticated GitHub API calls, which a private repo answers with a 404 indistinguishable from a generic network failure. Both now send the GitHub Personal Access Token already stored for GitHub Sync (the download goes through GitHub's authenticated release-asset API instead of the plain, sign-in-walled `browser_download_url`), and tapping "Check for Updates" with no token set shows a specific message pointing at where to add one instead of a generic failure.

### Changed
- The Playthrough Simulator's strategy/runs controls now also collapse the moment the player scrolls down into the results (previously they only auto-collapsed right after running a batch, and only re-expanded on scrolling back to the top).
- The story view's status bar and companion strip now collapse automatically once the player scrolls down into a long piece of narration, instead of only ever collapsing via their manual chevron toggles.

## [1.50.0+75]

### Added
- Structural graph-integrity checker (`lib/data/story_graph_integrity.dart`) that walks every choice from the start node, ignoring gold/alignment/flag gating, to find unreachable nodes, dead ends, and broken `next_id` links — codifying the exhaustive BFS this project had been running by hand after content passes.
- "Audit Graph Structure" button in the Playthrough Simulator that runs the same check and reports results in-app.
- Automated test suite (`test/story_graph_integrity_test.dart`) that runs the structural audit against the shipped story graph on every CI run.
- A real smoke test (`test/widget_test.dart`) that launches the actual app and checks it renders, replacing the leftover default Flutter counter-app test.
- `flutter analyze` and `flutter test` steps in CI, and a `pull_request` trigger so both run before merge instead of only after pushing to `main`.
- `CHANGELOG.md` (this file).
- A guaranteed encounter for the previously-unused `void_wisp` enemy and its "Void Relic" quest, added to node 3005 alongside the chapter's other optional side-fights.

### Changed
- Node 3005's four side-fights now hint at their relative danger in their choice text (previously identical HP-blind phrasing spanned 74-182 HP with no in-fiction signal).
- Bumped the `gemini-1.5-flash` calls in the AI story generator and the simulator's Gemini analysis to `gemini-2.5-flash`, matching the model generation already used for Gemini TTS.

### Removed
- Seven dead root-level prototype files (`main.dart`, `models.dart`, `game_provider.dart`, `editor_tab.dart`, `play_tab.dart`, `schema_tab.dart`, `theme.dart`) superseded by `lib/` since the project's earliest commits and never part of the actual build.

### Fixed
- A version-string sync regression from earlier in this same release: `pubspec.yaml` bumped to 1.50.0 but `AppInfo.version` and the AndroidManifest app label were left at 1.49.2, so Settings' "Current version" and the in-app update checker's own version comparison were reading a stale value. Resynced all three.
- `installApk()` discarded the system installer's result entirely, so a failed install (most commonly "install unknown apps" not yet granted for this app — the expected first run) failed completely silently after a successful download. Now surfaces a message telling the user to grant the permission and retry.
- `flutter analyze` failing on 23 pre-existing info-level issues that had accumulated silently since analyze had never run in CI before this release — 17 fixed outright (deprecated `withOpacity`, missing `const`, unguarded `BuildContext` use across an `await`), 6 deliberately left as `DropdownButtonFormField.value` (each genuinely needs to stay reactive to external state) and suppressed with a documented `// ignore:`.
- Added `test/update_checker_test.dart` covering the update checker's version-string comparison.

## [1.49.2+74]
- Fix the story's true ending looping back to Chapter 1 instead of ending (#77)

## [1.49.1+73]
- Reduce clutter in playthrough simulator results (#76)

## [1.49.0+72]
- Add chapter/location/mood breakdowns, run filtering, and transcript export to the playthrough simulator (#75)

## [1.48.1+71]
- Remove the 'Leave (End Game)' choice from the very first story node (#74)

## [1.48.0+70]
- Fix silent combat trigger and an infinitely-farmable rat fight found in a coherence audit (#73)

## [1.47.1+69]
- Vary overused narrator phrasing found by re-running the 20-playthrough simulation (#72)

## [1.47.0+68]
- Rewrite all 75 story nodes in a denser, ironic first-person voice (#71)

## [1.46.1+67]
- Add collapse toggles for the status bar and companion, fix mislabeled origin-ending moods (#70)

## [1.46.0+66]
- Normalize story node metadata, enrich chapters 4-5, and auto-match excursion flavor to scene (#69)

## [1.45.0+65]
- Remove sherpa-onnx voice, add manual save/load, restrict reset to edit mode (#68)

## [1.44.7+64]
- Surface auto-read voice errors instead of failing silently (#67)

## [1.44.6+63]
- Fix "Please initialize sherpa-onnx first" error on every French read-aloud (#66)

## [1.44.5+62]
- Fix demon walk sprite overflowing the companion strip (#65)

## [1.44.4+61]
- Use the uploaded walking_angel/walking_evil frame sequences (#64)

## [1.44.3+60]
- Fix main build (pattern-assignment compile error) + scaffold companion walk-cycle folders (#63)

## [1.44.1+58]
- Fix UI freeze from sherpa-onnx voice by moving it off the main isolate (#62)

## [1.44.0+57]
- Use sherpa-onnx offline neural voice for French narration (#61)

## [1.43.0+56]
- Add auto-read narration using the fast on-device voice (#60)

## [1.42.2+55]
- Fix alignment-based companion sprite scale during walking (#59)

## [1.42.1+54]
- Remove misleading Later option on shop discovery, add alignment-based companion look (#58)

## [1.42.0+53]
- Add edit-mode back button fix, node-scoped shops, unseen badges, and level-up point distribution (#57)

## [1.41.0+52]
- Character creation overhaul: skill preview, lock-in naming, origin stories (#56)

## [1.40.0+51]
- Gemini voice loading/preload, and a 3-reroll dice mechanic with face preview (#55)

## [1.39.0+50]
- Edit-mode stat editor, Gemini playthrough analysis, dice/log polish in combat (#54)

## [1.38.0+49]
- Add optional Gemini AI voice for the read-aloud button (#53)

## [1.37.0+48]
- Restrict Back to edit mode, bark on fight-available nodes, animate dice rolls (#52)

## [1.36.0+47]
- Fix narrative continuity issues in the Ashen Street story (#51)

## [1.35.0+46]
- South-facing idle/fight poses, walk-in entrance, and a companion name (#50)

## [1.34.0+45]
- Turn the companion into an idle/walk/fight state machine (#49)

## [1.33.1+44]
- Show character stats before starting the game after creation (#48)

## [1.33.0+43]
- Rework companion animation direction/size and tutorial trigger (#47)

## [1.32.1+42]
- Fix walking companion still showing the fallback dog on-device (#46)

## [1.32.0+41]
- Add a first-time guided tour for In-Game mode, hosted by the companion (#45)

## [1.31.2+40]
- Wire the walking companion to the uploaded sprite frames (#44)

## [1.31.1+39]
- Scaffold sprite-frame folder for the walking companion (#43)

## [1.31.0+38]
- Add a walking companion animation option for story transitions (#42)

## [1.30.0+37]
- Add Continue button, filter, and sort to the shop screen (#41)

## [1.29.1+36]
- Fix release APK signing so in-app updates install without uninstall (#40)

## [1.29.0+35]
- New app icon; replace player-facing SnackBars with immersive modals (#39)

## [1.28.0+34]
- Split the app into Edit mode and In-Game mode (#38)

## [1.27.0+33]
- Collapsible Play sections, multi-run simulator, dark-mode map fix, TTS (#37)

## [1.26.0+32]
- Animate the story interface: node transitions, staggered choices, stat pulses (#36)

## [1.25.0+31]
- Add GitHub push-as-branch for in-app data edits (#35)

## [1.24.1+30]
- Make the discovery modal's View Quest actually work, add direct Accept (#34)

## [1.24.0+29]
- Add fixed shop stock, direct equip, and item/skill comparison (#33)

## [1.23.1+28]
- Fix update checker silently reporting "up to date" on API failures (#32)
