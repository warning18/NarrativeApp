import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ability_check.dart';
import '../data/approval.dart';
import '../data/camp_fate.dart';
import '../data/chapter_conditions.dart';
import '../data/chapter_loop.dart';
import '../data/journey_rules.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import 'approval_notice.dart';

/// The camp's fate die (see camp_fate.dart) after a night's rest at the
/// camp: [restedLine] says the night was had, then the die is rolled and
/// its face played out. The party's reactions follow once the dialog is
/// closed.
Future<void> showCampFateDie(BuildContext context, WidgetRef ref,
    {required String restedLine}) async {
  final session = ref.read(playerSessionProvider);
  final chapter = ref.read(reachedChapterProvider);
  final story = ref.read(storyDataProvider).value;
  final flags = session.flags.toSet();
  final fateContext = FateContext(
    chapter: chapter,
    gold: session.gold,
    provisions: session.provisions,
    provisionsMax: provisionsMax,
    companionIds: session.activeAllyIds,
    rumorPlaceIds: [
      if (story != null)
        for (final place in loopPlaces(story))
          if (place.settlement!.chapter == chapter &&
              place.settlement!.mustDiscover &&
              !flags.contains(placeFoundFlag(place.id)))
            place.id,
    ],
  );
  final seed = conditionSeedFor(
    runSeed: session.runSeed,
    characterName: session.characterName,
    raceId: session.raceId,
    professionId: session.professionId,
    cycle: session.newGamePlusCycle,
  );
  final random = fateRandomFor(seed, session.day);
  final roll = rollFate(fateContext, random);
  final reactions = await showDialog<List<ApprovalChange>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CampFateDialog(
      fateContext: fateContext,
      roll: roll,
      random: random,
      restedLine: restedLine,
    ),
  );
  if (reactions != null && reactions.isNotEmpty && context.mounted) {
    await showApprovalReactions(context, ref, reactions);
  }
}

extension FateFaceStyle on FateFace {
  IconData get icon => switch (this) {
        FateFace.windfall => Icons.savings_outlined,
        FateFace.visitor => Icons.hail,
        FateFace.rumor => Icons.hearing,
        FateFace.quarrel => Icons.forum_outlined,
        FateFace.theft => Icons.back_hand_outlined,
        FateFace.quiet => Icons.bedtime_outlined,
      };

  String get labelKey => 'fate_face_$name';
}

/// The die itself, rolled and played out: the six faces with the one it
/// lands on lit, what the night brings, its choices and what came of them.
/// Pops the party's approval changes.
class CampFateDialog extends ConsumerStatefulWidget {
  const CampFateDialog({
    super.key,
    required this.fateContext,
    required this.roll,
    required this.random,
    this.restedLine,
  });

  final FateContext fateContext;
  final FateRoll roll;

  /// Draws the night's checks, after the roll.
  final Random random;
  final String? restedLine;

  @override
  ConsumerState<CampFateDialog> createState() => _CampFateDialogState();
}

enum _Stage { waiting, rolling, landed, done }

class _CampFateDialogState extends ConsumerState<CampFateDialog> {
  _Stage _stage = _Stage.waiting;
  int? _lit;
  Timer? _tumble;
  FateOutcome? _outcome;
  FateChoice? _chosen;
  List<ApprovalChange> _reactions = const [];

  late final List<FateFace> _die = fateDieFor(widget.fateContext);

  @override
  void dispose() {
    _tumble?.cancel();
    super.dispose();
  }

