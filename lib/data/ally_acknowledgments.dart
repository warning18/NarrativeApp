/// A companion's voice inside the story text: a sentence appended to a
/// scene when an ally is active, in that companion's own words where one
/// is authored for them and a party-wide default otherwise. Resolved off
/// the player's *current* party (see [withAllyAcknowledgment]) rather than
/// a snapshot story flag, so it always reflects who is walking beside the
/// character right now, including a party that changed since the last
/// camp visit.
///
/// Keyed by node id, then by companion id; `'*'` is the default for any
/// active party.
const Map<String, Map<String, String>> _acksEn = {
  '891': {
    '*': ' Someone kept pace with me the whole way down to the water, which '
        'I had not asked for and did not, when it came to it, mind.',
    'vess': ' Vess ran beside me without seeming to hurry, as though the '
        'docks were somewhere she had already been and merely intended to '
        'arrive at again.',
  },
  '2001': {
    '*': ' I was not, for once, the only one watching the shore burn from '
        'the rail, and the company made the fire smaller.',
    'vess': " Vess watched the fire with the flat attention of someone "
        "comparing it to another. \"It goes out,\" she said. \"Eventually. "
        "Everything I have watched burn has.\"",
  },
  '2015': {
    '*': ' Whoever was walking with me kept a hand near a weapon and an '
        'eye on the crowd, and the crowd, sensibly, gave us room.',
    'kelda': ' Kelda walked the wharf the way she had held the gate, as '
        'though it were a wall someone had asked her to keep, and the '
        'stallholders straightened as she passed.',
    'sable': ' Sable had already priced every stall we passed and, I '
        'suspected, lightened at least one of them. "Browsing," she said, '
        'when I looked at her.',
    'liora': ' Liora counted the rooftops as we went, and named two she '
        'would have chosen, and one she would have avoided.',
  },
  '2900': {
    '*': ' Whoever had come down to the berths with me looked at the Eel '
        'the way I looked at her, and did not say what we were both '
        'thinking, which was that she was a great deal of boat to trust '
        'with a great deal of sea.',
    'kelda': " \"She floats,\" Kelda said, kicking the hull. \"Mostly. I "
        "float worse.\" It was the closest thing to a joke I had heard from "
        "her, and she meant every word.",
    'sable': ' Sable had already been aboard, without being asked, and came '
        'back up the gangway with a list of everything the Eel was missing '
        'and a smaller list of where to steal it.',
    'liora': ' Liora looked at the sail, and the torn place in it, and '
        'said nothing, and started coiling rope as though the coiling were '
        'an argument she intended to win.',
    'vess': ' Vess put her palm flat on the hull below the waterline, where '
        'the pike had gone through, and held it there, and when she took it '
        'away the wood was dry. "Not for long," she said. "But long enough '
        'to get to the pitch."',
  },
  '2900_boat_fixed': {
    '*': ' The crew stood along the rail and looked at the wharf and did '
        'not look at me, which was their way of leaving the deciding where '
        'it belonged.',
    'kelda': ' Kelda counted the wharf the way she counted a wall: heads, '
        'then hands, then the ones who could hold a line. "Twenty," she '
        'said. "Twenty-five if they sit still. They will not sit still."',
    'sable': ' "Stores go over," Sable said, before I had asked anyone '
        'anything, "or people stay. I have done the sum. I did not like it '
        'either."',
    'liora': ' Liora had gone up the mast and was looking past the wharf to '
        'the Upper Tier, where the drums were, and counting something I did '
        'not want to know the total of.',
    'vess': ' Vess stood at the gangway with her hood back so the wharf '
        'could see what she was, and the ones who stepped back from her '
        'were, she told me later, the ones she would have left.',
  },
  '2999': {
    '*': ' The crew looked at me across the tilted deck the way a crew '
        'looks at the one who has to say it, and I understood that whatever '
        'I said next would be repeated, later, in a dry place, by whoever '
        'was left to repeat it.',
    'kelda': ' Kelda was at the tiller already, both arms around it, and '
        'shouted over the sea that whatever I decided I should decide it '
        'before the next wave, because the next wave was not going to wait '
        'for a discussion.',
    'sable': ' Sable was cutting lashings free without waiting for the '
        'order, which she would later describe as anticipating it.',
    'liora': ' Liora had one arm through the shrouds and the other around '
        'a child from the wharf, and was not, whatever I decided, going to '
        'let go of either.',
    'vess': ' The thread in Vess had gone white in the storm-light, and she '
        'was talking to the sea, quietly, in a language it seemed to be '
        'listening to.',
  },
  '4999_standard': {
    '*': ' The ones who had come into the sanctum with me stood back from '
        'the Warden and the grey showing through his white, and gave me the '
        'room, and the silence, that the next hour needed.',
    'kelda': ' "He held the wrong thing," Kelda said, looking down at him, '
        '"but he held it. Do not make him wait for the sake of it."',
    'maren': ' Maren knelt at his head, where he could see her, and told '
        'him what a cleric tells a dying man, and did not tell me what to '
        'do, which from her was a mercy I had not expected.',
    'grosh': ' Grosh turned his back on the Warden and watched the '
        'sanctum door. "Cathedral is burning," he said. "Whatever you do, '
        'do it before the roof does."',
    'vess': ' Vess could not take her eyes off the grey in the standard. '
        '"It is the same cloth," she said. "It knows what you are going to '
        'do. It is waiting to see how."',
  },
  '5004_altar': {
    '*': ' Nobody who had come down with me said anything at the altar. '
        'There was nothing to say that the twelve sleepers in the grey were '
        'not already saying.',
    'maren': ' Maren went from sleeper to sleeper with her hand on each '
        'forehead, and when she had touched the last she looked at me and '
        'shook her head, very slightly, at a question I had not asked aloud.',
    'tobin': ' Tobin began the hymn for the dying and stopped after two '
        'bars. "They are not," he said. "Yet. That is the whole of the '
        'problem, is it not."',
    'sable': ' "Quick," Sable said, "whichever way. Quick is the only kind '
        'thing left in this room." She did not look at the sleepers when '
        'she said it.',
    'liora': ' Liora had her bow half-drawn at the sleepers before she '
        'understood what they were, and lowered it slowly, and did not '
        'raise it again.',
  },
  '6010_thread': {
    '*': ' The chapel was too small for the company I kept, and they '
        'waited at the door, and every one of them found somewhere else to '
        'look.',
    'malrik': ' Malrik priced the reliquary from the door out of habit, and '
        'caught himself, and for the first time since I had known him did '
        'not name the figure.',
    'maren': ' Maren asked the chart-keeper her sister\'s name, and said '
        'it back to her, and that was the only prayer said in that chapel.',
    'tobin': ' Tobin put his hammer down outside the door before he came '
        'in, which I understood to be the nearest thing to taking off his '
        'boots that a dwarf has.',
    'vess': ' Vess stood as far from the reliquary as the chapel allowed. '
        '"It knows me," she said. "The thread in it. Do not let it out near '
        'me."',
  },
  '7002_price': {
    '*': ' The crew heard the price with me, and I watched each of them do '
        'the sum, and I watched more than one of them come to the same '
        'answer and step forward before I could speak.',
    'kelda': ' Kelda stepped forward before I had finished hearing the '
        'price, shield still on her arm. "I go first," she said. "I always '
        'go first. This is not different."',
    'sable': ' Sable stepped forward before I had finished hearing the '
        'price. "Somebody has to," she said, "and I am the only one here '
        'who has robbed a door before."',
    'maren': ' Maren stepped forward before I had finished hearing the '
        'price, and did not argue it, and did not let me argue it either.',
    'liora': ' Liora stepped forward before I had finished hearing the '
        'price, unstrung her bow, and handed it to me. "Nine arrows," she '
        'said. "Use them."',
    'vess': ' Vess stepped forward before I had finished hearing the price. '
        '"It knows my name," she said. "Let it have the rest of me. It will '
        'choke on it."',
    'grosh': ' Grosh stepped forward before I had finished hearing the '
        'price, and said nothing, because he had never in his life needed '
        'to.',
    'tobin': ' Tobin stepped forward before I had finished hearing the '
        'price, humming, and did not stop humming, and the reflections on '
        'the sand turned to listen.',
    'malrik': ' Malrik stepped forward before I had finished hearing the '
        'price. "First pick," he said. "I did say." He was not smiling. It '
        'was the first time.',
  },
  '7002_pact': {
    '*': ' The crew had gone very quiet behind me, and I did not need to '
        'turn around to know who was standing closest to the legate\'s '
        'boat, or why.',
    'kelda': ' Kelda had moved, without a word, to stand between me and the '
        'legate\'s boat, and she had her shield up, and it was not raised '
        'against him.',
    'maren': ' Maren said my name once, quietly, the way you say a name to '
        'someone who is walking toward a drop.',
    'vess': ' "He is not offering you a crown," Vess said. "He is offering '
        'the tear a bearer. Ask him who taught him the words."',
    'malrik': ' Malrik looked at the legate\'s purse, and at the legate, '
        'and at me, and said, "Whatever he is paying, it is not enough, and '
        'I say that as a professional."',
  },
  '3001_camp': {
    '*': ' The ones who had come this far with me set to work before I had '
        'found a word to say about it, and the camp was theirs as much as '
        'anyone\'s from that first fire.',
    'kelda': ' Kelda had a wall marked out before the kettle boiled, and '
        'two refugees carrying stone for it before she had finished '
        'explaining why.',
  },
  '4999_camp': {
    '*': ' The ones who had walked back from the Spire with me went '
        'straight to the fires, and the camp made room for them the way '
        'it makes room for anyone who comes home.',
    'maren': ' Maren went from fire to fire with her hands and her '
        'censer, and by nightfall people had started calling the camp a '
        'parish, which she did not correct.',
    'grosh': ' Grosh lifted things. Large things. He appeared to consider '
        'it payment enough that nobody asked him to do anything else.',
  },
  '6002_camp': {
    '*': ' Whoever had come back to the cove with me slept like the dead '
        'and ate like the living, and nobody mentioned the ledger until '
        'morning.',
  },
  '3005': {
    '*': ' The quarter was easier to walk with someone at my shoulder, if '
        'only because two sets of eyes see twice as many things worth '
        'avoiding.',
    'maren': ' Maren stopped at every shrine the ash had spared and at '
        'several it had not. I stopped asking her to hurry.',
    'liora': ' Liora read the chalk-marks on the walls before I had '
        'noticed there were any, and steered us, without comment, past two '
        'of them.',
    'grosh': ' Grosh walked the quarter like a man returning to a job he '
        'had left unfinished, and the ash did not argue with him.',
  },
  '3002': {
    '*': ' Two passages, and for once I was not the only one to weigh '
        'them. We chose together, which is not the same as choosing well, '
        'but is better company for the consequences.',
    'vess': ' Vess tilted her head at the left-hand passage the way one '
        'listens to a sound nobody else can hear. "That one is older," she '
        'said. "Older is not the same as safer."',
  },
  '4999': {
    '*': ' Whoever had come down into that cathedral at my back was still '
        'standing beside me when the dust settled, and I found — against '
        'every instinct three chapters like these should have taught me — '
        'that this mattered rather more than the victory itself.',
    'maren': ' Maren knelt by the High Warden when it was done and said '
        'something over him I did not hear and did not ask about. Whatever '
        'she had left of her vows, she spent it there.',
    'kelda': ' Kelda leaned on her shield and looked at the fallen Warden '
        'with something close to respect. "He held," she said. "Wrong '
        'thing, but he held."',
  },
  '5001': {
    '*': ' The whispers changed pitch when they saw I was not alone, and '
        'the survivors who had been about to say nothing said, instead, a '
        'little more.',
    'tobin': ' Brother Tobin heard the name before I did and set his jaw. '
        '"I sang for them," he said. "Once. Whatever they say about the '
        'Court, believe it."',
  },
  '5010': {
    '*': ' The refugees in the cloister looked past me to whoever stood '
        'behind, and decided, on the strength of that, that we were '
        'worth talking to.',
    'maren': ' Maren was among the sick before I had finished looking '
        'for a dry place to stand, and the candles seemed steadier for '
        'it.',
    'tobin': ' Tobin knew the cloister\'s hymns and did not sing them, '
        'which the people here seemed to understand as the greater '
        'courtesy.',
    'malrik': ' Malrik priced the reliquaries with his eyes and kept his '
        'hands in plain sight, which for him was practically piety.',
  },
  '6001': {
    '*': ' Daylight found more than one of us blinking at it, and the '
        'ledger felt lighter for being read in company.',
    'liora': ' Liora put her back to the doorway without being asked and '
        'watched the street while I read, which is the kindest thing '
        'anyone has done for a book in my presence.',
  },
  '6004': {
    '*': " I was, at least, not the only one who heard it. Whoever had "
        "followed me this far into the dark heard it too, and a certainty "
        "like that, it turned out, weighed rather less when it wasn't mine "
        "alone to carry.",
    'vess': ' Vess heard it too, and for the first time since I had known '
        'her she looked afraid — not of the Void, I think, but of how much '
        'of it she recognised.',
  },
  '6010': {
    '*': ' The quarter\'s last few people looked at the company I kept '
        'and decided I might be worth selling to after all.',
    'malrik': ' Malrik knew the Reliquary Quarter the way a fox knows a '
        'henhouse, and nodded to three stallholders who very carefully '
        'did not nod back.',
    'tobin': ' Tobin walked the frost with his hammer at his belt and his '
        'eyes on the chapel roofs, and the penitents made room for him '
        'without knowing why.',
  },
  '7001': {
    '*': ' The Eel had carried more than me to the Hollow Shore. I was '
        'glad of it in a way I did not, then, have words for.',
    'kelda': ' Kelda was already checking the Eel\'s hull when I came to, '
        'because a wall is a wall whether it floats or not.',
    'grosh': ' Grosh stood at the water\'s edge and looked at the tear the '
        'way he looked at everything he intended to break.',
    'sable': ' Sable sat on the Eel\'s rail sharpening a knife she did not '
        'need sharpened. "Last one," she said. "Make it worth the trip."',
  },
  '7002': {
    '*': ' Nobody spoke much while we readied the Eel. There was nothing '
        'to say that the tear across the water was not already saying.',
    'maren': ' Maren blessed the ballista, the hull, the crew and, when '
        'she thought I was not looking, me.',
    'liora': ' Liora strung her bow and counted her arrows twice, and '
        'then a third time, and did not pretend it was for any reason but '
        'nerves.',
    'vess': ' Vess stood at the bow with her face to the tear and said, '
        'quietly, that it knew her name too, and that she meant to make it '
        'regret learning it.',
  },
  '7002_crew': {
    '*': ' They stood in a loose half-ring on the sand and let me finish, '
        'which was its own kind of answer.',
    'kelda': ' Kelda said nothing until I had done, and then: "You talk too '
        'much before a fight. Always have." She was smiling. I had not seen '
        'that before.',
    'sable': ' "Speech over?" Sable asked. "Good. I was going to cry, and it '
        'ruins my aim."',
    'maren': ' Maren took my hand when I had finished and did not let go '
        'of it for some time, and did not say anything at all, which from '
        'her was a benediction.',
    'vess': ' Vess waited until the others had turned away. "It knows my '
        'name too," she said. "Out there. If it says it, do not listen to '
        'what I do next."',
    'grosh': ' Grosh grunted, which I had learned to read, and put a hand '
        'on my shoulder that nearly put me in the sand.',
    'tobin': ' Tobin hummed two bars of something under his breath and '
        'stopped, and the sand was quieter for the stopping.',
    'liora': ' Liora looked at the tear rather than at me while I spoke, '
        'counting something, and when I finished she said: "Nine arrows. '
        'Then I climb something."',
    'malrik': ' "Very moving," Malrik said. "I get first pick of the '
        'throne room." I told him he could have the throne. He said he '
        'would think about it.',
  },
  '7003': {
    '*': ' We stood in the wreck of the throne room together, and I '
        'counted us, and the number was the one I had sailed in with.',
    'tobin': ' Tobin was the first to speak, and what he said was a '
        'hymn, and for once nobody minded.',
    'malrik': ' Malrik was already looking at the crown. "Somebody\'s '
        'going to," he said, when I looked at him. "Might as well be '
        'someone who\'ll talk to me after."',
  },
  '7004': {
    '*': ' The question was mine to answer, but I found I wanted to '
        'know what the ones who had sailed with me would think of the '
        'answer, which is not something I would have said a year ago.',
  },
};

