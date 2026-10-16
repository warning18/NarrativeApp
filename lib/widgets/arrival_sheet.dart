// Arriving at a place (docs/proposals/journey-pins-scene.md, option S2, the
// user's pick for places): the scene's words in a sheet that rises over the
// map, the place's name on its header, a Continue under them. The map stays
// in view (dimmed) with the party's mark at the place; main-story scenes keep
// the full page (S1). See choice_flow.dart for when each opens.
import 'package:flutter/material.dart';

import '../data/choice_flow.dart';
import '../theme/stitched_ink.dart';

/// How the Journey shows the scene a taken choice led to.
enum ArrivalView {
  /// Read full screen, Continue under it (S1: the main story, a detour).
  page,

  /// A sheet over the map (S2: any other place).
  sheet,

  /// Nothing: the map, with its own notice (a one-tap return to a hub).
  none,
}

/// Which view the scene a choice led to opens in (see choice_flow.dart):
/// a one-tap return to a hub opens none, a main-story scene (or one met on a
/// detour) the full page, every other scene the sheet.
ArrivalView arrivalViewOf(
  ChoiceFlow flow, {
  required bool mainStory,
  required bool inExcursion,
}) {
  if (flow is FlowReturnToHub) return ArrivalView.none;
  return inExcursion || mainStory ? ArrivalView.page : ArrivalView.sheet;
}

class ArrivalSheet extends StatefulWidget {
  const ArrivalSheet({
    super.key,
    required this.title,
    required this.child,
    required this.continueLabel,
    required this.closeTip,
    required this.onContinue,
  });

  /// The place's name (empty when the scene has none: no header).
  final String title;

  /// The scene's words.
  final Widget child;
  final String continueLabel;
  final String closeTip;
  final VoidCallback onContinue;

  @override
  State<ArrivalSheet> createState() => _ArrivalSheetState();
}

class _ArrivalSheetState extends State<ArrivalSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    _rise.forward();
  }

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final still = MediaQuery.of(context).disableAnimations;
    final eased = CurvedAnimation(parent: _rise, curve: Curves.easeOutCubic);
    return LayoutBuilder(builder: (context, box) {
      final panel = Material(
        key: const Key('journey_arrival_panel'),
        color: theme.colorScheme.surface,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: box.maxHeight * 0.62),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (widget.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 4, 6),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, size: 18, color: ink.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          key: const Key('journey_arrival_title'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontFamily: InkFonts.display),
                        ),
                      ),
                      IconButton(
                        key: const Key('journey_arrival_close'),
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: widget.closeTip,
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onContinue,
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: widget.child,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('journey_continue'),
                    onPressed: widget.onContinue,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(widget.continueLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return Stack(
        key: const Key('journey_arrival_sheet'),
        children: [
          // The map, dimmed: a tap on it is Continue.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onContinue,
              child: FadeTransition(
                opacity: eased,
                child: const ColoredBox(color: Color(0x73000000)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: still
                ? FadeTransition(opacity: eased, child: panel)
                : SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.35), end: Offset.zero)
                        .animate(eased),
                    child: FadeTransition(opacity: eased, child: panel),
                  ),
          ),
        ],
      );
    });
  }
}
