// The choice cards and the small widgets around the story text, cut out of
// story_player_screen.dart with no change.
part of '../story_player_screen.dart';

/// Fade + subtle upward slide used whenever the story advances to a
/// different node (or leaves/enters an excursion), for both the narrative
/// text and the choice list below it.
Widget _nodeTransition(Widget child, Animation<double> animation) {
  final offset = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
      .animate(animation);
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(position: offset, child: child),
  );
}

/// Fades and slides [child] up into place, starting after [delay] — used to
/// stagger each choice button's entrance so a fresh node's options reveal
/// one after another instead of popping in all at once.
class _StaggeredReveal extends StatefulWidget {
  const _StaggeredReveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (stillMotion(context)) {
      _controller.value = 1; // shown at once, not staggered
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _ChoiceButton extends ConsumerWidget {
  const _ChoiceButton({
    required this.choice,
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
  });

  final StoryChoice choice;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainQuestShut = _mainQuestShut(ref, choice, isExcursion);
    final locked = mainQuestShut ||
        _isChoiceLocked(choice, story, session, isExcursion,
            world: ref.watch(coastGateWorldProvider),
            shutWays: ref.watch(lockedStoryWaysProvider));

    final lockedLabel = locked
        ? storyChoiceLockedText(ref, choice, session,
            isExcursion: isExcursion,
            french: french,
            mainQuestShut: mainQuestShut)
        : null;
    final label = (lockedLabel?.isNotEmpty ?? false)
        ? lockedLabel!
        : choice.textFor(french);

    // A fight is never a surprise behind a plain label ("Return to the
    // stalls"): the button carries crossed swords and who is fought. A
    // detour's own fight button already names them.
    // Watching the enemies database also keeps it warm, so it is ready by
    // the time a fight button is tapped.
    final enemies = choice.triggersCombat
        ? ref.watch(localizedDbProvider(enemiesSchema)).value
        : null;
    final roster = isExcursion ? null : _fightRosterFor(choice, enemies);
    // A side job waits a scene or two down this way: say so.
    final workAhead = !isExcursion &&
        !locked &&
        questOfferedAhead(
          choice: choice,
          story: story,
          takenQuestIds: {
            ...session.activeQuestIds,
            ...session.completedQuestIds,
          },
          mainQuestIds: mainQuestIdsOf(
              ref.watch(localizedDbProvider(questsSchema)).value ?? const {}),
        );

    final hint = isExcursion ? '' : choicePoliticsHint(ref, choice);
    final Widget content = roster != null && !choice.hasAbilityCheck
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_martial_arts, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    Text(
                      tr(ref, 'choice_fight_roster')
                          .replaceAll('{roster}', roster),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          )
        : choice.hasAbilityCheck
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.casino_outlined, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$label '
                      '(${tr(ref, '${choice.checkAbility}_label')} '
                      'DC ${choice.checkDC ?? 10})',
                    ),
                  ),
                ],
              )
            : _ChoiceLabel(
                label: label,
                choice: choice,
                locked: locked,
                workAhead: workAhead,
              );

    return ElevatedButton(
      style: inkChoiceStyle(context),
      onPressed: locked
          ? null
          : () => _selectChoice(
                context: context,
                ref: ref,
                choice: choice,
                story: story,
                session: session,
                currentNodeId: currentNodeId,
                isExcursion: isExcursion,
                french: french,
              ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: hint.isEmpty
            ? content
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: 4),
                  _PoliticsHintLine(hint: hint),
                ],
              ),
      ),
    );
  }
}

/// What a choice moves among the clans (v1.195, see politicsHint), for the
/// muted line under it: '' when the setting is off, or the choice moves
/// nothing it may say.
String choicePoliticsHint(WidgetRef ref, StoryChoice choice) {
  final politics = choice.politics;
  if (politics == null || !politics.hasHint) return '';
  if (!ref.watch(politicsHintsEnabledProvider)) return '';
  return politicsHint(
      politics, ref.watch(clanDataProvider), ref.watch(appLanguageProvider),
      politics: ref.watch(politicsProvider));
}

/// The muted line under a choice: "Vigil +5 · Dominion −5".
class _PoliticsHintLine extends StatelessWidget {
  const _PoliticsHintLine({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.7,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                hint,
                key: const Key('politics_hint'),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
}

/// A plain choice's text, with what it costs or brings underneath as
/// small tags ("+20 gold", "−10 HP", "Alignment −1").
class _ChoiceLabel extends ConsumerWidget {
  const _ChoiceLabel({
    required this.label,
    required this.choice,
    this.locked = false,
    this.workAhead = false,
  });

  final String label;
  final StoryChoice choice;

  /// A choice the player can't take yet: its tags fade with the card.
  final bool locked;

  /// A side job is on offer down this way (see questOfferedAhead).
  final bool workAhead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    String signed(int v) => v > 0 ? '+$v' : '\u2212${v.abs()}';
    final tags = [
      if (choice.goldMod != 0)
        InkTag(
          label: '${signed(choice.goldMod)} ${tr(ref, 'gold_label')}',
          color: ink.gold,
        ),
      if (choice.healAmount != 0)
        InkTag(
          label: '${signed(choice.healAmount)} ${tr(ref, 'hp_label')}',
          color: choice.healAmount > 0 ? ink.heal : ink.blood,
        ),
      if (choice.alignmentMod != 0)
        InkTag(
          label: '${tr(ref, 'alignment_label')} ${signed(choice.alignmentMod)}',
          color: ink.voidColor,
        ),
      if (choice.grantsItem)
        InkTag(
          label:
              '+ ${(ref.watch(localizedDbProvider(itemsSchema)).value?[choice.grantItemId] as Map<String, dynamic>?)?['itemName'] ?? choice.grantItemId}',
          color: ink.gold,
        ),
      if (workAhead)
        InkTag(label: tr(ref, 'choice_work_ahead'), color: ink.gold),
    ];
    if (tags.isEmpty) return Text(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Opacity(
          opacity: locked ? 0.45 : 1,
          child: Wrap(spacing: 6, runSpacing: 4, children: tags),
        ),
      ],
    );
  }
}

