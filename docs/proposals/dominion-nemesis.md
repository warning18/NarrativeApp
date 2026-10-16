# The Dominion as the starting nemesis: story check and texts (Narrative)

Answers to Core's questions about making the Dominion the nemesis from the first chapter, and the texts for it. The user's reason, as the manager passed it on: **you hold a piece of the banner (the Shroud), and the Dominion wants it. Lysa is not the reason.** So the hunt is the same whether Lysa was saved or lost.

## The story agrees

The motive is already on the page before the nemesis could matter:
- Node 300, the street: the Inquisitors tear up the floorboards and hold every scrap of cloth against a drawing. “They had not come for her, or not only. They were looking for something.”
- Node 470: the piece is under the trapdoor, in the oilcloth. “What they wanted had never been under a board.”
- Node 7520 (the Lantern Hall): Vane wanted the player’s blood for his rite before he knew their name.
One sentence in the opening could say it more plainly (Vane asking where the cloth is); I will add it with the Lysa arc, not now.

## 1. Where the player can side with the Dominion, and what should end the nemesis

Standing gains with the Dominion in the story (from `politics.standing.dominion` on choices):

| Chapter | Where | Standing | Flag |
|---|---|---|---|
| 2 | the Houses’ small jobs (Keyholders’ key sold to an Inquisition patrol, the Salt Ledger’s tenth) | +5 each | `hub_2015_house_*` |
| 3 | the three envoys at the Ashen Quarter’s gate (Vane’s purse, Morrow’s whetstone, Tallis’s oil) | +5 each | `envoy_gift_vane`, `_morrow`, `_tallis` |
| 5 | clan step 1, shield the flame and climb | +10 | `clan_dominion_step_1` |
| 6 | clan step 2, swear the Warden let it through | +15 | `clan_dominion_step_2`, `witness_lie` |
| 7 | clan step 3, leave it closed: the Houses stand with you | +10 | `clan_dominion_step_3` |
| 7 | the legate’s pact and its crown (7002) | +20 | `inquisition_pact` |
| 7 | the Throne vote (7002): back Vane / Morrow / Tallis | +15 / +10 / +5 | `throne_backed_vane` etc. |

**Friendly (+12) is enough to end the nemesis**, and it is reachable from chapter 5 (clan step 1, plus one envoy gift). Two moments are a hard turn, not a slow one, and I would let them end it outright: `inquisition_pact` (the player takes the legate’s pact and crown) and `throne_backed_vane`.

## 2. Sister-rescue beat

There is none today. On the lost branch (`lysa_lost`) the player finds her dead (`lysa_found_dead`) or fights her unknowing in a porcelain mask (`lysa_fallen`). The user asked for a better Lysa story: see `docs/proposals/lysa-arc.md`. **Rescuing her should not end the nemesis**, since Lysa is not why the Dominion hunts. Leave it to standing, to `inquisition_pact`, and to the nemesis quest.

## 3. Texts

**The nemesis panel line (EN/FR):**
- EN: Your family kept a piece of the Shroud, and the Lantern wants it. The Dominion has hunted you since the night your house fell.
- FR : Votre famille gardait un pan du Linceul, et la Lanterne le veut. Le Dominion vous traque depuis la nuit où votre maison s’est effondrée.

**The `q_nemesis_dominion` offer, for a chapter-4 start after a story-long enmity** (replaces the stranger’s warning of the first draft; “a Wickwarden’s lamp-boy” keeps it a courier, not a clerk):
- EN: A Wickwarden’s lamp-boy catches up with you at the roadside, out of breath. “Your name is on the List, and the High Lantern-Bearer has read it aloud in the Hall. The Lantern has wanted the piece of the Shroud you carry since the night your house fell. She has finished sending others.”
- FR : Le garçon de lampe d’un Garde-Mèche vous rattrape au bord de la route, hors d’haleine. « Votre nom est au Registre, et la Haute Porte-Lanterne l’a lu tout haut dans la Salle. La Lanterne veut le pan de Linceul que vous portez depuis la nuit où votre maison s’est effondrée. Elle a fini d’envoyer d’autres. »
