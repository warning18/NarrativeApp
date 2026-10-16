// The nemesis (v5.2 step 6, docs/proposals/territory-power-nemesis.md):
// a clan the character keeps turning against does not just fade.
//
// - Who: at most one, the strongest main clan (power [nemesisMinPower] or
//   more) the character stands Hostile or Hunted with. It rises at a
//   chapter's turn ([updateNemesis]) and stays until the standing climbs
//   back to Wary, so it does not flicker at the border.
// - What it does: it hunts the character, sworn or not, at the Hunted
//   odds (rival_hunters.dart: its hunters share the alignment hunters' cap
//   and cooldown, mercy and betrayal); at war it takes your patron's
//   places first (clan_power.dart); it offers nothing (Hostile already
//   does that).
// - The story's own (v1.409, the user's call: your family kept a piece
//   of the Shroud, and the Dominion wants it): every new game opens with the Dominion the nemesis
//   ([PoliticsState.storyStart], `nemesisReason` 'story'). It hunts at the
//   Hostile odds, not the Hunted (rival_hunters.dart), and its people do
//   not join fights against you (clan_power.dart's reinforcements). It
//   lets go at Friendly rather than Wary; a clan crossed harder takes its
//   place; turned Hostile, it becomes an earned nemesis like any other.
//   Two story flags side you with it for good ([dominionSidedFlags]).
// - Breaking it ([breakNemesis], its quest's end, PR 5): a tier of power
//   lost, the hunt ended, and no nemesis from it for
//   [nemesisBreakChapters] chapters.
//
// Pure rules; the session (a chapter reached) and the playthrough
// simulator play them.
import 'dart:math';

import '../combat/combat_engine.dart' show damageShareOf;
import '../combat/encounter.dart' show EncounterModifiers;
import '../l10n/app_locale.dart';
import '../models/story_node.dart';
import 'clan_crisis.dart' show clanCrisisNodePrefix;
import 'clan_power.dart';
import 'factions.dart';

const int nemesisMinPower = risingPower;
const int nemesisBreakChapters = 2;

/// Whether [state]'s standing with [clanId] makes it a nemesis candidate:
/// Hostile or Hunted.
bool _turnedAgainst(PoliticsState state, String clanId, ClanData data) =>
    !state.tierOf(clanId, data).isAtLeast(StandingTier.resented);

/// The clan that would be the character's nemesis now, with no
/// hysteresis: the strongest main clan of power [nemesisMinPower] or more
/// stood Hostile or Hunted with, not fallen, not cooling down; '' for
/// none.
String nemesisCandidate(PoliticsState state, ClanData data,
    {int chapter = 0, Set<String> exclude = const {}}) {
  var best = '';
  var bestPower = -1;
  for (final id in data.factions.keys) {
    if (!isMainClan(id, data) || state.fallen.contains(id)) continue;
    if (exclude.contains(id)) continue;
    if ((state.nemesisCooldown[id] ?? 0) > chapter) continue;
    if (!_turnedAgainst(state, id, data)) continue;
    final power = powerOf(state, id, data);
    if (power < nemesisMinPower || power <= bestPower) continue;
    best = id;
    bestPower = power;
  }
  return best;
}

/// Whether the nemesis [clanId] lets go: the standing back at Wary or
/// better, or the clan fallen.
bool nemesisEnds(PoliticsState state, String clanId, ClanData data) =>
    state.fallen.contains(clanId) ||
    state.tierOf(clanId, data).isAtLeast(StandingTier.wary);

/// The story's flags that side the character with the Dominion for good
/// (Narrative, docs/proposals/dominion-nemesis.md): the legate's pact, and
/// Vane backed for the throne. With one, the Dominion is no nemesis.
const List<String> dominionSidedFlags = [
  'inquisition_pact',
  'throne_backed_vane'
];

/// The clans [flags] put out of the nemesis's reach ([dominionSidedFlags]).
Set<String> _sidedWith(Iterable<String> flags) =>
    flags.any(dominionSidedFlags.contains)
        ? const {storyNemesisClan}
        : const {};

