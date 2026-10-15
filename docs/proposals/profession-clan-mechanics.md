# Professions and clans, v5.2: the profession plays, the clans specialise it (Core, proposal)

**v5.2** answers your two answers on v5.1:
- **Fight length:** *"propose multiple and diverse mechanics to fix it. Can depend on the location, enemies etc."* The single Tide gives way to **a menu of fight-length mechanics tied to the world**: a small default for every fight, plus variants by place and by enemy. The Tide stays as the fallback (see *Fight length: a menu tied to the world*).
- **Specialisations:** *"Specialisation can also be on the main clan too."* **The main clan offers its specialisation, and its friendly subclans offer variants and upgrades of it** (see *Where a specialisation comes from*). Their strengths are tuned toward +3 to +6 over the core, and the ones outside that range are flagged.

**v5.1** answered your feedback on v5:

- **Rogue:** *"I would rather have a mechanism around critical hits or more hits per turn, and specialisation in poison or others."* The core is now **Flurry**: every strike hits twice, and each hit rolls its own critical. The Rot becomes the Mire's specialisation. The crit chain becomes the Crows'.
- **Cleric:** *"Find a compensation."* The cleric won 74% of fights today and 77–81% with the Watchfire, in 39-round fights. The Watchfire now has a real cost: **no more self-healing, and healing spells heal 40% less**. In return, every heal from the die also burns the enemy. That brings it to 57% and 28 rounds. **With the Tide the cost isn't needed:** the Tide alone is the compensation (see below).
- **Warrior:** *"The berserk should be a spec; find a main mechanism that could be related."* The core is now **Fury**: built by hitting and by being hit, and spent on a heavy blow. Blood Price becomes the Crows' **Berserker**, where life pays for Fury. Thorn-wall and Holy warrior grow out of Fury too.
- **Weak links:** *"The more you are enemy with a clan, the less bonus you might receive from them."* What a clan gives now scales with **your standing × the clan's link to your profession** (see *Standing and link*).
- **Still open:** the Tide, and how strong a specialisation should be.

The rest of v5 stands:
- the profession owns the core mechanic, and clans specialise it through today's offers, which accumulate;
- the affinity table;
- the passive stats per clan level;
- subclan gifts as clan offers;
- power, territory and the nemesis;
- the Pit, the Choir and the Open Hand as minor directions.

Proposal only; nothing is built. **[N]** marks Narrative's part, **[UX]** UX's.

## At a glance

| Profession | Core mechanic | Specialisation 1 | Specialisation 2 | Specialisation 3 | Minor direction |
|---|---|---|---|---|---|
| **Warrior** | **Fury**: each hit you land or take adds 1 Fury; at 5, your next strike is a **heavy blow** (×2.5) that spends it | **Berserker** (Crows): Attack faces are Pain strikes, and the life you pay feeds Fury | **Thorn-wall** (Compact): blows your guard stops feed Fury, and half of them go back; no dodge | **Holy warrior** (Dominion): the heavy blow is Fire and Pierces, and heals you a tenth of it against Evil | **Dark knight** (Pit): spells paid in blood feed Fury |
| **Cleric** | **The Watchfire**: every heal from the die also burns the enemy for its amount; healing past full burns double at the round's end. The cost (if there is no Tide): healing spells heal 40% less | **Long Vigil** (Vigil): 2% self-healing each round while above half | **Ember Sister** (Penitents): the fire also gives 1 mana and cleanses | **Lantern Cantor** (Dominion): the fire holds your whole max health and burns every enemy | **Paladin** (Choir): the Vow |
| **Mage** | **The Ash Well**: mana from Mana faces only, starting at 0; Mana faces give double; spells cost 1 less; mana left heals | **Inquisitor** (Dominion): mana past full burns the enemy | **Ash Chorister** (Penitents): a spell from a full Well hits +50% | **Storm Arcanist** (Crows): spells steal life; Teleport Strike | **Blood mage** (Pit): Clause in Blood |
| **Rogue** | **Flurry**: every strike hits twice at 60%, each hit rolling its own critical | **Fever Blade** (Mire): a critical hit leaves a lasting, stacking poison (the Rot) | **Ledger Knife** (Crows): each hit that isn't critical raises the next one's chance by 15%; criticals hit double | **Relic Thief** (Penitents): each critical gives you 1 mana | — |
| **Ranger** | **The Trail** (the die as a deck): each face comes up once before any repeats; you see the next face; the sixth, the Verdict, counts half again | **Trapwright** (Compact): the Verdict is a trap that stuns | **Fen Guide** (Mire): first draws poison | **Corsair Marksman** (Crows): the Verdict doubles and Pierces | — |

