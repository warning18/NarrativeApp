# Professions and clans, v5: the profession plays, the clans specialise it (Core, proposal)

v5 reorganises v4.2 around your clarification:

> *"Professions define your gameplay, and each is linked more or less to clans, who allow you to specialize through their offers. So gameplay orientation is linked to professions but can be built differently upon becoming friendlier to a clan."*

- **The profession owns the core mechanic.** Each of the five professions gets one solo signature mechanic on its die faces and resources. The mechanics come from the material you already validated:
  - Blood Price, the Watchfire, the Ash Well, the Rot and the deck become professions' cores;
  - Thornplate becomes a warrior specialisation.
- **Clans specialise it.** As you grow closer to a clan, its offers bring gifts that bend your profession's mechanic in that clan's direction: warrior → holy warrior, berserker, thorn-wall. They come through today's offer system and accumulate. There is nothing to wear and no rule to switch on or off.
- **"More or less linked."** Each profession has three **natural clans**, taken from the factions' existing `sponsors` (the skill branches each clan already backs). These offer its gifts more often and give the strongest twists. The other clans are weaker links.
- **Kept:**
  - the passive stats per clan level;
  - subclan gifts as clan offers;
  - the Tide and the skill-verb proposals (still open questions);
  - power, territory and the nemesis;
  - the Pit, the Choir and the Open Hand as minor directions.

Proposal only; nothing is built. **[N]** marks Narrative's part, **[UX]** UX's.

## At a glance

| Profession | Core mechanic | Specialisation 1 | Specialisation 2 | Specialisation 3 | Minor direction |
|---|---|---|---|---|---|
| **Warrior** | **Blood Price**: Attack faces are Pain strikes (double damage, 8% of your max health); stronger below half health | **Berserker** (Crows): +50% below half, a kill heals 10% | **Thorn-wall** (Compact): half of what your guard and armour stop goes back; no dodge | **Holy warrior** (Dominion): Pain strikes are Fire and Pierce; against Evil they cost nothing | **Dark knight** (Pit): spells paid in blood |
| **Cleric** | **The Watchfire**: self-healing above half; healing past full burns the enemy for double | **Radiance** (Vigil): every heal also burns the enemy for its amount | **Ember Sister** (Penitents): the fire turns into mana, and cleanses | **Lantern Cantor** (Dominion): the fire holds your whole max health and burns every enemy | **Paladin** (Choir): the Vow |
| **Mage** | **The Ash Well**: mana from Mana faces only, starting at 0; Mana faces give double; spells cost 1 less; mana left heals | **Inquisitor** (Dominion): mana past full burns the enemy | **Ash Chorister** (Penitents): a spell from a full Well hits +50% | **Storm Arcanist** (Crows): spells steal life; Teleport Strike | **Blood mage** (Pit): Clause in Blood |
| **Rogue** | **The Rot**: strikes deal 20% less, but each one that lands adds a lasting, stacking poison | **Fever Blade** (Mire): stronger rot that passes on when its bearer falls | **Tar Bleeder** (Crows): Pain strikes whose cost is paid as rot on the enemy | **Relic Thief** (Penitents): each rot tick feeds you mana | — |
| **Ranger** | **The Trail** (the die as a deck): each face comes up once before any repeats; you see the next face; the sixth, the Verdict, counts half again | **Trapwright** (Compact): the Verdict is a trap that stuns | **Fen Guide** (Mire): first draws poison | **Corsair Marksman** (Crows): the Verdict doubles and Pierces | — |

## Why each mechanic fits its profession

