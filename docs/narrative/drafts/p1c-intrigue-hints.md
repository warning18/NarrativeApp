# P1c — Intrigue hints: one rule for all ten (draft, revision 2, not built)
Status: draft only, revised after Core's wiring (`claude/core-intrigue-hints`, b30f7b01) found that five speakers appear in no scene and some were met after the hub. Nothing here is in `assets/`; no key, id or flag is renamed. EN and FR; FR passes the lint rules (NBSP, curly ’, « », vous without gendered participle).
## The rule (unchanged, plus one)
1. **One line, one NPC the player has already met** in a scene (not only in `npcs.json`): the chef de caravane / caravan master (2001), the crape courier and his crier, the Crows' tally-boys (2005), Vane and his porters (2010), the Last Watch's sergeant (3005_clan_vigil_1). The line is written as a memory (“X had said…”) so it does not matter that the speaker is not at the host.
2. **Timing:** the speaker must be met before the host node; the Clue must be reachable from the host chapter (a chapter-6 Clue is hinted from a chapter-5 camp, not from chapter 3).
3. **Mechanism** (as Core wired it): `flag_callbacks` on the host, `flag` `void_banner_bearer`, `unlessFlags` the clue's flag, priority −1. The second offer is a reminder at a later camp keyed on `intrigue_<id>_stage_1`, hidden from stage 2.
4. **No new stage, flag, number or id.** `taken_names` has no Hook (its `names_clerk` errand is stage 1): hint only, no reminder.
## The ten
### The Hooded Lantern (`hooded_lantern`)
- Speaker: the caravan master. Met in: scene 2001 (ch2 arrival). Host: `2010`. Hidden once `hub_2015_informant` is set.
- EN: The caravan master had said it on the way down, shouldering his pack: “Ask on the wharf who sells lamp-oil by the cask and burns none. Someone here is paying to keep a lantern shuttered.”
- FR: Le chef de caravane l’avait dit en descendant, en rajustant son paquetage : « Demandez sur le quai qui vend l’huile de lampe au tonneau et n’en brûle pas. Quelqu’un, ici, paie pour qu’une lanterne reste voilée. »
- Hook: 3002 (spine).
- Reminder in `3001_camp` (shown from `intrigue_hooded_lantern_stage_1`, hidden from stage 2):
  - EN: The caravan master’s riddle about the lamp-oil is still open. The shuttered lantern has a master, and he has not left Saltmouth.
  - FR: L’énigme du chef de caravane sur l’huile de lampe reste ouverte. La lanterne voilée a un maître, et il n’a pas quitté Saltmouth.
### The Dying Lantern-Bearer (`dying_lantern_bearer`)
- Speaker: the Dominion courier in crape. Met in: scene 2005 itself. Host: `2005`. Hidden once `(none: its Clue is automatic)` is set.
- EN: The courier in crape, low: “If you meet a lantern-bearer who coughs, ask whose seal he carries. Do not ask loudly.”
- FR: Le courrier au crêpe, à voix basse : « Si vous croisez un porteur de lanterne qui tousse, demandez quel sceau il porte. Pas à voix haute. »
- Hook: 3005_envoys.
- Reminder in `3001_camp` (shown from `intrigue_dying_lantern_bearer_stage_1`, hidden from stage 2):
  - EN: The envoys at the Ashen Quarter gate still wait on an answer. Someone should give them one.
  - FR: Les envoyés de la porte du Quartier cendré attendent toujours une réponse. Il faudrait bien leur en donner une.
### The Broken Charter (`broken_charter`)
- Speaker: the crier of the crape courier. Met in: scene 2005 (the crier tells the queue what the crape means). Host: `2015`. Hidden once `hub_2015_dominion_blades` is set.
- EN: The crier at the gate had let something slip between prayers: “The Dominion’s masons measured the scaffolds twice and the harbour once. Ask them who signs the second count.”
- FR: Le crieur de la porte avait laissé échapper quelque chose entre deux prières : « Les maçons du Dominion ont mesuré les échafaudages deux fois et le port une seule. Demandez-leur qui signe le second compte. »
- Hook: 3005_tribunal_gold.
- Reminder in `4999_camp` (shown from `intrigue_broken_charter_stage_1`, hidden from stage 2):
  - EN: The Tribunal’s gold is still counted twice somewhere in the Ashen Quarter. The hall clerks know where.
  - FR: L’or du Tribunal est toujours compté deux fois quelque part dans le Quartier cendré. Les greffiers de la salle savent où.
