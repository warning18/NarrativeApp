# Specialisations and fight-length words, EN and FR (Narrative, proposal)

The words for Core's **profession and clan design, v5.2** (`docs/proposals/profession-clan-mechanics.md` on `claude/core-3`, commit 4e3d992). Core imports this file into the data; Narrative owns the wording, Core owns the numbers.

**How to read it**
- Every text is given in EN then FR. Gifts say *what it does* without a figure; where a figure shows, it is Core's, written `{x}`: Core replaces it with the live number.
- FR is addressed with *vous* and never gendered for the player. Spec names are epicene (nouns of things or roles that take no agreement: *Guide du marais*, *Phare*, *Forge-piège*).
- **Names I changed from the working names**, and why:

| Working name | Final name | Why |
|---|---|---|
| Thorn-wall | **Briar Guard** | `warrior_thornwall` already exists as a skill |
| Holy warrior | **Lantern Vanguard** | generic; ties to the Dominion's Vanguard tree |
| Ember Sister (cleric) | **Ashen Hand** | the Ember Sisters are a sub-clan that offers a variant of it |
| Lantern Cantor | **Beacon** | the Cantors are a sub-clan that offers a variant of it |
| Inquisitor (mage) | **Censer Mage** | "Inquisitor" is already an enemy, an NPC and a sub-clan |
| Ash Chorister | **Burden-Bearer** | the Scorched Choir is a sub-clan; and it is the Penitents' motto |
| Storm Arcanist | **Tempest Toll** | "Arcanist" is already a training path; spells *collect* life, the Crows' way |
| Relic Thief | **Relicbreaker** | the Reliquary Thieves are a sub-clan; and they break what they steal |
| Corsair Marksman | **Corsair’s Eye** | epicene in FR, and the Verdict is a look before it is a shot |

Unchanged: Berserker, Long Vigil, Fever Blade, Ledger Knife, Trapwright, Fen Guide.

---

## 1. The five core mechanics

For each: **name**, **rule text** (one line, for the fight screen, with the figure Core confirms) and a **flavour line**.

### Warrior: Fury / Fureur
- **Rule:** Each blow you land or take adds 1 Fury. At 5, your next strike is a heavy blow and spends it all.
- **Règle :** Chaque coup porté ou reçu ajoute 1 de Fureur. À 5, votre prochaine frappe est un coup lourd et la dépense en entier.
- **Flavour:** The longer it lasts, the less you feel it, and the more it feels you.
- **Saveur :** Plus cela dure, moins vous le sentez, et plus cela vous sent.

### Cleric: Watchfire / Feu de guet
- **Rule:** Every heal from your die also burns the enemy for its amount. Healing past full feeds the fire.
- **Règle :** Chaque soin de votre dé brûle aussi l’ennemi d’autant. Un soin au-delà du plein nourrit le feu.
- **Flavour:** You were told to keep the lamp lit. Nobody said who it would burn.
- **Saveur :** On vous a dit d’entretenir la lampe. Personne n’a dit qui elle brûlerait.

### Mage: Ash Well / Puits de cendre
- **Rule:** You start each fight empty. Mana faces give double, spells cost 1 less, and mana left after a win heals you.
- **Règle :** Vous commencez chaque combat à vide. Les faces de mana donnent le double, les sorts coûtent 1 de moins, et le mana restant après une victoire vous soigne.
- **Flavour:** The well is dry on the way in. What you draw, you draw from the dice, and from nowhere else.
- **Saveur :** Le puits est à sec à l’entrée. Ce que vous puisez, vous le puisez dans les dés, et nulle part ailleurs.

### Rogue: Flurry / Rafale
- **Rule:** Every strike hits twice, and each hit rolls its own critical.
- **Règle :** Chaque frappe touche deux fois, et chaque coup tire son propre critique.
- **Flavour:** One hit is a question. Two is an answer.
- **Saveur :** Un coup est une question. Deux, une réponse.

### Ranger: The Trail / La Piste
- **Rule:** Each roll takes a face that has not come up yet in this run; you see the next one coming.
- **Règle :** Chaque jet prend une face qui n’est pas encore sortie dans cette série ; vous voyez venir la suivante.
- **Flavour:** Nothing comes twice before everything has come once. You only have to read it.
- **Saveur :** Rien ne revient avant que tout soit venu une fois. Il suffit de savoir lire.

---

## 2. The fifteen main specialisations

