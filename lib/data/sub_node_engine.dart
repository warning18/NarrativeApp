import 'dart:math';

import '../combat/combat_engine.dart';
import '../combat/enemy_affix.dart';
import '../combat/loot_box.dart';
import '../models/story_node.dart';
import 'alignment_events.dart';
import 'encounter_text.dart';
import 'hunt_names.dart';
import 'map_themes.dart';

/// Generates short chains of procedural "excursion" nodes inserted between
/// the fixed main story beats — a shop visit, an enemy encounter, a quest
/// pickup, a small treasure find, a moment of rest, or a bit of ambient
/// flavor. If a quest pickup is rolled, the chain is lengthened to 4-7
/// nodes to represent that quest's own mini-arc; otherwise it's a short
/// 1-3 node detour. The wording of these excursions comes from [theme]
/// (see map_themes.dart) — the main story beats themselves never change,
/// only the flavor of what happens between them.
class SubNodeEngine {
  static int _counter = 0;

  /// Odds a story transition takes a detour ([maybeGenerate]'s default).
  static const double detourChance = 0.7;

  /// Returns null when no excursion is rolled this time.
  static List<StoryNode>? maybeGenerate({
    required Random random,
    required int chapter,
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
    required Map<String, dynamic> quests,
    required List<String> unlockedShopIds,
    required List<String> unlockedEnemyIds,
    required List<String> unlockedQuestIds,
    required List<String> completedQuestIds,
    MapTheme theme = defaultMapTheme,
    double triggerChance = detourChance,
    int partySize = 3,
    String alignmentLabel = 'Neutral',
  }) {
    if (random.nextDouble() > triggerChance) return null;

    final flavor = flavorFor(theme);

    final shopPool = filterShopPool(
      shops: shops,
      unlockedShopIds: unlockedShopIds,
      chapter: chapter,
    );
    final enemyPool = filterEnemyPool(
      enemies: enemies,
      unlockedEnemyIds: unlockedEnemyIds,
      chapter: chapter,
    );
    // A quest already completed shouldn't come back around in a later
    // excursion -- questIDToProgress (the main-path way into a quest) only
    // ever adds to activeQuestIds, never unlockedQuestIds, so that alone
    // isn't enough to keep a finished quest out of this pool.
    // And a quest written for one alignment (Tobin's vigil is for the
    // Good, Malrik's cut for the Evil -- the same gate their story
    // recruit nodes carry) is never offered to the other; without this
    // check the excursion path handed every character both companions.
    final questPool = filterQuestPool(
      quests: quests,
      chapter: chapter,
      unlockedQuestIds: unlockedQuestIds,
      completedQuestIds: completedQuestIds,
      alignmentLabel: alignmentLabel,
    );

    final includeQuest = questPool.isNotEmpty && random.nextDouble() < 0.35;
    final length = includeQuest ? 4 + random.nextInt(4) : 1 + random.nextInt(3);
    // A companion-recruit quest (rewardAllyId set) that's still eligible
    // this chapter is a second chance at a companion the player didn't
    // pick at their one-shot recruitment hub (e.g. node 2015's Kelda-vs-
    // Sable choice) -- worth surfacing over an ordinary side quest instead
    // of leaving it to compete equally in the full pool.
    final recruitQuestPool = questPool.where((id) {
      final rewardAllyId =
          (quests[id] as Map<String, dynamic>?)?['rewardAllyId']?.toString();
      return rewardAllyId != null && rewardAllyId.isNotEmpty;
    }).toList();
    final questSlotId = !includeQuest
        ? null
        : recruitQuestPool.isNotEmpty
            ? (recruitQuestPool..shuffle(random)).first
            : (questPool..shuffle(random)).first;

    final chain = [
      for (var i = 0; i < length; i++)
        buildNode(
          random: random,
          flavor: flavor,
          shopPool: shopPool,
          enemyPool: enemyPool,
          packPool: filterPackPool(enemies: enemies, enemyPool: enemyPool),
          maxPackSize: maxPackSizeFor(chapter, partySize: partySize),
          questId: i == 0 ? questSlotId : null,
          enemies: enemies,
          shops: shops,
          quests: quests,
        ),
    ];
    return withHunts(chain, enemies: enemies, random: random, flavor: flavor);
  }