/// Toggles reading the current node's narrative text aloud -- in the
/// recorded ElevenLabs voice when it is on, the device's text-to-speech
/// voice otherwise (see [_speakNarration]) -- in whichever language the
/// app is set to. Tapping again while speaking (or while a paragraph is
/// being recorded) stops it.
class _ReadAloudButton extends ConsumerWidget {
  const _ReadAloudButton({required this.paragraphs, required this.language});

  final List<String> paragraphs;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(elevenLabsTtsProvider);
    final isLoading = voiceState == VoicePlaybackState.loading;
    final isSpeaking =
        voiceState != VoicePlaybackState.idle || ref.watch(ttsProvider);

    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isSpeaking
                  ? Icons.stop_circle_outlined
                  : Icons.volume_up_outlined,
              size: 18),
      tooltip: isLoading
          ? tr(ref, 'loading_voice_tooltip')
          : (isSpeaking
              ? tr(ref, 'stop_reading_tooltip')
              : tr(ref, 'read_aloud_tooltip')),
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        if (isSpeaking) {
          _stopAllNarration(ref);
          return;
        }
        try {
          await _speakNarration(ref, paragraphs, language);
        } catch (e) {
          if (!context.mounted) return;
          unawaited(showImmersiveNotice(
            context,
            icon: Icons.error_outline,
            message: '${tr(ref, 'voice_error_prefix')}: $e',
          ));
        }
      },
    );
  }
}

/// Edit Mode: records the scene on screen -- every paragraph it can be
/// read in, in the app's language, companions' asides and callbacks
/// included -- so it plays offline and can be pushed to the repository.
/// Lit once the whole scene is recorded.
class _RecordSceneButton extends ConsumerWidget {
  const _RecordSceneButton({required this.paragraphs, required this.language});

  final List<String> paragraphs;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(narrationRecordingsVersionProvider);
    final voice = ref.watch(elevenLabsVoiceSettingsProvider);
    return FutureBuilder<bool>(
      future: ref
          .read(elevenLabsTtsProvider.notifier)
          .isRecorded(paragraphs, settings: voice, language: language),
      builder: (context, snapshot) {
        final recorded = snapshot.data ?? false;
        return IconButton(
          icon: Icon(recorded ? Icons.mic : Icons.mic_none, size: 18),
          color: recorded ? Theme.of(context).colorScheme.primary : null,
          tooltip: tr(ref, recorded ? 'scene_recorded' : 'record_scene'),
          visualDensity: VisualDensity.compact,
          onPressed: () => recordNarration(context, ref, {language: paragraphs},
              confirm: false),
        );
      },
    );
  }
}

/// A town or camp's scene the reader has already read, folded to one line
/// that opens it again, with the last fight's aftermath under it when
/// there is one -- so the place's own lists get the screen.
class _FoldedNarration extends StatelessWidget {
  const _FoldedNarration({
    super.key,
    required this.label,
    required this.onOpen,
    this.uiTheme,
    this.aftermath,
    this.aftermathHeading = '',
    this.outcome,
  });

  final String label;
  final VoidCallback onOpen;
  final String? uiTheme;
  final String? aftermath;
  final String aftermathHeading;

  /// A check's outcome in words (see check_outcomes.dart), kept under the
  /// folded line like the aftermath.
  final String? outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = uiThemePaletteFor(uiTheme);
    final accent = resolveUiAccent(theme.colorScheme, palette);
    return Material(
      color: accent.cardTint.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_outlined,
                      size: 20, color: accent.text),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: accent.text),
                    ),
                  ),
                  Icon(Icons.expand_more, color: accent.text),
                ],
              ),
              if (aftermath != null && aftermath!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  aftermathHeading.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: accent.text.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Text(
                      aftermath!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              if (outcome != null && outcome!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  outcome!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a story node's narrative text with a book-like presentation:
/// a leading `[CHAPTER N: TITLE]`-style header (if present) is pulled out
/// and styled as a centered heading with a divider, and the body gets
/// generous spacing, justified alignment, and a soft parchment-like card.
class _StoryWeather extends ConsumerWidget {
  const _StoryWeather();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = ref.watch(reachedChapterProvider);
    // What the sky brings where the story stands (v1.204), the burning
    // chapters' ash under a clear one.
    final sky = ref.watch(skyHereProvider)?.today();
    return WeatherLayer(
        weather: journeyWeatherOf(sky?.kind, chapter), strength: 0.3);
  }
}
