// The Journey's list of ways, grouped by pin (v1.561): the district view's
// rows used to be one for every way, so a building holding several choices
// spread over several rows and the list stopped looking like the map. A pin
// that holds several ways is one row (the pin's own banner or disc, the name
// of the way that leads it, a count and a chevron), closed until tapped; a
// tap opens it in place to its ways, each the row it always was, indented.
// A pin with one way stays a plain row. Only one pin is open at a time.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// A way as the grouping reads it: its [index] among the steps, the [pin] it
/// hangs at on the map (a building, or a spot), and whether it [leads]: it
/// has a banner of its own (a way on, a main road) rather than a plain disc.
class WayPinEntry {
  const WayPinEntry(this.index, this.pin, {this.leads = false});

  final int index;
  final String pin;
  final bool leads;
}

/// The ways that hang at one pin, in the order the steps give them: the
/// [lead] names the pin (the first that leads, else the first).
class WayPinGroup {
  const WayPinGroup(this.pin, this.lead, this.members);

  final String pin;
  final int lead;
  final List<int> members;

  bool get isPin => members.length > 1;
}

/// [entries] grouped by pin, the pins in the order of their first way.
List<WayPinGroup> groupWaysByPin(List<WayPinEntry> entries) {
  final order = <String>[];
  final byPin = <String, List<WayPinEntry>>{};
  for (final e in entries) {
    (byPin[e.pin] ??= []).add(e);
    if (byPin[e.pin]!.length == 1) order.add(e.pin);
  }
  return [
    for (final pin in order)
      WayPinGroup(
        pin,
        (byPin[pin]!.where((e) => e.leads).firstOrNull ?? byPin[pin]!.first)
            .index,
        [for (final e in byPin[pin]!) e.index],
      ),
  ];
}

/// How many pins hold more than one way.
int pinsWithManyWays(List<WayPinGroup> groups) =>
    groups.where((g) => g.isPin).length;

/// The list: a plain row for a pin with one way, a closed row with a count
/// for one with several. [rowOf] builds a way's row ([indent] logical pixels
/// in when it is inside a pin); [leadOf] its pin's banner or disc; [titleOf]
/// the name a pin takes from its lead.
class WayPinList extends StatefulWidget {
  const WayPinList({
    super.key,
    required this.groups,
    required this.rowOf,
    required this.leadOf,
    required this.titleOf,
  });

  final List<WayPinGroup> groups;
  final Widget Function(int index, {double indent}) rowOf;
  final Widget Function(int lead) leadOf;
  final String Function(int lead) titleOf;

  @override
  State<WayPinList> createState() => _WayPinListState();
}

class _WayPinListState extends State<WayPinList> {
  /// The lead of the pin that is open, if any.
  int? _open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final still = MediaQuery.of(context).disableAnimations;
    final children = <Widget>[];
    for (final g in widget.groups) {
      if (!g.isPin) {
        children.add(widget.rowOf(g.lead));
        continue;
      }
      final open = _open == g.lead;
      children.add(AnimatedContainer(
        duration: still ? Duration.zero : const Duration(milliseconds: 160),
        color: open ? ink.gold.withValues(alpha: 0.07) : Colors.transparent,
        child: Column(children: [
          InkWell(
            key: ValueKey('journey_city_pin_${g.lead}'),
            onTap: () => setState(() => _open = open ? null : g.lead),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ink.seam))),
              child: Row(children: [
                SizedBox(
                    width: 30, child: Center(child: widget.leadOf(g.lead))),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.titleOf(g.lead),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.2)),
                ),
                const SizedBox(width: 8),
                Container(
                  key: ValueKey('journey_city_pin_count_${g.lead}'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ink.gold.withValues(alpha: 0.7)),
                  ),
                  child: Text('${g.members.length}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: ink.gold)),
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more,
                    size: 22, color: ink.ash),
              ]),
            ),
          ),
          if (open)
            for (final i in g.members) widget.rowOf(i, indent: 22),
        ]),
      ));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
