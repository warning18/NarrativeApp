// The Tower floor's "Your dice" panel: the dice the run has gained, the one
// in play marked, a die of the main clan saying it resonates, a "new" dot on
// a die not looked at yet, and a tap on a die showing its faces and "Roll
// this die". The data and the moves are Core's (towerDiceOf, chooseDie,
// markDieSeen); this file only draws them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart';
import '../../data/tower/tower_dice.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/pixel_chip.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/face_style.dart';
import '../../widgets/ink_panel.dart';
import '../../widgets/die_tile.dart';

class TowerDicePanel extends ConsumerStatefulWidget {
  const TowerDicePanel({
    super.key,
    required this.dice,
    required this.onChoose,
    required this.onSeen,
  });

  final List<TowerDieView> dice;

  /// The die [id] chosen to roll from the next fight on.
  final void Function(String id) onChoose;

  /// The die [id] opened: no longer new.
  final void Function(String id) onSeen;

  @override
  ConsumerState<TowerDicePanel> createState() => _TowerDicePanelState();
}

class _TowerDicePanelState extends ConsumerState<TowerDicePanel> {
  String? _open;

  void _tap(TowerDieView d) {
    setState(() => _open = _open == d.id ? null : d.id);
    if (d.isNew) widget.onSeen(d.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final open = widget.dice.where((d) => d.id == _open).firstOrNull;
    return InkPanel(
      key: const Key('tower_dice_panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in widget.dice)
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 124),
                      child: InkWell(
                        key: Key('tower_die_${d.id}'),
                        onTap: () => _tap(d),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                          decoration: ShapeDecoration(
                            color: d.inPlay
                                ? ink.gold.withValues(alpha: 0.12)
                                : Colors.transparent,
                            shape: PixelChipBorder(
                              side: BorderSide(
                                color: _open == d.id
                                    ? ink.gold
                                    : d.inPlay
                                        ? ink.gold.withValues(alpha: 0.6)
                                        : ink.seam,
                                width: _open == d.id ? 2 : 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  DieTile(
                                    dieId: d.id,
                                    faces: d.faces.length,
                                    size: 48,
                                    glowing: d.inPlay,
                                  ),
                                  if (d.isNew)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Semantics(
                                        label: tr(ref, 'tower_dice_new'),
                                        child: Container(
                                          key: Key('tower_die_new_${d.id}'),
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: ink.blood,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dieDisplayName(d.id, language: lang),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              if (d.inPlay)
                                _tag(
                                  tr(ref, 'tower_dice_in_play'),
                                  ink.gold,
                                  theme,
                                ),
                              if (d.resonates)
                                _tag(
                                  tr(ref, 'tower_dice_resonates'),
                                  ink.heal,
                                  theme,
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
          if (open != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final f in open.faces) _face(f, theme)],
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('tower_die_roll'),
              onPressed: open.inPlay ? null : () => widget.onChoose(open.id),
              child: Text(
                open.inPlay
                    ? tr(ref, 'tower_dice_in_play')
                    : tr(ref, 'tower_dice_roll'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _face(Map<String, dynamic> face, ThemeData theme) {
    final kind = faceKind('${face['type']}');
    final value = face['value'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(
        shape: PixelChipBorder(
          side: BorderSide(color: kind.color.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: IconSize.s16, color: kind.color),
          if (value != null) ...[
            const SizedBox(width: 3),
            Text('$value', style: theme.textTheme.labelMedium),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text, Color color, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: ShapeDecoration(
            color: color.withValues(alpha: 0.14),
            shape: PixelChipBorder(
              side: BorderSide(color: color.withValues(alpha: 0.7)),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ),
      );
}
