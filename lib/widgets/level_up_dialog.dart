import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'moments.dart';
import 'level_up_stats.dart';
import 'offer_dialog.dart';
import 'pixel_vfx.dart';

/// Shown right after a fight that leveled the character up. Lets the player
/// spend their new stat point(s) immediately, right in the modal, or close
/// it and distribute them later from the Level Up screen — either way the
/// points aren't lost. Each level brings an offer from the clans (see
/// offers.dart): it follows once this closes.
Future<void> showLevelUpDialog(BuildContext context, WidgetRef ref,
    {required int newLevel}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _LevelUpDialog(newLevel: newLevel),
  );
  if (context.mounted) await showOfferIfWaiting(context, ref);
}

class _LevelUpDialog extends ConsumerWidget {
  const _LevelUpDialog({required this.newLevel});

  final int newLevel;

  /// The medal over turning rays and a pixel flourish, once.
  Widget _medal(InkColors ink) => SizedBox(
        width: 120,
        height: 96,
        child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: RayBurst(colour: ink.gold)),
              const Positioned(
                left: -12,
                top: -24,
                width: 144,
                height: 144,
                child: PixelMoment(
                  key: Key('level_up_burst'),
                  palette: PixelMoment.gold,
                  duration: Duration(milliseconds: 1500),
                  layers: [
                    PixelMomentLayer('vfx_crit', span: 0.55),
                    PixelMomentLayer('vfx_shout', t0: 0.15, span: 0.6),
                    PixelMomentLayer('vfx_heal', t0: 0.3, span: 0.7),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(ink.gold, Colors.white, 0.35)!,
                      ink.gold
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: ink.gold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.military_tech,
                    size: 30, color: Color(0xFF14110A)),
              ),
            ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final hasPoints = session.statPoints > 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The level, and the points to spend: fixed, so they stay in view
          // while the stats scroll.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                _medal(ink),
                const SizedBox(height: 8),
                RiseIn(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    '${tr(ref, 'level_up')}! ${tr(ref, 'level_field_label')} $newLevel',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: InkFonts.display, color: ink.gold),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  key: const Key('level_up_points'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ink.seam),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_outline,
                          size: 20, color: hasPoints ? ink.gold : ink.ash),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tr(ref, 'stat_points_available')}: ${session.statPoints}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: hasPoints ? ink.gold : null),
                        ),
                      ),
                    ],
                  ),
                ),
                // The clans come once this closes (see offers.dart).
                if (session.pendingOffers.isNotEmpty)
                  FlipIn(
                    flipKey: 'offers',
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.diversity_3,
                              size: 18, color: ink.voidColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr(ref, 'level_up_offer_note'),
                              key: const Key('level_up_offer_note'),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: ink.ash),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  tr(ref, 'hold_stat_for_details_hint'),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: LevelUpStats(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('level_up_close'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(tr(ref,
                    hasPoints ? 'distribute_later_button' : 'close_button')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
