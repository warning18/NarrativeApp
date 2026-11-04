// The story text, the ending view, New Game+ and the discovery modal, cut out
// of story_player_screen.dart with no change.
part of '../story_player_screen.dart';

class _StoryText extends StatelessWidget {
  const _StoryText({
    required this.text,
    this.prelude = const [],
    this.echoes = const [],
    this.echoCaption = '',
    this.uiTheme,
    this.placeLabel,
    this.moodLabel,
    this.epilogue,
    this.epilogueHeading = '',
    this.speakerLabel,
    this.aftermath,
    this.aftermathHeading = '',
    this.outcome,
    this.revealKey,
  });

  final String text;

  /// Names the scene for the typewriter (see StoryText): the text writes
  /// itself out the first time it is shown under it. Null: shown at once.
  final String? revealKey;

  /// Plain scenes read on the way here (see scene_flow.dart): they open
  /// the page, the scene's own text after a small rule.
  final List<ScenePrelude> prelude;

  /// Lines an earlier choice earned (see echoes.dart), after the scene's
  /// own text, each under the choice that earned it.
  final List<SceneEcho> echoes;

  /// "Because you chose “{choice}”".
  final String echoCaption;

  /// A check's outcome in words (see check_outcomes.dart): the scene
  /// opens with it, after the aftermath, if any. (What the party says
  /// about the last choice shows over the scene in a speech bubble, see
  /// companion_remark_bubble.dart.)
  final String? outcome;

  /// Who is speaking, for a scene voiced by someone other than the
  /// Narrator -- shown as an eyebrow above the body.
  final String? speakerLabel;

  /// The last fight's aftermath, opening the scene in italics under its
  /// own small heading (see combat_aftermath.dart).
  final String? aftermath;
  final String aftermathHeading;

  /// An alignment-specific closing paragraph (see
  /// [StoryNode.alignmentEpilogues]) set under a small heading after the
  /// body, in italics -- how this road looked from where the character
  /// walked it.
  final String? epilogue;
  final String epilogueHeading;

  /// The current node's `context_taxonomy.ui_theme` (docks, cathedral,
  /// slums, ...) — looked up against [uiThemePalettes] to give a few
  /// locations their own subtle color/type accent. Null, or a value with no
  /// entry, leaves this card looking exactly as it always has.
  final String? uiTheme;

  /// Where the scene is and how it feels, as tags above the text (null:
  /// no tag).
  final String? placeLabel;
  final String? moodLabel;

  @override
  Widget build(BuildContext context) {
    // A chapter's title may come with a scene read on the way into it.
    final header = storyHeaderFor(text) ??
        prelude
            .map((p) => storyHeaderFor(p.text))
            .firstWhere((h) => h != null && h.isNotEmpty, orElse: () => null);
    final body = storyBodyFor(text);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = uiThemePaletteFor(uiTheme);
    final accent = resolveUiAccent(colorScheme, palette);
    final hasAftermath = aftermath != null && aftermath!.isNotEmpty;
    final hasOutcome = outcome != null && outcome!.isNotEmpty;

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: InkFonts.prose,
              fontSize: 17,
              height: palette?.lineHeight ?? 1.6,
              letterSpacing: palette?.letterSpacing ?? 0.1,
            ) ??
        const TextStyle();

