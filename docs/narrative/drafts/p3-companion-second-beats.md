# P3 draft: a second beat for each companion, and Vica's scenes

> **WIRE-READY (supersedes the "Wiring" list below).** The scenes are built as data and tested; nothing here is in `assets/` yet because the user has not chosen to build P3.
>
> - `docs/narrative/drafts/p3-beat2-patch.json`: the eleven nodes (`beat2_<c>` ×9 incl. Vica, and `loyal_vica`), the loyalty-flag edits, the 9 hub choices and the `7800` echo lines, every one with EN/FR, prompt/prompt_fr and revisit text.
> - `docs/narrative/drafts/apply_p3_beat2.py`: applies the patch (idempotent) and the three one-line `lib/data/world_map.dart` scene-list edits. Run from the repo root once `7516_eve` is on `main`, then `dart format lib/data/world_map.dart`.
> - **Tested** on a scratch copy of `claude/core-ch7-scenes` (6f2d55a9) with the patch applied: `story_graph_integrity`, `story_rules`, `companion_remarks`, `french_data_lint`, `qa_story_fr`, `camp_errands`, `story_cap_revisit`, `french_address`, `companion_remark_story`, `story_text`, `world_map`, `world_map_edit`, `qa_story_blocking`, `chapter_eight`, `chapter_loop`, `app_strings_french_typography`: all green.
> - **Design change from the first draft:** the eight beats are **not camp errands**. They are hub choices on `7516_eve` (“Sit with <name>”, shown while `<c>_loyal_done` and `ally_<c>` hold and neither outcome flag is set), the scenes sit at `candlehold_gates` (cathedral theme, as the hub) and return to `7516_eve`. So no `campErrand`, no `7400` return, and `7516_eve` stays a night of choices with “Sleep, and climb at dawn” last. Up to nine hub choices at once; the player can take any, in any order.
> - **Flags:** each `loyal_<c>` choice also sets `<c>_loyal_done` (the one gate flag; the real outcome flags are unchanged). Each beat sets one of two new outcome flags (listed per scene below). They are *read* by the hub's own `hideIfFlags`, so the “every mark is read” rule is met without Muster lines; Vica’s loyalty flags are echoed at `7800` (two lines, priority 2, like the other eight) and `vica_at_the_fire` (set by `1155_vica_follows`, whose single choice needs an effect) is read by a callback in `loyal_vica`.
> - **Prompts:** each beat has a `prompt`/`prompt_fr` line and a one-line `revisit_description` (EN/FR) in the patch; loyalty and recruit scenes follow the existing `loyal_*` shape.
> - **Core still has to:** nothing but run the script (the world-map list edits are in it). **Not touched:** `companion_remarks.json` (an optional follow-up, same keys as the flags here); approvals (no `approvalMods`).
> - **Revision 2 (after Core's wiring, `claude/core-p3-beat2`):** (1) `1155_vica_follows` is gone: a forced one-choice page for every run was wrong. Its three lines are now `flag_callbacks` on `1200` (`vica_follow`, `vica_shared`, `vica_paid`, priority 1), so each player sees only what they did, and `vica_at_the_fire` no longer exists. `1150_vica` is untouched; the patch has ten nodes, not eleven. (2) The FR hub choices are verb phrases that mirror the EN (“Écouter…”, “Découvrir…”, “Regarder de nouveau…”, “S’asseoir avec…”); `Kelda`'s EN is now “Sit with Kelda and her shield-strap”. Tested again on a fresh `origin/main` (7516_eve is there): story graph and rules, remarks, French lint, `qa_story_fr`, world map, camp errands, narration: green.
> - **Gate for the user:** build all nine, a subset (delete entries from the patch), or none.

**Why** (story review 3.3, 6.1): each of the eight story companions has a recruit scene and one loyalty scene, and the loyalty choice is read only at the Muster in chapter 8 (`7800`). There is no companion beat in chapters 6 or 7, where the party is largest and the player most invested. Vica has one scene (`1150_vica`) and nothing else.

**Shape:** one camp scene per companion (70 to 90 words, two choices), offered in the chapter 7 camp. It is a companion asking for something the Throne will cost them. The choice sets one flag; the Muster can echo it (see "Echo", optional).

**Size:** L in total, but each scene is S. **Needs Core:** (1) add the eleven scene ids to the Cove Camp `scenes` list in `lib/data/world_map.dart`; (2) confirm the flag convention below; (3) nothing else (the scenes are plain camp errands like `loyal_*`). **Needs the user's choice:** whether to build it at all (the review marks P3 as the user's choice) and how many of the eight.

