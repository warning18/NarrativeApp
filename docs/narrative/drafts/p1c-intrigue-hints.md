# P1c — Intrigue hints: one rule for all ten (draft, not built)
Status: draft only. The user has not decided. Nothing here is in `assets/`; no key, id or flag is renamed. EN and FR; FR passes the lint rules (NBSP, curly ’, « », vous without gendered participle).
## The rule
1. **One line, one NPC the player already met**, spoken once, at a node every route passes. It points at the Clue (stage 1), never explains the plot.
2. **Mechanism:** a `flag_callbacks` entry on a spine node (`2010`, `2005`, `3005` hub arrival…), `flag` = `void_banner_bearer` (set by all three chapter-1 end choices), `unlessFlags` = the clue's hub flag (so it disappears once the player takes the lead), `priority` below any existing callback on that node. Where the node already has a callback at its cap, use `callback_cap` of the node unchanged and put the hint at the lowest priority, so it only shows when there is room.
3. **Second offer of the Hook (stage 2):** a reminder line in a later camp scene (`3001_camp`, `4999_camp`, `6002_camp`, `7001`), `flag` = the stage-1 plot flag (`plot_x_1`), `unlessFlags` = the stage-2 flag (`plot_x_2`). One line, no choice; the hub choice that opens the Hook is already offered again each time, so the reminder only points back.
4. **No new stage, flag, number or id.** Stage firing stays as it is (`politics.intrigue` on the existing choices). If a hint host node is at its callback cap the line is dropped, never the existing one.
5. Hosts and speakers below are proposals; each speaker is in `npcs.json` or an existing scene. Size: S per intrigue (one callback in, one callback out), M for the set. Tag: **needs the user's choice** (go-ahead for the whole rule), then a quick win to build.
6. `hosts_price` (ch 8) is a payoff, not a hook: no hint, so the count is ten with `taken_names` and not eleven.
## The ten
### The Hooded Lantern (`hooded_lantern`)
- Speaker: Vane, the quartermaster. Host node: `2010 (wharf)`. Hint hidden once flag `hub_2015_informant` is set.
- EN: Vane: “Ask on the wharf who sells lamp-oil by the cask and burns none. Someone is paying to keep a lantern shuttered.”
- FR: Vane : « Demandez sur le quai qui vend l’huile de lampe au tonneau et n’en brûle pas. Quelqu’un paie pour qu’une lanterne reste voilée. »
- Hook: `3002 (spine, automatic)`. Second offer in `3001_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: Vane’s lamp-oil riddle is still open. The shuttered lantern has a master, and he has not left Saltmouth.
  - FR: L’énigme de Vane sur l’huile de lampe reste ouverte. La lanterne voilée a un maître, et il n’a pas quitté Saltmouth.
### The Dying Lantern-Bearer (`dying_lantern_bearer`)
- Speaker: the courier in crape. Host node: `2005 (landward gate)`. Hint hidden once flag `(none; Clue is automatic)` is set.
- EN: The courier in crape, low: “If you meet a lantern-bearer who coughs, ask whose seal he carries. Do not ask loudly.”
- FR: Le courrier en crêpe, à voix basse : « Si vous croisez un porteur de lanterne qui tousse, demandez quel sceau il porte. Pas à voix haute. »
- Hook: `3005_envoys (hub)`. Second offer in `3001_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The envoys at the Ashen Quarter gate still wait on an answer. Someone should give them one.
  - FR: Les envoyés de la porte du Quartier cendré attendent toujours une réponse. Il faudrait bien leur en donner une.
### The Broken Charter (`broken_charter`)
- Speaker: Dorran Quill. Host node: `2015 (hub)`. Hint hidden once flag `hub_2015_dominion_blades` is set.
- EN: Dorran Quill, wiping chalk from his hands: “The Dominion’s men measured my scaffold twice and the harbour once. Ask them why.”
- FR: Dorran Quill, qui s’essuie les mains pleines de craie : « Les hommes du Dominion ont mesuré mon échafaudage deux fois et le port une seule. Demandez-leur pourquoi. »
- Hook: `3005_tribunal_gold`. Second offer in `4999_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The Tribunal’s gold is still counted twice somewhere in the Ashen Quarter. The hall clerks know where.
  - FR: L’or du Tribunal est toujours compté deux fois quelque part dans le Quartier cendré. Les greffiers de la salle savent où.
### The Double Ledger (`double_ledger`)
- Speaker: Old Harker. Host node: `2015 (hub)`. Hint hidden once flag `hub_2015_route_sold` is set.
- EN: Old Harker, to nobody: “Two books for one cargo. Saltmouth only keeps one honestly. Guess which.”
- FR: Le vieux Harker, à personne : « Deux livres pour une seule cargaison. Saltmouth n’en tient qu’un honnêtement. Devinez lequel. »
- Hook: `3005_black_thread`. Second offer in `4999_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The black thread in the Ashen Quarter ledgers is still there for whoever pulls it.
  - FR: Le fil noir des registres du Quartier cendré est toujours là pour qui le tire.
