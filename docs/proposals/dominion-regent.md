# The Lantern Dominion's boss: Regent Cassian Oriel

The user's feedback on the Design Codex: two "Aurel Vane, Inquisitor-General" enemies. Keep the chapter 1 man (`aurel_vane`); give the chapter 7 boss of the Lantern clan a character of his own.

## Who he is

**Cassian Oriel, Regent of the Lantern** (`cassian_oriel`; Régent de la Lanterne). The Lantern-Bearer has not been seen in a year, and the Dominion's law says nothing is law until the Voice speaks it. Oriel has spoken in the failing Voice's place for eleven years, and has stopped hearing the difference. He holds the Lantern Hall and the Hooded Lantern on its chain. Aurel Vane is his Inquisitor-General, his hunting hand: the man who came to Alster for the tear and the blood is the Regent's instrument, and the Regent wants it more.

- Court: Dominion rank 2, directly under the Voice. The other Dominion people moved down one rank (Vane is now 3).
- `claimant_vane` keeps its id (combat, world map, icons and balance test use it); only its name and lore changed. No numbers, skills or loot changed.
- The three claimants are now the Regent (the Dominion's own, "an inquisition"), Morrow (a crusade) and Tallis (a church). The flag ids `envoy_gift_vane`, `throne_backed_vane`, `throne_vane`, `dominion_leader_vane`, `intrigue_hooded_lantern_*` keep their names (internal ids); their texts now say the Regent.

## Where Aurel went

- Chapters 1 to 6: unchanged (Alster, the Lysa arc, the envoy at the Ashen Quarter, who now brings the Regent's purse as well as his own message).
- Chapter 7: he stands a step behind the Regent in the Lantern Hall. If you take the Regent alive, he kneels in chains beside him; if you burn the Regent, he slips out by the Hall's back stair before the fire and nobody follows him. If the pact path makes him the player's Hand (`dominion_hand_vane`), that line is unchanged.
- After the throne is filled, Aurel signs the writ that hunts the Open Hand, in the Regent's name.

## Look (for the icon)

A slight, courteous man in the Dominion's white, a tide-blue and gold sash, hair silver at the temples, holding the great Hooded Lantern on a chain (the hood a black cowl; when he unhoods it, an eye where the flame should be). Taller lanterns hang on the wall behind him. Not armoured. Aurel's own small hooded lantern at his collar is a copy of this one.

## Touched

`enemies.json` (`claimant_vane` name, description, encounter text, two phase messages), `npcs.json` (`cassian_oriel`, Aurel's states, Dominion ranks), `Cleaned_Narrative_DAG.json` (3005_envoys, 6100_knife, 7002_throne, 7500, 7510_*, 7520_vane, 7590_*), `politics_events.json`, `intrigues.json` (`dying_lantern_bearer`), `items.json` (the staff's description), `city_plans.json` (one building name).