Each is the gift of a main clan, offered from Friend. Format: **name EN / FR**, **gift text**, **flavour in the clan’s voice**. Clan voices follow the mottoes: Dominion *One flame, one law*; Vigil *We do not look away*; Compact *What we make, we choose*; Mire *What the fen takes, the fen returns*; Crows *Every door has a price*; Penitents *We carry what we burned*.

### Warrior (Fury)

**Berserker / Berserker**, Crows
- **Gift:** Your Attack faces become Pain strikes: they hit for double, and the life you pay feeds your Fury.
- **Gift (FR) :** Vos faces d’Attaque deviennent des coups de Douleur : ils frappent au double, et la vie que vous payez nourrit votre Fureur.
- **Voice:** “Everything has a price. Be sure you can afford yours.”
- **Voix :** « Tout a un prix. Assurez-vous de pouvoir payer le vôtre. »

**Briar Guard / Garde-Ronce**, Compact
- **Gift:** Blows your block and armour stop feed your Fury, and a part of each goes back at the one who threw it. You can no longer dodge.
- **Gift (FR) :** Les coups que votre parade et votre armure arrêtent nourrissent votre Fureur, et une part de chacun retourne à qui l’a porté. Vous ne pouvez plus esquiver.
- **Voice:** “We do not strike first. We make the other regret it.”
- **Voix :** « Nous ne frappons pas les premiers. Nous faisons regretter à l’autre d’avoir commencé. »

**Lantern Vanguard / Avant-garde de la Lanterne**, Dominion
- **Gift:** Your heavy blow is Fire and Pierces. Against an Evil foe it also heals you.
- **Gift (FR) :** Votre coup lourd est de Feu et Perce. Contre un ennemi Mauvais, il vous soigne aussi.
- **Voice:** “One flame goes first. The rest of us follow its light.”
- **Voix :** « Une flamme passe la première. Nous suivons sa lumière. »

### Cleric (Watchfire)

**Long Vigil / Longue Veille**, Vigil
- **Gift:** While you stand above half health, you slowly mend each round.
- **Gift (FR) :** Tant que vous restez au-dessus de la moitié de votre vie, vous vous refaites doucement à chaque tour.
- **Voice:** “The watch does not ask whether you are tired.”
- **Voix :** « La veille ne demande pas si la nuit pèse. »

**Ashen Hand / Main de cendre**, Penitents
- **Gift:** When the fire burns, it also gives you 1 mana and cleanses one affliction.
- **Gift (FR) :** Quand le feu brûle, il vous donne aussi 1 de mana et purge une affliction.
- **Voice:** “What burned us can burn for others. That is the only mercy we know.”
- **Voix :** « Ce qui nous a brûlés peut brûler pour d’autres. C’est la seule pitié que nous connaissions. »

**Beacon / Phare**, Dominion
- **Gift:** The fire may hold all your health, and it burns every enemy at once, in Light.
- **Gift (FR) :** Le feu peut contenir toute votre vie, et il brûle tous les ennemis à la fois, en Lumière.
- **Voice:** “A lantern lights one door. A beacon lights the coast.”
- **Voix :** « Une lanterne éclaire une porte. Un phare éclaire la côte. »

### Mage (Ash Well)

**Censer Mage / Mage à l’encensoir**, Dominion
- **Gift:** Mana past full does not spill: it burns the enemy, in proportion to your strike.
- **Gift (FR) :** Le mana au-delà du plein ne se perd pas : il brûle l’ennemi, en proportion de votre frappe.
- **Voice:** “The censer swings. The smoke carries the verdict.”
- **Voix :** « L’encensoir oscille. La fumée porte le verdict. »

**Burden-Bearer / Porte-Fardeau**, Penitents
- **Gift:** A spell cast from a full Well hits harder.
- **Gift (FR) :** Un sort lancé d’un Puits plein frappe plus fort.
- **Voice:** “We carry it all the way. The blow is only where we put it down.”
- **Voix :** « Nous le portons jusqu’au bout. Le coup n’est que l’endroit où nous le posons. »

**Tempest Toll / Péage d’orage**, Crows
- **Gift:** Your spells take a share of their damage back as health, and Teleport Strike joins your offers.
- **Gift (FR) :** Vos sorts reprennent une part de leurs dégâts en vie, et la Frappe téléportée rejoint vos offres.
- **Voice:** “Storms are not free. We only make sure we are the ones who collect.”
- **Voix :** « Les orages ne sont pas gratuits. Nous veillons seulement à être ceux qui encaissent. »

