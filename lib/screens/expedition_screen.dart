import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_aftermath.dart';
import '../combat/combat_engine.dart';
import '../combat/encounter.dart';
import '../data/ability_check.dart';
import '../data/alignment_events.dart';
import '../data/chapter_conditions.dart';
import '../data/chapter_loop.dart';
import '../data/check_outcomes.dart';
import '../data/companion_remarks.dart';
import '../data/expedition_kinds.dart';
import '../data/map_themes.dart';
import '../data/sub_node_engine.dart';
import '../data/zone_gating.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/chapter_loop_provider.dart'
    show chapterConditionProvider, reachedChapterProvider;
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/approval_notice.dart';
import '../widgets/companion_remark_bubble.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/moments.dart';
import 'fight_screen.dart';
import 'shop_detail_screen.dart';

enum _ExpeditionPhase { event, completed, retreated }

/// Walks one zone's fixed chain of expedition events (`expeditionCount` in
/// zones.json) — the Phase 1 "one zone, land only" slice of the roguelike
/// redesign. Each event is drawn live from [SubNodeEngine]'s existing themed
/// flavor pools rather than hand-authored content, so a new zone needs no
/// per-event writing to exist — only a zones.json row.
///
/// A fight lost or fled mid-expedition, or a voluntary retreat between
/// events, ends the run without the zone's own banked reward (see
/// [PlayerSessionNotifier.completeZone]) — everything already gained this
/// run (gold, items, XP from any won fight) is kept regardless.
///
/// An escort or a delivery (zones.json `kind`, see expedition_kinds.dart)
/// walks its own stages instead of random events: the wagons' load or the
/// days on the road are shown under the progress bar, each choice says
/// what it cost, and the pay at the end follows what arrived and when.
class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen(
      {super.key, required this.zoneId, required this.zone, this.random});

  final String zoneId;
  final Map<String, dynamic> zone;

  /// The expedition's draws (a test's seeded one); a fresh one by default.
  final Random? random;

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen> {
  late final Random _random = widget.random ?? Random();
  int _index = 0;
  StoryNode? _current;
  _ExpeditionPhase _phase = _ExpeditionPhase.event;
  bool _busy = false;
  List<String> _summaryLines = const [];

  /// Bonus events queued ahead of the zone's own next draw -- a hunt's
  /// trail and quarry after a pack win (see [SubNodeEngine.buildHuntNodes]).
  /// They don't count toward [_expeditionCount]: a hunt is extra, never a
  /// substitute for the zone's own events.
  final List<StoryNode> _bonusQueue = [];

  /// Set once the zone's boss (zones.json `bossEnemyId`) has been beaten
  /// this run, so the zone completes instead of re-offering it.
  bool _bossDone = false;

  /// The zone's halfway beat has been shown this expedition.
  bool _midpointShown = false;

  /// The last fight's aftermath, opening the next event's text.
  String? _aftermath;

  /// A check's outcome in words (see check_outcomes.dart), opening the
  /// next event like the aftermath, and a companion's remark on it (see
  /// companion_remarks.dart), shown over the next event in a speech bubble.
  String? _checkOutcome;
  List<CompanionRemark> _remarks = const [];

  /// What the expedition asks (see expedition_kinds.dart).
  late final ExpeditionKind _kind = expeditionKindOf(widget.zone);

  /// An escort's load left, in percent, and a delivery's days on the road.
  int _cargo = escortCargoFull;
  int _daysUsed = 0;

  /// The escort's or delivery's current stage (its choices' costs), and
  /// the stages already met this expedition.
  ExpeditionStep? _step;
  final Set<String> _usedScenes = {};

  /// What the last choice cost the wagons or the days, opening the next
  /// event.
  String? _kindNote;

  /// The expedition's half day has passed on the world's clock (see
  /// [_passItsTime]).
  bool _timePassed = false;

  int get _deadline => deliveryDeadlineOf(widget.zone);

  int get _expeditionCount =>
      (widget.zone['expeditionCount'] as num?)?.toInt() ?? 3;

  int get _zoneChapter => (widget.zone['chapter'] as num?)?.toInt() ?? 1;

  String get _bossEnemyId => widget.zone['bossEnemyId']?.toString() ?? '';

  /// Every fight in this zone carries the zone's chapter (for the chapter
  /// difficulty curve and the chest's loot window) and its tier multiplier.
  EncounterModifiers _zoneModifiers(EncounterModifiers base) => base.copyWith(
        chapter: _zoneChapter,
        difficultyMultiplier: zoneTierMultiplier(zoneTier(widget.zone)),
      );

  bool _isBossNode(StoryNode? node) =>
      node != null && node.id == 'zone_boss_${widget.zoneId}';

  bool _isMidpointNode(StoryNode? node) =>
      node != null && node.id == 'zone_mid_${widget.zoneId}';

  /// The zone's halfway beat: a paragraph of the zone's own narration
  /// (`midpointFlavorText`) between two events, shown once per expedition
  /// and never counted as an event. Null for a zone without one.
  StoryNode? _buildMidpointNode() {
    final text = widget.zone['midpointFlavorText']?.toString() ?? '';
    if (text.isEmpty) return null;
    final textFr = widget.zone['midpointFlavorTextFr']?.toString() ?? '';
    return StoryNode(
      id: 'zone_mid_${widget.zoneId}',
      description: text,
      descriptionFr: textFr.isEmpty ? null : textFr,
      choices: [
        StoryChoice(
          text: trFor(AppLanguage.en, 'expedition_press_on'),
          textFr: trFor(AppLanguage.fr, 'expedition_press_on'),
          nextId: '',
        ),
      ],
    );
  }

  /// The zone-boss event: the zone's `bossFlavorText` and a single fight
  /// choice against `bossEnemyId`, shown once the zone's own events are
  /// done. Winning completes the zone; losing ends the run as a defeat.
  StoryNode _buildBossNode(Map<String, dynamic> boss) {
    final bossName = boss['enemyName']?.toString() ?? _bossEnemyId;
    final flavorFr = widget.zone['bossFlavorTextFr']?.toString() ?? '';
    return StoryNode(
      id: 'zone_boss_${widget.zoneId}',
      description: widget.zone['bossFlavorText']?.toString() ?? '',
      descriptionFr: flavorFr.isEmpty ? null : flavorFr,
      choices: [
        StoryChoice(
          text: '${trFor(AppLanguage.en, 'zone_boss_face_prefix')} $bossName',
          textFr: '${trFor(AppLanguage.fr, 'zone_boss_face_prefix')} $bossName',
          nextId: '',
          triggerEnemyId: _bossEnemyId,
        ),
      ],
    );
  }

  StoryNode _rollEvent({
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
  }) {
    final session = ref.read(playerSessionProvider);
    final theme = MapTheme.values.firstWhere(
      (t) => t.name == (widget.zone['mapTheme']?.toString() ?? ''),
      orElse: () => defaultMapTheme,
    );
    final zoneChapter = _zoneChapter;
    final alignmentEvent = maybeAlignmentEvent(
      alignmentScore: session.alignmentScore,
      activeQuestIds: session.activeQuestIds,
      completedQuestIds: session.completedQuestIds,
      enemies: enemies,
      chapter: zoneChapter,
      random: _random,
      enabled: ref.read(alignmentHuntersEnabledProvider),
      rollsSinceAmbush: session.alignmentRollsSinceAmbush,
    );
    unawaited(ref.read(playerSessionProvider.notifier).noteAlignmentRoll(
        ambushed:
            alignmentEvent != null && isHunterAmbushChain(alignmentEvent)));
    _step = null;
    if (alignmentEvent != null) return alignmentEvent.first;
    final shopPool = SubNodeEngine.filterShopPool(
      shops: shops,
      unlockedShopIds: session.unlockedShopIds,
      chapter: zoneChapter,
    );
    final enemyPool = SubNodeEngine.weightedEnemyPool(
      enemies: enemies,
      unlockedEnemyIds: session.unlockedEnemyIds,
      chapter: zoneChapter,
    );
    // An escort or a delivery walks its own stages, not the zone's random
    // events.
    if (_kind != ExpeditionKind.clear) {
      final step = buildKindStep(
        _kind,
        chapter: zoneChapter,
        random: _random,
        used: _usedScenes,
        enemyPool: enemyPool,
        packPool: SubNodeEngine.filterPackPool(
            enemies: enemies, enemyPool: enemyPool),
      );
      _usedScenes.add(step.key);
      _step = step;
      return step.node;
    }
    return SubNodeEngine.buildNode(
      random: _random,
      flavor: flavorFor(theme),
      shopPool: shopPool,
      enemyPool: enemyPool,
      packPool:
          SubNodeEngine.filterPackPool(enemies: enemies, enemyPool: enemyPool),
      maxPackSize: SubNodeEngine.maxPackSizeFor(
        zoneChapter,
        partySize: 1 + session.activeAllyIds.length,
      ),
      enemies: enemies,
      shops: shops,
      chapter: zoneChapter,
    );
  }

  Future<void> _advance({
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
    bool countsTowardZone = true,
  }) async {
    if (_bonusQueue.isNotEmpty) {
      setState(() {
        _current = _bonusQueue.removeAt(0);
        _step = null;
        _busy = false;
      });
      return;
    }
    final nextIndex = countsTowardZone ? _index + 1 : _index;
    if (nextIndex >= _expeditionCount) {
      // The zone's own events are done: its boss (if it has one) guards
      // the banked reward; a zone without one completes outright.
      final boss = enemies[_bossEnemyId] as Map<String, dynamic>?;
      if (_bossEnemyId.isNotEmpty && !_bossDone && boss != null) {
        setState(() {
          _index = nextIndex;
          _current = _buildBossNode(boss);
          _step = null;
          _busy = false;
        });
        return;
      }
      await _completeZone();
      return;
    }
    // Halfway through, the zone reveals its first place (a town, a
    // village, a site the party can travel to from now on).
    if (countsTowardZone && nextIndex == _expeditionCount ~/ 2) {
      final found = await _discoverPlaces(atEnd: false);
      if (found.isNotEmpty && mounted) {
        showImmersiveNotice(context,
            icon: Icons.travel_explore, message: found.join('\n'));
      }
    }
    // Halfway through a zone of three or more events, its own narration
    // gets a word in before the next draw.
    if (countsTowardZone &&
        !_midpointShown &&
        _expeditionCount >= 3 &&
        nextIndex == _expeditionCount ~/ 2) {
      final beat = _buildMidpointNode();
      if (beat != null) {
        _midpointShown = true;
        setState(() {
          _index = nextIndex;
          _current = beat;
          _step = null;
          _busy = false;
        });
        return;
      }
    }
    setState(() {
      _index = nextIndex;
      _current = _rollEvent(shops: shops, enemies: enemies);
      _busy = false;
    });
  }

  Future<void> _resolveChoice(
    StoryChoice choice, {
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
  }) async {
    setState(() {
      _busy = true;
      _aftermath = null;
      _checkOutcome = null;
      _kindNote = null;
      _remarks = const [];
    });
    final notifier = ref.read(playerSessionProvider.notifier);
    // A bonus event (a hunt's trail or quarry, or an alignment ambush that
    // replaced a draw) is extra: resolving it never advances the zone's
    // own event count.
    final countsTowardZone = !_isBonusNode(_current);
    final isBoss = _isBossNode(_current);
    // What this choice costs an escort's wagons or a delivery's days.
    final step =
        _step != null && identical(_step!.node, _current) ? _step : null;
    final stepOutcome = step != null
        ? step.outcomeFor(_current!.choices.indexOf(choice))
        : isBoss && _kind == ExpeditionKind.escort
            ? escortBossOutcome
            : null;

    // A check on the road (v1.162): sneak past, dig deeper, scavenge. A
    // failed one forfeits the choice's reward; a sneak that works leaves
    // its fight behind, and one that fails starts it.
    var fightAvoided = false;
    var checkFailed = false;
    if (choice.hasAbilityCheck) {
      final lang = ref.read(appLanguageProvider);
      final result = rollAbilityCheck(
        ability: choice.checkAbility!,
        dc: choice.checkDC ?? 10,
        session: ref.read(playerSessionProvider),
      );
      await showImmersiveNotice(
        context,
        icon: result.success ? Icons.check_circle : Icons.cancel,
        message: '${trFor(lang, '${result.ability}_label')} '
            '${trFor(lang, 'check_label')}: '
            '${result.roll} + ${result.modifier} = ${result.total} '
            '${trFor(lang, 'vs_dc_label')} ${result.dc} — '
            '${trFor(lang, result.success ? 'ability_check_success' : 'ability_check_fail')}',
      );
      if (!mounted) return;
      fightAvoided = result.success && choice.avoidFightOnSuccess;
      checkFailed = !result.success;
      if (checkOutcomeNeedsTelling(
        success: result.success,
        onTheRoad: true,
        hasFailScene: false,
        isSneak: choice.avoidFightOnSuccess,
      )) {
        _checkOutcome = checkOutcomeLineFor(result.ability,
            success: result.success,
            french: lang == AppLanguage.fr,
            seed: Random().nextInt(1 << 20));
      }
      _remarks = speakUpAbout(ref,
          action: !result.success
              ? RemarkKind.checkFailed
              : fightAvoided
                  ? RemarkKind.sneakedPast
                  : RemarkKind.checkPassed);
    }

    final enemyIds =
        fightAvoided ? const <String>[] : choice.allTriggerEnemyIds;
    if (enemyIds.isNotEmpty) {
      final resolvedEnemies = {
        for (final eid in enemyIds) eid: enemies[eid] as Map<String, dynamic>?,
      };
      if (resolvedEnemies.values.any((e) => e == null)) {
        await _advance(
            shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
        return;
      }
      final won = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FightScreen(
            enemyId: enemyIds.first,
            enemy: resolvedEnemies[enemyIds.first]!,
            additionalEnemyIds: enemyIds.skip(1).toList(),
            additionalEnemies: {
              for (final eid in enemyIds.skip(1)) eid: resolvedEnemies[eid]!,
            },
            modifiers: isBoss
                ? EncounterModifiers.zoneBoss(
                    chapter: _zoneChapter,
                    difficultyMultiplier:
                        zoneTierMultiplier(zoneTier(widget.zone)),
                  )
                : _zoneModifiers(EncounterModifiers.fromChoice(choice)),
          ),
        ),
      );
      if (!mounted) return;
      if (won != true) {
        // Getting away from the fight ends the expedition as a retreat.
        final retreated = ref.read(lastFightRetreatedProvider);
        ref.read(lastFightRetreatedProvider.notifier).state = false;
        await _endAsRetreat(defeated: !retreated);
        return;
      }
      final outcome = ref.read(lastFightOutcomeProvider);
      if (outcome != null) {
        _aftermath = aftermathLineFor(
          outcome,
          french: ref.read(appLanguageProvider) == AppLanguage.fr,
          seed: _random.nextInt(1 << 20),
        );
      }
      for (final eid in enemyIds.toSet()) {
        await notifier.unlockContent(enemyId: eid);
      }
      if (!mounted) return;
      if (!await _applyStepOutcome(stepOutcome,
          failed: checkFailed, fought: true, isStage: step != null)) {
        return;
      }
      if (isBoss) {
        _bossDone = true;
        await _completeZone();
        return;
      }
      // A pack win may open a hunt: the trail, then the pack's named
      // survivor, queued as bonus events before the zone's next draw.
      final wasBonus = !countsTowardZone;
      if (enemyIds.length >= 2 &&
          _random.nextDouble() < SubNodeEngine.huntChance) {
        final quarryId = enemyIds[_random.nextInt(enemyIds.length)];
        _bonusQueue.addAll(SubNodeEngine.buildHuntNodes(
          quarryId: quarryId,
          quarryBaseName:
              (enemies[quarryId] as Map<String, dynamic>?)?['enemyName']
                      ?.toString() ??
                  quarryId,
          random: _random,
        ));
      }
      await _advance(
          shops: shops, enemies: enemies, countsTowardZone: !wasBonus);
      return;
    }

    final shopId = choice.unlockShopId;
    if (shopId != null && shopId.isNotEmpty) {
      final shop = shops[shopId] as Map<String, dynamic>?;
      // Met on the expedition's road: gone once the party moves on.
      await notifier.unlockContent(
          shopId: shopId, shopUnlockNodeId: roadShopNodeId);
      if (shop != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ShopDetailScreen(shopId: shopId, shop: shop)),
        );
      }
      if (!mounted) return;
      await _advance(
          shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
      return;
    }

    final questId = choice.unlockQuestId;
    if (questId != null && questId.isNotEmpty) {
      await notifier.unlockContent(questId: questId);
      if (!mounted) return;
      await _advance(
          shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
      return;
    }

    if (choice.hasEffects && !checkFailed) {
      final reactions = await notifier.applyChoiceEffects(
        goldMod: choice.goldMod,
        alignmentMod: choice.alignmentMod,
        healAmount: choice.healAmount,
        flagsToAdd: choice.flagsToAdd,
        questIDToProgress: choice.questIDToProgress,
        approvalMods: choice.approvalMods,
        companions:
            ref.read(gameDbProvider(companionsSchema)).value ?? const {},
        // What an expedition turns up is loot, not greed.
        goldIsProfit: false,
      );
      if (reactions.isNotEmpty && mounted) {
        await showApprovalReactions(context, ref, reactions,
            deed: RemarkDeed(
                alignmentMod: choice.alignmentMod,
                approvalMods: choice.approvalMods));
      }
    }
    if (!mounted) return;
    if (!await _applyStepOutcome(stepOutcome,
        failed: checkFailed, fought: false, isStage: step != null)) {
      return;
    }
    await _advance(
        shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
  }

  /// What a choice of an escort's or a delivery's stage cost ([outcome],
  /// resolved by whether its roll [failed] and whether the party
  /// [fought]): the wagons' load, the days on the road (a stage takes one,
  /// when [isStage]; extra ones pass on the world's clock too) and the
  /// leader's health. False when the last of the load was lost, which ends
  /// the escort.
  Future<bool> _applyStepOutcome(StepOutcome? outcome,
      {required bool failed,
      required bool fought,
      required bool isStage}) async {
    if (outcome == null || _kind == ExpeditionKind.clear) return true;
    final lang = ref.read(appLanguageProvider);
    final notifier = ref.read(playerSessionProvider.notifier);
    final cost = outcome.resolve(failed: failed, fought: fought);
    final notes = <String>[];
    if (_kind == ExpeditionKind.escort && cost.cargo != 0) {
      _cargo = (_cargo + cost.cargo).clamp(0, escortCargoFull);
      if (cost.cargo < 0) {
        notes.add(trFor(lang, 'escort_cargo_lost')
            .replaceAll('{n}', '${-cost.cargo}')
            .replaceAll('{left}', '$_cargo'));
      }
    }
    if (_kind == ExpeditionKind.delivery && isStage) {
      _daysUsed = max(0, _daysUsed + 1 + cost.days);
      if (cost.days != 0) {
        notes.add(trFor(lang,
                cost.days > 0 ? 'delivery_day_lost' : 'delivery_day_saved')
            .replaceAll('{used}', '$_daysUsed')
            .replaceAll('{deadline}', '$_deadline'));
      }
    } else if (_kind == ExpeditionKind.escort && cost.days > 0) {
      notes.add(trFor(lang, 'escort_day_lost'));
    }
    // A day lost on the road is a day on the world's clock (see
    // journey_rules.dart).
    if (cost.days > 0) {
      await notifier.passDays(cost.days,
          chapter: ref.read(reachedChapterProvider));
    }
    if (cost.hurt > 0) {
      final session = ref.read(playerSessionProvider);
      final bite = max(1, (session.maxHealth * cost.hurt / 100).round());
      await notifier.applyChoiceEffects(healAmount: -bite);
      notes.add(trFor(lang, 'expedition_hurt').replaceAll('{n}', '$bite'));
    }
    if (!mounted) return false;
    _kindNote = notes.isEmpty ? null : notes.join(' ');
    if (_kind == ExpeditionKind.escort && _cargo <= 0) {
      await _passItsTime();
      if (!mounted) return false;
      setState(() {
        _phase = _ExpeditionPhase.retreated;
        _summaryLines = [trFor(lang, 'escort_lost_message')];
        _busy = false;
      });
      return false;
    }
    return true;
  }

  /// A hunt node (trail or quarry), a hunter ambush, or a temptation --
  /// anything not drawn from the zone's own pools.
  bool _isBonusNode(StoryNode? node) {
    if (node == null) return false;
    if (node.id.startsWith('hunter_') ||
        node.id.startsWith('temptation_') ||
        _isMidpointNode(node)) {
      return true;
    }
    final choice = node.choices.isEmpty ? null : node.choices.first;
    return choice != null &&
        ((choice.huntName ?? '').isNotEmpty ||
            (choice.text == 'Follow the trail'));
  }

  /// Marks the places the zone reveals at this point (see
  /// zoneDiscoveriesAt) found, and returns a line for each newly found one.
  Future<List<String>> _discoverPlaces({required bool atEnd}) async {
    final ids = zoneDiscoveriesAt(widget.zone, atEnd: atEnd);
    if (ids.isEmpty) return const [];
    final flags = ref.read(playerSessionProvider).flags;
    final fresh = [
      for (final id in ids)
        if (!flags.contains(placeFoundFlag(id))) id,
    ];
    if (fresh.isEmpty) return const [];
    await ref.read(playerSessionProvider.notifier).applyChoiceEffects(
        flagsToAdd: [for (final id in fresh) placeFoundFlag(id)]);
    final story = ref.read(storyDataProvider).value;
    final lang = ref.read(appLanguageProvider);
    return [
      for (final id in fresh)
        trFor(lang, 'place_found_line').replaceAll(
            '{place}',
            story?.nodeFor(id)?.settlement?.nameFor(lang == AppLanguage.fr) ??
                id),
    ];
  }

  /// An expedition takes half a day, however it ends (cleared, a
  /// retreat, a defeat, the load lost): it passes once, on the world's
  /// clock (see journey_rules.dart).
  Future<void> _passItsTime() async {
    if (_timePassed) return;
    _timePassed = true;
    await ref
        .read(playerSessionProvider.notifier)
        .passTime(2, chapter: ref.read(reachedChapterProvider));
  }

  Future<void> _completeZone() async {
    final notifier = ref.read(playerSessionProvider.notifier);
    await _passItsTime();
    final lang = ref.read(appLanguageProvider);
    final zoneGold = (widget.zone['rewardGold'] as num?)?.toInt() ?? 0;
    final zoneItemId = widget.zone['rewardItemId']?.toString() ?? '';
    // An escort is paid for the load that arrived, a delivery for arriving
    // in time; either keeps its extra thanks (the item) for doing well.
    final kindLines = <String>[];
    var rewardGold = zoneGold;
    var rewardItemId = zoneItemId;
    switch (_kind) {
      case ExpeditionKind.clear:
        break;
      case ExpeditionKind.escort:
        rewardGold = escortPayFor(zoneGold, _cargo);
        kindLines
            .add(trFor(lang, 'escort_arrived').replaceAll('{n}', '$_cargo'));
        if (!escortKeepsItem(_cargo) && zoneItemId.isNotEmpty) {
          rewardItemId = '';
          kindLines.add(trFor(lang, 'escort_item_missed'));
        }
      case ExpeditionKind.delivery:
        final onTime = deliveryOnTime(daysUsed: _daysUsed, deadline: _deadline);
        rewardGold =
            deliveryPayFor(zoneGold, daysUsed: _daysUsed, deadline: _deadline);
        if (onTime) {
          kindLines.add(trFor(lang, 'delivery_on_time')
              .replaceAll('{used}', '$_daysUsed')
              .replaceAll('{deadline}', '$_deadline'));
        } else {
          rewardItemId = '';
          kindLines.add(trFor(lang, 'delivery_late')
              .replaceAll('{n}', '${_daysUsed - _deadline}'));
        }
    }
    // The chapter's condition: a rival company takes the best contracts,
    // a bounty season pays over the rate.
    final condition = ref.read(chapterConditionProvider);
    if (condition != null && condition.expeditionPay != 1 && rewardGold > 0) {
      final before = rewardGold;
      rewardGold = conditionedPrice(rewardGold, condition.expeditionPay);
      final delta = rewardGold - before;
      kindLines.add(trFor(lang, 'condition_pay_line')
          .replaceAll('{name}', condition.nameFor(lang == AppLanguage.fr))
          .replaceAll('{delta}', delta > 0 ? '+$delta' : '$delta'));
    }
    final rewardDiceId = widget.zone['rewardDiceId']?.toString() ?? '';
    final rewardAllyId = widget.zone['rewardAllyId']?.toString() ?? '';
    final rewardFlag = widget.zone['rewardFlag']?.toString() ?? '';
    final companions =
        ref.read(localizedDbProvider(companionsSchema)).value ?? const {};

    await notifier.completeZone(
      widget.zoneId,
      rewardGold: rewardGold,
      rewardItemId: rewardItemId.isNotEmpty ? rewardItemId : null,
      rewardDiceId: rewardDiceId.isNotEmpty ? rewardDiceId : null,
      rewardFlag: rewardFlag.isNotEmpty ? rewardFlag : null,
    );

    final lines = <String>[
      ...kindLines,
      ...await _discoverPlaces(atEnd: true),
    ];
    if (rewardGold > 0) {
      lines.add('+$rewardGold ${trFor(lang, 'gold_label')}');
    }
    if (rewardItemId.isNotEmpty) {
      final items =
          ref.read(localizedDbProvider(itemsSchema)).value ?? const {};
      final itemName =
          (items[rewardItemId] as Map<String, dynamic>?)?['itemName']
              ?.toString();
      lines.add(itemName ?? rewardItemId);
    }
    if (rewardDiceId.isNotEmpty) {
      final dice = ref.read(localizedDbProvider(diceSchema)).value ?? const {};
      final diceName =
          (dice[rewardDiceId] as Map<String, dynamic>?)?['diceName']
              ?.toString();
      lines.add(diceName ?? rewardDiceId);
    }
    if (rewardAllyId.isNotEmpty) {
      final races =
          ref.read(localizedDbProvider(racesSchema)).value ?? const {};
      final professions =
          ref.read(localizedDbProvider(professionsSchema)).value ?? const {};
      final companion = companions[rewardAllyId] as Map<String, dynamic>?;
      final race = races[companion?['raceId']?.toString() ?? '']
          as Map<String, dynamic>?;
      final profession =
          professions[companion?['professionId']?.toString() ?? '']
              as Map<String, dynamic>?;
      final houses =
          ref.read(localizedDbProvider(housesSchema)).value ?? const {};
      await notifier.recruitAlly(
        rewardAllyId,
        race: race,
        profession: profession,
        companion: companion,
        dice: ref.read(localizedDbProvider(diceSchema)).value ?? const {},
        houses: houses,
        requiredHouseId: companion?['requiredHouseId']?.toString(),
      );
      lines.add(companion?['companionName']?.toString() ?? rewardAllyId);
    }
    if (rewardFlag.isNotEmpty) {
      final flagKey = 'zone_flag_$rewardFlag';
      final flagLine = trFor(lang, flagKey);
      if (flagLine != flagKey) lines.add(flagLine);
    }

    final newAchievements = await notifier.checkAchievements(
        totalCompanionCount: companions.length);
    if (newAchievements.isNotEmpty) {
      final achievements =
          ref.read(localizedDbProvider(achievementsSchema)).value ?? const {};
      for (final id in newAchievements) {
        final name =
            (achievements[id] as Map<String, dynamic>?)?['achievementName']
                ?.toString();
        lines.add(
            '${trFor(lang, 'achievement_unlocked_prefix')}: ${name ?? id}');
      }
    }

    if (!mounted) return;
    if (newAchievements.isNotEmpty) {
      final achievements =
          ref.read(localizedDbProvider(achievementsSchema)).value ?? const {};
      unawaited(announceAchievements(
          context,
          [
            for (final id in newAchievements)
              (achievements[id] as Map<String, dynamic>?)?['achievementName']
                      ?.toString() ??
                  id
          ],
          trFor(lang, 'achievement_unlocked_prefix').toUpperCase()));
    }
    setState(() {
      _phase = _ExpeditionPhase.completed;
      _summaryLines = lines;
      _busy = false;
    });
  }

  Future<void> _endAsRetreat({required bool defeated}) async {
    if (!mounted) return;
    await _passItsTime();
    if (!mounted) return;
    setState(() {
      _phase = _ExpeditionPhase.retreated;
      _summaryLines = [
        trFor(
          ref.read(appLanguageProvider),
          defeated
              ? 'expedition_defeated_message'
              : 'expedition_retreat_message',
        ),
      ];
      _busy = false;
    });
  }

  String _choiceLabel(StoryChoice choice) =>
      ref.watch(appLanguageProvider) == AppLanguage.fr &&
              (choice.textFr?.isNotEmpty ?? false)
          ? choice.textFr!
          : choice.text;

  @override
  Widget build(BuildContext context) {
    final zoneName = widget.zone['zoneName']?.toString() ?? '';
    final shopsAsync = ref.watch(localizedDbProvider(shopsSchema));
    final enemiesAsync = ref.watch(localizedDbProvider(enemiesSchema));
    // Kept loaded for the party's reactions to a choice (see approval.dart).
    ref.watch(localizedDbProvider(companionsSchema));
    final shops = shopsAsync.value;
    final enemies = enemiesAsync.value;

    if (shops == null || enemies == null) {
      return Scaffold(
        appBar: AppBar(title: Text(zoneName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _current ??= _rollEvent(shops: shops, enemies: enemies);
    final lang = ref.watch(appLanguageProvider);

    return TutorialTrigger(
      topic: TutorialTopic.expedition,
      child: CompanionRemarksTrigger(
        remarks: _remarks,
        ready: !_busy,
        // Backing out of an event is a retreat, and takes its time too.
        child: PopScope(
          canPop: _phase != _ExpeditionPhase.event,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_busy) _endAsRetreat(defeated: false);
          },
          child: Scaffold(
            appBar: AppBar(title: Text(zoneName)),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: switch (_phase) {
                  // Each event dealt like a card turning over.
                  _ExpeditionPhase.event => FlipIn(
                      flipKey: _index,
                      child: _buildEvent(context,
                          shops: shops, enemies: enemies, lang: lang),
                    ),
                  _ExpeditionPhase.completed => _buildSummary(
                      context,
                      icon: switch (_kind) {
                        ExpeditionKind.escort => Icons.local_shipping,
                        ExpeditionKind.delivery => Icons.markunread_mailbox,
                        ExpeditionKind.clear => Icons.flag_circle,
                      },
                      title: trFor(
                          lang,
                          switch (_kind) {
                            ExpeditionKind.escort => 'escort_done_title',
                            ExpeditionKind.delivery => 'delivery_done_title',
                            ExpeditionKind.clear => 'zone_cleared_prefix',
                          }),
                    ),
                  _ExpeditionPhase.retreated => _buildSummary(
                      context,
                      icon: Icons.directions_walk,
                      title: trFor(lang, 'expedition_ended_title'),
                    ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvent(
    BuildContext context, {
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
    required AppLanguage lang,
  }) {
    final node = _current!;
    // A payment the purse can't make (a toll, a bribe, a guide's fee) is
    // shut, and says why.
    final gold = ref.watch(playerSessionProvider.select((s) => s.gold));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
            value: (_index / _expeditionCount).clamp(0.0, 1.0)),
        const SizedBox(height: 8),
        Text(
          _isBossNode(node)
              ? trFor(lang, 'expedition_boss_label')
              : _isMidpointNode(node)
                  ? trFor(lang, 'expedition_midpoint_label')
                  : '${trFor(lang, 'expedition_progress_label')} ${_index + 1} / $_expeditionCount',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        if (_kind != ExpeditionKind.clear) ...[
          const SizedBox(height: 8),
          _kindGauge(context, lang),
        ],
        const SizedBox(height: 4),
        // Why every event here happens: the party came to clear this
        // place, and its guardian stands between them and what it holds.
        Text(
          _goalLine(lang, enemies),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (node.contextNoteFor(lang == AppLanguage.fr)
                    case final note?) ...[
                  Text(
                    note,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_aftermath != null && _aftermath!.isNotEmpty) ...[
                  Text(
                    _aftermath!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_checkOutcome != null && _checkOutcome!.isNotEmpty) ...[
                  Text(
                    _checkOutcome!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_kindNote != null) ...[
                  Text(
                    _kindNote!,
                    key: const ValueKey('expedition_kind_note'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  node.descriptionFor(lang == AppLanguage.fr),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // A temptation scene offers two answers; every other event has one.
        for (final choice in node.choices) ...[
          ElevatedButton(
            onPressed: _busy || !choice.affordableWith(gold)
                ? null
                : () => _resolveChoice(choice, shops: shops, enemies: enemies),
            child: Text(choice.affordableWith(gold)
                ? _choiceLabel(choice)
                : trFor(lang, 'choice_gold_short_lock')
                    .replaceAll('{choice}', _choiceLabel(choice))
                    .replaceAll('{gold}', '$gold')),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _endAsRetreat(defeated: false),
          icon: const Icon(Icons.directions_walk),
          label: Text(trFor(lang, 'retreat_button')),
        ),
      ],
    );
  }

  /// "Clear 4 encounters here, then its guardian, Overseer Renn, to claim
  /// the zone." -- the reason the party is fighting its way through. An
  /// escort's or a delivery's says what it is paid for.
  String _goalLine(AppLanguage lang, Map<String, dynamic> enemies) {
    final bossName =
        (enemies[_bossEnemyId] as Map<String, dynamic>?)?['enemyName']
                ?.toString() ??
            '';
    final key = switch (_kind) {
      ExpeditionKind.escort => 'expedition_goal_escort',
      ExpeditionKind.delivery => 'expedition_goal_delivery',
      ExpeditionKind.clear =>
        bossName.isEmpty ? 'expedition_goal_no_boss' : 'expedition_goal',
    };
    final place = widget.zone['destinationName']?.toString() ?? '';
    return trFor(lang, key)
        .replaceAll('{n}', '$_expeditionCount')
        .replaceAll('{boss}', bossName)
        .replaceAll('{days}', '$_deadline')
        .replaceAll('{place}', place);
  }

  /// An escort's load left, or a delivery's days on the road against its
  /// deadline: a bar that reddens as it runs short.
  Widget _kindGauge(BuildContext context, AppLanguage lang) {
    final scheme = Theme.of(context).colorScheme;
    if (_kind == ExpeditionKind.escort) {
      final low = _cargo < escortItemCargo;
      return Row(
        key: const ValueKey('expedition_cargo_gauge'),
        children: [
          Icon(Icons.local_shipping,
              size: 18, color: low ? scheme.error : scheme.primary),
          const SizedBox(width: 6),
          Text('${trFor(lang, 'escort_cargo_label')} $_cargo%',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: _cargo / escortCargoFull,
              color: low ? scheme.error : scheme.primary,
            ),
          ),
        ],
      );
    }
    // Days left against the stages left: red once the parcel can only
    // arrive late.
    final stagesLeft = max(0, _expeditionCount - _index);
    final late = _daysUsed + stagesLeft > _deadline;
    return Row(
      key: const ValueKey('expedition_deadline_gauge'),
      children: [
        Icon(Icons.hourglass_bottom,
            size: 18, color: late ? scheme.error : scheme.primary),
        const SizedBox(width: 6),
        Text(
          trFor(lang, 'delivery_days_line')
              .replaceAll('{used}', '$_daysUsed')
              .replaceAll('{deadline}', '$_deadline'),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: late ? scheme.error : null),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: (_daysUsed / _deadline).clamp(0.0, 1.0),
            color: late ? scheme.error : scheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context,
      {required IconData icon, required String title}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        for (final line in _summaryLines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_phase == _ExpeditionPhase.completed),
          child: Text(
              trFor(ref.watch(appLanguageProvider), 'return_to_town_button')),
        ),
      ],
    );
  }
}
