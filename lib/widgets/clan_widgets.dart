import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../data/shop_pricing.dart' show shopFactionId;
import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/signs_provider.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'sign_widgets.dart';

/// The colour of a foe's square, and of the Hunted end of a meter.
const Color clanFoeColor = Color(0xFFD9544D);

/// [tier]'s colour (see tierColor), the same on every screen.
Color standingTierColor(StandingTier tier) => Color(tierColor(tier));

/// [color] for words on [context]'s background: as it is on a dark one,
/// deepened on a light one, where gold and teal would wash out.
Color readableOn(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.dark
        ? color
        : Color.lerp(color, Colors.black, 0.38)!;

/// [tier]'s colour for words (see [readableOn]).
Color standingTierTextColor(BuildContext context, StandingTier tier) =>
    readableOn(context, standingTierColor(tier));

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
          color: standingTierTextColor(context, tier),
          fontWeight: FontWeight.w700),
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
                                color: standingTierTextColor(
                                    context, StandingTier.sworn)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            _FactionShops(factionId: faction.id),
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

/// The shops a faction runs (shops.json `faction`, v1.197): their signs and
/// names in a line, so the standing's price reads as somewhere to go.
class _FactionShops extends ConsumerWidget {
  const _FactionShops({required this.factionId});

  final String factionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(localizedDbProvider(shopsSchema)).value ?? const {};
    final theme = Theme.of(context);
    final own = [
      for (final e in shops.entries)
        if (e.value is Map<String, dynamic> &&
            shopFactionId(e.value as Map<String, dynamic>) == factionId)
          e,
    ];
    if (own.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: Key('faction_shops_$factionId'),
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(tr(ref, 'clans_shops_label'),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          for (final e in own)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShopPixelIcon(e.key, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    (e.value as Map<String, dynamic>)['shopName']?.toString() ??
                        e.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A lost clan's emblem (v1.195, the Open Hand): its own until the
/// remembrance reaches [ownHandNameStage], a dark silhouette before.
class LostClanEmblem extends StatelessWidget {
  const LostClanEmblem({
    super.key,
    required this.faction,
    required this.stage,
    this.size = 30,
  });

  final Faction faction;
  final int stage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emblem = PatronEmblem(patron: faction.patron, size: size);
    if (stage >= ownHandNameStage) return emblem;
    return ColorFiltered(
      key: Key('lost_clan_silhouette_${faction.id}'),
      colorFilter: const ColorFilter.mode(Color(0xFF2B2A28), BlendMode.srcIn),
      child: emblem,
    );
  }
}

/// The remembrance stage from which the Open Hand is called by its name:
/// the name heard at the harbour.
const int ownHandNameStage = 2;

/// A lost clan's name as the remembrance allows: "A clan with no name"
/// before [ownHandNameStage], its own after.
String lostClanNameFor(Faction faction, int stage, AppLanguage language) =>
    stage >= ownHandNameStage
        ? faction.nameFor(language)
        : trFor(language, 'open_hand_unknown_name');

/// "Remembrance 3/6", or "Not remembered yet".
String remembranceLabel(int stage, AppLanguage language) => stage <= 0
    ? trFor(language, 'open_hand_stage_none')
    : trFor(language, 'open_hand_stage')
        .replaceAll('{n}', '$stage')
        .replaceAll('{max}', '$openHandStages');

/// A lost clan (the Open Hand) where the others show a standing: no meter,
/// its remembrance stage, and whether the banner is raised. [editable]
/// (Edit Mode) adds a stage to set (its flags `open_hand_1..n`) and the
/// banner's switch.
class LostClanCard extends ConsumerWidget {
  const LostClanCard({super.key, required this.faction, this.editable = false});

  final Faction faction;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final stage = openHandStageFrom(flags);
    final raised = bannerRaisedIn(flags);
    final notifier = ref.read(playerSessionProvider.notifier);
    final gold = standingTierTextColor(context, StandingTier.sworn);
    return Card(
      key: Key('lost_clan_card_${faction.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                LostClanEmblem(faction: faction, stage: stage),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(lostClanNameFor(faction, stage, lang),
                      style: theme.textTheme.titleSmall),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    remembranceLabel(stage, lang),
                    key: Key('lost_clan_stage_${faction.id}'),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: stage > 0
                            ? gold
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (raised)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(trFor(lang, 'open_hand_banner_raised'),
                    style: theme.textTheme.labelSmall?.copyWith(color: gold)),
              ),
            if (editable) ...[
              const SizedBox(height: 4),
              Text(trFor(lang, 'open_hand_edit_hint'),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var n = 0; n <= openHandStages; n++)
                    ChoiceChip(
                      key: Key('open_hand_stage_$n'),
                      label: Text('$n'),
                      selected: stage == n,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => notifier.setOpenHandStage(n,
                          data: ref.read(clanDataProvider)),
                    ),
                ],
              ),
              SwitchListTile(
                key: const Key('open_hand_banner_switch'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(trFor(lang, 'open_hand_banner_raised')),
                subtitle: const Text(bannerRaisedFlag),
                value: raised,
                onChanged: (on) => notifier.setStoryFlag(bannerRaisedFlag, on,
                    data: ref.read(clanDataProvider)),
              ),
            ],
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
        // The dead clan, once remembered (v1.195): its stage, no meter.
        if (openHandStageFrom(flags) > 0)
          for (final faction in data.lost) LostClanCard(faction: faction),
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
        if (data.faction(id) case final faction?)
          if (!faction.isLost) faction,
    ]..sort((a, b) => a.kind.index != b.kind.index
        ? a.kind.index.compareTo(b.kind.index)
        : a.nameFor(lang).compareTo(b.nameFor(lang)));
    // The dead clan (v1.195): known from its first remembrance, a
    // silhouette until its name is heard.
    final stage = openHandStageFrom(session.flags);
    final lost = [
      for (final faction in data.lost)
        if (stage >= 1 || session.patronsMet.contains(faction.id)) faction,
    ];
    if (met.isEmpty && lost.isEmpty) {
      return Text(tr(ref, 'patrons_none_met'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final faction in lost)
          Padding(
            key: Key('patron_codex_${faction.id}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LostClanEmblem(faction: faction, stage: stage, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lostClanNameFor(faction, stage, lang),
                          key: Key('codex_lost_name_${faction.id}'),
                          style: theme.textTheme.titleSmall),
                      Text(
                        '${tr(ref, 'patron_kind_lost')} · '
                        '${remembranceLabel(stage, lang)}'
                        '${bannerRaisedIn(session.flags) ? ' · ${tr(ref, 'open_hand_banner_raised')}' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: standingTierTextColor(
                                context, StandingTier.sworn)),
                      ),
                      Text(
                        stage >= ownHandNameStage &&
                                faction.mottoFor(lang).isNotEmpty
                            ? faction.mottoFor(lang)
                            : tr(ref, 'open_hand_unknown_line'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
