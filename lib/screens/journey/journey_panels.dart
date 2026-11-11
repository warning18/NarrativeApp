// The scene panel, the map button, the looked-at panel and the ended panel.
// Cut out of journey_screen.dart with no change.
part of '../journey_screen.dart';

/// The scene the story is on, as the Story tab tells it: what the last
/// fight or roll left behind, who speaks, and the scene itself. A
/// double-tap reads it full screen, as in the Story tab, and another
/// brings the map back.
class _ScenePanel extends ConsumerWidget {
  const _ScenePanel({
    super.key,
    required this.story,
    required this.node,
    required this.french,
    required this.folded,
    required this.reading,
    required this.onFold,
    required this.onReading,
    this.detour,
    this.revealKey,
    this.shrinkToText = false,
    this.toMap = true,
    this.locked = false,
  });

  final StoryData story;
  final StoryNode node;

  /// The panel is only as tall as its words, up to the room it is given,
  /// and scrolls beyond it (the arrival sheet, v1.550); false fills it.
  final bool shrinkToText;

  /// Read full screen, whether it has a way back to the map.
  final bool toMap;

  /// A locked page (v1.553): the corner's map button waits, greyed.
  final bool locked;

  /// Names the scene for the typewriter (see StoryText); null shows its
  /// words at once.
  final String? revealKey;
  final bool french;

  /// Folded to its first lines, to leave the map the room.
  final bool folded;
  final ValueChanged<bool> onFold;

  /// Read full screen.
  final bool reading;
  final ValueChanged<bool> onReading;