  void _roll() {
    if (_stage != _Stage.waiting) return;
    if (!ref.read(combatEffectsEnabledProvider)) {
      _land();
      return;
    }
    setState(() => _stage = _Stage.rolling);
    var ticks = 0;
    _tumble = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      ticks++;
      if (ticks >= 10) {
        timer.cancel();
        _land();
        return;
      }
      setState(() => _lit = (ticks * 5 + widget.roll.faceIndex) % _die.length);
    });
  }

  void _land() {
    setState(() {
      _lit = widget.roll.faceIndex;
      _stage = _Stage.landed;
    });
    if (fateChoicesFor(widget.roll).isEmpty) _resolve(null);
  }

  Future<void> _resolve(FateChoice? choice) async {
    final session = ref.read(playerSessionProvider);
    final chapter = widget.fateContext.chapter;
    final ability = widget.roll.face == FateFace.theft
        ? theftCheckAbility
        : choice == FateChoice.makePeace
            ? peaceCheckAbility
            : null;
    AbilityCheckResult? check;
    if (ability != null) {
      check = rollAbilityCheck(
        ability: ability,
        dc: fateCheckDc(chapter),
        session: session,
        random: widget.random,
      );
    }
    final outcome = fateOutcome(
      widget.roll,
      widget.fateContext,
      choice: choice,
      checkTotal: check?.total,
      checkPassed: check?.success,
    );
    final notifier = ref.read(playerSessionProvider.notifier);
    var rations = 0;
    if (outcome.provisions != 0) {
      rations = await notifier.adjustProvisions(outcome.provisions);
    }
    final companions =
        ref.read(gameDbProvider(companionsSchema)).value ?? const {};
    final reactions = await notifier.applyChoiceEffects(
      goldMod: outcome.gold,
      alignmentMod: outcome.alignment,
      approvalMods: outcome.approval,
      flagsToAdd: [
        if (outcome.revealPlaceId != null)
          placeFoundFlag(outcome.revealPlaceId!),
      ],
      companions: companions,
      // Only the deserter's bounty is gold made off someone.
      goldIsProfit: choice == FateChoice.handOver,
    );
    if (!mounted) return;
    setState(() {
      _chosen = choice;
      _outcome = FateOutcome(
        gold: outcome.gold,
        provisions: rations,
        alignment: outcome.alignment,
        approval: outcome.approval,
        revealPlaceId: outcome.revealPlaceId,
        checkRoll: outcome.checkRoll,
        checkPassed: outcome.checkPassed,
      );
      _reactions = reactions;
      _stage = _Stage.done;
    });
  }

  String _companionName(String id) {
    final companions =
        ref.read(gameDbProvider(companionsSchema)).value ?? const {};
    final record = companions[id];
    return record is Map ? '${record['companionName'] ?? id}' : id;
  }

  String _placeName(String id, bool french) {
    final story = ref.read(storyDataProvider).value;
    return story?.nodeFor(id)?.settlement?.nameFor(french) ?? id;
  }

  /// What the night brings, before any choice.
  String _eventText(AppLanguage lang) {
    final roll = widget.roll;
    String t(String key) => trFor(lang, key);
    switch (roll.face) {
      case FateFace.windfall:
        return t(widget.fateContext.provisions * 2 <=
                widget.fateContext.provisionsMax
            ? 'fate_windfall_rations'
            : 'fate_windfall_gold');
      case FateFace.visitor:
        return t('fate_visitor_${roll.visitor!.name}');
      case FateFace.rumor:
        return t('fate_rumor').replaceAll(
            '{place}', _placeName(roll.placeId!, lang == AppLanguage.fr));
      case FateFace.quarrel:
        return t('fate_quarrel')
            .replaceAll('{a}', _companionName(roll.quarrelers.first))
            .replaceAll('{b}', _companionName(roll.quarrelers.last))
            .replaceAll(
                '{topic}', t('fate_quarrel_topic_${roll.quarrelTopic}'));
      case FateFace.theft:
        return t('fate_theft');
      case FateFace.quiet:
        return t('fate_quiet_${roll.quietLine}');
    }
  }

  String _choiceLabel(FateChoice choice, AppLanguage lang) {
    final roll = widget.roll;
    final chapter = widget.fateContext.chapter;
    return trFor(lang, 'fate_choice_${choice.name}')
        .replaceAll(
            '{n}',
            choice == FateChoice.handOver
                ? '${deserterBounty(chapter)}'
                : '$pilgrimRations')
        .replaceAll(
            '{name}',
            _companionName(choice == FateChoice.sideWithSecond
                ? roll.quarrelers.last
                : roll.quarrelers.isEmpty
                    ? ''
                    : roll.quarrelers.first))
        .replaceAll('{dc}', '${fateCheckDc(chapter)}');
  }

  /// What came of it, in words.
  String? _resultText(AppLanguage lang) {
    final outcome = _outcome;
    if (outcome == null) return null;
    String t(String key) => trFor(lang, key);
    final roll = widget.roll;
    switch (roll.face) {
      case FateFace.theft:
        if (outcome.checkPassed ?? false) return t('fate_theft_caught');
        if (outcome.gold < 0) return t('fate_theft_gold');
        return t(outcome.provisions < 0
            ? 'fate_theft_rations'
            : 'fate_theft_nothing');
      case FateFace.visitor:
        return _chosen == null ? null : t('fate_result_${_chosen!.name}');
      case FateFace.quarrel:
        final first = _companionName(roll.quarrelers.first);
        final second = _companionName(roll.quarrelers.last);
        return switch (_chosen) {
          FateChoice.sideWithFirst => t('fate_result_side')
              .replaceAll('{winner}', first)
              .replaceAll('{loser}', second),
          FateChoice.sideWithSecond => t('fate_result_side')
              .replaceAll('{winner}', second)
              .replaceAll('{loser}', first),
          FateChoice.makePeace => t((outcome.checkPassed ?? false)
              ? 'fate_result_peace'
              : 'fate_result_no_peace'),
          _ => null,
        };
      case FateFace.windfall:
      case FateFace.rumor:
      case FateFace.quiet:
        return null;
    }
  }

  /// The night's changes, one short line each.
  List<String> _effectLines(AppLanguage lang) {
    final outcome = _outcome;
    if (outcome == null) return const [];
    String t(String key) => trFor(lang, key);
    final ability = widget.roll.face == FateFace.theft
        ? theftCheckAbility
        : peaceCheckAbility;
    return [
      if (outcome.checkRoll != null)
        t('fate_check_line')
            .replaceAll('{stat}', t('${ability}_label'))
            .replaceAll('{total}', '${outcome.checkRoll}')
            .replaceAll('{dc}', '${fateCheckDc(widget.fateContext.chapter)}'),
      if (outcome.gold > 0)
        t('fate_gain_gold').replaceAll('{n}', '${outcome.gold}'),
      if (outcome.gold < 0)
        t('fate_lose_gold').replaceAll('{n}', '${-outcome.gold}'),
      if (outcome.provisions > 0)
        t('fate_gain_rations').replaceAll('{n}', '${outcome.provisions}'),
      if (outcome.provisions < 0)
        t('fate_lose_rations').replaceAll('{n}', '${-outcome.provisions}'),
      if (outcome.alignment != 0)
        t('fate_alignment').replaceAll(
            '{n}',
            outcome.alignment > 0
                ? '+${outcome.alignment}'
                : '${outcome.alignment}'),
      if (outcome.revealPlaceId != null)
        t('fate_place_found').replaceAll('{place}',
            _placeName(outcome.revealPlaceId!, lang == AppLanguage.fr)),
    ];
  }

  Widget _faceTile(int index, ThemeData theme, AppLanguage lang) {
    final face = _die[index];
    final lit = _lit == index;
    final landed = lit && _stage.index >= _Stage.landed.index;
    final scheme = theme.colorScheme;
    return AnimatedContainer(
      key: ValueKey('fate_face_$index'),
      duration: const Duration(milliseconds: 120),
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: lit ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: landed ? scheme.primary : scheme.outlineVariant,
          width: landed ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(face.icon,
              size: 22,
              color: lit ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            trFor(lang, face.labelKey),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
                color:
                    lit ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final choices = fateChoicesFor(widget.roll);
    final showEvent = _stage.index >= _Stage.landed.index;
    final result = _resultText(lang);
    final effects = _effectLines(lang);
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.casino_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(trFor(lang, 'fate_title'))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.restedLine != null) ...[
              Text(widget.restedLine!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            if (!showEvent) Text(trFor(lang, 'fate_intro'), style: body),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _die.length; i++) _faceTile(i, theme, lang),
              ],
            ),
            if (!showEvent) ...[
              const SizedBox(height: 8),
              Text(trFor(lang, 'fate_hint'), style: theme.textTheme.labelSmall),
            ],
            if (showEvent) ...[
              const SizedBox(height: 16),
              Text(_eventText(lang), style: body),
            ],
            if (_stage == _Stage.landed && choices.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final (i, choice) in choices.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: i == 0
                      ? ElevatedButton(
                          key: ValueKey('fate_choice_${choice.name}'),
                          onPressed: fateChoiceOpen(choice, widget.fateContext)
                              ? () => _resolve(choice)
                              : null,
                          child: Text(_choiceLabel(choice, lang)),
                        )
                      : OutlinedButton(
                          key: ValueKey('fate_choice_${choice.name}'),
                          onPressed: fateChoiceOpen(choice, widget.fateContext)
                              ? () => _resolve(choice)
                              : null,
                          child: Text(_choiceLabel(choice, lang)),
                        ),
                ),
            ],
            if (result != null) ...[
              const SizedBox(height: 12),
              Text(result, style: body?.copyWith(fontStyle: FontStyle.italic)),
            ],
            if (effects.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final line in effects)
                Text(line,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
            ],
          ],
        ),
      ),
      actions: [
        if (_stage == _Stage.waiting)
          FilledButton.icon(
            key: const ValueKey('fate_roll_button'),
            onPressed: _roll,
            icon: const Icon(Icons.casino),
            label: Text(trFor(lang, 'fate_roll_button')),
          ),
        if (_stage == _Stage.done)
          FilledButton(
            key: const ValueKey('fate_sleep_button'),
            onPressed: () => Navigator.of(context).pop(_reactions),
            child: Text(trFor(lang, 'fate_close_button')),
          ),
      ],
    );
  }
}