## Why each mechanic fits its profession

| Profession | Mechanic | Why it fits |
|---|---|---|
| Warrior | Fury | The warrior gets stronger the longer the melee lasts: every blow given or taken builds to a heavy blow. Each clan bends it: the berserk pays life to fill it, the thorn-wall fills it by blocking, the holy warrior sets it alight. Warriors are the weakest profession today (37% of fights won); Fury lifts them to 58%. |
| Cleric | The Watchfire | Healing is the cleric's way of fighting: every heal also burns. The 40% cut on healing spells is the price, since spells are where the cleric's endless sustain came from. |
| Mage | The Ash Well | Mana from the die alone, your Slice & Dice example. The mage already lives on Mana faces and Channel. |
| Rogue | Flurry | Many quick hits and critical strikes, as you asked. Two hits per strike also double every on-hit effect (poison, lifesteal, mana on hit), so poison and the other specialisations grow from it. |
| Ranger | The Trail | A hunter reads what comes: the die becomes a trail you can see one step ahead, for aimed shots and traps set in advance. Before v5, Dominion held it as the Writ of Order. |

## Measured: each profession's core and one specialisation

**Setup:**
- 200 seeded runs per line, 40 per profession, random strategy. Each profession plays only its own mechanic.
- The mechanics were added through a temporary patch of the fight simulator, kept in the Core session's scratchpad as `v51_sim.patch` and never committed.
- The autoplay doesn't rebuild its die for a mechanic, so the numbers show a player who doesn't adapt.

| Profession | Today: win / rounds | Core: win / rounds | Specialisation measured: win / rounds | With the Tide: today → core → specialisation |
|---|---|---|---|---|
| Warrior | 37.0% / 14.2 | **Fury 58.2% / 12.5** | Berserker 58.6% / **8.2**; Thorn-wall 63.8% / 9.2 | 41.7% → 60.9% → 64.3% (Berserker), 65.8% (Thorn-wall), 7–10 rounds |
| Cleric | 73.7% / **38.8** | **Watchfire with its cost 56.7% / 28.0** | Long Vigil 68.3% / 30.5 | 52.0% → **55.4% / 16.4** (Watchfire *without* the cost) |
| Mage | 63.0% / 8.3 | Ash Well 65.8% / 8.2 | Inquisitor 66.0% / 8.1 | 62.1% → 62.1% → 63.7% |
| Rogue | 48.7% / 13.1 | **Flurry 61.2% / 12.2** | Fever Blade 68.3% / 11.1 | 57.2% → 68.6% → 73.0%, about 9.5 rounds |
| Ranger | 53.8% / 13.5 | Trail 63.8% / 12.5 | Corsair 71.0% / 12.2 | 59.8% → 68.1% → 72.6% |

**Options measured but not chosen:**

| Profession | Option | Win / rounds | Why not |
|---|---|---|---|
| Warrior | **Momentum**: consecutive damaging faces build +15% each, up to +60%, reset by a non-damage face | 53.3% / 13.0 | Weaker, and a Defend face breaks it, which punishes guarding |
| Warrior | Fury at 4 for ×2 | 52.1% | — |
| Rogue | **Crit chain** as the core: +10% crit chance per hit that isn't critical | 52.3% | Barely felt |
| Rogue | Crit chain at +15% with criticals ×2 | 60.8% / 12.2 | Kept as the Crows' specialisation |
| Rogue | Flurry at 70% per hit | 68.6% | Too strong |
| Cleric | Watchfire with self-healing (v5) | 77.1% / 39.1 | Too strong, too long |
| Cleric | Healing spells ×0.5 | 42–45% / 25–26 | Too weak |
| Cleric | Healing spells ×0.7, heals burn | 64.2% / 30.7 | Still high |

**The cleric and the Tide.** The two compensations don't stack well:
- **Without the Tide:** the Watchfire needs its cost (healing spells −40%) to bring the cleric to 57%.
- **With the Tide:** the Tide alone takes the cleric from 74% to 52%, because a slow killer suffers most when blows grow. Adding the cost on top drops it to 39%, which is too low.
- **Proposal: if the Tide is adopted, the Watchfire keeps no cost** (55.4% / 16.4 rounds). If not, it takes the −40%.