const Map<String, Map<String, String>> _acksFr = {
  '891': {
    '*': " Quelqu'un tint mon allure jusqu'à l'eau, ce que je n'avais pas "
        "demandé et qui, au bout du compte, ne me déplut pas.",
    'vess': " Vess courait à mes côtés sans paraître se presser, comme si "
        "les quais étaient un endroit où elle était déjà allée et où elle "
        "comptait simplement arriver de nouveau.",
  },
  '2001': {
    '*': " Je n'étais pas, pour une fois, seul à regarder brûler le rivage "
        "depuis le bastingage, et la compagnie rendait le feu plus petit.",
    'vess': " Vess regardait le feu avec l'attention plate de qui le compare "
        "à un autre. « Il s'éteint, dit-elle. À la longue. Tout ce que j'ai "
        "vu brûler s'est éteint. »",
  },
  '2015': {
    '*': " Qui marchait avec moi gardait une main près d'une arme et un œil "
        "sur la foule, et la foule, raisonnablement, nous faisait de la place.",
    'kelda': " Kelda arpentait le quai comme elle avait tenu la porte, comme "
        "un mur qu'on lui aurait demandé de garder, et les marchands se "
        "redressaient sur son passage.",
    'sable': " Sable avait déjà estimé chaque étal que nous passions et, je "
        "le soupçonnais, allégé au moins l'un d'eux. « Je regarde », dit-elle "
        "quand je la fixai.",
    'liora': " Liora comptait les toits en chemin, en nomma deux qu'elle "
        "aurait choisis, et un qu'elle aurait évité.",
  },
  '2900': {
    '*': " Qui était descendu aux mouillages avec moi regardait l'Eel comme "
        "je le regardais, et ne disait pas ce que nous pensions tous deux, à "
        "savoir que c'était beaucoup de bateau à confier à beaucoup de mer.",
    'kelda': " « Il flotte, dit Kelda en frappant la coque du pied. Presque. "
        "Je flotte moins bien. » C'était ce qui ressemblait le plus à une "
        "plaisanterie de sa part, et elle en pensait chaque mot.",
    'sable': " Sable était déjà montée à bord sans qu'on le lui demande, et "
        "redescendit la passerelle avec la liste de tout ce qui manquait à "
        "l'Eel et une liste plus courte des endroits où le voler.",
    'liora': " Liora regarda la voile, et la déchirure dedans, ne dit rien, "
        "et se mit à lover du cordage comme si le lovage était une dispute "
        "qu'elle comptait gagner.",
    'vess': " Vess posa la paume à plat sur la coque sous la ligne de "
        "flottaison, là où la pique était passée, et l'y laissa, et quand "
        "elle la retira le bois était sec. « Pas pour longtemps, dit-elle. "
        "Mais assez pour aller jusqu'à la poix. »",
  },
  '2900_boat_fixed': {
    '*': " L'équipage se tenait le long du bastingage et regardait le quai "
        "sans me regarder, ce qui était sa façon de laisser la décision là "
        "où elle devait être.",
    'kelda': " Kelda compta le quai comme elle comptait un mur : les têtes, "
        "puis les mains, puis ceux qui savaient tenir un cordage. « Vingt, "
        "dit-elle. Vingt-cinq s'ils ne bougent pas. Ils bougeront. »",
    'sable': " « Les vivres par-dessus bord, dit Sable avant que j'aie rien "
        "demandé à personne, ou les gens restent. J'ai fait le compte. Il ne "
        "m'a pas plu non plus. »",
    'liora': " Liora était montée au mât et regardait par-delà le quai vers "
        "l'Étage Supérieur, où étaient les tambours, et comptait quelque "
        "chose dont je ne voulais pas connaître le total.",
    'vess': " Vess se tenait à la passerelle, capuche rabattue pour que le "
        "quai voie ce qu'elle était, et ceux qui reculèrent devant elle "
        "étaient, me dit-elle plus tard, ceux qu'elle aurait laissés.",
  },
  '2999': {
    '*': " L'équipage me regardait à travers le pont incliné comme un "
        "équipage regarde celui qui doit le dire, et je compris que ce que je "
        "dirais ensuite serait répété, plus tard, dans un endroit sec, par "
        "qui resterait pour le répéter.",
    'kelda': " Kelda était déjà à la barre, les deux bras autour, et cria "
        "par-dessus la mer que quoi que je décide, je devais le décider avant "
        "la prochaine vague, parce que la prochaine vague n'attendrait pas "
        "une discussion.",
    'sable': " Sable tranchait les saisines sans attendre l'ordre, ce qu'elle "
        "décrirait plus tard comme l'avoir anticipé.",
    'liora': " Liora avait un bras dans les haubans et l'autre autour d'un "
        "enfant du quai, et n'allait, quoi que je décide, lâcher ni l'un ni "
        "l'autre.",
    'vess': " Le fil en Vess était devenu blanc dans la lumière de la "
        "tempête, et elle parlait à la mer, tout bas, dans une langue que "
        "celle-ci semblait écouter.",
  },
  '4999_standard': {
    '*': " Ceux qui étaient entrés dans le sanctuaire avec moi reculèrent "
        "devant le Gardien et le gris perçant sous son blanc, et me "
        "laissèrent la place, et le silence, dont l'heure suivante avait "
        "besoin.",
    'kelda': " « Il a tenu la mauvaise chose, dit Kelda en le regardant, mais "
        "il l'a tenue. Ne le fais pas attendre pour le principe. »",
    'maren': " Maren s'agenouilla à sa tête, là où il pouvait la voir, et lui "
        "dit ce qu'une clerc dit à un mourant, et ne me dit pas quoi faire, "
        "ce qui de sa part était une miséricorde à laquelle je ne "
        "m'attendais pas.",
    'grosh': " Grosh tourna le dos au Gardien et surveilla la porte du "
        "sanctuaire. « La cathédrale brûle, dit-il. Quoi que tu fasses, "
        "fais-le avant le toit. »",
    'vess': " Vess ne pouvait détacher les yeux du gris dans l'étendard. "
        "« C'est la même étoffe, dit-elle. Elle sait ce que tu vas faire. "
        "Elle attend de voir comment. »",
  },
  '5004_altar': {
    '*': " Personne de ceux qui étaient descendus avec moi ne dit rien à "
        "l'autel. Il n'y avait rien à dire que les douze dormeurs dans le "
        "gris ne disent déjà.",
    'maren': " Maren alla de dormeur en dormeur, la main sur chaque front, "
        "et quand elle eut touché le dernier elle me regarda et secoua la "
        "tête, très légèrement, à une question que je n'avais pas posée à "
        "voix haute.",
    'tobin': " Tobin entama l'hymne des mourants et s'arrêta après deux "
        "mesures. « Ils ne le sont pas, dit-il. Pas encore. C'est tout le "
        "problème, n'est-ce pas. »",
    'sable': " « Vite, dit Sable, quelle que soit la façon. Vite est la "
        "seule bonté qui reste dans cette pièce. » Elle ne regardait pas les "
        "dormeurs en le disant.",
    'liora': " Liora avait à demi bandé son arc sur les dormeurs avant de "
        "comprendre ce qu'ils étaient, et l'abaissa lentement, et ne le "
        "releva plus.",
  },
  '6010_thread': {
    '*': " La chapelle était trop petite pour la compagnie que je gardais, "
        "et ils attendirent à la porte, et chacun d'eux trouva autre chose "
        "à regarder.",
    'malrik': " Malrik estima le reliquaire depuis la porte par habitude, se "
        "reprit, et pour la première fois depuis que je le connaissais ne "
        "nomma pas le chiffre.",
    'maren': " Maren demanda à la gardienne des cartes le nom de sa sœur, et "
        "le lui redit, et ce fut la seule prière dite dans cette chapelle.",
    'tobin': " Tobin posa son marteau dehors avant d'entrer, ce que je "
        "compris comme ce qui ressemble le plus, chez un nain, à retirer ses "
        "bottes.",
    'vess': " Vess se tenait aussi loin du reliquaire que la chapelle le "
        "permettait. « Il me connaît, dit-elle. Le fil qu'il contient. Ne le "
        "laisse pas sortir près de moi. »",
  },
  '7002_price': {
    '*': " L'équipage entendit le prix avec moi, et je regardai chacun "
        "d'eux faire le compte, et j'en vis plus d'un arriver à la même "
        "réponse et s'avancer avant que j'aie pu parler.",
    'kelda': " Kelda s'avança avant que j'aie fini d'entendre le prix, le "
        "bouclier encore au bras. « Je passe en premier, dit-elle. Je passe "
        "toujours en premier. Ce n'est pas différent. »",
    'sable': " Sable s'avança avant que j'aie fini d'entendre le prix. "
        "« Il faut bien quelqu'un, dit-elle, et je suis la seule ici à avoir "
        "déjà cambriolé une porte. »",
    'maren': " Maren s'avança avant que j'aie fini d'entendre le prix, et ne "
        "discuta pas, et ne me laissa pas discuter non plus.",
    'liora': " Liora s'avança avant que j'aie fini d'entendre le prix, "
        "débanda son arc et me le tendit. « Neuf flèches, dit-elle. "
        "Sers-t'en. »",
    'vess': " Vess s'avança avant que j'aie fini d'entendre le prix. « Il "
        "connaît mon nom, dit-elle. Qu'il ait le reste. Il s'étouffera "
        "avec. »",
    'grosh': " Grosh s'avança avant que j'aie fini d'entendre le prix, et ne "
        "dit rien, parce qu'il n'en avait jamais eu besoin de sa vie.",
    'tobin': " Tobin s'avança avant que j'aie fini d'entendre le prix, en "
        "fredonnant, et ne cessa pas de fredonner, et les reflets sur le "
        "sable se tournèrent pour écouter.",
    'malrik': " Malrik s'avança avant que j'aie fini d'entendre le prix. "
        "« La priorité, dit-il. J'avais prévenu. » Il ne souriait pas. "
        "C'était la première fois.",
  },
  '7002_pact': {
    '*': " L'équipage s'était fait très silencieux derrière moi, et je "
        "n'avais pas besoin de me retourner pour savoir qui se tenait le "
        "plus près de la barque du légat, ni pourquoi.",
    'kelda': " Kelda s'était placée, sans un mot, entre moi et la barque du "
        "légat, le bouclier levé, et il n'était pas levé contre lui.",
    'maren': " Maren dit mon nom une fois, tout bas, comme on dit un nom à "
        "quelqu'un qui marche vers un précipice.",
    'vess': " « Il ne t'offre pas une couronne, dit Vess. Il offre un "
        "porteur à la déchirure. Demande-lui qui lui a appris les mots. »",
    'malrik': " Malrik regarda la bourse du légat, puis le légat, puis moi, "
        "et dit : « Quoi qu'il paie, ce n'est pas assez, et je dis cela en "
        "professionnel. »",
  },
  '3001_camp': {
    '*': " Ceux qui étaient venus jusque-là avec moi se mirent au travail "
        "avant que j'aie trouvé un mot à dire, et le camp fut autant le leur "
        "que celui de quiconque dès ce premier feu.",
    'kelda': " Kelda avait tracé un mur avant que la bouilloire ne chante, et "
        "deux réfugiés portaient déjà des pierres avant qu'elle ait fini "
        "d'expliquer pourquoi.",
  },
  '4999_camp': {
    '*': " Ceux qui étaient revenus de la Flèche avec moi allèrent droit aux "
        "feux, et le camp leur fit de la place comme il en fait à quiconque "
        "rentre chez soi.",
    'maren': " Maren allait de feu en feu avec ses mains et son encensoir, et "
        "à la nuit tombée les gens appelaient le camp une paroisse, ce "
        "qu'elle ne corrigea pas.",
    'grosh': " Grosh soulevait des choses. De grosses choses. Il semblait "
        "tenir pour paiement suffisant que personne ne lui demande autre chose.",
  },
  '6002_camp': {
    '*': " Ceux qui étaient revenus à la crique avec moi dormirent comme des "
        "morts et mangèrent comme des vivants, et personne ne parla du "
        "registre avant le matin.",
  },
  '3005': {
    '*': " Le quartier se traversait plus aisément avec quelqu'un à mon "
        "épaule, ne serait-ce que parce que deux paires d'yeux voient deux "
        "fois plus de choses à éviter.",
    'maren': " Maren s'arrêtait à chaque sanctuaire que la cendre avait "
        "épargné, et à plusieurs qu'elle n'avait pas épargnés. Je cessai de "
        "lui demander de se presser.",
    'liora': " Liora lut les marques de craie sur les murs avant que j'aie "
        "remarqué qu'il y en avait, et nous fit contourner, sans commentaire, "
        "deux d'entre elles.",
    'grosh': " Grosh traversait le quartier comme un homme revenant à un "
        "travail laissé inachevé, et la cendre ne discutait pas avec lui.",
  },
  '3002': {
    '*': " Deux passages, et pour une fois nous étions plusieurs à les "
        "soupeser. Nous avons choisi ensemble, ce qui n'est pas choisir "
        "bien, mais fait meilleure compagnie pour les conséquences.",
    'vess': " Vess pencha la tête vers le passage de gauche comme on écoute "
        "un son que personne d'autre n'entend. « Celui-là est plus vieux, "
        "dit-elle. Plus vieux n'est pas plus sûr. »",
  },
  '4999': {
    '*': " Quiconque était descendu dans cette cathédrale à mes côtés se "
        "tenait encore debout près de moi une fois la poussière retombée, et "
        "je découvris — contre tout instinct que trois chapitres pareils "
        "auraient dû m'enseigner — que cela comptait bien davantage que la "
        "victoire elle-même.",
    'maren': " Maren s'agenouilla près du Haut Gardien quand ce fut fini et "
        "dit sur lui quelque chose que je n'entendis pas et ne demandai pas. "
        "Ce qui lui restait de ses vœux, elle le dépensa là.",
    'kelda': " Kelda s'appuya sur son bouclier et regarda le Gardien tombé "
        "avec quelque chose proche du respect. « Il a tenu, dit-elle. Pour la "
        "mauvaise cause, mais il a tenu. »",
  },
  '5001': {
    '*': " Les murmures changèrent de ton quand ils virent que j'avais de "
        "la compagnie, et les survivants qui allaient se taire dirent, au lieu de "
        "cela, un peu plus.",
    'tobin': " Frère Tobin entendit le nom avant moi et serra la mâchoire. "
        "« J'ai chanté pour eux, dit-il. Une fois. Quoi qu'on dise de la Cour, "
        "croyez-le. »",
  },
  '5010': {
    '*': " Les réfugiés du cloître regardaient derrière moi qui s'y tenait, "
        "et décidèrent, sur cette foi, que nous valions qu'on nous parle.",
    'maren': " Maren était parmi les malades avant que j'aie fini de chercher "
        "un endroit sec où me tenir, et les chandelles en parurent plus "
        "stables.",
    'tobin':
        " Tobin connaissait les hymnes du cloître et ne les chanta pas, ce "
            "que les gens d'ici semblèrent prendre pour la plus grande des "
            "courtoisies.",
    'malrik': " Malrik estimait les reliquaires des yeux et gardait les mains "
        "bien en vue, ce qui chez lui tenait pratiquement de la piété.",
  },
  '6001': {
    '*': " Le jour trouva plus d'un d'entre nous à cligner des yeux, et le "
        "registre parut plus léger d'être lu en compagnie.",
    'liora': " Liora se posta dos à l'embrasure sans qu'on le lui demande et "
        "surveilla la rue pendant que je lisais, ce qui est la chose la plus "
        "aimable qu'on ait faite pour un livre en ma présence.",
  },
  '6004': {
    '*': " Du moins, je ne fus pas la seule personne à l'entendre. "
        "Quiconque était venu avec moi jusque dans cette obscurité "
        "l'entendit aussi, et une telle "
        "certitude, s'avéra-t-il, pesait nettement moins lorsqu'elle n'était "
        "pas mienne seule à porter.",
    'vess': " Vess l'entendit aussi, et pour la première fois depuis que je la "
        "connaissais elle parut effrayée — non du Néant, je crois, mais de "
        "tout ce qu'elle en reconnaissait.",
  },
  '6010': {
    '*': " Les derniers habitants du quartier regardèrent la compagnie que je "
        "gardais et décidèrent que je valais peut-être qu'on me vende quelque "
        "chose après tout.",
    'malrik': " Malrik connaissait le Quartier des Reliquaires comme un renard "
        "connaît un poulailler, et salua d'un signe trois marchands qui se "
        "gardèrent bien de le lui rendre.",
    'tobin': " Tobin marchait sur le givre, le marteau à la ceinture et les "
        "yeux sur les toits des chapelles, et les pénitents lui faisaient "
        "place sans savoir pourquoi.",
  },
  '7001': {
    '*': " L'Eel avait porté plus que moi jusqu'à la Rive Creuse. J'en fus "
        "heureux d'une façon pour laquelle je n'avais pas encore de mots.",
    'kelda': " Kelda inspectait déjà la coque de l'Eel quand je revins à moi, "
        "parce qu'un mur est un mur, qu'il flotte ou non.",
    'grosh':
        " Grosh se tenait au bord de l'eau et regardait la déchirure comme "
            "il regardait tout ce qu'il comptait briser.",
    'sable': " Sable, assise sur le bastingage, aiguisait un couteau qui n'en "
        "avait pas besoin. « Le dernier, dit-elle. Que ça vaille le voyage. »",
  },
  '7002': {
    '*': " Personne ne parla beaucoup pendant que nous préparions l'Eel. Il "
        "n'y avait rien à dire que la déchirure, de l'autre côté de l'eau, ne "
        "dise déjà.",
    'maren': " Maren bénit la baliste, la coque, l'équipage et, quand elle "
        "crut que je ne regardais pas, moi.",
    'liora': " Liora tendit son arc et compta ses flèches deux fois, puis une "
        "troisième, et ne fit pas semblant que ce fût pour autre chose que "
        "les nerfs.",
    'vess': " Vess se tenait à la proue, face à la déchirure, et dit, tout "
        "bas, qu'elle connaissait son nom à elle aussi, et qu'elle comptait "
        "lui faire regretter de l'avoir appris.",
  },
  '7002_crew': {
    '*': " Ils se tenaient en demi-cercle lâche sur le sable et me laissèrent "
        "finir, ce qui était une réponse en soi.",
    'kelda': " Kelda ne dit rien avant que j'aie terminé, puis : « Tu parles "
        "trop avant un combat. Depuis toujours. » Elle souriait. Je n'avais "
        "jamais vu cela.",
    'sable': " « Discours terminé ? demanda Sable. Tant mieux. J'allais "
        "pleurer, et ça me gâche la visée. »",
    'maren': " Maren me prit la main quand j'eus fini et ne la lâcha pas de "
        "longtemps, sans rien dire du tout, ce qui, venant d'elle, était une "
        "bénédiction.",
    'vess': " Vess attendit que les autres se soient détournés. « Il connaît "
        "mon nom aussi, dit-elle. Là-bas. S'il le prononce, n'écoute pas ce "
        "que je ferai ensuite. »",
    'grosh': " Grosh grogna, ce que j'avais appris à lire, et me posa sur "
        "l'épaule une main qui faillit m'envoyer dans le sable.",
    'tobin': " Tobin fredonna deux mesures de quelque chose et s'arrêta, et "
        "le sable fut plus silencieux de cet arrêt.",
    'liora': " Liora regardait la déchirure plutôt que moi pendant que je "
        "parlais, comptant quelque chose, et quand j'eus fini elle dit : "
        "« Neuf flèches. Ensuite je grimpe sur quelque chose. »",
    'malrik': " « Très émouvant, dit Malrik. J'ai la priorité sur la salle du "
        "trône. » Je lui dis qu'il pouvait garder le trône. Il dit qu'il y "
        "réfléchirait.",
  },
  '7003': {
    '*': " Nous nous tenions ensemble dans les ruines de la salle du trône, "
        "et je nous comptai, et le nombre était celui avec lequel j'avais "
        "embarqué.",
    'tobin': " Tobin fut le premier à parler, et ce qu'il dit était un hymne, "
        "et pour une fois personne ne s'en plaignit.",
    'malrik': " Malrik regardait déjà la couronne. « Quelqu'un va la "
        "prendre, dit-il quand je le regardai. Autant que ce soit quelqu'un "
        "qui me parlera encore après. »",
  },
  '7004': {
    '*': " La question m'appartenait, mais je découvris que je voulais "
        "savoir ce que ceux qui avaient navigué avec moi penseraient de la "
        "réponse, ce que je n'aurais pas dit un an plus tôt.",
  },
};

/// Node ids that carry a companion line -- exposed for tests.
Iterable<String> get acknowledgedNodeIds => _acksEn.keys;

/// The line for [nodeId] and the party's [activeAllyIds]: the first active
/// companion with their own authored line speaks, otherwise the default
/// for any company; nothing when the character walks alone.
String? allyAcknowledgmentFor(
  String nodeId, {
  required List<String> activeAllyIds,
  required bool french,
}) {
  if (activeAllyIds.isEmpty) return null;
  final table = (french ? _acksFr : _acksEn)[nodeId] ??
      (french ? _acksEn : _acksFr)[nodeId];
  if (table == null) return null;
  for (final id in activeAllyIds) {
    final line = table[id];
    if (line != null && line.isNotEmpty) return line;
  }
  return table['*'];
}

/// [description] with the companion line appended, if [nodeId] has one
/// and a companion is active; otherwise returns [description] unchanged.
String withAllyAcknowledgment(
  String nodeId,
  String description, {
  required List<String> activeAllyIds,
  required bool french,
}) {
  final addition = allyAcknowledgmentFor(nodeId,
      activeAllyIds: activeAllyIds, french: french);
  return addition == null ? description : '$description$addition';
}