  /// On a detour: what it is met on the way to, and why.
  final String? detour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final aftermath = ref.watch(pendingAftermathProvider);
    final outcome = ref.watch(pendingCheckOutcomeProvider);
    final roadNote = ref.watch(pendingRoadNoteProvider);
    final taken = ref.watch(pendingTakenProvider);
    // Plain scenes read on the way here open this one (see
    // scene_flow.dart); lines an earlier choice earned close it.
    final speaker = speakerLabelFor(node.speaker, french: french);
    final parts = composeNarrationParts(node, session, story,
        french: french, revisit: isRevisit(ref.watch(storyPlayProvider)));
    // A scene in pages shows the page being read (v1.750): what led here
    // opens its first page, the echoes close its last.
    final page = scenePageOf(
        ref.watch(scenePageProvider),
        scenePageKey(ref.watch(storyPlayProvider), node.id),
        parts.pages.length);
    final firstPage = page == 0;
    final lastPage = page >= parts.pages.length - 1;
    final text = parts.pages.length > 1 ? parts.pages[page] : parts.text;
    final allPreludes = ref.watch(pendingPreludeProvider);
    final preludes = firstPage ? allPreludes : const <ScenePrelude>[];
    if (!folded && lastPage) {
      noteShownEchoes(ref, session, [
        for (final prelude in preludes) ...prelude.echoes,
        ...parts.echoes,
      ]);
    }
    final prose = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: InkFonts.prose,
      fontSize: reading ? 17 : 15,
      height: reading ? 1.55 : 1.45,
    );
    final aside = prose?.copyWith(
      fontStyle: FontStyle.italic,
      color: ink.ash,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A step taken inside this place: what was taken, and that nothing
        // moved (the scene-or-map rule, v1.809).
        if (firstPage && taken != null) ...[
          Text(
            '\u203a ${taken.choice.textFor(french)}',
            key: const ValueKey('journey_taken_line'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: InkFonts.prose,
              fontStyle: FontStyle.italic,
              color: ink.gold,
            ),
          ),
          Text(
            tr(ref, 'journey_still_in').replaceAll(
                '{place}',
                ref
                        .watch(geographyProvider)
                        .places[taken.placeId]
                        ?.nameFor(french) ??
                    ''),
            key: const ValueKey('journey_still_line'),
            style: theme.textTheme.labelSmall?.copyWith(color: ink.ash),
          ),
          const SizedBox(height: 10),
        ],
        if (firstPage && detour != null && detour!.isNotEmpty) ...[
          Text(detour!, style: prose),
          const SizedBox(height: 12),
        ],
        if (firstPage && aftermath != null && aftermath.isNotEmpty) ...[
          Text(aftermath, style: prose),
          const SizedBox(height: 12),
        ],
        if (firstPage && roadNote != null && roadNote.isNotEmpty) ...[
          Text(roadNote, style: prose),
          const SizedBox(height: 12),
        ],
        if (firstPage && outcome != null && outcome.isNotEmpty) ...[
          Text(outcome, style: prose),
          const SizedBox(height: 12),
        ],
        for (final prelude in preludes) ...[
          if (prelude.speaker != null) ...[
            Text(
              prelude.speaker!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: InkFonts.system,
                letterSpacing: 1.2,
                color: ink.gold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(prelude.body, style: prose),
          for (final echo in prelude.echoes) ...[
            const SizedBox(height: 10),
            EchoLine(
              key: ValueKey('journey_prelude_echo_${echo.key}'),
              echo: echo,
              caption:
                  tr(ref, 'echo_because').replaceAll('{choice}', echo.cause),
              colour: ink.gold,
              style: prose ?? const TextStyle(),
            ),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('⁂', style: aside),
            ),
          ),
        ],
        if (speaker != null) ...[
          Text(
            speaker.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: InkFonts.system,
              letterSpacing: 1.2,
              color: ink.gold,
            ),
          ),
          const SizedBox(height: 4),
        ],
        // A new scene's words come out of the ink, top to bottom.
        StoryText(
          key: ValueKey(text),
          text: text,
          style: prose ?? const TextStyle(),
          revealKey: revealKey,
        ),
        if (lastPage)
          for (final echo in parts.echoes) ...[
            const SizedBox(height: 10),
            EchoLine(
              key: ValueKey('journey_echo_${echo.key}'),
              echo: echo,
              caption:
                  tr(ref, 'echo_because').replaceAll('{choice}', echo.cause),
              colour: ink.gold,
              style: prose ?? const TextStyle(),
            ),
          ],
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          if (folded)
            GestureDetector(
              key: const ValueKey('journey_scene_text'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onFold(false),
              onDoubleTap: () => onReading(true),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 80, 12),
                child: Text(
                  [
                    if (detour != null && detour!.isNotEmpty) detour!,
                    for (final prelude in preludes) prelude.text,
                    text,
                  ].map(stripStoryMarkup).join(' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: prose,
                ),
              ),
            )
          else
            LayoutBuilder(
              // Captured above the scroll view, which gives its child an
              // unbounded height: short scenes are centred in the full
              // screen when read that way.
              builder: (context, viewport) => GestureDetector(
                key: const ValueKey('journey_scene_text'),
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => onReading(!reading),
                child: Scrollbar(
                  child: shrinkToText && !reading
                      ? ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(14, 12, 40, 36),
                          children: [body],
                        )
                      : SingleChildScrollView(
                          padding: reading
                              ? const EdgeInsets.fromLTRB(22, 20, 44, 20)
                              : const EdgeInsets.fromLTRB(14, 12, 40, 36),
                          child: reading
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight:
                                          math.max(0, viewport.maxHeight - 40)),
                                  child: Align(
                                      alignment: Alignment.topLeft,
                                      child: body),
                                )
                              : body,
                        ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reading && (toMap || locked))
                  IconButton(
                    key: const ValueKey('journey_reading_exit'),
                    icon: const Icon(Icons.map_outlined, size: IconSize.s16),
                    // A locked page's map waits (v1.553): greyed.
                    tooltip: tr(
                        ref,
                        locked
                            ? 'journey_choose_first'
                            : 'journey_reading_exit'),
                    visualDensity: VisualDensity.compact,
                    onPressed: locked ? null : () => onReading(false),
                  )
                else ...[
                  if (folded)
                    IconButton(
                      key: const ValueKey('journey_scene_unfold'),
                      icon: const Icon(Icons.expand_more, size: IconSize.s16),
                      tooltip: tr(ref, 'hub_story_unfold'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onFold(false),
                    ),
                ],
              ],
            ),
          ),
          if (!folded && !reading)
            Positioned(
              bottom: 2,
              right: 2,
              child: IconButton(
                key: const ValueKey('journey_scene_fold'),
                icon: const Icon(Icons.expand_less, size: IconSize.s16),
                tooltip: tr(ref, 'hub_story_fold'),
                visualDensity: VisualDensity.compact,
                onPressed: () => onFold(true),
              ),
            ),
        ],
      ),
    );
  }
}

/// No way on from here on the map: the Story tab has the ending, New
/// Game+ and the way back to the beginning.
/// A small button over a map, in the chart's colours.
class _MapButton extends StatelessWidget {
  const _MapButton({
    super.key,
    required this.icon,
    required this.tip,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String tip;
  final ChartPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: Material(
        color: palette.land.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: palette.coast, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: IconSize.s16, color: palette.place),
          ),
        ),
      ),
    );
  }
}

class _LookedAtPanel extends ConsumerWidget {
  const _LookedAtPanel({required this.landmark, required this.language});

  final Landmark? landmark;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final landmark = this.landmark;
    if (landmark == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          tr(ref, 'journey_level_hint'),
          key: const ValueKey('journey_level_hint'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
      );
    }
    return Container(
      key: ValueKey('journey_looked_${landmark.id}'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(landmark.name(language),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 4),
            Text(
              landmark.blurb(language),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontFamily: InkFonts.prose, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndedPanel extends ConsumerWidget {
  const _EndedPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const ValueKey('journey_open_story'),
              onPressed: () => openStoryReader(context, ref),
              icon: const Icon(Icons.menu_book),
              label: Text(tr(ref, 'journey_open_story')),
            ),
          ],
        ),
      ),
    );
  }
}