What the numbers show:
- **Without the Tide:** warrior 58, cleric 57, mage 66, rogue 61, ranger 64. Today's spread is 37 points (37–74); now it is **9 points**.
- **With the Tide:** cleric 55, mage 62, warrior 61, ranger 68, rogue 69, a spread of **14 points**. The rogue's and ranger's cores are then the strongest, with suggested trims: Flurry at 55% per hit, and a Verdict of ×1.25 for the Trail.
- **Fights:** every core but the cleric's runs 8 to 12.5 rounds. The cleric's falls from 39 to 28 rounds with the cost, and to 16 with the Tide.

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
| **Cleric** | ●● Lantern Cantor | ●● Long Vigil | ○ | ● Moss Singer | ○ | ●● Ember Sister |
| **Mage** | ●● Inquisitor | ○ | ● Ember Adept | ● Hex-Weaver | ●● Storm Arcanist | ●● Ash Chorister |
| **Rogue** | ○ | ● Stitcher | ● Tar Snare | ●● Fever Blade | ●● Ledger Knife | ●● Relic Thief |
| **Ranger** | ● Admiralty Gunner | ○ | ●● Trapwright | ●● Fen Guide | ●● Corsair Marksman | ○ |

Notes on the table:
- **Warrior and Crows.** The Crows don't sponsor a warrior branch today. The berserker comes from your own example, and the Crows already lend low-health damage and lifesteal signs. Vigil's Warlord sponsorship makes it the weaker warrior link.

## Standing and link: what a clan gives you

*"The more you are enemy with a clan, the less bonus you might receive from them."* What a clan gives depends on two things:
- **its link to your profession,** set by the affinity table:
  - ●● natural link: 1;
  - ● weak link: ½;
  - ○ no link: 0, so it offers no twist, only its ordinary gifts;
- **your standing with it,** which is today's standing tiers (factions.dart `StandingTier`).

**Offer rate = link × standing factor.** It sets how often the clan's suitor brings one of your profession's twists.

**Gift strength** is set by your standing:

| Your standing | Standing factor | What the clan gives |
|---|---|---|
| Hunted (nemesis) | 0 | Nothing. Its twists you hold **sleep**; its fighters hunt you |
| Hostile, Resented | 0 | Nothing: no offers, no passive. Twists you hold work at half |
| Unfriendly, Wary | ¼ | Ordinary gifts, rarely; no twists |
| Unknown, Known | ½ | Ordinary gifts, as today |
| Friendly, Friend | 1 | Ordinary gifts at the full rate; +1 to its first stat each level |
| **Trusted** | 1¼ | **Its twists for your profession open, at rank I**; +1 to its second stat each level |
| **Sworn** | 1½ | **Rank II** (+50%) for twists you hold that come back, and its rare second twists; +5 max health each level |

**Examples:**
- A warrior **Trusted** with the Crows (natural link): 1 × 1¼, the Berserker comes often.
- The same warrior **Trusted** with the Vigil (weak link): ½ × 1¼, the Wall Veteran comes now and then, and never rises past rank I.
- **Wary** with the Compact: no Thorn-wall at all.
- If the Compact turns **Hostile**, the Thorn-wall twists you hold work at half. If it becomes your **nemesis**, they go quiet.

**So:**
- standing decides *whether* and *how strongly* a clan gives;
- the link decides *how often* it gives to your profession;
- a weak link never reaches rank II.

## Loyalty has a price: the rivals cool

You asked: *"The more you are linked to a unique clan, the more malus you may receive from others to compensate."*

**The malus follows the relations map** (relations.json, steps 1 to 7). Every clan does not cool at once:
- your patron's **rivals** (Blood feud, War, Hostile: steps 1–3) grow colder;
- its **tense** neighbours (step 4) cool a little;
- its **allies** (Trade, Allies: steps 6–7) warm slightly;
- the rest (step 5) don't move.

**What exists today.** factions.dart already does part of this:
- a gain with a clan costs each of its rivals half of it (`rivalRippleShare`), and its allies share a quarter (`allyRippleShare`);
- swearing costs each rival 20, once (`swornRivalCost`), and keeps them at the top of Known while you're Sworn (`swornRivalCap`).

