# What each foe is: a kind tag (Core, for Narrative to check)

The fight-length menu (`profession-clan-mechanics.md`, "Fight length: a menu tied to the world") has two rules by foe that wait on data:
- **Beasts tire:** from round 6 a beast hits 5% softer each round.
- **The dead crumble:** from round 6 an undead foe loses 3% of its health each round.

Morale ("never undead, constructs or bosses") would also read it.

`enemies.json` doesn't say what a foe *is*. Today `isEvilFoe` reads "weak to Light", which mixes the dead, the void and demons. This note proposes one `kind` per enemy.

**Kinds:** `person`, `beast`, `undead`, `construct`, `void`, `demon`, `angel`, `giant`.

**What Core needs from Narrative:** confirm or fix each row. A **?** marks the rows Core is least sure of. Core then adds the field and the two rules after step 5 (the manager's order).

| Kind | Enemies |
|---|---|
| **person** | slum_thug, street_bandit, smuggler_captain, brine_jack, den_bouncer, den_looter, sore_loser, wreck_scavenger, dock_overseer, inquisition_warden, inquisition_soldier, inquisition_high_warden, inquisition_auxiliary, inquisition_legate, inquisition_penitent, masked_penitent, kroll_the_branded, purifier_vell, aurel_vane, claimant_vane, claimant_morrow, claimant_tallis, cultist_acolyte, hollow_court_zealot, hollow_court_inquisitor, white_soldier, horn_taker, the eight *_turned companions, the six rival hunters (vigil_*, compact_*, mire_*) |
| **beast** | harbor_rat, rat_matriarch, plague_hound, kraken_arm |
| **undead** | catacomb_ghoul, bone_warden, bone_sexton, drowned_pilgrim, knell_keeper, rime_bailiff, white_admiral, teind_rider, unmade_knight |
| **construct** | iron_golem, strand_colossus, glass_shepherd |
| **void** | void_wisp (the Grey Candle), void_stalker, void_hound, void_manifestation, void_archon, void_sovereign, tear_spawn, tear_herald, hollow_reflection |
| **demon** | demon_imp, demon_tormentor |
| **angel** | angel_sentinel, angel_judicator |
| **giant** | frost_kept_giant |

**Open questions:**
1. **The White Soldiers and the White Admiral:** are they dead, or living soldiers of a cold court? If they are undead, they crumble.
2. **The Teind-Rider and the Unmade Knight:** undead, or void?
3. **The Turned companions:** void, or people still? This decides whether morale lets them flee, which matters for the story.
4. **The Horn-Taker:** a demon, or a beast of the Pit?

## Narrative's review

Checked against each enemy's `description` and `weakTo` in `enemies.json`. All rows are confirmed except **three moved** (and the question marks resolved); the table above is the corrected one.

**Moved**
- **white_soldier: undead → person.** "Porcelain-masked, faceless, sent when the Church wants something taken": living soldiers of the Church, and weak to Fire, not Light. They do not crumble.
- **horn_taker: demon → person.** He is the Spire's senior exorcist, who *collects* horns; weak to the Void, like the Choir's angels, not to Light. He is the hunter, not the hunted.
- **The eight *_turned companions: void → person.** They are the party's own people, turned by the legate's pact. As persons they can break and flee under morale, and **sparing one is the right ending to such a fight**, which the story wants. (They carry `weakTo: Light` because the pact marks them; that is data, not their kind.)

**Resolved questions**
1. **The White Soldiers and the White Admiral:** the Soldiers are living (person). The Admiral is dead: he "went down the way his fleet had, all at once, still giving orders", and stands on his quarterdeck a year after the tear took the fleet. **Undead.** He is a boss, so morale never applies, and the crumble would be his armour coming apart.
2. **The Teind-Rider and the Unmade Knight:** both **undead**. The Rider has ridden the fen road every seventh year for three hundred years; the Knight is armour that keeps walking after the tear unmade the man in it. Neither is Void in the fiction: the Void is what *comes through* the tear; these are Court dead.
3. **The Turned companions:** persons (see above).
4. **The Horn-Taker:** neither a demon nor a beast: a person.

**Confirmed, with a note**
- **void_hound: void**, not beast: "all smoke and teeth, hunts by the scent of the Shroud". A beast that tired would be wrong for smoke.
- **glass_shepherd: construct**: "a crook of fused sand", Earth-weak. It is the tear's, but it is made of glass; no morale, no tiring.
- **kraken_arm: beast**: one arm of the Tide-Mother, tiring is fine.
- **knell_keeper, rime_bailiff: undead**: Court and Reliquary servants long past death (Light/Earth-weak, Fire-weak, cold).
- **cultist_acolyte, hollow_court_zealot: person**, though both are weak to Light (they pray to the tear). They are living; they can break and flee, and sparing them is a real choice.

**For Core: do not build `isEvilFoe` on `weakTo: Light`.** It catches the Turned companions, the cultists and the zealots, who are living people. Build it on the kind: `void`, `undead` or `demon`. (The Lantern Vanguard's heal, "a foe weak to Light (the void, the dead, demons)", then reads true to its text.) The six new hunters' kinds are `person`.