| Profession | Mechanic | Why it fits |
|---|---|---|
| Warrior | Blood Price | Heavy blows paid in your own health: the warrior is the one who stands in front, and the berserk style you described. Warriors are the weakest profession today (37% of fights won), and this is the mechanic that lifts them most. |
| Cleric | The Watchfire | Healing is what clerics do, and overheal becomes their damage: your idea for the Vigil, now the cleric's own, while the Vigil becomes a cleric clan. |
| Mage | The Ash Well | Mana from the die alone, your Slice & Dice example. The mage already lives on Mana faces and Channel. |
| Rogue | The Rot | Poison and patience: the Venom branch and Poison Blade are rogue skills. The many quick hits suit the rogue's dice. |
| Ranger | The Trail | A hunter reads what comes: the die becomes a trail you can see one step ahead, for aimed shots and traps set in advance. Before v5, Dominion held it as the Writ of Order. |

## Measured: each profession's core and one specialisation

**Setup:**
- 200 seeded runs per line, 40 per profession, random strategy. Each profession plays only its own mechanic.
- The mechanic was added through a temporary patch of the fight simulator, kept in the Core session's scratchpad as `v5_prof_sim.patch` and never committed.
- The autoplay doesn't rebuild its die for a mechanic, so the numbers show a player who doesn't adapt.

| Profession | Today: win / rounds | Core: win / rounds | Specialisation measured: win / rounds | With the Tide: today → core → specialisation |
|---|---|---|---|---|
| Warrior | 37.0% / 14.2 | **Blood Price 48.5% / 8.9** | Berserker 56.5% / 9.1 (Thorn-wall in place of the core: 43.1% / 11.2) | 41.7% → 56.3% → 63.4%, about 8.4 rounds |
| Cleric | 73.7% / **38.8** | **Watchfire 77.1% / 39.1** | Radiance 81.5% / 33.8 | 52.0% → 55.5% → 55.4%, about 16.5 rounds |
| Mage | 63.0% / 8.3 | **Ash Well 65.8% / 8.2** | Inquisitor 66.0% / 8.1 | 62.1% → 62.1% → 63.7%, about 7.8 rounds |
| Rogue | 48.7% / 13.1 | **Rot 52.8% / 13.0** | Fever Blade (rot at 10%) 62.1% / 12.0 | 57.2% → 56.8% → 61.1%, about 10.5 rounds |
| Ranger | 53.8% / 13.5 | **Trail 63.8% / 12.5** | Corsair (Verdict ×2) 71.0% / 12.2 | 59.8% → 68.1% → 72.6%, about 10.1 rounds |

What the numbers show:
- **The cores narrow the gap between professions.** Today's spread is 37 points (warrior 37%, cleric 74%). With the cores it is 29 points; with the cores and the Tide, 12 points (55–68%).
- **The long fights are a cleric problem.** Clerics average **38.8 rounds** against 8 to 14 for everyone else: they outlast, and their damage is low. No healing rule fixes it. Even every heal burning for its full amount (Radiance) only brings them to 33.8. **The Tide does: 17 rounds.** A cleric's damage skills with a verb (Smite double against Evil, below) are the second lever.
- **The Trail is the strongest core (+10 for rangers).** **Suggested:** a Verdict of ×1.25, or the deck with no Verdict (58.8% overall in v4).
- **The mage's Ash Well barely moves (+3):** the autoplay keeps one Mana face. A mage who builds two is the case the mechanic is for. Estimate: +5.
- **The specialisations add 0 to 9 points over their core,** and most of them shorten fights. That is the room a clan's gifts add up to.

## Clans by profession: the affinity table

Natural links (●●) come from what each clan already sponsors in factions.json:
- Dominion: warrior Vanguard, cleric Judgment, mage Evocation;
- Vigil: warrior Warlord, cleric Vigil;
- Compact: warrior Bulwark, ranger Trapper;
- Mire: rogue Venom, ranger Wilds;
- Crows: rogue Shadow, mage Tempest, ranger Marksman;
- Penitents: cleric Devotion, rogue Trickster, mage Aegis.

Where a profession has more than three, the three listed first are its main specialisations. A weak link (●) still offers a twist, less often.