v5.1 adds what makes loyalty *deepen* the cost over time.

**The drift, each chapter you end with your patron at:**

| Your patron | Its rivals (1–3) | Tense (4) | Allies (6–7) |
|---|---|---|---|
| Friendly | nothing | nothing | nothing |
| Trusted | −2 | nothing | nothing |
| Sworn | −4 | −2 | +1 |

**The maluses are social and economic, never stat cuts:**
- **Their standing falls.** That brings the rest along through tiers that already exist:
  - shops charge more (Wary ×1.15, Hostile ×1.40, none at Hunted);
  - offers come less often, then not at all (the standing × link rule above).
- **Their twists you hold weaken.** At Hostile they work at half (standing × link).
- **Their hunters, at Sworn.** A rival at Hostile or below sends hunters onto the roads, through the hunter ambush system that alignment hunters already use:
  - 4% a road step per Hostile rival, 8% at Hunted;
  - capped at the alignment hunters' 15%.
- **No combat penalty.** Committing to one clan never makes you weaker in a fight; it makes the world around you colder.

**Shown where you'd look for it:** a line on the clan tab and the radar, such as *"Dominion's favour cools the Crows (−4 this chapter)"* **[UX]**, with the words by **[N]**.

**Tie to power and the nemesis.** A rival that keeps cooling toward you is the natural nemesis candidate (see *Neglect and the nemesis*). When a rival reaches Hunted through drift, it is the clan that can become your nemesis, and its champion the one that hunts you.

### What a fully loyal run costs

**The loyal run assumed:** Trusted with the patron in chapter 3, Sworn in chapter 5, eight chapters, every rival starting near 0. Today's ripple and the swearing cost already take each rival to about −50 (Hostile). The drift adds 2 × 2 + 4 × 4 = **−20 more by the end: Hunted (−70)**. Tense neighbours end at about −8 (Wary).

| Patron | Rivals by the end (Hunted) | Tense (Wary) | Warming allies | What it costs |
|---|---|---|---|---|
| **Dominion** | Vigil, Mire, Penitents | Compact | Crows | **Three clans closed:** no shops, offers or twists from half the map, and hunters from three directions |
| **Penitents** | Dominion, Compact, Mire | — | Vigil | Three clans closed |
| **Vigil** | Dominion, Crows | — | Compact, Penitents | Two |
| **Mire** | Dominion, Penitents | — | Compact | Two |
| **Compact** | Penitents | Dominion | Vigil, Mire | One, and a Wary Dominion |
| **Crows** | Vigil | — | Dominion | One |

**In numbers, for a Dominion loyalist:**
- **About half the offer pool is gone** by chapter 6: three of the six clans give nothing.
- **Shopping in their towns is shut.**
- **On the roads, hunters reach about 15% a step** in the last chapters (the cap).

A Crows loyalist pays a sixth of that. **The asymmetry is the relations map's**, and it makes the choice of patron a choice of enemies too. A player who wants an easy road picks the Crows; one who wants the Dominion's Fire pays for it.

**Not simulated:** the simulator's politics doesn't run the chapter drift or road hunters yet. The numbers above follow from today's ripple constants and the tier table.

## Where a specialisation comes from: the main clan, then its subclans

*"Specialisation can also be on the main clan too."* Read this way:
- **The main clan offers the specialisation itself.** The Crows offer the warrior **Berserker**. This is the clan's own gift, offered once you are a **Friend** (19+), the tier before Trusted.
- **Its friendly subclans offer variants and upgrades of it,** from **Trusted**:
  - a **variant** changes how the specialisation works (Tar-Hands: the life cost becomes a bleed on the enemy);
  - an **upgrade** raises its number (Brig-Born: a kill heals 10%).
  - Subclan gifts need the main specialisation first: they bend it, they don't replace it.
- **At Sworn,** the main specialisation can rise to rank II, and the subclans' rarer second gifts open.
- **Confirmed by you:** *"Yes that's what I meant."*

