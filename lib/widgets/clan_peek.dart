// A clan's details on a long press (Wave 8): hold a clan's banner (in the
// offer's banner row, on the ring's crests, on the Throne room's standards)
// and its card appears over the screen: where it leans, what it stands for,
// its sub-clans, a short recap of its story. Letting go, or a tap outside,
// closes it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'clan_radar_chart.dart';
import 'pixel_banner.dart';

/// Wraps [child] so a long press shows the details of [factionId] for as
/// long as it is held. With no clan (the Wayfarer's flag, a piece of the
/// Shroud) it is just [child].
class ClanPeek extends StatefulWidget {
  const ClanPeek({super.key, required this.factionId, required this.child});

  final String? factionId;
  final Widget child;

  @override
  State<ClanPeek> createState() => _ClanPeekState();
}

class _ClanPeekState extends State<ClanPeek> {
  OverlayEntry? _entry;

  void _show() {
    final id = widget.factionId;
    if (id == null || _entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry = OverlayEntry(
      builder: (_) => ClanPeekLayer(factionId: id, onClose: _hide),
    );
    overlay.insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.factionId == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (_) => _show(),
      onLongPressEnd: (_) => _hide(),
      onLongPressCancel: _hide,
      child: widget.child,
    );
  }
}

/// The dimmed screen and the card on it; a tap anywhere closes it.
class ClanPeekLayer extends StatelessWidget {
  const ClanPeekLayer(
      {super.key, required this.factionId, required this.onClose});

  final String factionId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const Key('clan_peek_barrier'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: GestureDetector(
                  onTap: onClose,
                  child: ClanDetailsCard(factionId: factionId),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What the long press shows: the banner and name with where the party
/// stands, the motto, what the clan stands for, the way it leans (alignment
/// and the five axes of its gifts), its sub-clans, and its story.
class ClanDetailsCard extends ConsumerWidget {
  const ClanDetailsCard(
      {super.key, required this.factionId, this.greeting = ''});

  final String factionId;

  /// What the clan says to the party (the offer's (i) adds it, the first
  /// time it is met); none on a long press.
  final String greeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final lang = ref.watch(appLanguageProvider);
    final politics = ref.watch(playerSessionProvider.select((s) => s.politics));
    final faction = data.faction(factionId);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    if (faction == null) return const SizedBox.shrink();
    final color = Color(faction.color | 0xFF000000);
    final bannerId = clanBannerId(factionId);
    final tier = faction.isLost ? null : politics.tierOf(factionId, data);
    final lean = faction.lean;
    final leanKey = lean > 0
        ? 'offer_align_good'
        : lean < 0
            ? 'offer_align_evil'
            : 'offer_align_none';
    final leanColor = lean > 0
        ? const Color(0xFF3E9B57)
        : lean < 0
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;
    final motto = faction.mottoFor(lang);
    final stands = faction.standsForIn(lang);
    final intro = faction.introFor(lang);
    final subs = [
      for (final s in data.subclansOf(factionId)) s.nameFor(lang),
    ];
    Widget heading(String key) => Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 3),
          child: Text(tr(ref, key).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: color, fontFamily: InkFonts.system, letterSpacing: 1)),
        );
    return Material(
      key: Key('clan_details_$factionId'),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.9), width: 1.5),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bannerId != null)
                  SizedBox(
                    width: 52,
                    height: 76,
                    child:
                        FittedBox(child: PixelBanner(id: bannerId, scale: 1)),
                  ),
                if (bannerId != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faction.nameFor(lang),
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: InkFonts.display, color: color)),
                      if (tier != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(trFor(lang, standingTierKey(tier)),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: Color(tierColor(tier) | 0xFF000000),
                                  fontWeight: FontWeight.w700)),
                        ),
                      if (motto.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('“$motto”',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            heading('clan_peek_orientation'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stands.isNotEmpty)
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: '${trFor(lang, 'offer_stands_for')} · ',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            TextSpan(
                                text: stands,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ]),
                          key: Key('clan_peek_stands_$factionId'),
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 6),
                      Container(
                        key: const Key('clan_peek_alignment'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: leanColor.withValues(alpha: 0.7)),
                          color: leanColor.withValues(alpha: 0.10),
                        ),
                        child: Text(
                            '${trFor(lang, 'alignment_label')} · ${trFor(lang, leanKey)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: leanColor, fontWeight: FontWeight.w700)),
                      ),
                      if (subs.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          key: const Key('clan_peek_subclans'),
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            for (final name in subs)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.6)),
                                  color: color.withValues(alpha: 0.12),
                                ),
                                child: Text(name,
                                    style: theme.textTheme.labelSmall),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                ClanRadarChart(factionId: factionId, color: color, size: 108),
              ],
            ),
            if (intro.isNotEmpty) ...[
              heading('clan_peek_backstory'),
              Text(intro,
                  key: Key('clan_peek_intro_$factionId'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (greeting.isNotEmpty) ...[
              heading('clan_peek_says'),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Text(greeting,
                    key: Key('clan_peek_greeting_$factionId'),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
            const SizedBox(height: 10),
            Center(
              child: Text(
                  tr(
                      ref,
                      greeting.isEmpty
                          ? 'clan_peek_release'
                          : 'clan_peek_tap_close'),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The same card from a button (the offer's (i)): a dialog a tap closes,
/// with what the clan says to the party when [greeting] is given.
Future<void> showClanDetails(BuildContext context,
        {required String factionId, String greeting = ''}) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(dialogContext).pop(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ClanDetailsCard(factionId: factionId, greeting: greeting),
            ),
          ),
        ),
      ),
    );
