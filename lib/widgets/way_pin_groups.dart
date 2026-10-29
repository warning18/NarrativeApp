// The Journey's ways grouped by the pin they hang at (v1.561, v1.607): the
// list under the map names the places, one row for each pin, however many ways
// hang at it; a pin with several ways opens a sheet naming them (the same as a
// tap on its pin on the map).

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