    // The page is sewn along a dashed thread in the colour of where the
    // story is; the prose sits on the bare page beside it.
    // The chapter's weather drifts faintly behind the words.
    return Stack(
      children: [
        const Positioned.fill(child: _StoryWeather()),
        CustomPaint(
          painter: StitchedEdgePainter(color: accent.border),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (placeLabel != null || moodLabel != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (placeLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: accent.border),
                          ),
                          child: Text(
                            placeLabel!.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: accent.text, letterSpacing: 1),
                          ),
                        ),
                      if (moodLabel != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            moodLabel!.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (header != null && header.isNotEmpty) ...[
                  Text(
                    header,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: InkFonts.display,
                          letterSpacing: 0.5,
                          height: 1.15,
                          color: accent.text,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 56,
                      height: 2,
                      color: accent.text.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (hasAftermath || hasOutcome) ...[
                  if (hasAftermath) ...[
                    Text(
                      aftermathHeading.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            color: accent.text.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aftermath!,
                      textAlign: TextAlign.start,
                      style: baseStyle.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (hasOutcome) ...[
                    if (hasAftermath) const SizedBox(height: 12),
                    Text(
                      outcome!,
                      textAlign: TextAlign.start,
                      style: baseStyle.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: 40,
                      height: 1,
                      color: accent.text.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                for (final scene in prelude) ...[
                  if (scene.speaker != null && scene.speaker!.isNotEmpty) ...[
                    Text(
                      '— ${scene.speaker}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.2,
                            fontStyle: FontStyle.italic,
                            color: accent.text.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  StoryText(
                    text: storyBodyFor(scene.body),
                    style: baseStyle,
                  ),
                  for (final echo in scene.echoes) ...[
                    const SizedBox(height: 14),
                    EchoLine(
                      key: ValueKey('echo_${echo.key}'),
                      echo: echo,
                      caption: echoCaption.replaceAll('{choice}', echo.cause),
                      colour: accent.text,
                      style: baseStyle,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '⁂',
                      style: TextStyle(
                          color: accent.text.withValues(alpha: 0.55),
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (speakerLabel != null && speakerLabel!.isNotEmpty) ...[
                  Text(
                    '— $speakerLabel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          fontStyle: FontStyle.italic,
                          color: accent.text.withValues(alpha: 0.85),
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
                StoryText(
                  text: body,
                  style: baseStyle,
                  revealKey: revealKey,
                ),
                for (final echo in echoes) ...[
                  const SizedBox(height: 14),
                  EchoLine(
                    key: ValueKey('echo_${echo.key}'),
                    echo: echo,
                    caption: echoCaption.replaceAll('{choice}', echo.cause),
                    colour: accent.text,
                    style: baseStyle,
                  ),
                ],
                if (epilogue != null && epilogue!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      width: 40,
                      height: 1,
                      color: accent.text.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    epilogueHeading.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          color: accent.text.withValues(alpha: 0.8),
                        ),
                  ),
                  const SizedBox(height: 8),
                  StoryText(
                    text: epilogue!,
                    style: baseStyle.copyWith(fontStyle: FontStyle.italic),
                    firstSentenceBold: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EndingView extends ConsumerWidget {
  const _EndingView({
    required this.title,
    required this.message,
    required this.restartLabel,
    required this.onRestart,
    this.session,
    this.onNewGamePlus,
  });

  final String title;
  final String message;
  final String restartLabel;
  final VoidCallback onRestart;

  /// Offered on a genuine story ending: bank this run's legacy and start
  /// the next, harder cycle (see `PlayerSessionNotifier.beginNewGamePlus`).
  final VoidCallback? onNewGamePlus;

  /// When set, a recap card (level/gold/alignment/quests) is shown below
  /// the message — only passed for a genuine story ending, not the "trail
  /// goes cold" data-error state.
  final PlayerSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapSession = session;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (recapSession != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(ref, 'path_summary_label'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '${tr(ref, 'final_level_label')}: ${recapSession.level}'),
                      Text(
                          '${tr(ref, 'final_gold_label')}: ${recapSession.gold}'),
                      Text(
                        '${tr(ref, 'final_alignment_label')}: '
                        '${trAlignmentLabel(ref, recapSession.alignmentLabel)} '
                        '(${recapSession.alignmentScore})',
                      ),
                      Text(
                        '${tr(ref, 'quests_completed_label')}: '
                        '${recapSession.completedQuestIds.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (recapSession != null) ...[
              const SizedBox(height: 16),
              // Who holds each town at the end (the epilogue map).
              OutlinedButton.icon(
                key: const Key('ending_realm_map'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EpilogueMapScreen())),
                icon: const Icon(Icons.map_outlined),
                label: Text(tr(ref, 'epilogue_map_button')),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRestart,
              child: Text(restartLabel),
            ),
            if (onNewGamePlus != null && recapSession != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onNewGamePlus,
                icon: const Icon(Icons.replay_circle_filled_outlined),
                label: Text(
                  '${tr(ref, 'new_game_plus_button')} · '
                  '${tr(ref, 'new_game_plus_cycle_label')} '
                  '${recapSession.newGamePlusCycle + 1}',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(ref, 'new_game_plus_hint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirms, then banks the finished run as the next cycle's legacy and
/// restarts the story from the top -- character creation picks the legacy
/// up (see `PlayerSessionNotifier.startNewGame`).
Future<void> _startNewGamePlus(BuildContext context, WidgetRef ref) async {
  final lang = ref.read(appLanguageProvider);
  final session = ref.read(playerSessionProvider);
  final nextCycle = session.newGamePlusCycle + 1;
  final bonus = (newGamePlusStep * nextCycle * 100).round();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
          '${trFor(lang, 'new_game_plus_button')} · ${trFor(lang, 'new_game_plus_cycle_label')} $nextCycle'),
      content: Text(
        '${trFor(lang, 'new_game_plus_desc')}\n\n'
        '${trFor(lang, 'new_game_plus_enemies_prefix')} +$bonus% '
        '${trFor(lang, 'new_game_plus_enemies_suffix')}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(trFor(lang, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(trFor(lang, 'new_game_plus_confirm')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(playerSessionProvider.notifier).beginNewGamePlus();
  if (!context.mounted) return;
  ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
  // A crown of gold sparks: the road begins again, harder.
  final middle = MediaQuery.sizeOf(context).center(Offset.zero);
  showBurst(context, at: middle, colour: const Color(0xFFD4A017), count: 28);
  showQuestSeal(context, colour: const Color(0xFFB8860B));
  showImmersiveNotice(
    context,
    icon: Icons.replay_circle_filled_outlined,
    message: trFor(lang, 'new_game_plus_started_message'),
  );
}

/// Shown once, right after a choice unlocks a shop and/or quest, on the
/// node the player just arrived at — lets them jump straight in instead of
/// only noticing the Play-tab CTA chip.
Future<void> _showDiscoveryModal(
  BuildContext context,
  WidgetRef ref,
  PendingDiscovery discovery, {
  required Map<String, dynamic> shops,
  required Map<String, dynamic> quests,
}) async {
  final lang = ref.read(appLanguageProvider);
  final shopId = discovery.shopId;
  final questId = discovery.questId;
  final shop = shopId != null ? shops[shopId] as Map<String, dynamic>? : null;
  final quest =
      questId != null ? quests[questId] as Map<String, dynamic>? : null;
  final session = ref.read(playerSessionProvider);
  // In play mode a shop is only reachable from the node that unlocked it
  // (see PlayerSession.shopUnlockNodeIds) — walking away without opening it
  // now means it isn't there "later" like the button implies, so don't
  // offer that false promise when a shop is part of the discovery.
  final isPlayMode = ref.read(appModeProvider) == AppMode.inGame;
  final showMaybeLater = !(isPlayMode && shopId != null);

  final questActive =
      questId != null && session.activeQuestIds.contains(questId);
  final questCompleted =
      questId != null && session.completedQuestIds.contains(questId);
  final requiredGold = (quest?['requiredGold'] as num?)?.toInt() ?? 0;
  final requiredFlags =
      (quest?['requiredFlags'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
  final questEligible = questId != null &&
      !questActive &&
      !questCompleted &&
      session.meetsRequirements(reqGold: requiredGold, reqFlags: requiredFlags);

  Future<void> acceptDiscoveredQuest() async {
    await ref
        .read(playerSessionProvider.notifier)
        .acceptQuest(questId!, quest: quest);
    if (!context.mounted) return;
    showImmersiveNotice(
      context,
      icon: Icons.assignment_turned_in_outlined,
      message:
          '${trFor(lang, 'quest_accepted_prefix')}: ${quest?['questName']?.toString() ?? questId}',
    );
  }

  // A main quest is never left for later (Wave 6): taken on at once (here,
  // or already by the quests that settle themselves, see
  // quest_autopilot.dart); the dialog then only shows what else was found.
  if (isPlayMode && isMainQuest(quest)) {
    if (questEligible) await acceptDiscoveredQuest();
    if (shopId == null || !context.mounted) return;
    return _showDiscoveryModal(context, ref, PendingDiscovery(shopId: shopId),
        shops: shops, quests: quests);
  }

  void viewDiscoveredQuest() {
    final questName = quest?['questName']?.toString() ?? questId!;
    final category = quest?['category']?.toString();
    final dialogue = quest?['npcDialogueText']?.toString() ?? '';
    final rewardGold = (quest?['rewardGold'] as num?)?.toInt() ?? 0;
    final rewardXp = (quest?['rewardXP'] as num?)?.toInt() ?? 0;
    final rewardItemId = quest?['rewardItemID']?.toString() ?? '';
    final rewardDiceId = quest?['rewardDiceID']?.toString() ?? '';

    showDetailDialog(
      context,
      title: questName,
      description: dialogue,
      icon: Icons.assignment,
      closeLabel: trFor(lang, 'close_button'),
      rows: [
        if (category != null && category.isNotEmpty)
          MapEntry(trFor(lang, 'category_label'), category),
        if (requiredGold > 0)
          MapEntry(trFor(lang, 'required_gold_label'), '$requiredGold'),
        if (requiredFlags.isNotEmpty)
          MapEntry(
              trFor(lang, 'required_flags_label'), requiredFlags.join(', ')),
        // A quest settled by a choice pays by it (see turn_in_choices.dart).
        if (turnInChoicesOf(quest).isNotEmpty)
          MapEntry(trFor(lang, 'reward_gold_label'), () {
            final golds = [
              for (final c in turnInChoicesOf(quest)) c.goldFor(rewardGold)
            ]..sort();
            return '${golds.first}–${golds.last}';
          }())
        else if (rewardGold > 0)
          MapEntry(trFor(lang, 'reward_gold_label'), '$rewardGold'),
        if (rewardXp > 0) MapEntry(trFor(lang, 'reward_xp_label'), '$rewardXp'),
        if (rewardItemId.isNotEmpty)
          MapEntry(trFor(lang, 'reward_item_label'), rewardItemId),
        if (rewardDiceId.isNotEmpty)
          MapEntry(trFor(lang, 'reward_dice_label'), rewardDiceId),
        MapEntry(
          trFor(lang, 'status_label'),
          questCompleted
              ? trFor(lang, 'status_completed')
              : (questActive
                  ? trFor(lang, 'status_active')
                  : trFor(lang, 'status_available')),
        ),
      ],
      extraActionLabel: questEligible ? trFor(lang, 'accept') : null,
      onExtraAction: questEligible ? acceptDiscoveredQuest : null,
    );
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(trFor(lang, 'discovery_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shopId != null) ...[
            Text(trFor(lang, 'shop_discovered_message')),
            const SizedBox(height: 4),
            Text(
              shop?['shopName']?.toString() ?? shopId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          if (shopId != null && questId != null) const SizedBox(height: 12),
          if (questId != null) ...[
            Text(trFor(lang, 'quest_discovered_message')),
            const SizedBox(height: 4),
            Text(
              quest?['questName']?.toString() ?? questId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        if (showMaybeLater)
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(trFor(lang, 'maybe_later_button')),
          ),
        if (shopId != null && shop != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        ShopDetailScreen(shopId: shopId, shop: shop)),
              );
            },
            child: Text(trFor(lang, 'open_shop_button')),
          ),
        if (questId != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              viewDiscoveredQuest();
            },
            child: Text(trFor(lang, 'view_quest_button')),
          ),
        if (questEligible)
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              acceptDiscoveredQuest();
            },
            child: Text(trFor(lang, 'accept')),
          ),
      ],
    ),
  );
}

/// The tag for a scene's place (`context_taxonomy.ui_theme`), or null for
/// none: only real places get one, not the prologue or the endings.
String? _placeLabel(WidgetRef ref, String? uiTheme) {
  if (uiTheme == null) return null;
  final key = 'place_$uiTheme';
  final label = tr(ref, key);
  return label == key ? null : label;
}

/// The tag for a scene's mood, or null for none (a neutral one has none).
String? _moodLabel(WidgetRef ref, String? mood) {
  if (mood == null) return null;
  final key = 'mood_$mood';
  final label = tr(ref, key);
  return label == key ? null : label;
}

/// A line an earlier choice earned (see echoes.dart). In play it is set
/// into the story as ordinary prose, with nothing to say where it came
/// from; in Edit Mode (the story node editor's preview) it stays under a
/// small caption naming the choice ("Because you chose “Spare him”"), set
/// off by a thread in the scene's colour, so the author sees what earned it.
class EchoLine extends ConsumerWidget {
  const EchoLine({
    super.key,
    required this.echo,
    required this.caption,
    required this.colour,
    required this.style,
  });

  final SceneEcho echo;
  final String caption;
  final Color colour;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appModeProvider) != AppMode.edit) {
      return StoryText(text: echo.line, style: style, firstSentenceBold: false);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(color: colour.withValues(alpha: 0.6), width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 14, color: colour),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    caption,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.4,
                          color: colour,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            StoryText(text: echo.line, style: style, firstSentenceBold: false),
          ],
        ),
      ),
    );
  }
}
