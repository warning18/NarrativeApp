// A clan's details on a long press (Wave 8): hold a clan's banner (in the
// offer's banner row, on the ring's crests, on the Throne room's standards)
// and its card opens over the screen: where it leans, what it stands for,
// its sub-clans, a short recap of its story. It stays open when the finger
// lifts (v1.555); a tap outside it, its close button or the back gesture
// closes it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'clan_power_block.dart';
import 'clan_radar_chart.dart';
import 'clan_glance.dart' show ClanMarks;
import 'pixel_banner.dart';

/// Wraps [child] so a long press opens the details of [factionId] (see
/// [showClanDetails]); they stay open until closed. With no clan (the
/// Wayfarer's flag, a piece of the Shroud) it is just [child].
class ClanPeek extends StatelessWidget {
  const ClanPeek({super.key, required this.factionId, required this.child});

  final String? factionId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final id = factionId;
    if (id == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => showClanDetails(context, factionId: id),
      child: child,
    );
  }
}

/// What the long press shows: the banner and name with where the party
/// stands, the motto, what the clan stands for, the way it leans (alignment
/// and the five axes of its gifts), its sub-clans, and its story.
class ClanDetailsCard extends ConsumerWidget {
  const ClanDetailsCard(
      {super.key, required this.factionId, this.greeting = '', this.onClose});

  final String factionId;

  /// Closes the card: its close button shows when this is given.
  final VoidCallback? onClose;

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
      child: Stack(children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(14, 14, onClose == null ? 14 : 38, 14),
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
                      child: FittedBox(
                          child: ClanMarks(
                              factionId: factionId,
                              discSize: 30,
                              plate: true,
                              child: PixelBanner(id: bannerId, scale: 1))),
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
              ClanPowerBlock(factionId: factionId, color: color),
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
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
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
                                  color: leanColor,
                                  fontWeight: FontWeight.w700)),
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
            ],
          ),
        ),
        if (onClose != null)
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              key: const Key('clan_details_close'),
              icon: const Icon(Icons.close, size: 20),
              tooltip: tr(ref, 'close_button'),
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
            ),
          ),
      ]),
    );
  }
}

/// The card as a dialog (a long press, and the offer's (i)): it stays open
/// until a tap outside it, its close button or the back gesture closes it;
/// [greeting] is what the clan says to the party, when given.
Future<void> showClanDetails(BuildContext context,
        {required String factionId, String greeting = ''}) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ClanDetailsCard(
              factionId: factionId,
              greeting: greeting,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ),
      ),
    );
