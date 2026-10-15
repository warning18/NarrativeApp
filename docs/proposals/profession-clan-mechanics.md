# Clan playstyles, v3: six ways to play, through the offers you already have (Core, proposal)

v3 replaces v2.1. The user's direction:
- *"No for the gift: I want to keep the actual system of offer, and the dice will be handled by the user."*
- *"However each clan has a leniency to certain skills, stats and way of play. First I need to validate the difference of gameplay built around the actual one for each of the 6 main clans, and the passive stat points they would offer in addition to their reward each level."*
- *"As you become closer to a clan later in the game, its subclans can offer you 'cards' too, so you specialize in other ways related to the main clan's spec."*

So:
- **The offers stay as they are**: three suitors, gifts of skills, signs, objects, titles.
- **The die stays the player's**: you put what you like on its faces.
- Each of the six main clans **leans** its offers toward a way of playing, and a closer clan adds **a few stat points each level** and, later, **subclan cards** that specialise your profession.

Proposal only; nothing is built. **[N]** Narrative writes it, **[UX]** UX designs it.

## Summary

| Clan | Leans to (skills, stats) | Playstyle | Passive stats per level (patron) | Example specialisations (cards) |
|---|---|---|---|---|
| **Dominion** | Vanguard (Power Strike, Guard Break, Whirlwind, Execute), Judgment (Smite, Inner Fire), Evocation (Fireball, Meteor). **Strength, Charisma** | **The Line.** Steady, heavy blows at the head of a party that fights with you. Few statuses: raw force and fire, attacks cancelled (the Writ) | +1 Strength (Friendly), +1 Charisma (Trusted) | Warrior → **Knight of the Flame** (Order); Mage → **Inquisitor** (Inquisition); Cleric → **Lantern Cantor** (Cantors) |
| **Vigil** | Warlord (Rallying Shout, Warcry), Vigil (Iron Will, Second Chance), orc and voidkin heritage. **Constitution, Perception** | **The Watch.** Long fights won by outlasting: block, shields, seeing the blow coming, a first strike that counts. The longest fights | +1 Constitution (Friendly), +1 Perception (Trusted) | Warrior → **Wall Veteran** (Last Watch); Cleric → **Ossuary Warden** (Candlebearers); Rogue → **Stitcher** (Stitchers) |
| **Compact** | Bulwark (Shield Bash stun, stances), Trapper (Trap stun), dwarf heritage. **Constitution, Strength** | **The Anvil.** Armour, thorns and retaliation; Earth and stuns; guards broken. Takes blows and gives them back | +1 Constitution (Friendly), +1 Strength (Trusted) | Warrior → **Stonebreaker** (Quarrymen); Ranger → **Trapwright** (Scaffolders); Mage → **Ember Adept** (Emberwives) |
| **Mire** | Venom (Poison Blade, Battle Trance), Wilds (Beast Bond, Mending Touch), elf heritage. **Dexterity, Luck** | **The Venom.** Statuses and patience: poison that lasts, weaken and stun, crits and dodges, potions that heal more | +1 Dexterity (Friendly), +1 Luck (Trusted) | Rogue → **Fever Blade** (Barkbleeders); Ranger → **Fen Guide** (Heron's Wake); Cleric → **Moss Singer** (Moss Choir) |
| **Crows** | Shadow (Backstab, Shadow Step, Clone), Tempest, Marksman, voidkin heritage. **Dexterity, Strength** | **The Knife.** Short, risky fights: burst, poison, lifesteal and harder hits when low, and gold from every hit | +1 Dexterity (Friendly), +1 Strength (Trusted) | Rogue → **Ledger Knife** (Whisper Ledger); Ranger → **Brig Marksman** (Brig-Born); Mage → **Vault Arcanist** (Keyholders) |
| **Penitents** | Devotion (Prayer, Purify, Sanctuary, Revive), Aegis (Channel, Mana Shield), Trickster. **Wisdom, Intelligence** | **The Ash.** A mana engine and sustain: spells that cost less and hit harder, cleanses, healing after every fight. The least damage taken | +1 Wisdom (Friendly), +1 Intelligence (Trusted) | Warrior → **Penitent Knight**, the "holy warrior" (Spire-Fallen); Cleric → **Ember Sister** (Ember Sisters); Mage → **Ash Chorister** (Scorched Choir) |

**The minor patrons** (Choir, Pit, the four tribes) stay aside, as decided. They can offer one card each, outside the six. The user's "dark knight" is the **Pit's** card for a warrior, and its mirror is the **Choir's** "paladin" (open question 3).

## What the simulator shows today

The question the user asked first: do the six clans already play differently? The simulator answers **no, not yet**.

**Setup:** 200 seeded runs per clan, with the five professions in turn. "Backing a clan" means taking its suitor whenever it is in an offer (a temporary local patch, not committed).

| Backed clan | Fights won | Rounds per fight | Damage taken per fight | Signs held at the end |
|---|---|---|---|---|
| none (baseline) | 54.0% | 16.5 | 74.9 | 25.1 |
| Dominion | 54.6% | 15.9 | 77.6 | 20.9 |
| Vigil | 58.1% | **19.1** | 71.1 | 20.7 |
| Compact | **59.6%** | 16.7 | **81.7** | 22.5 |
| Mire | 53.6% | 16.8 | 74.2 | 21.3 |
| Crows | 51.0% | **15.7** | 70.4 | 19.1 |
| Penitents | 51.5% | 16.6 | **67.3** | 20.2 |

What the numbers show:
- **The die is the same whatever the clan.** Attack faces are rolled 31% of the time, Defend 20%, Mana 9%, for every clan.
- **The skills rolled most are the profession's and the race's, not the clan's.** Prayer leads everywhere, then Entropy Touch, Backstab, Berserk Rage.
- **The hints of identity are there, but faint:**
  - Vigil makes fights longest;
  - Compact wins most and takes most;
  - Crows makes fights shortest;
  - Penitents takes least damage.
- **The professions dwarf the clans.** Fights won by profession: cleric 70–82%, mage 59–71%, ranger and rogue 42–56%, warrior 33–44%.

So the leanings below are about **widening those faint differences** until a run that backs a clan feels like that clan. The target, measured the same way after the change, is in the last column of each section.

## The six playstyles

Each section covers what the clan's offers lean on today (data in factions.json: `sponsors`, signs, `objects`, `sworn`), how a run that backs it plays, and the lean to add. The lean only weights what is already offered; it builds nothing new.

**How the lean works, for all six:**
1. **More of its own.** A clan's skill gifts come from its sponsored branches; its weight on those goes up, so its gifts are its style, not a random branch.
2. **Its signs carry its stats.** Each clan's signs get its two stats, where the effect kind has a stat (`stat` effects), and its status or keyword.
3. **Its objects follow suit.** The weapons and armour it offers scale on its stats.
4. **The patron's passive stats** (below) push the character the same way, level after level.

### Dominion: The Line
- **Today.**
  - Branches: Vanguard, Judgment, Evocation, human and dwarf heritage.
  - Signs: party block ×2, ally damage, party health, steady keyword, thorns, a mend for the party, cheaper spells.
  - Objects: sword, shield, a halo lance (Strength), the Harborwatch coat and lantern.
  - Sworn: the Writ (cancels a blow) and a calm sea.
- **How it plays.** Steady force. Your Attack faces carry Power Strike, Execute or Fireball. Your companions hit harder and start with block. The Writ takes the enemy's worst blow off the table. Little luck, few statuses: the plan works because it is solid.
- **On the die.** Heavy Attack skills, one steady face, a party shout. Low variance.
- **Lean.**
  - Stats: Strength and Charisma.
  - Keyword: steady.
  - Skills: more Vanguard and Judgment.
- **Target.** Fights short-to-medium (about 15 rounds), win rate in the middle, damage taken in the middle. The party matters: companion damage share up.

### Vigil: The Watch
- **Today.**
  - Branches: Warlord, Vigil, orc and voidkin heritage.
  - Signs: block % and flat, mend %, mend shield, weaken spells, Perception +2, party block and health, first-round damage, crit, pierce, Light.
  - Objects: spear, gravecloth hood, the Last Watch helm and coat, a tower shield.
  - Sworn: Open Eyes (see intents a round ahead).
- **How it plays.** You see what comes and stand in front of it: block, a shield on the wounded, Second Chance when it goes wrong, one hard first strike. Long fights that you don't lose.
- **On the die.** Two Defend faces with block signs, Iron Will or Second Chance, one shout.
- **Lean.**
  - Stats: Constitution and Perception.
  - Status: weaken.
  - Skills: more Vigil and Warlord.
- **Target.** The longest fights (19 rounds or more), damage taken low per round, win rate high but slow.

### Compact: The Anvil
- **Today.**
  - Branches: Bulwark, Trapper, dwarf heritage.
  - Signs: armour, thorns, retaliate, flat guard, mend shield, Earth ×2, cleave and pierce, Constitution +2, spell damage.
  - Objects: the iron cap, boots and scale, emberproof plate, thornmail, a sword.
  - Sworn: the Edge (breaks a guard).
- **How it plays.** You take the blow and it costs them. Armour and thorns punish every hit. Shield Bash and traps stun, Earth strikes cleave, guards break. It wins by being expensive to hit.
- **On the die.** Shield Bash or Trap Set on two faces, Defend faces with retaliate, Earth Attack faces.
- **Lean.**
  - Stats: Constitution and Strength.
  - Status: stun.
  - Element: Earth.
  - Skills: more Bulwark and Trapper.
- **Target.** Highest win rate and highest damage *taken*, as now, but with more of it returned (thorns and retaliate damage share up).

### Mire: The Venom
- **Today.**
  - Branches: Venom, Wilds, elf and orc heritage.
  - Signs: crit ×2, dodge, first-round damage, a weaken guard, a stun spell, Luck, Wind.
  - Objects: antidote, major potion, the Venom Hex spellbook, Tidewalker boots, the moon shard, the bloodthorn blade.
  - Sworn: potions +15% and poison 1 turn longer.
- **How it plays.** Patience and statuses. Poison Blade and Venom Hex tick, weaken and stun buy rounds, crits and dodges swing a fight, and potions keep you up. The longer the fight, the better it goes.
- **On the die.** Poison Blade on two faces, one dodge or Battle Trance face, Mending Touch.
- **Lean.**
  - Stats: Dexterity and Luck.
  - Statuses: poison, weaken.
  - Skills: more Venom and Wilds.
- **Target.** Poison's share of damage dealt clearly up (the highest of the six); fights medium-long; damage taken in the middle, potions used most.

### Crows: The Knife
- **Today.**
  - Branches: Shadow, Tempest, Marksman, voidkin heritage.
  - Signs: poison ×3 (strike, spell), lifesteal, low-health damage, kill heal, Strength +2, max health, spell damage, Fire.
  - Objects: the lucky coin, the fourth-roll charm, brigandine, the Smoke Veil spellbook, a sallet, a dagger.
  - Sworn: the Crow's Price (gold per hit) and a calm sea.
- **How it plays.** In fast, out rich. Backstab and Shadow Clone burst, poison finishes, lifesteal and harder hits at low health turn a bad fight around. Every hit pays. High variance: the shortest fights, lost faster when they go wrong.
- **On the die.** Backstab and Multi-Shot on Attack faces, a Shadow Step face, few Defend faces.
- **Lean.**
  - Stats: Dexterity and Strength.
  - Status: poison.
  - Skills: more Shadow and Marksman.
  - Rerolls (the fourth-roll charm).
- **Target.** The shortest fights (about 14 rounds), the widest spread of outcomes, gold per fight highest.

### Penitents: The Ash
- **Today.**
  - Branches: Devotion, Aegis, Trickster, human and elf heritage.
  - Signs: mana ×2, max mana, mana on hit, cheaper spells, spell damage, a cleanse, mend %, XP +, Lightning and Ice, a stun.
  - Objects: a minor potion, a warding charm, Sanctified Ground, the saint's reliquary, the phoenix sigil, the dawnward shield.
  - Sworn: 10% healing after each fight, and the Ember face (lifts a Curse).
- **How it plays.** A mana engine. Channel and mana faces fill the well, spells cost less and hit harder, Purify and Sanctuary clean and hold, and you walk out of every fight healed. The least damage taken, and the slowest damage dealt.
- **On the die.** Channel and Prayer on two faces, a Mana face, Sanctuary or Mana Shield.
- **Lean.**
  - Stats: Wisdom and Intelligence.
  - Status: stun.
  - Skills: more Devotion and Aegis.
- **Target.** Least damage taken (already true), spell share of damage the highest, fights medium.

## Passive stat points per level

Your **patron** is the main clan you stand best with, if Friendly or better. It adds stat points each time you level up, on top of the level's own reward (+20 health) and the training offer (5 points).

| Standing with your patron | Each level |
|---|---|
| Friendly (12+) | +1 to its first stat |
| Trusted (26+) | +1 to its first stat and +1 to its second |
| Sworn (61+) | as Trusted, and +5 max health |

- **One patron only.** No stacking across clans; the bonus follows whoever is your patron at that level. Points already given stay: they are the character's.
- **It stops** when no main clan is Friendly or better, or when the patron becomes your **nemesis**.
- **Size.** At most 2 points a level, against the 5 of training: a lean, not a second training. The simulator check is that the six clans' win rates stay within ±5 points of each other with the bonus on.
- **The Open Hand,** once raised, gives +1 to the stat you have most of: your own hand.

## Subclan cards: specialising your profession

When you are **Trusted** with a main clan, its subclans can offer you **cards**.
- **A card is a specialisation of your profession in that clan's direction.**
- It is built only from what exists:
  - **a skill** from the clan's branches, often one your profession can't learn otherwise;
  - **a passive** (a sign effect kind, kept on the card, not in a sign slot);
  - sometimes **a die** your profession can now use.
- It **isn't a title**: titles stay as they are.

**Structure**
- **One card per subclan, filtered by profession.** Each subclan writes cards for the professions it fits, about 2 per subclan, so about 3 cards per profession × clan.
  - Warrior × Penitents can be offered Penitent Knight (Spire-Fallen) or Ember Warden (Ember Sisters).
  - Rogue × Penitents gets Relic Thief (Reliquary Thieves).
- **Offered by the subclans you are friends with.** A subclan becomes a friend as today, through the world (table below). Once you're Trusted with its clan, that friend's card can come up in an offer, as a gift of a new kind, `card`.
- **Held in a small deck; one card is worn** (two at Sworn). You change the worn card at the camp, free between chapters. A card you were given stays in your deck even if you change clans.
- **A card is lost** only if its clan becomes your nemesis: that clan's cards go grey until you reconcile.

**Worked examples** (a profession and clan pair gives each card):

| Clan | Card (subclan) | Profession | What it gives |
|---|---|---|---|
| Dominion | **Knight of the Flame** (Order) | Warrior | Execute (Vanguard); steady keyword on Attack; companions start with 5 block |
| | **Inquisitor** (Inquisition) | Mage | Fireball; spells inflict weaken; the Writ cancels one blow a fight |
| | **Lantern Cantor** (Cantors) | Cleric | Smite; mend the party 10% when you heal |
| Vigil | **Wall Veteran** (Last Watch) | Warrior | Warcry; see intents a round ahead; +10% party health |
| | **Ossuary Warden** (Candlebearers) | Cleric | Second Chance; Light on Attack faces |
| | **Stitcher** (Stitchers) | Rogue | Umbral Veil (voidkin); a shield when you heal |
| Compact | **Stonebreaker** (Quarrymen) | Warrior | Shield Bash stuns longer; breaks one guard a fight; +2 armour |
| | **Trapwright** (Scaffolders) | Ranger | Trap Set; thorns 3 |
| | **Ember Adept** (Emberwives) | Mage | Forgeheart (dwarf); +15% spell damage with Fire |
| Mire | **Fever Blade** (Barkbleeders) | Rogue | Poison Blade; poison lasts 1 turn longer |
| | **Fen Guide** (Heron's Wake) | Ranger | Beast Bond; +5% dodge; +1 to road checks |
| | **Moss Singer** (Moss Choir) | Cleric | Mending Touch; potions +15% |
| Crows | **Ledger Knife** (Whisper Ledger) | Rogue | Shadow Clone; each hit steals gold |
| | **Brig Marksman** (Brig-Born) | Ranger | Multi-Shot; +15% ship guns |
| | **Vault Arcanist** (Keyholders) | Mage | Teleport Strike; 10% lifesteal |
| Penitents | **Penitent Knight** (Spire-Fallen), the holy warrior | Warrior | Second Chance and Purify; heal 10% after each fight; the Ember face |
| | **Ember Sister** (Ember Sisters) | Cleric | Revive Prayer; cleanse on heal |
| | **Ash Chorister** (Scorched Choir) | Mage | Mana Shield; mana on hit |

**Minor patrons' cards** (aside, one per profession at most):
- Pit + Warrior: **Dark Knight** (lifesteal, harder hits when low, a pact).
- Choir + Warrior: **Paladin** (a vow, Light, a party shield).

**How subclans become your friends** (the world, as today; this is where each card can later come from):

| Clan | Subclan | Becomes your friend through |
|---|---|---|
| Dominion | Inquisition | the *hooded_lantern* intrigue |
|  | Order | defeating a Challenger (the Order's mark) |
|  | Tribunal | the *broken_charter* intrigue |
|  | Admiralty | z_white_fleet_grave cleared |
|  | Reliquary | a Shroud piece found |
|  | Wickwardens | Candlehold's lantern hall (story) |
|  | Salt Ledger | the *double_ledger* intrigue |
|  | Cantors | the *dying_lantern_bearer* intrigue |
| Vigil | Candlebearers | z_ossuary_galleries cleared |
|  | Stitchers | z_shroud_vigil cleared |
|  | Last Watch | the *unwatched_hour* intrigue |
| Compact | Quarrymen | z_frost_quarry cleared |
|  | Scaffolders | z_scaffold_yards cleared |
|  | Emberwives | z_ember_run delivered |
|  | Anvil-Deaf | Hammersmith built |
| Mire | Barkbleeders | z_fever_bark delivered |
|  | Heron's Wake | z_changeling_fen cleared |
|  | Returned | the *the_returned* intrigue |
|  | Moss Choir | z_bell_road escorted |
| Crows | Keyholders | Smugglers' Cellar built |
|  | Tar-Hands | Harbor built |
|  | Brig-Born | a boarding won at sea |
|  | Whisper Ledger | the *admiraltys_silence* intrigue |
|  | Drowned Debt | z_lantern_docks cleared |
| Penitents | Scorched Choir | z_cinder_row cleared |
|  | Road Exorcists | z_exorcists_road cleared |
|  | Reliquary Thieves | the *relic_road* intrigue |
|  | Spire-Fallen | the Spire (story) |
|  | Ember Sisters | z_glass_strand cleared |
| Open Hand | Fishbasket Line | the Open Hand's last stage |

**Data:** about 3 cards per profession × clan, so about 90 cards. Names and lines **[N]**; the numbers, from existing skills and effect kinds, are Core's. **[UX]**: the card, the deck, wearing one at the camp.

## Kept from v2.1, secondary

These parts stand as they were. The new parts tie in like this:
- your **patron** for the passive stats is the clan you stand best with;
- cards need **Trusted**;
- a **nemesis** stops the passive stats and greys its cards;
- clan **power** rises as you take its offers and cards.

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

### The Open Hand, and the Choir and the Pit
- **The Open Hand** is your own clan. It is raised by the banner and heritage recovery the story already tells. Once raised, it is a seventh main clan: its passive is your strongest stat, and its cards are any subclan card you have already been offered (your own hand).
- **The Choir and the Pit** keep their vows and pacts, aside, as minor patrons; each can offer one card per profession.
- **Alignment** stays parallel; clans only nudge it, as gifts do now.

## Order of work (once the user validates the six playstyles)

1. **The lean:** offer weights toward each clan's branches; its signs and objects carried on its stats; a per-clan simulator report (the table above, kept as a test).
2. **Patron passive stats per level.**
3. **Cards:** the gift kind, the deck, wearing at the camp. The first 18 cards are the worked examples above; Narrative writes the rest.
4. Power, territory and the nemesis (v2.1), afterwards.

## Open questions for the user

1. **The six playstyles:** do the Line, the Watch, the Anvil, the Venom, the Knife and the Ash read as six different ways to play? Swap any lean you'd rather see.
2. **Passive stats:** +1 at Friendly, +2 at Trusted, +5 health at Sworn, one patron at a time. More, less, or other stats?
3. **Cards:** one card worn (two at Sworn), changed freely at the camp. And should the minor patrons (Pit, Choir) offer a card too, for the dark knight and the paladin?
