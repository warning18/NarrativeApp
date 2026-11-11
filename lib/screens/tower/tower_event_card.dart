// PROTOTYPE of the Tower's floor-event cards (picture first, never merged):
// the setback's test with its odds, the rival's condition, the shortcut's
// offer, the result line of the last event and the revisit line. The data
// is a mock of Core's TowerEventView (docs/proposals/tower-snakes-and-ladders.md)
// so the cards can be pictured on the real screens.
import 'package:flutter/material.dart';

import '../../theme/stitched_ink.dart';
import '../../widgets/ink_panel.dart';

enum MockEventKind { test, rival, shortcut }

class TowerEventMock {
  const TowerEventMock({
    this.kind,
    this.floor = 14,
    this.revisit = false,
    this.setbacksLeft = 1,
    this.ability = 'strength',
    this.dc = 12,
    this.modifier = 3,
    this.chance = 0.6,
    this.fallTo = 12,
    this.gain = 1,
    this.rounds = 3,
    this.landsOn = 16,
    this.foe = 'Unmade Knight',
    this.skip = 2,
    this.result,
  });

  final MockEventKind? kind;
  final int floor;
  final bool revisit;
  final int setbacksLeft;
  final String ability;
  final int dc, modifier, fallTo, gain, rounds, landsOn, skip;
  final double chance;
  final String foe;
  final MockResult? result;
}

class MockResult {
  const MockResult(
      {required this.kind,
      required this.passed,
      required this.from,
      required this.to,
      this.roll,
      this.total,
      this.dc});
  final MockEventKind kind;
  final bool passed;
  final int from, to;
  final int? roll, total, dc;
}

/// What the picture shows; null leaves the screens as they are.
TowerEventMock? towerEventMock;

class TowerEventCard extends StatelessWidget {
  const TowerEventCard(this.event, {super.key});

  final TowerEventMock event;

  @override
  Widget build(BuildContext context) {
    switch (event.kind) {
      case MockEventKind.test:
        return _test(context);
      case MockEventKind.rival:
        return _rival(context);
      case MockEventKind.shortcut:
        return _shortcut(context);
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _tag(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(text.toUpperCase(),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: color, letterSpacing: 1.2)),
    ]);
  }

  Widget _outcome(BuildContext context, IconData icon, Color color,
      String label, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: '$label  ',
                style: theme.textTheme.labelLarge?.copyWith(color: color)),
            TextSpan(text: text, style: theme.textTheme.bodyMedium),
          ])),
        ),
      ]),
    );
  }

  Widget _test(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final pct = (event.chance * 100).round();
    return InkPanel(
      key: const Key('tower_event_test'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tag(context, Icons.trending_down, 'Setback', ink.blood),
        const SizedBox(height: 6),
        Text('A test of ${event.ability}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(
            'The stair is slick with ash. Roll a d20, add ${event.modifier}: '
            'you need ${event.dc} to hold your footing.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(children: [
          Text('$pct%',
              style: theme.textTheme.headlineSmall?.copyWith(color: ink.gold)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                  value: event.chance, minHeight: 8, color: ink.heal),
            ),
          ),
        ]),
        Text('chance to pass (d20 + ${event.modifier} against ${event.dc})',
            style: theme.textTheme.bodySmall),
        _outcome(context, Icons.check_circle_outline, ink.heal, 'Pass',
            'keep your footing and take ${event.gain} potion.'),
        _outcome(context, Icons.south, ink.blood, 'Fail',
            'fall to floor ${event.fallTo}. Floors you have cleared pay nothing twice.'),
        const SizedBox(height: 6),
        Text(
            event.setbacksLeft == 1
                ? '1 setback left on this climb'
                : '${event.setbacksLeft} setbacks left on this climb',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _rival(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return InkPanel(
      key: const Key('tower_event_rival'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tag(context, Icons.bolt, 'Rival', ink.gold),
        const SizedBox(height: 6),
        Text('A rival races you up',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(
            'Beat them fast and the stair will not make you climb floor '
            '${event.floor + 1}.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        _outcome(
            context,
            Icons.timer_outlined,
            ink.gold,
            'Win within ${event.rounds} rounds',
            'skip to floor ${event.landsOn}.'),
        _outcome(
            context,
            Icons.arrow_forward,
            theme.colorScheme.onSurfaceVariant,
            'Slower or lost fight',
            'it is the ordinary fight, no penalty.'),
      ]),
    );
  }

  Widget _shortcut(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return InkPanel(
      key: const Key('tower_event_shortcut'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tag(context, Icons.north_east, 'Shortcut', ink.gold),
        const SizedBox(height: 6),
        Text('A shorter way up',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(
            'A door in the wall. Behind it stands ${event.foe}, an Elite, '
            'in place of the ordinary fight.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        _outcome(context, Icons.north, ink.gold, 'Win',
            'skip ${event.skip} floors: land on floor ${event.landsOn}.'),
        _outcome(context, Icons.dangerous_outlined, ink.blood, 'Lose',
            'the climb ends here, as any lost fight does.'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  key: const Key('tower_shortcut_decline'),
                  onPressed: () {},
                  child: const Text('Take the stair'))),
          const SizedBox(width: 10),
          Expanded(
              child: FilledButton(
                  key: const Key('tower_shortcut_accept'),
                  onPressed: () {},
                  child: const Text('Take the door'))),
        ]),
      ]),
    );
  }
}

/// The line of how the last event ended, and the floor the run is now on.
class TowerEventResultLine extends StatelessWidget {
  const TowerEventResultLine(this.result, {super.key});

  final MockResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final up = result.to > result.from + 1;
    final down = result.to < result.from;
    final color = down ? ink.blood : ink.gold;
    final headline = switch ((result.kind, result.passed)) {
      (MockEventKind.test, false) =>
        'You fell from floor ${result.from} to floor ${result.to}',
      (MockEventKind.test, true) =>
        'You held your footing on floor ${result.from}',
      (MockEventKind.rival, true) =>
        'You outran your rival: floor ${result.from + 1} skipped, you land on floor ${result.to}',
      (MockEventKind.rival, false) => 'Your rival got away',
      (MockEventKind.shortcut, true) =>
        'You took the door: floor ${result.from} to floor ${result.to}',
      (MockEventKind.shortcut, false) => 'The door held a worse fate',
    };
    final detail = result.roll == null
        ? null
        : 'You rolled ${result.roll} + ${result.total! - result.roll!} = '
            '${result.total} against ${result.dc}.';
    return InkPanel(
      key: const Key('tower_event_result'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(down ? Icons.south : (up ? Icons.north : Icons.check),
            color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(headline,
                style: theme.textTheme.titleSmall?.copyWith(color: color)),
            if (detail != null)
              Text(detail,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (down)
              Text('Floors you have already cleared pay nothing again.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}

/// The revisit line: a floor met again pays nothing.
class TowerRevisitLine extends StatelessWidget {
  const TowerRevisitLine({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkPanel(
      key: const Key('tower_event_revisit'),
      dim: true,
      child: Row(children: [
        Icon(Icons.history,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
            child: Text('You have been here: this floor pays nothing.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant))),
      ]),
    );
  }
}