  /// Scene moods (StoryNode.mood, the story file's context_taxonomy) of a
  /// scene in the middle of something: a raid, a chase, a stand-off, a
  /// town on fire.
  static const Set<String> tenseMoods = {
    'action',
    'tense',
    'suspense',
    'desperate',
  };

  /// Whether the story may take a detour between a scene of [fromMood] and
  /// one of [toMood]. Not when both are [tenseMoods]: that transition is
  /// one crisis running on ("Run for the docks", "Climb out before the
  /// roof comes down"), and nobody stops at a stall or picks a fight with
  /// a rat halfway through it. A crisis that starts or ends at the
  /// transition still leaves a road between the two scenes. What the road
  /// held is not lost, only put off: a detour rolled mid-crisis is owed
  /// and taken at the next transition at rest (see
  /// StoryPlayNotifier.oweDetour).
  static bool detourAllowedBetween(String? fromMood, String? toMood) =>
      !(tenseMoods.contains(fromMood) && tenseMoods.contains(toMood));

  /// Odds a pack fight in a chain is followed by a hunt: a trail node, then
  /// the pack's named survivor -- a tougher specimen with two affixes and a
  /// guaranteed Gold chest (see [buildHuntNodes]).
  static const double huntChance = 0.35;

  /// [chain] with a hunt spliced in after its first pack fight, when one
  /// rolls. A chain with no pack fight is returned as-is.
  static List<StoryNode> withHunts(
    List<StoryNode> chain, {
    required Map<String, dynamic> enemies,
    required Random random,
    required ExcursionFlavor flavor,
    double chance = huntChance,
  }) {
    for (var i = 0; i < chain.length; i++) {
      final choice = chain[i].choices.isEmpty ? null : chain[i].choices.first;
      final ids = choice?.allTriggerEnemyIds ?? const [];
      if (ids.length < 2) continue;
      if (random.nextDouble() >= chance) return chain;
      final quarryId = ids[random.nextInt(ids.length)];
      final hunt = buildHuntNodes(
        quarryId: quarryId,
        quarryBaseName:
            (enemies[quarryId] as Map<String, dynamic>?)?['enemyName']
                    ?.toString() ??
                quarryId,
        random: random,
      );
      return [...chain.take(i + 1), ...hunt, ...chain.skip(i + 1)];
    }
    return chain;
  }