/// [state] with its nemesis brought up to date at [chapter]: the one held
/// kept until it ends ([nemesisEnds]), then the [nemesisCandidate]; the
/// news says when one rises or lets go. [flags]: the story's, for
/// [dominionSidedFlags].
PoliticsState updateNemesis(
  PoliticsState state,
  ClanData data, {
  int chapter = 0,
  int day = 0,
  Iterable<String> flags = const [],
}) {
  final sided = _sidedWith(flags);
  // Of a fallen clan (clan_crisis.dart): its winner hunts you, whatever
  // its power.
  final forced = state.fallenWinner;
  if (forced.isNotEmpty) {
    return state.nemesis == forced
        ? state
        : _told(state.copyWith(nemesis: forced), 'nemesis:$forced',
            nemesisRiseNews(data.faction(forced)), chapter, day);
  }
  var next = state;
  final held = state.nemesis;
  if (state.isStoryNemesis) {
    final story = sided.contains(held)
        ? null
        : _storyNemesisTurn(state, data, chapter: chapter, day: day);
    if (story != null) return story;
    next = _told(next.copyWith(nemesis: ''), 'nemesis_end:$held',
        nemesisEndNews(data.faction(held)), chapter, day);
    final rising =
        nemesisCandidate(next, data, chapter: chapter, exclude: sided);
    if (rising.isEmpty || rising == held) return next;
    return _told(next.copyWith(nemesis: rising), 'nemesis:$rising',
        nemesisRiseNews(data.faction(rising)), chapter, day);
  }
  if (held.isNotEmpty) {
    if (!sided.contains(held) && !nemesisEnds(state, held, data)) return state;
    next = _told(next.copyWith(nemesis: ''), 'nemesis_end:$held',
        nemesisEndNews(data.faction(held)), chapter, day);
  }
  final rising = nemesisCandidate(next, data, chapter: chapter, exclude: sided);
  if (rising.isEmpty || rising == held) return next;
  return _told(next.copyWith(nemesis: rising), 'nemesis:$rising',
      nemesisRiseNews(data.faction(rising)), chapter, day);
}

/// Why the nemesis hunts the character, for its panel: the story's own
/// line (Narrative's) for [PoliticsState.isStoryNemesis]; null for an
/// earned nemesis (its standing says why) or none.
({String en, String fr})? nemesisReasonLine(PoliticsState state) =>
    state.isStoryNemesis
        ? (
            en: 'Your family kept a piece of the Shroud, and the Lantern '
                'wants it. The Dominion has hunted you since the night your '
                'house fell.',
            fr: 'Votre famille gardait un pan du Linceul, et la Lanterne le '
                'veut. Le Dominion vous traque depuis la nuit où votre '
                'maison s’est effondrée.',
          )
        : null;

/// The story's nemesis ([PoliticsState.isStoryNemesis]) at a chapter's
/// turn: null when it lets go (the character Friendly with it, or it
/// fallen); else [state] with it kept, made an earned one (the character
/// turned Hostile against it: from there the ordinary rules), or replaced
/// by a [nemesisCandidate] the character has crossed harder.
PoliticsState? _storyNemesisTurn(PoliticsState state, ClanData data,
    {required int chapter, required int day}) {
  final held = state.nemesis;
  if (state.fallen.contains(held) ||
      state.tierOf(held, data).isAtLeast(StandingTier.friendly)) {
    return null;
  }
  if (_turnedAgainst(state, held, data)) {
    return state.copyWith(nemesisReason: '');
  }
  final rival = nemesisCandidate(state, data, chapter: chapter);
  if (rival.isEmpty ||
      rival == held ||
      state.standingOf(rival, data) >= state.standingOf(held, data)) {
    return state;
  }
  return _told(state.copyWith(nemesis: rival), 'nemesis:$rival',
      nemesisRiseNews(data.faction(rival)), chapter, day);
}

/// [state] with the nemesis [clanId] broken (its quest won): a tier of
/// power lost, the hunt over, and none from it for [nemesisBreakChapters].
PoliticsState breakNemesis(
  PoliticsState state,
  String clanId,
  ClanData data, {
  int chapter = 0,
  int day = 0,
}) {
  final power = powerOf(state, clanId, data);
  var next = addPower(state, clanId, -min25(power), data).copyWith(
    nemesis: state.nemesis == clanId ? '' : state.nemesis,
    nemesisCooldown: {
      ...state.nemesisCooldown,
      clanId: chapter + nemesisBreakChapters,
    },
  );
  next = _told(next, 'nemesis_broken:$clanId',
      nemesisBrokenNews(data.faction(clanId)), chapter, day);
  return next;
}

/// A tier of [power]: 25, never more than there is.
int min25(int power) => power < risingPower ? power : risingPower;

