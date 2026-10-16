# Lysa’s story: an arc proposal (Narrative)

The user asked for Lysa’s story to be improved: she can be saved, and there should also be choices where the player kills her. This is the plan, before any node is written. Docs only. Each point marked **[user]** is a decision for the user.

## 1. What is in the game now

| Branch | Where | What happens | Flags |
|---|---|---|---|
| Opening (ch. 1, node 400) | the house | Charge Vane and win: she is saved. Run, kneel, or lose: Vane carries her off. | `lysa_survived` / `lysa_lost` (+ `fled_house`, `surrendered`, `unfurl_lost`) |
| Saved | ch. 1–4 | She walks with you; one line of her per chapter (the crash, the caravan, the wharf, the camp’s healer). | `lysa_shielded`, `lysa_held`, `lysa_sent_coin` |
| Saved | ch. 5, Reliquary Quarter (6010) | You find her tending the sick. Take her to the camp or leave her. | `lysa_to_camp` / `lysa_stays_quarter` |
| Lost | ch. 3 (3005_envoys) | A line: “He had my sister.” | |
| Lost | ch. 5 (6010_thread) | The Inquisition’s list: “held at the Quarter; the rite has not taken.” | |
| Lost | ch. 5 (6010_masked) | A masked penitent comes at you. The only choice is “Fight her”; the mask comes off afterwards and it is Lysa. | `lysa_fallen`, then `lysa_mask_kept` / `lysa_left_masked` |
| Lost | ch. 5 (6010_lysa_dead) | Or you find her dead in the chapel chair, your name scratched twelve times. | `lysa_found_dead` |
| Both | ch. 7–8 (7001, 7004, 7005, 7520) | One-line echoes by flag. | |

## 2. What is weak

1. **The lost branch has no agency.** The player never decides anything about Lysa after chapter 1: they kill her blind, or find her dead. Nothing to rescue, bargain for, or choose to end.
2. **The Dominion’s use of her is two lines.** It is never tied to the banner piece, which is the real reason the Dominion hunts.
3. **How you lost her does not matter.** Running, kneeling and losing the fight all lead to the same Quarter scene.
4. **The saved branch is risk-free.** Lysa is a healer in the background; nothing can happen to her, and nothing she does costs you.
5. **Her end is not a choice anywhere.** There is no moment where the player decides to end her life, for any reason.

## 3. The lost branch: the Quarter’s prisoner

**Principle.** How you lost her in chapter 1 sets what the Dominion made of her. She is kept in the Reliquary Quarter, at the chair in the chapel (6010), under Brother Clement’s hand (the porcelain-masked torturer of the Black Hold, who already told you she was dead).

| How she was lost (ch. 1) | Her state when you reach her (ch. 5) | Why |
|---|---|---|
| Knelt and begged (`surrendered`) | **Whole.** “The rite has not taken.” She is wary of you, not hateful. | The Dominion kept her gentle, as a lever. |
| Fought and lost (`unfurl_lost`) | **Half-turned.** She says your name through the mask; she may or may not know who you are. | She was kept long, and taught. |
| Ran (`fled_house`) | **Turned.** The mask is on; she says your name as an accusation. | You left her with them for a year. |

**Finding her (new, light).** Three small beats, only on `lysa_lost`:
1. **Chapter 2, Saltmouth.** The Whisper Ledger’s Needle sells a line: *a girl from Tallow Street, moved inland.* (A Crows hook; ties to the court.)
2. **Chapter 3, the Ashen Quarter envoys.** Vane’s envoy now names a price: *the piece for the girl.* The player can refuse, stall, or ask for proof. Nothing is decided yet; it sets `lysa_offer_heard`.
3. **Chapter 4, the camp.** A black thread knotted to your door (as in the story already) with a child’s mask under it. It points to the Reliquary Quarter. Sets `lysa_trail`.

**The Quarter scene (6010_masked, rewritten).** Before any blade is drawn she speaks your name through the mask, and the player chooses. The options depend on her state, shown in the table.

| Choice | What it is | Outcome | Flags | Alignment |
|---|---|---|---|---|
| **Rescue by force** | Break the chair-chapel: fight Brother Clement and the white masks (a new boss: **[Core]** needs an enemy) | She comes out alive; whole → she joins the camp as healer, half-turned → she keeps the mask and speaks little, turned → she will not follow you but will not stop you either | `lysa_rescued_force` | + (more if whole) |
| **Bargain: the piece** | Hand Clement the heirloom piece for her | She is returned alive. The piece goes to the Dominion and the Shroud is short one until it is taken back (a ch. 6 beat, or the nemesis quest’s end). **[user]** is that acceptable, or must the piece never leave the player? | `lysa_piece_lent` | − (small) |
| **Bargain: your word** | Swear to the Lantern for her | She is returned alive. Your standing with the Dominion rises to Friendly, which ends the nemesis under Core’s rule; the Penitents and the Vigil cool. She does not forgive the oath. | `lysa_sworn_for` | − |
| **Mercy** | If she is turned or half-turned, and the rite has taken: end it | She dies quickly, in your arms, without the mask. | `lysa_mercy` | + (small) or neutral |
| **Execution** | She is turned and comes at you: fight her knowing who she is | She falls; the mask comes off. (This is the current `lysa_fallen`, now a choice.) | `lysa_fallen` (kept) | − |
| **Sacrifice** | Put her blood on the Shroud to wake it | She dies on the piece; the Shroud takes the blood and warms: a banner boon **[Core]** and a mark with the Void. | `lysa_sacrificed` | − − |

