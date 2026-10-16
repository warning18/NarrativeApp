# The courts of the six clans (Narrative)

Each main clan now has a way of ruling and a court of 8 to 9 people, ranked from the leader down. 49 in all: 22 existing characters placed in the hierarchy, 27 new where a rank was empty. The way of ruling is `ruling` / `ruling_fr` on each clan in `factions.json`; each person carries `clan`, `rank` (1 = leader), `title` / `title_fr`, `stanceLeader` (loyal, scheming, wavering) and `stancePlayer` (open, neutral, wary, hostile, or unseen) in `npcs.json`. Descriptions, wants and a line of dialogue are in the file, EN and FR.

**Notes for Core / UX**
- The `faction` field on an existing person (a sub-clan) is unchanged; `clan` is the main clan.
- A new person has no `metNodes`, `metFlags` or `shopId`, so the People codex treats them as *legacy*: known from their `chapter`. If you would rather the court only appear on the clan card (or after the clan is met), say so and I will gate them.
- The six champions and the two unseen sovereigns (the Lantern-Bearer, the Heron Queen) are now people in `npcs.json` too.

### dominion

The Dominion is a theocracy under a single voice. The Lantern-Bearer speaks the will of the First Lantern, and nothing is law until it is spoken; the Order, the Inquisition, the Tribunal, the Admiralty and the Wickwardens each rule a flame beneath it and answer for it. A Lantern-Bearer is not elected: the flame is passed to the name given in the last breath of the one before, and taken away only by death, or by the Houses’ vote at the Lantern Throne when the voice fails. A member owes the oath, the tithe, and their name on the List.

| Rank | Name | Title | Stance to the leader | Stance to you | |
|---|---|---|---|---|---|
| 1 | The Lantern-Bearer | Voice of the First Lantern | (leader) | unseen | new |
| 2 | Aurel Vane | Inquisitor-General | scheming | hostile | existing |
| 3 | Hesk Morrow | Grand Master of the Order | scheming | wary | existing |
| 4 | Maud Tallis | Eldest Wickwarden | loyal | open | existing |
| 5 | High Lantern-Bearer Orsolya Keld | High Lantern-Bearer, Keeper of the List | loyal | hostile | new |
| 6 | The High Warden | Commander of the Crusade | loyal | hostile | existing |
| 7 | Magister Corvane | Magister of the Cantors, keeper of the tithe | loyal | wary | existing |
| 8 | Overseer Renn | Overseer, Inquisition customs | wavering | wary | existing |
| 9 | The courier in black crape | Courier of the crape | loyal | neutral | existing |

### vigil

The Vigil is a chain of watches, and rank is the length of your longest unbroken hour. Every post goes to whoever last kept it without looking away; each captain names the one who will relieve them, and the Warden-in-Chief is simply the watch nobody has yet relieved. A leader is removed by the rule that raised them: a missed hour, a glance turned aside, and the next in the chain takes the lamp without a vote. A member owes their hours, and the truth about the count.

| Rank | Name | Title | Stance to the leader | Stance to you | |
|---|---|---|---|---|---|
| 1 | Joss Harrow | Warden-in-Chief | (leader) | wary | new |
| 2 | Watch-Captain Edda Grey | Watch-Captain of the Ridge | loyal | hostile | new |
| 3 | Wickwarden Tallis | Keeper of the Last Lantern | loyal | open | existing |
| 4 | Halvard | Spearman of the Last Watch | wavering | hostile | new |
| 5 | Ysel | Candlebearer, keeper of the count | loyal | wary | new |
| 6 | Orsabet Vell | Candlebearer widow | wavering | open | existing |
| 7 | Cade Rowan | Watch-Lieutenant | scheming | neutral | new |
| 8 | Tam | Lamp-boy of the ridge post | loyal | open | new |

### compact

The Compact is a table, not a throne. Seven masters of the crafts sit at the Charter’s table, each with one stone, and a Speaker chairs it without a casting vote. Nothing is made, sold or sworn that the table has not allowed, and it decides by the stones, one hand each. A Speaker is raised by five stones and removed by five; the Charter binds the Speaker as hard as the apprentice. A member owes restraint: a blade made only by invitation, and the table’s rule kept even when it costs.