### The Returned (`the_returned`)
- Speaker: Sister Ysolde. Host node: `2015 (hub)`. Hint hidden once flag `hub_2015_child_tongue` is set.
- EN: Sister Ysolde: “A child on Tern Row spoke in a voice that was not hers. If you hear it, do not answer in kind.”
- FR: Sœur Ysolde : « Une enfant de la Rangée des sternes a parlé d’une voix qui n’était pas la sienne. Si vous l’entendez, ne répondez pas sur le même ton. »
- Hook: `3005_spire_takings`. Second offer in `4999_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The Spire’s takings do not match its mourners. Sister Ysolde’s unease has a number.
  - FR: Les recettes de la Flèche ne correspondent pas à ses pleureurs. L’inquiétude de sœur Ysolde a un chiffre.
### The Admiralty’s Silence (`admiraltys_silence`)
- Speaker: Nadira, Tern Row. Host node: `2015 (hub)`. Hint hidden once flag `hub_2015_survivor` is set.
- EN: Nadira: “One man came off a ship the Admiralty swears never sailed. He sleeps behind the net-loft, and he will not sleep long.”
- FR: Nadira : « Un homme est descendu d’un navire que l’Amirauté jure n’avoir jamais appareillé. Il dort derrière la resserre aux filets, et il ne dormira pas longtemps. »
- Hook: `3005_logbook_gap`. Second offer in `4999_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The page missing from the Admiralty logbook is still missing. The survivor’s story names the gap.
  - FR: La page qui manque au livre de bord de l’Amirauté manque toujours. Le récit du rescapé nomme le trou.
### The Relic Road (`relic_road`)
- Speaker: Old Pell. Host node: `2015 (hub)`. Hint hidden once flag `hub_2015_bundle` is set.
- EN: Old Pell: “My wagons carry cloth and salt. Lately they carry bundles I never packed, and they are heavier on the way in than the way out.”
- FR: Le vieux Pell : « Mes chariots portent du tissu et du sel. Depuis peu ils portent des ballots que je n’ai pas faits, plus lourds à l’aller qu’au retour. »
- Hook: `3005_shrine_break`. Second offer in `4999_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: Somebody is breaking shrines to keep a road open. The broken one at the Ashen Quarter is the clearest.
  - FR: Quelqu’un brise des sanctuaires pour garder une route ouverte. Celui du Quartier cendré, brisé, est le plus clair.
### The Unwatched Hour (`unwatched_hour`)
- Speaker: Sister Inès. Host node: `3005 (hub)`. Hint hidden once flag `hub_3100_new_moon` is set.
- EN: Sister Inès: “The watch changes at the new moon, and for one hour nobody is looking at the Sigil. Count it, if you can stand to.”
- FR: Sœur Inès : « La relève se fait à la nouvelle lune, et pendant une heure personne ne regarde le Sceau. Comptez-la, si vous en avez le cœur. »
- Hook: `6010_count_short (needs hub_6010_orsabet)`. Second offer in `6002_camp`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The count at the reliquary is short by one. Orsabet knows which one, and has not said.
  - FR: Le compte du reliquaire est court d’un. Orsabet sait lequel, et ne l’a pas dit.
### The Lantern-Bearer’s Will (`lanternbearers_will`)
- Speaker: Hollis Reck. Host node: `3005 (hub)`. Hint hidden once flag `hub_6100_will_scribe` is set.
- EN: Hollis Reck: “A dying man’s will is the only honest document in this town, and the only one nobody has read. Find the scribe.”
- FR: Hollis Reck : « Le testament d’un mourant est le seul document honnête de cette ville, et le seul que personne n’ait lu. Trouvez le scribe. »
- Hook: `7100_will_seal`. Second offer in `7001`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The will’s seal is still unbroken. The scribe at Rimewell only needs a reason to hand it over.
  - FR: Le sceau du testament est toujours intact. Le scribe de Rimewell n’attend qu’une raison de le remettre.
### The Taken’s Names (`taken_names`)
- Speaker: Edda Grey. Host node: `3005_clan_vigil_1 (Wall of Names)`. Hint hidden once flag `names_clerk` is set.
- EN: Edda Grey, tracing a name with her thumb: “Some of them were not taken. They were counted out. Someone kept the count, and it is not on this wall.”
- FR: Edda Grey, qui suit un nom du pouce : « Certains n’ont pas été emportés. On les a rayés du compte. Quelqu’un a tenu ce compte, et il n’est pas sur ce mur. »
- Hook: `names_clerk (ch 8 camp errand)`. Second offer in `7001`, shown when `plot_*_1` is held and `plot_*_2` is not.
  - EN: The Wall of Names was only the first list. A clerk at the end of the road keeps the other.
  - FR: Le Mur des noms n’était que la première liste. Un greffier au bout de la route tient l’autre.
## Checks before building
- Confirm each speaker has met the player at that point (Vane `2010`, the courier `2005`, others at the `2015` hub: they are met when the hub is entered, so those hints sit on the hub's own callbacks, not before it).
- `2015` already holds 13 callbacks: the hub hints take the lowest priority and are the first dropped by the cap.
- Run `companion_remarks_test`, `qa_story_fr_test` and the French lint after building.
