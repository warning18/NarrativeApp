# Profession and clan mechanics: one main, three specs (Core, proposal)

The user's ask: *"propose specific mechanics (using the actual game mechanisms) for each profession/clan. Ideally 1 main that can specialize in 3 different sub specs."* This is a proposal only; nothing is built. Sizes: **S** a day, **M** a PR, **L** two or three PRs, **XL** a wave. **[Q]** marks a question for the user, **[N]** a name or text Narrative writes, **[UX]** a screen UX designs.

## What the game already has (and this builds on)

- **Professions are stat packages today.** professions.json gives bonuses, a standard skill, a caster's mana skill and spells, and a scaling stat. No code checks `== 'warrior'`: a profession only gates skills, dice, spells and offers.
- **Every profession already has three original skill branches**, and mastering one is called "the specialisation" in `skill_tree.dart` (`masteredBranchId`: all its skills known plus 2,000 essence for +1 tier). Seven later branches (storm, frost, dawn, tides, gale, skyhunter, stoneward) sit beside them.
- **The fight already has the pieces a class mechanic needs:**
  - a momentum meter that cashes into a guaranteed crit;
  - rerolls;
  - telegraphed enemy intents (`enemy_intent.dart`);
  - enemy guards and Curse faces on the player's die (`dice_tamper.dart`);
  - block, dodge, crit and the face keywords (cleave, pierce, growth, echo, pain, steady);
  - three statuses (poison, stun, weaken);
  - elements on faces and spells.
- **Every clan's sworn boon already carries one effect kind that only that clan has:**

  | Clan | Effect kind | Name |
  |---|---|---|
  | Dominion | `writFace` | the Writ |
  | Vigil | `intentLookahead` | Open Eyes |
  | Compact | `compactEdge` | the Edge |
  | Crows | `crowsPrice` | the Price |
  | Penitents | `emberFace` | the Ember face |
  | Mire | `poisonExtraTurns` | — |

  Those six are the clan mechanics in embryo.
- Standing (-100..100, eleven tiers), subclan marks (friend/foe), one sworn clan, titles with effects, signs with 48 effect kinds, and the training paths of v1.320.

So the plan reuses rather than invents:
- **a profession's three specs are its three original branches**, each with a signature mechanic bent three ways;
- **a clan's mechanic is its sworn effect kind**, growing with standing, bent by the subclan the player sides with.

## Summary

| Who | Main mechanic (one line) | Spec 1 | Spec 2 | Spec 3 | Size |
|---|---|---|---|---|---|
| **Warrior** | **Momentum** also fills when you take a hit or block | Bulwark: cash-out is a reflecting guard | Vanguard: cash-out is a cleaving crit | Warlord: cash-out rallies the party | M |
| **Mage** | **Resonance**: spells of one element in a row stack +damage | Evocation: at 3 stacks the spell hits every enemy | Tempest: each stack adds stun chance | Aegis: stacks turn into a mana shield | M |
| **Rogue** | **Exploit**: a foe not attacking this round, or poisoned or stunned, takes +crit | Shadow: first strike of a fight always exploits | Venom: poison always exploits, and lasts longer | Trickster: +1 reroll a round, and a crit steals gold | M |
| **Cleric** | **Grace**: healing past full health is kept as grace | Judgment: grace adds to your next strike | Devotion: grace mends the party, and revives once | Vigil: grace becomes block for the party | M |
| **Ranger** | **Quarry**: you mark one foe; it takes +damage and shows its intent a round early | Marksman: the mark pierces, and a multi-shot hits it twice | Trapper: a marked foe's first attack is snared (stun) | Wilds: +1 to road and expedition checks, and discoveries give double | M–L |
| **Dominion** | **Writ**: cancels N enemy attacks a fight | Inquisition: a cancelled attack weakens the foe | Order: a cancelled attack opens a counter | Admiralty: the Writ calms the sea (voyages) | M |
| **Vigil** | **Open Eyes**: see intents N rounds ahead | Candlebearers: +damage to the dead and the tear's things | Stitchers: blocking a foreseen attack heals | Last Watch: a foreseen attack gives the party block | M |
| **Compact** | **Edge**: breaks N enemy guards a fight | Quarrymen: a broken guard stuns | Emberwives: a broken guard takes fire | Anvil-Deaf: one more hone at the smithy | M |
| **Mire** | **Venom**: poison you inflict lasts N turns longer | Barkbleeders: poison hits harder | Heron's Wake: road and expedition guides (checks, days) | Moss Choir: poison ticks heal you | M |
| **Crows** | **Price**: each hit steals N gold | Keyholders: chests come one rarity better | Tar-Hands: the hull mends between voyages | Whisper Ledger: see an offer's gifts before you choose | M |
| **Penitents** | **Ember**: lifts N Curses from your die a fight | Scorched Choir: a lifted Curse heals | Road Exorcists: +damage to the tear's things, cleanses | Ember Sisters: the party heals after each fight | M |

