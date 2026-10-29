// The wards on the road (wave 16, road_wards.dart): a small mark on the
// Journey map for each clan whose hunters the Warding Cairn keeps off the
// trail, "Warded from the Lantern Dominion: 4 roads". It sits above the
// sky's chip and is gone when the ward runs out.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart';
import '../data/road_wards.dart' show wardLine;
import '../l10n/app_locale.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart' show roadWardsProvider;
import '../theme/stitched_ink.dart';

class WardMark extends ConsumerWidget {
  const WardMark({super.key, required this.palette, this.compact = false});

  final ChartPalette palette;

  /// Just the shield (a tap reads the line): for a narrow screen.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wards = ref.watch(roadWardsProvider);
    if (wards.isEmpty) return const SizedBox.shrink();
    final language = ref.watch(appLanguageProvider);
    final data = ref.watch(clanDataProvider);
    final ink = InkColors.of(context);
    final lines = [
      for (final w in wards)
        wardLine('ward_mark', language,
            clanId: w.clanId, data: data, n: w.roadsLeft),
    ];
    final line = lines.join('\n');
    if (compact) {
      return Semantics(
        container: true,
        label: line,
        child: Tooltip(
          message: line,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 6),
          child: DecoratedBox(
            key: const ValueKey('journey_ward_mark_compact'),
            decoration: BoxDecoration(
              color: palette.fog.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ink.heal.withValues(alpha: 0.7)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child:
                  Icon(Icons.shield_outlined, size: 16, color: palette.place),
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: line,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.fog.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: ink.heal.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 13, color: palette.place),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  line,
                  key: const ValueKey('journey_ward_mark'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 11,
                    color: palette.place,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