### Rogue (Flurry)

**Fever Blade / Lame-fièvre**, Mire
- **Gift:** A critical hit leaves a lasting poison, the Rot, that stacks.
- **Gift (FR) :** Un coup critique laisse un poison durable, la Pourriture, qui s’accumule.
- **Voice:** “The fen is patient. So is the fever.”
- **Voix :** « Le marais est patient. La fièvre aussi. »

**Ledger Knife / Couteau du registre**, Crows
- **Gift:** Each hit that is not critical raises the chance of the next. A critical resets it and hits for double.
- **Gift (FR) :** Chaque coup non critique augmente la chance du suivant. Un critique la remet à zéro et frappe au double.
- **Voice:** “Every miss is a line in the ledger. One day the sum comes due.”
- **Voix :** « Chaque raté est une ligne au registre. Un jour, la somme tombe due. »

**Relicbreaker / Brise-relique**, Penitents
- **Gift:** Each critical hit gives you 1 mana.
- **Gift (FR) :** Chaque coup critique vous donne 1 de mana.
- **Voice:** “We do not keep the relic. We keep what falls out when it breaks.”
- **Voix :** « Nous ne gardons pas la relique. Nous gardons ce qui tombe quand elle se brise. »

### Ranger (the Trail)

**Corsair’s Eye / L’Œil du corsaire**, Crows
- **Gift:** The Verdict, the sixth face of a run, counts double and Pierces.
- **Gift (FR) :** Le Verdict, sixième face d’une série, compte double et Perce.
- **Voice:** “One shot, one door. Make it the right one.”
- **Voix :** « Un tir, une porte. Choisissez la bonne. »

**Trapwright / Forge-piège**, Compact
- **Gift:** The Verdict is a trap: it also stuns its target.
- **Gift (FR) :** Le Verdict est un piège : il étourdit aussi sa cible.
- **Voice:** “We do not chase. We build where the thing will walk.”
- **Voix :** « Nous ne poursuivons pas. Nous bâtissons là où la bête passera. »

**Fen Guide / Guide du marais**, Mire
- **Gift:** The first face of each run poisons its target.
- **Gift (FR) :** La première face de chaque série empoisonne sa cible.
- **Voice:** “Follow me, and step where I step. The fen will do the rest.”
- **Voix :** « Suivez-moi, et posez le pied où je pose le mien. Le marais fera le reste. »

---

## 3. The thirty sub-clan variants

Two per specialisation: a **variant** changes how the gift works, an **upgrade** raises it. Each has a name, text and a line in the sub-clan’s voice. Offered from Trusted, and only if you already hold the main gift.

### On the Berserker

**Tar-Hands: Bleeding Hull / Coque qui saigne** (variant)
- **Text:** The life you pay is not lost: it bleeds the enemy instead.
- **Texte :** La vie que vous payez n’est pas perdue : elle fait saigner l’ennemi.
- **Voice:** “What leaks from you, we caulk into them.”
- **Voix :** « Ce qui fuit de vous, nous le calfatons en eux. »

**Brig-Born: Boarding Heart / Cœur d’abordage** (upgrade)
- **Text:** A kill heals you a tenth of your health.
- **Texte :** Une mise à mort vous rend un dixième de votre vie.
- **Voice:** “You win the deck, you keep the breath.”
- **Voix :** « Qui gagne le pont garde le souffle. »

### On the Briar Guard

**Quarrymen: Cut Stone / Pierre taillée** (variant)
- **Text:** A blow you send back also breaks the guard of whoever threw it.
- **Texte :** Un coup que vous renvoyez brise aussi la garde de qui l’a porté.
- **Voice:** “Stone does not argue. It just sits where you were going.”
- **Voix :** « La pierre ne discute pas. Elle se met là où vous alliez. »

**Anvil-Deaf: Hand-Signed Wall / Mur signé** (variant)
- **Text:** Half of each blow you stop goes back at the one who threw it, and you can no longer use Heal faces.
- **Texte :** La moitié de chaque coup que vous arrêtez retourne à qui l’a porté, et vous ne pouvez plus utiliser les faces de Soin.
- **Voice:** *(signed, so a few words)* “We hear nothing. We feel everything.”
- **Voix :** *(par signes, donc peu de mots)* « Nous n’entendons rien. Nous sentons tout. »