**Picking a spec.**
- *Profession:* a "Calling" at **level 5**, three cards like the training offer, one per original branch. It can be changed at the Skillwright for essence.
- *Clan:* at **Trusted** standing, the clan asks which of its three voices you stand with. Changing sides is possible but costs standing with the voice you leave.

Details below.

## 1. Professions

### How the spec works (all five)

- **When:**
  - At level 5 the level-up brings a **Calling** after the training offer: three cards, one per original branch, with the spec's line and what it does to the main mechanic. **[UX]** reuses the training cards.
  - Taking one sets `specId` (the branch id). There is no "later", as with training.
  - Level 5 lands in chapter 2–3, once the player has seen the class play plain.
- **What it touches besides the mechanic:**
  - the spec's branch skills come up more in clan offers (offer weight ×2);
  - the training "calling" leans to the spec's paths;
  - mastering the spec's branch keeps the +1 tier.
  - **[Q]** should mastery be *limited* to the spec's branch (cleaner) or stay open to any branch (today's rule)?
- **Changing:** at the **Skillwright** (v1.319) for essence (e.g. 500). Skills known are kept; only the bend changes. **[Q]** free once, then paid?
- **The later branches** (storm, frost, dawn, tides, gale, skyhunter, stoneward) stay open to any spec, through offers, as today. **[Q]** or should each become a fourth spec later?
- **New data:** `specId` on the session; a `spec` block on each original branch in skill_trees.json (`mainBend` key and numbers, `line`, `line_fr` **[N]**).
- **Autoplay and simulator:** the simulator takes the spec of its build's stat (as it takes training today).
- **Balance check for all five:** the simulator's win rate per chapter, by profession × spec, against today's baseline. A spec must land within ±5 points of the others of its profession, and the main mechanic must add no more than about +8% to a chapter's win rate.

### Warrior: Momentum

- **Mechanic:** the momentum meter (today filled by your own hits and skills, cashed for a guaranteed crit) **also fills when you take a hit or block one**. The warrior is the class that gets stronger by standing in it.
- **Specs** (what the cash-out does):
  - **Bulwark:** cashing momentum raises a guard that **reflects** the next attack (`guardRetaliate` at 100% for one hit).
  - **Vanguard:** the cashed crit gets **cleave** (the face keyword): it hits every enemy.
  - **Warlord:** cashing momentum gives every companion +25% damage and 5 block for the round (`allyDamagePercent`, `partyStartBlock`, used live).
- **Example:** two goblins hit the Bulwark for 6 and 4, and the meter is full. Next round the warrior cashes it: a crit, and the next goblin blow comes back at the goblin.
- **Reuses:** `fight_dice_rules.dart` (momentum), the keywords, the sign effect kinds (applied by the spec instead of a sign).
- **New:** one momentum source (hits taken) and the three cash-out bends. **[UX]** the meter shows the spec's icon when full.
- **Size:** M.
- **Risk:** momentum from taking hits makes long fights snowball. Cap it at one cash-out a round, and simulate the boss fights of chapters 3, 5 and 7.

### Mage: Resonance

- **Mechanic:** casting spells **of the same element in a row** builds resonance: +15% spell damage per stack, up to 3. Another element resets it. It reuses spell elements and `spellDamagePercent`.
- **Specs:**
  - **Evocation:** at 3 stacks the next damaging spell **hits every enemy**.
  - **Tempest:** each stack adds 10% to stun the target (status `stun`, 1 turn); Ice and Electricity spells resonate together.
  - **Aegis:** stacks can be **spent as a mana shield** of 6 per stack (`mendShield`) instead of damage.
