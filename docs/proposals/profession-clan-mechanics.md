# Clan mechanics, v2.1: the build is the clans you choose (Core, proposal)

**v2.1, from the user's answers:**
1. **Six main clans, six mechanics.** The Choir and the Pit become minor patrons, with the four tribes. **The Open Hand, the player's own clan, starts minor and can be raised into a seventh main clan** (below).
2. **Slots:** explained below, with a recommendation. The user's call is still open.
3. **A neglected clan loses power, or becomes the player's nemesis** (below).

v2 replaces v1. The user's direction:
- *"Make it more natural. The player adapts his play depending on the combination of cards/banners he earns. Make the main mechanics more different, like in Hades or Slice & Dice, specializing mainly by building his deck and die."*
- *"Mainly focus on the 8 clans... The subclans can be bonuses earned on special quests, events, discoveries."*
- *"The more you choose a clan, the more it gains power, conquers cities and territories, and gives you access to rarer skills and rewards."*

Proposal only; nothing is built. Sizes: **S** a day, **M** a PR, **L** two or three PRs, **XL** a wave. **[N]** Narrative writes it, **[UX]** UX designs it.

## Why v2

Today the clans' gifts don't make them play differently. Every clan's signs cover the same strike, guard, mend, spell and passive slots with similar numbers: the Dominion's, the Mire's and the Compact's read almost alike. A run doesn't change shape with the clans picked. v2 gives each clan **one play mechanic of its own, carried by every gift it gives**, the way each god in Hades has its own status and each face in Slice & Dice is a verb. The build is the die: which clans' gifts sit on its faces.

## Summary: the six main clans (and the seventh you can raise)

| | Clan | Mechanic (one line) | On the die | Feels like |
|---|---|---|---|---|
| 1 | **Dominion** | **Sentence**: your faces stack Sentence on a foe; at 5 its next attack is cancelled | Writ faces: Attack faces that add Sentence | control, denial |
| 2 | **Vigil** | **Watch**: you see intents ahead, and a Defend face against a foreseen attack **parries** (riposte) | Watch faces: Defend faces that parry what you saw coming | reading the fight |
| 3 | **Compact** | **Heat**: a face heats each time it is rolled in a fight (+1, to 3); at 3 it breaks guards | Forged faces that grow during the fight | slow build, big finish |
| 4 | **Mire** | **Rot**: poison that stacks, lasts, and spreads to another foe when its bearer dies | Venom faces that add Rot | attrition, packs melt |
| 5 | **Crows** | **Price**: gold is a fight resource; hits steal it, and you spend it on rerolls and loaded faces | Loaded faces (pay gold to fix the roll); rerolls that cost coin | gambling, economy |
| 6 | **Penitents** | **Burden**: take Curses on your own die on purpose; each feeds your other faces; lifting one bursts | Ember faces, plus the Curses you carry | risk, self-harm for power |
| 7 | **Open Hand** (your own) | **Echo**: its faces copy the mechanic of another clan's gift on your die, one step weaker; at its peak, two | Echo faces | the build that takes from everyone |

The six clans proper (dominion, vigil, compact, mire, crows, penitents) dictate play.

**Minor patrons:** the Choir and the Pit, and the four tribes (giants, oni, tidekin, kindly).
- Their gifts are neutral boons, like Hades' Chaos or Hermes, that fit any build.
- They take no slot, are never Dominant, and own no territory.
- The Choir's vows and the Pit's pacts stay as they are today, as their boons.