| Profession | Main clan | Main specialisation (from Friend) | Subclan variants and upgrades (from Trusted) |
|---|---|---|---|
| Warrior | Crows | **Berserker**: Pain strikes feed Fury | Tar-Hands: the cost bleeds the enemy · Brig-Born: a kill heals 10% |
| Warrior | Compact | **Thorn-wall**: stopped blows feed Fury, a third goes back | Quarrymen: a blow sent back breaks the guard · Anvil-Deaf: half goes back, no Heal faces |
| Warrior | Dominion | **Holy warrior**: the heavy blow is Fire and Pierces | Order: it heals a tenth against Evil · Inquisition: it weakens |
| Cleric | Vigil | **Long Vigil**: 1% self-heal a round above half | Candlebearers: 2% · Last Watch: Defend faces feed the fire |
| Cleric | Penitents | **Ember Sister**: the fire gives mana and cleanses | Ember Sisters: two afflictions · Road Exorcists: the burn is Light |
| Cleric | Dominion | **Lantern Cantor**: the fire holds your whole max health and burns every foe | Cantors: +25% burn · Wickwardens: the fire lasts a round longer |
| Mage | Dominion | **Inquisitor**: mana past full burns the foe | Inquisition: the burn weakens · Tribunal: once a fight, refill the Well |
| Mage | Penitents | **Ash Chorister**: a spell from a full Well hits +50% | Scorched Choir: +75% · Spire-Fallen: the spell also heals |
| Mage | Crows | **Storm Arcanist**: spells steal 10% as health | Keyholders: Teleport Strike · Whisper Ledger: spells steal gold |
| Rogue | Mire | **Fever Blade**: criticals leave a stacking Rot (6%) | Barkbleeders: the Rot passes on · Moss Choir: the Rot heals you a fifth |
| Rogue | Crows | **Ledger Knife**: the crit chain (+15% a miss, crits ×2) | Whisper Ledger: crits steal gold · Drowned Debt: a crit refunds the chain |
| Rogue | Penitents | **Relic Thief**: each critical gives 1 mana | Reliquary Thieves: 2 mana · Ember Sisters: the mana heals |
| Ranger | Crows | **Corsair Marksman**: the Verdict (the sixth face) counts double and Pierces | Brig-Born: ship guns +15% · Drowned Debt: a kill reshuffles the deck |
| Ranger | Compact | **Trapwright**: the Verdict stuns | Scaffolders: it stuns two · Quarrymen: it breaks the guard |
| Ranger | Mire | **Fen Guide**: the first face of each run poisons | Heron's Wake: and slows · Returned: and you see two faces ahead |

**The minor directions work the same way:**
- the Pit offers the **Dark knight** (warrior) and the **Blood mage** (mage);
- the Choir offers the **Paladin** (warrior, cleric);
- they have no subclans.

**The Open Hand** offers again any main specialisation you passed on.

**Weak links** (● in the affinity table) offer only the subclan *upgrades* to specialisations you already hold, never a main one. **○** offers none.

### How strong: tuned toward +3 to +6 over the core

Measured under the recommended combination (default plus Tide), against each profession's core:

| Specialisation | Over its core | Status |
|---|---|---|
| Warrior · Berserker (Pain strikes feed Fury) | **+4.3** (72.3% / 6.6 rounds) | in range |
| Warrior · Thorn-wall at a third back | **+2.7** | at the low edge. Suggested: a quarter to a third back (half back was +10.3, too strong) |
| Cleric · Long Vigil at 1% | **+3.0** | in range (2% was +7.2, too strong) |
| Rogue · Fever Blade, Rot at 6% | **+4.2** | in range |
| Ranger · Corsair, Verdict ×2 | +2.2 (×1.75: +0.4) | **below range.** The Trail's core is already too strong (above); once the core is trimmed, the Verdict becomes this gift's whole value. Estimate: +5 |
| Mage · Inquisitor (surplus mana burns) | +0.9 | **below range.** The autoplay's mage rarely fills the Well (one Mana face). Suggested: burn your full strike per point; estimate +4 for a mage who builds two Mana faces |
| Holy warrior, Ember Sister, Lantern Cantor, Ash Chorister, Storm Arcanist, Ledger Knife, Relic Thief, Trapwright, Fen Guide | not simulated | numbers set to the same size by design, to be measured once built |

## How a specialisation arrives: the clan's offers

