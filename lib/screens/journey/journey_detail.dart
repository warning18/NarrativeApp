// The step picked under the map, and the story reader. Cut out of
// journey_screen.dart with no change.
part of '../journey_screen.dart';

/// Under the map: the step picked, what it holds and costs, and Go.
/// Nothing picked yet says how to pick.
class _StepDetail extends ConsumerWidget {
  const _StepDetail({
    required this.step,
    required this.busy,
    required this.french,
    required this.isExcursion,
    required this.onGo,
  });

  final _Step? step;
  final bool busy;
  final bool french;
  final bool isExcursion;
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final step = this.step;
    if (step == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          tr(ref, 'journey_pick_hint'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
      );
    }
    final choice = step.choice;
    String signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
    final enemies = choice.triggersCombat
        ? ref.watch(localizedDbProvider(enemiesSchema)).value
        : null;
    final ids = choice.allTriggerEnemyIds;
    final roster = isExcursion ||
            enemies == null ||
            ids.isEmpty ||
            ids.any((id) => id.startsWith('@'))
        ? null
        : enemyRoster(ids, enemies);
    final colour = step.locked
        ? ink.ash
        : _colorFor(step.kind, ink, ChartPalette.of(ref.watch(mapLookProvider)),
            greyed: false);
    final tags = [
      if (choice.hasAbilityCheck)
        InkChip(
            '${tr(ref, '${choice.checkAbility}_label')} '
            'DC ${choice.checkDC ?? 10}',
            color: ink.tide),
      if (choice.goldMod != 0)
        InkChip('${signed(choice.goldMod)} ${tr(ref, 'gold_label')}',
            color: ink.gold),
      if (choice.healAmount != 0)
        InkChip('${signed(choice.healAmount)} ${tr(ref, 'hp_label')}',
            color: choice.healAmount > 0 ? ink.heal : ink.blood),
      if (choice.alignmentMod != 0)
        InkChip('${tr(ref, 'alignment_label')} ${signed(choice.alignmentMod)}',
            color: ink.voidColor),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              // Capped under the map on a short phone (see
              // _JourneyViewState._mapMin): the words scroll, Go stays.
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(ref, _kindKey(step.kind)).toUpperCase(),
                      style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: colour,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: InkFonts.prose,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    if (step.tag case final tag?)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 1),
                        child: ChoiceTagChip(
                            key: const ValueKey('journey_detail_tag'),
                            tag: tag,
                            locked: step.locked),
                      ),
                    if (roster != null && !step.locked)
                      Text(
                        tr(ref, 'choice_fight_roster')
                            .replaceAll('{roster}', roster),
                        style: theme.textTheme.labelSmall,
                      ),
                    if (step.leadsTo != null)
                      Text(
                        tr(ref, 'journey_leads_to')
                            .replaceAll('{place}', step.leadsTo!),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash),
                      ),
                    // The road it takes, by the stops it passes (v1.256).
                    if (step.route != null && step.route!.stops.isNotEmpty)
                      Text(
                        tr(ref, 'journey_by_road').replaceAll('{stops}',
                            step.route!.stops.map((s) => s.name).join(' · ')),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash),
                      ),
                    if (step.event != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(_eventIcon(step.event!, hazard: step.hazard),
                                size: IconSize.s16,
                                color: _eventColour(step.event!, ink)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tr(ref, 'journey_event_${step.event!.name}')
                                    .replaceAll('{hazard}',
                                        step.hazard?.nameFor(french) ?? ''),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: _eventColour(step.event!, ink)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: step.locked ? 0.45 : 1,
                        child: Wrap(spacing: 6, runSpacing: 4, children: tags),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              key: const ValueKey('journey_go'),
              onPressed: step.locked || busy ? null : onGo,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr(ref, 'journey_go')),
            ),
          ],
        ),
      ),
    );
  }
}

/// The story reader, for what the map has no way on to (the ending, New
/// Game+, the way back to the beginning): the Story tab in Edit Mode,
/// pushed over the game in play (v1.201: the game has no Story tab).
void openStoryReader(BuildContext context, WidgetRef ref) {
  if (ref.read(appModeProvider) == AppMode.edit) {
    ref.read(homeTabIndexProvider.notifier).state = 0;
    return;
  }
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'title_story'))),
      body: const StoryPlayerScreen(),
    ),
  ));
}
