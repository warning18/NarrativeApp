import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart' show scaledMaxHealth;
import '../gamedata/db_schema.dart';
import '../models/ally_state.dart';
import '../providers/chapter_loop_provider.dart'
    show chapterConditionProvider, reachedChapterProvider;
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import 'journey_rules.dart';
import 'road_events.dart';
import 'story_repository.dart';

/// What a road hazard (v1.197, see road_events.dart) does to the party,
/// for the story's own choice and for autoplay alike.

/// A companion's health after pushing on through a hazard that deals
/// [wound]: what is [stored] (the full-health sentinel included), at most
/// [maxHealth], less the wound, never the last point (see
/// healthAfterHazard).
int companionHealthAfterHazard({
  required int stored,
  required int maxHealth,
  required int wound,
}) =>
    healthAfterHazard(min(stored, maxHealth), wound);

/// Pushing on through a hazard: [wound] health from each companion in the
/// party, never the last point. The character's own wound is the push's
/// healAmount, taken with the choice's other effects.
Future<void> woundCompanionsOnRoad(WidgetRef ref, int wound) async {
  final session = ref.read(playerSessionProvider);
  if (wound <= 0 || session.activeAllyIds.isEmpty) return;
  Future<Map<String, dynamic>> table(DbSchema schema) =>
      ref.read(gameDbProvider(schema).notifier).whenLoaded();
  final companions = await table(companionsSchema);
  final races = await table(racesSchema);
  final professions = await table(professionsSchema);
  Map<String, dynamic> gameConfig;
  try {
    gameConfig = await ref.read(gameConfigProvider.future);
  } catch (_) {
    gameConfig = const {};
  }
  final notifier = ref.read(playerSessionProvider.notifier);
  for (final ally in session.recruitedAllies) {
    if (!session.activeAllyIds.contains(ally.companionId)) continue;
    final companion = companions[ally.companionId] as Map<String, dynamic>?;
    Map<String, dynamic> preset(Map<String, dynamic> records, String key) =>
        records[companion?[key]?.toString() ?? ''] as Map<String, dynamic>? ??
        const {};
    final base = deriveAllyBaseStats(
      gameConfig: gameConfig,
      race: preset(races, 'raceId'),
      profession: preset(professions, 'professionId'),
    );
    final maxHealth = scaledMaxHealth(base.maxHealth, session.level);
    final before = min(ally.currentHealth, maxHealth);
    final after = companionHealthAfterHazard(
        stored: ally.currentHealth, maxHealth: maxHealth, wound: wound);
    if (after == before) continue;
    await notifier.applyAllyCombatResult(ally.companionId, hpAfter: after);
  }
}

/// Waiting a hazard out in [chapter]: a whole day on the road, with the
/// day's ration (or, with none left, hunger; see takeRoadStep).
Future<RoadStep> waitOutRoadHazard(WidgetRef ref, {required int chapter}) => ref
    .read(playerSessionProvider.notifier)
    .takeRoadStep(chapter: chapter, watches: watchesPerDay);

/// What a party nobody steers did about a hazard (see [meetRoadHazard]).
enum HazardTaken { pushedOn, waitedOut }

/// The hazard on the road from [fromNodeId] to [toNodeId] of [story], for
/// autoplay (v1.197): met where the game would meet it (see roadEventFor,
/// with the chapter's condition), and as the simulator takes it, pushed
/// through above half health (the character and each companion wounded,
/// see hazardWoundFor), waited out below (see [waitOutRoadHazard]). The
/// road's other events autoplay passes by, as it does detours. Null when
/// the road holds no hazard.
Future<HazardTaken?> meetRoadHazard(
  WidgetRef ref,
  StoryData story, {
  required String fromNodeId,
  required String toNodeId,
}) async {
  final biome =
      (await loadGeography(ref)).roadBiome(story, fromNodeId, toNodeId);
  final share = hazardShareFor(biome);
  if (share == 0) return null;
  final chapter = ref.read(reachedChapterProvider);
  final condition = ref.read(chapterConditionProvider);
  final kind = roadEventFor(
    story: story,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    historyLength: ref.read(storyPlayProvider).history.length,
    chapter: chapter,
    oddsFactor: condition?.roadEventOdds ?? 1,
    championShare: condition?.championShare ?? 0.4,
    shrineShare: condition?.shrineShare ?? 0.3,
    hazardShare: share,
  );
  if (kind != RoadEventKind.hazard) return null;
  final session = ref.read(playerSessionProvider);
  if (hazardPushesOn(
      health: session.currentHealth, maxHealth: session.maxHealth)) {
    final wound = hazardWoundFor(chapter);
    await ref
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(healAmount: -wound);
    await woundCompanionsOnRoad(ref, wound);
    return HazardTaken.pushedOn;
  }
  await waitOutRoadHazard(ref, chapter: chapter);
  return HazardTaken.waitedOut;
}
