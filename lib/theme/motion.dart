// The pace of the interface's own transitions (v1.886): three durations for a
// fade, a switch, a slide or a resize that is part of the UI. Timelines that
// are choreographed to art (a fight's blows, a reveal, a loop) keep their own.
abstract final class Motion {
  Motion._();

  /// A small change in place: a tint, a tick, a chevron turning.
  static const Duration fast = Duration(milliseconds: 160);

  /// The usual change: a card that appears, a tab that swaps, a panel that
  /// resizes.
  static const Duration base = Duration(milliseconds: 240);

  /// A change that should be seen arriving: a banner, a large fade.
  static const Duration slow = Duration(milliseconds: 400);
}