  static const List<String> _trailEn = [
    'One of them got away. The blood trail is fresh, and it leads somewhere '
        'that was clearly a lair long before tonight.',
    'Tracks in the dust, dragging on one side -- the one that ran is hurt, '
        'and hurt things go home.',
    'A dropped scrap of cloth, then another. Whoever fled this fight was '
        'not being careful, and was not alone where it was going.',
    'A scream, cut short, from the direction the survivor fled. Whatever it ran home to has not been kind about the delay.',
    'The one that ran left a boot in the mud, and the mud beyond it has been crossed by something heavier, going the same way.',
    'Torn cloth on a nail, then a smear on a doorframe, then a door left open on a dark that breathes.',
    'The trail is not hidden. It was never meant to be. Something at the end of it wants company.',
    'A dropped weapon, then a dropped pack, then nothing dropped at all: the runner has stopped being careless and started being afraid.',
  ];
  static const List<String> _trailFr = [
    "L'un d'eux s'est échappé. La traînée de sang est fraîche, et elle mène "
        'quelque part qui était manifestement un repaire bien avant ce soir.',
    "Des traces dans la poussière, traînantes d'un côté : celui qui a fui "
        'est blessé, et les bêtes blessées rentrent chez elles.',
    "Un lambeau d'étoffe tombé, puis un autre. Celui qui a fui ce combat "
        "ne prenait aucune précaution, et n'était pas seul là où il allait.",
    "Un cri, coupé net, du côté où le survivant a fui. Ce qu'il est allé retrouver n'a pas été tendre pour le retard.",
    'Celui qui a fui a laissé une botte dans la boue, et la boue au-delà a été traversée par quelque chose de plus lourd, dans la même direction.',
    'Une étoffe déchirée sur un clou, puis une traînée sur un chambranle, puis une porte laissée ouverte sur une obscurité qui respire.',
    "La piste n'est pas cachée. Elle n'a jamais été censée l'être. Quelque chose au bout veut de la compagnie.",
    "Une arme abandonnée, puis un sac abandonné, puis plus rien d'abandonné : le fuyard a cessé d'être négligent et commencé à avoir peur.",
  ];
  static const List<String> _quarryEn = [
    'It is waiting at the end of the trail, bigger than the ones you killed '
        'and far angrier, and it has clearly been the reason the others '
        'were bold.',
    'The lair is a hollow of stolen things and old bones, and the thing '
        'that owns it rises to meet you with no intention of running.',
    'It has been eating what the others brought back for a long time, and it has grown into the space they left it, and it does not look up when you enter because it has never once had to.',
    "The lair's floor is a ring of picked bones, and at the center of the ring the thing that picked them uncoils, unhurried, to see who has walked in on its own feet.",
    'It wears what the pack stole, all of it, in layers, and turns to show you the one piece it is proudest of, which is a face.',
    'The runner is here, dead, at its feet. It has been waiting for whoever would follow, and it has been waiting for a while, and it is not patient.',
    'It is old, and scarred in the shape of every hunter who came before you, and it stands the way a wall stands: as if the question of moving had been settled long ago.',
    'The others were its children, or its tools, or its food; it does not seem to have troubled to decide. It has decided about you.',
  ];
  static const List<String> _quarryFr = [
    "Il attend au bout de la piste, plus gros que ceux que vous avez tués "
        'et bien plus furieux, et il est clairement la raison pour laquelle '
        'les autres étaient si hardis.',
    "Le repaire est un creux de choses volées et de vieux os, et la chose "
        "qui le possède se dresse pour vous affronter, sans la moindre "
        'intention de fuir.',
    "Il mange depuis longtemps ce que les autres rapportaient, il a grandi dans l'espace qu'ils lui ont laissé, et il ne lève pas la tête quand vous entrez parce qu'il n'en a jamais eu besoin.",
    "Le sol du repaire est un cercle d'os rongés, et au centre du cercle la chose qui les a rongés se déroule, sans hâte, pour voir qui est entré sur ses propres pieds.",
    'Il porte ce que la meute a volé, tout, en couches, et se tourne pour vous montrer la pièce dont il est le plus fier, qui est un visage.',
    "Le fuyard est là, mort, à ses pieds. Il attendait qui suivrait, il attend depuis un moment, et il n'est pas patient.",
    'Il est vieux, et marqué de la forme de chaque chasseur venu avant vous, et il se tient comme se tient un mur : comme si la question de bouger avait été réglée depuis longtemps.',
    "Les autres étaient ses enfants, ou ses outils, ou sa nourriture ; il ne semble pas s'être donné la peine de trancher. Pour vous, il a tranché.",
  ];

  /// The hunt pools' sizes, for the parity test.
  static ({int trail, int trailFr, int quarry, int quarryFr})
      get huntPoolSizes => (
            trail: _trailEn.length,
            trailFr: _trailFr.length,
            quarry: _quarryEn.length,
            quarryFr: _quarryFr.length,
          );

  /// The two hunt nodes: the trail, then the quarry's fight. [quarryId]
  /// is a member of the pack just beaten; its one-off name, two affixes
  /// and Gold-floor chest ride on the fight choice (see
  /// [StoryChoice.huntName]).
  static List<StoryNode> buildHuntNodes({
    required String quarryId,
    required String quarryBaseName,
    required Random random,
  }) {
    _counter++;
    final trailId = 'gen_$_counter';
    _counter++;
    final quarryNodeId = 'gen_$_counter';
    final name = huntNameFor(quarryId, random);
    final affixes = rollNamedVariantAffixes(random);
    final trailIdx = random.nextInt(_trailEn.length);
    final quarryIdx = random.nextInt(_quarryEn.length);
    return [
      StoryNode(
        id: trailId,
        description: _trailEn[trailIdx],
        descriptionFr: _trailFr[trailIdx],
        choices: const [
          StoryChoice(
            text: 'Follow the trail',
            textFr: 'Suivre la piste',
            nextId: '',
          ),
        ],
      ),
      StoryNode(
        id: quarryNodeId,
        description: '${_quarryEn[quarryIdx]} ($name, $quarryBaseName)',
        descriptionFr: '${_quarryFr[quarryIdx]} ($name, $quarryBaseName)',
        choices: [
          StoryChoice(
            text: 'Hunt it down',
            textFr: 'Le traquer',
            nextId: '',
            triggerEnemyId: quarryId,
            huntName: name,
            huntAffixes: [for (final a in affixes) a.name],
            chestFloor: chestTierAssetName(ChestTier.gold),
          ),
        ],
      ),
    ];
  }

