# The six nemesis quests and their champions (Narrative, proposal)

The words for PR 5 of `docs/proposals/territory-power-nemesis.md`, after the outline in `territory-texts.md` §6. English then French. Core fits them to the data schema; the **ids are working names** (`nemq_<clan>` for the quest, `nemq_<clan>_champion` for the boss), and every figure, reward and boss stat is Core's.

**How each quest runs** (the same five beats for all six, so one engine path serves them):
1. **The word** — offered when the clan becomes your nemesis; the giver is a neutral third party, never the clan.
2. **The trail** — one step to learn where the champion can be met (a talk or a visit).
3. **The way in** — one choice with three doors: **Force**, **Guile**, **Mercy** (the last gives the champion's own people a chance to stand down first). Each sets a flag, `nemq_<clan>_force|guile|mercy`; Core may turn the flag into an edge in the fight (a round of Fury, a foe weakened, an ally at the gate).
4. **The champion** — the boss fight.
5. **The break** — the aftermath line, the news line, and the flag `nemesis_broken_<clan>` that Core's `breakNemesis` reads.

French: *vous*, never gendered for the player; the champions are fixed characters, so their own gender is stated in the text.

---

## 1. The Dominion: *The List of Oaths* / *Le Registre des serments*

**Champion: High Lantern-Bearer Orsolya Keld** / *Haute Porte-Lanterne Orsolya Keld*
- **Description:** The First Lantern's warden, who keeps in her own hand the list of every oath sworn under its light. She has never forgotten a name, and she has yours.
- **Description (FR):** La gardienne de la Première Lanterne, qui tient de sa main le registre de tous les serments prêtés sous sa lumière. Elle n’a jamais oublié un nom, et elle a le vôtre.
- **Battle cry:** “One flame, one law. I wrote your name in it myself.”
- **Cri (FR) :** « Une flamme, une loi. J’y ai écrit votre nom de ma propre main. »

**1. The word.** *A clerk who owes you nothing finds you.*
- EN: “The Lantern has stopped asking, and started counting. There is a list, and a woman who keeps it. As long as she does, nothing the Dominion holds will open to you. I would not go near her. I am telling you where she is.”
- FR : « La Lanterne a cessé de demander ; elle compte. Il existe un registre, et une femme qui le tient. Tant qu’elle le tiendra, rien de ce que possède le Dominion ne s’ouvrira devant vous. Je n’irais pas la voir. Je vous dis seulement où elle est. »

**2. The trail.** *Objective:* find the Lantern Hall's lower stair. EN: “Find the stair beneath the Lantern Hall.” / FR : « Trouvez l’escalier sous la Salle de la Lanterne. »

**3. The way in.**
- **Force** — EN: *Take the stair by the front.* / FR : *Prendre l’escalier de front.*
- **Guile** — EN: *Walk in with a forged page of the list.* / FR : *Entrer avec une fausse page du registre.*
- **Mercy** — EN: *Offer her clerks the night off.* / FR : *Offrir à ses scribes une nuit de congé.*

**4. The champion.** Intro — EN: She does not look up from the page. “You are the next entry. Wait there, please. I am nearly done.” / FR : Elle ne lève pas les yeux de la page. « Vous êtes l’entrée suivante. Attendez là, je vous prie. J’ai presque fini. »

**5. The break.**
- EN: The page stays blank where your name was. Orsolya Keld is carried from the hall, and for the first time in forty years the list is short. The Dominion does not forgive you. It does, however, stop counting.
- FR : La page reste vierge là où se trouvait votre nom. Orsolya Keld est emportée hors de la salle, et pour la première fois en quarante ans, le registre est incomplet. Le Dominion ne vous pardonne pas. Mais il cesse de compter.
- **News (EN/FR):** *The Dominion’s List of Oaths is torn.* / *Le registre des serments du Dominion est déchiré.*

---

## 2. The Salt Crows: *A Debt Called In* / *Une dette exigible*

**Champion: Captain Mireille Sable** / *Capitaine Mireille Sable*
- **Description:** The Crows’ collector, who has never lost a debt and never raised her voice to collect one. Her ledger is bound in sailcloth, and the last page is yours.
- **Description (FR) :** La percepteuse des Corneilles, qui n’a jamais perdu une créance ni élevé la voix pour en réclamer une. Son registre est relié de toile à voile, et la dernière page est la vôtre.
- **Battle cry:** “Every door has a price. I have come for yours.”
- **Cri (FR) :** « Toute porte a son prix. Je suis venue chercher le vôtre. »

**1. The word.**
- EN: A dockhand hands you a tarred slip. “She is owed, and she is patient, and she is here. If you pay in blood, she takes it. If you pay in coin, she takes that too. She just wants to be paid.”
- FR : Un docker vous tend un billet goudronné. « Elle est créancière, elle est patiente, et elle est là. Si vous payez en sang, elle le prend. Si vous payez en pièces, elle les prend aussi. Elle veut seulement être payée. »

**2. The trail.** EN: “Find the boat the collector keeps at Smugglers’ Wharf.” / FR : « Trouvez le bateau que la percepteuse garde au Quai des Contrebandiers. »

**3. The way in.**
- **Force** — EN: *Board her boat by night.* / FR : *Monter à bord de son bateau de nuit.*
- **Guile** — EN: *Sell her the debt to someone else.* / FR : *Lui revendre la dette par un autre.*
- **Mercy** — EN: *Pay what you owe, and ask her to stop.* / FR : *Payer ce que vous devez, et lui demander de s’arrêter.*

**4. The champion.** Intro — EN: She is counting coins into a purse when you step aboard. “You are early. Put it on the table. I will tell you whether it is enough.” / FR : Elle compte des pièces dans une bourse quand vous montez à bord. « Vous êtes en avance. Posez cela sur la table. Je vous dirai si cela suffit. »

**5. The break.**
- EN: The ledger goes into the harbour with her sailcloth wrapping. Nobody on the wharf says your debt is paid. Nobody says it is owed, either.
- FR : Le registre part au port avec sa toile à voile. Personne sur le quai ne dit que votre dette est payée. Personne ne dit non plus qu’elle est due.
- **News:** *The Salt Crows’ collector is gone from the wharf.* / *La percepteuse des Corneilles a quitté le quai.*

---

## 3. The Cinder Compact: *The Last Hammer* / *Le dernier marteau*

**Champion: Master Hollis Reck** / *Maître Hollis Reck*
- **Description:** The Charter’s last hammer, who broke every other on its own anvil so that the table’s rule would stay unbroken. He is the only man left who remembers why it was made.
- **Description (FR) :** Le dernier marteau de la Charte, qui a brisé tous les autres sur sa propre enclume pour que la règle de la table reste intacte. Il est le seul à se souvenir encore pourquoi elle fut faite.
- **Battle cry:** “What we make, we choose. And we choose not to make you.”
- **Cri (FR) :** « Ce que nous forgeons, nous le choisissons. Et nous choisissons de ne pas vous forger. »

**1. The word.**
- EN: An old smith wipes her hands. “The Compact has a rule, and Hollis Reck is the rule with a face. He will not move for gold. He will not move for fear. If you are going to him, go with something he made.”
- FR : Une vieille forgeronne s’essuie les mains. « Le Pacte a une règle, et Hollis Reck est cette règle avec un visage. Il ne bougera ni pour l’or ni pour la peur. Si vous allez le voir, allez-y avec quelque chose qu’il a forgé. »

**2. The trail.** EN: “Find the cold forge of Cinder Row.” / FR : « Trouvez la forge froide de la Rue des Braises. »

**3. The way in.**
- **Force** — EN: *Break the forge door.* / FR : *Défoncer la porte de la forge.*
- **Guile** — EN: *Bring one of his own old blades, and ask him to mend it.* / FR : *Apporter une de ses anciennes lames et lui demander de la réparer.*
- **Mercy** — EN: *Sit down at the table and ask for a hearing.* / FR : *S’asseoir à la table et demander à être entendu.*

**4. The champion.** Intro — EN: He does not turn from the anvil. “Every hammer in the Row broke on this. You may try yours.” / FR : Il ne se détourne pas de l’enclume. « Chaque marteau de la Rue s’est brisé là-dessus. Vous pouvez essayer le vôtre. »

**5. The break.**
- EN: The last hammer rings once on the stone and does not ring again. When you walk out through Cinder Row nobody calls you maker, but nobody closes a door on you either.
- FR : Le dernier marteau sonne une fois sur la pierre et ne sonne plus. Quand vous traversez la Rue des Braises, personne ne vous appelle artisan, mais personne ne ferme sa porte devant vous.
- **News:** *The Compact’s last hammer is silent.* / *Le dernier marteau du Pacte s’est tu.*

---

## 4. The Grey Vigil: *The Hour Unwatched* / *L’heure sans veille*

**Champion: Watch-Captain Edda Grey** / *Capitaine du Guet Edda Grey*
- **Description:** The Vigil’s eyes on the ridge. She has not looked away from the tear in thirty-eight years, and does not mean to start with you.
- **Description (FR) :** Les yeux de la Veille sur la crête. Elle n’a pas détourné le regard de la déchirure depuis trente-huit ans, et ne compte pas commencer avec vous.
- **Battle cry:** “We do not look away. I have not looked away from you since you left.”
- **Cri (FR) :** « Nous ne détournons pas le regard. Mes yeux ne vous ont pas lâché depuis votre départ. »

**1. The word.**
- EN: A sentry on a lonely road, lantern shuttered. “She has seen you. She sees everything, from there. If you are going up, go in the dark hour, when even she must blink.”
- FR : Une sentinelle sur une route déserte, sa lanterne voilée. « Elle vous a vu. Elle voit tout, de là-haut. Si vous montez, montez à l’heure noire, quand même elle doit cligner des yeux. »

**2. The trail.** EN: “Climb to the ridge post above Rimewell.” / FR : « Montez au poste de la crête, au-dessus de Rimewell. »

**3. The way in.**
- **Force** — EN: *Take the ridge by the front stair.* / FR : *Prendre la crête par l’escalier de face.*
- **Guile** — EN: *Go up in the dark hour, unlit.* / FR : *Monter à l’heure noire, sans lumière.*
- **Mercy** — EN: *Take the watch a lamp, and sit it with her.* / FR : *Apporter une lampe au guet et veiller avec elle.*

**4. The champion.** Intro — EN: She stands at the parapet with her back to you and her eyes on the tear. “Thirty-eight years. You could have asked me for the hour.” / FR : Elle se tient au parapet, dos tourné, les yeux sur la déchirure. « Trente-huit ans. Vous auriez pu me demander l’heure. »

**5. The break.**
- EN: For the first time since the Vigil was founded, the post above Rimewell is dark for an hour. Nothing comes through. Down in the valley, someone lights a second lamp.
- FR : Pour la première fois depuis la fondation de la Veille, le poste au-dessus de Rimewell reste sombre une heure entière. Rien ne passe. Dans la vallée, quelqu’un allume une seconde lampe.
- **News:** *The Vigil’s ridge post has gone dark for an hour.* / *Le poste de la Veille sur la crête est resté sombre une heure.*

---

## 5. The Ashen Penitents: *The Weight Set Down* / *Le poids déposé*

**Champion: The Ash Confessor** / *La Confesseuse de Cendre*
- **Description:** The Penitents’ voice, who burned her own face to hear confession better. She has never put the lantern down, and has never asked anyone else to carry it.
- **Description (FR) :** La voix des Pénitents, qui s’est brûlé le visage pour mieux entendre les confessions. Elle n’a jamais posé sa lanterne, et n’a jamais demandé à personne de la porter.
- **Battle cry:** “What you burned, you will carry. Let me show you its weight.”
- **Cri (FR) :** « Ce que vous avez brûlé, vous le porterez. Laissez-moi vous en montrer le poids. »

**1. The word.**
- EN: A penitent on the Exorcists’ Road, ash to the elbows. “She hears everything, and forgives only what is carried to her on foot. Whoever goes to her hands over more than they meant to.”
- FR : Une pénitente sur la route des Exorcistes, la cendre jusqu’aux coudes. « Elle entend tout, et ne pardonne que ce qu’on lui apporte à pied. Qui va la voir lui remet plus qu’il ne comptait. »

**2. The trail.** EN: “Walk the Exorcists’ Road to the Wall of Names.” / FR : « Parcourez la route des Exorcistes jusqu’au Mur des Noms. »

**3. The way in.**
- **Force** — EN: *Walk in with your blade out.* / FR : *Entrer lame au clair.*
- **Guile** — EN: *Confess something false, and see who answers.* / FR : *Confesser une chose fausse et voir qui répond.*
- **Mercy** — EN: *Carry a stone from the road, and set it down before her.* / FR : *Porter une pierre de la route et la déposer devant elle.*

**4. The champion.** Intro — EN: The lantern in her hand burns no flame. “Kneel, and tell me everything. Or stand, and I will tell you.” / FR : La lanterne qu’elle tient ne brûle d’aucune flamme. « Agenouillez-vous et dites-moi tout. Ou restez debout, et c’est moi qui vous le dirai. »

**5. The break.**
- EN: The lantern goes out in her hand, and for the first time, nobody lifts it. The penitents on the road stop walking, one by one, and look at the sky.
- FR : La lanterne s’éteint dans sa main, et pour la première fois, personne ne la relève. Sur la route, les pénitents s’arrêtent un à un et lèvent les yeux au ciel.
- **News:** *The Ash Confessor’s lantern is out.* / *La lanterne de la Confesseuse de Cendre est éteinte.*

---

## 6. The Mire Courts: *The Court’s Courtesy* / *La courtoisie de la Cour*

**Champion: The Heron Queen’s Hand** / *La Main de la Reine-Héron*
- **Description:** The Court’s courtesy, armed. It has never once been rude, and has never once been refused. Nobody outside the Mire has seen its face and kept the memory.
- **Description (FR) :** La courtoisie de la Cour, en armes. Elle n’a jamais été impolie, et n’a jamais essuyé de refus. Nul, hors du Marais, n’a vu son visage sans en perdre le souvenir.
- **Battle cry:** “You have been most patient. The Court thanks you, and regrets the rest.”
- **Cri (FR) :** « Vous avez été patient. La Cour vous en remercie, et regrette le reste. »

**1. The word.**
- EN: A heron stands in the shallows and does not move. A voice from the reeds: “The Court has sent for you. It is polite. It is always polite. That is the worst of it.”
- FR : Un héron se tient dans les bas-fonds, immobile. Une voix, dans les roseaux : « La Cour vous a fait appeler. Elle est polie. Elle est toujours polie. C’est le pire. »

**2. The trail.** EN: “Follow the heron into the fen, and don’t ask where it is going.” / FR : « Suivez le héron dans le marais, et ne demandez pas où il va. »

**3. The way in.**
- **Force** — EN: *Wade straight to the Court.* / FR : *Marcher droit vers la Cour.*
- **Guile** — EN: *Arrive with every courtesy, and a lie in each.* / FR : *Arriver avec toutes les politesses, et un mensonge dans chacune.*
- **Mercy** — EN: *Sit, and let the Court speak first.* / FR : *S’asseoir et laisser la Cour parler d’abord.*

**4. The champion.** Intro — EN: The chairs are set. One of them is for you. “Sit. Please. We have been so looking forward to this.” / FR : Les sièges sont dressés. L’un est pour vous. « Asseyez-vous, je vous prie. Nous attendions ce moment avec tant d’impatience. »

**5. The break.**
- EN: The Hand folds like a heron into the water. The chairs stay set. In the Court, someone says very quietly that it was, after all, a most courteous defeat.
- FR : La Main se replie comme un héron dans l’eau. Les sièges restent dressés. Dans la Cour, quelqu’un dit très bas que ce fut, tout compte fait, une défaite fort courtoise.
- **News:** *The Mire’s Court has lost its Hand.* / *La Cour du Marais a perdu sa Main.*

---

## The void hound’s battle cry

The void hound hunts a Good character from chapter 5 (alignment −35).
- **EN:** *(no words; a low sound like water running uphill)*
- **FR :** *(aucun mot ; un grondement sourd, comme l’eau qui remonte la pente)*

(This is a line for `battleCry` / `battleCry_fr`; the stalker kept its own.)