Rules: *Rescue by force* and *Bargain* are available at every state; *Mercy* only when the rite has taken (half-turned, turned); *Execution* only when turned; *Sacrifice* at every state, always the darkest. Taking *Rescue by force* with her turned fails: she will not follow, and the choice reverts to Mercy or Execution. **[user]** do you want a state where rescue is impossible?

## 4. The saved branch: what can go wrong

The goal: Lysa is a person whose safety is on the table, not scenery. Four possible beats, each a small scene, each a decision for you:

| Beat | When | The risk | The choice | Flags |
|---|---|---|---|---|
| **The raid** | ch. 4, the camp | The Inquisition comes for her (the list says *at large, with the cloth*) | Guard the camp, or go for the Spire and leave her to the wall | `lysa_taken_ch4` if you go; `lysa_guarded` if you stay |
| **The ledger** | ch. 5–6 | Lysa, healing the Quarter’s sick, trades the *copy* of a page to buy medicine; the Dominion learns where you are | Forgive her, scold her, or burn the ledger | `lysa_traded` / `lysa_forgiven` |
| **The fever** | ch. 6 | She is dying of what she heals; stay or go | Take her to the camp (exists), or let her finish | `lysa_stays_quarter` (kept) |
| **The stitch** | ch. 7, the Hollow Shore | **Sewing the tear shut** needs a stitcher of the family’s blood; Lysa offers | Let her; do it yourself; or give up the sewing | `lysa_stitched` (she dies), `lysa_spared_stitch`, `lysa_replaced` |

**[user]** The last is the one that can cost her life. It makes the sewing ending the costliest of the four, which fits it; but it takes something from a path that is, today, the gentle one.

If `lysa_taken_ch4`, she re-joins the lost branch from the Quarter scene (section 3), in the *whole* state, with the same six choices. So the saved and lost branches meet.

## 5. What each ending does to the Dominion, and to the epilogue

The hunt **never ends because of Lysa**: the Dominion wants the piece. What the endings change is how hard it hunts and what it does in the Hall.

| Ending | The Dominion’s hunt | Echoes: 7001 / 7004 / 7005 / 7520 |
|---|---|---|
| Rescued by force | **Fiercer**: Clement is dead, the Inquisition marks you a foe (`politics.marks.inquisition: foe`) | She is at the camp, cold toward the Penitents; Vane: “the girl I let go” |
| Piece lent | Stays; the Dominion holds the piece until you take it back | Her hands are shaking when you return it; Vane smiles at the piece |
| Sworn for her | **Eases**: Friendly ends the nemesis; Vane treats you as the Lantern’s | She does not speak of it; at the Hall, Vane: “you owed us a debt, and paid it” |
| Mercy | Stays | You carry her mask home; 7004 keeps `lysa_mask_kept`; no Vane line about her |
| Execution | Stays; Vane asks, kindly, whether the mask fitted (exists: `lysa_fallen`) | as today |
| Sacrifice | **Fiercer**: the Shroud now sings and the Lantern can hear it; Keld arrives sooner | The dawn at 7005 is gold and empty; she is the face in the tear in 7004 |
| Saved and kept (no beat taken) | Stays | as today |
| Stitched | Stays | A final scene at the Hollow Shore; the epilogue names her |

Rule for the alignment: the cruel choices cost 3 to 6 points, the kind ones give 2 to 5, the sacrifice costs 8. Core sets the numbers; I give only the direction.

## 6. Consistency checks

- **Companions.** Lysa is not a companion (the companions are Kelda, Sable, Maren, Liora, Vess, Grosh, Tobin, Malrik). She stays an NPC. I would keep Liora’s healing distinct from hers: Liora is a hand-healer of the camp; Lysa is the one who heals *because* she lost something.
- **Brother Clement** is the Black Hold torturer (node 800, “a man in a porcelain mask… Brother Clement”); using him as her handler needs one new line in 6010 and a **[Core]** enemy for the boss fight.
- **The hunters.** The masked penitent in the enemies is the same figure; if Lysa is the masked penitent in the lost branch, the hunter version on the road is a different person, and I would write it as such.
- **Node 800** already says “They told me Lysa was dead”: this proposal keeps it and makes it the Dominion’s lie.

## 7. What I will write once this is approved

New nodes: the Needle line (ch. 2), the envoy’s price (ch. 3), the thread and mask (ch. 4), the rewritten Quarter scene with its six outcomes (ch. 5), a Clement fight node, and the saved-branch beats (raid, ledger, stitch). Also the matching `flag_callbacks` in 7001, 7004, 7005 and 7520, EN and FR. I ask **Core** for: the Clement enemy, the banner boon for the sacrifice, the alignment numbers, and the piece’s handling if it is lent.