**Wiring (the same for the eight):**
- `campErrand: true`, `location: "cove_camp"`, `context_taxonomy.mood: "solemn"`.
- `showIfFlags: ["<c>_loyal_done", "banner_five"]`, `hideIfFlags: [<the two outcome flags>]`.
- Choice `next_id: "7400"` (the chapter 7 camp node; `7400`'s own choices already return there).
- **Edit to the existing loyalty scene:** add `<c>_loyal_done` to `flagsToAdd` of **both** choices of `loyal_<c>` (see each block).
- No `approvalMods`, no `politics`; the scenes are character beats, not clan beats.

## The eight
### `beat2_kelda`: Kelda

- **Button (camp):** EN “Show Kelda the shield-strap” / FR “Kelda et la lanière”
- **Reads:** `kelda_loyal_done`, `banner_five`
- **Hides when:** `kelda_strap_taken` or `kelda_strap_refused`
- **Edit to `loyal_kelda`:** add `kelda_loyal_done` to `flagsToAdd` of both choices (they set `kelda_gate_held / kelda_gate_left` today)

**EN**

> Kelda was oiling her shield-strap by the fire, and had not stopped when I came near. “If I fall on that shore,” she said, “this goes to Highhearth. To my brother. He will not want it. Give it to him anyway.” She did not look up. “Nobody else will carry it who knows what it held.”

**FR**

> Kelda huilait la lanière de son bouclier près du feu, et n’avait pas cessé quand je m’étais approché. « Si je tombe sur cette grève, dit-elle, ceci va à Haut-Âtre. À mon frère. Il n’en voudra pas. Donnez-le-lui quand même. » Elle ne leva pas les yeux. « Personne d’autre ne le portera en sachant ce qu’il a tenu. »

- EN “Take the strap” / FR “Prendre la lanière”: sets `kelda_strap_taken`, → `7400`
- EN “Tell her she will carry it herself” / FR “Lui dire qu’elle le portera elle-même”: sets `kelda_strap_refused`, → `7400`

### `beat2_sable`: Sable

- **Button (camp):** EN “Hear what Sable found on her bedroll” / FR “Ce que Sable a trouvé sur son couchage”
- **Reads:** `sable_loyal_done`, `banner_five`
- **Hides when:** `sable_price_paid` or `sable_price_alone`
- **Edit to `loyal_sable`:** add `sable_loyal_done` to `flagsToAdd` of both choices (they set `sable_marker_kept / sable_marker_torn` today)

**EN**

> A Crow’s runner had left a pennant-pin on Sable’s bedroll, and she held it at arm’s length, the way you hold a fish that has begun to speak. “They’ve priced me,” she said. “Not high. An insult, really.” The pin was a feather in iron. “I can answer it myself. Or you can answer it for me, and I’ll hate that, and be grateful.”

**FR**

> Un coureur des Corneilles avait laissé une épingle de fanion sur le couchage de Sable, et elle la tenait à bout de bras, comme on tient un poisson qui se met à parler. « Ils m’ont mise à prix, dit-elle. Pas cher. Une insulte, en fait. » L’épingle était une plume de fer. « Je peux répondre moi-même. Ou vous répondez pour moi, et je détesterai ça, et je serai reconnaissante. »

- EN “Answer it for her” / FR “Répondre à sa place”: sets `sable_price_paid`, → `7400`
- EN “Let her answer it herself” / FR “La laisser répondre elle-même”: sets `sable_price_alone`, → `7400`

### `beat2_maren`: Maren

- **Button (camp):** EN “Sit with Maren and her new list” / FR “S’asseoir avec Maren et sa nouvelle liste”
- **Reads:** `maren_loyal_done`, `banner_five`
- **Hides when:** `maren_list_read` or `maren_list_kept`
- **Edit to `loyal_maren`:** add `maren_loyal_done` to `flagsToAdd` of both choices (they set `maren_names_read / maren_roll_burned` today)

**EN**

> Maren had a new list on her knee, a short one, in a hand that did not shake. “The names of those who went down to the shore and did not come back,” she said. “Not the Court’s. Ours. The crews, the camp.” She folded it small. “I would like to read it at the muster, before anyone speaks for the Throne. Or I will keep it, and say them to myself, which I already do.”

**FR**

> Maren avait une nouvelle liste sur le genou, courte, d’une main qui ne tremblait pas. « Les noms de ceux qui sont descendus sur la grève et ne sont pas revenus, dit-elle. Pas ceux de la Cour. Les nôtres. Les équipages, le camp. » Elle la plia en petit. « J’aimerais la lire au rassemblement, avant que quiconque parle pour le Trône. Ou je la garde, et je les dis pour moi seule, ce que je fais déjà. »

- EN “Ask her to read it at the muster” / FR “Lui demander de la lire au rassemblement”: sets `maren_list_read`, → `7400`
- EN “Let her keep it” / FR “La laisser la garder”: sets `maren_list_kept`, → `7400`

### `beat2_liora`: Liora

- **Button (camp):** EN “Hear Liora’s report from the ridge” / FR “Le rapport de Liora, depuis la crête”
- **Reads:** `liora_loyal_done`, `banner_five`
- **Hides when:** `liora_ridge_climbed` or `liora_ridge_rested`
- **Edit to `loyal_liora`:** add `liora_loyal_done` to `flagsToAdd` of both choices (they set `liora_watch_shared / liora_watch_left` today)

**EN**

> Liora had come down off the ridge at dawn with frost on her hood and nothing to report. “That is what I am reporting,” she said. “The Hollow Shore does not move. It does not breathe. It watches the coast the way I watch it.” She turned her bow over in her hands. “Come up with me tonight. Or tell me to sleep, and I will, and I will not like it.”

**FR**

> Liora était redescendue de la crête à l’aube, du givre sur le capuchon et rien à signaler. « C’est cela que je signale, dit-elle. La Rive Creuse ne bouge pas. Elle ne respire pas. Elle regarde la côte comme je la regarde. » Elle retournait son arc dans ses mains. « Montez avec moi cette nuit. Ou dites-moi de dormir, et je dormirai, et je n’aimerai pas ça. »

- EN “Climb the ridge with her” / FR “Monter sur la crête avec elle”: sets `liora_ridge_climbed`, → `7400`
- EN “Tell her to sleep” / FR “Lui dire de dormir”: sets `liora_ridge_rested`, → `7400`

### `beat2_vess`: Vess

- **Button (camp):** EN “Go to Vess, apart from the fire” / FR “Rejoindre Vess, à l’écart du feu”
- **Reads:** `vess_loyal_done`, `banner_five`
- **Hides when:** `vess_shore_asked` or `vess_camp_kept`
- **Edit to `loyal_vess`:** add `vess_loyal_done` to `flagsToAdd` of both choices (they set `vess_voice_answered / vess_voice_stilled` today)

**EN**

> Vess sat apart from the fire with her hands folded, as one does in a church. “It has gone quiet,” she said. “Since the crowning was planned. I think it is waiting for you to choose, the way a creditor waits.” She looked at me with something nearer to fear than I had seen in her. “If you take me to the shore it will speak again. I would rather you asked first.”

**FR**

> Vess était assise à l’écart du feu, les mains jointes, comme on l’est à l’église. « Il s’est tu, dit-elle. Depuis qu’on a prévu le couronnement. Je crois qu’il attend que vous choisissiez, comme un créancier attend. » Elle me regarda avec quelque chose de plus proche de la peur que tout ce que j’avais vu en elle. « Si vous m’emmenez à la grève, il parlera de nouveau. Je préférerais que vous me le demandiez d’abord. »

- EN “Ask her to come to the shore” / FR “Lui demander de venir à la grève”: sets `vess_shore_asked`, → `7400`
- EN “Leave her at the camp” / FR “La laisser au camp”: sets `vess_camp_kept`, → `7400`

### `beat2_grosh`: Grosh

- **Button (camp):** EN “Find out what Grosh is holding” / FR “Savoir ce que Grosh tient”
- **Reads:** `grosh_loyal_done`, `banner_five`
- **Hides when:** `grosh_sent_home` or `grosh_stays`
- **Edit to `loyal_grosh`:** add `grosh_loyal_done` to `flagsToAdd` of both choices (they set `grosh_debt_paid / grosh_debt_kept` today)

**EN**

> A letter had come up from Highhearth, and Grosh held it the way he held a sword he did not trust. “Old man who held the paper on my mother’s hall,” he said. “Dead. Heirs say the debt is gone.” He turned it over, as if there might be more on the back. “Grosh does not know what Grosh is for, if there is no debt. Tell Grosh.”

**FR**

> Une lettre était montée de Haut-Âtre, et Grosh la tenait comme une épée en laquelle il n’avait pas confiance. « Le vieux qui tenait le papier sur la salle de ma mère, dit-il. Mort. Les héritiers disent que la dette est partie. » Il la retourna, comme s’il pouvait y avoir plus au dos. « Grosh ne sait pas à quoi Grosh sert, s’il n’y a plus de dette. Dites à Grosh. »

- EN “Tell him to go home” / FR “Lui dire de rentrer chez lui”: sets `grosh_sent_home`, → `7400`
- EN “Ask him to stay for the Throne” / FR “Lui demander de rester pour le Trône”: sets `grosh_stays`, → `7400`

### `beat2_tobin`: Tobin

- **Button (camp):** EN “Sit with Tobin and his letter” / FR “S’asseoir avec Tobin et sa lettre”
- **Reads:** `tobin_loyal_done`, `banner_five`
- **Hides when:** `tobin_reply_read` or `tobin_reply_burned`
- **Edit to `loyal_tobin`:** add `tobin_loyal_done` to `flagsToAdd` of both choices (they set `tobin_letter_sent / tobin_stays` today)

**EN**

> A reply had come from the Choir, in a clerk’s hand, sealed with a note Tobin would not touch. “They have forgiven me,” he said. “That is the worst part.” He held it out. “Read it, if you like. Or put it in the fire. I cannot do either, and I would be grateful to have it done for me.”

**FR**

> Une réponse était venue du Chœur, d’une main de clerc, scellée d’une note que Tobin refusait de toucher. « Ils m’ont pardonné, dit-il. C’est le pire. » Il la tendit. « Lisez-la, si vous voulez. Ou jetez-la au feu. Je ne peux faire ni l’un ni l’autre, et je vous serais reconnaissant de le faire pour moi. »

- EN “Read it aloud” / FR “La lire à voix haute”: sets `tobin_reply_read`, → `7400`
- EN “Burn it unread” / FR “La brûler sans la lire”: sets `tobin_reply_burned`, → `7400`

### `beat2_malrik`: Malrik

- **Button (camp):** EN “Look at Malrik’s ledger again” / FR “Revoir le registre de Malrik”
- **Reads:** `malrik_loyal_done`, `banner_five`
- **Hides when:** `malrik_paid_now` or `malrik_paid_dawn`
- **Edit to `loyal_malrik`:** add `malrik_loyal_done` to `flagsToAdd` of both choices (they set `malrik_book_read / malrik_book_shut` today)

**EN**

> Malrik set a ledger on the barrel and turned it so I could read it. “Your page,” he said. “Updated. One line added, one struck out.” He did not say which. “Wages, in advance, for the shore. I do not expect to be paid after.” He said it as a fact about the weather. “Pay me now, and I will know you do not mean to die. Pay me at dawn, and I will wonder.”

**FR**

> Malrik posa un registre sur le tonneau et le tourna pour que je puisse lire. « Votre page, dit-il. À jour. Une ligne ajoutée, une autre rayée. » Il ne dit pas lesquelles. « Les gages, d’avance, pour la grève. Je ne compte pas être payé après. » Il le dit comme on parle de la météo. « Payez-moi maintenant, et je saurai que vous ne comptez pas mourir. Payez-moi à l’aube, et je me poserai la question. »

- EN “Pay him now” / FR “Le payer maintenant”: sets `malrik_paid_now`, → `7400`
- EN “Pay him at dawn” / FR “Le payer à l’aube”: sets `malrik_paid_dawn`, → `7400`

## Vica (three scenes)

Vica is a hound (`ranger`), so her scenes have no speech, in the manner of her existing remarks. She has no recruit quest and no loyalty scene today.

### `1155_vica_follows`: a recruit follow-up (chapter 1)

- **Slots in:** between `1150_vica` and `1200`: change the three choices of `1150_vica` to `next_id: "1155_vica_follows"`, and this scene's one choice goes to `1200`.
- **Reads:** `vica_shared`, `vica_paid` (set by `1150_vica` choices 1 and 2; choice 0 sets neither)
- **Sets:** nothing
- **Callbacks (flag_callbacks):** `vica_shared`: EN “She ate what was left in the flask, which was nothing, and licked the flask.” / FR « Elle mangea ce qui restait dans la gourde, c’est-à-dire rien, et lécha la gourde. » `vica_paid`: EN “She sat on the coins until I understood they were hers.” / FR « Elle s’assit sur les pièces jusqu’à ce que je comprenne qu’elles étaient à elle. »

**EN**

> She did not follow me out of the hollow. She followed me out of the dark, which is not the same, and it took me until the fire to see the difference. By the water she lay down at the edge of the light, close enough to be mine, far enough to leave.

**FR**

> Elle ne me suivit pas hors du creux. Elle me suivit hors du noir, ce qui n’est pas pareil, et il me fallut attendre le feu pour voir la différence. Près de l’eau, elle se coucha au bord de la lumière, assez près pour être à moi, assez loin pour partir.

- EN “Go to the fire” / FR “Aller au feu” → `1200`

### `loyal_vica`: her loyalty scene (camp)

- **Button:** EN “Sit at the water with Vica” / FR “S’asseoir au bord de l’eau avec Vica”
- **Reads:** `devoted_vica`, `ally_vica` (the loyalty gate used by the other eight)
- **Hides when:** `vica_watch_kept` or `vica_watch_left`
- **Edit:** add `vica_loyal_done` to both choices
- Camp node: `4999_camp` for chapter 4 and after, as the other `loyal_*` scenes use.

**EN**

> Vica had been at the water’s edge since dusk, ears forward, facing the Hollow Shore. She did not look round when I came. She had smelled it for days: a wind from nowhere, cold, that carried no sound. She leaned back against my knee, once, so I would know she knew.

**FR**

> Vica était au bord de l’eau depuis le crépuscule, les oreilles en avant, face à la Rive Creuse. Elle ne se retourna pas quand j’arrivai. Elle le flairait depuis des jours : un vent venu de nulle part, froid, qui ne portait aucun bruit. Elle s’appuya une fois contre mon genou, pour que je sache qu’elle savait.

- EN “Keep the watch with her” / FR “Veiller avec elle”: sets `vica_watch_kept`, → `4999_camp`
- EN “Call her in” / FR “La rappeler au camp”: sets `vica_watch_left`, → `4999_camp`

### `beat2_vica`: her second beat (chapter 7)

- **Button:** EN “Meet Vica on the shore path” / FR “Retrouver Vica sur le sentier de la grève”
- **Reads:** `vica_loyal_done`, `banner_five`; **hides when** `vica_shore_taken` or `vica_camp_guarded`; choices → `7400`

**EN**

> At dusk Vica stood in the shore path and would not let me by. Not growling: standing, the way a door stands. She had decided something, and she waited for me to ask what, and I understood she did not mean to answer in words. She looked at the boats, and at me.

**FR**

> Au crépuscule, Vica se tint dans le sentier de la grève et ne me laissa pas passer. Sans grogner : debout, comme une porte est debout. Elle avait décidé quelque chose, et elle attendait que je demande quoi, et je compris qu’elle ne comptait pas répondre avec des mots. Elle regarda les barques, puis moi.

- EN “Take her to the shore” / FR “L’emmener à la grève”: sets `vica_shore_taken`
- EN “Ask her to guard the camp” / FR “Lui demander de garder le camp”: sets `vica_camp_guarded`

## Echo (optional, phase two)

The Muster `7800` already echoes the eight loyalty choices (priority 2). Each second beat can add a sentence there in the same way: `<c>_beat2_a` / `_b` callback lines, priority 2 (the cap of ten applies). That is 18 more lines and does not change what is above.

## Companion remarks

Each new flag can carry a story-choice remark from the other companions in the party, in the same way as P2: the keys are the flags above.