  /// The largest pack a random encounter may draw at [chapter] for a party
  /// of [partySize] (the player plus active allies): a pair through
  /// chapter 2 (a level-1 party against three of anything is a coin flip at
  /// best), three from chapter 3 on -- but never more enemies than the
  /// party has dice. A pack's threat is its action economy, and three
  /// enemies against a solo character is unwinnable on that alone, whatever
  /// their stats (a level-5 solo mage went 0 for 25 against one).
  static int maxPackSizeFor(int chapter, {int partySize = 3}) =>
      min(chapter <= 2 ? 2 : 3, max(2, partySize));

  /// The subset of [enemyPool] a pack may be drawn from: enemies flagged
  /// `packEligible` in enemies.json (the trash tier), never a
  /// [soloOnlyEnemyIds] boss/unique, and never an unflagged heavy -- a
  /// 200-hp / 24-damage chapter-2 heavy is a tuned solo fight, and two or
  /// three of them at once out-stat every boss in the game.
  static List<String> filterPackPool({
    required Map<String, dynamic> enemies,
    required List<String> enemyPool,
  }) {
    return enemyPool
        .where((id) =>
            isRandomDrawEnemy(id) &&
            ((enemies[id] as Map<String, dynamic>?)?['packEligible'] as bool? ??
                false))
        .toList();
  }

  /// The quests an excursion may offer this chapter: this chapter's, not
  /// yet unlocked or completed, and not written for another alignment.
  /// A quest's `requiredAlignment` of 'Good' or 'Evil' must match the
  /// character's [alignmentLabel] (PlayerSession.alignmentLabel); 'Neutral'
  /// or unset means anyone may take it.
  static List<String> filterQuestPool({
    required Map<String, dynamic> quests,
    required int chapter,
    required List<String> unlockedQuestIds,
    required List<String> completedQuestIds,
    String alignmentLabel = 'Neutral',
  }) {
    return quests.entries
        .where((e) {
          final q = e.value as Map<String, dynamic>;
          final questChapter = (q['chapter'] as num?)?.toInt() ?? 1;
          return questChapter == chapter &&
              !unlockedQuestIds.contains(e.key) &&
              !completedQuestIds.contains(e.key) &&
              questMeetsAlignment(q, alignmentLabel);
        })
        .map((e) => e.key)
        .toList();
  }

  /// Whether a quest's `requiredAlignment` admits [alignmentLabel].
  static bool questMeetsAlignment(
      Map<String, dynamic> quest, String alignmentLabel) {
    final required = quest['requiredAlignment']?.toString() ?? '';
    if (required.isEmpty || required == 'Neutral') return true;
    return required == alignmentLabel;
  }

  /// Shops a detour or an expedition may lead to at [chapter]: not yet
  /// found, open by this chapter (shops.json `minChapter`) and not one of
  /// the camp houses' own shops (`detourEligible` false), which the camp
  /// opens when the house is built. Unfiltered, a chapter-1 detour could
  /// open the Hammersmith and its tier-6 gear.
  static List<String> filterShopPool({
    required Map<String, dynamic> shops,
    required List<String> unlockedShopIds,
    required int chapter,
  }) {
    return [
      for (final entry in shops.entries)
        if (!unlockedShopIds.contains(entry.key) &&
            ((entry.value as Map<String, dynamic>)['detourEligible'] as bool? ??
                true) &&
            (((entry.value as Map<String, dynamic>)['minChapter'] as num?)
                        ?.toInt() ??
                    1) <=
                chapter)
          entry.key,
    ];
  }

