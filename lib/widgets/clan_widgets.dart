import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../data/signs.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/signs_provider.dart';
import 'sign_widgets.dart';

/// The colour of a foe's square, and of the Hunted end of a meter.
const Color clanFoeColor = Color(0xFFD9544D);

/// [tier]'s colour (see tierColor), the same on every screen.
Color standingTierColor(StandingTier tier) => Color(tierColor(tier));

/// A standing from -100 to +100 as a thin bar: dark red at the bottom,
/// a dark neutral middle, green then gold at the top, and a tick where
/// [value] stands.
class StandingMeter extends StatelessWidget {
  const StandingMeter({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height + 6,
        child: CustomPaint(
          painter: _StandingMeterPainter(
            value: value,
            barHeight: height,
            tick: Theme.of(context).colorScheme.onSurface,
          ),
          size: Size.infinite,
        ),
      );
}

class _StandingMeterPainter extends CustomPainter {
  _StandingMeterPainter({
    required this.value,
    required this.barHeight,
    required this.tick,
  });

  final double value;
  final double barHeight;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - barHeight) / 2;
    final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, size.width, barHeight),
        Radius.circular(barHeight / 2));
    canvas.drawRRect(
      bar,
      Paint()
        ..shader = const LinearGradient(colors: [
          Color(0xFF8A1A1A),
          Color(0xFF4A4740),
          Color(0xFF7DBE6A),
          Color(0xFFF2C14E),
        ], stops: [
          0,
          0.5,
          0.8,
          1,
        ]).createShader(bar.outerRect),
    );
    final x = ((value.clamp(minStanding, maxStanding) - minStanding) /
            (maxStanding - minStanding)) *
        size.width;
    canvas.drawRect(
      Rect.fromLTWH((x - 1.5).clamp(0, size.width - 3), 0, 3, size.height),
      Paint()..color = tick,
    );
  }

  @override
  bool shouldRepaint(_StandingMeterPainter old) =>
      old.value != value || old.tick != tick || old.barHeight != barHeight;
}

/// One small square per sub-clan: filled in its colour for a friend, red
/// for a foe, a faded outline for none. With [onTap] (Edit Mode) a tap
/// cycles the mark.
class SubclanSquares extends StatelessWidget {
  const SubclanSquares({
    super.key,
    required this.subclans,
    required this.politics,
    required this.language,
    this.onTap,
    this.size = 14,
  });

  final List<SubClan> subclans;
  final PoliticsState politics;
  final AppLanguage language;
  final void Function(SubClan subclan)? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final s in subclans)
          Builder(builder: (context) {
            final mark = politics.markOf(s.id);
            final color = Color(s.color);
            final square = Container(
              key: Key('subclan_square_${s.id}'),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: switch (mark) {
                  SubclanMark.friend => color,
                  SubclanMark.foe => clanFoeColor,
                  SubclanMark.none => null,
                },
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: switch (mark) {
                    SubclanMark.friend => color,
                    SubclanMark.foe => clanFoeColor,
                    SubclanMark.none => outline.withValues(alpha: 0.6),
                  },
                ),
              ),
              child: mark == SubclanMark.foe
                  ? Icon(Icons.close, size: size - 4, color: Colors.white)
                  : null,
            );
            final tip = '${s.nameFor(language)} · '
                '${trFor(language, subclanMarkKey(mark))}';
            return Tooltip(
              message: tip,
              child: onTap == null
                  ? square
                  : InkWell(
                      onTap: () => onTap!(s),
                      child: Padding(
                        // A finger-sized target around a small square.
                        padding: const EdgeInsets.all(4),
                        child: square,
                      ),
                    ),
            );
          }),
      ],
    );
  }
}

/// A faction's tier word and standing, in the tier's colour: "KNOWN +22".
class StandingTierLabel extends StatelessWidget {
  const StandingTierLabel({
    super.key,
    required this.value,
    required this.language,
  });

  final double value;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final tier = standingTierFor(value);
    return Text(
      '${trFor(language, standingTierKey(tier)).toUpperCase()} '
      '${formatStanding(value)}',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: standingTierColor(tier), fontWeight: FontWeight.w700),
    );
  }
}

/// One faction's standing, as the design's phone mockup draws it: the
/// banner (its icon on its colour), its name, the tier and value in the
/// tier's colour, the meter, a square per sub-clan and the Sworn mark.
/// [editable] (Edit Mode) adds a slider that sets the standing (no
/// ripple) and lets a tap on a square cycle its mark.
class FactionStandingCard extends ConsumerWidget {
  const FactionStandingCard({
    super.key,
    required this.faction,
    this.editable = false,
  });