**The Open Hand is your own clan.** It is the lost clan the story lets you remember (`open_hand_1…`, five stages today).
- It starts as a minor patron.
- Raising it is a long quest: its stages, the Fishbasket Line, its last stage.
- Once raised, it becomes a **seventh main clan**: it gets power, can take places, and opens its own mechanic, **Echo** (its faces copy another clan's mechanic on your die).
- It's the only clan that can never be your nemesis: it is you.
- Its rise is a natural hook for the ch5/ch7 upheavals.

**Existing pieces each mechanic builds on:**
- **Dominion:** the Writ face (`writFace`).
- **Vigil:** Open Eyes (`intentLookahead`) and `parry.dart`.
- **Compact:** the Edge (`compactEdge`) and the `growth` keyword.
- **Mire:** `poisonExtraTurns` and the poison status.
- **Crows:** the Price (`crowsPrice`) and rerolls.
- **Penitents:** the Ember face (`emberFace`) and the Curses enemies already put on your die (`dice_tamper.dart`).
- **Open Hand:** its stages (`openHandStageFrom`) and the Fishbasket Line's "choose any boon".

## How a gift works

- **A gift carries its clan's mechanic into one slot.** The slots exist: strike (Attack faces), guard (Defend), mend (Heal), spell, passive.
  - A Dominion strike gift adds Sentence to every Attack face; a Mire mend gift makes heals "cleanse and Rot the attacker". **[N]** names.
  - A slot holds one clan's gift (as a sign slot holds one sign today). Which clan fills Attack, which fills Defend, **is** the build.
  - A gift can also be a **new skill** for a face, of that clan's mechanic, through the existing skill offers.
- **Rarity, gated by the clan's power** (below):
  - **common** from the start;
  - **rare** once the clan is Rising;
  - **legendary** once it is Dominant.
  - A legendary gift changes the rule, not the number. Dominion: Sentence at 5 *executes* a foe under 20%. Mire: Rot spreads to *every* foe.
- **Choosing.** Offers stay three suitors, three gifts, as today. Each gift shows its mechanic's icon and the slot it takes. **[UX]**
  - Taking it gives standing (as today) **and clan power**.
  - Filling a slot another clan holds replaces that gift, and the replaced clan takes it ill (standing -3).

## Combinations: duos and betrayals

**Duos.** When the die holds a gift from each of two clans whose relation is **Wary or better** (relations.json step ≥ 5), their **duo** can come up as a fourth card in an offer: one gift that joins the two mechanics, like Hades' duo boons. Today's relations allow exactly eight clan pairs:

| Duo | Clans (step today) | What it does |
|---|---|---|
| Writ of Seizure | Dominion + Crows (6, Trade) | a Sentenced foe pays double to the Price |
| Watchful Forge | Vigil + Compact (6) | a parry heats the parrying face to 3 |
| Mire Watch | Vigil + Mire (5) | a foreseen attacker is Rotted before it strikes |
| Keepers' Penance | Vigil + Penitents (7, Allies) | a parry lifts one of your Curses, which bursts |
| Smelter's Rot | Compact + Mire (6) | a face at Heat 3 also adds Rot |
| Loaded Heat | Compact + Crows (5) | paying for a loaded face heats it to 3 at once |
| Poisoned Purse | Mire + Crows (5) | each Rot tick steals 1 gold |
| Pawned Sins | Crows + Penitents (5) | sell a carried Curse for gold mid-fight |

The Open Hand, once raised, has no feuds: it duos with any clan whose gift its Echo copies.

**Betrayals.** Feuding clans (step ≤ 3) never offer a duo. Holding gifts from both can bring a **betrayal gift** from one of them: legendary-strong, at heavy standing cost with the other, and their relation drops a step. Today's feuds:
- Dominion with Vigil (3), Mire (3) and Penitents (2);
- Vigil with Crows (3);
- Compact with Penitents (3);
- Mire with Penitents (1).

So the strongest pair on paper, Sentence + Watch (Dominion + Vigil), is a feud: a betrayal path, not a duo. That is where the politics bite.

**Synergies and tensions by design.**
- **Synergies:** Heat with Rot, Price with Sentence (Dominion and Crows trade), Watch with Burden (Vigil and Penitents are allies).
- **Tensions:** the feuds below, and slots (two clans that both want Attack).
- Relations move during play, so a pair's duo can open or close as the story shifts.

## Clan power and territory

### Power

Each clan gets a **power** value (0–100) in `PoliticsState`, beside standing. Standing is how the clan sees *you*; power is how strong *it* is.

| Source | Power |
|---|---|
| A gift taken from it | +2 (legendary +4) |
| A quest done for it (quests carry a faction) | +5 |
| A zone cleared that it claims | +5 |
| A subclan boon earned | +5 |
| A betrayal against it | -10 |
| Politics events (variants shift standing today; they would shift power too) | ±5 to 15 |

| Tier | Power | Unlocks |
|---|---|---|
| Minor | 0–24 | common gifts |
| Rising | 25–49 | rare gifts; takes its first claim |
| Dominant | 50–74 | legendary gifts; takes more claims; its house in a town it holds (later hook) |
| Ascendant | 75+ | its throne claim weighs more at the ch7 decision (throne.dart) |

### Territory

- **The starting map.** `geography.json` already gives 12 places a `controller`:
  - Dominion: the Spire, Candlehold, its lantern hall, Alster's Black Hold;
  - Crows: the Wharf, Card Row, Alster's lower town;
  - Compact: Emberwick;
  - minor patrons: oni at Akagiri, Kindly Hill, the giants at Highhearth, the Tide-Kin on Tern Row.
- **Taking places.** `PoliticsState.control` (place id → clan) overrides that map as clans take places.
  - Each clan gets ordered **claims** in factions.json (the Mire: Kindly Hill, the Drowned Cloister, the Hollow Court).
  - When a clan's power crosses a tier, it takes its next claim.
  - The former holder loses the place, their relation drops a step, and a news line says so ("The Mire Courts hold the Drowned Cloister now"). **[N]**
- **What control does now:** in a held place, its clan's gifts are likelier in offers and its shops charge its standing price. The visuals are a later hook.
- **The radar** (#264) gains the clan's **power** (a ring or a bar) and the **places it holds** (a count, and the list on the clan tab). **[UX]**
- **Politics events** (26 in politics_events.json) gain:
  - a `trigger.power` condition (`{"faction": "dominion", "minPower": 50}`);
  - `effects.power` and `effects.control`.
  - The existing events keep working.

## Neglect and the nemesis

A clan the player keeps turning away from does not just fade.

- **Neglect.** Each chapter in which the player takes no gift and does no quest for a main clan costs it 5 power. Rivals then take its places as their tiers rise. That is a clan losing power.
- **Nemesis.** A clan becomes the player's nemesis when:
  - the player's standing with it falls to **Hostile** (−26 or lower), by refusing it, betraying it or serving its feuds;
  - it is still **Rising or stronger** (power 25+).

  There is at most one nemesis, the strongest such clan. A nemesis:
  - **hunts the party.** Its ambushes come on roads, detours and expeditions, through the alignment hunters' system (`buildHunterAmbushNode`). Its foes carry its own mechanic against you: Sentence on your attacks, Rot on your party, your gold stolen.
  - **contests your places.** It moves against the clans you back.
  - **offers nothing.** No gifts while it is your nemesis.
- **Ending it.**
  - **Reconcile:** raise standing back above Wary, through a costly quest or gift it asks for.
  - **Break it:** a nemesis quest, its champion as a boss, which drops its power by a tier and ends the hunt. That is a **[N]** story beat per clan, six of them.
- **The radar** shows a nemesis in red. **[UX]**

## Subclans: bonus boons earned in the world

A subclan is no longer chosen. Each one gives **one bonus boon**:
- of its clan's mechanic, bending it;
- stronger than a common gift;
- outside the slots (a passive).

It drops where the story already meets that subclan. These are proposed sources from the existing zones, intrigues, houses and voyages; **[N]** checks the fit.

| Clan | Subclan | Bonus boon | Drops from |
|---|---|---|---|
| Dominion | Inquisition | Sentence also weakens | the *hooded_lantern* intrigue |
| | Order | at 5 Sentence your next strike +50% | defeating a Challenger (the Order's mark) |
| | Tribunal | Sentence wins checkpoints (Charisma checks pass) | the *broken_charter* intrigue |
| | Admiralty | Sentence works in sea fights | z_white_fleet_grave cleared |
| | Reliquary | Sentence carries over against the same foe kind | a Shroud piece found |
| | Wickwardens | Writ faces give the party 3 block | Candlehold's lantern hall (story) |
| | Salt Ledger | each Sentence refunds 2 gold | the *double_ledger* intrigue |
| | Cantors | Sentence stacks on every foe, at half | the *dying_lantern_bearer* intrigue |
| Vigil | Candlebearers | +20% damage to the dead | z_ossuary_galleries cleared |
| | Stitchers | a parry heals half what it stopped | z_shroud_vigil cleared |
| | Last Watch | a foreseen attack on a companion gives them block | the *unwatched_hour* intrigue |
| Compact | Quarrymen | Heat 3 stuns | z_frost_quarry cleared |
| | Scaffolders | faces start at Heat 1 | z_scaffold_yards cleared |
| | Emberwives | Heat deals Fire | z_ember_run delivered |
| | Anvil-Deaf | +1 hone at the Smithy | Hammersmith built |
| Mire | Barkbleeders | Rot ticks +2 | z_fever_bark delivered |
| | Heron's Wake | +1 to fen crossings and expedition checks | z_changeling_fen cleared |
| | Returned | once a fight, Rot on you is turned on the foe | the *the_returned* intrigue |
| | Moss Choir | Rot ticks heal you 1 | z_bell_road escorted |
| Crows | Keyholders | one chest per expedition opens a rarity better | Smugglers' Cellar built |
| | Tar-Hands | the hull mends 25% between voyages | Harbor built |
| | Brig-Born | Price works at sea (boarding steals cargo) | a boarding won at sea |
| | Whisper Ledger | see each suitor's gifts before choosing | the *admiraltys_silence* intrigue |
| | Drowned Debt | rerolls cost 1 less gold | z_lantern_docks cleared |
| Penitents | Scorched Choir | each Curse carried heals 2 a round | z_cinder_row cleared |
| | Road Exorcists | lifting a Curse cleanses a status | z_exorcists_road cleared |
| | Reliquary Thieves | once a fight, steal a Curse onto a foe | the *relic_road* intrigue |
| | Spire-Fallen | with 3 Curses carried, +1 armor per Curse | the Spire (story) |
| | Ember Sisters | the party heals 10% after each fight | z_glass_strand cleared |
| Open Hand | Fishbasket Line | choose any one bonus boon already seen | the Open Hand's last stage |

Earning a boon makes its subclan a friend (as today) and adds clan power.

## Professions: the base the clans bend

The v1 profession specs are **dropped**: the clans are the spec. A profession stays what it is today, the **base**:
- its die (and the dice only it can use);
- its standard skill;
- its stats and scaling stat;
- for casters, mana and spells.

Different bases make the same clan play differently. A mage's Mana faces become Dominion Writs; a warrior's many Attack faces heat faster under the Compact. Skill branches and branch mastery stay as they are, offered by the clans that sponsor them.

## Example runs

1. **Dominion.** A warrior's Attack faces add Sentence, so the ogre loses every third attack. At Dominant, the legendary gift executes foes at 20%.
2. **Vigil.** A cleric reads two rounds ahead and parries the boss's telegraphed slam, riposting for half.
3. **Compact.** A ranger's faces heat through a long fight; from round 4 every roll breaks guard. The Quarrymen boon (Frost Quarry) adds stuns.
4. **Mire.** A rogue Rots one bandit; it dies and the Rot jumps to the next. Packs melt.
5. **Crows.** A rogue steals 30 gold a fight and spends it on loaded faces at the boss.
6. **Penitents.** A mage takes two Curses on purpose. Every face hits +20%, and an Ember face lifts one for a 30-point burst.
7. **Open Hand (raised).** A ranger with Mire on Attack and Compact on Defend takes the Open Hand's Echo on Heal: heals now add Rot, and at its peak heat too.

Duo run: Compact + Mire with *Smelter's Rot*. Heated faces Rot, and long fights end themselves.

## What's new, sizes, simulator checks

| Piece | New | Reuses | Size | Simulator check |
|---|---|---|---|---|
| Gifts carry a clan mechanic | the 6 mechanics in the fight state (Sentence, Watch parry, Heat, Rot, Price spending, Burden), then Echo; a gift's `mechanic` and `rarity` | sign slots, faces, keywords, statuses, writ/edge/ember/price, parry, dice tamper, pacts, vows | L (an M per pair of clans) | win rate per clan build by chapter: within ±5 points of each other, none above today's best by more than 8 |
| Rarity by clan power | gating in offers.dart | SignRarity, offer draws | S | rarity counts per chapter |
| Duos and betrayals | 8 duo gifts, 6 betrayal gifts, conditions | relations, offers | M | duo by ch5 in at most 1 run in 4 |
| Clan power, territory and the nemesis | `power`, `control`, `nemesis` in PoliticsState; `claims` in factions.json; tier crossing takes a claim; neglect decay; nemesis ambushes through the hunters' system | geography `controller`, politics events, relations | M | power curves per strategy (autoplay backs one clan): none Dominant before ch4 |
| Subclan boons | 30 boons and their drop hooks | zone rewards, intrigues, houses, voyages | M (data heavy, **[N]**) | boons a typical run finds (target 4–6 by the throne) |
| Radar: power and holdings | two readings | #264's radar | S | — |
| Offer UI | mechanic icon, slot, duo card | the offer dialog | M **[UX]** | — |
| Saves | old signs keep working; power starts from standing | | S | old save fixtures |

## Order of work

1. **Clan power and territory** (state, claims, tier crossings, radar readings). Rarity and duos depend on it.
2. **The mechanics, two clans per PR**, simplest first:
   - Mire + Compact (Rot, Heat);
   - Crows + Penitents (Price, Burden);
   - Dominion + Vigil (Sentence, Watch);
   - the Open Hand's Echo, once its stages are in place.

   Each PR turns that clan's signs into gifts of its mechanic, with rarity tiers.
3. **Duos and betrayals.**
4. **Subclan boons** with Narrative, zone by zone.
5. The simulator's per-clan report after each step.

## Later hooks (no design yet)

- **Town influence and clan houses (UX + Core).** A place's holder (`PoliticsState.control`) tints its scenes: the holding clan's banners, pennants and colours. A clan at Dominant may open one **clan house** in a town it holds: a shop of its rarer gifts and objects, at most one per clan, using the camp-house and shop systems.
- **The chapter 5 and 7 upheavals (Narrative + Core).** Two politics events where the player's choice can turn the tables before the throne: a betrayal taken earlier, or offered on the spot, flips a clan's power and a relation by two steps. They need only the `trigger.power`, `effects.power` and `effects.control` fields above.

## Open questions for the user

1. ~~The eight~~: answered. Six main clans, minor patrons, and the Open Hand raised into a seventh.
2. **Slots, explained.** Your die's faces come in kinds: **Attack** faces, **Defend** faces, **Heal** faces, plus **spells** and **passives** (always on). A gift today attaches to one kind, as a sign does (`strike`, `guard`, `mend`, `spell`, `passive`). So a Dominion gift on Attack makes every Attack face add Sentence. The question: can each kind hold one clan only (the Dominion owns Attack, the Mire owns Defend…), or can two clans share a kind (Attack faces adding both Sentence and Rot)?
   - **Recommended: one clan per kind.** That gives four or five clans at most on a die, so the build reads at a glance. Choosing who fills Attack and who fills Defend *is* the strategy. It's also what makes the duos meaningful: a duo is the only way two mechanics meet on the same face.
3. ~~Power decay~~: answered. Neglect costs power; hostility plus power makes a nemesis.
4. **New:** should the Choir and the Pit keep their vows and pacts as the minor boons they are today (proposed), or lose them to keep the minor patrons all alike?