  /// Enemies eligible to appear in a randomly-drawn encounter at [chapter]
  /// -- shared by excursions ([maybeGenerate]) and expeditions
  /// (ExpeditionScreen) so both draw from the same chapter-appropriate
  /// pool. Unfiltered, this could roll a late-game enemy (e.g. a
  /// 230hp/27dmg chapter-5 monster) into a chapter-1 excursion or a
  /// chapter-2 expedition -- an unwinnable fight for a low-level character
  /// with no way to decline it and no way to progress past it. minChapter
  /// (see enemies.json) caps the pool to enemies the main story has
  /// already introduced by [chapter].
  static List<String> filterEnemyPool({
    required Map<String, dynamic> enemies,
    required List<String> unlockedEnemyIds,
    required int chapter,
  }) {
    return enemies.entries
        .where((e) => !unlockedEnemyIds.contains(e.key))
        // An alignment hunter only ever arrives through
        // alignment_events.dart, never as an ordinary random draw.
        .where((e) => !isHunterEnemy(e.value as Map<String, dynamic>?))
        // A story boss or a zone's own boss (soloOnlyEnemyIds) is met where
        // the story or the zone puts it, never as a random draw -- the Void
        // Sovereign does not wander into an expedition's third event.
        // A story-only enemy (storyOnlyEnemyIds) likewise, and each zone's
        // own boss (zoneBossEnemyIds), met at the end of its expedition.
        .where((e) => isRandomDrawEnemy(e.key))
        .where((e) {
          final minChapter =
              ((e.value as Map<String, dynamic>)['minChapter'] as num?)
                      ?.toInt() ??
                  1;
          return minChapter <= chapter;
        })
        .map((e) => e.key)
        .toList();
  }