### On the Lantern Vanguard

**Order of the Vigilant Flame: Fallen Knight’s Fire / Feu du chevalier tombé** (upgrade)
- **Text:** Against an Evil foe, the heavy blow heals you a tenth of its damage.
- **Texte :** Contre un ennemi Mauvais, le coup lourd vous rend un dixième de ses dégâts.
- **Voice:** “Brave, proud, losing. Let us at least lose forward.”
- **Voix :** « Braves, fiers, perdants. Perdons au moins en avançant. »

**Inquisition: Name on the List / Nom sur la liste** (variant)
- **Text:** The heavy blow also weakens the foe it strikes.
- **Texte :** Le coup lourd affaiblit aussi l’ennemi qu’il frappe.
- **Voice:** “First comes the name. Then the flame.”
- **Voix :** « D’abord le nom. Ensuite la flamme. »

### On the Long Vigil

**Candlebearers: Counted Breath / Souffle compté** (upgrade)
- **Text:** You mend faster each round while above half health.
- **Texte :** Vous vous refaites plus vite à chaque tour tant que vous dépassez la moitié de votre vie.
- **Voice:** “Count the dead. Count the living. Make sure the sum does not move.”
- **Voix :** « Comptez les morts. Comptez les vivants. Veillez à ce que la somme ne bouge pas. »

**Last Watch: Spear at the Wall / Lance au rempart** (variant)
- **Text:** Your Defend faces feed the fire.
- **Texte :** Vos faces de Défense nourrissent le feu.
- **Voice:** “The new moon comes. We are on the wall.”
- **Voix :** « La nouvelle lune vient. Nous sommes sur le mur. »

### On the Ashen Hand

**Ember Sisters: One More Bed / Un lit de plus** (upgrade)
- **Text:** The fire cleanses two afflictions instead of one.
- **Texte :** Le feu purge deux afflictions au lieu d’une.
- **Voice:** “No one is turned away. Not the marked. Not the burned.”
- **Voix :** « Personne n’est renvoyé. Ni les marqués, ni les brûlés. »

**Road Exorcists: Honest Fire / Feu honnête** (variant)
- **Text:** The fire’s burn is Light, and strikes what the Shroud left in people.
- **Texte :** La brûlure du feu est de Lumière, et frappe ce que le Linceul a laissé dans les gens.
- **Voice:** “No theatre. No pyre. Just the thing, and the door out.”
- **Voix :** « Pas de théâtre. Pas de bûcher. La chose, et la porte de sortie. »

### On the Beacon

**Cantors of the Flame: Bell-Voiced / Voix de cloche** (upgrade)
- **Text:** The fire burns harder.
- **Texte :** Le feu brûle plus fort.
- **Voice:** “The hour is rung. The flame answers.”
- **Voix :** « L’heure est sonnée. La flamme répond. »

**Wickwardens: Keep the Light / Garder la lumière** (variant)
- **Text:** The fire lasts one round longer after it is last fed.
- **Texte :** Le feu dure un tour de plus après sa dernière alimentation.
- **Voice:** “A light kept is a light that stays.”
- **Voix :** « Une lumière gardée est une lumière qui reste. »

### On the Censer Mage

**Inquisition: The Accusing Smoke / La fumée accusatrice** (variant)
- **Text:** The burn from overflowing mana also weakens the foe.
- **Texte :** La brûlure du mana qui déborde affaiblit aussi l’ennemi.
- **Voice:** “The smoke has already named you.”
- **Voix :** « La fumée vous a déjà nommé. »

**Tribunal of the Spire: One Witness, Once / Un témoin, une fois** (variant)
- **Text:** Once per fight, you may refill the Well in full.
- **Texte :** Une fois par combat, vous pouvez remplir le Puits entièrement.
- **Voice:** “The court hears the case once. Make it count.”
- **Voix :** « La cour entend l’affaire une seule fois. Qu’elle compte. »

### On the Burden-Bearer

**Scorched Choir: The Name Sung / Le nom chanté** (upgrade)
- **Text:** A spell cast from a full Well hits much harder.
- **Texte :** Un sort lancé d’un Puits plein frappe beaucoup plus fort.
- **Voice:** “One name a night. The last one is the loudest.”
- **Voix :** « Un nom chaque nuit. Le dernier est le plus fort. »