### The Double Ledger (`double_ledger`)
- Speaker: Vane. Met in: scene 2010 (the quartermaster with the ledger). Host: `2015`. Hidden once `hub_2015_route_sold` is set.
- EN: Vane had said it over his ledger, to nobody: “Two books for one cargo. Saltmouth keeps only one honestly. Guess which.”
- FR: Vane l’avait dit penché sur son registre, à personne : « Deux livres pour une seule cargaison. Saltmouth n’en tient qu’un honnêtement. Devinez lequel. »
- Hook: 3005_black_thread.
- Reminder in `4999_camp` (shown from `intrigue_double_ledger_stage_1`, hidden from stage 2):
  - EN: The black thread in the Ashen Quarter ledgers is still there for whoever pulls it.
  - FR: Le fil noir des registres du Quartier cendré est toujours là pour qui le tire.
### The Returned (`the_returned`)
- Speaker: a Crows’ tally-boy. Met in: scene 2005 (the tally-boys down the queue). Host: `2015`. Hidden once `hub_2015_child_tongue` is set.
- EN: A Crows’ tally-boy at the gate had muttered it into his slate: “There’s a child on Tern Row talking in a voice that isn’t hers. Don’t answer it in kind.”
- FR: Un gamin des Corneilles, à la porte, l’avait marmonné dans son ardoise : « Il y a une enfant, dans la Rangée des sternes, qui parle d’une voix qui n’est pas la sienne. Ne répondez pas sur le même ton. »
- Hook: 3005_spire_takings.
- Reminder in `4999_camp` (shown from `intrigue_the_returned_stage_1`, hidden from stage 2):
  - EN: The Spire’s takings do not match its mourners. The child on Tern Row was only the first sign.
  - FR: Les recettes de la Flèche ne correspondent pas à ses pleureurs. L’enfant de la Rangée des sternes n’était que le premier signe.
### The Admiralty’s Silence (`admiraltys_silence`)
- Speaker: one of Vane’s porters. Met in: scene 2010 (“Vane, the porters called him”). Host: `2015`. Hidden once `hub_2015_survivor` is set.
- EN: One of Vane’s porters had said it low: “A man came off a ship the Admiralty swears never sailed. He sleeps behind the net-loft, and he won’t sleep long.”
- FR: Un des porteurs de Vane l’avait dit à voix basse : « Un homme est descendu d’un navire que l’Amirauté jure n’avoir jamais appareillé. Il dort derrière la resserre aux filets, et il ne dormira pas longtemps. »
- Hook: 3005_logbook_gap.
- Reminder in `4999_camp` (shown from `intrigue_admiraltys_silence_stage_1`, hidden from stage 2):
  - EN: The page missing from the Admiralty logbook is still missing. The survivor’s story names the gap.
  - FR: La page qui manque au livre de bord de l’Amirauté manque toujours. Le récit du rescapé nomme le trou.
### The Relic Road (`relic_road`)
- Speaker: the caravan master. Met in: scene 2001. Host: `2015`. Hidden once `hub_2015_bundle` is set.
- EN: The caravan master had grumbled it on the road in: “My wagons carry cloth and salt. Lately they carry bundles I never packed, heavier going in than coming out.”
- FR: Le chef de caravane l’avait grommelé en chemin : « Mes chariots portent du tissu et du sel. Depuis peu ils portent des ballots que je n’ai pas faits, plus lourds à l’aller qu’au retour. »
- Hook: 3005_shrine_break.
- Reminder in `4999_camp` (shown from `intrigue_relic_road_stage_1`, hidden from stage 2):
  - EN: Somebody is breaking shrines to keep a road open. The broken one at the Ashen Quarter is the clearest.
  - FR: Quelqu’un brise des sanctuaires pour garder une route ouverte. Celui du Quartier cendré, brisé, est le plus clair.
