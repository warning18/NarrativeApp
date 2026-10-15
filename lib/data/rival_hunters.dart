// The rivals' hunters (v5.2 step 3b, docs/proposals/profession-clan-mechanics.md
// "Loyalty has a price"): sworn to a clan, each of its rivals you stand
// Hostile with, or that hunts you, may send a fighter onto the roads.
//
// - The odds: [rivalHunterChanceHostile] a road at rest for each Hostile
//   rival, [rivalHunterChanceHunted] for each one that hunts you, up to
//   [hunterChanceCap] (the alignment hunters' own cap). They share the
//   alignment hunters' cooldown and settings toggle: a road holds one
//   ambush at most.
// - The fighters: enemies.json's `hunterClan` (and `hunterTier`: tier 1
//   through chapter 2, either from chapter 3). The Vigil's, the Compact's
//   and the Mire's are `hunterOnly` (never an ordinary draw), with their
//   `battleCry` (Narrative's, docs/proposals/rival-hunters.md); the
//   Dominion, the Crows and the Penitents send fighters already on the
//   roads.
//
// Pure rules; the story player and the playthrough simulator roll them.
import 'dart:math';

import '../l10n/app_locale.dart';
import '../models/story_node.dart';
import 'alignment_events.dart' show hunterChanceCap;
import 'factions.dart';

const double rivalHunterChanceHostile = 0.04;
const double rivalHunterChanceHunted = 0.08;

/// The sworn clan's rivals hunting the character now, each with its odds
/// a road: a Hostile one [rivalHunterChanceHostile], a Hunted one
/// [rivalHunterChanceHunted]. Empty while sworn to none.
Map<String, double> rivalHunts(PoliticsState state, ClanData data) {
  final sworn = state.swornFactionId;
  if (sworn.isEmpty) return const {};
  return {
    for (final rival in rivalsOf(sworn, state, data))
      if (data.faction(rival)?.isClan ?? false)
        if (switch (state.tierOf(rival, data)) {
          StandingTier.hunted => rivalHunterChanceHunted,
          StandingTier.hostile => rivalHunterChanceHostile,
          _ => 0.0,
        }
            case final chance when chance > 0)
          rival: chance,
  };
}

/// The odds a rival's hunter comes on a road: [rivalHunts] summed, up to
/// [hunterChanceCap].
double rivalHunterChance(PoliticsState state, ClanData data) => min(
    hunterChanceCap,
    rivalHunts(state, data).values.fold(0.0, (sum, chance) => sum + chance));

/// [clanId]'s hunters in [enemies] for [chapter]: tier 1 through chapter
/// 2, either tier from chapter 3, none before its `minChapter`.
List<String> rivalHunterPool({
  required Map<String, dynamic> enemies,
  required String clanId,
  required int chapter,
}) =>
    [
      for (final MapEntry(:key, :value) in enemies.entries)
        if (value is Map<String, dynamic> &&
            value['hunterClan']?.toString() == clanId &&
            ((value['minChapter'] as num?)?.toInt() ?? 1) <= chapter &&
            (chapter > 2 || ((value['hunterTier'] as num?)?.toInt() ?? 1) <= 1))
          key,
    ];

const String _ambushEn = '{name} bars the road. {cry}';
const String _ambushFr = '{name} vous barre la route. {cry}';
const String _noCryEn = '“You swore to the other side. We remember.”';
const String _noCryFr = '« Vous avez juré à l’autre camp. Nous nous en '
    'souvenons. »';
const String _reasonEn = '{clan}: your oath to {sworn} is not forgiven.';
const String _reasonFr =
    '{clan} : votre serment envers {sworn} n’est pas pardonné.';

/// A one-node ambush by a hunter of [clanId] (drawn from
/// [rivalHunterPool]), or null when it has none for [chapter].
StoryNode? buildRivalAmbushNode({
  required Map<String, dynamic> enemies,
  required String clanId,
  required String swornId,
  required ClanData data,
  required int chapter,
  required Random random,
}) {
  final pool =
      rivalHunterPool(enemies: enemies, clanId: clanId, chapter: chapter);
  if (pool.isEmpty) return null;
  final enemyId = pool[random.nextInt(pool.length)];
  final enemy = enemies[enemyId] as Map<String, dynamic>;
  String text(String key) => enemy[key]?.toString() ?? '';
  final cry = text('battleCry');
  final cryFr = text('battleCry_fr');
  final clan = data.faction(clanId);
  final sworn = data.faction(swornId);
  return StoryNode(
    id: 'rival_hunter_${enemyId}_${random.nextInt(1 << 30)}',
    description: _ambushEn
        .replaceAll('{name}', text('enemyName'))
        .replaceAll('{cry}', cry.isEmpty ? _noCryEn : cry),
    descriptionFr: _ambushFr
        .replaceAll(
            '{name}',
            text('enemyName_fr').isEmpty
                ? text('enemyName')
                : text('enemyName_fr'))
        .replaceAll('{cry}', cryFr.isEmpty ? _noCryFr : cryFr),
    contextNote: _reasonEn
        .replaceAll('{clan}', clan?.nameFor(AppLanguage.en) ?? clanId)
        .replaceAll('{sworn}', sworn?.nameFor(AppLanguage.en) ?? swornId),
    contextNoteFr: _reasonFr
        .replaceAll('{clan}', clan?.nameFor(AppLanguage.fr) ?? clanId)
        .replaceAll('{sworn}', sworn?.nameFor(AppLanguage.fr) ?? swornId),
    choices: [
      StoryChoice(
        text: 'Stand and fight',
        textFr: 'Faire face',
        nextId: '',
        triggerEnemyId: enemyId,
        isHunterAmbush: true,
      ),
    ],
  );
}

/// A rival's hunter on this road, or null (the common case): sworn, at
/// [rivalHunterChance], a fighter of one of the [rivalHunts] (drawn by
/// their odds). Rolled where an alignment hunter is, after it, and
/// sharing its [enabled] toggle and cooldown ([cooledDown]).
List<StoryNode>? maybeRivalHunter({
  required PoliticsState politics,
  required ClanData data,
  required Map<String, dynamic> enemies,
  required int chapter,
  required Random random,
  bool enabled = true,
  bool cooledDown = true,
}) {
  if (!enabled || !cooledDown) return null;
  final hunts = rivalHunts(politics, data);
  if (hunts.isEmpty) return null;
  if (random.nextDouble() >= rivalHunterChance(politics, data)) return null;
  final total = hunts.values.fold(0.0, (sum, chance) => sum + chance);
  var pick = random.nextDouble() * total;
  var clanId = hunts.keys.last;
  for (final MapEntry(:key, :value) in hunts.entries) {
    pick -= value;
    if (pick < 0) {
      clanId = key;
      break;
    }
  }
  final node = buildRivalAmbushNode(
      enemies: enemies,
      clanId: clanId,
      swornId: politics.swornFactionId,
      data: data,
      chapter: chapter,
      random: random);
  return node == null ? null : [node];
}