**Spire-Fallen: Broken Sword, Open Hand / Épée brisée, main ouverte** (variant)
- **Text:** A spell cast from a full Well also heals you.
- **Texte :** Un sort lancé d’un Puits plein vous soigne aussi.
- **Voice:** “We broke the sword. What is left is for carrying.”
- **Voix :** « Nous avons brisé l’épée. Ce qui reste sert à porter. »

### On the Tempest Toll

**Keyholders: One Door / Une porte** (variant)
- **Text:** Teleport Strike joins your offers.
- **Texte :** La Frappe téléportée rejoint vos offres.
- **Voice:** “One key, one door. You are the door.”
- **Voix :** « Une clef, une porte. La porte, c’est vous. »

**Whisper Ledger: A Letter Opened / Une lettre ouverte** (variant)
- **Text:** Your spells also steal a few coins from the foe.
- **Texte :** Vos sorts volent aussi quelques pièces à l’ennemi.
- **Voice:** “Everything someone carries is somebody’s information.”
- **Voix :** « Ce que chacun porte est l’information de quelqu’un. »

### On the Fever Blade

**Barkbleeders: Tapped Sap / Sève tirée** (variant)
- **Text:** When a poisoned enemy falls, its poison passes to the next.
- **Texte :** Quand un ennemi empoisonné tombe, son poison passe au suivant.
- **Voice:** “The tree gives to the cut. The cut gives on.”
- **Voix :** « L’arbre donne à l’entaille. L’entaille donne plus loin. »

**Moss Choir: A Song Sung Over It / Un chant dessus** (variant)
- **Text:** The Rot also heals you a fifth of what it takes.
- **Texte :** La Pourriture vous soigne aussi d’un cinquième de ce qu’elle prend.
- **Voice:** “Every poison is a remedy for someone.”
- **Voix :** « Chaque poison est le remède de quelqu’un. »

### On the Ledger Knife

**Whisper Ledger: Entered in Full / Inscrit en entier** (variant)
- **Text:** Your critical hits steal a few coins.
- **Texte :** Vos coups critiques volent quelques pièces.
- **Voice:** “Never miss an entry.”
- **Voix :** « Ne manquez jamais une écriture. »

**Drowned Debt: Debt Forgiven / Dette remise** (variant)
- **Text:** A critical hit gives back the chain it spent.
- **Texte :** Un coup critique rend la chaîne qu’il a dépensée.
- **Voice:** “The link is paid. Start another.”
- **Voix :** « Le maillon est payé. Commencez-en un autre. »

### On the Relicbreaker

**Reliquary Thieves: Twice the Spoil / Double butin** (upgrade)
- **Text:** Each critical hit gives 2 mana.
- **Texte :** Chaque coup critique donne 2 de mana.
- **Voice:** “Look the other way. We’ll be quick.”
- **Voix :** « Regardez ailleurs. Nous serons rapides. »

**Ember Sisters: Warm Hands / Mains chaudes** (variant)
- **Text:** The mana from critical hits also heals you.
- **Texte :** Le mana des coups critiques vous soigne aussi.
- **Voice:** “What we take from the Inquisition we give back to the burned.”
- **Voix :** « Ce que nous prenons à l’Inquisition, nous le rendons aux brûlés. »

### On the Corsair’s Eye

**Brig-Born: Broadside / Bordée** (upgrade)
- **Text:** Your ship’s guns hit harder.
- **Texte :** Les canons de votre navire frappent plus fort.
- **Voice:** “Beat them at sea, or beat them in the water after.”
- **Voix :** « Battez-les en mer, ou battez-les dans l’eau ensuite. »

**Drowned Debt: Paid in the Deep / Payé par le fond** (variant)
- **Text:** A kill reshuffles your deck of faces.
- **Texte :** Une mise à mort rebat votre jeu de faces.
- **Voice:** “Each debt settled starts the next.”
- **Voix :** « Chaque dette réglée ouvre la suivante. »

### On the Trapwright

**Scaffolders: Take It Down / Abattre** (variant)
- **Text:** The Verdict’s stun reaches a second target.
- **Texte :** L’étourdissement du Verdict atteint une deuxième cible.
- **Voice:** “We built the gallows. We know where the weight goes.”
- **Voix :** « Nous avons bâti la potence. Nous savons où va le poids. »