  final Faction faction;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(politicsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final value = politics.standingOf(faction.id, data);
    final subclans = data.subclansOf(faction.id);
    final sworn = politics.isSworn(faction.id);
    final notifier = ref.read(playerSessionProvider.notifier);
    int chapter() => ref.read(reachedChapterProvider);

    return Card(
      key: Key('faction_card_${faction.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: sworn
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: standingTierColor(StandingTier.sworn), width: 1.5))
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PatronEmblem(patron: faction.patron, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(faction.nameFor(lang),
                      style: theme.textTheme.titleSmall),
                ),
                const SizedBox(width: 6),
                StandingTierLabel(value: value, language: lang),
              ],
            ),
            const SizedBox(height: 4),
            StandingMeter(value: value),
            if (subclans.isNotEmpty || sworn) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SubclanSquares(
                      subclans: subclans,
                      politics: politics,
                      language: lang,
                      onTap: editable
                          ? (s) => notifier.setSubclanMark(
                              s.id, nextSubclanMark(politics.markOf(s.id)),
                              data: data, cause: 'edit', chapter: chapter())
                          : null,
                    ),
                  ),
                  if (sworn)
                    Tooltip(
                      message: trFor(lang, 'clans_sworn_marker'),
                      child: Row(
                        key: Key('faction_sworn_${faction.id}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.military_tech,
                              size: 18,
                              color: standingTierColor(StandingTier.sworn)),
                          Text(
                            faction.sworn?.nameFor(lang) ??
                                trFor(lang, 'standing_tier_sworn'),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: standingTierColor(StandingTier.sworn)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (editable)
              _StandingSlider(
                key: Key('faction_slider_${faction.id}'),
                value: value,
                onSet: (v) => notifier.setStandingForEdit(faction.id, v,
                    data: data, chapter: chapter()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Edit Mode's slider: drags freely, sets the standing once let go (one
/// log entry, not one a pixel).
class _StandingSlider extends StatefulWidget {
  const _StandingSlider({super.key, required this.value, required this.onSet});

  final double value;
  final ValueChanged<int> onSet;

  @override
  State<_StandingSlider> createState() => _StandingSliderState();
}

class _StandingSliderState extends State<_StandingSlider> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final shown = _dragging ?? widget.value.roundToDouble();
    return SizedBox(
      height: 32,
      child: Slider(
        min: minStanding.toDouble(),
        max: maxStanding.toDouble(),
        divisions: maxStanding - minStanding,
        value: shown.clamp(minStanding.toDouble(), maxStanding.toDouble()),
        label: formatStanding(shown),
        onChanged: (v) => setState(() => _dragging = v),
        onChangeEnd: (v) {
          setState(() => _dragging = null);
          widget.onSet(v.round());
        },
      ),
    );
  }
}

/// The Character tab's Clans: a card per clan (and per tribe the story
/// has opened), without Edit Mode's controls.
class ClansSection extends ConsumerWidget {
  const ClansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
    final theme = Theme.of(context);
    final shown = [
      ...data.clans,
      for (final tribe in data.tribes)
        if (tribe.unlockFlag.isEmpty || flags.contains(tribe.unlockFlag)) tribe,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr(ref, 'clans_section'), style: theme.textTheme.titleSmall),
        Text(tr(ref, 'clans_section_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        if (shown.isEmpty)
          Text(tr(ref, 'clans_none'), style: theme.textTheme.bodySmall),
        for (final faction in shown) FactionStandingCard(faction: faction),
      ],
    );
  }
}

/// The codex's Clans (it was the Patrons' until v1.193): every faction
/// that has offered a sign (see PlayerSession.patronsMet), with its
/// motto, the standing with it, the favour of the signs taken, and
/// whether this life has closed it off (the Choir or the Pit).
class ClansCodex extends ConsumerWidget {
  const ClansCodex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final data = ref.watch(clanDataProvider);
    final patrons = ref.watch(patronsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final met = [
      for (final id in session.patronsMet)
        if (data.faction(id) != null) data.faction(id)!,
    ]..sort((a, b) => a.kind.index != b.kind.index
        ? a.kind.index.compareTo(b.kind.index)
        : a.nameFor(lang).compareTo(b.nameFor(lang)));
    if (met.isEmpty) {
      return Text(tr(ref, 'patrons_none_met'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final faction in met)
          Padding(
            key: Key('patron_codex_${faction.id}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatronEmblem(patron: faction.patron, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faction.nameFor(lang),
                          style: theme.textTheme.titleSmall),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${tr(ref, 'patron_kind_${faction.kind.name}')} · '
                            '${tr(ref, 'patron_favour').replaceAll('{n}', '${session.patronFavour[faction.id] ?? 0}').replaceAll('{l}', '${favourLevelFor(session.patronFavour[faction.id] ?? 0)}')}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          StandingTierLabel(
                              value:
                                  session.politics.standingOf(faction.id, data),
                              language: lang),
                        ],
                      ),
                      if ((faction.mottoFor(lang).isNotEmpty
                              ? faction.mottoFor(lang)
                              : faction.introFor(lang))
                          .isNotEmpty)
                        Text(
                          faction.mottoFor(lang).isNotEmpty
                              ? faction.mottoFor(lang)
                              : faction.introFor(lang),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      if (closedThisLife(faction.patron,
                          patronsThisLife: session.signPatronsThisLife,
                          patrons: patrons))
                        Text(
                          tr(ref, 'patron_closed_life'),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