  /// Builds a single typed flavor-pool node (shop/enemy/treasure/rest/quest,
  /// or a plain generic beat if none of those roll) — the same weighted
  /// draw [maybeGenerate] chains together for excursions, exposed on its
  /// own so other callers (e.g. the expedition system) can draw one event
  /// at a time from the same themed pools instead of a whole chain.
  /// [packPool] is the subset of [enemyPool] a 2-[maxPackSize] pack may be
  /// drawn from (see [filterPackPool]); left null, every non-solo-only id
  /// in [enemyPool] is eligible.
  static StoryNode buildNode({
    required Random random,
    required ExcursionFlavor flavor,
    required List<String> shopPool,
    required List<String> enemyPool,
    List<String>? packPool,
    int maxPackSize = 3,
    String? questId,
    Map<String, dynamic> enemies = const {},
    Map<String, dynamic> shops = const {},
    Map<String, dynamic> quests = const {},
  }) {
    _counter++;
    final id = 'gen_$_counter';

    if (questId != null) {
      final idx = random.nextInt(flavor.quest.length);
      final quest = quests[questId] as Map<String, dynamic>?;
      final questName = quest?['questName']?.toString() ?? '';
      final objective = _firstObjective(quest);
      return StoryNode(
        id: id,
        description: flavor.quest[idx],
        descriptionFr: flavor.questFr[idx],
        contextNote: objective == null ? null : 'The job: $objective',
        contextNoteFr: objective == null ? null : 'Le travail : $objective',
        choices: [
          StoryChoice(
            text:
                questName.isEmpty ? 'Take the job' : 'Take the job: $questName',
            textFr: questName.isEmpty
                ? 'Accepter le travail'
                : 'Accepter le travail : $questName',
            nextId: id,
            unlockQuestId: questId,
          ),
        ],
      );
    }

    final roll = random.nextDouble();
    if (shopPool.isNotEmpty && roll < 0.25) {
      final shopId = shopPool[random.nextInt(shopPool.length)];
      final idx = random.nextInt(flavor.shop.length);
      final shopName =
          (shops[shopId] as Map<String, dynamic>?)?['shopName']?.toString() ??
              '';
      return StoryNode(
        id: id,
        description: flavor.shop[idx],
        descriptionFr: flavor.shopFr[idx],
        choices: [
          StoryChoice(
            text: shopName.isEmpty ? 'Take a look' : 'Take a look: $shopName',
            textFr:
                shopName.isEmpty ? 'Jeter un œil' : 'Jeter un œil : $shopName',
            nextId: id,
            unlockShopId: shopId,
          ),
        ],
      );
    }
    if (enemyPool.isNotEmpty && roll < 0.5) {
      final idx = random.nextInt(flavor.enemy.length);
      // A pack fight never draws a solo-only enemy (the tuned bosses and
      // uniques -- see soloOnlyEnemyIds) -- those stay solo encounters
      // exclusively, drawn only through the plain single-enemy path below.
      final packEligible =
          packPool ?? enemyPool.where(isRandomDrawEnemy).toList();
      if (packEligible.isNotEmpty && random.nextDouble() < 0.3) {
        final size = 2 + random.nextInt(max(1, maxPackSize - 1));
        final ids = [
          for (var i = 0; i < size; i++)
            packEligible[random.nextInt(packEligible.length)],
        ];
        return _fightNode(id, ids, idx, flavor, enemies, pack: true);
      }
      final enemyId = enemyPool[random.nextInt(enemyPool.length)];
      return _fightNode(id, [enemyId], idx, flavor, enemies, pack: false);
    }
    if (roll < 0.65) {
      final goldFound = 5 + random.nextInt(16);
      final idx = random.nextInt(flavor.treasure.length);
      return StoryNode(
        id: id,
        description: flavor.treasure[idx],
        descriptionFr: flavor.treasureFr[idx],
        choices: [
          StoryChoice(
            text: 'Take it ($goldFound gold)',
            textFr: 'Le prendre ($goldFound or)',
            nextId: id,
            goldMod: goldFound,
          ),
        ],
      );
    }
    if (roll < 0.8) {
      final idx = random.nextInt(flavor.rest.length);
      return StoryNode(
        id: id,
        description: flavor.rest[idx],
        descriptionFr: flavor.restFr[idx],
        choices: const [
          StoryChoice(
              text: 'Rest a while',
              textFr: 'Se reposer un moment',
              nextId: '',
              healAmount: 20),
        ],
      );
    }
    final idx = random.nextInt(flavor.generic.length);
    return StoryNode(
      id: id,
      description: flavor.generic[idx],
      descriptionFr: flavor.genericFr[idx],
      choices: const [
        StoryChoice(text: 'Move on', textFr: 'Continuer', nextId: ''),
      ],
    );
  }

  /// A random fight's node. The text is the drawn enemy's own encounter
  /// line (how it shows up and why it attacks; its pack line when it leads
  /// several), so a rat is never announced as "a figure with a blade";
  /// the theme's generic line is only the fallback for an enemy with no
  /// lines. The button names who is fought. [idx] is the theme line
  /// already drawn, reused to pick the enemy's line so the detour draws
  /// no extra randomness.
  static StoryNode _fightNode(
    String id,
    List<String> ids,
    int idx,
    ExcursionFlavor flavor,
    Map<String, dynamic> enemies, {
    required bool pack,
  }) {
    final line = encounterLineFor(ids: ids, enemies: enemies, index: idx);
    final label = enemies.isEmpty
        ? (en: 'Fight', fr: 'Combattre')
        : fightLabelFor(ids, enemies);
    return StoryNode(
      id: id,
      description: line?.en ?? flavor.enemy[idx],
      descriptionFr: line?.fr ?? flavor.enemyFr[idx],
      choices: [
        StoryChoice(
          text: label.en,
          textFr: label.fr,
          nextId: id,
          triggerEnemyId: pack ? null : ids.single,
          triggerEnemyIds: pack ? ids : const [],
        ),
      ],
    );
  }

  /// A quest's first objective, as written in quests.json, or null.
  static String? _firstObjective(Map<String, dynamic>? quest) {
    final objectives = quest?['objectives'];
    if (objectives is! List || objectives.isEmpty) return null;
    final first = objectives.first;
    if (first is! Map) return null;
    final text = first['description']?.toString() ?? '';
    return text.isEmpty ? null : text;
  }
}