- **Main and subclan gifts are clan offers.** The main specialisation comes from **Friend**, its subclans' variants and upgrades from **Trusted** (when the subclan is your friend, v3's table). Both are filtered by **your profession**. You pick one like any gift, and it stays for the run.
- **Specialisations stack.** A warrior can be Crows-Berserker and Compact-Thorn-wall at once: Fury fed both by the life you pay and by the blows you stop. Mixing is a build, not a mistake.
- **Stacking stays in check without slots:**
  1. Each gift twists a different part of the mechanic (its trigger, its payoff, or its cost).
  2. The mechanic's caps stay, and no gift lifts them:
     - Fury tops out at 5 and spends all of it;
     - Pain never takes the last point;
     - the Rot adds at most 10% per critical hit;
     - Flurry is two hits, never more;
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

### Warrior: Fury
- **Core.**
  - Each hit you land, and each blow that gets through to you, adds 1 **Fury**.
  - At 5 Fury, your next damaging face is a **heavy blow**: it deals ×2.5 and spends all of it.
  - The fight screen shows five notches beside your health **[UX]**.
  - Measured: 58.2% / 12.5 rounds (from 37%); with the Tide, 60.9% / 9.8.
- **Why you build differently.** Many hitting faces fill Fury fast. Defend faces still fill it when blows get through, so guarding never wastes it. A heavy skill (Execute, Berserk Rage) on the heavy blow is the payoff.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twist | Measured |
  |---|---|---|---|
  | **Crows** (Brig-Born, Tar-Hands) | **Berserker** | Attack faces become Pain strikes (double, 8% of your max health), and the life you pay adds 1 Fury. Rank II: below half health, the heavy blow is ×3 | 58.6% / **8.2 rounds**, and 64.3% with the Tide |
  | **Compact** (Quarrymen, Anvil-Deaf) | **Thorn-wall** | Blows your block and armour stop add Fury, and half of what they stop goes back; you can't dodge | 63.8% / 9.2, and 65.8% with the Tide |
  | **Dominion** (Order) | **Holy warrior** | The heavy blow is Fire and Pierces, and heals you a tenth of its damage against an Evil foe | not run |

- **Weaker links:**
  - Vigil, Wall Veteran: a Defend face adds 1 Fury.
  - Penitents, Ash Penitent: a Mana face adds 1 Fury.
- **Minor direction:** the Pit, **Dark knight**: spells can be paid in blood, and the blood paid adds Fury.