**Quarrymen: Stone Trap / Piège de pierre** (variant)
- **Text:** The Verdict’s trap also breaks its target’s guard.
- **Texte :** Le piège du Verdict brise aussi la garde de sa cible.
- **Voice:** “A good wall holds. A good trap lets it fall.”
- **Voix :** « Un bon mur tient. Un bon piège le laisse tomber. »

### On the Fen Guide

**Heron’s Wake: Wading Step / Pas dans l’eau** (variant)
- **Text:** The first face’s poison also slows its target.
- **Texte :** Le poison de la première face ralentit aussi sa cible.
- **Voice:** “Go in without a guide and you may come out someone else.”
- **Voix :** « Entrez sans guide et vous pourriez ressortir quelqu’un d’autre. »

**The Returned: Seen From the Other Side / Vu de l’autre côté** (variant)
- **Text:** You see two faces ahead of the Trail instead of one.
- **Texte :** Vous voyez deux faces à l’avance sur la Piste au lieu d’une.
- **Voice:** “We have already been where you are going.”
- **Voix :** « Nous avons déjà été là où vous allez. »

> **Sub-clan reuse.** The Quarrymen and the Tar-Hands etc. each appear under two or three specialisations; every offer has its own name, so none repeats.

---

## 4. Fight-length lines

Words for the mechanics on Core’s menu. **On-screen labels** are short; **lines** are the log or the story beat.

### Default rules

**Healing fatigue**
- **Label:** Wearying heal / Soin qui s’épuise
- **Line:** Each healing feels a little thinner than the last.
- **Ligne :** Chaque soin paraît un peu plus mince que le précédent.

**Execute**
- **Label:** Finishing blow / Coup de grâce
- **Line:** Hurt this badly, the foe cannot stand a clean strike.
- **Ligne :** Si mal en point, l’ennemi ne peut plus encaisser un coup net.

### Morale: a foe flees

- **Label over the foe:** Wavering / Vacillant
- **Flee line, for a person:** The {foe} drops the blade and runs.
- **Ligne de fuite, personne :** {foe} lâche son arme et s’enfuit.
- **Flee line, for a beast:** The {foe} breaks off and bolts into the dark.
- **Ligne de fuite, bête :** {foe} rompt le combat et file dans le noir.
- **The choice:** the fight is won either way; the loot is lost either way. The choice is whether to let the foe go.

| | Button EN | Bouton FR | Line EN | Ligne FR | Alignment |
|---|---|---|---|---|---|
| **Spare** | Let it go | Le laisser partir | You lower your hand. The {foe} does not look back. | Vous baissez la main. {foe} ne se retourne pas. | toward Good |
| **Finish** | Cut it down | L’achever | It is easy. That is the worst of it. | C’est facile. C’est le pire. | toward Evil |

- **Never offered** against undead, constructs and bosses.

### The pack breaks

- **Label:** The pack breaks / La meute rompt
- **Line:** The captain falls and the rest lose their nerve; they scatter.
- **Ligne :** Le chef tombe et les autres perdent courage ; ils se dispersent.
- **For beasts:** The leader falls. The pack stops being a pack.
- **Bêtes :** Le chef tombe. La meute cesse d’être une meute.

### Boss enrage

- **Warning, round 8:** The {boss} is growing restless. It will not wait much longer.
- **Avertissement, tour 8 :** {boss} s’impatiente. Il ne va plus attendre longtemps.
- **Enrage, round 10:** The {boss} stops testing you.
- **Fureur, tour 10 :** {boss} cesse de vous éprouver.
- **On-screen label:** Enraged / En rage

### The Tide (fallback)

- **Label:** The Tide / La Marée
- **Line, round 8:** The fight tilts. Both sides feel the wave coming, and neither can step back.
- **Ligne :** Le combat bascule. Les deux camps sentent venir la vague, et aucun ne peut reculer.
- **Rule text:** From round 8, every round your blows grow stronger, and the enemies’ more slowly.
- **Règle :** Dès le tour 8, vos coups gagnent en force à chaque tour, ceux des ennemis plus lentement.

### Rising ground

Each: **omen** (round 5), **line** (round 6, it begins), **gauge label**.

**Marsh mist (reeds, fens)**
- **Omen:** A green haze lifts from the reeds.
- **Présage :** Une brume verte monte des roseaux.
- **Line:** The mist is in your throat. It is in theirs, too.
- **Ligne :** La brume est dans votre gorge. Elle est aussi dans la leur.
- **Gauge:** Mist / Brume

