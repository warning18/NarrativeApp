// The road the party is carried along and the party mark that walks it. Cut
// out of journey_screen.dart with no change.
part of '../journey_screen.dart';

/// A road the party is carried along (v1.245): from where it stood to the
/// place the story set it down, with a few words on why.
class _Transit {
  const _Transit({
    required this.from,
    required this.to,
    required this.fromName,
    required this.toName,
    required this.flight,
    required this.forced,
    required this.caption,
    this.path,
  })  : icon = null,
        atTop = false;

  /// Only [text] told over the map, no road: a walk inside a town, a door
  /// gone through (v1.537).
  _Transit.words(String text, {this.icon})
      : from = Offset.zero,
        to = Offset.zero,
        fromName = '',
        toName = '',
        flight = false,
        forced = false,
        caption = text,
        path = null,
        atTop = true;

  /// The icon beside the words (a walking figure when null).
  final IconData? icon;

  /// Whether the words sit at the top of the map: the map's own buttons are
  /// at its foot, and a short word must not cover them.
  final bool atTop;

  /// The two places on the region's chart.
  final Offset from;
  final Offset to;
  final String fromName;
  final String toName;

  /// Whether the places differ, so there is a road to draw; else only the
  /// words are told.
  final bool flight;

  /// Whether the story took the party there against its pick (a lost fight,
  /// a failed roll), not a journey the player started.
  final bool forced;
  final String caption;

  /// The road (or sea lane) from one place to the other over the world
  /// chart, with the stops it passes (wave 14), when the world's roads lead
  /// there; without one only the caption is told.
  final WorldLegPath? path;

  /// How long the move takes: slow, and longer for a longer road.
  Duration get duration {
    final path = this.path;
    return flight && path != null
        ? worldMoveDuration(path)
        : const Duration(milliseconds: 2000);
  }
}

/// The [_Transit] over the map: the world chart with the party walking the
/// road, and the caption under it. A tap skips it; with reduced motion only
/// the caption shows, a few seconds.
class _PartyTransit extends StatefulWidget {
  const _PartyTransit({
    super.key,
    required this.transit,
    required this.mapBuilder,
    required this.passText,
    required this.onDone,
  });

  final _Transit transit;

  /// The world chart with the move on it, on the move's clock.
  final Widget Function(WorldLegPath path, Animation<double> clock) mapBuilder;

  /// "You pass {stop}.", the words said of the stop the party has reached.
  final String passText;
  final VoidCallback onDone;

  @override
  State<_PartyTransit> createState() => _PartyTransitState();
}

class _PartyTransitState extends State<_PartyTransit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.transit.duration,
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transit = widget.transit;
    final still = MediaQuery.of(context).disableAnimations;
    final scheme = Theme.of(context).colorScheme;
    void skip() {
      _c.stop();
      widget.onDone();
    }

    final path = transit.path;
    final road = transit.flight && !still && path != null;
    return ClipRRect(
      key: const ValueKey('journey_transit'),
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The party's move over the world chart takes a tap to skip; a few
          // words alone (the party moved inside its place) leave the map to
          // be played with, and the map shows the move.
          if (road) ...[
            widget.mapBuilder(path, _c),
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('journey_transit_skip'),
                behavior: HitTestBehavior.opaque,
                onTap: skip,
              ),
            ),
          ],
          Align(
            alignment:
                transit.atTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: GestureDetector(
              onTap: skip,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: scheme.surface.withValues(alpha: 0.94),
                  elevation: 3,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          transit.forced
                              ? Icons.warning_amber_rounded
                              : transit.icon ?? Icons.directions_walk,
                          size: IconSize.s16,
                          color: transit.forced
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transit.caption,
                                key: const ValueKey('journey_transit_caption'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              // The stop the party has just passed on the
                              // way there (v1.254).
                              if (road)
                                AnimatedBuilder(
                                  animation: _c,
                                  builder: (context, _) {
                                    final walked =
                                        RegionFlightPainter.walkAt(_c.value);
                                    ChartRouteStop? stop;
                                    for (final s in path.stops) {
                                      if (s.along <= walked) stop = s;
                                    }
                                    if (stop == null) return const SizedBox();
                                    return Text(
                                      widget.passText
                                          .replaceAll('{stop}', stop.name),
                                      key: const ValueKey(
                                          'journey_transit_stop'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: scheme.onSurfaceVariant),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