### The Unwatched Hour (`unwatched_hour`)
- Speaker: the Last Watch’s sergeant. Met in: scene 3005_clan_vigil_1 itself (“Their sergeant was an orc with one ear”). Host: `3005_clan_vigil_1`. Hidden once `hub_3100_new_moon` is set.
- EN: Their sergeant, not turning from the rubble: “The watch changes at the new moon, and for one hour nobody looks at the Sigil. Someone ought to count it.”
- FR: Leur sergente, sans se détourner des gravats : « La relève se fait à la nouvelle lune, et pendant une heure personne ne regarde le Sceau. Quelqu’un devrait la compter. »
- Hook: 6010_count_short (needs hub_6010_orsabet).
- Reminder in `6002_camp` (shown from `intrigue_unwatched_hour_stage_1`, hidden from stage 2):
  - EN: The count at the Reliquary is short by one, and somebody there knows which.
  - FR: Le compte du Reliquaire est court d’un, et quelqu’un, là-bas, sait lequel.
### The Lantern-Bearer’s Will (`lanternbearers_will`)
- Speaker: the courier in crape (he returns at 6010_lantern_manifest and 6100_knife). Met in: scenes 2005 and 6010_lantern_manifest. Host: `6002_camp (moved from the ch3 hub: the Clue is in ch6)`. Hidden once `hub_6100_will_scribe` is set. Also needs `hub_3005_envoys (the Clue needs it)`.
- EN: The courier in crape had left word at the camp: “A dying man’s will is the one honest paper in this country, and the one nobody has read. The scribe at Rimewell has it.”
- FR: Le courrier au crêpe avait laissé un mot au camp : « Le testament d’un mourant est le seul papier honnête de ce pays, et le seul que personne n’ait lu. Le scribe de Rimewell l’a. »
- Hook: 7100_will_seal.
- Reminder in `7001` (shown from `intrigue_lanternbearers_will_stage_1`, hidden from stage 2):
  - EN: The will’s seal is still unbroken. The scribe at Rimewell only needs a reason to hand it over.
  - FR: Le sceau du testament est toujours intact. Le scribe de Rimewell n’attend qu’une raison de le remettre.
### The Taken’s Names (`taken_names`)
- Speaker: the Last Watch’s sergeant. Met in: scene 3005_clan_vigil_1 itself (“Their sergeant was an orc with one ear”). Host: `3005_clan_vigil_1`. Hidden once `intrigue_taken_names_stage_1` is set.
- EN: Their sergeant, tracing a name with her thumb: “Some were not taken. They were counted out. Someone kept that count, and it is not on this wall.”
- FR: Leur sergente, qui suit un nom du pouce : « Certains n’ont pas été emportés. On les a rayés du compte. Quelqu’un a tenu ce compte, et il n’est pas sur ce mur. »
- Hook: names_clerk is stage 1 itself (ch 8 camp errand): no Hook, no reminder.

## What changed from the first draft
- Harker, Ysolde, Pell, Reck, Edda Grey (in no scene) and Inès, Dorran, Nadira (met only through the hub's own choices) are gone as speakers. The `npcs.json` entries stay for the codex.
- `lanternbearers_will`: hint moved from the ch3 hub to `6002_camp`; needs `hub_3005_envoys`.
- `taken_names`: speaker is the Watch sergeant in the Wall scene itself; reminder dropped.
- `unwatched_hour`: now the Last Watch's sergeant at the Wall scene (`3005_clan_vigil_1`), not an unmet sentry; the hint only reaches players who visit the Wall, which is fine for a hint. FR uses « chef de caravane » everywhere, as the rest of the story.
- Reminders no longer name Ysolde, Orsabet, or Vane's riddle unless the speaker was met.