### Cleric: the Watchfire
- **Core.**
  - **Every heal from your die** (a Heal face, a heal skill) **also burns the enemy for its amount.**
  - Healing past full feeds the Watchfire, up to half your max health. Enemy blows hit it first, and what's left at the round's end burns the enemy for double.
  - **The cost:** no self-healing any more (v5's 2% a round is gone), and **if there is no Tide**, healing spells heal 40% less. The fire takes its share.
- **Measured.**
  - With the cost: 56.7% / 28.0 rounds (from 73.7% / 38.8).
  - Without the cost but with the Tide: 55.4% / 16.4.
- **Why you build differently.** Heal faces become your damage, so you want them on the die, not only on spells. The spells keep you alive, but no longer forever.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twist | Measured |
  |---|---|---|---|
  | **Vigil** (Candlebearers) | **Long Vigil** | The self-healing comes back: 2% of your max health each round while above half | 68.3% / 30.5 with the cost |
  | **Penitents** (Ember Sisters) | **Ember Sister** | When the fire burns, it also gives 1 mana and cleanses one affliction | not run |
  | **Dominion** (Cantors) | **Lantern Cantor** | The fire holds up to your whole max health and burns every enemy (Light) | not run |

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

### Rogue: Flurry
- **Core.**
  - Every damaging face strikes **twice, at 60% each**, and each hit rolls its own critical (Luck, as today).
  - Every on-hit effect counts twice: mana on hit, lifesteal, a sign's status, a poison.
  - Measured: 61.2% / 12.2 rounds (from 48.7%); with the Tide, 68.6% / 9.8.
  - **Suggested:** 55% per hit if the Tide is adopted.
- **Why you build differently.** Luck, critical chance and on-hit gear are worth twice as much. Two small hits beat one big one against armour-less foes, and lose to heavy armour. That gives Pierce a reason to exist.
- **Main specialisations:**

  | Clan (subclan) | Specialisation | Twist | Measured |
  |---|---|---|---|
  | **Mire** (Barkbleeders) | **Fever Blade** (poison) | A critical hit leaves a lasting, stacking poison (the Rot: 10% of the hit, every turn, all fight). Rank II: when a poisoned enemy falls, its poison passes to the next | 68.3% / 11.1, and 73.0% with the Tide |
  | **Crows** (Whisper Ledger) | **Ledger Knife** (crits) | Each hit that isn't critical raises the next one's chance by 15%; a critical resets it and hits for double | measured as a core: 60.8% / 12.2 |
  | **Penitents** (Reliquary Thieves) | **Relic Thief** | Each critical gives you 1 mana (Smoke Bomb, Quick Pockets) | not run |

- **Weaker links:**
  - Vigil, Stitcher: healing past full becomes a hit.
  - Compact, Tar Snare: the second hit of a strike slows (weaken).

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

## Fight length: a menu tied to the world

**The problem, measured today** (200 runs per line):
- **Clerics' fights last 38.8 rounds**: their healing spells outlast everything.
- Everyone else fights 8 to 14 rounds.
- Chapter 7 averages 30 rounds; bosses 18.

You asked for several mechanics, depending on the place and the enemy, so fights feel different from one place to the next while staying near 10 to 12 rounds. They build on what exists:
- **fight stages and field anomalies** (field_anomaly.dart): 11 stages, 28 anomalies such as the sandstorm, the racing tide, the collapse, the marsh lights. They already break over a fight for a few rounds;
- **the enemies' data:** bosses and their phases, factions, biomes;
- **the clash rules:** the rout and subdue goals, squads with a captain;
- **standing and alignment.**

### The menu

**Measured** = the mechanic alone, in every fight, against today. Each cell is cleric win% / rounds, then the other four professions.

| Mechanic | What it does | Where it applies | On screen **[UX]** | Measured: cleric · others |
|---|---|---|---|---|
| **Healing fatigue** | Each heal in a fight heals 5% less than the one before (never under 30%) | Every fight | The heal number dims, with a small "weary" mark after the third heal | 5%: cleric 41% / 27.8 · others ±2, unchanged length. 10%: cleric 37.5% / 21.2 |
| **Execute** | Any damaging face finishes an enemy under 10–15% of its health | Every fight | The enemy's bar shows a red line at the threshold | 15%: cleric 83.5% / 32.9 · others +5 to +11, −0.5 to −1.5 rounds |
| **Morale** | A hurt foe (under 25%) that isn't a boss may flee: the fight is won, with no loot from it. Sparing or cutting down the fleeing is an alignment choice **[N]** | Fights against people and beasts; never undead, constructs or bosses | "Wavering" over the foe | cleric 76.7% / 37.0 · others +3 to +4, −0.5 to −1 round |
| **The pack breaks** | When a pack's leader (the captain, as in the rout goal) falls, each other member flees at 70% | Packs | The captain's crown; "the pack breaks" | small alone: +1 to +4, about −1 round on pack fights |
| **Boss enrage** | From round 10, a boss hits 50% harder | Bosses | A boss's phase bar turns red at round 8: a warning | cleric 52.4% / 31.0 · others −2 to −6 |
| **Rising ground** (the field anomalies made to escalate) | From round 6 the place itself turns on both sides, and grows each round: | By stage | The anomaly's omen, then its gauge rising | (see each) |
|   · **marsh mist** (reeds) | Poison on both sides, 3% of max health a round | Reeds, fens | Green haze | cleric **92.5%** / 20.7 · others +0 to +4, −2 to −3 rounds |
|   · **desert heat** (dunes, salt flats) | Both sides lose 2% a round; healing −20% | Dunes, salt flats | Heat shimmer | estimate: like the mist, but cuts healing too, so clerics gain less |
|   · **rising tide / collapse** (waves, cliffs, halls) | Both sides hit +10% a round | Shores, ruins, halls | Water rising / dust falling | measured as the Tide at +20% for both: 46.8% win overall, 10.4 rounds; clerics lose most |
|   · **sanctified ground** (shrines) | Healing fades 10% a round; Light strikes +10% a round | Shrines, chapels | Candles guttering | estimate: the cleric's hardest ground |
| **Reinforcements** | From round 8, allies arrive if your standing in the zone's holder is Friend or better (they deal 5% of the foe's health a round); **enemies arrive if you're hunted there** | Zones held by a clan (territory) | A banner at the edge of the field | allies: cleric 98% / 18.1 · others +5 to +21, −2 to −3 rounds. Hostile reinforcements: the reverse, not measured |
| **Town guards** | In a city, from round 6, the watch breaks the fight up. You win if you were ahead on health, otherwise both sides walk away (no loot) | City districts | The watch's whistle | not simulated (the simulator has no cities) |
| **Beasts tire / the dead crumble** | Beasts hit 5% softer each round from round 6; undead lose 3% of their health a round | By foe | "Panting" / "crumbling" | not measured as such: undead crumbling works like the mist on one side |
| **The Tide** (fallback) | From round 8, your blows +20% a round, the enemies' +10% | Fights with none of the above | A wave mark by the round count | cleric 52% / 17.2 · others about +0 to +6, 10.4 to 10.8 rounds |