**Desert heat (dunes, salt flats)**
- **Omen:** The air begins to shimmer.
- **Présage :** L’air se met à trembler.
- **Line:** The heat takes something from everyone, and lets nothing heal.
- **Ligne :** La chaleur prend quelque chose à chacun, et ne laisse rien guérir.
- **Gauge:** Heat / Chaleur

**Rising tide (shores, cliffs)**
- **Omen:** The water has crept up the stones.
- **Présage :** L’eau a gagné les pierres.
- **Line:** The tide is at your knees, and it does not choose sides.
- **Ligne :** La marée vous monte aux genoux, et elle ne choisit pas son camp.
- **Gauge:** Tide / Marée

**Collapsing ruin (ruins, halls)**
- **Omen:** Dust sifts down from the vault.
- **Présage :** La poussière filtre de la voûte.
- **Line:** The roof gives a little more each round. Neither of you has time to be careful.
- **Ligne :** Le toit cède un peu plus à chaque tour. Ni l’un ni l’autre n’a le temps d’être prudent.
- **Gauge:** Ruin / Ruine

**Sanctified chapel (shrines, chapels)**
- **Omen:** The candles gutter, though there is no wind.
- **Présage :** Les bougies faiblissent, bien qu’il n’y ait pas de vent.
- **Line:** The place disapproves of mending. It approves of the light that strikes.
- **Ligne :** Le lieu désapprouve qu’on se refasse. Il approuve la lumière qui frappe.
- **Gauge:** Sanctity / Sainteté

### Beasts tire, the dead crumble

- **Beasts, round 6:** The {foe} is panting. Its blows come slower.
- **Bêtes :** {foe} halète. Ses coups viennent plus lentement.
- **The dead, round 6:** The {foe} is coming apart. It does not seem to mind.
- **Les morts :** {foe} se défait. Il n’a pas l’air de s’en soucier.

### Reinforcements

**Allies arrive (Friend or better, in a zone a clan holds)**
- **Banner label:** {clan} reinforcements / Renforts : {clan}
- **Line:** A banner shows at the edge of the field. {clan} did not forget who they owe.
- **Ligne :** Une bannière paraît au bord du champ. {clan} n’a pas oublié ce qu’on lui doit.

**Hunters arrive (hunted in that zone)**
- **Banner label:** {clan} hunters / Chasseurs : {clan}
- **Line:** A horn sounds from the road behind you. They have been following a while.
- **Ligne :** Un cor sonne sur la route derrière vous. Ils vous suivent depuis un moment.

### Town guards

- **Label:** The watch / Le guet
- **Line, round 6:** A whistle. Boots on cobbles. The watch is coming to end this.
- **Ligne :** Un sifflet. Des bottes sur les pavés. Le guet vient mettre fin à tout cela.
- **If you were ahead on health:** The watch drags your foe away and notes you were not the one losing. You may go.
- **Si vous aviez l’avantage :** Le guet traîne votre adversaire et note que ce n’était pas vous qui perdiez. Vous pouvez partir.
- **Otherwise:** The watch parts you both. Neither of you walks away richer.
- **Sinon :** Le guet vous sépare. Aucun de vous deux ne repart plus riche.

---

## 5. Rivals cooling

**Template** (for every pair; Core fills the placeholders):
- **EN:** The favour of {patron} cools {rival} ({n} this chapter).
- **FR :** La faveur de {patron} refroidit {rival} ({n} ce chapitre).
- **Warming:** The favour of {patron} warms {ally} (+{n} this chapter). / La faveur de {patron} réchauffe {ally} (+{n} ce chapitre).

`{patron}` and `{rival}` use the clan’s `short` name in the language, with the right article (see the table below). Spelled out for the pairs where the drift applies. Chapter figures are Core’s: −2 for a rival at Trusted, −4 at Sworn, −2 for a tense neighbour at Sworn, +1 for an ally at Sworn.

### Cooling (relations 1 to 4)