- **Example:** an Evocation mage casts Ember Wave, then Fireball: two stacks, +30%. Next round a third Fire spell washes over the whole pack.
- **Reuses:** spells.json elements, mana, the sign effect kinds.
- **New:** a resonance counter in the fight state and three bends. **[UX]** pips beside the mana bar.
- **Size:** M.
- **Risk:** Evocation's area hit against packs, especially in chapter 4+ when packs grow. Simulate pack fights; the area hit may need to be at 70% damage.

### Rogue: Exploit

- **Mechanic:** a foe whose telegraphed intent this round is **not an attack**, or who is **poisoned, stunned or weakened**, is *exposed*: your strikes on it get +25% crit chance. It reuses the enemy intents and statuses.
- **Specs:**
  - **Shadow:** your first strike of each fight always exploits, and a crit gives 1 dodge for the next hit.
  - **Venom:** poison always exposes, and poison you inflict lasts 1 turn longer (the Mire's kind, at 1).
  - **Trickster:** +1 reroll a round, and a crit lifts a few gold off the foe (the Crows' kind, small).
- **Example:** a cultist's intent reads "chant" (no attack). The rogue's backstab lands a crit.
- **Reuses:** `enemy_intent.dart`, statuses, rerolls, `crowsPrice` and `poisonExtraTurns`.
- **New:** the "exposed" check and three bends. **[UX]** a mark over an exposed foe.
- **Size:** M.
- **Risk:** crit stacking with Luck. Cap crit at the current cap, and simulate a Luck-heavy rogue build.

### Cleric: Grace

- **Mechanic:** healing **past full health is not lost but kept as grace** (up to 30% of max health, gone at the end of the fight). Clerics overheal a lot today; this turns the waste into the class's resource.
- **Specs:**
  - **Judgment:** grace is spent automatically on your next strike as extra Light damage. It hits harder against foes of the opposite alignment (the alignment hunters, the tear's things).
  - **Devotion:** grace mends the companion lowest on health at the start of each round, and once per fight a fallen companion rises with it (`secondWind` for the party).
  - **Vigil:** grace turns into block for the whole party at the start of the enemy's turn (`partyStartBlock`, live).
- **Example:** a Devotion cleric heals 30 on a 10-HP wound. The spare 20 is grace, and next round it closes a companion's cut.
- **Reuses:** heal faces, spells, the mend kinds, alignment.
- **New:** a grace pool and three bends. **[UX]** a white edge on the health bar.
- **Size:** M.
- **Risk:** Vigil's party block in long fights. Simulate chapter 5–7 bosses with a full party.

### Ranger: Quarry

- **Mechanic:** at the start of a fight the ranger **marks one foe** (by default the strongest; a tap changes it once). The marked foe takes +15% damage from the party and shows its intent **one round early** (the Vigil's kind, on that foe only). It reuses `hunters_mark`'s idea and intents.
- **Specs:**
  - **Marksman:** strikes on the mark get **pierce** (the keyword), and a multi-shot hits the mark twice.
  - **Trapper:** the mark's first attack each fight is snared: it stuns the mark instead.
  - **Wilds:** the ranger's mark is **the road**: +1 to every crossing, detour and expedition check, and a discovery step on an expedition gives two materials instead of one. In fights the mark only shows the intent.
- **Example:** a Trapper marks the ogre. The ogre raises its club, the snare takes it, and it loses the round.
- **Reuses:** intents, keywords, statuses, the d20 checks (crossings, detours, expedition steps), discovery steps (v1.327).
- **New:** a quarry slot in the fight state and three bends. **[UX]** a reticle on the mark.
- **Size:** M, L for Wilds (it touches the road code).
- **Risk:** Wilds trades fight power for road power. Check it's worth taking with the simulator's crossing and expedition success rates, not the win rate.

## 2. Clans

### How the clan spec works (the six clans)

- **The main mechanic grows with standing.** It's the clan's sworn effect kind, and it works for the clan you stand best with, at Trusted or above:
  - Trusted gives value 1;
  - Sworn gives value 2 (the sworn boon itself, as today).
  - It works for one clan at a time: your **patron**, the highest standing at Trusted+, or your sworn clan when you have one.
  - **[Q]** one patron at a time (clear, and rivals matter), or every Trusted clan at once (stronger, and the radar fills up)?
- **The sub-spec is a voice of the clan.** On reaching Trusted, the clan's next offer asks which of three voices you side with, mapped onto subclans.json. It sets that subclan to **friend** (as an offer's voice does today) and records `clanVoice[clan]`.
  - Changing voice later means a gift from another voice. It marks the old voice **foe**, costs 10 standing with the clan, and can bring the "mark:foe" titles that already exist.
- **Ties:**
  - **Standing:** the mechanic's value.
  - **Offers:** the chosen voice speaks more often (voice weight ×2), and its gifts carry its bend.
  - **Alignment:** a voice's `lean` nudges alignment when chosen, as gifts do; the Inquisition (lean -1) and Ember Sisters (lean 1) pull.
  - **Titles:** one title per voice at Sworn, e.g. "Writ of the Inquisition". **[N]**
- **The radar** (the clan tab and the gift popin, being built):
  - The clan's stat orientation, computed from its sponsored branches' scaling stats and its signs' `stat` effects.
  - Its relations to the other clans (relations.json steps).
  - The chosen voice highlighted.
  - A small Core helper gives UX both (separate PR, this week).
- **Clans with more than three subclans:**
  - The Dominion has 8, the Crows 5, the Penitents 5, the Compact 4 and the Mire 4.
  - Three are picked below. The others stay what they are today: voices of offers, intrigues and marks, without a bend.
  - **[Q]** is the pick right?
- **New data:**
  - in factions.json, `voices: [subclanId ×3]` and one `bend` record per voice (`kind`, `value`, `line`, `line_fr` **[N]**);
  - `clanVoice` on the session.
- **Balance check for all:** the simulator with a patron at Trusted from chapter 3 (as autoplay would get there), per clan × voice: win rate, gold per chapter (Crows), voyage losses (Admiralty, Tar-Hands). Within ±5 points of win rate of each other.

### Dominion: the Writ (`writFace`)

- **Mechanic:** a Writ face cancels N enemy attacks on you each fight (N = 1 Trusted, 2 Sworn).
- **Voices:**
  - **Inquisition:** a cancelled attack also **weakens** that foe for 2 turns. Lean -1: taking it pulls alignment down.
  - **Order of the Vigilant Flame:** a cancelled attack opens a **counter**: your next strike on that foe +50%. Ties to the "Challenged" title the Order already gives.
  - **Admiralty:** the Writ works at sea. Each voyage's first hostile event is calmed (`voyageCalm`, the Dominion's sworn boon already has it), and the hull takes 20% less from sea fights.
- **Example:** an Inquisition patron cancels a bandit's swing, and the bandit fights weakened for two turns.
- **Size:** M.
- **Risk:** the Writ on bosses. Simulate chapter 5 and 7 bosses at N=2.

### Vigil: Open Eyes (`intentLookahead`)

- **Mechanic:** see each enemy's intent N rounds ahead, and the tear's things can't ambush the party.
- **Voices:**
  - **Candlebearers:** +20% damage to the dead and the tear's things (enemy tags), whose intents you now see.
  - **Stitchers:** blocking an attack you foresaw **heals** for half what it blocked (`guardHeal`).
  - **Last Watch:** a foreseen attack on a companion gives that companion 8 block (`partyStartBlock`, aimed).
- **Size:** M.
- **Risk:** low. Lookahead is information; Stitchers' heal in long fights is the thing to watch.

### Compact: the Edge (`compactEdge`)

- **Mechanic:** breaks N enemy guards outright each fight.
- **Voices:**
  - **Quarrymen:** a broken guard **stuns** the foe 1 turn.
  - **Emberwives:** the blow that breaks a guard deals **Fire** (element), and burns for 2 turns of 3 damage (poison's tick, under a fire name). **[Q]** a burn status is new; or keep it plain Fire damage.
  - **Anvil-Deaf:** the smithy honours the clan: **one more hone** per face (`maxHones` 3 → 4) and tempering costs a third less.
- **Size:** M.
- **Risk:** the Quarrymen stun on bosses. Bosses resist stun every other try.

### Mire: Venom (`poisonExtraTurns`)

- **Mechanic:** poison you inflict lasts N turns longer.
- **Voices:**
  - **Barkbleeders:** poison you inflict ticks +2 harder.
  - **Heron's Wake:** the fen guides. +1 to crossing and expedition checks, and a delivery's deadline gets one spare day.
  - **Moss Choir:** each poison tick on a foe heals you 1 (`lifesteal` from poison).
- **Size:** M.
- **Risk:** poison stacking with Venom rogues (profession + clan). Simulate that pair specifically.

### Crows: the Price (`crowsPrice`)

- **Mechanic:** each hit you land steals N gold (10 hits a fight at most, as today).
- **Voices:**
  - **Keyholders:** chests open one rarity better, once per expedition.
  - **Tar-Hands:** the ship's hull mends 25% between voyages, and fitting a part at a port costs less.
  - **Whisper Ledger:** you see each suitor's gifts before choosing whom to hear (the offer dialog shows them face up), and an intrigue tells you one more clue.
- **Size:** M (Whisper Ledger is mostly UX).
- **Risk:** gold inflation. Check gold per chapter against the shop prices; Crows stays lean −1 (Evil).

### Penitents: the Ember (`emberFace`)

- **Mechanic:** lifts N Curses from your die each fight.
- **Voices:**
  - **Scorched Choir:** each lifted Curse heals you 5 (they sing a name for it).
  - **Road Exorcists:** +20% damage to the tear's things, and a lifted Curse also cleanses a status (`mendCleanse`).
  - **Ember Sisters:** the party heals 10% after each fight (`afterFightHealPercent`). Lean 1.
- **Size:** M.
- **Risk:** low. Curses are rare before chapter 4; Ember Sisters' heal saves potions, so check potion spend.

### The others (tribes, otherworld, the lost clan)

- **Choir** (vows) and **Pit** (pacts) already have their own mechanic, and it is their identity. They have no subclans; nothing changes.
- **Giants, oni, Tide-Kin and Kindly Ones** have no subclans and come late. **[Q]** give each a main mechanic without voices (S each), or leave them as sign patrons?
- **The Open Hand** (the lost clan, one subclan, the Fishbasket Line) is the player's own hand. **[Q]** its mechanic could be *choose any one clan voice's bend*, a late-game reward (S).

## 3. How the two meet

- A character has one **spec** (profession) and one **voice** (patron clan), so two bends.
- The clans' sponsored branches already line up with the specs. The Dominion sponsors Vanguard, Judgment and Evocation; the Mire sponsors Venom and Wilds; the Crows sponsor Shadow, Tempest and Marksman. Each clan is a natural home for some specs, and the offer weights make that the easy road without forcing it.
- Pairs to simulate on purpose:
  - Venom rogue + Mire;
  - Judgment cleric + Inquisition;
  - Trapper ranger + Quarrymen (two stuns).
- **[UX]** The character sheet shows both bends in one line each: "Bulwark: momentum reflects", "Inquisition: the Writ weakens".

## 4. Order of work (if the user says go)

| Step | What | Size |
|---|---|---|
| 1 | The Calling at level 5 and `specId`; spec data on the 15 original branches; Skillwright respec | M |
| 2 | The five main mechanics and their bends, one PR per profession (Warrior and Cleric first: the simplest, and the most played) | 5 × M |
| 3 | Patron and voice: standing value, the voice choice at Trusted, `clanVoice` | M |
| 4 | The six clan mechanics and their bends (the effect kinds exist; bends are new) | 6 × S–M |
| 5 | Simulator: spec and voice in autoplay, the per-spec and per-voice reports | M |

Steps 1 and 3 need **[UX]** (the Calling cards, the voice choice inside the offer popin) and **[N]** (15 spec lines, 18 voice lines, 18 titles).

## Open questions for the user

1. Profession spec at **level 5**, a choice of three cards. Or earlier/later, or at branch mastery as today?
2. Respec at the Skillwright for essence. Free the first time?
3. Branch mastery only on the spec's branch, or open as today?
4. The seven later branches: open to all (proposed), or fourth specs later?
5. One patron clan at a time (proposed), or every Trusted clan's mechanic at once?
6. The three voices picked for the Dominion (Inquisition, Order, Admiralty), Compact (Quarrymen, Emberwives, Anvil-Deaf), Mire (Barkbleeders, Heron's Wake, Moss Choir), Crows (Keyholders, Tar-Hands, Whisper Ledger) and Penitents (Scorched Choir, Road Exorcists, Ember Sisters): right picks?
7. A new **burn** status for the Emberwives, or plain Fire damage?
8. The four tribes and the Open Hand: a mechanic each, or left as they are?
