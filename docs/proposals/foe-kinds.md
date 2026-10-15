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
| **person** | slum_thug, street_bandit, smuggler_captain, brine_jack, den_bouncer, den_looter, sore_loser, wreck_scavenger, dock_overseer, inquisition_warden, inquisition_soldier, inquisition_high_warden, inquisition_auxiliary, inquisition_legate, inquisition_penitent, masked_penitent, kroll_the_branded, purifier_vell, aurel_vane, claimant_vane, claimant_morrow, claimant_tallis, cultist_acolyte, hollow_court_zealot, hollow_court_inquisitor, the six rival hunters (vigil_*, compact_*, mire_*) |
| **beast** | harbor_rat, rat_matriarch, plague_hound, kraken_arm |
| **undead** | catacomb_ghoul, bone_warden, bone_sexton, drowned_pilgrim, knell_keeper, rime_bailiff, white_soldier **?**, white_admiral **?**, teind_rider **?**, unmade_knight **?** |
| **construct** | iron_golem, strand_colossus, glass_shepherd **?** |
| **void** | void_wisp (the Grey Candle), void_stalker, void_hound **?** (beast or void), void_manifestation, void_archon, void_sovereign, tear_spawn, tear_herald, hollow_reflection, the eight *_turned companions **?** |
| **demon** | demon_imp, demon_tormentor, horn_taker **?** |
| **angel** | angel_sentinel, angel_judicator |
| **giant** | frost_kept_giant |

**Open questions:**
1. **The White Soldiers and the White Admiral:** are they dead, or living soldiers of a cold court? If they are undead, they crumble.
2. **The Teind-Rider and the Unmade Knight:** undead, or void?
3. **The Turned companions:** void, or people still? This decides whether morale lets them flee, which matters for the story.
4. **The Horn-Taker:** a demon, or a beast of the Pit?