| Patron → Rival | EN | FR |
|---|---|---|
| Dominion → Vigil | The Dominion’s favour cools the Vigil ({n} this chapter). | La faveur du Dominion refroidit la Veille ({n} ce chapitre). |
| Vigil → Dominion | The Vigil’s favour cools the Dominion ({n} this chapter). | La faveur de la Veille refroidit le Dominion ({n} ce chapitre). |
| Dominion → Mire | The Dominion’s favour cools the Mire ({n} this chapter). | La faveur du Dominion refroidit le Marais ({n} ce chapitre). |
| Mire → Dominion | The Mire’s favour cools the Dominion ({n} this chapter). | La faveur du Marais refroidit le Dominion ({n} ce chapitre). |
| Dominion → Penitents | The Dominion’s favour cools the Penitents ({n} this chapter). | La faveur du Dominion refroidit les Pénitents ({n} ce chapitre). |
| Penitents → Dominion | The Penitents’ favour cools the Dominion ({n} this chapter). | La faveur des Pénitents refroidit le Dominion ({n} ce chapitre). |
| Dominion → Compact *(tense)* | The Dominion’s favour cools the Compact a little ({n} this chapter). | La faveur du Dominion refroidit un peu le Pacte ({n} ce chapitre). |
| Compact → Dominion *(tense)* | The Compact’s favour cools the Dominion a little ({n} this chapter). | La faveur du Pacte refroidit un peu le Dominion ({n} ce chapitre). |
| Vigil → Crows | The Vigil’s favour cools the Crows ({n} this chapter). | La faveur de la Veille refroidit les Corneilles ({n} ce chapitre). |
| Crows → Vigil | The Crows’ favour cools the Vigil ({n} this chapter). | La faveur des Corneilles refroidit la Veille ({n} ce chapitre). |
| Compact → Penitents | The Compact’s favour cools the Penitents ({n} this chapter). | La faveur du Pacte refroidit les Pénitents ({n} ce chapitre). |
| Penitents → Compact | The Penitents’ favour cools the Compact ({n} this chapter). | La faveur des Pénitents refroidit le Pacte ({n} ce chapitre). |
| Mire → Penitents | The Mire’s favour cools the Penitents ({n} this chapter). | La faveur du Marais refroidit les Pénitents ({n} ce chapitre). |
| Penitents → Mire | The Penitents’ favour cools the Mire ({n} this chapter). | La faveur des Pénitents refroidit le Marais ({n} ce chapitre). |

### Warming (relations 6 to 7)

| Patron → Ally | EN | FR |
|---|---|---|
| Dominion → Crows | The Dominion’s favour warms the Crows (+{n} this chapter). | La faveur du Dominion réchauffe les Corneilles (+{n} ce chapitre). |
| Crows → Dominion | The Crows’ favour warms the Dominion (+{n} this chapter). | La faveur des Corneilles réchauffe le Dominion (+{n} ce chapitre). |
| Vigil → Compact | The Vigil’s favour warms the Compact (+{n} this chapter). | La faveur de la Veille réchauffe le Pacte (+{n} ce chapitre). |
| Compact → Vigil | The Compact’s favour warms the Vigil (+{n} this chapter). | La faveur du Pacte réchauffe la Veille (+{n} ce chapitre). |
| Vigil → Penitents | The Vigil’s favour warms the Penitents (+{n} this chapter). | La faveur de la Veille réchauffe les Pénitents (+{n} ce chapitre). |
| Penitents → Vigil | The Penitents’ favour warms the Vigil (+{n} this chapter). | La faveur des Pénitents réchauffe la Veille (+{n} ce chapitre). |
| Compact → Mire | The Compact’s favour warms the Mire (+{n} this chapter). | La faveur du Pacte réchauffe le Marais (+{n} ce chapitre). |
| Mire → Compact | The Mire’s favour warms the Compact (+{n} this chapter). | La faveur du Marais réchauffe le Pacte (+{n} ce chapitre). |

**Pairs with no line** (relation 5, Wary or neutral, no drift): Vigil–Mire, Compact–Crows, Mire–Crows, Crows–Penitents.

**Note.** The relations reasons already exist in `relations.json` (*the Edict of the Marked*, *the broken Charter*, …). If UX wants a tooltip under the line, Core can show the pair’s `reason` there.

---

## What this does not cover

- The **weaker-link gifts** (Wall Veteran, Moss Singer, Hex-Weaver, Tar Snare, Stitcher, Ember Adept, Admiralty Gunner, Ash Penitent) and the **minor directions** (Dark knight, Blood mage, Paladin) are in v5.2’s table but were not on this brief. I can name and write them in a second pass once the first set is in.
- The **skill verbs** (v5.2 “More skills in play”) are marked [N] in the design. They are a separate list and can follow this one.