| Rank | Name | Title | Stance to the leader | Stance to you | |
|---|---|---|---|---|---|
| 1 | Speaker Odalys Fenn | Speaker of the Table | (leader) | wary | new |
| 2 | Master Hollis Reck | Master of the Charter | loyal | hostile | new |
| 3 | Orrin Vell | Master smith | loyal | open | existing |
| 4 | Hesta Brann | Master of the Quarrymen | wavering | open | existing |
| 5 | Dorran Quill | Master of the Scaffolders | scheming | open | existing |
| 6 | Dagny Ironhand | Master of the Anvil-Deaf | loyal | neutral | existing |
| 7 | Tally-Master Corin Ashdown | Tally-Master of the Table | scheming | wary | new |
| 8 | Kit Emberly | Coal-runner of Cinder Row | loyal | open | new |

### mire

The Mire Courts are ruled by courtesy and inherited favour. The Heron Queen sits at the Court and is never seen to command; her wishes arrive as invitations, and no one in the fen declines one. Favour passes down like land: a house keeps its place by the courtesies it is owed, and a Queen is not deposed but invited to step into the water, which she does with great grace. A member owes their word, kept to the minute, and a courtesy for every discourtesy received.

| Rank | Name | Title | Stance to the leader | Stance to you | |
|---|---|---|---|---|---|
| 1 | The Heron Queen | The Heron Queen | (leader) | unseen | new |
| 2 | The Heron Queen’s Hand | The Queen’s Hand | loyal | hostile | new |
| 3 | Dame Hesper Mere | Seneschal of Favours | loyal | wary | new |
| 4 | Lady Perrin Mere | Heir of the House of Mere | scheming | neutral | new |
| 5 | Sister Ysolde | Apothecary of the Courts | loyal | open | existing |
| 6 | Brannoc Reedtithe | Healer of the Barkbleeders | wavering | open | existing |
| 7 | Wen | Guide of the Heron’s Wake | loyal | wary | new |
| 8 | Sedge | One of the Returned | loyal | wary | new |

### crows

The Salt Crows are a syndicate of captains, run on debt. Seven captains hold seats on the Wharf by the contracts they own, and the First Captain is whoever is owed the most; the Keyholders keep the ledger’s doors, and no door opens with fewer than two keys. A First Captain falls when their debts are bought out from under them, which is how every captain before them rose. A member owes the one thing the Crows ask of anyone: a paid contract is honoured, and an unpaid one was never a contract.

| Rank | Name | Title | Stance to the leader | Stance to you | |
|---|---|---|---|---|---|
| 1 | First Captain Tamsin Brask | First Captain | (leader) | wary | new |
| 2 | Captain Mireille Sable | Collector of the Syndicate | loyal | hostile | new |
| 3 | The Keyholder | First Keyholder | loyal | neutral | existing |
| 4 | The Keyholder | Second Keyholder, keeper of the Vault | wavering | neutral | existing |
| 5 | Brine Jack | Captain of the Wreckers | scheming | hostile | new |
| 6 | Needle | Keeper of the Whisper Ledger | scheming | wary | existing |
| 7 | Nkem Tallow | Brig-Born salvager | wavering | open | existing |
| 8 | A Crow with no name | Fence of the Tide Cellar | loyal | neutral | existing |

### penitents

The Ashen Penitents rank their members by what they carry. Each confesses a burden before the others and takes up a lantern with no flame in it; the heavier the confessed weight, the higher the seat, and the Eldest is the one whose burden the rest agree is heaviest. A leader falls the day they put the lantern down, or the day another’s confession outweighs theirs. A member owes a burden carried in public, a confession made in full, and the road walked on foot.

| Rank | Name | Title | Stance to the leader | Stance to you | |
|---|---|---|---|---|---|
| 1 | Eldest Aldith Crowe | Eldest of the Ashen Penitents | (leader) | wary | new |
| 2 | The Ash Confessor | The Ash Confessor | loyal | hostile | new |
| 3 | The Masked Penitent | The Masked Penitent | wavering | hostile | new |
| 4 | Brother Anselm Voe | Knight of the Spire-Fallen | scheming | neutral | new |
| 5 | Sister Inès | Acolyte of the Quarter’s shrine | wavering | open | existing |
| 6 | A deserter called Hask | Trader of relics | scheming | neutral | existing |
| 7 | Sister Odile | Ember Sister, nurse of the Quarter | loyal | open | new |
| 8 | Old Wick | Ash-sweeper of the Wall of Names | loyal | open | new |