| | Dominion | Vigil | Compact | Mire | Crows | Penitents |
|---|---|---|---|---|---|---|
| **Warrior** | ●● Holy warrior | ● Wall Veteran | ●● Thorn-wall | ○ | ●● Berserker | ● Ash Penitent |
| **Cleric** | ●● Lantern Cantor | ●● Radiance | ○ | ● Moss Singer | ○ | ●● Ember Sister |
| **Mage** | ●● Inquisitor | ○ | ● Ember Adept | ● Hex-Weaver | ●● Storm Arcanist | ●● Ash Chorister |
| **Rogue** | ○ | ● Stitcher | ○ | ●● Fever Blade | ●● Tar Bleeder | ●● Relic Thief |
| **Ranger** | ● Admiralty Gunner | ○ | ●● Trapwright | ●● Fen Guide | ●● Corsair Marksman | ○ |

Notes on the table:
- **Warrior and Crows.** The Crows don't sponsor a warrior branch today. The berserker comes from your own example, and the Crows already lend low-health damage and lifesteal signs. Vigil's Warlord sponsorship makes it the weaker warrior link.
- **What the links change:**
  - **●●** offers the profession's gifts at the full rate, and its gifts can rise to rank II at Sworn.
  - **●** offers them at half the rate, rank I only.
  - **○** offers no twist for that profession: only today's gifts and the passive stats.

## How a specialisation arrives: the clan's offers