**Cut, as weak:**
- **exhaustion against adrenaline:** it overlaps with the Tide and with Fury;
- **a flat 30-round cap:** a non-rule.

### Recommended combination

1. **Default, in every fight:**
   - healing fatigue at 5%;
   - execute at 10%;
   - morale;
   - the pack breaks.

   Small rules that each read clearly and cut the long tail.
2. **One context rule by place or foe:**
   - rising ground by stage (mist, heat, tide or collapse, sanctified);
   - boss enrage for bosses;
   - reinforcements in held zones;
   - town guards in cities.
3. **The Tide**, only when no context rule applies (open country, a road with no anomaly).

**Measured with the default plus the Tide in every fight** (the case where no place rule applies):

| | Cleric | Mage | Ranger | Rogue | Warrior |
|---|---|---|---|---|---|
| Today | 73.7% / 38.8 | 63.0% / 8.3 | 53.8% / 13.5 | 48.7% / 13.1 | 37.0% / 14.2 |
| Default + Tide | 48.3% / **14.7** | 69.3% / 6.9 | 66.0% / 10.0 | 65.3% / 9.7 | 53.0% / 10.1 |
| Default + Tide + the five cores | 51.8% / **14.4** | 68.2% / 7.2 | **80.4%** / 9.3 | 68.8% / 9.2 | 68.0% / 9.0 |

- **Every profession runs 7 to 15 rounds.** The cleric falls from 39 rounds to 14.5: healing fatigue is the natural fix for its endless spells.
- **The cleric's cost now comes from the combination.** With healing fatigue in every fight, the Watchfire takes **no extra cost**: v5.1's −40% on healing spells is dropped.
  - The cleric's range depends on the place: 52% where the Tide applies, up to about 77% in the marshes (the mist favours a healer).
  - The default without the Tide gives 60.8% / 25.3 rounds.
- **Flagged:** the ranger's Trail is too strong under these rules (80%). Its deck gains most from the execute, because every face comes up in turn.
  - **Suggested:** the deck draws five of its six faces each run, one face sitting out at random. This is not measured; estimate about −8.
  - The Verdict is also dropped from the core; it moves to the Crows' specialisation.

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
     | Warrior | Execute, Berserk Rage, Whirlwind: the heavy blow wants a heavy skill |
     | Cleric | Heal faces, Iron Will, Mending Touch |
     | Mage | Channel, Mana Shield |
     | Rogue | Luck and crit gear, Backstab, Poison Blade |
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

1. **The fight-length default** (healing fatigue, execute, morale, the pack breaks) and **the Tide** as fallback, then the rising grounds by stage, boss enrage, reinforcements and town guards.
2. **The five core mechanics**, one per profession, with a committed per-profession simulator report.
3. **Free the mana face, and the skill verbs** (texts by **[N]**).
4. **Specialisation gifts** in the clans' offers: the 15 main ones first, then the weaker links, named by **[N]**. **[UX]**: how a gift shows the mechanic it bends.
5. **The passive stats per level.**
6. Power, territory and the nemesis, afterwards.

## Open questions for the user

1. **Fight length:**
   - the default (healing fatigue 5%, execute 10%, morale, the pack breaks);
   - one context rule by place or foe;
   - the Tide as fallback.

   Which mechanics do you like, and which feel wrong?
2. ~~Specialisations, main and sub~~: confirmed. The main clan offers the specialisation from Friend (19+); its friendly subclans offer variants and upgrades from Trusted (26+); rank II and the rarer gifts come at Sworn (61+).
3. **The ranger's Trail is too strong** under the new rules. Trim it: five of six faces drawn per run, and the Verdict moved to the Crows' gift?
4. **Still open from v5.1:** the cores' feel (Fury, Flurry, the Watchfire, now with no extra cost), standing × link, and the price of loyalty.