PoliticsState _told(PoliticsState state, String id,
    ({String en, String fr}) text, int chapter, int day) {
  final news = [
    ...state.news,
    CoastNews(
      eventId: id,
      chapter: chapter,
      day: day,
      text: text.en,
      textFr: text.fr,
    ),
  ];
  return state.copyWith(
      news: news.length <= maxCoastNews
          ? news
          : news.sublist(news.length - maxCoastNews));
}

/// The news of [clan] making the character its nemesis.
({String en, String fr}) nemesisRiseNews(Faction? clan) => (
      en: '${clan?.nameFor(AppLanguage.en) ?? ''} have made you their '
          'nemesis. Their hunters are on your roads.',
      fr: 'Les gens ${clan?.nameOfFor(AppLanguage.fr) ?? ''} vous tiennent '
          'pour leur ennemi juré : leurs chasseurs sont sur vos routes.',
    );

/// The news of the nemesis [clan] letting go.
({String en, String fr}) nemesisEndNews(Faction? clan) => (
      en: '${clan?.nameFor(AppLanguage.en) ?? ''} no longer hunt you.',
      fr: 'Les gens ${clan?.nameOfFor(AppLanguage.fr) ?? ''} ne vous '
          'traquent plus.',
    );

/// The news of the nemesis [clan] broken, its champion beaten: the
/// clan's own line (Narrative's, factions.json `brokenNews`), else the
/// shared one.
({String en, String fr}) nemesisBrokenNews(Faction? clan) => (
      en: (clan?.brokenNews ?? '').isNotEmpty
          ? clan!.brokenNews
          : '${clan?.nameFor(AppLanguage.en) ?? ''} have lost their champion, '
              'and their hunt with it.',
      fr: (clan?.brokenNewsFr ?? '').isNotEmpty
          ? clan!.brokenNewsFr
          : 'Les gens ${clan?.nameOfFor(AppLanguage.fr) ?? ''} ont perdu '
              'leur champion, et leur traque avec lui.',
    );

// --- The nemesis quest and its champion (PR 5 and its follow-up) ----------
//
// When a clan makes the character its nemesis, its quest opens
// ([nemesisQuestIdOf], quests.json), in Narrative's beats
// (docs/proposals/nemesis-quests.md): the word (the quest's offer), the
// trail (a road at rest sets [trailFlagOf]), the way in and the champion
// (a later road: three choices, Force, Guile or Mercy, each setting its
// flag ([wayFlagOf]) and fighting the champion with its edge:
// encounter.dart's `nemesis_<way>` road events), and the break (the
// quest's turn-in: its politics' `breakNemesis`, the clan's own news).
// The roads come from [championMinChapter], at [championRoadChance],
// while the quest is under way.

/// The champion of [clanId] (enemies.json).
String championIdOf(String clanId) => 'champion_$clanId';

/// The nemesis quest of [clanId] (quests.json).
String nemesisQuestIdOf(String clanId) => 'q_nemesis_$clanId';

/// The flag the trail sets (the quest's first objective).
String trailFlagOf(String clanId) => 'nemq_${clanId}_trail';

/// The ways in to the champion, in order.
const List<String> championWays = ['force', 'guile', 'mercy'];

/// The flag a way in sets.
String wayFlagOf(String clanId, String way) => 'nemq_${clanId}_$way';

/// The standing Mercy earns with the clan, its champion beaten.
const int mercyStanding = 5;

const int championMinChapter = 4;
const double championRoadChance = 0.35;

String _text(Map<String, dynamic> record, String key, [String fallback = '']) {
  final value = record[key]?.toString() ?? '';
  return value.isEmpty ? fallback : value;
}

/// The trail's road scene: the quest's first objective as the way on, one
/// choice that follows it ([trailFlagOf]); null when [quests] lacks it.
StoryNode? buildTrailNode(
    String clanId, Map<String, dynamic> quests, Random random) {
  final quest = quests[nemesisQuestIdOf(clanId)];
  if (quest is! Map<String, dynamic>) return null;
  final objectives = (quest['objectives'] as List?) ?? const [];
  final trail = objectives
      .whereType<Map<String, dynamic>>()
      .where((o) => o['targetFlag'] == trailFlagOf(clanId))
      .firstOrNull;
  if (trail == null) return null;
  return StoryNode(
    id: '$clanCrisisNodePrefix${clanId}_trail_${random.nextInt(1 << 30)}',
    description: 'The word you were given leads somewhere. '
        '${_text(trail, 'description')}',
    descriptionFr: 'La piste qu’on vous a donnée mène quelque part. '
        '${_text(trail, 'description_fr', _text(trail, 'description'))}',
    choices: [
      StoryChoice(
        text: 'Follow the trail',
        textFr: 'Suivre la piste',
        nextId: '',
        flagsToAdd: [trailFlagOf(clanId)],
      ),
    ],
  );
}