- **Subclan gifts are clan offers.** From **Trusted** with a clan, its subclans that are your friends (v3's table) add their gifts to that clan's offers, filtered by **your profession**. You pick one like any gift, and it stays for the run.
- **Specialisations stack.** A warrior can be Crows-Berserker and Compact-Thorn-wall at once: Pain strikes that heal on a kill and plating that bites back. Mixing is a build, not a mistake.
- **Stacking stays in check without slots:**
  1. Each gift twists a different part of the mechanic (its trigger, its payoff, or its cost).
  2. The mechanic's caps stay, and no gift lifts them:
     - Pain never takes the last point;
     - the Rot adds at most 10% per strike;
     - the Watchfire holds at most half your max health (the Lantern Cantor, by design, holds your whole max health);
     - the deck has six faces.
  3. One of each: a gift you hold that comes back at Sworn rises to rank II (+50%), and no further.
  4. **Rarity:**
     - a subclan's first gift is uncommon, from Trusted;
     - its second is rare, from Sworn;
     - the minor directions' gifts are epic.

     At most one of an offer's three suitors is a subclan gift.
  5. When two gifts touch the same number, the second adds half.
- **Passive stat points per level, unchanged:** they come from the clan you stand best with (Friendly +1 to its first stat, Trusted +1 to its second, Sworn +5 max health).

  | Clan | Stats |
  |---|---|
  | Dominion | Strength, Charisma |
  | Vigil | Constitution, Perception |
  | Compact | Constitution, Strength |
  | Mire | Dexterity, Luck |
  | Crows | Strength, Dexterity |
  | Penitents | Wisdom, Intelligence |

  So a clan pulls your stats as well as your mechanic.
- **A nemesis** stops offering. The gifts you hold from it sleep until you reconcile.

## The five professions in detail

### Warrior: Blood Price
- **Core.** Every Attack face is a Pain strike: it hits for double and costs 8% of your max health (never the last point). Below half health, your strikes deal 25% more.
  - **Suggested:** Pain at ×1.75 under the core, if a sidegrade is wanted.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twists |
  |---|---|---|
  | **Crows** (Brig-Born, Tar-Hands) | **Berserker** | Below half health, strikes deal 50% more (not 25%); a kill heals 10% of your max health |
  | **Compact** (Quarrymen, Anvil-Deaf) | **Thorn-wall** | Half of every blow your block, parry and armour stop goes back (Thornplate); you can't dodge. Stonebreaker, the rank II gift: a blow sent back breaks the striker's guard |
  | **Dominion** (Order) | **Holy warrior** | Knight of the Flame: Pain strikes are Fire and Pierce. Lantern Oath: a Pain strike against an Evil foe costs nothing |

- **Weaker links:**
  - Vigil, Wall Veteran: a Defend face pays back the last Pain cost.
  - Penitents, Ash Penitent: Pain costs mana first, health only when the well is dry.
- **Minor direction:** the Pit, **Dark knight**: spells can be paid in blood, and blood-paid spells heal you for a share.

### Cleric: the Watchfire
- **Core.**
  - At the start of each round, while at half health or more, you heal 2% of your max health.
  - Healing past full feeds the Watchfire, up to half your max health.
  - Enemy blows hit it first. What's left at the round's end burns the enemy for double.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twists |
  |---|---|---|
  | **Vigil** (Candlebearers) | **Radiance** | Every heal also burns the enemy for its amount (measured: 81.5%, 33.8 rounds) |
  | **Penitents** (Ember Sisters) | **Ember Sister** | When the fire burns, it also gives 1 mana and cleanses one affliction |
  | **Dominion** (Cantors) | **Lantern Cantor** | The fire holds up to your whole max health, and its burn reaches every enemy (Light) |

- **Weaker link:** Mire, Moss Singer: potions overheal into the fire.
- **Minor direction:** the Choir, **Paladin**: no potions; heals +50%; once a fight, a killing blow leaves you at 1.

### Mage: the Ash Well
- **Core.**
  - Each fight starts with 0 mana.
  - Mana faces (and mana skills) give double.
  - Spells cost 1 less.
  - Mana left after a win heals you 2% per point.

  Mana already comes back mid-fight only through the die, as in your example; the Well adds the empty start.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twists |
  |---|---|---|
  | **Dominion** (Inquisition) | **Inquisitor** | Mana past full burns the enemy, for half your strike per point (measured: 66.0%) |
  | **Penitents** (Scorched Choir) | **Ash Chorister** | A spell cast from a full Well hits 50% harder |
  | **Crows** (Keyholders) | **Storm Arcanist** | Spells steal 10% of their damage as health; Teleport Strike joins your offers |

- **Weaker links:**
  - Compact, Ember Adept: your Fire spells set off reactions twice.
  - Mire, Hex-Weaver: your spells' statuses last a turn longer.
- **Minor direction:** the Pit, **Blood mage** (Clause in Blood): a spell you can't afford is paid in health, 5% of your max per missing mana, while above half.

### Rogue: the Rot
- **Core.** Your strikes deal 20% less. Each strike that lands adds a lasting poison (5% of the full strike, every turn, all fight), stacking.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twists |
  |---|---|---|
  | **Mire** (Barkbleeders) | **Fever Blade** | The rot adds 10% per strike (measured: 62.1%, 12.0 rounds); when a rotting enemy falls, its rot passes to the next |
  | **Crows** (Tar-Hands) | **Tar Bleeder** | Attack faces become Pain strikes, but the cost goes onto the enemy as rot, and you pay half |
  | **Penitents** (Reliquary Thieves) | **Relic Thief** | Each rot tick gives you 1 mana, at most 3 a round |

- **Weaker link:** Vigil, Stitcher: healing past full becomes rot on the enemy.

### Ranger: the Trail
- **Core.**
  - Each roll takes a face that hasn't come up yet in this run of six, and you **see the next face**.
  - When all six have come up, the deck is shuffled again.
  - The sixth face of a run, the **Verdict**, counts half again.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twists |
  |---|---|---|
  | **Crows** (Brig-Born) | **Corsair Marksman** | The Verdict counts double and Pierces (measured: 71.0%) |
  | **Compact** (Scaffolders) | **Trapwright** | The Verdict also stuns its target |
  | **Mire** (Heron's Wake) | **Fen Guide** | The first face of each run poisons its target |

- **Weaker link:** Dominion, Admiralty Gunner: once a fight, send the face you drew to the bottom of the run and draw again.

## The Open Hand

- **It is raised by the banner.**
- **Its passive** is +1 to your strongest stat.
- **Its offers can bring back** any subclan gift you passed on, for your profession, whatever clan it came from.
- **Its own gift** is **Your Own Hand**: once a round, reroll the die. It is measured at +5 overall. Under the ranger's Trail, it draws the next face instead.

## Short fights: the Tide

Unchanged from v4.2, and still an open question for you:
- From round 8, your blows gain +20% a round and the enemies' +10%, adding up.
- Measured over all professions: the same win rate (54.5%); 16.6 → 11.2 rounds per fight; fights over 25 rounds from 14.5% to 1.1%; chapter 7 from 30.3 → 16.6 rounds.
- v5 adds the detail that matters: **it is mostly the cleric's fights it shortens** (38.8 → 17.2 rounds). Everyone else's are 8 to 14 rounds today.

## More skills in play

Unchanged from v4.2, and still open:
- **Today:** 92 skills come up, but they spread like only 17 equally used skills. Prayer alone is 18% of skill rolls (a fixed face). 39 skills are under 0.2%: Execute, Meteor, Fireball, Shield Bash, Multi-Shot and more.
- **Proposals:**
  1. Free the mana face once the die has a second mana source.
  2. One verb per damage skill:

     | Skill | Its verb |
     |---|---|
     | Execute | Double under 30% |
     | Meteor | Delayed, every enemy, double |
     | Multi-Shot | Three hits of 40% |
     | Smite | Double against Evil |
     | Backstab | Double against a stunned or weakened enemy |
     | Whirlwind | Cleave |
     | Power Strike | Steady |
     | Aimed Shot | Pierce |
     | Hammer Blow | Growth |
     | Poison Blade | Stacks |
     | Iron Will | Block equal to its heal |
     | Second Chance | Double below a quarter health |
     | Fireball | Splash |

  3. The core mechanics now lift different skills per profession:

     | Profession | Skills its mechanic lifts |
     |---|---|
     | Warrior | Berserk Rage, Reaping Whirl, lifesteal |
     | Cleric | heal skills |
     | Mage | Channel, Mana Shield |
     | Rogue | Multi-Shot, Poison Blade |
     | Ranger | Steady faces, Aimed Shot |

  4. The fresh face, optional, at +25%.
  5. An epic skill offered from chapter 4.
  6. Track the spread of skills in play in the simulator report, target 25.

## Kept from v2.1 and v3

How the kept parts tie in:
- **Passive stats** come from your best-standing clan.
- **Specialisation gifts** come in clans' offers from Trusted.
- **A nemesis** stops its offers; the gifts you hold from it sleep.
- **Taking a clan's gifts raises its power**, so a specialisation shapes the map too.
- **Alignment** stays separate.

### Clan power and territory

#### Power

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

#### Territory

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

### Neglect and the nemesis

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

## Order of work (once the user validates)

1. **The Tide**, alone first.
2. **The five core mechanics**, one per profession, with a committed per-profession simulator report.
3. **Free the mana face, and the skill verbs** (texts by **[N]**).
4. **Specialisation gifts** in the clans' offers: the 15 main ones first, then the weaker links, named by **[N]**. **[UX]**: how a gift shows the mechanic it bends.
5. **The passive stats per level.**
6. Power, territory and the nemesis, afterwards.

## Open questions for the user

1. **The mapping:**
   - warrior Blood Price;
   - cleric Watchfire;
   - mage Ash Well;
   - rogue Rot;
   - ranger Trail.

   Swap any?
2. **The three main specialisations** per profession, and the affinity table: do the natural clans match how you see them?
3. **Weak links:** half the rate and rank I only, or no offers at all?
4. **The Tide**, and the **skill proposals**: still open from v4.1.
5. **Strength:** a specialisation adds 0 to 9 points over its core. Is that the right size for loyalty to a clan?