/// The champion's road scene: its `arrival` line, and the ways in
/// (`wayForce`, `wayGuile`, `wayMercy`: each fights it with its edge and
/// sets its flag; Mercy, won, earns [mercyStanding]); with none written,
/// one plain "Face" choice. Null when [enemies] lacks it.
StoryNode? buildChampionNode(
    String clanId, Map<String, dynamic> enemies, Random random) {
  final id = championIdOf(clanId);
  final enemy = enemies[id];
  if (enemy is! Map<String, dynamic>) return null;
  final name = _text(enemy, 'enemyName', id);
  final nameFr = _text(enemy, 'enemyName_fr', name);
  // Its arrival speaks for it (Narrative's lines carry its words); with
  // none, it bars the road and cries out.
  String scene(String arrival, String fallback, String who, String cry) =>
      arrival.isNotEmpty
          ? arrival.replaceAll('{name}', who)
          : '${fallback.replaceAll('{name}', who)} $cry'.trim();
  final ways = [
    for (final way in championWays)
      if (_text(enemy, 'way${way[0].toUpperCase()}${way.substring(1)}')
          .isNotEmpty)
        way,
  ];
  String wayKey(String way) => 'way${way[0].toUpperCase()}${way.substring(1)}';
  return StoryNode(
    id: '$clanCrisisNodePrefix${id}_${random.nextInt(1 << 30)}',
    description: scene(_text(enemy, 'arrival'), '{name} bars the road.', name,
        _text(enemy, 'battleCry')),
    descriptionFr: scene(
        _text(enemy, 'arrival_fr'),
        '{name} vous barre la route.',
        nameFr,
        _text(enemy, 'battleCry_fr', _text(enemy, 'battleCry'))),
    choices: [
      if (ways.isEmpty)
        StoryChoice(
          text: 'Face $name',
          textFr: 'Affronter $nameFr',
          nextId: '',
          triggerEnemyId: id,
        ),
      for (final way in ways)
        StoryChoice(
          text: _text(enemy, wayKey(way)),
          textFr: _text(enemy, '${wayKey(way)}_fr', _text(enemy, wayKey(way))),
          nextId: '',
          triggerEnemyId: id,
          roadEvent: 'nemesis_$way',
          flagsToAdd: [wayFlagOf(clanId, way)],
          politics: way == 'mercy'
              ? StoryPolitics(standing: {clanId: mercyStanding})
              : null,
        ),
    ],
  );
}

/// The champion's record ([record]) with the edge of [way] (encounter.dart's
/// `nemesis_<way>`) folded into its health and damage, for the playthrough
/// simulator, which plays no encounter modifiers.
Map<String, dynamic> championRecordFor(
    Map<String, dynamic> record, String way) {
  final edge = EncounterModifiers.nemesisWayEdges['nemesis_$way'];
  if (edge == null) return record;
  num of(String key) => (record[key] as num?) ?? 0;
  return {
    ...record,
    'maxHealth':
        max(1, (of('maxHealth') * edge.health * edge.difficulty).round()),
    'damage': (of('damage') * damageShareOf(edge.difficulty)).round(),
  };
}

/// The nemesis quest's beat on this road at rest, or null: its quest under
/// way ([activeQuestIds]), from [championMinChapter], at
/// [championRoadChance]; the trail first ([flags] without [trailFlagOf]),
/// then the champion.
List<StoryNode>? maybeChampionRoad({
  required PoliticsState politics,
  required Iterable<String> activeQuestIds,
  required Map<String, dynamic> enemies,
  required int chapter,
  required Random random,
  Iterable<String> flags = const [],
  Map<String, dynamic> quests = const {},
}) {
  final clan = politics.nemesis;
  if (clan.isEmpty || chapter < championMinChapter) return null;
  if (!activeQuestIds.contains(nemesisQuestIdOf(clan))) return null;
  if (random.nextDouble() >= championRoadChance) return null;
  final node = flags.contains(trailFlagOf(clan))
      ? buildChampionNode(clan, enemies, random)
      : buildTrailNode(clan, quests, random) ??
          buildChampionNode(clan, enemies, random);
  return node == null ? null : [node];
}
